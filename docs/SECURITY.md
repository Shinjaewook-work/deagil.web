# Security Contract — v8 Compact

Master가 우선한다.

## Trust Boundary

Untrusted:

```text
Flutter client
device clock
client ad callbacks
user-entered strings
AI provider output
public Internet requests
```

Trusted only after verification:

```text
Postgres constraints/transactions
authenticated ownership checks
server config
verified Google SSV
approved AI adapter
```

## Client Secrets

Flutter/public repo 금지:

```text
Supabase secret/admin/service-role credential
AI provider API key/token
OAuth private secret/key
Apple private key
server HMAC/signing secret
```

Mobile = publishable client key only.
Admin/secret credential은 RLS를 우회하므로 narrow backend operation에서만 사용.

## RLS

API-exposed tables RLS.
Direct client write 기본 revoke.

Client cannot:

```text
set entitlement
set generation state
issue pass
change attempts
read locked payload
read another user
modify provider/prompt/budget
```

### SECURITY DEFINER

필요 시:

```text
explicit safe search_path
schema-qualified relations
dynamic SQL 회피
public/anon EXECUTE revoke
minimum grant
auth.uid() ownership re-check
```

가능하면 SECURITY INVOKER.

## Edge Auth

Implementation day current Supabase official docs 재확인.

```text
prepare-ad-session          user JWT
report-ad-impression        user JWT
claim-ad-reward             user JWT
report-ad-dismissed         user JWT
use-fortune-pass            user JWT
resume-fortune-generation   user JWT
delete-account              user JWT + fresh liveness where needed
admob-ssv                   public at Supabase auth layer + Google signature
cron/cleanup                named server secret
```

Blanket auth setting 금지.
삭제된 user의 stale JWT가 privileged mutation을 하지 못하게 필요한 경로에서 fresh liveness 확인.

## AD_SECURITY_MODE

Server-only one preset:

```text
fast
reward_gated
ssv_strict
```

별도 독립 trust/trigger flags 금지.

### fast

```text
impression → generation 가능
client reward → optimistic entitlement
SSV → audit
```

### reward_gated

```text
reward → entitlement + generation
SSV → audit
```

### ssv_strict

```text
client reward → REWARD_VERIFYING
valid SSV → entitlement + generation
```

Invalid/missing mode → production fail closed.

## Ad Lease / Abuse

같은 user/Fortune Day active show attempt 1개.

Controls:

```text
prepare rate limit
ad attempts/day cap
one active lease
claim idempotency
provider budget
SSV mismatch telemetry
```

Client callback을 cryptographic proof로 보지 않는다.

## SSV

Public `admob-ssv`.

Rules:

```text
GET only
bounded query/URI length
original signed content 보존
key_id/public-key lookup
signature verify first
semantic parse after successful signature
custom_data percent-decode exactly once
opaque token hash match
transaction_id unique
expected ad_unit_id
expected reward item/amount
timestamp sanity
idempotent reconciliation
```

금지:

```text
source IP auth
query user_id trust
invalid callback이 pending challenge를 terminal consume
unknown key_id key-refresh flood
직접 ECDSA/JWT crypto 구현
```

Current Google docs의 vetted verification path 사용.

## OAuth

Current provider/Supabase docs 사용.

```text
PKCE where applicable
state
nonce where required
exact redirect allowlist
no arbitrary post-login return URL
no token logging
```

Production에서는 owned App Links/Universal Links 우선 검토.

Logout 제품 의도:

```text
현재 device/session만 로그아웃
```

SDK default에 의존하지 않고 local/current-session scope를 명시.

## Account Deletion

In-app double confirmation.

```text
fresh active-user check where required
personal app data delete
Auth user delete
current device local notification cancel
late worker/webhook → terminal no-op
```

Apple login 사용자는 current Sign in with Apple deletion/token-revocation guidance 확인.
Provider token unavailable이어도 app account deletion을 막지 않는다.

Public `/account-deletion`:

```text
HTTPS
state
PKCE
exact callback
same-provider identity resolution
no open redirect
```

## Consent / Privacy

`legal_documents` = server current version.
`user_consent_events` = append-only.

```text
accept → withdraw → accept again
```

AI consent가 actual legal basis이며 withdrawable이면 철회 즉시:

```text
new ad/pass/AI blocked
required personalization data purge according to policy
```

Earned entitlement metadata는 보존.
같은 날 re-consent + birth re-entry 후 추가 광고 없이 recovery 가능.

법적 근거가 consent가 아닌 경우 억지 withdrawal flow를 만들지 않는다.
Release 시 실제 provider/data flow/current Korean law를 재검토.

## Firebase

Native default:

```text
Analytics OFF
Crashlytics automatic collection OFF
```

Opt-in 후만 enable.
Crashlytics는 collection OFF 상태에서도 unsent crash가 남을 수 있으므로 current API가 지원하면:

```text
pre-consent unsent reports delete
→ collection enable
```

Opt-out 시 disable + supported unsent cleanup.

Telemetry 금지:

```text
birth date/time/city
nickname
email
raw UUID
fortune text
prompt
AI response
provider secret/token
```

## AI Security

모든 Provider:

```text
Flutter → backend → approved ProviderAdapter
```

무료/no-key도 동일.

No arbitrary:

```text
provider
model
base URL
fallback order
```

User text = data, not instruction.
Birth city etc. server validation:

```text
NFKC
trim
single-line
length bound
control chars reject
unexpected URL-like value reject
```

AI tools:

```text
web OFF
tools OFF
function calling OFF
code execution OFF
file access OFF
```

Provider output untrusted:

```text
response byte limit
timeout
JSON parse
local schema validation
content validation
plain-text render
```

Raw HTML/WebView execution 금지.

## Network

```text
HTTPS only
no global Android cleartext
no broad iOS ATS exception
no TLS certificate verification disable
no certificate pinning by default
```

## Local Storage

Allowed:

```text
Supabase auth session through current SDK strategy
OS notification schedule
non-sensitive pending reward marker:
  ad_attempt_id
  fortune_date
  claimed_at
```

Forbidden persistent local:

```text
fortune payload
generation input snapshot
birth duplicate DB
prompt/AI response
SSV custom_data token after lifecycle
provider secret
```

## Supply Chain

Critical dependency categories:

```text
Auth/OAuth
Crypto/SSV
Secure storage
Networking
WebView
```

Prefer official/vendor-maintained packages.
Commit lockfiles.
Review unexpected dependency/permission changes.
Do not copy-paste crypto primitives.
