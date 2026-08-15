#!/usr/bin/env python3
from pathlib import Path
import re, sys

ROOT=Path(__file__).resolve().parents[1]
errors=[]

public_roots=['lib','android','ios','web']
secret_patterns=[
    (r'\bsb_secret_[A-Za-z0-9._-]+','Supabase secret key'),
    (r'SUPABASE_SERVICE_ROLE','legacy service role'),
    (r'SUPABASE_SECRET','Supabase secret env'),
    (r'OPENAI_API_KEY','OpenAI secret env'),
    (r'ANTHROPIC_API_KEY','Anthropic secret env'),
    (r'GEMINI_API_KEY|GOOGLE_GENERATIVE_AI_API_KEY','Google AI secret env'),
    (r'AI_PROVIDER_[A-Z0-9_]+_(?:KEY|TOKEN|SECRET|CREDENTIAL)','generic AI provider secret'),
    (r'-----BEGIN (?:RSA |EC |OPENSSH |PRIVATE )?PRIVATE KEY-----','private key material'),
]

for rel in public_roots:
    base=ROOT/rel
    if not base.exists(): continue
    for p in base.rglob('*'):
        if not p.is_file() or p.suffix.lower() in {'.png','.jpg','.jpeg','.gif','.mp4','.webp','.ico'}: continue
        txt=p.read_text(encoding='utf-8',errors='ignore')
        for pat,label in secret_patterns:
            if re.search(pat,txt,re.I):
                errors.append(f'{label}: {p.relative_to(ROOT)}')
        if p.suffix.lower() in {'.pem','.p8','.key'}:
            errors.append(f'private key file in client/public tree: {p.relative_to(ROOT)}')
        if p.suffix=='.dart':
            # Direct provider URLs in Flutter are prohibited.
            if re.search(r'https://[^\"\']*(openai|anthropic|generativelanguage|api\.[A-Za-z0-9.-]*ai)',txt,re.I):
                errors.append(f'possible direct AI provider URL in Flutter: {p.relative_to(ROOT)}')
            if any(x in p.name.lower() for x in ['screen','page','view','widget']):
                if 'Supabase.instance.client' in txt:
                    errors.append(f'direct Supabase access in UI: {p.relative_to(ROOT)}')
                if 'RewardedAd.load' in txt:
                    errors.append(f'direct RewardedAd SDK use in UI: {p.relative_to(ROOT)}')
                if 'FirebaseAnalytics.instance' in txt:
                    errors.append(f'direct Firebase Analytics use in UI: {p.relative_to(ROOT)}')

for e in errors: print('ERROR:',e)
if errors:
    print(f'FAIL: {len(errors)} errors')
    sys.exit(1)
print('PASS')
