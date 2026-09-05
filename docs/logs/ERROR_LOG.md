# Error Log

#### 2026-09-05 — Entitled generation could not recover after provider failure

**Root cause:** The failure recorder preserved `recovery_pending`, but the
client-callable recovery endpoint and the atomic claim transaction did not
exist. A retry would therefore be either a 404 or an unsafe duplicate
monetization attempt. Provider failure handling also derived the next state from
a stale session snapshot instead of locking and rechecking current entitlement.
**Permanent fix:** Added a server-owned runtime config and locked recovery RPC
with current-day, active-account, registration, AI-consent, entitlement,
snapshot, cooldown, provider-request, recovery-round and daily-budget fences.
Each claim increments the epoch and gives a bounded lease. Added the authenticated
resume Edge Function; provider failures now use the locked failure RPC. Web and
native retry controls never prepare another ad or reserve another pass.
**Regression guard:** Recovery endpoint, SQL contract, CORS, dispatch and SSV
tests pass; Flutter test/analyze and web test/typecheck/build pass. Remote
migration applied and unauthenticated live probe is 401; no authenticated user
generation was exercised.
**DO_NOT_REPEAT:** A persisted entitlement is not proof that retry is safe.
Recheck server time, consent, current ownership, snapshot and all request/budget
caps inside the same locked transaction, then fence worker commit by epoch.

#### 2026-09-05 — Worker connection failures bypassed recovery recording

**Root cause:** startGenerationIfRequired only handled a non-OK HTTP response.
Thrown fetch errors escaped before mark_generation_dispatch_failed; pass use
duplicated dispatch without recording failures at all. Both could leave a
committed entitlement/session generating after worker connection loss.
**Fix:** Catch network/60s timeout failures, call the existing epoch-fenced RPC,
surface persistence failures via a normalized code, and share the helper with
pass use. Do not guess recovery_pending when the RPC may be a stale no-op or
when entitlement is absent; the client must load authoritative app state.
**Regression:** Seven helper + two pass-handler tests; complete backend suite 32.
**DO_NOT_REPEAT:** Test network rejection as well as HTTP error. Missing recovery
endpoint (live 404) and client retry are still separate incomplete work.
**Tool note:** Deno check initially inherited unrelated node_modules resolution;
--no-config --no-lock --node-modules-dir=none passed without repo dependency edits.


#### 2026-09-05 — Web rewarded ad lifecycle and CORS failures

**Root cause:** Initial web implementation omitted GPT enableServices. Its
promise settled only on a grant, never on unrewarded close or no-fill; listeners
and slots survived, grants could repeat and same-tick clicks prepared twice.
Separate server defect: user functions rejected all OPTIONS with 405 and never
returned CORS headers, preventing cross-origin browser function invocation.

**Permanent fix:** A scoped rewarded lifecycle handles setup/load/show failure,
close/abort, one-time grants, separate viewable-impression reports and cleanup.
UI actions are single-flight and wait for close before refreshing state.
Exact-origin CORS handles OPTIONS before user logic and decorates error/success
responses while preserving mandatory JWT and native no-Origin handling.

**Regression guard:** Web suite 19 tests, CORS 18 tests, existing SSV 5 tests.
Live probes on all six redeployed endpoints: 204 preflight, 401 missing JWT,
403 foreign Origin. No actual reward/pass/deletion mutation was made by probes.
**DO_NOT_REPEAT:** Test browser preflight, not only mobile/CLI POST. Treat close
and grant independently. SDK loading and failed-show paths must settle/clean up.
Do not claim real ad delivery from mocks; GAM web has no app SSV support.


#### 2026-09-05 — Web result silently substituted sample content

**Root cause:** The result branch used `currentPayload ?? DEMO_RESULT` regardless
of backend mode. Payload selection checked content presence but not the current
server gate or fortune state. Existing tests covered registration, not rendering.

**Permanent fix:** Remove implicit sample substitution. Require UNLOCKED and
server gate NONE outside demo mode; missing/unreadable results show a reload
action. Synthetic actual-page render tests failed before and pass after the fix.

