# Error Log

오류 수정 전에 이 파일을 검색한다.

### ERR-20260815-001 — Flutter toolchain unavailable

**Status:** RESOLVED
**Task/Phase:** Phase 0 / Repository bootstrap
**Area:** Flutter

#### Fingerprint

```text
ERROR_CODE: TOOLCHAIN_NOT_FOUND
EXCEPTION_TYPE: CommandNotFound
CORE_MESSAGE: flutter and dart commands are not available on PATH
COMPONENT: local verification
ENVIRONMENT/VERSION: Windows, Python 3.13.9, 2026-08-15
```

#### Symptom

The scaffold is present, but `flutter pub get`, `dart format`, `flutter analyze`, and `flutter test` cannot start.

#### Reproduction

```text
flutter --version
dart --version
```

#### Root Cause

Flutter SDK is not installed or is not exposed through the current PATH.

#### DO_NOT_REPEAT

```text
- failed approach: report Phase 0 as fully verified without running the Flutter commands
- why it failed: the local toolchain is a required verification dependency
```

#### Permanent Fix

Install/configure the Flutter SDK in the development environment, then rerun the Phase 0 verification commands. Chocolatey installation also requires an elevated shell in this environment.

#### Verification

Flutter 3.41.9 / Dart 3.11.5 installed. `flutter pub get`, `dart format --set-exit-if-changed .`, `flutter analyze`, and `flutter test` pass.

#### Regression Guard

Phase 0 progress log records the blocked commands and must be cleared only after native verification passes.

#### Prevention Rule

Record actual toolchain availability before claiming Flutter verification.

## Entry Template

### ERR-YYYYMMDD-NNN — <short title>

**Status:** OPEN | RESOLVED | RECURRENT  
**Task/Phase:**  
**Area:** Flutter | Auth | DB | RLS | Edge | AdMob | SSV | AIProvider | Notification | Release

#### Fingerprint

```text
ERROR_CODE:
EXCEPTION_TYPE:
CORE_MESSAGE:
COMPONENT:
ENVIRONMENT/VERSION:
```

#### Symptom

#### Reproduction

#### Root Cause

#### DO_NOT_REPEAT

```text
- failed approach:
- why it failed:
```

#### Permanent Fix

#### Verification

#### Regression Guard

#### Prevention Rule

---

### ERR-20260815-002 — AppConfig ad security mode constructor omission

**Status:** RESOLVED
**Task/Phase:** Phase 5 / Rewarded Ad flow
**Area:** AdMob

#### Fingerprint

```text
ERROR_CODE: CONFIG_FIELD_NOT_INITIALIZED
EXCEPTION_TYPE: Dart compile error
CORE_MESSAGE: The named parameter 'adSecurityMode' isn't defined
COMPONENT: daegil_app/lib/core/config/app_config.dart
ENVIRONMENT/VERSION: Flutter 3.41.9 / Dart 3.11.5
```

#### Symptom

`AppConfig.fromEnvironment()` could not construct `AppConfig` after adding the `AD_SECURITY_MODE` parser.

#### Root Cause

The field and parser were added without wiring the optional constructor parameter and development default.

#### DO_NOT_REPEAT

```text
- failed approach: add an environment-backed final field without updating all constructors
- why it failed: Dart requires every final field to be initialized and named arguments to exist
```

#### Permanent Fix

Added `adSecurityMode` to the const constructor with the Master default `fast`.

#### Verification

```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS: 6 tests
```

#### Regression Guard

Rewarded-ad tests exercise both `fast` and `ssv_strict` paths.

#### Prevention Rule

When adding an environment-backed final config field, update its constructor, parser, default, and test path together.

### ERR-20260815-003 — SSV late-callback fixture before expiry

**Status:** RESOLVED
**Task/Phase:** Phase 7 / SSV webhook contract
**Area:** SSV

#### Fingerprint

```text
ERROR_CODE: TEST_FIXTURE_WRONG_TIME_ORDER
EXCEPTION_TYPE: Assertion failure
CORE_MESSAGE: expected lateCompensationOnly, actual granted
COMPONENT: daegil_app/test/widget_test.dart
ENVIRONMENT/VERSION: Flutter 3.41.9 / Dart 3.11.5
```

#### Root Cause

The test reward timestamp was five minutes before the expiry timestamp, so the handler correctly granted it.

