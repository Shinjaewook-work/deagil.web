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

### PROG-20260816-041 — 서버 주도 registration RPC 및 Flutter Dev 연결

**Status:** DONE
**Goal:** Master가 요구하는 legal registration contract를 구현하고 Flutter를 원격 Dev project의 Auth/RPC에 연결한다.

**Changed**
- `get_public_registration_requirements()`를 추가해 active legal documents만 공개 RPC로 반환한다.
- `complete_my_registration()`을 추가해 age attestation, 표시 문서, 수락 문서, analytics preference를 한 transaction으로 기록한다.
- 직접 client write 없이 `profiles`, `user_entry_records`, `privacy_preferences`, `user_consent_events`를 server function으로 갱신하도록 했다.
- Flutter `SupabaseAuthRepository`가 Fake legal requirements 대신 원격 RPC를 호출하도록 연결했다.
- OAuth session callback 이후 registration completion RPC를 호출하도록 AuthController를 연결했다.
- server legal document payload parser와 RPC contract 테스트를 추가했다.

**Validation**
- `flutter analyze`: PASS
- `flutter test`: 29 tests PASS
- debug APK with remote Dev URL/publishable key: PASS
- local migration reset: new registration migration applied
- local `get_public_registration_requirements()`: returns contract version and documents array
- local `complete_my_registration()`: authenticated claim test created registration and privacy rows
- remote registration RPC: HTTP 200
- remote anonymous birth profile response: empty result under RLS
- remote migration push result: `202608160001_registration_rpc.sql` applied

**Notes**
- Windows Supabase CLI still emits the known profile-file/native-exit anomaly after DB operations; remote schema/RPC endpoints were cross-checked independently.

**Manual Actions**
- Android callback QA remains deferred to the next workday.
- Production Kakao/Apple/AdMob/Firebase/provider/signing/legal work remains outside the Dev Google-only scope.

### PROG-20260816-042 — OpenRouter Nemotron Dev provider adapter

**Status:** CODE_READY / SECRET_CONFIGURED
**Goal:** OpenRouter의 NVIDIA Nemotron 3 Ultra free 모델을 Master의 backend-only ProviderAdapter 경계에 연결한다.

**Changed**
- 고정 endpoint `https://openrouter.ai/api/v1/chat/completions`와 고정 model slug를 사용하는 Deno server adapter를 추가했다.
- `OPENROUTER_API_KEY`는 Supabase server secret에서만 읽도록 했다.
- JSON Schema structured output, 45초 timeout, 128 KiB response cap, no-tools 요청을 적용했다.
- provider HTTP 오류를 Master taxonomy로 정규화하고, 원문 응답/credential을 로그에 남기지 않도록 했다.
- provider registry 상태는 `DEV_APPROVED`로 기록했다. 무료 endpoint의 데이터 처리/로깅 조건 때문에 production provider로 승인하지 않았다.

**Validation**
- OpenRouter 공식 API/model/structured-output 문서 확인
- repository secret scan: supplied OpenRouter key not present
- Flutter/client tree에는 OpenRouter URL·API key·provider credential을 추가하지 않음
- `npx supabase secrets list`: `OPENROUTER_API_KEY` 및 `OPENROUTER_MODEL` 등록 확인(값은 출력/기록하지 않음)

**Manual Actions**
- 기존 노출 key 폐기와 새 key 발급/secret 입력은 완료된 것으로 확인했다.
- Dev provider registry/실제 generation worker 활성화 전 OpenRouter 무료 endpoint의 보안·개인정보·약관 검토가 필요하다.

**Next**
- 내부 generation worker에서 frozen birth snapshot을 OpenRouter adapter로 전달하고, schema/content 검증 후 canonical payload를 기록한다.

### PROG-20260816-043 — OpenRouter 내부 generation worker 배포

**Status:** DONE / DEV_ONLY
**Goal:** OpenRouter adapter를 실제 Supabase 내부 generation worker와 Dev provider registry에 연결한다.