**DO_NOT_REPEAT:** Never conceal a live payload failure with demo content.
**Regression guard:** `npm test` includes missing-payload, locked/gated retained
payload, and valid unlocked server-headline rendering. Expiry and schema
validation still require separate work; these tests are not live provider proof.

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

2026-08-16 Phase 10~14 migration retry additionally received Supabase API
`login-role` HTTP 502 from the Cloudflare origin. Local reset/lint passed.
Resolved by using the official database-password flow; remote push subsequently
reported `Remote database is up to date`.

Official troubleshooting was checked: `supabase@beta link --skip-pooler`
confirmed the alternate path, but this PC has no IPv6 support. The supported
password flow was used without recording the password.

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

### ERR-202608160005 — Android emulator hardware acceleration unavailable

**Status:** OPEN / MANUAL_ACTION_REQUIRED
**Task/Phase:** Phase 15 / physical QA
**Area:** Android emulator execution

#### Fingerprint

```text
ERROR_CODE: ANDROID_EMULATOR_ACCELERATION_UNAVAILABLE
EXCEPTION_TYPE: Emulator startup failure
CORE_MESSAGE: x86_64 emulation requires hardware acceleration; virtualization extension is not supported
COMPONENT: Android Emulator 37.2.4 / Pixel_6_x86
ENVIRONMENT/VERSION: Windows host, Android API 37.1 Google APIs x86_64
```

#### Investigation

- 기존 Pixel_6 AVD는 arm64 이미지라 x86_64 Windows 호스트에서 시작할 수 없었다.
- x86_64 system image를 사용한 `Pixel_6_x86` AVD를 새로 만들었지만, 호스트에서 CPU virtualization extension이 비활성/미지원이라 QEMU2가 종료됐다.

#### Required Fix

BIOS/UEFI virtualization 또는 Windows Hypervisor Platform을 owner가 활성화하고 재부팅하거나, 실제 Android 기기를 연결한다. Windows 보안/BIOS 설정은 자동 변경하지 않는다.

#### Regression Guard

Before physical QA, `emulator -list-avds`, `adb devices`, and a cold boot of the selected x86_64 AVD must all pass before reporting Android callback or release QA as complete.

### ERR-202608160006 — Windows Developer Mode required for plugin build

**Status:** RESOLVED / VERIFIED
**Task/Phase:** Phase 15 / Windows runtime QA
**Area:** Local Windows build

#### Fingerprint

```text
CORE_MESSAGE: Building with plugins requires symlink support
COMPONENT: Flutter Windows build / daegil_app
```

#### Investigation

- `daegil_app` is the current implementation project; its analyze, test, and web release build pass.
- Windows build reaches the platform toolchain but stops before compilation because Flutter cannot create plugin symlinks.
- The Windows Settings UI toggle was switched from Off to On through UI automation, but a direct symbolic-link probe still returns `WinError 1314`.
- The current user therefore still lacks `SeCreateSymbolicLinkPrivilege`; an elevated terminal or organization policy change is required before Flutter can create plugin links.

#### Required Fix

Owner must enable Windows Settings > System > For developers > Developer Mode, then rerun `flutter build windows --debug` from `C:\Users\every\Documents\대길 개발\daegil_app`. No BIOS/security bypass was performed.

#### Resolution

- Owner completed the required elevated build step.
- `flutter build windows --debug --no-pub` and `flutter build windows --release --no-pub` both completed successfully.
- Release executable launched and displayed the `대길` consent screen with the hanbok cat asset and Google sign-in entry point.

### ERR-202608160007 — Google OAuth redirect URI mismatch

**Status:** RESOLVED / VERIFIED
**Task/Phase:** Phase 15 / Google OAuth verification
**Area:** Google Cloud OAuth client configuration

#### Fingerprint

```text
HTTP_STATUS: 400
ERROR: redirect_uri_mismatch
CALLBACK: https://nbdgwssdikmzitebqwkq.supabase.co/auth/v1/callback
```

#### Investigation

- The corrected Supabase project URL resolves and registration RPC returns HTTP 200.
- The authorize endpoint returns HTTP 302 to Google.
- The Windows release app reaches the Google account page, which then rejects the request because the Supabase callback is not registered on the Google OAuth client used by Supabase.

