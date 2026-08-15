-- Development-only provider registry activation.
-- Production still requires a separate PROD_APPROVED provider review.

insert into public.ai_provider_sets(version, status, provider_ids, activated_at)
values (
  'dev-openrouter-nemotron-v1',
  'active',
  '["openrouter-nemotron-3-ultra-free"]'::jsonb,
  now()
)
on conflict (version) do update
  set status = excluded.status,
      provider_ids = excluded.provider_ids,
      activated_at = coalesce(public.ai_provider_sets.activated_at, excluded.activated_at);

insert into public.prompt_versions(version, status, prompt_contract, output_schema_version, activated_at)
values (
  'dev-prompt-v2',
  'active',
  'safe-korean-fortune-json-v1',
  'fortune-v1',
  now()
)
on conflict (version) do update
  set status = excluded.status,
      prompt_contract = excluded.prompt_contract,
      output_schema_version = excluded.output_schema_version,
      activated_at = coalesce(public.prompt_versions.activated_at, excluded.activated_at);

alter table public.daily_fortune_sessions
  alter column provider_set_version set default 'dev-openrouter-nemotron-v1';

alter table public.daily_fortune_sessions
  alter column prompt_version set default 'dev-prompt-v2';