**Changed**
- `supabase/functions/generate-fortune/index.ts`를 추가·배포했다.
- worker는 `apikey`가 Supabase service-role secret과 일치할 때만 실행된다.
- session id와 `generation_epoch`를 검증하고, frozen `generation_input_snapshot`만 provider에 전달한다.
- provider set이 `dev-openrouter-nemotron-v1`이 아니면 실행하지 않는다.
- 응답 JSON schema, 배열 길이, rating 범위, 금지 콘텐츠, payload byte cap을 server에서 재검증한다.
- 성공 시 epoch 조건부 update로 canonical payload를 저장하고, 실패 시 entitlement 유무에 따라 `failed` 또는 `recovery_pending`으로 정규화한다.
- Dev migration에 OpenRouter provider set/prompt version을 active로 등록하고 새 세션 기본값을 교체했다.

**Validation**
- local reset: `202608160002_openrouter_dev_provider.sql` applied
- local provider registry/prompt/default columns: PASS
- remote migration push: `202608160002_openrouter_dev_provider.sql` applied
- Edge Function deploy: `generate-fortune` deployed
- publishable key direct invocation: HTTP 401
- repository secret scan: PASS
- `harness_lint`, `master_contract_audit`, `repo_guard`: PASS

**Manual Actions**
- OpenRouter free endpoint의 DEV_ONLY 상태를 유지한다. Production 전환은 별도 보안·개인정보·약관 승인 후 수행한다.
- 실제 authenticated session의 worker 성공 경로는 Android callback 및 rewarded/session 생성 flow가 연결된 뒤 synthetic data로 검증한다.

### PROG-20260816-044 — Phase 7~9 서버/클라이언트 바인딩

**Status:** DONE / DEV DEPLOYED
**Goal:** SSV, pass ledger, Fortune Result를 Master의 server-owned state 계약에 연결한다.

**Changed**
- `202608160003_phase7_9_contracts.sql`에 원자적 pass 예약, recovery 후 reserved pass 복구, SSV callback idempotency/late 처리 RPC를 추가했다.
- `use-fortune-pass` Edge Function이 인증 사용자 RPC 결과를 내부 `generate-fortune` worker에 전달하도록 연결했다. client-callable `start-fortune-generation`은 만들지 않았다.
- `admob-ssv` Edge Function에 GET 제한, query 길이 제한, Google public-key 기반 RSA-SHA256 서명 검증, transaction replay 경계를 추가했다.
- Flutter `FortuneRepository`가 `get_my_app_state()`를 읽고 서버 payload가 `UNLOCKED`일 때만 typed Fortune Result를 표시하도록 연결했다.
- Cat Home의 pass count/패스권 CTA를 backend app state에 연결했고, worker 성공 시 reserved pass를 redeemed로 전환한다.

**Validation**
- Flutter `analyze`: PASS
- Flutter `test`: 29 tests PASS
- local DB reset: PASS
- local DB lint: PASS / No schema errors found
- remote migration push: applied `202608160003_phase7_9_contracts.sql` (Windows CLI native exit anomaly는 기존과 동일)
- Edge Functions deployed: `use-fortune-pass`, `admob-ssv`, updated `generate-fortune`
- public SSV malformed probe: HTTP 400 `SIGNATURE_MISSING`, no mutation

**Manual Actions**
- AdMob SSV 실제 활성화 전 `ADMOB_SSV_PUBLIC_KEY_URL`, expected ad unit/reward spec, Google console SSV 설정을 입력해야 한다. 현재 malformed callback만 검증했으며 실제 reward mutation은 수행하지 않았다.
- Android physical/callback QA는 사용자가 요청한 대로 별도 진행한다.

### PROG-20260816-045 — Phase 10~14 연결 및 hardening

**Status:** IMPLEMENTED / LOCAL VERIFIED / DEV FUNCTION DEPLOYED
**Goal:** 알림·계정·telemetry·보안 경계와 production fail-closed 설정을 Master 계약에 연결한다.

**Changed**
- 알림 설정 화면과 서버 `set_my_notification_preferences` 저장 경계를 연결하고, logout/account deletion 시 local notification 취소를 먼저 수행한다.
- `withdraw_my_ai_consent()` RPC와 `delete-account` Edge Function을 추가했다. 계정 삭제는 fresh user JWT 확인 후 Auth user를 삭제한다.
- telemetry opt-in 전/opt-out 시 unsent crash report 정리 경계를 추가하고, 이벤트 parameter 길이와 민감 키를 제한했다.
- production config에 Firebase project/app ID 필수값을 추가해 미설정 production을 fail closed로 유지했다.
- Phase 13 보안 audit와 client secret scan을 다시 통과시켰다.

