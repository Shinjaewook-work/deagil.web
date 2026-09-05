create or replace function public.get_my_app_state()
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  current_user_id uuid := auth.uid();
  now_value timestamptz := now();
  current_day date := public.get_current_fortune_date(now_value);
  current_session public.daily_fortune_sessions%rowtype;
  current_profile public.profiles%rowtype;
  runtime_config public.ai_generation_runtime_config%rowtype;
  required_registration_count integer;
  accepted_registration_count integer;
  gate_value text := 'NONE';
  state_value text := 'NO_SESSION';
  readable boolean := false;
  can_resume boolean := false;
begin
  if current_user_id is null then
    return jsonb_build_object(
      'api_contract_version', 1,
      'server_now', now_value,
      'gate', 'REGISTRATION_REQUIRED',
      'fortune_state', 'NO_SESSION',
      'can_resume_generation', false
    );
  end if;

  select * into current_profile from public.profiles where id = current_user_id;
  if current_profile.account_status = 'suspended' then gate_value := 'ACCOUNT_SUSPENDED';
  elsif not exists (select 1 from public.user_entry_records where user_id = current_user_id) then gate_value := 'REGISTRATION_REQUIRED';
  else
    select count(*) into required_registration_count from public.legal_documents where status = 'active' and required_for_registration;
    select count(*) into accepted_registration_count
      from public.legal_documents d
      where d.status = 'active' and d.required_for_registration
        and exists (select 1 from public.user_consent_events e where e.user_id = current_user_id and e.legal_document_id = d.id and e.action = 'accepted'
          and e.event_at = (select max(e2.event_at) from public.user_consent_events e2 where e2.user_id = current_user_id and e2.legal_document_id = d.id));
    if accepted_registration_count < required_registration_count then gate_value := 'CONSENT_UPDATE_REQUIRED'; end if;
  end if;

  select * into current_session from public.daily_fortune_sessions where user_id = current_user_id and fortune_date = current_day;
  select * into runtime_config from public.ai_generation_runtime_config where singleton = true;
  if current_session.id is not null then
    readable := current_session.entitlement_status <> 'none' and current_session.generation_status = 'ready'
      and current_session.fortune_payload is not null and now_value < current_session.expires_at;
    if public.is_fortune_transition_window(now_value) then state_value := 'TRANSITION_WINDOW';
    elsif readable then state_value := 'UNLOCKED';
    elsif current_session.generation_status = 'generating' then state_value := 'GENERATING';
    elsif current_session.generation_status = 'recovery_pending' then state_value := 'RECOVERY_PENDING';
    elsif current_session.generation_status = 'failed' then state_value := 'FAILED';
    elsif current_session.generation_status = 'ready' then state_value := 'READY_LOCKED';
    else state_value := 'LOCKED'; end if;

    can_resume := gate_value = 'NONE'
      and not public.is_fortune_transition_window(now_value)
      and current_session.entitlement_status <> 'none'
      and current_session.generation_status = 'recovery_pending'
      and current_session.generation_input_snapshot is not null
      and (current_session.next_retry_at is null or current_session.next_retry_at <= now_value)
      and current_session.provider_request_count < coalesce(runtime_config.max_provider_requests_per_session, 4)
      and current_session.recovery_round_count < coalesce(runtime_config.max_recovery_rounds_per_session, 3)
      and not exists (
        select 1
        from public.legal_documents d
        where d.status = 'active' and d.required_for_ai
          and not exists (
            select 1
            from public.user_consent_events e
            where e.user_id = current_user_id and e.legal_document_id = d.id and e.action = 'accepted'
              and e.event_at = (
                select max(e2.event_at)
                from public.user_consent_events e2
                where e2.user_id = current_user_id and e2.legal_document_id = d.id
              )
          )
      );
  elsif public.is_fortune_transition_window(now_value) then state_value := 'TRANSITION_WINDOW'; end if;

  return jsonb_build_object(
    'api_contract_version', 1, 'server_now', now_value, 'gate', gate_value, 'fortune_state', state_value,
    'fortune_date', current_day, 'expires_at', current_session.expires_at,
    'birth_profile_exists', exists(select 1 from public.birth_profiles where user_id = current_user_id),
    'available_pass_count', (select count(*) from public.fortune_passes where user_id = current_user_id and status = 'available' and current_day between valid_from_fortune_date and expires_after_fortune_date),
    'active_pass_count', (select count(*) from public.fortune_passes where user_id = current_user_id and status in ('available', 'reserved')),
    'can_prepare_rewarded_ad', gate_value = 'NONE' and not readable and not public.is_fortune_transition_window(now_value),
    'can_use_pass', gate_value = 'NONE' and not readable and not public.is_fortune_transition_window(now_value)
      and exists(select 1 from public.fortune_passes where user_id = current_user_id and status = 'available' and current_day between valid_from_fortune_date and expires_after_fortune_date),
    'can_resume_generation', can_resume,
    'next_retry_at', current_session.next_retry_at,
    'fortune_payload', case when readable then current_session.fortune_payload else null end
  );
end;
$$;

revoke all on function public.get_my_app_state() from public, anon;
grant execute on function public.get_my_app_state() to authenticated;
