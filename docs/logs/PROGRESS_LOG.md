# Progress Log

### PROG-20260815-001 — Phase 0 / Repository bootstrap

**Status:** DONE
**Goal:** 기존 harness를 보존하면서 최소 Flutter scaffold와 dev/prod client config skeleton을 추가한다.

**Changed**
- Git repository를 초기화하고 계약 문서 기준 최초 커밋을 생성했다.
- Flutter entrypoint/bootstrap/app/config와 smoke test를 추가했다.
- client-visible config example과 harness contract/hash audit script를 추가했다.

**Verified**
```text
python scripts/harness_lint.py → PASS
python scripts/master_contract_audit.py → PASS
python scripts/repo_guard.py → PASS
flutter pub get → BLOCKED: flutter command not found
dart format --set-exit-if-changed . → BLOCKED: dart command not found
flutter analyze → BLOCKED: flutter command not found
flutter test → BLOCKED: flutter command not found
```

**Security / Privacy Check**
- Client config에는 publishable/test placeholder만 두고 server secret/provider credential는 넣지 않았다.
- `unlock_status`, direct AI URL, direct provider call은 추가하지 않았다.

**Manual Actions**
- NONE. Flutter SDK 설치 후 검증을 완료했다.

**Follow-up**
- Chocolatey로 Flutter 3.41.9를 설치했고, `C:\tools\flutter`를 검증 셸 PATH에 반영했다.
- const lint 1건을 수정한 뒤 native 검증을 모두 통과했다.

### PROG-20260815-002 — Phase 1 / App foundation and design

**Status:** DONE
**Goal:** Riverpod/go_router 기반 앱 foundation, Master 디자인 token, AppFailure, 공용 UI 컴포넌트를 구현한다.

**Changed**
- `flutter_riverpod`와 `go_router`를 추가했다.
- `/auth`, `/today`, `/profile/setup` 라우팅 skeleton을 추가했다.
- 동양풍 색상·간격·반경·타이포그래피 token과 Material 3 theme을 추가했다.
- `AppFailure`, `LunaCard`, `LunaPrimaryButton` 공용 기반을 추가했다.
- bootstrap에서 ProviderScope와 router를 연결했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS: No issues found
flutter test → PASS: 3 tests
python scripts/harness_lint.py → PASS
python scripts/master_contract_audit.py → PASS
python scripts/repo_guard.py → PASS
```

**Security / Privacy Check**
- 화면은 직접 Supabase/AdMob/AI provider를 호출하지 않는다.
- 외부 credential, provider URL, PII는 추가하지 않았다.

**Manual Actions**
- NONE

**Follow-up**
- Phase 2에서 authoritative DB schema, Fortune Day functions, RLS, validated RPC 계약을 구현한다.

### PROG-20260815-003 — Phase 2 / Supabase DB contract skeleton

**Status:** PARTIAL
**Goal:** Master DB schema, Fortune Day functions, validated write RPCs, app-state RPC, and RLS boundary를 추가한다.

**Changed**
- Supabase migration에 profile/legal/consent/birth/session/ad/pass/provider/budget tables를 추가했다.
- Korea Fortune Day 중앙 함수와 `get_my_app_state()`를 추가했다.
- birth/profile/privacy/notification/consent validated RPC를 추가했다.
- own-read RLS와 server-owned table direct access revoke를 추가했다.
- Supabase local config skeleton을 추가했다.

**Verified**
```text
python scripts/harness_lint.py → PASS
python scripts/master_contract_audit.py → PASS
python scripts/repo_guard.py → PASS
flutter analyze → PASS
flutter test → PASS: 3 tests
Supabase db reset/RLS execution → BLOCKED: Supabase CLI and Dev project are not configured
```

**Security / Privacy Check**
- mutable `unlock_status`를 만들지 않았다.
- client direct birth/session/ad/AI writes를 grant하지 않았다.
- app state에서 fortune payload는 readable 조건을 만족할 때만 반환하도록 했다.

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Supabase Dev project URL/publishable key와 local CLI/Docker 실행 환경 준비.

**Follow-up**
- Phase 3 mock-first auth/legal UI를 구현하고, Supabase 연결 전까지 실제 OAuth credential 없이 테스트한다.

### PROG-20260815-004 — Phase 3 / Mock-first auth and legal gate

**Status:** PARTIAL
**Goal:** Server-driven legal requirement model, age gate, social provider abstraction, and login UI를 구현한다.

**Changed**
- FakeAuthRepository로 terms/AI 필수와 analytics 선택 requirement를 모델링했다.
- Riverpod AuthController가 age/legal state와 sign-in idempotent boundary를 관리한다.
- `/auth`에 카카오/Google/Apple mock buttons와 필수 동의 전 disabled gate를 추가했다.
- auth success 후 `/today`로 이동하는 router 연결을 추가했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS: 4 tests
python scripts/harness_lint.py → PASS
python scripts/master_contract_audit.py → PASS
python scripts/repo_guard.py → PASS
```

