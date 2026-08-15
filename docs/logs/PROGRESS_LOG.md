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

### PROG-20260815-027 — Release gate refresh after OAuth work

**Status:** PARTIAL
**Goal:** Google development OAuth, mobile redirect, and current emulator limitation을 반영해 release gate를 재검증한다.

**Verified**
```text
python scripts/release_gate_audit.py → PASS automated checks
python scripts/security_hardening_audit.py → PASS
client secret scan → PASS
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: final package IDs, production credentials/console setup, physical or cloud-device QA, signing/store/legal approval.
- `MANUAL_ACTION_REQUIRED`: Supabase CLI access token and live migration/RLS reset verification.

**Follow-up**
- Android emulator is blocked on this Snapdragon ARM workstation; continue mock/contract work until a physical or cloud Android device is available.

### PROG-20260815-028 — Kakao OAuth adapter preparation

**Status:** PARTIAL
**Goal:** Apple은 보류하면서 Kakao OAuth provider mapping을 준비한다.

**Changed**
- Supabase OAuth adapter가 Google과 Kakao provider를 구분해 호출하도록 확장했다.
- Kakao credential이나 console 설정은 저장·활성화하지 않았다.
- Apple은 계속 `SOCIAL_PROVIDER_NOT_CONFIGURED`로 fail-closed 상태다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Kakao Developers app key, redirect configuration, and Supabase Kakao Provider setup.
- `MANUAL_ACTION_REQUIRED`: Apple OAuth remains deferred by owner request.

### PROG-20260815-029 — Google-only authentication scope

**Status:** DONE
**Goal:** owner 지시에 따라 실제 로그인 구현 범위를 Google 하나로 제한한다.

**Changed**
- `SocialProvider`를 Google 단일 provider로 축소했다.
- Supabase adapter가 Google OAuth만 호출하도록 고정했다.
- 로그인 화면에서 Kakao/Apple 버튼을 제거했다.
- Kakao는 현재 범위 밖, Apple은 owner 요청에 따라 보류로 문서화했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Google physical/cloud-device callback QA only.

### PROG-20260815-030 — OAuth pending-session state

**Status:** DONE
**Goal:** Google OAuth browser launch와 실제 Supabase session 인증 완료를 구분한다.

**Changed**
- Auth repository가 `authenticated`와 `pending` 결과를 구분해 반환한다.
- Supabase OAuth는 callback 전까지 authenticated로 표시하지 않는다.
- Mock 로그인은 기존 테스트 편의를 위해 authenticated 결과를 반환한다.
- Auth controller에 `isAuthPending` 상태를 추가했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: physical/cloud-device callback test must confirm pending → session transition.

### PROG-20260815-031 — OAuth pending UI feedback

**Status:** DONE
**Goal:** OAuth callback 대기 상태를 사용자에게 명확히 표시하고 중복 시작을 막는다.

**Changed**
- Google 인증 callback 대기 문구를 추가했다.
- pending 상태에서는 로그인 버튼을 비활성화한다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: physical/cloud-device callback test remains pending.

### PROG-20260815-033 — Explicit development Supabase Auth mode

**Status:** DONE
**Goal:** cloud/physical Google OAuth QA가 Mock 인증과 섞이지 않도록 명시적 development Auth mode를 추가한다.

**Changed**
- `ENABLE_SUPABASE_AUTH=true`와 valid Supabase URL/publishable key가 함께 주어진 development build에서만 Supabase를 초기화한다.
- 기본 development build는 계속 Mock/Fake 인증을 사용한다.
- production fail-closed 조건은 변경하지 않았다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: cloud device reservation and Google callback QA.

**Correction**
- Development `isProductionReady` semantics are intentionally ignored for Supabase initialization; default dev remains Mock unless the explicit flag and client config are both present.

### PROG-20260815-032 — Supabase session callback wiring

**Status:** DONE
**Goal:** Google OAuth callback 이후 실제 Supabase session을 Auth controller에 반영한다.

**Changed**
- AuthRepository에 authentication change stream 계약을 추가했다.
- Supabase repository가 `onAuthStateChange`를 구독해 session 존재 여부를 전달한다.
- Auth controller가 callback session 수신 시 pending을 해제하고 authenticated 상태로 전환한다.
- subscription은 provider dispose 시 취소한다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: physical/cloud-device callback test remains pending.

### PROG-20260815-026 — Production OAuth redirect fail-closed gate

**Status:** DONE
**Goal:** production build에서 mobile OAuth callback URL 누락을 배포 전에 차단한다.

**Changed**
- custom-scheme mobile redirect URL 형식을 검증한다.
- 누락·HTTP(S)·잘못된 callback host는 `AUTH_REDIRECT_URL_INVALID`로 fail-closed 처리한다.
- production configuration regression test에 해당 gate를 추가했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS
```

