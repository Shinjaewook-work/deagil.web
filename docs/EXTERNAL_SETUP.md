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
| Supabase Dev | Auth/DB/Edge | NOT_STARTED |
| Supabase Prod | Production backend | NOT_STARTED |
| Google OAuth | Login | NOT_STARTED |
| Apple Developer / Sign in with Apple | Login/deletion | NOT_STARTED |
| Kakao Developers | Login | NOT_STARTED |
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