**Security / Privacy Check**
- 실제 OAuth token/credential를 저장하거나 로그하지 않는다.
- 필수 age/legal action 없이는 provider action이 호출되지 않는다.
- legal requirement는 client 고정 목록이 아니라 repository response로 공급되는 구조다.

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Google/Apple/Kakao production app IDs, redirect allowlist, provider console configuration.

**Follow-up**
- Phase 4에서 Cat Home, missing video fallback, birth form, server RPC repository boundary를 구현한다.
- Chocolatey 자동 설치는 비관리자 셸 확인 프롬프트에서 중단되었고 미완료 산출물은 남기지 않았다.

## Entry Template

### PROG-20260815-005 — Phase 4 / Cat Home and birth profile

**Status:** PARTIAL
**Goal:** Cat Home CTA, pass badge, missing-video fallback, and validated birth profile entry를 구현한다.

**Changed**
- Cat Home에 광고 패스권 0/3 badge, CTA, 설정 진입점, static cat fallback을 추가했다.
- `assets/videos/fortune_cat.mp4`가 없어도 의미가 유지되는 fallback UI를 추가했다.
- birth date/calendar/time precision/city 입력 화면과 fake server-RPC boundary를 추가했다.
- unknown birth time은 null 의미를 유지하고 city URL/control-character validation을 추가했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS: 5 tests
python scripts/harness_lint.py → PASS
python scripts/master_contract_audit.py → PASS
python scripts/repo_guard.py → PASS
```

**Security / Privacy Check**
- birth profile은 client direct table write가 아니라 controller의 RPC boundary를 통과하도록 구성했다.
- 실제 birth data/fortune payload를 persistent local storage에 저장하지 않는다.

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: owner-provided/licensed `assets/videos/fortune_cat.mp4` before release.

**Follow-up**
- Phase 5에서 RewardedAdService interface/fake, test ad configuration, prepare/impression/reward/dismiss flow를 구현한다.

### PROG-20260815-006 — Phase 4 / Cat video asset connection

**Status:** DONE
**Goal:** Owner-provided cat video를 Master asset path에 연결한다.

**Changed**
- `Cat_shaking_Omikuji_container_202608142253.mp4`를 `assets/videos/fortune_cat.mp4`로 배치했다.
- `video_player`를 추가하고 muted/autoplay/loop, lifecycle pause/resume, reduce-motion/static fallback을 연결했다.

**Verified**
```text
asset exists → PASS: 2,713,875 bytes
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS: 5 tests
```

**Manual Actions**
- NONE for current file connection. Release 전 asset license/codec 검토는 owner release gate다.

**Follow-up**
- Phase 5 Rewarded Ad flow로 진행한다.

### PROG-20260815-007 — Phase 5 / Rewarded Ad service and fake flow

**Status:** PARTIAL
**Goal:** RewardedAdService interface/fake, test ad configuration, prepare/impression/reward/dismiss flow, pending reward boundary, and the single AD_SECURITY_MODE preset을 구현한다.

**Changed**
- `RewardedAdService` 추상화와 개발용 `FakeRewardedAdService`를 추가했다.
- Master의 Google Rewarded test unit ID를 dev fake configuration에 연결했다.
- preload → prepare-ad-session → opaque custom_data → show → impression → reward claim → dismiss 이벤트 순서를 모델링했다.
- `fast`, `reward_gated`, `ssv_strict` typed mode를 추가하고 strict mode에서는 server verification 전 claim하지 않도록 했다.
- pending reward retry boundary와 Cat Home CTA 상태 표시를 연결했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS: No issues found
flutter test → PASS: 6 tests
```

**Security / Privacy Check**
- 실제 광고 SDK, credential, SSV secret, user/fortune data를 호출하거나 저장하지 않는다.
- custom_data는 fake opaque token이며 실제 identity/PII를 포함하지 않는다.
- 3/3 pass 상태를 광고 차단 조건으로 사용하지 않는다.
- `AD_SECURITY_MODE`는 단일 enum으로만 노출한다.

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: production AdMob app/unit IDs와 실제 모바일 SDK/콘솔 설정은 Phase 14 external integration에서 owner가 제공·승인해야 한다.