**Manual Actions**
- NONE

### PROG-20260815-022 — Supabase Flutter Google OAuth adapter

**Status:** PARTIAL
**Goal:** production configuration에서만 Supabase Auth Google OAuth를 사용하고, 개발 환경은 Mock 경로를 유지한다.

**Changed**
- `supabase_flutter` 의존성을 추가했다.
- production-ready configuration에서만 Supabase를 초기화하도록 `main.dart`를 연결했다.
- Google OAuth `SupabaseAuthRepository`를 추가했다. Apple/Kakao는 아직 연결하지 않는다.
- Android/iOS custom deep-link callback scheme을 등록했다.
- mobile redirect URL을 외부 설정 문서에 기록했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS: 28 tests
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Supabase URL Configuration에 `com.example.daegil_app://login-callback/`를 Redirect URL로 추가한다.
- `MANUAL_ACTION_REQUIRED`: production build values, release signing identity, and physical Android callback test remain pending.

**Follow-up**
- 개발 환경은 계속 FakeAuthRepository를 사용한다.
- Supabase schema/session persistence와 birth profile DB binding은 별도 DB integration gate에서 진행한다.

### PROG-20260815-023 — Supabase redirect confirmation and Android build gate

**Status:** PARTIAL
**Goal:** 사용자의 mobile redirect 등록을 기록하고 Android debug build를 검증한다.

**Changed**
- 사용자가 Supabase URL Configuration에 mobile redirect URL을 추가했다.
- Windows 한글 workspace 경로에서 Android Gradle이 차단되는 환경 문제를 `android.overridePathCheck=true`로 완화했다.

**Verified**
```text
flutter devices → Windows, Chrome, Edge detected; Android device not connected
Initial APK build → BLOCKED by non-ASCII project path check
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Android physical device or emulator connection for OAuth callback QA.

### PROG-20260815-024 — Android Emulator recovery attempt

**Status:** PARTIAL
**Goal:** 휴대폰 없이 Android OAuth QA를 위해 Emulator/AVD 환경을 복구한다.

**Changed**
- Google 공식 Windows Emulator archive를 다운로드하고 SHA-1을 검증했다.
- SDK `emulator` 실행 파일을 설치했다.
- Android Studio SDK Manager의 `emulator` dependency metadata 문제를 확인했다.

**Verified**
```text
emulator.exe → installed
archive SHA-1 → f514c42b51add4015d8c4dd17a79794929ce09b1
flutter emulators → no AVD available
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: system image download/AVD creation remains pending because SDK Manager dependency resolution is still unavailable.

### PROG-20260815-025 — OAuth provider error containment

**Status:** DONE
**Goal:** 실제 Supabase Auth provider 오류가 UI 컨트롤러 밖으로 누출되지 않도록 안전한 앱 오류 코드로 변환한다.

