-- Server-driven registration/legal contract.
-- Master Sections 6-7 and 25.1 are authoritative.

create or replace function public.get_public_registration_requirements()
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'api_contract_version', 1,
    'documents', coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', d.id,
          'document_type', d.document_type,
          'version', d.version,
          'title', d.title,
          'public_url', d.public_url,
          'interaction', d.interaction,
          'required_for_registration', d.required_for_registration,
          'required_for_ai', d.required_for_ai,
          'withdrawable', d.withdrawable
        ) order by d.document_type, d.version
      ) filter (where d.id is not null),
      '[]'::jsonb
    )
  )
  from public.legal_documents d
  where d.status = 'active';
$$;

create or replace function public.complete_my_registration(
  age_14_plus_attested boolean,
  displayed_document_ids uuid[] default '{}'::uuid[],
  accepted_document_ids uuid[] default '{}'::uuid[],
  analytics_enabled boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_user_id uuid := auth.uid();
  displayed_ids uuid[] := coalesce(displayed_document_ids, '{}'::uuid[]);
  accepted_ids uuid[] := coalesce(accepted_document_ids, '{}'::uuid[]);
  current_profile public.profiles%rowtype;
begin
  if current_user_id is null then
    raise exception 'UNAUTHENTICATED';
  end if;
  if coalesce(age_14_plus_attested, false) is not true then
    raise exception 'AGE_ATTESTATION_REQUIRED';
  end if;

  select * into current_profile
    from public.profiles
    where id = current_user_id;
  if current_profile.account_status = 'suspended' then
    raise exception 'ACCOUNT_SUSPENDED';
  end if;

  if exists (
    select 1
      from unnest(accepted_ids) accepted_id
     where not (accepted_id = any(displayed_ids))
  ) then
    raise exception 'ACCEPTED_DOCUMENT_NOT_DISPLAYED';
  end if;

  if exists (
    select 1
      from unnest(displayed_ids) displayed_id
     where not exists (
       select 1 from public.legal_documents d
        where d.id = displayed_id and d.status = 'active'
     )
  ) then
    raise exception 'DISPLAYED_DOCUMENT_NOT_ACTIVE';
  end if;

  if exists (
    select 1
      from public.legal_documents d
     where d.status = 'active'
       and d.required_for_registration
       and d.interaction in ('acceptance_required', 'consent_required')
       and not (d.id = any(accepted_ids))
  ) then
    raise exception 'REGISTRATION_REQUIREMENTS_INCOMPLETE';
  end if;

  insert into public.profiles(id, updated_at, last_active_at)
  values (current_user_id, now(), now())
  on conflict (id) do update
    set updated_at = now(), last_active_at = now();

  insert into public.user_entry_records(user_id, age_14_plus_attested_at)
  values (current_user_id, now())
  on conflict (user_id) do update
    set age_14_plus_attested_at = excluded.age_14_plus_attested_at,
        updated_at = now();

  insert into public.privacy_preferences(user_id, analytics_enabled)
  values (current_user_id, coalesce(analytics_enabled, false))
  on conflict (user_id) do update
    set analytics_enabled = excluded.analytics_enabled, updated_at = now();

  insert into public.user_consent_events(user_id, legal_document_id, action, source)
  select current_user_id, d.id, 'accepted', 'app'
    from public.legal_documents d
   where d.status = 'active'
     and d.id = any(accepted_ids);

  return jsonb_build_object(
    'api_contract_version', 1,
    'registered', true,
    'user_id', current_user_id,
    'accepted_document_ids', to_jsonb(accepted_ids),
    'analytics_enabled', coalesce(analytics_enabled, false)
  );
end;
$$;

revoke all on function public.get_public_registration_requirements() from public;
grant execute on function public.get_public_registration_requirements() to anon, authenticated;
revoke all on function public.complete_my_registration(boolean, uuid[], uuid[], boolean) from public, anon;
grant execute on function public.complete_my_registration(boolean, uuid[], uuid[], boolean) to authenticated;