#### Required Fix

In Google Cloud Console, open the Web OAuth client configured in Supabase Authentication > Sign In / Providers > Google and add this exact Authorized redirect URI:

`https://nbdgwssdikmzitebqwkq.supabase.co/auth/v1/callback`

Save it, wait for propagation, then repeat Google sign-in. The custom app scheme remains the Supabase `redirect_to`; it must not replace the Supabase callback in Google Cloud.

#### Resolution

- The Google web client callback was registered and the Supabase Google provider was synchronized with that client.
- Windows OAuth now uses a loopback callback server on `http://localhost:3000` and exchanges the PKCE code in the same app process.
- Live verification completed: Google account selection returned to the local callback page and the app transitioned to the authenticated fortune home screen.

#### 2026-08-16 — Auth widget test could not find sign-in button

**Symptom:** The expanded cat illustration pushed the sign-in button below the initial viewport, so the widget test's first finder saw zero mounted `ElevatedButton` widgets.

**Resolution:** Updated the test to scroll the `ListView` and call `ensureVisible` for each consent row and the sign-in button. The production widget behavior was unchanged.

**Validation:** Targeted test and full `flutter test --no-pub` both pass.

#### 2026-08-16 — Android OAuth relay allowlist diagnosis (superseded)

**Symptom:** The newly installed APK showed `not_found` / `requested function was not found`, and Google OAuth did not return to the app.

**Evidence:** The deployed function list contains `oauth-mobile-redirect` as ACTIVE, and a live request to its exact URL returns `HTTP 302` to `com.example.daegil_app://login-callback/`. The Supabase URL Configuration screenshot contains only the custom scheme and localhost; it does not contain the HTTPS relay URL.

**Initial diagnosis:** The mobile HTTPS relay was not in the supplied screenshot's Additional Redirect URLs. Adding it corrected the allowlist, but the same failure persisted; this was not the final root cause.

**Required fix:** Add the exact HTTPS relay URL to Additional Redirect URLs and save it before reinstalling/testing the APK. Keep the Google provider callback at `/auth/v1/callback`.

**Regression guard:** `npx supabase functions list` confirms the relay is ACTIVE; live smoke test confirms the exact endpoint returns the expected 302 deep-link location.

#### 2026-08-16 — Android OAuth deep-link scheme was not a valid URI scheme

**Symptom:** Google and Supabase Auth both completed with HTTP 302, but the browser ended on `requested function was not found` instead of reopening the app.

**Evidence:** Supabase unified logs show the Android app requested the configured OAuth redirect and Google returned successfully to `/auth/v1/callback`. The relay was ACTIVE and its post-deploy invocations had no errors. The next-hop URI was `com.example.daegil_app://login-callback/`; independent URL parsers reject it because URI schemes may not contain `_`.

**Root cause:** The Android application ID was reused verbatim as a URI scheme even though it contains an underscore. Android package identifiers and URI schemes have different syntax constraints. The browser could not dispatch the invalid scheme back to `MainActivity`, leaving the OAuth flow outside the app.

**Resolution:** Changed the mobile OAuth scheme to `com.example.daegilapp`, updated the Android intent filter and Flutter default, changed Supabase Site URL and Additional Redirect URLs to the valid direct deep link, removed the obsolete invalid/relay entries, and redeployed the relay with the corrected fallback scheme.

**Regression guard:** Production config rejects the underscored scheme, a focused test asserts the valid default deep link, and the live Supabase authorize endpoint accepts the corrected direct redirect.

#### 2026-08-16 — Native ad dependency initially failed analysis

**Symptom:** The first native Rewarded implementation used `const StateError` and triggered analyzer errors because `StateError` is not const in this SDK/runtime.

**Resolution:** Removed the invalid const constructors, added override annotations, and replaced the unused callback underscores with named callback parameters.

**Validation:** `flutter analyze --no-pub`, full Flutter tests, and debug APK build pass.

#### 2026-08-16 — AdMob SSV callback validation returned HTTP 400