**Validation**
- Flutter analyze: PASS
- Flutter test: 29 tests PASS
- local DB reset/lint: PASS
- security_hardening_audit: PASS
- harness/master/repo guard: PASS
- `delete-account` malformed unauthenticated probe: HTTP 401
- `delete-account` Edge Function: deployed

**Manual Actions**
- Firebase Analytics/Crashlytics native SDK와 실제 Firebase app IDs는 production credential/console 작업이므로 아직 설정하지 않았다.
- Android/iOS native notification permission/channel 및 reboot/timezone QA는 실기기 단계에서 수행한다.
- 원격 migration push는 Supabase API login-role 502로 재시도 필요하며, 코드와 local migration은 검증 완료 상태다.

### PROG-20260816-046 — Phase 15 release audit

**Status:** AUTOMATED GATES PASS / MANUAL RELEASE GATES OPEN
**Goal:** 릴리스 artifact·P0 자동 검증과 남은 출시 승인 경계를 확정한다.

**Validation**
- `release_gate_audit.py`: automated release artifact/config checks PASS
- Flutter analyze: PASS
- Flutter test: 30 tests PASS
- security/harness/master/repo guard: PASS
- Android release APK built: `daegil_app/build/app/outputs/flutter-apk/app-release.apk`
- APK SHA-256: `E654B4DE189CCF2C1BB761E53110370379ECA3193ADBA94AD612A0F1F16974C8`
- Android artifact applicationId remains placeholder `com.example.daegil_app`; release signing/identity is not claimed complete.

**MANUAL_ACTION_REQUIRED**
- Final Android applicationId/iOS Bundle ID, signing, physical Android/iOS QA
- production Supabase/OAuth/AdMob/Firebase/AI credentials and console approvals
- store privacy/Data Safety/legal/asset license approvals
- Supabase migration `202608160004` remote push completed through the database-password flow; password was not recorded

### PROG-202608160047 — responsive screen preview and full cat voice

**Status:** DONE / DEV FUNCTION DEPLOYED
**Goal:** phone-width preview에서 발생한 화면 잘림을 제거하고, Fortune 문장과 행동 제안을 냥체로 통일한다.

**Changed**
- 공통 `LunaPageFrame`을 적용해 모든 화면 콘텐츠를 안전한 phone column 안에 배치했다.
- 인증 화면 브랜드명을 `대길`로 수정하고, 고양이 fallback 문장·설정 안내·결과 텍스트에 줄바꿈을 보장했다.
- Mock fortune과 OpenRouter prompt를 모든 Fortune sentence/action item이 자연스러운 냥체로 끝나도록 갱신했다.
- generation worker validator가 headline·fortune/action 배열 각 항목의 냥체 종결을 서버에서 재검증하도록 강화했다.
- `generate-fortune` Edge Function을 Dev project에 재배포했다.

**Validation**
- `flutter analyze`: PASS
- `flutter test`: 30 tests PASS
- `flutter build web --release`: PASS
- 9개 route 로컬 phone preview 재캡처: PASS / clipping 없음

### PROG-202608160048 — concept board visual refresh

**Status:** IMPLEMENTED / LOCAL VERIFIED
**Goal:** 사용자가 제공한 고양이 운세 앱 컨셉 시안의 따뜻한 일러스트 톤을 현재 Flutter 화면에 반영한다.

**Changed**
- 시안 기반 고양이 mascot raster asset을 `assets/images/daegil_cat_mascot.png`로 추가하고 인증·홈·결과·계정 삭제 화면에서 재사용했다.
- 크림/복숭아 배경, 갈색 잉크 텍스트, 오렌지 CTA, 둥근 입력/카드 테두리, 발바닥 아이콘을 design token에 반영했다.
- Cat Home에 시안의 하단 탭 네비게이션을 추가했다. 이 변경은 사용자가 최신 시안 반영을 명시한 디자인 override다.

**Validation**
- Flutter analyze/test: PASS
- web release build: PASS
- 9개 route phone preview capture: PASS

### PROG-202608160049 — mascot pose variants

**Status:** IMPLEMENTED / LOCAL VERIFIED
**Goal:** 같은 대길 고양이를 유지하면서 화면별 자세와 표정을 달리해 반복감을 줄인다.

