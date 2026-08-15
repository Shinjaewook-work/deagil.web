# Session Resume

Harness:

```text
v8 Compact
```

Source of Truth:

```text
LUNA_IMPLEMENTATION_MASTER.md
```

Current status:

```text
Phase 0 scaffold and native verification are complete.
Flutter 3.41.9 / Dart 3.11.5 are installed at C:\tools\flutter; this shell prepends that path for commands.
Phase 1 app foundation/design is complete.
Phase 2 migration/RPC/RLS skeleton is present; the linked Dev project migration was pushed and remote table endpoints were verified.
Phase 3 mock-first auth/legal foundation is present; Google development OAuth is connected in Supabase, while release IDs and physical callback QA remain manual.
Phase 4 Cat Home and birth profile foundation is present; the owner-provided cat MP4 is connected for development and native build verification.
Phase 5 Rewarded Ad service interface and fake flow is present; real AdMob SDK/console integration remains a production gate.
Phase 6 MockFortuneProvider/provider architecture is complete with strict validation, generation fencing, and budget boundaries.
Phase 7 SSV webhook contract is present with injected signature verification, replay protection, token matching, and late-callback handling; production server crypto/deployment remains a gate.
Phase 8 pass ledger rules are present with active cap, reserve/redeem, restore, expiry, and goodwill boundaries; Supabase transaction/UI binding remains.
Phase 9 typed Fortune Result model and result screen are present with AI disclosure and rewarded completion routing; backend result binding remains.
Phase 10 local notification permission/schedule, safe tap route, and logout cancellation contracts are present; native SDK integration remains.
Phase 11 settings/privacy/account routes and consent withdrawal contracts are present; Supabase deletion and OAuth revocation remain production gates.
Phase 12 analytics/crash opt-in and normalized safe event contracts are present; native provider configuration remains a production gate.
Phase 13 security hardening audit and client secret scan are present; live Supabase adversarial execution remains a follow-up validation task.
Phase 14 production fail-closed config boundary is present; actual service credentials and console approvals remain manual gates.
Phase 15 release audit is present; automated artifact/security checks pass, but production identities, credentials, physical QA, signing, store, and legal gates remain open.
Continue by resolving `MANUAL_ACTION_REQUIRED` release gates; then run the physical P0 matrix.
```

Phase 0 changed:

```text
pubspec.yaml
analysis_options.yaml
lib/main.dart
lib/bootstrap.dart
lib/app/app.dart
lib/core/config/app_config.dart
test/smoke_test.dart
config/dev.env.example
config/prod.env.example
```

Critical current rules:

```text
3/3 Rewarded Ad allowed
Reward entitlement ≠ pass compensation
OpenAI optional
free AI API backend-only
AD_SECURITY_MODE is one preset: fast|reward_gated|ssv_strict
no unlock_status
no current FULFILLMENT_MISSED UI state
pass active cap = available + reserved <= 3
pass stays reserved through recovery
birth write is server validated
consent events are append-only and re-consentable
earned entitlement is never re-monetized
```
