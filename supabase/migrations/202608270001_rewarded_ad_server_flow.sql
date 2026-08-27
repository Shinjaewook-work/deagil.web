-- Connect the mobile rewarded-ad callbacks to server-owned attempts,
-- entitlement, and generation state.

alter table public.ad_attempts
  add column if not exists security_mode_at_prepare text,
  add column if not exists expected_ad_unit_id text,
  add column if not exists expected_reward_item text,
  add column if not exists expected_reward_amount numeric;

alter table public.ad_attempts
  drop constraint if exists ad_attempts_security_mode_at_prepare_check;
alter table public.ad_attempts
  add constraint ad_attempts_security_mode_at_prepare_check
  check (security_mode_at_prepare in ('fast', 'reward_gated', 'ssv_strict'));

create or replace function public.prepare_my_ad_session(
  prepare_request_id_value uuid,
  challenge_hash_value text,
  security_mode_value text,
  expected_ad_unit_id_value text,
  expected_reward_item_value text,
  expected_reward_amount_value numeric
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_user_id uuid := auth.uid();
  now_value timestamptz := now();
  current_day date := public.get_current_fortune_date(now_value);
  session_row public.daily_fortune_sessions%rowtype;
  birth_row public.birth_profiles%rowtype;
  attempt_row public.ad_attempts%rowtype;
  provider_version text;
  prompt_version_value text;
begin
  if current_user_id is null then raise exception 'UNAUTHENTICATED'; end if;
  if security_mode_value not in ('fast', 'reward_gated', 'ssv_strict') then raise exception 'INVALID_AD_SECURITY_MODE'; end if;
  if challenge_hash_value !~ '^[0-9a-f]{64}$' then raise exception 'INVALID_AD_CHALLENGE'; end if;
  if expected_ad_unit_id_value is null or expected_reward_item_value is null
    or expected_reward_amount_value is null or expected_reward_amount_value <= 0 then
    raise exception 'INVALID_REWARD_SPEC';
  end if;
  if public.is_fortune_transition_window(now_value) then raise exception 'TRANSITION_WINDOW'; end if;
  if not exists (
    select 1 from public.profiles
    where id = current_user_id and account_status = 'active'
  ) then raise exception 'REGISTRATION_REQUIRED'; end if;
  if not exists (
    select 1 from public.user_consent_events e
    join public.legal_documents d on d.id = e.legal_document_id
    where e.user_id = current_user_id and e.action = 'accepted'
      and d.status = 'active' and d.required_for_ai
      and e.event_at = (
        select max(e2.event_at) from public.user_consent_events e2
        where e2.user_id = e.user_id and e2.legal_document_id = e.legal_document_id
      )
  ) then raise exception 'AI_CONSENT_REQUIRED'; end if;

  select * into birth_row from public.birth_profiles where user_id = current_user_id;
  if birth_row.user_id is null then raise exception 'BIRTH_PROFILE_REQUIRED'; end if;
  select version into provider_version from public.ai_provider_sets
    where status = 'active' order by activated_at desc nulls last limit 1;
  select version into prompt_version_value from public.prompt_versions
    where status = 'active' order by activated_at desc nulls last limit 1;
  if provider_version is null or prompt_version_value is null then raise exception 'PROVIDER_NOT_AVAILABLE'; end if;

  select * into attempt_row from public.ad_attempts
    where user_id = current_user_id and prepare_request_id = prepare_request_id_value;
  if attempt_row.id is not null then
    return jsonb_build_object(
      'status', 'already_prepared', 'ad_attempt_id', attempt_row.id,
      'fortune_date', attempt_row.fortune_date, 'expires_at', attempt_row.expires_at
    );
  end if;

  select * into session_row from public.daily_fortune_sessions
    where user_id = current_user_id and fortune_date = current_day for update;
  if session_row.id is not null then
    if session_row.entitlement_status <> 'none' then raise exception 'ALREADY_ENTITLED'; end if;
    if session_row.generation_status = 'ready' and session_row.fortune_payload is not null then
      raise exception 'FORTUNE_ALREADY_READY';
    end if;
    if session_row.active_ad_attempt_id is not null
      and session_row.active_ad_lease_until > now_value then
      raise exception 'AD_ATTEMPT_ALREADY_ACTIVE';
    end if;
  else
    insert into public.daily_fortune_sessions(
      user_id, fortune_date, generation_status, entitlement_status,
      provider_set_version, prompt_version, generation_input_snapshot,
      expires_at, metadata_delete_after
    ) values (
      current_user_id, current_day, 'not_started', 'none',
      provider_version, prompt_version_value,
      jsonb_build_object(
        'fortune_date', current_day, 'calendar_type', birth_row.calendar_type,
        'is_leap_month', birth_row.is_leap_month, 'birth_date', birth_row.birth_date,
        'birth_time', birth_row.birth_time,
        'birth_time_precision', birth_row.birth_time_precision,
        'birth_country_code', birth_row.birth_country_code,
        'birth_city', birth_row.birth_city
      ),
      public.get_fortune_day_expires_at(current_day),
      public.get_fortune_day_expires_at(current_day) + interval '30 days'
    ) returning * into session_row;
  end if;

  insert into public.ad_attempts(
    user_id, session_id, fortune_date, prepare_request_id, challenge_hash,
    security_mode_at_prepare, expected_ad_unit_id, expected_reward_item,
    expected_reward_amount, expires_at
  ) values (
    current_user_id, session_row.id, current_day, prepare_request_id_value,
    challenge_hash_value, security_mode_value, expected_ad_unit_id_value,
    expected_reward_item_value, expected_reward_amount_value, now_value + interval '7 days'
  ) returning * into attempt_row;

  update public.daily_fortune_sessions
  set active_ad_attempt_id = attempt_row.id,
      active_ad_lease_until = now_value + interval '15 minutes',
      updated_at = now_value
  where id = session_row.id;

  return jsonb_build_object(
    'status', 'prepared', 'ad_attempt_id', attempt_row.id,
    'fortune_date', current_day, 'expires_at', attempt_row.expires_at
  );
end;
$$;

create or replace function public.ensure_reward_generation_started(session_id_value uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  session_row public.daily_fortune_sessions%rowtype;
begin
  select * into session_row from public.daily_fortune_sessions
    where id = session_id_value for update;
  if session_row.id is null then raise exception 'SESSION_NOT_FOUND'; end if;
  if session_row.generation_status = 'ready' and session_row.fortune_payload is not null then
    return jsonb_build_object('generation_started', false, 'session_id', session_row.id,
      'generation_epoch', session_row.generation_epoch, 'generation_status', 'ready');
  end if;
  if session_row.generation_status in ('generating', 'recovery_pending') then
    return jsonb_build_object('generation_started', false, 'session_id', session_row.id,
      'generation_epoch', session_row.generation_epoch, 'generation_status', session_row.generation_status);
  end if;
  update public.daily_fortune_sessions
  set generation_status = 'generating', generation_epoch = generation_epoch + 1,
      generation_started_at = now(), updated_at = now()
  where id = session_row.id returning * into session_row;
  return jsonb_build_object('generation_started', true, 'session_id', session_row.id,
    'generation_epoch', session_row.generation_epoch, 'generation_status', 'generating');
end;
$$;

create or replace function public.report_my_ad_impression(ad_attempt_id_value uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  attempt_row public.ad_attempts%rowtype;
  generation_result jsonb := jsonb_build_object('generation_started', false);
begin
  if auth.uid() is null then raise exception 'UNAUTHENTICATED'; end if;
  select * into attempt_row from public.ad_attempts
    where id = ad_attempt_id_value and user_id = auth.uid() for update;
  if attempt_row.id is null then raise exception 'AD_ATTEMPT_NOT_FOUND'; end if;
  if attempt_row.fortune_date <> public.get_current_fortune_date(now()) then raise exception 'STALE_AD_ATTEMPT'; end if;
  if attempt_row.display_status not in ('prepared', 'impression') then raise exception 'INVALID_AD_DISPLAY_STATE'; end if;
  update public.ad_attempts set display_status = 'impression',
    client_impression_at = coalesce(client_impression_at, now()) where id = attempt_row.id;
  if attempt_row.security_mode_at_prepare = 'fast' then
    generation_result := public.ensure_reward_generation_started(attempt_row.session_id);
  end if;
  return generation_result || jsonb_build_object('status', 'recorded', 'ad_attempt_id', attempt_row.id);
end;
$$;

create or replace function public.claim_my_ad_reward(ad_attempt_id_value uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  attempt_row public.ad_attempts%rowtype;
  session_row public.daily_fortune_sessions%rowtype;
  generation_result jsonb := jsonb_build_object('generation_started', false);
begin
  if auth.uid() is null then raise exception 'UNAUTHENTICATED'; end if;
  select * into attempt_row from public.ad_attempts
    where id = ad_attempt_id_value and user_id = auth.uid() for update;
  if attempt_row.id is null then raise exception 'AD_ATTEMPT_NOT_FOUND'; end if;
  if attempt_row.fortune_date <> public.get_current_fortune_date(now()) then raise exception 'STALE_AD_ATTEMPT'; end if;
  update public.ad_attempts set reward_status = case
      when reward_status = 'ssv_verified' then reward_status else 'client_claimed' end,
    client_reward_claimed_at = coalesce(client_reward_claimed_at, now())
    where id = attempt_row.id;
  if attempt_row.security_mode_at_prepare <> 'ssv_strict' then
    update public.daily_fortune_sessions
    set entitlement_status = case when entitlement_status = 'none' then 'earned_reward' else entitlement_status end,
        updated_at = now()
    where id = attempt_row.session_id returning * into session_row;
    generation_result := public.ensure_reward_generation_started(attempt_row.session_id);
  end if;
  return generation_result || jsonb_build_object(
    'status', case when attempt_row.security_mode_at_prepare = 'ssv_strict'
      then 'verification_pending' else 'granted' end,
    'ad_attempt_id', attempt_row.id, 'session_id', attempt_row.session_id
  );
end;
$$;

create or replace function public.report_my_ad_dismissed(
  ad_attempt_id_value uuid,
  terminal_reason_value text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare attempt_row public.ad_attempts%rowtype;
begin
  if auth.uid() is null then raise exception 'UNAUTHENTICATED'; end if;
  if terminal_reason_value not in ('dismissed', 'show_failed') then raise exception 'INVALID_TERMINAL_REASON'; end if;
  select * into attempt_row from public.ad_attempts
    where id = ad_attempt_id_value and user_id = auth.uid() for update;
  if attempt_row.id is null then raise exception 'AD_ATTEMPT_NOT_FOUND'; end if;
  update public.ad_attempts set display_status = terminal_reason_value where id = attempt_row.id;
  update public.daily_fortune_sessions
  set active_ad_attempt_id = null, active_ad_lease_until = null, updated_at = now()
  where id = attempt_row.session_id and active_ad_attempt_id = attempt_row.id;
  return jsonb_build_object('status', 'recorded', 'ad_attempt_id', attempt_row.id);
end;
$$;

revoke all on function public.prepare_my_ad_session(uuid, text, text, text, text, numeric) from public, anon;
grant execute on function public.prepare_my_ad_session(uuid, text, text, text, text, numeric) to authenticated;
revoke all on function public.ensure_reward_generation_started(uuid) from public, anon, authenticated;
revoke all on function public.report_my_ad_impression(uuid) from public, anon;
grant execute on function public.report_my_ad_impression(uuid) to authenticated;
revoke all on function public.claim_my_ad_reward(uuid) from public, anon;
grant execute on function public.claim_my_ad_reward(uuid) to authenticated;
revoke all on function public.report_my_ad_dismissed(uuid, text) from public, anon;
grant execute on function public.report_my_ad_dismissed(uuid, text) to authenticated;

create or replace function public.process_admob_ssv_callback(
  custom_data_value text, transaction_id_value text,
  reward_timestamp_value timestamptz, ad_unit_id_value text,
  reward_item_value text, reward_amount_value numeric
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  attempt_row public.ad_attempts%rowtype;
  session_row public.daily_fortune_sessions%rowtype;
  issued_pass_id uuid;
  generation_result jsonb := jsonb_build_object('generation_started', false);
begin
  if custom_data_value is null or length(custom_data_value) = 0 or length(custom_data_value) > 8192 then
    return jsonb_build_object('status', 'rejected');
  end if;
  select * into attempt_row from public.ad_attempts
    where challenge_hash = encode(sha256(convert_to(custom_data_value, 'UTF8')), 'hex')
    for update;
  if attempt_row.id is null then return jsonb_build_object('status', 'rejected'); end if;
  if attempt_row.transaction_id is not null then
    return jsonb_build_object('status', 'duplicate', 'session_id', attempt_row.session_id);
  end if;
  if ad_unit_id_value is distinct from attempt_row.expected_ad_unit_id
    or reward_item_value is distinct from attempt_row.expected_reward_item
    or reward_amount_value is distinct from attempt_row.expected_reward_amount then
    update public.ad_attempts set invalid_ssv_count = invalid_ssv_count + 1,
      last_invalid_ssv_at = now() where id = attempt_row.id;
    return jsonb_build_object('status', 'rejected');
  end if;
  if attempt_row.expires_at < now() then
    select * into session_row from public.daily_fortune_sessions
      where id = attempt_row.session_id for update;
    if session_row.goodwill_compensation_status = 'none'
      and (select count(*) from public.fortune_passes
        where user_id = session_row.user_id and status in ('available', 'reserved')) < 3 then
      insert into public.fortune_passes(
        user_id, source, status, valid_from_fortune_date,
        expires_after_fortune_date, source_session_id
      ) values (
        session_row.user_id, 'fulfillment_missed', 'available',
        public.get_current_fortune_date(now()),
        public.get_current_fortune_date(now()) + 30, session_row.id
      ) returning id into issued_pass_id;
      update public.daily_fortune_sessions
      set goodwill_compensation_status = 'issued',
          goodwill_compensation_pass_id = issued_pass_id, updated_at = now()
      where id = session_row.id;
    elsif session_row.goodwill_compensation_status = 'none' then
      update public.daily_fortune_sessions
      set goodwill_compensation_status = 'skipped_cap', updated_at = now()
      where id = session_row.id;
    end if;
    return jsonb_build_object('status', 'late_compensation_only',
      'session_id', attempt_row.session_id);
  end if;
  update public.ad_attempts
  set reward_status = 'ssv_verified', transaction_id = transaction_id_value,
      reward_item = reward_item_value, reward_amount = reward_amount_value,
      ad_unit_id = ad_unit_id_value, ssv_rewarded_at = reward_timestamp_value,
      ssv_verified_at = now()
  where id = attempt_row.id;

  select * into session_row from public.daily_fortune_sessions
    where id = attempt_row.session_id for update;
  if session_row.entitlement_status = 'none'
    and session_row.fortune_date = public.get_current_fortune_date(now()) then
    update public.daily_fortune_sessions
    set entitlement_status = 'earned_reward', updated_at = now()
    where id = session_row.id;
    generation_result := public.ensure_reward_generation_started(session_row.id);
    return generation_result || jsonb_build_object(
      'status', 'granted', 'session_id', session_row.id
    );
  end if;
  return jsonb_build_object('status', 'verified', 'session_id', session_row.id,
    'generation_started', false);
end;
$$;

revoke all on function public.process_admob_ssv_callback(text, text, timestamptz, text, text, numeric)
  from public, anon, authenticated;