**Changed**
- `AuthException`을 `AUTH_PROVIDER_FAILED`로 정규화해 UI 상태에 저장한다.
- provider의 원문 오류, 토큰, credential은 앱 상태나 로그에 저장하지 않는다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS
```

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

### PROG-20260815-017 — Phase 15 / release gate audit

**Status:** PARTIAL
**Goal:** Release artifact/config automated checks를 실행하고 owner-only release gates를 분리한다.

**Changed**
- `release_gate_audit.py`를 추가해 target app files, dependencies, asset declaration, non-empty cat video, and native project presence를 검사한다.
- Release checklist에 현재 automated verification record를 추가했다.
- Android/iOS `com.example...` identity는 임의 변경하지 않고 manual owner gate로 남겼다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS: 27 tests
flutter build windows → PASS
python scripts/release_gate_audit.py → PASS + manual gates listed
python scripts/security_hardening_audit.py → PASS
python scripts/repo_guard.py → PASS
python scripts/harness_lint.py → PASS
python scripts/master_contract_audit.py → PASS
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: final app/package identities, service credentials/console settings, physical devices, signing, store/legal/privacy review, and asset license approval.

**Follow-up**
- Do not claim release readiness until manual gates are configured and physical P0 matrix passes.

### PROG-20260815-016 — Phase 14 / production fail-closed integration boundary

**Status:** PARTIAL
**Goal:** Production configuration validation and external integration fail-closed boundary를 구현한다.

**Changed**
- `AppConfig`에 production identity, legal URL, AdMob, provider registry, AD_SECURITY_MODE explicit 검증을 추가했다.
- production에서 missing/placeholder Supabase, test Ad ID, placeholder package/bundle, missing policy URL, non-`PROD_APPROVED` provider를 거부한다.
- invalid production config는 bootstrap에서 안전한 설정 오류 화면으로 차단한다.
- dev environment는 credential 없이 Mock/Fake 경로를 유지한다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS: No issues found
flutter test → PASS: 27 tests
flutter build windows → PASS
python scripts/security_hardening_audit.py → PASS
python scripts/repo_guard.py → PASS
python scripts/harness_lint.py → PASS
python scripts/master_contract_audit.py → PASS
```

**Security / Privacy Check**
- production fail-open default를 만들지 않았다.
- 실제 credential/secret을 코드·로그·문서에 기록하지 않았다.
- production Mock provider와 test Ad ID 사용을 차단한다.

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Supabase Dev/Prod project and keys, Google/Apple/Kakao production OAuth, AdMob production units/SSV, Firebase native config, approved AI provider credentials/registry approval, final package IDs and legal URLs.

**Follow-up**
- Phase 15 release gate는 위 manual actions가 구성된 뒤 physical Android/iOS, store/legal, signed build 검증으로 진행한다.

### PROG-20260815-015 — Phase 13 / security and concurrency hardening

**Status:** PARTIAL
**Goal:** RLS/security invariants, concurrency boundaries, provider input/output checks, and client secret scan을 자동 검증한다.

**Changed**
- `repo_guard.py`가 실제 `daegil_app` Flutter public tree도 secret/direct-SDK scan하도록 확장했다.
- `security_hardening_audit.py`를 추가해 migration RLS, SECURITY DEFINER search_path, authenticated RPC grants, direct-write revoke를 자동 검사한다.
- `unlock_status`, client secret/private key, direct AI provider URL, UI direct SDK 호출을 검사한다.
- provider schema/output validation, SSV replay boundary, pass cap, generation fence의 존재를 hardening guard로 확인한다.

**Verified**
```text
python scripts/security_hardening_audit.py → PASS
python scripts/repo_guard.py → PASS
python scripts/harness_lint.py → PASS
python scripts/master_contract_audit.py → PASS
git diff --check → PASS
```

**Security / Privacy Check**
- 실제 secret/credential을 추가하지 않았다.
- RLS와 server-owned mutation revoke invariant를 정적 guard로 고정했다.
- 기존 generation fence, provider budget, pass cap, SSV replay 테스트를 유지한다.

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Supabase Dev reset/RLS adversarial execution, production secret scanning in CI, physical device security/network verification.

**Follow-up**
- Phase 14에서 실제 Supabase/AdMob/OAuth/approved AI provider production integration을 owner credential 범위 내에서 연결한다.

