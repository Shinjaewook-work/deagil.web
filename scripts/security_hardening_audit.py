#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

migrations = list((ROOT / 'supabase' / 'migrations').glob('*.sql'))
if not migrations:
    errors.append('no Supabase migration found')
else:
    migration = '\n'.join(path.read_text(encoding='utf-8', errors='ignore') for path in migrations)
    required = [
        'enable row level security',
        'revoke all on table public.user_entry_records',
        'revoke insert, update, delete on table public.profiles',
        'security definer set search_path = public, pg_temp',
        'auth.uid() is null',
        'grant execute on function public.upsert_my_birth_profile(jsonb) to authenticated',
    ]
    for phrase in required:
        if phrase.lower() not in migration.lower():
            errors.append(f'migration missing security invariant: {phrase}')
    if 'unlock_status' in migration.lower():
        errors.append('forbidden mutable unlock_status found in migration')

source_roots = [ROOT / 'daegil_app' / 'lib', ROOT / 'lib']
secret_patterns = [
    r'\b(?:SUPABASE_SERVICE_ROLE|SUPABASE_SECRET|OPENAI_API_KEY|ANTHROPIC_API_KEY)\b',
    r'-----BEGIN (?:RSA |EC |OPENSSH |PRIVATE )?PRIVATE KEY-----',
]
for source_root in source_roots:
    if not source_root.exists():
        continue
    for path in source_root.rglob('*.dart'):
        text = path.read_text(encoding='utf-8', errors='ignore')
        for pattern in secret_patterns:
            if re.search(pattern, text, re.IGNORECASE):
                errors.append(f'client secret pattern: {path.relative_to(ROOT)}')
        if 'unlock_status' in text.lower():
            errors.append(f'forbidden unlock_status: {path.relative_to(ROOT)}')
        if re.search(r'https://[^"\']*(openai|anthropic|generativelanguage)', text, re.IGNORECASE):
            errors.append(f'direct AI provider URL: {path.relative_to(ROOT)}')

for path in (ROOT / 'daegil_app' / 'lib').rglob('*.dart'):
    text = path.read_text(encoding='utf-8', errors='ignore')
    if any(token in text for token in ('Supabase.instance.client', 'RewardedAd.load', 'FirebaseAnalytics.instance')):
        if any(name in path.name.lower() for name in ('screen', 'page', 'view', 'widget')):
            errors.append(f'direct SDK call in UI: {path.relative_to(ROOT)}')

for required_file in [
    ROOT / 'daegil_app' / 'lib' / 'features' / 'fortune' / 'domain' / 'fortune_generation.dart',
    ROOT / 'daegil_app' / 'lib' / 'features' / 'passes' / 'domain' / 'fortune_pass_ledger.dart',
    ROOT / 'daegil_app' / 'lib' / 'features' / 'ads' / 'domain' / 'ssv_verification.dart',
]:
    if not required_file.exists():
        errors.append(f'missing hardening boundary: {required_file.relative_to(ROOT)}')

if errors:
    for error in errors:
        print(f'ERROR: {error}')
    print(f'FAIL: {len(errors)} errors')
    sys.exit(1)
print('PASS: security hardening invariants and client secret scan')
