# Release Checklist — v8 Compact

## Master / Build

- [ ] `LUNA_IMPLEMENTATION_MASTER.md` 구현 완료
- [ ] harness lint pass
- [ ] repo guard pass
- [ ] format/analyze/test pass
- [ ] Mock Provider prod에서 불가
- [ ] placeholder production identity 없음

## Identity / External

- [ ] final app display name
- [ ] Android applicationId
- [ ] iOS Bundle ID / Apple Team
- [ ] Supabase prod
- [ ] Kakao
- [ ] Google
- [ ] Apple
- [ ] Firebase prod
- [ ] AdMob prod
- [ ] AI Provider `PROD_APPROVED`
- [ ] privacy/terms/account-deletion URLs

## Reward / Entitlement

- [ ] 3/3에서 Rewarded option 보임
- [ ] explicit action/reward disclosure
- [ ] fast mode tested
- [ ] reward_gated tested
- [ ] ssv_strict tested
- [ ] one active ad lease
- [ ] pending reward claim recovery
- [ ] SSV signature/custom_data/replay
- [ ] entitlement exists → no re-monetization
- [ ] late SSV no old Fortune resurrection

## AI Provider

- [ ] backend-only
- [ ] provider allowlist
- [ ] no arbitrary URL/model selection
- [ ] Provider security/privacy/terms review
- [ ] free Provider도 quota/cap 있음
- [ ] request timeout/response byte limit
- [ ] strict local schema
- [ ] prompt-injection boundary
- [ ] tools/web/code/file disabled
- [ ] generation epoch fencing
- [ ] no fake static personalized Fortune fallback
- [ ] 14+ content safety

## Pass

- [ ] `available + reserved <= 3`
- [ ] atomic reserve
- [ ] recovery keeps pass reserved
- [ ] 04:00 missed → restore
- [ ] restore expiry +1 Fortune Day
- [ ] active pass=3 → no fourth goodwill pass

## Time

- [ ] Fortune Day server KST
- [ ] 03:55 block
- [ ] 03:59:59 unlocked readable
- [ ] 04:00 old result inaccessible
- [ ] old missed metadata never becomes new-day UI state
- [ ] payload/input purge
- [ ] late callback settlement

## Auth / Legal

- [ ] 만14세 이상 self-attestation
- [ ] server-driven legal versions
- [ ] consent events append-only
- [ ] withdraw/re-consent tested where applicable
- [ ] birth write server validated
- [ ] logout current-session scope explicit
- [ ] stale deleted-user token no privileged mutation
- [ ] Apple deletion/token revocation current docs verified
- [ ] 14+ age-gate approach final legal/product review

## Security

- [ ] RLS adversarial tests
- [ ] SECURITY DEFINER search_path/grants
- [ ] publishable key only client
- [ ] no server/provider secret client/repo
- [ ] OAuth PKCE/state/nonce/redirect review
- [ ] public SSV endpoint bounded
- [ ] no TLS bypass/cleartext broad exception
- [ ] dependency/supply-chain review

## Firebase

- [ ] native Analytics OFF default
- [ ] native Crashlytics OFF default
- [ ] opt-in only
- [ ] pre-consent unsent crash behavior verified
- [ ] no PII/Fortune telemetry

## Notification

- [ ] Local Notification only
- [ ] fixed cat copy
- [ ] contextual permission
- [ ] no exact-alarm special permission by default
- [ ] current-device logout cancel
- [ ] reboot/timezone/update QA

## Design / Assets

- [ ] Cat Home visual QA
- [ ] Result visual QA
- [ ] no AI SaaS visual drift
- [ ] reduce-motion
- [ ] Cat video license/ownership
- [ ] font/icon/image licenses

## Physical / Store

- [ ] Android clean install physical
- [ ] iOS clean install physical
- [ ] all social providers
- [ ] Rewarded/SSV flow
- [ ] notification tap
- [ ] account deletion
- [ ] 03:55 / 04:00 boundary
- [ ] App Store privacy labels match actual SDK/data flow
- [ ] Google Play Data Safety matches actual SDK/data flow
- [ ] Rewarded Ads current Google policy final review
- [ ] Korean privacy/legal copy final review