### PROG-20260815-014 — Phase 12 / analytics and crash opt-in

**Status:** PARTIAL
**Goal:** Native analytics/crash collection OFF default, explicit opt-in, normalized events, and safe crash reporting을 구현한다.

**Changed**
- Analytics/Crash service abstraction과 Fake provider를 추가했다.
- collection default OFF와 명시적 동시 opt-in controller를 추가했다.
- app/auth/fortune/result/notification/consent normalized event enum을 추가했다.
- PII, birth, fortune, prompt, token, user_id 파라미터를 거부한다.
- Crash는 message/payload 대신 bounded error code와 fatal 여부만 기록한다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS: No issues found
flutter test → PASS: 25 tests
```

**Security / Privacy Check**
- opt-in 이전에는 analytics/crash event가 저장되지 않는다.
- fortune output/prompt와 사용자 식별자를 telemetry parameter로 허용하지 않는다.
- 실제 provider SDK/자동 collection 설정은 연결하지 않았다.

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Firebase/analytics/crash production project configuration, native automatic collection OFF verification, and privacy policy finalization.

**Follow-up**
- Phase 13에서 RLS/concurrency/security hardening과 secret scan을 수행한다.

### PROG-20260815-013 — Phase 11 / settings, privacy, and account

**Status:** PARTIAL
**Goal:** Settings routes, privacy preference, consent withdrawal, logout, and account deletion contract를 구현한다.

**Changed**
- `/settings`, `/settings/profile`, `/settings/notification`, `/settings/privacy`, `/settings/account`, `/settings/account/delete` routes를 추가했다.
- analytics preference는 기본 OFF이며 사용자가 명시적으로 켤 수 있다.
- AI personalization consent withdrawal 시 AI personalization과 analytics를 함께 비활성화한다.
- logout과 account deletion Fake service 경계를 추가했다.
- Cat Home 설정 버튼을 `/settings`로 연결했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS: No issues found
flutter test → PASS: 23 tests
```

**Security / Privacy Check**
- consent withdrawal은 append-only server event/RPC 경계로 연결할 수 있는 service interface를 사용한다.
- client direct birth/account table write를 추가하지 않았다.
- account deletion 화면은 provider secret이나 arbitrary callback URL을 다루지 않는다.
- analytics default OFF 상태를 유지한다.

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: production Supabase delete-account Edge Function, OAuth provider revocation, final legal deletion copy, and physical deletion verification.

**Follow-up**
- Phase 12에서 analytics/crash provider abstraction과 opt-in event normalization을 구현한다.

### PROG-20260815-012 — Phase 10 / local notification contract

**Status:** PARTIAL
**Goal:** Local notification permission/schedule, result tap route, logout cancellation, and timezone-safe Fortune Day boundary를 구현한다.