**Changed**
- 인증 화면에는 한 손을 들고 인사하는 고양이를 적용했다.
- 홈의 동영상 미지원 fallback에는 기지개를 켜는 고양이를 적용했다.
- 운세 결과 요약 카드에는 하품하는 고양이를 적용했다.
- 계정 삭제 화면은 반복 mascot 대신 발바닥 아이콘을 사용하도록 정리했다.
- 세 변형 자산을 Flutter asset manifest에 등록했다.

**Validation**
- Flutter analyze: PASS
- Flutter test: 32 tests PASS

### PROG-202608160050 — butterfly curiosity mascot

**Status:** IMPLEMENTED / LOCAL VERIFIED
**Goal:** 출생정보 입력 화면에 새로운 감정·상호작용 포즈를 추가해 mascot 반복을 줄인다.

**Changed**
- 위에서 날아오는 나비를 한 손으로 잡으려는 앉은 고양이와 호기심 가득한 표정을 새 변형 자산으로 추가했다.
- 출생정보 입력 화면 상단에 새 변형을 배치했다.
- Flutter asset manifest에 `daegil_cat_butterfly.png`를 등록했다.

**Validation**
- Flutter analyze: PASS
- Flutter test: 32 tests PASS

### PROG-202608160051 — cat protection donation slogan

**Status:** IMPLEMENTED / LOCAL VERIFIED
**Goal:** 광고 시청과 고양이 보호 활동의 연결을 홈 화면에서 명확히 알린다.

**Changed**
- Cat Home의 동영상과 운세 CTA 사이에 `광고 수익 일부를 고양이 보호 활동에 보탠다냥.` 안내 카드를 추가했다.
- 긴 문구도 작은 화면에서 줄바꿈되도록 `Expanded`와 `softWrap`을 적용했다.

**Validation**
- Flutter analyze: PASS
- Flutter test: 32 tests PASS

### PROG-202608160052 — male hanbok mascot set

**Status:** IMPLEMENTED / LOCAL VERIFIED
**Goal:** 모든 고양이 mascot 변형을 동일한 남자 한복 콘셉트로 통일한다.

**Changed**
- 기본·인사·기지개·하품·나비 변형 5종을 남자 한복 형태인 저고리+바지로 교체했다.
- 민트색 바탕, 분홍·노랑·청색 띠, 꽃 자수와 노리개 포인트를 공통 적용했다.
- 기존 포즈·표정·나비 요소는 유지했다.

**Validation**
- 이미지 5종 육안 검수: PASS
- Flutter analyze/test: PASS
- Flutter web release build: PASS

### PROG-202608160053 — Android x86 emulator recovery attempt

**Status:** BLOCKED / MANUAL_ACTION_REQUIRED
**Goal:** arm64 AVD 문제를 x86_64 AVD로 우회해 Android QA를 직접 실행한다.

**Changed**
- `Pixel_6_x86` AVD를 Android 37.1 Google APIs x86_64 system image로 생성했다.
- 기존 arm64 AVD와 x86_64 AVD의 cold boot을 각각 확인했다.

**Result**
- x86_64 AVD도 호스트의 CPU virtualization extension 미지원으로 종료됐다.
- 오류 상세와 BIOS/Windows Hypervisor Platform 수동 조치를 `ERROR_LOG.md`에 기록했다.

### PROG-202608160054 — Windows runtime target correction

**Status:** PARTIAL / MANUAL_ACTION_REQUIRED
**Goal:** 최신 대길 UI를 올바른 Flutter 프로젝트에서 Windows로 실행 검증한다.

**Changed**
- 최상위 저장소가 별도 초기 Luna 스캐폴드이고 실제 최신 UI가 `daegil_app`에 있음을 실행 화면으로 확인했다.
- 잘못 생성했던 최상위 Windows 임시 파일을 제거해 하네스를 복구했다.
- `daegil_app` 정적 검증은 analyze PASS, 32 tests PASS, web release build PASS.

**Result**
- `daegil_app` Windows build는 코드가 아닌 Windows Developer Mode/symlink 권한 게이트에서 중단됐다.
- 설정 페이지를 열고 현재 사용자 개발자 플래그를 설정했으나 Flutter가 계속 OS 개발자 모드 활성화를 요구한다.

### PROG-202608160055 — Windows release runtime verified

**Status:** VERIFIED
**Goal:** Windows release build and runtime smoke check.

