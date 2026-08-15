-- Phase 7-9 server contracts. All entitlement and result state is server-owned.

create or replace function public.use_my_fortune_pass()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_user_id uuid := auth.uid();
  now_value timestamptz := now();
  current_day date := public.get_current_fortune_date(now_value);
  pass_row public.fortune_passes%rowtype;
  session_row public.daily_fortune_sessions%rowtype;
  birth_row public.birth_profiles%rowtype;
  provider_version text;
  prompt_version_value text;
begin
  if current_user_id is null then raise exception 'UNAUTHENTICATED'; end if;
  if public.is_fortune_transition_window(now_value) then raise exception 'TRANSITION_WINDOW'; end if;
  if not exists (select 1 from public.user_entry_records where user_id = current_user_id) then
    raise exception 'REGISTRATION_REQUIRED';
  end if;
  if not exists (select 1 from public.user_consent_events e join public.legal_documents d on d.id = e.legal_document_id
    where e.user_id = current_user_id and e.action = 'accepted' and d.status = 'active' and d.required_for_ai
      and e.event_at = (select max(e2.event_at) from public.user_consent_events e2 where e2.user_id = e.user_id and e2.legal_document_id = e.legal_document_id)) then
    raise exception 'AI_CONSENT_REQUIRED';
  end if;
  select * into birth_row from public.birth_profiles where user_id = current_user_id;
  if birth_row.user_id is null then raise exception 'BIRTH_PROFILE_REQUIRED'; end if;

  select * into session_row from public.daily_fortune_sessions
    where user_id = current_user_id and fortune_date = current_day for update;
  if session_row.id is not null and session_row.entitlement_status <> 'none' then
    return jsonb_build_object('status', 'already_entitled', 'session_id', session_row.id, 'fortune_date', current_day);
  end if;
  if session_row.id is not null and session_row.generation_status = 'ready' and session_row.fortune_payload is not null then
    raise exception 'FORTUNE_ALREADY_READY';
  end if;

  select * into pass_row from public.fortune_passes
    where user_id = current_user_id and status = 'available'
      and current_day between valid_from_fortune_date and expires_after_fortune_date
    order by expires_after_fortune_date, created_at
    for update skip locked limit 1;
  if pass_row.id is null then raise exception 'NO_AVAILABLE_PASS'; end if;
  select version into provider_version from public.ai_provider_sets where status = 'active' order by activated_at desc nulls last limit 1;
  select version into prompt_version_value from public.prompt_versions where status = 'active' order by activated_at desc nulls last limit 1;
  if provider_version is null or prompt_version_value is null then raise exception 'PROVIDER_NOT_AVAILABLE'; end if;

  if session_row.id is null then
    insert into public.daily_fortune_sessions(
      user_id, fortune_date, generation_status, entitlement_status, entitlement_pass_id,
      provider_set_version, prompt_version, generation_epoch, generation_input_snapshot,
      expires_at, metadata_delete_after, generation_started_at
    ) values (
      current_user_id, current_day, 'generating', 'earned_pass', pass_row.id,
      provider_version, prompt_version_value, 1,
      jsonb_build_object('fortune_date', current_day, 'calendar_type', birth_row.calendar_type,
        'is_leap_month', birth_row.is_leap_month, 'birth_date', birth_row.birth_date,
        'birth_time', birth_row.birth_time, 'birth_time_precision', birth_row.birth_time_precision,
        'birth_country_code', birth_row.birth_country_code, 'birth_city', birth_row.birth_city),
      public.get_fortune_day_expires_at(current_day), public.get_fortune_day_expires_at(current_day) + interval '30 days', now()
    ) returning * into session_row;
  else
    update public.daily_fortune_sessions set generation_status = 'generating', entitlement_status = 'earned_pass',
      entitlement_pass_id = pass_row.id, provider_set_version = provider_version, prompt_version = prompt_version_value,
      generation_epoch = generation_epoch + 1, generation_input_snapshot = jsonb_build_object(
        'fortune_date', current_day, 'calendar_type', birth_row.calendar_type, 'is_leap_month', birth_row.is_leap_month,
        'birth_date', birth_row.birth_date, 'birth_time', birth_row.birth_time,
        'birth_time_precision', birth_row.birth_time_precision, 'birth_country_code', birth_row.birth_country_code,
        'birth_city', birth_row.birth_city), generation_started_at = now(), updated_at = now()
      where id = session_row.id returning * into session_row;
  end if;
  update public.fortune_passes set status = 'reserved', reserved_for_session_id = session_row.id,
    reserved_at = now(), updated_at = now() where id = pass_row.id;
  return jsonb_build_object('status', 'reserved', 'session_id', session_row.id, 'generation_epoch', session_row.generation_epoch, 'fortune_date', current_day);
end;
$$;