**Changed**
- `LocalNotificationService`와 development Fake를 추가했다.
- permission denied 상태에서는 schedule을 생성하지 않는다.
- 예약 payload는 `/fortune/result`만 허용하고 unknown payload는 `/today`로 fallback한다.
- notification tap route와 logout `cancelAll` controller 경계를 추가했다.
- schedule에는 Fortune date와 local scheduled time을 함께 보존한다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS: No issues found
flutter test → PASS: 20 tests
```

**Security / Privacy Check**
- notification payload에 PII, fortune content, token을 넣지 않는다.
- arbitrary deep link/open redirect를 허용하지 않는다.
- permission 거부를 재시도 무한 루프로 만들지 않는다.

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: iOS/Android native notification permission/channel configuration and physical reboot/timezone verification.

**Follow-up**
- Phase 11에서 settings/privacy/account 화면, consent withdrawal, logout/account deletion을 구현한다.

### PROG-20260815-011 — Phase 9 / typed Fortune Result and screen

**Status:** PARTIAL
**Goal:** Typed Fortune Result model, result sections, lucky metadata, AI disclosure, and result route를 구현한다.

**Changed**
- 날짜/headline/overall rating/overall을 typed `FortuneResult`로 추가했다.
- 재물운·연애운·직장·학업운·인간관계운·컨디션운을 각각 3문장 section으로 구성했다.
- 오늘 하면 좋다냥/피하라냥과 행운 숫자·색상·시간·키워드를 추가했다.
- AI disclosure를 결과 화면 하단에 고정했다.
- `/fortune/result` route를 추가하고 rewarded flow 완료 시 결과 화면으로 이동시켰다.
- 개발용 Mock Result로 외부 provider 없이 화면을 검증했다.

**Verified**
```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS: No issues found
flutter test → PASS: 18 tests
```

**Security / Privacy Check**
- 결과 화면은 client가 임의 entitlement를 생성하지 않는다.
- AI disclosure는 결과 화면에 항상 표시된다.
- 실제 fortune payload/provider credential를 로그하지 않는다.

**Manual Actions**
- NONE for development result UI.

**Follow-up**
- Phase 10에서 local notification permission/schedule, tap route, logout cancellation을 구현한다.

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

### PROG-20260815-018 — App identity and OAuth preparation

**Status:** PARTIAL
**Goal:** 앱 표시 이름을 `대길`로 통일하고 Android OAuth 개발 입력값을 준비한다.

**Changed**
- Android, iOS, Windows 표시 이름을 `대길`로 변경했다. Apple OAuth 설정은 수행하지 않았다.
- 기존 Android 개발 applicationId `com.example.daegil_app`는 유지했다.
- 로컬 debug keystore에서 Android 개발 SHA-1을 확인했다.
- 사용자가 제공한 anon JWT의 `ref`에서 Supabase project ref를 확인할 수 있는 상태로 정리했다. credential 자체는 저장하지 않았다.

**Verified**
```text
Android debug SHA-1 → F4:04:9C:D4:E0:6E:57:EA:43:13:D7:96:60:26:F5:1E:11:C1:08:22
Supabase project ref → nbdgwssdikmzitebqwdkq (user-provided JWT payload derived)
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Google OAuth client creation is a persistent access-key creation and requires action-time confirmation before submission.
- `MANUAL_ACTION_REQUIRED`: Supabase dashboard confirmation of project URL/credential and production OAuth console setup remain pending.

**Follow-up**
- Chrome URL detection failed in the Windows Computer Use helper, so no console form was submitted.
- Google Android OAuth form can use package `com.example.daegil_app` and the SHA-1 above for local development.

### PROG-20260815-019 — Google Android OAuth client created

**Status:** PARTIAL
**Goal:** Google Android 개발 OAuth client 생성 결과를 계약 문서에 반영한다.

**Changed**
- 사용자가 Google Cloud OAuth Android client 생성을 완료했다.
- client ID, 개발 package, debug SHA-1, TEST 전용 상태를 `docs/EXTERNAL_SETUP.md`에 기록했다.
- client secret, access token, anon key 원문은 저장하지 않았다.

**Verified**
```text
Google Android OAuth client → CREATED
Package → com.example.daegil_app
SHA-1 → F4:04:9C:D4:E0:6E:57:EA:43:13:D7:96:60:26:F5:1E:11:C1:08:22
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: Supabase Auth Google provider에 client ID/secret과 redirect configuration을 연결한다.
- `MANUAL_ACTION_REQUIRED`: production release signing SHA-1, physical-device callback, and OAuth consent publishing remain pending.

**Follow-up**
- Apple OAuth는 사용자가 요청한 대로 보류한다.
- Web OAuth client/domain은 만들지 않는다.

### PROG-20260815-020 — Supabase Google Provider connected

**Status:** PARTIAL
**Goal:** 사용자가 Supabase Auth Google Provider 설정을 완료한 결과를 기록한다.

**Changed**
- 사용자가 Supabase Dashboard에서 Google Provider를 활성화하고 Google OAuth Client ID/Client Secret을 입력·저장했다.
- Supabase callback URL을 `https://nbdgwssdikmzitebqwdkq.supabase.co/auth/v1/callback`으로 기록했다.
- Secret 원문은 로그나 저장소에 기록하지 않았다.