**Cause:** The deployed verifier expected a map of RSA keys, while Google's current AdMob SSV response is a rotating `keys` array containing ECDSA/P-256 public keys. The expected ad-unit/reward secrets were also not configured.

**Resolution:** Updated the verifier to parse the current key-array format, convert DER ECDSA signatures for WebCrypto verification, configured the Android ad unit with reward item `fortune` and amount `1`, and redeployed `admob-ssv`.

**Next check:** Repeat AdMob's callback URL validation after the console test request is regenerated.

#### 2026-08-16 — Android OAuth fallback and relay correction

**Symptom:** Android OAuth returned to localhost or the Supabase API root, producing connection-refused or `requested path is invalid` pages.

**Cause:** The Windows-only localhost callback and the hosted Supabase API root were being used as fallback targets for a mobile flow that needs an app deep link.

**Resolution:** Added a public Supabase Edge Function relay at `/functions/v1/oauth-mobile-redirect`. It forwards the OAuth code/state to `com.example.daegil_app://login-callback/`; no open redirect is accepted. The first relay deployment returned Edge Runtime 500 because a null 302 body was used; changing it to an empty body produced the verified HTTP 302 response.

#### 2026-08-27 — OAuth session navigated before registration sync

**Symptom:** Google could create a Supabase session while the app entered the home screen before `complete_my_registration` finished. A failed RPC therefore looked like successful signup, and an external OAuth process restart could lose in-memory consent state.

**Root cause:** `authenticationChanges` set `isAuthenticated=true` before firing an unawaited registration RPC; the auth screen navigated on that first state change.

**Resolution:** Split authenticated-session state from app-entry authorization. The app now remains on the registration gate until the RPC succeeds, supports re-confirming consent after process restoration, and maps sync errors to safe Korean UI copy.

**Regression guard:** Controller tests prove that navigation remains locked while registration is pending and after sync failure.

#### 2026-08-27 — Native Rewarded Ad had no server attempt lifecycle

**Symptom:** The SDK could show an ad, but it generated local attempt IDs/tokens and left impression, reward, and dismiss reports empty. SSV could not match a DB row and no server entitlement or generation started.

**Resolution:** Added authenticated prepare/impression/claim/dismiss Edge Functions, server-owned opaque SSV challenges, frozen reward/security specifications, DB attempt transitions, generation start fencing, and client gateway wiring. SSV now starts the generation worker when verification grants the reward.

**Validation:** Deployed endpoints return 401 without a user JWT, SSV health returns 200, and a rolled-back remote DB smoke test completed prepare → impression → claim → dismiss.

#### 2026-08-27 — Supabase project restore and missing legal seed

**Symptom:** DB push and Management API SQL calls timed out; after restore, ad preparation failed with `AI_CONSENT_REQUIRED`.

**Root causes:** The free Supabase project status was `INACTIVE`, and `legal_documents` contained zero active rows, so signup created no AI consent event.

**Resolution:** Restored the project through the official Management API, verified `ACTIVE_HEALTHY`, seeded development terms/privacy/AI documents with public Supabase-hosted pages, and connected the privacy checkbox to its server document ID. Final legal copy still requires owner/legal approval before release.

#### 2026-08-27 — Fortune rating card overflowed on 320px phones

**Symptom:** A new responsive test found a 24px right overflow on `FortuneResultScreen`.

**Resolution:** Reflowed the enlarged cat illustration and rating information into a compact two-column layout. All major cat-themed pages and birth-time controls now pass 320px overflow tests.

#### 2026-08-28 — Consent matching and generation dispatch recovery gaps

**Symptoms:** Legal consent controls depended on Korean title fragments, a requirements RPC failure could leave the auth gate loading indefinitely, and a failed internal generation-worker dispatch changed only the Edge response while the database remained `generating`.

**Root causes:** The client ignored the server-owned `document_type`; expected Supabase/format exceptions were not normalized at the auth boundary; the rewarded-ad helper had no fenced database transition for a failed worker request.