#### Permanent Fix

Changed the fixture so the reward timestamp is 30 seconds before server time while Fortune expiry is one minute before server time.

#### Verification

```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS: 13 tests
```

#### Regression Guard

The test now explicitly proves a verified late callback returns `lateCompensationOnly` and does not resurrect expired Fortune content.

### ERR-20260815-004 — Pass reserve incorrectly blocked at active cap

**Status:** RESOLVED
**Task/Phase:** Phase 8 / pass ledger
**Area:** AdMob

#### Fingerprint

```text
ERROR_CODE: PASS_RESERVE_CAP_CONFUSION
EXCEPTION_TYPE: Assertion failure
CORE_MESSAGE: existing available pass could not be reserved at active cap
COMPONENT: daegil_app/lib/features/passes/domain/fortune_pass_ledger.dart
ENVIRONMENT/VERSION: Flutter 3.41.9 / Dart 3.11.5
```

#### Root Cause

The first implementation rejected every reserve when `available + reserved == 3`, even though reserve changes state without increasing the active count.

#### Permanent Fix

The ledger now validates the cap when passes are added and lets existing available passes transition to reserved. Goodwill issuance remains capped at three active passes.

#### Verification

```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS: 17 tests
```

#### Regression Guard

The pass test reserves all three existing passes, rejects a fourth, and separately rejects a fourth goodwill pass.

### ERR-20260815-005 — Fortune Result mock DateTime const fixture

**Status:** RESOLVED
**Task/Phase:** Phase 9 / typed Fortune Result
**Area:** Flutter

#### Fingerprint

```text
ERROR_CODE: CONST_DATETIME_FIXTURE
EXCEPTION_TYPE: Dart compile error
CORE_MESSAGE: Cannot invoke a non-const DateTime constructor in a const expression
COMPONENT: daegil_app/lib/features/fortune/domain/fortune_result.dart
ENVIRONMENT/VERSION: Flutter 3.41.9 / Dart 3.11.5
```

#### Root Cause

Dart's `DateTime` constructor is not const, while the Mock Result subclass initializer was declared as a const expression.

#### Permanent Fix

Made the Mock Result construction non-const and kept the screen's optional result input const-safe.

#### Verification

```text
dart format --set-exit-if-changed . → PASS
flutter analyze → PASS
flutter test → PASS: 18 tests
```

#### Regression Guard

The result screen widget test constructs the default mock result and verifies the typed sections and disclosure.

## Known Historical Prevention Rules

1. Active spec에 오래된 규칙을 남기고 override만 얹지 않는다.
2. pass 3/3을 Rewarded Ad 차단 조건으로 사용하지 않는다.
3. Provider temporary failure에서 reserved pass를 즉시 복원하지 않는다.
4. 고정 `AI max 2 attempts`를 제품 invariant로 사용하지 않는다.
5. 사용자 birth data는 UI validation만 믿지 않고 server RPC에서 다시 검증한다.
6. SSV delayed callback과 04:00 Fortune content expiry를 같은 retention으로 묶지 않는다.
7. Supabase admin/secret client를 일반 user-data path의 기본값으로 사용하지 않는다.

### ERR-20260816-001 — Docker Desktop WSL data distro missing

**Status:** RESOLVED
**Task/Phase:** Phase 2 / Supabase local migration verification
**Area:** Docker Desktop / WSL2

#### Fingerprint

```text
ERROR_CODE: DOCKER_WSL_DATA_DISTRO_MISSING
EXCEPTION_TYPE: Docker Desktop startup failure
CORE_MESSAGE: wsl-keepalive failed to start; docker-desktop-data ext4.vhdx path not found
COMPONENT: Docker Desktop 4.86.0 / WSL 2.7.11.0
ENVIRONMENT/VERSION: Windows 10.0.26200.9168 / ARM64
```

#### Root Cause

The registered `docker-desktop-data` WSL distribution pointed to
`%LOCALAPPDATA%\Docker\wsl\data\ext4.vhdx`, but that VHDX was absent. Docker
backend remained in a stale engine-wait loop and later failed to open its
backend named pipe because old backend processes were still alive.

#### Permanent Fix

Confirmed the VHDX was absent, unregistered only the broken
`docker-desktop-data` distribution, fully terminated stale Docker processes,
ran `wsl --shutdown`, and restarted Docker Desktop. Docker recreated the data
distribution and its VHDX without touching the Ubuntu distribution.

