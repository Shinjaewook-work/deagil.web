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
Phase 2 migration/RPC/RLS skeleton is present; live Supabase reset verification is pending Dev project/CLI setup.
Phase 3 mock-first auth/legal foundation is present; production OAuth console setup remains manual.
Phase 4 Cat Home and birth profile foundation is present; the owner-provided cat MP4 remains a release asset gate.
Continue with Phase 5 — Rewarded Ad service interface and fake flow.
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
