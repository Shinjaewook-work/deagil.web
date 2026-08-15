# Database & API Contract — v8 Compact

Master Sections 32–47이 최종 권한.

## Result Access

별도 mutable `unlock_status` 없음.

```text
can_read_fortune =
  entitlement_status != none
  AND generation_status = ready
  AND fortune_payload IS NOT NULL
  AND session.fortune_date = current_server_fortune_date
  AND server_now < expires_at
```

## Tables

### profiles

```text
id UUID PK/FK auth.users.id ON DELETE CASCADE
nickname varchar(30) nullable
account_status active|suspended
created_at
updated_at
last_active_at
```

### user_entry_records

```text
user_id UUID PK/FK
age_14_plus_attested_at
created_at
updated_at
```

Server-only write.

### legal_documents

```text
id UUID PK
document_type
version
status draft|active|retired
title
public_url
interaction acceptance_required|consent_required|notice_only|link_only
required_for_registration bool
required_for_ai bool
withdrawable bool
provider_set_version nullable
content_sha256 nullable
effective_at
created_at
UNIQUE(document_type,version)
```

### user_consent_events

Append-only:

```text
id bigint PK
user_id UUID FK
legal_document_id UUID FK
action accepted|withdrawn
event_at
source app|web
```

`accept → withdraw → re-accept` 가능.
`UNIQUE(user,document)` 금지.

### privacy_preferences

```text
user_id UUID PK/FK
analytics_enabled bool default false
updated_at
```

### birth_profiles

```text
user_id UUID PK/FK
calendar_type solar|lunar
is_leap_month bool
birth_date date
birth_time time nullable
birth_time_precision exact|approximate|unknown
birth_country_code char(2)
birth_city varchar(80)
created_at
updated_at
```

Constraints:

```text
unknown → birth_time IS NULL
solar → is_leap_month=false
```

Write = validated server RPC only.

### notification_preferences

```text
user_id UUID PK/FK
enabled bool
notification_time time
prompt_status never_asked|enabled|declined
updated_at
```

### daily_fortune_sessions

```text
id UUID PK
user_id UUID FK ON DELETE CASCADE
fortune_date date

generation_status not_started|generating|recovery_pending|ready|failed
entitlement_status none|earned_reward|earned_pass
entitlement_pass_id UUID nullable

provider_request_count int default 0
recovery_round_count int default 0
next_retry_at timestamptz nullable

generation_request_id UUID UNIQUE
generation_epoch bigint default 0
generation_lease_until timestamptz nullable

provider_set_version text
prompt_version text
successful_provider_id text nullable
successful_model_name text nullable
provider_request_id text nullable
last_provider_error_class text nullable

generation_input_snapshot jsonb nullable
fortune_payload jsonb nullable

active_ad_attempt_id UUID nullable
active_ad_lease_until timestamptz nullable

generated_at nullable
generation_started_at nullable
last_generation_failure_at nullable
fulfillment_missed_at nullable
missed_reason text nullable

goodwill_compensation_status none|issued|skipped_cap|not_applicable
goodwill_compensation_pass_id UUID nullable

expires_at
metadata_delete_after
created_at
updated_at

UNIQUE(user_id,fortune_date)
```

### ad_attempts

```text
id UUID PK
user_id UUID FK
session_id UUID FK
fortune_date date

prepare_request_id UUID UNIQUE
challenge_hash text UNIQUE

display_status prepared|impression|dismissed|show_failed
reward_status none|client_claimed|ssv_verified

client_impression_at nullable
client_reward_claimed_at nullable
ssv_rewarded_at nullable
ssv_verified_at nullable

transaction_id text nullable
ad_unit_id text nullable
reward_item text nullable
reward_amount numeric nullable

invalid_ssv_count int default 0
last_invalid_ssv_at nullable

created_at
expires_at
```

`transaction_id` partial unique when non-null.
TTL 7 days.

### fortune_passes

```text
id UUID PK
user_id UUID FK
source api_failure|admin|promotion
status available|reserved|redeemed|expired
valid_from_fortune_date date
expires_after_fortune_date date
reserved_for_session_id UUID nullable
reserved_at nullable
redeemed_at nullable
redeemed_fortune_date date nullable
source_session_id UUID nullable UNIQUE
created_at
updated_at
```

Atomic active cap:

```text
count(status in available,reserved) <= 3
```

### ai_provider_sets

```text
version text PK
status draft|active|retired
provider_ids jsonb
created_at
activated_at nullable
```

Activated immutable.

### prompt_versions

```text
version text PK
status draft|active|retired
prompt_contract text
output_schema_version
created_at
activated_at nullable
retired_at nullable
```

Activated immutable.

### ai_generation_attempts

실제 external provider request 1건당 1행.