**Resolution:** Matched AI/privacy documents by `document_type`, added a safe retryable load-failure UI, restored completed sessions from the server gate without repeated consent, retried transient SSV state polling, and added `mark_generation_dispatch_failed(session_id, epoch)` so a failed worker dispatch records `failed` before entitlement or `recovery_pending` after entitlement.

**Validation:** Added regression tests for title-independent privacy consent, requirements-load recovery, completed-session restoration, and transient Supabase polling. The migration and all affected Edge Functions were deployed; unauthenticated endpoints fail closed with HTTP 401, SSV health returns HTTP 200, and the linked database reports no pending migrations.

#### 2026-08-28 — Cute redesign exposed narrow dropdown and visual-capture regressions

**Symptoms:** The first redesign pass produced a 4.4 px overflow in the birth hour/minute fields at 320 px. Flutter screenshot tests also rendered explicit AppBar/button Korean text as square glyphs, repeated the Cat Home fallback caption, and pushed the Auth CTA below the initial viewport.

**Root causes:** The birth form's card padding reduced each two-column dropdown below its content width. The screenshot harness loaded the Korean body font but not explicit AppBar/button styles. Cat Home supplied the same fallback copy both inside and outside the video widget, and the larger mascot/legal cards lengthened the Auth list.

**Resolution:** Reflowed all birth-time fields vertically below 280 logical pixels, assigned the capture font to explicit AppBar/button styles, kept the Cat Home caption in one owner, and moved the Google action into a persistent Auth bottom panel.

**Regression guard:** The 320 px responsive tests, 45-test functional suite, nine-screen 390 x 844 capture run, and `design-qa.md` comparison all pass.

#### 2026-08-29 — Vercel web deployment returned NOT_FOUND

**Symptom:** The Vercel project URL returned HTTP 404 with `X-Vercel-Error: NOT_FOUND` even though the GitHub branch contained the web package.

**Cause:** The Vercel project Root Directory was `.` and its initial Framework Preset was `Other`, while the Next.js app lives under `daegil_web`. The project also had SSO deployment protection enabled for the intended public experience.

**Resolution:** Updated the project Framework Preset to Next.js, disabled SSO deployment protection through the authenticated Vercel CLI, and set the remote project Root Directory to `daegil_web`. A production deployment from the GitHub `main` commit completed successfully; both the deployment URL and the project URL now return HTTP 200.

#### 2026-08-29 — Opaque mascot backgrounds looked pasted onto the page

**Symptoms:** The mascot PNGs showed lighter square backgrounds against the app paper. Circular backplates and floating paw bubbles at opposite image corners added unrelated layers and made the artwork feel inserted rather than integrated.

**Root causes:** The page token (`#F5E6C8`) did not match the assets' sampled edge values (`#F9E7CA` to `#FDF3D7`). The initial edge blend was calculated over the full banner width rather than the fitted square asset, so large banners retained visible vertical strips.

**Resolution:** Aligned the shared paper/image canvas to `#FBEACD`, removed image-corner decorations and backplates, flattened the surface system, and constrained a two-axis edge blend to the real 1:1 asset bounds.

**Regression guard:** `design-qa.md` records benchmark analysis and three visual iterations. All nine final 390 x 844 captures were compared with the supplied benchmark in the same visual input; 320 px tests, the full Flutter suite, and the APK build pass.

#### 2026-08-31 — Web Google OAuth callback remained in loading state

**Symptom:** After selecting a Google account, the web callback could remain on `로그인을 확인하는 중이다냥…` instead of returning to the app.

**Root cause:** The browser Supabase client had `detectSessionInUrl: true` while `/auth/callback` also explicitly exchanged the same PKCE authorization code. The one-time code/verifier could therefore be consumed by competing handlers; the callback promise also had no rejection or timeout path.

**Resolution:** Disabled automatic URL session detection for the web client so `/auth/callback` owns the single PKCE exchange, and added callback error-parameter handling, a 15-second timeout, and a catch path with retry guidance. The existing Supabase auth and registration contract is unchanged.

**Validation:** Web typecheck and production build pass; a local invalid-code callback exits to the explicit login-failure message instead of remaining in the loading state.

#### 2026-09-05 — Concurrent ad CTA interrupted preload and masked load failures