#### Verification

```text
docker-desktop WSL distro: Running
docker-desktop-data WSL distro: Running
Docker Engine: 29.7.2 / linux / aarch64
npx supabase db lint --local: PASS, no schema errors
npx supabase db reset --local: PASS
```

#### Regression Guard

Before running Supabase local commands, verify `docker version` succeeds and
both Docker WSL distributions are Running. If `docker-desktop-data` points to
a missing VHDX, do not delete arbitrary Docker files; inspect the registered
path and confirm the target is absent before unregistering that broken distro.

### ERR-20260816-002 — Supabase remote project ref typo

**Status:** RESOLVED
**Task/Phase:** Phase 3 / Google OAuth staging connection
**Area:** Supabase remote configuration

#### Fingerprint

```text
ERROR_CODE: SUPABASE_PROJECT_REF_MISMATCH
EXCEPTION_TYPE: Remote connection failure
CORE_MESSAGE: app URL ref differed from the authenticated Dashboard project ref by one character
COMPONENT: daegil_app test/config verification and OAuth staging command
ENVIRONMENT/VERSION: Supabase Dashboard current project / publishable API key
```

#### Root Cause

The app execution value and documentation used `nbdgwssdikmzitebqwdkq`, while
the authenticated Supabase Dashboard project and the supplied publishable key
responded at `nbdgwssdikmzitebqwkq`. The former URL did not respond to the
read-only Auth settings probe, so OAuth configuration appeared to fail.

#### Permanent Fix

Updated the config test fixture and current external setup callback URL to the
Dashboard-verified project ref. Historical progress entries remain unchanged
as audit history.

#### Verification

```text
correct URL + publishable key: HTTP 200
wrong URL + publishable key: connection failure
flutter analyze: PASS
flutter test: 28 tests PASS
debug APK with corrected URL: PASS
```

#### Regression Guard

Before staging or production OAuth QA, compare the Dashboard project URL and
the API key's project endpoint with a read-only request; never infer the ref
from a copied command or historical log entry.

### ERR-20260816-003 — Supabase CLI linked status process exit anomaly

**Status:** MITIGATED
**Task/Phase:** Phase 2 / remote migration push
**Area:** Supabase CLI on Windows

#### Fingerprint

```text
ERROR_CODE: SUPABASE_CLI_STATUS_PROCESS_EXIT
EXCEPTION_TYPE: CLI process termination after linked database operation
CORE_MESSAGE: profile file warning and non-zero native process exit during follow-up status/list commands
COMPONENT: Supabase CLI 2.114.0 / Windows ARM64
ENVIRONMENT/VERSION: Windows 10.0.26200.9168 / npx supabase
```

#### Root Cause

The CLI authenticated successfully and reached the linked database, but
follow-up status/list invocations emitted a missing profile-file warning and
could terminate with a native process exit before returning normal status.

#### Mitigation

The migration push was rerun with debug output and returned a completed push
result with exit marker 0. The remote schema was then verified through the
authenticated public REST endpoints for `legal_documents` and `birth_profiles`.

#### Regression Guard

For this Windows CLI behavior, do not treat the status/list process exit alone
as proof that a migration failed. Confirm the push result and verify one or
more expected remote schema endpoints without printing credentials or data.

### ERR-20260816-004 — OpenRouter API key exposed in chat

**Status:** OPEN / MANUAL_ACTION_REQUIRED
**Task/Phase:** Phase 6 / provider credential setup
**Area:** External AI provider credential handling

#### Fingerprint

```text
ERROR_CODE: PROVIDER_SECRET_EXPOSED_OUTSIDE_SECRET_STORE
EXCEPTION_TYPE: Credential exposure
CORE_MESSAGE: OpenRouter API key was pasted into the conversation
COMPONENT: OpenRouter provider setup
ENVIRONMENT/VERSION: OpenRouter API key / user-provided
```

#### Required Fix

Revoke the exposed key in OpenRouter, create a replacement, and enter the
replacement directly into the Supabase server secret store. The key must not
be committed, placed in Flutter config, or pasted into chat again.

#### Regression Guard

Provider adapters read only server environment secrets. Repository scans must
reject provider key prefixes and client code must contain no provider endpoint,
model-selection, or credential input path.