**Validation**
- Owner-provided elevated build succeeded for `daegil_app`.
- Debug and release Windows builds both succeeded.
- Release executable launched successfully as `대길`.
- Runtime screenshot verified the Korean consent screen, hanbok male cat asset, required consent rows, and Google sign-in entry point.

### PROG-202608160056 — Google OAuth live verification

**Status:** PARTIAL / MANUAL_ACTION_REQUIRED

**Validation**
- Corrected Supabase project URL: RPC HTTP 200 and Google authorize HTTP 302.
- Supabase-authenticated Windows release app reached the Google account screen.
- Google returned `redirect_uri_mismatch`; exact callback and owner action recorded in `ERROR_LOG.md`.
- Removed Supabase client-side validation of Mock fixture legal IDs; server-driven legal requirements remain authoritative.

### PROG-202608160057 — Google OAuth final login verified

**Status:** VERIFIED
**Goal:** Complete the Windows Google OAuth flow through authenticated app state.

**Validation**
- Added explicit Google email userinfo scope for Supabase callback identity creation.
- Added a Windows-only loopback callback server at `http://localhost:3000` that exchanges the PKCE code with Supabase in-process.
- `flutter analyze --no-pub`: passed.
- `flutter test --no-pub`: 32 tests passed.
- Windows Release build succeeded.
- Live Google login completed and the app displayed the authenticated fortune home screen.

### PROG-202608161230 — UI and consent flow update

**Status:** VERIFIED
**Goal:** Birth-time input, cat-themed copy/layout, persistent navigation labels, rewarded-ad presentation, and consent gate update.

**Validation**
- Exact/approximate birth-time precision now exposes AM/PM, 12-hour, and 5-minute selectors; unknown precision keeps time unset.
- Home fallback copy and bottom navigation label updated to the requested Korean wording.
- Cat image containers use the illustration background color; the auth cat illustration is enlarged.
- The rewarded-ad fake flow now visibly presents the ad dialog before completion routing.
- Age, AI-processing, and personal-information-use consent rows are required before Google sign-in.
- `flutter analyze --no-pub`: passed.
- `flutter test --no-pub`: 32 tests passed.
- `harness_lint.py`, `repo_guard.py`, and `git diff --check`: passed.

### PROG-202608161300 — Mobile Rewarded Ad SDK integration

**Status:** PARTIAL / MANUAL_ACTION_REQUIRED
**Goal:** Connect Google Mobile Ads Rewarded SDK while preserving Fake ads on Windows/web.

**Validation**
- Added `google_mobile_ads` and a native Android/iOS Rewarded implementation with preload, show, impression, reward, dismiss, and SSV custom-data hooks.
- Android uses the official Google test App ID and rewarded unit ID; iOS uses the corresponding official test IDs.
- Windows/web continue using the deterministic Fake service and visible development ad dialog.
- `flutter analyze --no-pub`: passed.
- `flutter test --no-pub`: 32 tests passed.
- Debug APK build succeeded at `daegil_app/build/app/outputs/flutter-apk/app-debug.apk`.

**Remaining gate**
- Replace test App IDs/unit IDs with the owner's production AdMob IDs and complete the server-side prepare/claim function deployment before a production release.

### PROG-202608161340 — Android AdMob IDs and SSV configured

**Status:** VERIFIED / AWAITING CONSOLE CALLBACK CHECK

**Validation**
- Android App ID configured: owner-provided production ID.
- Android Rewarded unit configured for `운세보기`.
- Supabase Function secrets configured for the exact ad unit, reward item `fortune`, and reward amount `1`.
- Corrected `admob-ssv` to parse Google's rotating key-array response and verify ECDSA/P-256 signatures.
- Redeployed `admob-ssv` successfully.
- iOS remains on official test IDs until an iOS App ID is provided.

### PROG-202608161430 — HTTPS OAuth callback relay

**Status:** IMPLEMENTED / MANUAL_ACTION_REQUIRED
**Goal:** Remove Android OAuth dependence on localhost or the Supabase API root.

**Validation**
- Added and deployed public `oauth-mobile-redirect` Edge Function.
- Relay returns `302` to the fixed Android deep link while forwarding only OAuth `code`, `state`, and error fields.
- Verified the deployed relay with a synthetic code/state request; response was `HTTP 302` with the expected custom-scheme Location.
- Flutter default/mobile redirect now targets the HTTPS relay; Windows continues to override it with the local callback server.
- `flutter analyze --no-pub`: passed.
- `flutter test --no-pub`: 32 tests passed.
- Debug APK rebuilt with Supabase auth and the relay redirect.

