-- Bound provider work and expose an authenticated, entitlement-only recovery claim.
-- The runtime row is server-owned: clients cannot change provider limits or retry state.

create table if not exists public.ai_generation_runtime_config (
  singleton boolean primary key default true check (singleton),
  max_provider_requests_per_session integer not null check (max_provider_requests_per_session > 0),
  max_recovery_rounds_per_session integer not null check (max_recovery_rounds_per_session >= 0),
  daily_max_provider_requests integer not null check (daily_max_provider_requests > 0),
  recovery_cooldown_seconds integer not null check (recovery_cooldown_seconds >= 0),
  updated_at timestamptz not null default now()
);

insert into public.ai_generation_runtime_config(
  singleton, max_provider_requests_per_session,
  max_recovery_rounds_per_session, daily_max_provider_requests,
  recovery_cooldown_seconds
) values (true, 4, 3, 1000, 300)
on conflict (singleton) do nothing;

alter table public.ai_generation_runtime_config enable row level security;
revoke all on table public.ai_generation_runtime_config from public, anon, authenticated;

create or replace function public.claim_generation_for_session(
  session_id_value uuid,
  recovery_value boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  session_row public.daily_fortune_sessions%rowtype;
  config_row public.ai_generation_runtime_config%rowtype;
  budget_row public.ai_budget_daily%rowtype;
  now_value timestamptz := now();
  current_day date := public.get_current_fortune_date(now_value);
  next_status text;
begin
  select * into config_row
  from public.ai_generation_runtime_config
  where singleton = true;
  if config_row.singleton is distinct from true then
    raise exception 'AI_RUNTIME_CONFIG_MISSING';
  end if;

  select * into session_row
  from public.daily_fortune_sessions
  where id = session_id_value
  for update;
  if session_row.id is null then raise exception 'SESSION_NOT_FOUND'; end if;

  if session_row.generation_status = 'ready' and session_row.fortune_payload is not null then
    return jsonb_build_object(
      'generation_started', false, 'session_id', session_row.id,
      'generation_epoch', session_row.generation_epoch,
      'generation_status', 'ready'
    );
  end if;

  if session_row.generation_status = 'generating' then
    if session_row.generation_lease_until is null or session_row.generation_lease_until <= now_value then
      next_status := case when session_row.entitlement_status = 'none' then 'failed' else 'recovery_pending' end;
      update public.daily_fortune_sessions
      set generation_status = next_status,
          generation_lease_until = null,
          last_provider_error_class = 'generation_lease_expired',
          last_generation_failure_at = now_value,
          next_retry_at = case when next_status = 'recovery_pending'
            then now_value + make_interval(secs => config_row.recovery_cooldown_seconds) else null end,
          updated_at = now_value
      where id = session_row.id;
    end if;
    return jsonb_build_object(
      'generation_started', false, 'session_id', session_row.id,
      'generation_epoch', session_row.generation_epoch,
      'generation_status', case when session_row.generation_lease_until is not null
        and session_row.generation_lease_until > now_value then 'generating' else next_status end
    );
  end if;

  if recovery_value and session_row.generation_status <> 'recovery_pending' then
    raise exception 'RECOVERY_NOT_PENDING';
  end if;
  if recovery_value and session_row.entitlement_status = 'none' then
    raise exception 'RECOVERY_NOT_ENTITLED';
  end if;
  if session_row.fortune_date <> current_day then raise exception 'STALE_FORTUNE_SESSION'; end if;
  if public.is_fortune_transition_window(now_value) then raise exception 'TRANSITION_WINDOW'; end if;
  if session_row.generation_input_snapshot is null then raise exception 'GENERATION_SNAPSHOT_MISSING'; end if;

  if recovery_value and session_row.next_retry_at is not null and session_row.next_retry_at > now_value then
    raise exception 'RECOVERY_COOLDOWN';
  end if;
  if recovery_value and session_row.recovery_round_count >= config_row.max_recovery_rounds_per_session then
    raise exception 'RECOVERY_LIMIT_REACHED';
  end if;
  if session_row.provider_request_count >= config_row.max_provider_requests_per_session then
    raise exception 'PROVIDER_REQUEST_LIMIT_REACHED';
  end if;

  insert into public.ai_budget_daily(usage_date, reserved_requests, completed_requests, updated_at)
  values (current_day, 1, 0, now_value)
  on conflict (usage_date) do update
  set reserved_requests = public.ai_budget_daily.reserved_requests + 1,
      updated_at = now_value
  where public.ai_budget_daily.reserved_requests < config_row.daily_max_provider_requests
  returning * into budget_row;
  if budget_row.usage_date is null then raise exception 'AI_DAILY_BUDGET_EXHAUSTED'; end if;

  update public.daily_fortune_sessions
  set generation_status = 'generating',
      generation_epoch = generation_epoch + 1,
      generation_request_id = gen_random_uuid(),
      generation_lease_until = now_value + interval '60 seconds',
      generation_started_at = now_value,
      provider_request_count = provider_request_count + 1,
      recovery_round_count = recovery_round_count + case when recovery_value then 1 else 0 end,
      next_retry_at = null,
      updated_at = now_value
  where id = session_row.id
  returning * into session_row;

  return jsonb_build_object(
    'generation_started', true, 'session_id', session_row.id,
    'generation_epoch', session_row.generation_epoch,
    'generation_status', session_row.generation_status
  );
end;
$$;

create or replace function public.ensure_reward_generation_started(session_id_value uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  return public.claim_generation_for_session(session_id_value, false);
end;
$$;

create or replace function public.resume_my_fortune_generation()
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
begin
  if current_user_id is null then raise exception 'UNAUTHENTICATED'; end if;
  if not exists (
    select 1 from public.profiles
    where id = current_user_id and account_status = 'active'
  ) then raise exception 'ACCOUNT_SUSPENDED'; end if;
  if not exists (select 1 from public.user_entry_records where user_id = current_user_id) then
    raise exception 'REGISTRATION_REQUIRED';
  end if;
  if public.is_fortune_transition_window(now_value) then raise exception 'TRANSITION_WINDOW'; end if;

  select * into session_row
  from public.daily_fortune_sessions
  where user_id = current_user_id and fortune_date = current_day
  for update;
  if session_row.id is null then raise exception 'SESSION_NOT_FOUND'; end if;
  if session_row.entitlement_status = 'none' then raise exception 'RECOVERY_NOT_ENTITLED'; end if;
  if session_row.generation_status <> 'recovery_pending' then
    if session_row.generation_status = 'generating'
      and session_row.generation_lease_until is not null
      and session_row.generation_lease_until > now_value then
      return jsonb_build_object(
        'status', 'already_generating', 'generation_started', false,
        'session_id', session_row.id, 'generation_epoch', session_row.generation_epoch
      );
    end if;
    raise exception 'RECOVERY_NOT_PENDING';
  end if;
  if session_row.next_retry_at is not null and session_row.next_retry_at > now_value then
    raise exception 'RECOVERY_COOLDOWN';
  end if;
  if session_row.generation_input_snapshot is null then raise exception 'GENERATION_SNAPSHOT_MISSING'; end if;
  if exists (
    select 1
    from public.legal_documents d
    where d.status = 'active' and d.required_for_ai
      and not exists (
        select 1 from public.user_consent_events e
        where e.user_id = current_user_id and e.legal_document_id = d.id
          and e.action = 'accepted'
          and e.event_at = (
            select max(e2.event_at)
            from public.user_consent_events e2
            where e2.user_id = current_user_id and e2.legal_document_id = d.id
          )
      )
  ) then raise exception 'AI_CONSENT_REQUIRED'; end if;

  return public.claim_generation_for_session(session_row.id, true);
end;
$$;

create or replace function public.record_generation_failure(
  session_id_value uuid,
  generation_epoch_value bigint,
  error_class_value text
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  session_row public.daily_fortune_sessions%rowtype;
  config_row public.ai_generation_runtime_config%rowtype;
  next_status text;
  next_retry timestamptz;
begin
  select * into config_row from public.ai_generation_runtime_config where singleton = true;
  select * into session_row
  from public.daily_fortune_sessions
  where id = session_id_value and generation_epoch = generation_epoch_value
  for update;
  if session_row.id is null or session_row.generation_status not in ('generating', 'recovery_pending') then
    return false;
  end if;
  next_status := case when session_row.entitlement_status = 'none' then 'failed' else 'recovery_pending' end;
  next_retry := case
    when next_status = 'recovery_pending'
      and session_row.provider_request_count < config_row.max_provider_requests_per_session
      and session_row.recovery_round_count < config_row.max_recovery_rounds_per_session
    then now() + make_interval(secs => config_row.recovery_cooldown_seconds)
    else null
  end;
  update public.daily_fortune_sessions
  set generation_status = next_status,
      generation_lease_until = null,
      last_provider_error_class = left(coalesce(nullif(error_class_value, ''), 'unknown'), 80),
      last_generation_failure_at = now(),
      next_retry_at = next_retry,
      updated_at = now()
  where id = session_row.id and generation_epoch = generation_epoch_value;
  return true;
end;
$$;

create or replace function public.mark_generation_dispatch_failed(
  session_id_value uuid,
  generation_epoch_value bigint
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  return public.record_generation_failure(session_id_value, generation_epoch_value, 'worker_dispatch_failed');
end;
$$;

create or replace function public.commit_fortune_generation(
  session_id_value uuid, generation_epoch_value bigint, payload_value jsonb,
  provider_id_value text, model_name_value text, provider_request_id_value text
)
returns boolean language plpgsql security definer set search_path = public, pg_temp as $$
declare committed boolean;
begin
  update public.daily_fortune_sessions
  set generation_status = 'ready', fortune_payload = payload_value,
    generated_at = now(), successful_provider_id = provider_id_value,
    successful_model_name = model_name_value, provider_request_id = provider_request_id_value,
    last_provider_error_class = null, generation_lease_until = null,
    next_retry_at = null, updated_at = now()
  where id = session_id_value and generation_epoch = generation_epoch_value
    and generation_status in ('generating', 'recovery_pending');
  get diagnostics committed = row_count;
  if committed then
    update public.fortune_passes
    set status = 'redeemed', redeemed_at = now(),
      redeemed_fortune_date = (select fortune_date from public.daily_fortune_sessions where id = session_id_value),
      updated_at = now()
    where reserved_for_session_id = session_id_value and status = 'reserved';
  end if;
  return committed;
end;
$$;

revoke all on function public.claim_generation_for_session(uuid, boolean) from public, anon, authenticated;
revoke all on function public.ensure_reward_generation_started(uuid) from public, anon, authenticated;
revoke all on function public.resume_my_fortune_generation() from public, anon;
grant execute on function public.resume_my_fortune_generation() to authenticated;
revoke all on function public.record_generation_failure(uuid, bigint, text) from public, anon, authenticated;
grant execute on function public.record_generation_failure(uuid, bigint, text) to service_role;
revoke all on function public.mark_generation_dispatch_failed(uuid, bigint) from public, anon, authenticated;
grant execute on function public.mark_generation_dispatch_failed(uuid, bigint) to service_role;
revoke all on function public.commit_fortune_generation(uuid, bigint, jsonb, text, text, text) from public, anon, authenticated;
grant execute on function public.commit_fortune_generation(uuid, bigint, jsonb, text, text, text) to service_role;
