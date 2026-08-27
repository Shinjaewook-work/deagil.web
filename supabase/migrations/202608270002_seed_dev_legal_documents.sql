-- Development legal documents required for end-to-end registration testing.
-- Owner/legal review must replace the copy and version before production.

insert into public.legal_documents(
  id, document_type, version, status, title, public_url, interaction,
  required_for_registration, required_for_ai, withdrawable, effective_at
) values
  (
    '10000000-0000-4000-8000-000000000001', 'terms', 'dev-v1', 'active',
    '서비스 이용약관에 동의합니다.',
    'https://nbdgwssdikmzitebqwkq.supabase.co/functions/v1/legal-documents?document=terms',
    'acceptance_required', true, false, false, now()
  ),
  (
    '10000000-0000-4000-8000-000000000002', 'privacy', 'dev-v1', 'active',
    '개인정보 활용에 동의합니다.',
    'https://nbdgwssdikmzitebqwkq.supabase.co/functions/v1/legal-documents?document=privacy',
    'consent_required', true, false, true, now()
  ),
  (
    '10000000-0000-4000-8000-000000000003', 'ai_processing', 'dev-v1', 'active',
    'AI 개인화 처리에 동의합니다.',
    'https://nbdgwssdikmzitebqwkq.supabase.co/functions/v1/legal-documents?document=ai',
    'consent_required', true, true, true, now()
  )
on conflict (document_type, version) do update
set status = excluded.status,
    title = excluded.title,
    public_url = excluded.public_url,
    interaction = excluded.interaction,
    required_for_registration = excluded.required_for_registration,
    required_for_ai = excluded.required_for_ai,
    withdrawable = excluded.withdrawable,
    effective_at = excluded.effective_at;
