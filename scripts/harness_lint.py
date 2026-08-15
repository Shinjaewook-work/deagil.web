#!/usr/bin/env python3
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
errors=[]
warnings=[]

EXPECTED = {
    'AGENTS.md',
    'LUNA_IMPLEMENTATION_MASTER.md',
    'README.md',
    'docs/SCREEN_SPEC.md',
    'docs/DESIGN_SYSTEM.md',
    'docs/DATABASE_AND_API.md',
    'docs/SECURITY.md',
    'docs/AI_PROVIDER.md',
    'docs/TEST_PLAN.md',
    'docs/EXTERNAL_SETUP.md',
    'docs/RELEASE_CHECKLIST.md',
    'docs/CURRENT_TASK.md',
    'docs/SESSION_RESUME.md',
    'docs/logs/ERROR_LOG.md',
    'docs/logs/PROGRESS_LOG.md',
    'docs/logs/DECISION_LOG.md',
    'scripts/harness_lint.py',
    'scripts/repo_guard.py',
    'scripts/master_contract_audit.py',
    'scripts/harness_hashes.py',
    'scripts/security_hardening_audit.py',
    'scripts/release_gate_audit.py',
}

actual={
    str(p.relative_to(ROOT)).replace('\\','/')
    for p in ROOT.rglob('*')
    if p.is_file()
    and '.git' not in p.relative_to(ROOT).parts
    and '__pycache__' not in p.relative_to(ROOT).parts
    and '.dart_tool' not in p.relative_to(ROOT).parts
    and 'build' not in p.relative_to(ROOT).parts
    and 'daegil_app' not in p.relative_to(ROOT).parts
    and p.name != 'pubspec.lock'
    and p.name != '.flutter-plugins-dependencies'
}
missing=sorted(EXPECTED-actual)
allowed_project_prefixes=('lib/','test/','config/','assets/','supabase/','pubspec.yaml','analysis_options.yaml','.gitignore')
extra=sorted(
    path for path in (actual-EXPECTED)
    if not path.startswith(allowed_project_prefixes)
)
for x in missing: errors.append(f'missing expected file: {x}')
for x in extra: errors.append(f'unexpected harness file: {x}')

master=(ROOT/'LUNA_IMPLEMENTATION_MASTER.md').read_text(encoding='utf-8') if (ROOT/'LUNA_IMPLEMENTATION_MASTER.md').exists() else ''

required_master=[
    '3/3이어도 Rewarded Ad를 막지 않는다',
    'AD_SECURITY_MODE = fast | reward_gated | ssv_strict',
    'Client-callable `start-fortune-generation` endpoint는 만들지 않는다',
    'user_consent_events',
    'upsert_my_birth_profile',
    'available + reserved <= 3',
    'MockFortuneProvider',
    'RECOVERY_PENDING',
]
for phrase in required_master:
    if phrase not in master:
        errors.append(f'Master missing invariant: {phrase}')

# Current files only. Logs may mention old rules as prevention history.
current=[p for p in ROOT.rglob('*.md') if '/logs/' not in str(p).replace('\\','/')]
forbidden={
    'available_pass_count == 3`이면 rewarded-ad 선택지를 표시하지 않는다':'stale 3/3 ad block',
    'Rewarded Ad route server-side reject':'stale 3/3 ad rejection',
    '3/3에서는 rewarded route 자체를 열지':'stale 3/3 blocked route',
    '최대 2 attempts':'stale fixed AI attempt rule',
    'max 2 attempts':'stale fixed AI attempt rule',
    'REWARD_TRUST_MODE=':'unsupported independent reward mode',
    'GENERATION_TRIGGER_MODE=':'unsupported independent trigger mode',
    'birth_profiles | own SELECT/UPDATE':'stale direct birth write',
}
for p in current:
    txt=p.read_text(encoding='utf-8',errors='ignore')
    for phrase,msg in forbidden.items():
        if phrase in txt:
            errors.append(f'{msg}: {p.relative_to(ROOT)}')

# No historical document trees in compact pack.
for dirname in ['archive','product-specs','design-docs','engineering','ops','exec-plans','checklists','prompts','references','generated']:
    if (ROOT/'docs'/dirname).exists():
        errors.append(f'compact pack unexpectedly contains docs/{dirname}/')

# Explicit markdown references should resolve.
for p in current:
    txt=p.read_text(encoding='utf-8',errors='ignore')
    for m in re.finditer(r'`((?:docs|scripts)/[^`\n]+?\.(?:md|py))`',txt):
        rel=m.group(1)
        if '*' in rel:
            continue
        if not (ROOT/rel).exists():
            errors.append(f'broken reference in {p.relative_to(ROOT)}: {rel}')

# Fence balance.
for p in ROOT.rglob('*.md'):
    txt=p.read_text(encoding='utf-8',errors='ignore')
    if txt.count('```') % 2:
        errors.append(f'unbalanced markdown fence: {p.relative_to(ROOT)}')

# Master should not point to deleted old hierarchies.
for stale in ['docs/product-specs/','docs/design-docs/','docs/engineering/','docs/ops/','docs/archive/']:
    if stale in master:
        errors.append(f'Master references removed hierarchy: {stale}')

print(f'Files: {len(actual)} (contract files: {len(EXPECTED)})')
print(f'Markdown: {len(list(ROOT.rglob("*.md")))}')
for w in warnings: print('WARN:',w)
for e in errors: print('ERROR:',e)
if errors:
    print(f'FAIL: {len(errors)} errors, {len(warnings)} warnings')
    sys.exit(1)
print(f'PASS: 0 errors, {len(warnings)} warnings')