**Manual gate**
- Add the relay URL to Supabase Authentication URL Configuration Additional Redirect URLs before installing the rebuilt APK.

### PROG-202608162200 — Relay deployment rechecked after Android 404

**Status:** DIAGNOSED / MANUAL_ACTION_REQUIRED

**Verified:** `oauth-mobile-redirect` is ACTIVE in the linked Supabase project and its exact HTTPS endpoint returns the expected 302 deep-link response. The supplied dashboard screenshot has not yet added that HTTPS relay URL to Additional Redirect URLs.

**Next:** Add the exact relay URL, save, then reinstall the latest debug APK and repeat Google login.

### PROG-202608162240 — Android OAuth URI scheme corrected

**Status:** IMPLEMENTED / DEVICE_VERIFICATION_REQUIRED

**Root cause:** `com.example.daegil_app` is a valid Android application ID but not a valid URI scheme because schemes cannot contain underscores.

**Changed**
- Mobile OAuth now redirects directly to `com.example.daegilapp://login-callback/`.
- Android intent filter and the deployed relay fallback use the same valid scheme.
- Supabase Site URL and redirect allowlist were updated directly; obsolete invalid and relay URLs were removed from Auth configuration.
- Added regression tests for invalid underscored schemes and the valid mobile default.

**Verified**
- Supabase authorize accepts the corrected direct redirect and returns Google OAuth HTTP 302.
- Redeployed relay returns HTTP 302 to the corrected deep link.
- Merged debug manifest contains `android:scheme="com.example.daegilapp"` and `android:host="login-callback"`.
- `flutter analyze --no-pub`: passed.
- `flutter test --no-pub`: 33 tests passed.
- Harness lint and repository guard: passed.
- Debug APK rebuilt successfully with the corrected direct OAuth redirect.

### PROG-202608272345 — APK intent audit, server wiring, and cat-theme completion

**Status:** IMPLEMENTED / REMOTE VERIFIED / PHYSICAL DEVICE QA REQUIRED

**Authentication**
- Google session and registration completion are separate states; home navigation occurs only after `complete_my_registration` succeeds.
- Supabase Auth configuration was read back: Site URL and allowlist use `com.example.daegilapp://login-callback/`, Google is enabled, and client ID/secret are present.
- Live authorize endpoint returns Google OAuth HTTP 302.
- Added active development terms, privacy, and AI-processing documents and verified registration RPC in a rolled-back remote transaction.

**Database**
- Birth profile now calls `upsert_my_birth_profile`; Korean 12-hour input is converted to PostgreSQL time.
- Home restores `birth_profile_exists` from `get_my_app_state` after restart.
- Remote rolled-back smoke test verified birth-profile persistence without leaving test data.

**Rewarded ad**
- Added and deployed `prepare-ad-session`, `report-ad-impression`, `claim-ad-reward`, and `report-ad-dismissed`.
- Added server attempt lease, opaque challenge hash, frozen security/reward specification, entitlement transition, and generation-worker start.
- Updated and redeployed `admob-ssv`; public health probe is HTTP 200.
- Remote DB smoke completed prepare → impression → claim → dismiss and rolled back.

**Design and layout**
- Added reusable hanbok-cat banner cards and applied them to fortune result, settings, notification, privacy, account, and deletion screens.
- Enlarged the result cat and aligned image containers to the illustration background.
- Added responsive birth-time controls and fixed the 320px result-card overflow.
- Current 390×844 previews were captured under `.codex/visualizations/2026/08/27/daegil-apk-audit-after`.

**Validation**
- `flutter analyze --no-pub`: PASS.
- `flutter test --no-pub`: PASS (functional suite; visual capture test is opt-in).
- 320px major-page and birth-time layout tests: PASS.
- `harness_lint.py`, `repo_guard.py`, `security_hardening_audit.py`, `release_gate_audit.py`, and `git diff --check`: PASS.
- Debug APK rebuilt with real Supabase Auth, valid direct callback, production Android AdMob IDs, and `AD_SECURITY_MODE=fast`.