**Verified**
```text
Supabase Google Provider → ENABLED / user-confirmed
Google development OAuth → CONNECTED / user-confirmed
```

**Manual Actions**
- `MANUAL_ACTION_REQUIRED`: 실제 Flutter Auth 호출 연결 및 physical Android callback test.
- `MANUAL_ACTION_REQUIRED`: release signing SHA-1과 production OAuth consent publishing.

**Follow-up**
- Apple OAuth와 Web OAuth client/domain은 계속 보류한다.

### PROG-20260815-021 — Flutter display title aligned

**Status:** DONE
**Goal:** 네이티브 표시 이름 변경 이후 Flutter 런타임 제목도 앱 이름 `대길`로 일치시킨다.

**Changed**
- 개발 환경 `AppConfig.appDisplayName`을 `대길`로 변경했다.
- fail-closed 설정 화면의 Material title도 `대길`로 변경했다.
- 기존 widget expectation을 갱신했다.

**Manual Actions**
- NONE

### PROG-20260815-034 — 원격 Android 기기 설치 검증

**Status:** DONE
**Goal:** Firebase Android Device Streaming 원격 기기에서 Google 인증 활성화 빌드를 설치하고 실행한다.

**Changed**
- Flutter JDK 경로를 사용자 로컬 Temurin 21.0.12로 고정했다.
- `ENABLE_SUPABASE_AUTH=true`와 Supabase 설정을 포함한 debug APK 빌드 성공을 확인했다.
- `localhost:63249` 원격 Android 기기에 APK 설치 성공을 확인했다.
- `com.example.daegil_app/.MainActivity`가 포그라운드로 실행 중임을 확인했다.

**Validation**
- Gradle 8.14 / JVM 21.0.12
- `flutter build apk --debug`: PASS
- `adb install -r`: PASS
- 원격 기기 Activity 확인: PASS

**Manual Actions**
- Google 로그인 버튼을 누르고 Google 테스트 계정으로 로그인하여 callback 완료를 확인해야 한다.

### PROG-20260815-035 — 자동 릴리스·보안 검증 재실행

**Status:** DONE
**Goal:** Device Streaming 중단 이후에도 코드와 릴리스 계약을 자동 검증한다.

**Validation**
- `python scripts/master_contract_audit.py`: PASS
- `python scripts/release_gate_audit.py`: PASS
- `python scripts/security_hardening_audit.py`: PASS
- `dart format --set-exit-if-changed .`: PASS
- `flutter analyze`: PASS
- `flutter test`: 28 tests PASS

**Manual Actions**
- Firebase Device Streaming 무료 사용량 소진으로 추가 원격 QA는 중단한다.
- 실제 서비스 credential/console 승인, 실기기 callback·알림·시간 경계 QA, signing/store/legal 승인은 출시 시점까지 유지한다.

### PROG-20260815-036 — Supabase CLI 준비 및 로컬 DB 점검

**Status:** PARTIAL
**Goal:** Supabase migration/RLS 검증을 실행할 수 있는 로컬 도구 상태를 확보한다.

**Changed**
- 사용자 npm 환경에서 Supabase CLI `2.114.0` 실행을 확인했다.
- Docker Desktop 재시작을 시도했다.

**Validation**
- `npx supabase --version`: PASS
- `npx supabase db lint --local`: BLOCKED (`127.0.0.1:54322` 연결 거부)
- Docker Engine: BLOCKED (Docker Desktop Linux engine unable to start)
- 저장소 Git 변경: 없음

**Manual Actions**
- Docker Desktop WSL Linux engine 복구가 필요하다. 복구되면 `npx supabase start` 후 `npx supabase db lint --local`과 `npx supabase db reset`을 실행한다.
- 원격 Dev project link/push에는 Supabase personal access token이 필요하며, 토큰은 채팅으로 보내지 않는다.

### PROG-20260816-037 — Docker WSL 복구 및 Supabase migration 검증