**Follow-up**
- Phase 6에서 MockFortuneProvider, ProviderRouter, strict schema/content validation, generation fencing, budget/recovery 구조를 구현한다.

### PROG-YYYYMMDD-NNN — <Phase/Task>

**Status:** DONE | PARTIAL | BLOCKED  
**Goal:**

**Changed**
- ...

### PROG-20260815-010 — Phase 8 / pass ledger rules

**Status:** PARTIAL
**Goal:** Pass reserve/redeem/restore/expiry/goodwill compensation 규칙을 구현한다.

**Changed**
- `available`, `reserved`, `redeemed`, `expired` 상태와 active cap 3을 추가했다.
- 기존 available pass의 reserve는 active 수를 늘리지 않고, goodwill 발급만 cap을 증가시키도록 했다.
- reserved pass는 provider recovery 중 유지되고 missed Fortune Day settlement에서 available로 복구된다.
- 복구 시 `expires_after_fortune_date`를 1 Fortune Day 연장한다.
- active pass가 3이면 goodwill 네 번째 pass를 발급하지 않는다.
- 만료된 available pass는 reserve할 수 없게 했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS: No issues found
flutter test → PASS: 17 tests
```

**Security / Privacy Check**
- client가 임의 pass 상태나 만료일을 직접 DB에 쓰는 API를 만들지 않았다.
- active cap은 ledger 경계에서 검증한다.
- Reward entitlement와 goodwill pass를 동일한 상태로 재사용하지 않는다.

**Manual Actions**
- NONE for mock/domain rules.

**Follow-up**
- Supabase reserve/redeem/restore transaction과 실제 UI/pass badge 연결은 DB integration 단계에서 이어간다.

### PROG-20260815-009 — Phase 7 / SSV webhook contract

**Status:** PARTIAL
**Goal:** Public SSV webhook validation, signature verifier boundary, custom_data matching, transaction replay protection, and late callback handling을 구현한다.

**Changed**
- GET-only, bounded URI, required field, timestamp sanity validation을 추가했다.
- 실제 ECDSA를 직접 구현하지 않고 `SsvSignatureVerifier` 주입 경계를 만들었다.
- `custom_data`를 exactly-once decode하고 server-side digest/token store와 매칭한다.
- `transaction_id` replay를 idempotent duplicate로 처리한다.
- 만료 후 callback은 `lateCompensationOnly`로 분리해 이전 Fortune을 부활시키지 않는다.
- AdMob 공식 SSV 문서 확인 내용을 `docs/EXTERNAL_SETUP.md`에 기록했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS: No issues found
flutter test → PASS: 13 tests
```

**Security / Privacy Check**
- source IP를 인증 수단으로 사용하지 않는다.
- invalid callback은 transaction을 소비하지 않는다.
- signature crypto와 key fetching은 vetted server library/Edge Function 통합 경계 뒤로 남겼다.
- callback/query, signature, token, user/fortune data를 로그하지 않는다.

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: production AdMob SSV URL, AdMob app/unit configuration, and vetted server-side ECDSA library selection/deployment.

**Follow-up**
- Phase 8에서 pass reserve/redeem/restore/expiry/goodwill compensation 구조를 구현한다.

### PROG-20260815-008 — Phase 6 / Mock Provider architecture

**Status:** DONE
**Goal:** MockFortuneProvider, ProviderRouter, strict schema/content validators, generation fencing, and provider budget을 구현한다.

**Changed**
- 결정적인 strict JSON을 반환하는 `MockFortuneProvider`를 추가했다.
- provider chain과 payload schema/content validation을 추가했다.
- 32KB response bound, required text/number validation, script/iframe/object markup 차단을 적용했다.
- `GenerationFence`로 최신 epoch만 결과를 commit할 수 있게 했다.
- `ProviderBudget`으로 session provider request cap을 원자적 reserve 경계로 표현했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS: No issues found
flutter test → PASS: 10 tests
```

**Security / Privacy Check**
- Flutter에서 외부 AI provider를 호출하지 않는다.
- client provider ID/base URL/credential 입력 경로를 만들지 않았다.
- Mock provider는 실제 birth data나 fortune payload를 외부로 전송하지 않는다.
- 고정 AI 2회 제품 invariant를 만들지 않았다.

**Manual Actions**
- NONE for development mock architecture.

**Follow-up**
- Phase 7에서 Supabase SSV webhook 계약과 signature/replay/late-callback 처리 구조를 구현한다. 실제 AdMob 키·콘솔 연결은 production integration manual action으로 유지한다.

**Verified**
```text
command → exit/result
```

**Security / Privacy Check**
- ...

**Manual Actions**
- NONE / ...

**Follow-up**
- ...
