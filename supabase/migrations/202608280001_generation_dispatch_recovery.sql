-- Keep a generation session recoverable when an Edge Function cannot dispatch
-- the internal generation worker after the entitlement transaction commits.

create or replace function public.mark_generation_dispatch_failed(
  session_id_value uuid,
  generation_epoch_value bigint
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  session_row public.daily_fortune_sessions%rowtype;
  next_status text;
begin
  select * into session_row
  from public.daily_fortune_sessions
  where id = session_id_value
    and generation_epoch = generation_epoch_value
  for update;

  if session_row.id is null or session_row.generation_status <> 'generating' then
    return false;
  end if;

  next_status := case
    when session_row.entitlement_status = 'none' then 'failed'
    else 'recovery_pending'
  end;

  update public.daily_fortune_sessions
  set generation_status = next_status,
      last_provider_error_class = 'worker_dispatch_failed',
      last_generation_failure_at = now(),
      next_retry_at = case
        when next_status = 'recovery_pending' then now() + interval '5 minutes'
        else null
      end,
      updated_at = now()
  where id = session_row.id;

  return true;
end;
$$;

revoke all on function public.mark_generation_dispatch_failed(uuid, bigint)
  from public, anon, authenticated;
grant execute on function public.mark_generation_dispatch_failed(uuid, bigint)
  to service_role;
