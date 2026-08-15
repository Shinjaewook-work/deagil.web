# Test Plan — v8 Compact

Master Section 68이 최종 기준.

## Unit

```text
Fortune Day / transition boundary
state derivation
Gate derivation
latest consent event state
pass active cap
pass expiry extension
provider error normalization
output schema/content validation
cat voice rules
```

## Widget

```text
Social Login/legal gate
Cat Home pass 0/1/3
Birth profile
Reward choice
Ad loading/failure
REWARD_VERIFYING
GENERATING
RECOVERY_PENDING
READY_LOCKED
Result
Transition
Settings/privacy
```

## P0 Auth / Legal

```text
age checkbox 없음 → login disabled
required legal action 없음 → login disabled
OAuth 중 legal version change → update gate
consent withdraw → new AI/ad/pass blocked
same-day re-consent + prior entitlement → no second ad
birth write bypass attempt → server reject
```

## P0 Ad

```text
app open → external AI 0
ad load → external AI 0
fast impression → one generation owner
reward_gated impression → AI 0
ssv_strict client reward → REWARD_VERIFYING, AI 0
valid SSV strict → entitlement + generation
dismiss no reward + ready → READY_LOCKED
later reward on READY_LOCKED → existing result, no regeneration
pass 3/3 → Rewarded route visible and allowed
multi-device prepare → one active lease
double CTA → one prepare
```

## P0 Reward / Entitlement

```text
reward claim repeated → one entitlement
network loss after reward → local marker retry idempotent
entitlement exists → new prepare/pass blocked
provider failure after reward → RECOVERY_PENDING
RECOVERY_PENDING → no second ad/pass
```

## P0 Provider

```text
client provider_id rejected/ignored
client base_url rejected/ignored
Mock provider impossible in prod
unapproved provider impossible in prod
oversized response rejected
schema invalid rejected
HTML/script response never executes
birth_city injection treated as data
stale generation worker cannot overwrite newer epoch
provider request cap atomic
```

## P0 Pass

```text
available→reserved atomic
two devices reserve same pass → one wins
available+reserved never >3
provider recovery → pass remains reserved
04:00 unfulfilled pass → restore + expiry +1 Fortune Day
reward fulfillment missed + active pass<3 → max one goodwill pass
active pass=3 → no fourth pass
```

## P0 Time

```text
03:54:59 normal
03:55:00 new ad/pass/generation blocked
03:59:59 current result readable
04:00 old result inaccessible
old missed metadata does not replace new-day Cat Home
late SSV does not resurrect old Fortune
```

## P0 Security

```text
User A cannot read/write B
ready payload without entitlement not returned
anonymous user endpoints rejected
invalid SSV → no mutation
duplicate transaction → idempotent
stale deleted-user JWT → no privileged write
client contains no provider/server secrets
SECURITY DEFINER grants/search_path verified
no arbitrary provider URL
```

## P0 Privacy

```text
Analytics/Crash native default OFF
opt-in only after preference
pre-opt-in unsent crash handling verified with current Firebase API
no PII/Fortune telemetry
withdraw/re-consent works
```

## Bug Workflow

```text
reproduce
→ failing regression
→ confirm fail
→ minimal fix
→ pass
→ related suite
→ ERROR_LOG
```

Flaky rerun-until-pass 금지.

## UI Visual Evidence

주요 화면은 가능하면 emulator/device screenshot으로 QA.
Compile 성공만으로 UI Task DONE 처리하지 않는다.