**Cause:** `start()` allowed overlapping calls while its first preload awaited
the SDK. The next invocation attempted preparation without a loaded ad, moving
the shared flow to failed. A failed preload also fell through to preparation,
replacing `ad_load_failed` with `ad_not_preloaded`.

**Fix:** Reserve the start operation synchronously, release it in `finally`,
reject a new flow during reward verification/pending reward, and prepare only
after the ready state. No reward or entitlement rule changed.

**Regression evidence:** Two new controller tests fail before the patch and pass
afterward. All 47 widget tests and Flutter analyze pass. Physical ad visibility
is not proven: the current ADB device list is empty.

#### 2026-09-05 — Native authentication failures left loading/pending UI stuck

**Cause:** `completeRegistration()` had no response deadline, so an unresolved
RPC kept `isLoading=true`. The auth stream subscription had no error callback;
an OAuth error escaped unhandled and left `isAuthPending=true`, disabling retry.

**Fix:** Limit registration completion to 15 seconds, retain the legal gate on
timeout, and handle auth stream errors without logging provider error contents.
Check `ref.mounted` before registration completion/failure writes; the added
timeout otherwise raised `UnmountedRefException` if the controller was disposed.

**Evidence:** Regression tests reproduced all three defects before correction.
All 50 widget tests and Flutter analysis pass afterward. The stalled-RPC test
also proves a late result does not silently authenticate and explicit retry works.
This does not establish the cause of the separately reported live web login hang.

**Do not repeat:** A successful build or error-callback test does not prove a real
Google account can finish login. Preserve server registration gating on timeout.

#### 2026-09-05 — Valid AdMob SSV signatures rejected and callback misconfigured

**Cause:** `URL.search` includes `?`, but Google signs only the query contents.
The handler included the separator, compared numeric ad units against full SDK
IDs, and read nonexistent `timestamp_millis` instead of signed `timestamp`.
Separately, the live console held Google's key URL as its callback URL.

**Fix:** Exclude the separator without re-encoding. Map only the configured
numeric unit to its full ID, preserving rejection of other publishers. Validate
and use signed reward time. Valid signed unrelated-unit/spec callbacks receive
HTTP 200 rejected with no DB calls; this accommodates the console placeholder
unit without issuing rewards. Invalid signatures still fail closed.

**Evidence:** Regression checks failed before each fix. Five actual-handler tests
using real synthetic ECDSA signatures pass, including tampering, wrong publisher,
missing signature, oversized query, and no-reward health probes. Remote v11 is
ACTIVE. Google console confirmed its signed synthetic callback, then the correct
backend URL was saved and verified after reload. Real reward delivery is unproven.

**Do not repeat:** Key discovery and callback delivery use different endpoints.
A console HTTP 200 is not evidence of earned entitlement or real ad display.
Reference: https://developers.google.com/admob/flutter/ssv

#### 2026-09-05 — Home action and pass-choice UX drift

Home claimed the Fortune was ready before generation and spent a pass immediately
when available, hiding the ad alternative. Added explicit confirmation/choice
using server eligibility, preserving ads at 3/3. New tests cover pass count 0/3,
cancel with no spend, single-flight pass operation and failure retry. A 320px/2x
font regression exposed a 92px badge overflow; Flexible text corrects the layout.
All 53 widget tests and Flutter analysis pass. The visual harness now keys each
page's ProviderScope because varying override counts on a reused scope fails.

#### 2026-09-05 — Web registration RPC errors treated as success

The web client ignored RPC `error`, removed pending consent, and entered Home
without checking the server gate. A test reproduced the missing rejection before
the fix. Registration now checks the error, preserves pending data for retry, and
requires explicit gate NONE for entry. Requests have finite per-request deadlines.
A newer consent snapshot is not removed by an older successful request. Existing
OAuth sessions can finish registration without another Google round trip. Callback
errors link to auth; legal-load failure offers reload.

Five helper tests, web typecheck/build and repository/security checks pass. This
does not prove the originally reported real-account OAuth root cause. Windows
Node 20 does not expand `lib/*.test.cjs`; npm test uses the explicit test file.