```text
id UUID PK
session_id
generation_epoch
attempt_ordinal
provider_id
model_name nullable
started_at
finished_at nullable
outcome
normalized_error_class nullable
provider_request_id nullable
input_tokens nullable
output_tokens nullable
estimated_cost_micros default 0
```

PII/input/output text 없음.

### ai_budget_daily

Fortune Day 기준.

```text
usage_date date PK
reserved_requests
completed_requests
estimated_cost_micros
updated_at
```

Atomic reservation.

### ai_usage_daily

```text
usage_date
provider_id
model_name nullable
prompt_version
request_count
success_count
failure_count
input_tokens nullable
output_tokens nullable
estimated_cost_micros
PRIMARY KEY(usage_date,provider_id,model_name,prompt_version)
```

## RLS / Client Access

Client own read가 필요한 최소 table만 SELECT.

```text
profiles
birth_profiles
notification_preferences
privacy_preferences
fortune_passes
```

Direct write 기본 revoke.

직접 access 금지:

```text
user_entry_records write
daily_fortune_sessions
ad_attempts
ai_*
prompt_versions
provider sets
```

## RPC

### get_my_app_state()

```json
{
  "api_contract_version": 1,
  "server_now": "...",
  "gate": "NONE",
  "fortune_state": "NO_SESSION",
  "fortune_date": "YYYY-MM-DD",
  "expires_at": "...",
  "birth_profile_exists": false,
  "available_pass_count": 0,
  "active_pass_count": 0,
  "can_prepare_rewarded_ad": true,
  "can_use_pass": false,
  "next_retry_at": null,
  "fortune_payload": null
}
```

Gate:

```text
NONE
REGISTRATION_REQUIRED
CONSENT_UPDATE_REQUIRED
AI_CONSENT_REQUIRED
ACCOUNT_SUSPENDED
```

Fortune State:

```text
NO_SESSION
LOCKED
GENERATING
REWARD_VERIFYING
RECOVERY_PENDING
READY_LOCKED
UNLOCKED
FAILED
TRANSITION_WINDOW
```

`FULFILLMENT_MISSED`는 current UI state가 아님.

### Validated write RPC

```text
set_my_profile(nickname)
upsert_my_birth_profile(payload)
set_my_notification_preferences(...)
set_my_privacy_preferences(...)
record_my_consent_event(document_id,action)
```

## Edge Surface

Client-callable:

```text
prepare-ad-session
report-ad-impression
claim-ad-reward
report-ad-dismissed
use-fortune-pass
resume-fortune-generation
delete-account
```

Webhook:

```text
admob-ssv
```

**Client-callable `start-fortune-generation` endpoint 금지.**

## prepare-ad-session

Preconditions:

```text
authenticated
account active
registration/legal gate satisfied
birth exists
not transition
current result not readable
no entitlement already exists
provider system available enough to offer service
ad attempt/day caps not exceeded
no active unexpired ad lease
```

**Pass 3/3은 rejection 조건이 아님.**

Success:

```text
session create/find
ad_attempt create
opaque SSV token return + hash store
active ad pointer/lease set
NO AI CALL
```

## report-ad-impression

```text
fast         → generation ensure
reward_gated → record only
ssv_strict   → record only
```

## claim-ad-reward

```text
fast/reward_gated:
  client_claimed
  entitlement=earned_reward
  generation ensure

ssv_strict:
  client_claimed only
  REWARD_VERIFYING
  entitlement not yet granted
```

Idempotent.

## report-ad-dismissed

```text
record dismissed
clear active pointer if same attempt
NO reward mutation
NO entitlement mutation
```

Fast mode ready + no reward → READY_LOCKED.

## use-fortune-pass

Transaction:

```text
available → reserved
entitlement=earned_pass
entitlement_pass_id=pass.id
freeze input/provider/prompt
ensure generation
```

Temporary provider failure → pass stays reserved.

## resume-fortune-generation

Only:

```text
owner
entitlement exists
recovery_pending
next_retry_at <= now
same Fortune Day
required AI processing allowed
```

No ad/pass change.

## Generation Fencing

```text
claim transaction:
  generation_epoch += 1
  lease grant

worker commit:
  session + generation_epoch still matches
```

Stale worker cannot overwrite newer result.

## 04:00 Settlement

Reward entitlement unfulfilled:

```text
fulfillment_missed_at
active pass <3 → goodwill pass max 1
active pass=3 → no fourth pass
```

Pass entitlement unfulfilled:

```text
reserved → available
expiry +1 Fortune Day
```

Consent-withdrawal reason:

```text
missed_reason=user_consent_withdrawn
no automatic service-failure goodwill pass
```

Then payload/input purge → new-day NO_SESSION.
