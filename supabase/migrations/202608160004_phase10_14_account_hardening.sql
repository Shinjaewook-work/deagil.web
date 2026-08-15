-- Phase 11/13 account and consent server boundaries.

create or replace function public.withdraw_my_ai_consent()
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare current_user_id uuid := auth.uid(); withdrawn_count integer;
begin
  if current_user_id is null then raise exception 'UNAUTHENTICATED'; end if;
  insert into public.user_consent_events(user_id, legal_document_id, action, source)
  select current_user_id, d.id, 'withdrawn', 'app'
    from public.legal_documents d
   where d.status = 'active' and d.required_for_ai and d.withdrawable;
  get diagnostics withdrawn_count = row_count;
  update public.privacy_preferences set analytics_enabled = false, updated_at = now()
   where user_id = current_user_id;
  return jsonb_build_object('status', 'withdrawn', 'documents_affected', withdrawn_count);
end; $$;

revoke all on function public.withdraw_my_ai_consent() from public, anon;
grant execute on function public.withdraw_my_ai_consent() to authenticated;
