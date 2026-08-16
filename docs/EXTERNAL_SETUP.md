# External Setup & Current Reference Gate — v8 Compact

Codex가 코드로 완료할 수 없는 console/credential 작업을 분리한다.

Status:

```text
NOT_STARTED
CODE_READY
MANUAL_ACTION_REQUIRED
CONFIGURED
VERIFIED
BLOCKED
```

## Phase 0 Toolchain Record

| Tool | Detected value | Status |
|---|---|---|
| Flutter | 3.41.9 stable (`C:\tools\flutter`) | VERIFIED |
| Dart | 3.11.5 (`C:\tools\flutter\bin\cache\dart-sdk`) | VERIFIED |
| Python | 3.13.9 | VERIFIED |
| Git | repository initialized | VERIFIED |
| Supabase CLI | npx Supabase CLI 2.114.0 | CODE_READY / BLOCKED by Docker engine |
| Deno/Node | not required in Phase 0 | NOT_STARTED |
| FlutterFire CLI | not required in Phase 0 | NOT_STARTED |
| Firebase CLI | not required in Phase 0 | NOT_STARTED |

Phase 2/4 environment note (2026-08-15): `npx supabase 2.114.0` is available, but local `supabase db lint --local` is blocked because Docker Desktop's Linux engine cannot start. No `SUPABASE_ACCESS_TOKEN` or project ref is present in the current environment.

## Project Identity

Development placeholder 사용 가능:

```text
internal code name = fortune_cat_app
```

Owner-required production values:

```text
APP_DISPLAY_NAME = TBD
ANDROID_APPLICATION_ID = TBD
IOS_BUNDLE_ID = TBD
APPLE_TEAM_ID = TBD
PUBLIC_WEB_DOMAIN = TBD
PRIVACY_URL = TBD
TERMS_URL = TBD
ACCOUNT_DELETION_URL = TBD
```

`com.example...`을 production console에 사용하지 않는다.

## Service Matrix

| Service | Purpose | Initial Status |
|---|---|---|
| Supabase Dev | Auth/DB/Edge | MANUAL_ACTION_REQUIRED |
| Supabase Prod | Production backend | NOT_STARTED |
| Google OAuth | Login | DEV_CONNECTED / MANUAL_ACTION_REQUIRED for release IDs and physical QA |
| Apple Developer / Sign in with Apple | Login/deletion | DEFERRED by owner request |
| Kakao Developers | Login | OUT_OF_SCOPE for current implementation |
| Firebase Dev | Analytics/Crash | NOT_STARTED |
| Firebase Prod | Analytics/Crash | NOT_STARTED |
| AdMob Android | Rewarded | NOT_STARTED |
| AdMob iOS | Rewarded | NOT_STARTED |
| AI Provider(s) | Fortune generation | NOT_STARTED |
| Public Website | privacy/terms/delete | NOT_STARTED |
| App Store Connect | iOS release | NOT_STARTED |
| Google Play Console | Android release | NOT_STARTED |

## AI Development Without Provider

Production Provider 미정이어도:

```text
MockFortuneProvider
```

로 전체 flow를 구현/테스트.
Real Provider credential 없다고 Phase 0~13을 멈추지 않는다.

## Ad Development

Non-production은 Google-provided current test ad units/test device config만 사용.
실제 production AdMob ID를 dev/test에서 사용 금지.

## Environment

Client-visible:

```text
APP_ENV
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
ADMOB_REWARDED_UNIT_ID
```

Server-only:

```text
AD_SECURITY_MODE
AI_GENERATION_ENABLED
AI_PRIMARY_PROVIDER
AI_FALLBACK_PROVIDER_IDS
AI_* caps
provider credentials
Supabase secret/admin credential
SSV expected config
```

Secrets를 Markdown/Progress Log에 복사하지 않는다.

## Toolchain Lock

Phase 0에서 실제 값 기록:

```text
Flutter
Dart
Git
Supabase CLI
Deno/Node if used
FlutterFire CLI
Firebase CLI
```