**Status:** DONE
**Goal:** Docker Desktop WSL 오류를 복구하고 Phase 2 migration/RLS 로컬 검증을 수행한다.

**Changed**
- 누락된 `docker-desktop-data` WSL 등록을 확인하고, 해당 깨진 등록만 해제했다.
- stale Docker backend 프로세스를 종료하고 WSL/Docker Desktop을 재기동했다.
- Docker가 `docker-desktop-data` VHDX를 재생성하도록 복구했다.

**Validation**
- Docker WSL distros: `docker-desktop` / `docker-desktop-data` Running
- Docker Engine `29.7.2` / Linux `aarch64`
- `npx supabase db lint --local`: PASS, no schema errors
- `npx supabase db reset --local`: PASS, migration applied
- 핵심 DB/Auth/REST 컨테이너: Running

**Manual Actions**
- 부가 Supabase 컨테이너의 ARM health-check 문제는 현재 DB/RLS 검증 범위 밖이므로 제외했다.
- Dev project 원격 link/push에는 Supabase personal access token이 필요하다. 토큰은 채팅으로 보내지 않는다.

### PROG-20260816-038 — Supabase 원격 project ref 교정

**Status:** DONE
**Goal:** 인증된 Supabase Dashboard와 앱 staging 실행값의 project ref 불일치를 교정한다.

**Changed**
- Dashboard에서 확인한 실제 project ref로 config 테스트 fixture를 교정했다.
- 현재 외부 설정 문서의 Supabase callback URL을 교정했다.
- historical progress entry는 감사 이력으로 보존했다.

**Validation**
- 올바른 URL + publishable key Auth settings probe: HTTP 200
- 잘못된 URL probe: connection failure
- `flutter analyze`: PASS
- `flutter test`: 28 tests PASS
- corrected Supabase URL debug APK: PASS

**Manual Actions**
- 원격 migration/RLS push는 Supabase PAT 입력 후 실행한다.
- Google callback은 Firebase 무료 Device Streaming 소진으로 실기기에서 확인한다.

### PROG-20260816-039 — Google OAuth 테스트 사용자 등록

**Status:** DONE
**Goal:** Google 로그인 테스트 계정이 OAuth 테스트 상태에서 인증할 수 있도록 등록한다.

**Changed**
- Google Cloud OAuth 대상 설정에서 `everydayatm2@naver.com`을 테스트 사용자로 등록했다.

**Validation**
- 게시 상태: 테스트 중
- 테스트 사용자: 1명
- 등록된 테스트 사용자: `everydayatm2@naver.com`
- Supabase Google Provider: enabled
- Supabase redirect URL: `com.example.daegil_app://login-callback/`

**Manual Actions**
- 실제 Android 실행 환경에서 Google 로그인 callback을 1회 확인해야 한다.
- 원격 Supabase migration/RLS push에는 PAT 입력이 필요하다. 토큰은 채팅으로 보내지 않는다.

### PROG-20260816-040 — 원격 Supabase migration push

**Status:** DONE
**Goal:** 인증된 Dev project에 Phase 2 migration을 적용하고 원격 스키마를 확인한다.

**Changed**
- Supabase CLI 로그인 완료 후 project ref `nbdgwssdikmzitebqwkq`에 link했다.
- `202608150001_phase2_foundation.sql` 원격 push를 실행했다.

**Validation**
- Supabase project 목록에서 대상 project `ACTIVE_HEALTHY` 확인
- `legal_documents` REST endpoint: HTTP 200
- `birth_profiles` REST endpoint: HTTP 200
- CLI push 완료 결과: migration 적용 대상 1개, exit marker 0 확인

**Notes**
- Windows CLI의 `migration list` 후속 호출에서 profile 파일 경고와 프로세스 종료 이상이 관찰되어 REST endpoint로 실제 적용을 교차 검증했다.

**Manual Actions**
- PAT는 채팅에 기록하지 않고 CLI 로그인 과정에서만 입력했다.
- Android physical callback QA는 다음 작업일에 진행한다.
