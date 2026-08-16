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
Phase 2 migration/RPC/RLS skeleton is present; server-driven registration RPCs were added, pushed to the linked Dev project, and remote endpoints were verified.
Phase 3 mock-first auth/legal foundation is present; Flutter now loads legal requirements from Supabase and syncs registration after auth, while release IDs and physical callback QA remain manual.
Phase 4 Cat Home and birth profile foundation is present; the owner-provided cat MP4 is connected for development and native build verification.
Phase 5 Rewarded Ad service interface and fake flow is present; real AdMob SDK/console integration remains a production gate.
Phase 6 MockFortuneProvider/provider architecture is complete with strict validation, generation fencing, and budget boundaries; OpenRouter Nemotron server adapter, Supabase secrets, Dev provider registry, and protected internal generation worker are deployed as DEV_APPROVED.
Phase 7 SSV webhook is deployed as `admob-ssv` with GET/query bounds, Google RSA-SHA256 key verification, replay/token matching, and late-callback handling; real AdMob expected-spec secrets remain a manual gate.
Phase 8 pass ledger is bound to `use_my_fortune_pass()` and `use-fortune-pass`; active cap, reserve/redeem, recovery restore, and backend pass count are server-owned.
Phase 9 Fortune Result is bound to `get_my_app_state()`; only server-derived `UNLOCKED` payloads render, while locked/generating/recovery/failed states do not fall back to mock content in remote mode.
Phase 10 notification settings now persist server preferences and cancel local schedules on logout/deletion; native permission/channel and physical time-boundary QA remain.
Phase 11 Supabase AI-consent withdrawal and `delete-account` Edge Function are implemented; OAuth provider revocation and remote migration retry remain gates.
Phase 12 telemetry opt-in/opt-out now clears unsent crash reports where the abstraction supports it and rejects sensitive/oversized parameters; Firebase native wiring remains manual.
Phase 13 security hardening audit and client secret scan pass; live adversarial/RLS race execution remains follow-up validation.
Phase 14 production config now fails closed unless Firebase project/app IDs and existing production approvals are present; actual credentials/console approvals remain manual.
Phase 15 release audit is complete: automated artifact/security checks pass, a Dev release APK was built, and remote migration `202608160004` is applied; production identities, credentials, physical QA, signing, store, and legal gates remain open.
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