Task와 무관한 upgrade 금지.
Major/minor upgrade는 별도 Task + baseline/full regression.

## Current Official Docs Verification

다음 integration은 구현 직전 공식문서 확인 필수:

```text
Supabase Edge Function auth
Supabase Flutter Auth/OAuth
Supabase API keys / RLS / DB functions
Google AdMob Rewarded Ads
Google AdMob SSV
Firebase Analytics
Firebase Crashlytics
Apple Sign in with Apple / account deletion / token revocation
Google Sign-In
Kakao Login
선택된 AI Provider API
App Store / Google Play current policy
```

Source order:

```text
1. official vendor docs
2. official vendor-maintained package/repo
3. formal standard
4. third party only if official insufficient
```

Network/reference unavailable + local verified reference 없음:

```text
BLOCKED_EXTERNAL_REFERENCE
```

API shape/version/policy를 기억으로 추측하지 않는다.

## Verification Ledger Entry

Progress/decision log에 최소:

```text
Task/Phase
Vendor
Topic
Official URL
Verified date
Behavior relied on
Version/API note
```

원문을 대량 복사하지 않는다.

## OAuth Manual Gate

Production IDs 확정 후:

```text
Google OAuth app
Apple identifier/service config
Kakao app/redirect config
```

실제 callback/deep-link를 physical device에서 검증.

현재 확인된 개발 Android Google OAuth client:

```text
Client ID: 271172249944-7e181c4trkh6eg511l6fenrcb9v3q590.apps.googleusercontent.com
Package: com.example.daegil_app
SHA-1: F4:04:9C:D4:E0:6E:57:EA:43:13:D7:96:60:26:F5:1E:11:C1:08:22
Status: TEST / development client only
```

이 client ID는 비밀키가 아니지만, production release signing SHA-1과 별도다. Google OAuth production 전환 및 physical-device callback 검증 전에는 release credential로 간주하지 않는다.

Supabase Auth Google Provider 상태:

```text
Enabled: yes (user-confirmed)
Client ID/Secret: entered in Supabase Dashboard (user-confirmed)
Callback URL: https://nbdgwssdikmzitebqwkq.supabase.co/auth/v1/callback
Mobile redirect URL: com.example.daegilapp://login-callback/
Development real Auth flag: `ENABLE_SUPABASE_AUTH=true` (only with explicit dart-define)
Apple: not configured
Web OAuth client/domain: not configured
```

현재 구현은 Google 로그인만 지원한다. Kakao와 Apple 로그인은 UI·adapter·console 설정 대상에서 제외한다.

Supabase `Authentication → URL Configuration → Redirect URLs`에도 mobile redirect URL을 추가해야 실제 앱 callback이 허용된다. 이는 공개 웹사이트를 만드는 설정이 아니다.

## Apple Operations

Sign in with Apple을 사용하므로 production 전 current Apple docs로:

```text
account deletion
provider token revocation
client secret/key rotation if applicable to chosen flow
```

검증.

## Firebase Consent Setup

Native configuration에서 automatic collection default OFF.
Runtime opt-in만 믿지 않는다.

## Public Web Pages

Production:

```text
/privacy
/terms
/account-deletion
```

실제 HTTPS public domain 필요.

## Backup / Retention Review

Release 시 실제 Supabase plan의 backup retention을 확인하고 privacy copy와 일치시킨다.
Active DB delete와 managed backup retention을 같은 것으로 표현하지 않는다.

## AdMob SSV Verification Ledger

```text
Task/Phase: Phase 7 / SSV webhook contract
Vendor: Google AdMob
Topic: Rewarded SSV callback parameters, custom_data escaping, public-key verification, duplicate transaction handling
Official URL: https://developers.google.com/admob/flutter/ssv
Verified date: 2026-08-15
Behavior relied on: callback query includes ad_unit, custom_data, key_id, reward_amount, reward_item, signature, timestamp, transaction_id; custom_data may be percent-escaped; signature verification uses the matching AdMob public key
Version/API note: Current official Flutter SSV guidance; crypto implementation deferred to a vetted server library
```