**Remaining manual gates**
- Physical Android install: complete Google account return-to-app, save real birth data, view a live rewarded ad, confirm generated fortune, and verify rows through normal user APIs.
- Replace development legal copy after owner/legal approval; complete store signing, Data Safety/privacy labels, and final application ID decision.

### PROG-202608280015 — Final Android APK rebuild and resilience review

**Status:** AUTOMATED VERIFIED / PHYSICAL DEVICE QA REQUIRED

**Review fixes**
- Legal consent selection now uses stable server `document_type` values rather than Korean title text.
- Auth requirements failures leave a safe, retryable gate instead of an indefinite loading state.
- Existing completed registrations restore from the server gate without asking for consent again.
- SSV verification polling tolerates transient Supabase errors.
- Failed internal generation dispatches are fenced by session/epoch and persisted as `failed` or `recovery_pending`.

**Remote validation**
- Applied `202608280001_generation_dispatch_recovery.sql` to the linked Supabase project.
- Redeployed prepare, impression, reward, dismiss, and SSV Edge Functions.
- Authenticated ad endpoints return HTTP 401 without a JWT; SSV reachability returns HTTP 200.
- `supabase db push --linked --dry-run`: remote database is up to date.

**Build and checks**
- `flutter analyze --no-pub`: PASS.
- `flutter test --no-pub`: PASS, 45 functional tests; visual capture test remains opt-in.
- Harness, repository, security, release, and whitespace guards: PASS.
- Debug APK rebuilt with real Supabase Auth, direct Android callback, production Android AdMob IDs, and `AD_SECURITY_MODE=fast`.
- APK SHA-256: `D7B58BEE1C8AAD778D83294BD3781F281187EF4CC5B8DE09C047DECB077656BA`.
- Current mobile captures: `C:/Users/every/.codex/visualizations/2026/08/28/daegil-apk-final`.

### PROG-202608281135 — Cat-first cute design system completion

**Status:** IMPLEMENTED / VISUAL QA PASSED

**Design changes**
- Expanded the warm cream design system with peach, blush, butter, and soft-jade surfaces while retaining the approved brown/seal hierarchy.
- Added rounded, softly elevated cards, pastel icon circles, paw accents, larger hanbok-cat banners, polished form controls, and a capsule-style persistent bottom navigation.
- Reworked Auth, Cat Home, birth profile, fortune result, settings, notification, privacy, account, and account-deletion screens.
- Kept the Google action fixed at the bottom of Auth so the primary CTA remains visible while the server-driven legal list scrolls.
- Kept the Cat Home message exactly `고양이가 오늘의 운세를 잡아올 준비를 하고 있다냥.` and removed its fallback duplication.

**Visual validation**
- Compared the owner-provided concept board and final 390 x 844 captures in the same visual QA pass.
- Final captures: `C:/Users/every/.codex/visualizations/2026/08/28/daegil-cute-final`.
- `daegil_app/design-qa.md`: `final result: passed`.
- 320 px major-screen and birth-time responsive tests pass.

**Build and checks**
- `flutter analyze`: PASS.
- `flutter test test/widget_test.dart`: PASS, 45 tests.
- Harness lint, Master contract audit, repository guard, security hardening audit, and whitespace guard: PASS.
- Debug APK rebuilt: `daegil_app/build/app/outputs/flutter-apk/app-debug.apk`.
- APK SHA-256: `CEEEE49A094DD58BDD7DCBEAE5B7FCE781805F92AF22ACFA17CBEBF5A657EE88`.

### PROG-202608291430 — Paper-integrated benchmark redesign

**Status:** IMPLEMENTED / VISUAL QA PASSED

**Benchmark findings**
- Analyzed the supplied target as a restrained paper-illustration system: one warm cream field, thin brown outlines, compact typography, small illustrative accents, and one muted-pink CTA.
- Sampled the five mascot PNG edge colors and aligned the shared page/image canvas to the common `#FBEACD` family.

**Design changes**
- Removed the two image-corner paw bubbles, Auth floating paws, Home floating paw, circular image backplates, elevated card shadows, and the repeated result thumbnail.
- Added `PaperBlendImage`, which fades only the artwork's outer paper pixels within the fitted square asset bounds so opaque raster backgrounds merge into the page.
- Flattened all nine screens to consistent cream cards, 1.15 px brown outlines, 18 px radii, compact icon accents, and a muted-pink primary action while preserving every existing interaction and the persistent navigation.

