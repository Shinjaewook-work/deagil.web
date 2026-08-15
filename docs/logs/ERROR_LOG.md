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

## Known Historical Prevention Rules

1. Active spec에 오래된 규칙을 남기고 override만 얹지 않는다.
2. pass 3/3을 Rewarded Ad 차단 조건으로 사용하지 않는다.
3. Provider temporary failure에서 reserved pass를 즉시 복원하지 않는다.
4. 고정 `AI max 2 attempts`를 제품 invariant로 사용하지 않는다.
5. 사용자 birth data는 UI validation만 믿지 않고 server RPC에서 다시 검증한다.
6. SSV delayed callback과 04:00 Fortune content expiry를 같은 retention으로 묶지 않는다.
7. Supabase admin/secret client를 일반 user-data path의 기본값으로 사용하지 않는다.