create or replace function public.restore_my_reserved_pass_after_missed_day()
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare restored_count integer;
begin
  if auth.uid() is null then raise exception 'UNAUTHENTICATED'; end if;
  update public.fortune_passes p set status = 'available', expires_after_fortune_date = p.expires_after_fortune_date + 1,
    reserved_for_session_id = null, reserved_at = null, updated_at = now()
    where p.user_id = auth.uid() and p.status = 'reserved' and exists (
      select 1 from public.daily_fortune_sessions s where s.id = p.reserved_for_session_id
        and s.generation_status = 'recovery_pending' and s.fortune_date < public.get_current_fortune_date(now()));
  get diagnostics restored_count = row_count;
  return jsonb_build_object('restored_count', restored_count);
end; $$;

revoke all on function public.use_my_fortune_pass() from public, anon;
grant execute on function public.use_my_fortune_pass() to authenticated;
revoke all on function public.restore_my_reserved_pass_after_missed_day() from public, anon;
grant execute on function public.restore_my_reserved_pass_after_missed_day() to authenticated;

create or replace function public.process_admob_ssv_callback(
  custom_data_value text, transaction_id_value text, reward_timestamp_value timestamptz,
  ad_unit_id_value text, reward_item_value text, reward_amount_value numeric
)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare attempt_row public.ad_attempts%rowtype; session_row public.daily_fortune_sessions%rowtype; issued_pass_id uuid;
begin
  if custom_data_value is null or length(custom_data_value) = 0 or length(custom_data_value) > 8192 then return jsonb_build_object('status','rejected'); end if;
  select * into attempt_row from public.ad_attempts where challenge_hash = encode(sha256(convert_to(custom_data_value, 'UTF8')), 'hex') for update;
  if attempt_row.id is null then return jsonb_build_object('status','rejected'); end if;
  if attempt_row.transaction_id is not null then return jsonb_build_object('status','duplicate','session_id',attempt_row.session_id); end if;
  if attempt_row.expires_at < now() then
    select * into session_row from public.daily_fortune_sessions where id = attempt_row.session_id for update;
    if session_row.goodwill_compensation_status = 'none'
      and (select count(*) from public.fortune_passes where user_id = session_row.user_id and status in ('available','reserved')) < 3 then
      insert into public.fortune_passes(user_id, source, status, valid_from_fortune_date, expires_after_fortune_date, source_session_id)
        values (session_row.user_id, 'fulfillment_missed', 'available', public.get_current_fortune_date(now()), public.get_current_fortune_date(now()) + 30, session_row.id)
        returning id into issued_pass_id;
      update public.daily_fortune_sessions set goodwill_compensation_status = 'issued', goodwill_compensation_pass_id = issued_pass_id, updated_at = now() where id = session_row.id;
    elsif session_row.goodwill_compensation_status = 'none' then
      update public.daily_fortune_sessions set goodwill_compensation_status = 'skipped_cap', updated_at = now() where id = session_row.id;
    end if;
    return jsonb_build_object('status','late_compensation_only','session_id',attempt_row.session_id);
  end if;
  update public.ad_attempts set reward_status = 'ssv_verified', transaction_id = transaction_id_value,
    reward_item = reward_item_value, reward_amount = reward_amount_value, ad_unit_id = ad_unit_id_value,
    ssv_rewarded_at = reward_timestamp_value, ssv_verified_at = now() where id = attempt_row.id;
  select * into session_row from public.daily_fortune_sessions where id = attempt_row.session_id for update;
  if session_row.entitlement_status = 'none' and session_row.fortune_date = public.get_current_fortune_date(now()) then
    update public.daily_fortune_sessions set entitlement_status = 'earned_reward', generation_status = 'generating',
      generation_epoch = generation_epoch + 1, updated_at = now() where id = session_row.id;
    return jsonb_build_object('status','granted','session_id',session_row.id,'generation_epoch',session_row.generation_epoch + 1);
  end if;
  return jsonb_build_object('status','late_compensation_only','session_id',session_row.id);
end; $$;

revoke all on function public.process_admob_ssv_callback(text, text, timestamptz, text, text, numeric) from public, anon, authenticated;

create or replace function public.commit_fortune_generation(
  session_id_value uuid, generation_epoch_value bigint, payload_value jsonb,
  provider_id_value text, model_name_value text, provider_request_id_value text
)
returns boolean language plpgsql security definer set search_path = public, pg_temp as $$
declare committed boolean;
begin
  update public.daily_fortune_sessions set generation_status = 'ready', fortune_payload = payload_value,
    generated_at = now(), successful_provider_id = provider_id_value, successful_model_name = model_name_value,
    provider_request_id = provider_request_id_value, last_provider_error_class = null, updated_at = now()
    where id = session_id_value and generation_epoch = generation_epoch_value
      and generation_status in ('generating', 'recovery_pending');
  get diagnostics committed = row_count;
  if committed then
    update public.fortune_passes set status = 'redeemed', redeemed_at = now(),
      redeemed_fortune_date = (select fortune_date from public.daily_fortune_sessions where id = session_id_value), updated_at = now()
      where reserved_for_session_id = session_id_value and status = 'reserved';
  end if;
  return committed;
end; $$;

revoke all on function public.commit_fortune_generation(uuid, bigint, jsonb, text, text, text) from public, anon, authenticated;
