# Error Log

오류 수정 전에 이 파일을 검색한다.

### ERR-20260815-001 — Flutter toolchain unavailable

**Status:** OPEN
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

Pending toolchain availability; static harness and repository guard pass.

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

## Known Historical Prevention Rules

1. Active spec에 오래된 규칙을 남기고 override만 얹지 않는다.
2. pass 3/3을 Rewarded Ad 차단 조건으로 사용하지 않는다.
3. Provider temporary failure에서 reserved pass를 즉시 복원하지 않는다.
4. 고정 `AI max 2 attempts`를 제품 invariant로 사용하지 않는다.
5. 사용자 birth data는 UI validation만 믿지 않고 server RPC에서 다시 검증한다.
6. SSV delayed callback과 04:00 Fortune content expiry를 같은 retention으로 묶지 않는다.
7. Supabase admin/secret client를 일반 user-data path의 기본값으로 사용하지 않는다.