**Visual validation**
- Compared the selected benchmark and final 390 x 844 captures in the same visual input over three render iterations.
- Final captures: `C:/Users/every/.codex/visualizations/2026/08/29/daegil-benchmark-final`.
- `daegil_app/design-qa.md`: `final result: passed` with no open P0/P1/P2 finding.

**Build and checks**
- `flutter analyze`: PASS.
- `flutter test`: PASS, 45 functional tests plus the visual capture test.
- 320 px responsive tests: PASS.
- Harness lint, Master contract audit, repository guard, security hardening audit, and whitespace guard: PASS.
- Debug APK rebuilt: `daegil_app/build/app/outputs/flutter-apk/app-debug.apk`.
- APK SHA-256: `80ED34143ED45BA35F76F6D8D9C39965628469DC9F56ED6E553407A3233FE119`.

### PROG-202608291600 — Independent web experience package

**Status:** IMPLEMENTED / LOCAL BUILD VERIFIED / GITHUB PUSH BLOCKED

**Implementation**
- Added standalone `daegil_web` Next.js package with warm paper design tokens, cat artwork, public landing flow, server-driven legal gate, Google OAuth callback, birth profile form, fortune result screen, Supabase RPC/Edge Function integration, and web Rewarded Ad adapter.
- Extended `prepare-ad-session` additively for `platform=web` using server-only `GAM_EXPECTED_REWARDED_AD_UNIT_ID`; existing Android/iOS platform behavior remains unchanged.
- Updated harness exclusions/allowed prefixes for web build output and added web deployment settings to `docs/EXTERNAL_SETUP.md`.

**Verification**
- `daegil_web`: `npm run typecheck`: PASS.
- `daegil_web`: `npm run build`: PASS; `/` and `/auth/callback` local HTTP smoke tests returned 200.
- `daegil_app`: `flutter analyze --no-pub`: PASS; `flutter test --no-pub`: PASS, 45 tests.
- `python scripts/harness_lint.py`: PASS; `python scripts/repo_guard.py`: PASS; `python scripts/master_contract_audit.py`: PASS.

**Manual action / blocker**
- `origin` is configured as `https://github.com/Shinjaewook-work/deagil.web.git`, but `git push -u origin codex/daegil-web` returned HTTP 403 because the local GitHub credential is `hfamily963-stack` without write access. Re-authenticate as `Shinjaewook-work` or grant write access, then retry the same push.

### PROG-202608291700 — Vercel project root diagnosis

**Status:** CODE PUSHED / VERCEL ROOT SETTING PENDING

- `https://deagil-web-gj8b.vercel.app/` returned HTTP 404 with `X-Vercel-Error: NOT_FOUND`.
- Vercel inspection showed project `jeawook/deagil-web-gj8b` using Root Directory `.` and Framework `Other`; the web package is `daegil_web`.
- Updated the project framework to Next.js and disabled SSO deployment protection for the public viral experience. Pushed `0d8527f` to `codex/daegil-web` and `main`.
- Owner action: set Vercel Root Directory to `daegil_web`, keep Production Branch `main`, add environment variables, and redeploy.

### PROG-202608291830 — Vercel root fix and production verification

**Status:** VERIFIED / DEPLOYED

- Authenticated Vercel project `jeawook/deagil-web-gj8b` was updated through the Vercel API with Root Directory `daegil_web`; Framework Preset is `nextjs` and public SSO protection is disabled.
- Production deployment `dpl_GMQnDK6mbEFvYaRWcGiiDWpF25pR` was created from GitHub `main` commit `cda2ba2c7721fb63ba0e908fad9c1b170c9443a2` and reached `READY`.
- `https://deagil-web-gj8b-ovre52jq4-jeawook.vercel.app/` and `https://deagil-web-gj8b.vercel.app/` both returned HTTP 200 with Korean Next.js HTML.
- Vercel Git integration still reports `codex/daegil-web` as the production branch; change it to `main` in Environments > Production > Branch Tracking if `main` should be the automatic production branch.
- Vercel Production/Preview now contain `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`; the redeployed bundle includes the Supabase project URL and `get_public_registration_requirements` returns HTTP 200. `NEXT_PUBLIC_WEB_REWARDED_AD_UNIT` remains pending because no real Google Ad Manager web rewarded unit is available; the mobile AdMob unit cannot be reused as a browser GPT path.
