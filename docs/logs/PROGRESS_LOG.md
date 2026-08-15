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

### PROG-YYYYMMDD-NNN — <Phase/Task>

**Status:** DONE | PARTIAL | BLOCKED  
**Goal:**

**Changed**
- ...

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
