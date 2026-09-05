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

2026-09-05 web result integrity: the result view no longer substitutes demo text
when a remote payload is missing. It requires UNLOCKED and an ungated session
(or the existing explicit demo flow), otherwise it offers a state reload.
Actual-page render regressions reproduced both the sample fallback and stale
locked/gated rendering before the fix. Eight web tests, typecheck and build pass.
This does not prove live provider generation or real advertising. Remaining web
work includes expiry refresh, complete payload validation and rewarded lifecycle.

2026-09-05 web registration recovery: pending consent is retained on RPC failure
and cleared only after confirmed success, without deleting a newer selection.
Web auth/session/legal/state requests have finite deadlines. Existing sessions
retry registration instead of restarting Google OAuth; only server gate NONE
enters Home/Result. Auth navigation no longer exposes the other app screens.
Callback errors have a return-to-login link. Five web tests, typecheck/build and
repository/security guards pass. Commit `2b94879` was pushed to
`origin/codex/daegil-web`; Vercel production deployment
`dpl_7pRaLHS81WQ3qgL2HoQF34RwCcpK` is Ready. On the public primary domain,
the OAuth error return link reaches `/?login=retry`, finishes restoration and
shows the consent form with Google disabled until consent is entered.
Successful real-account sign-in remains unproven and needs user-entered consent.

2026-09-05 native Home polish: preserved the selected paper/cat benchmark, shortened
the caption, and made the CTA truthful. An explicit cream-paper sheet now offers
ad/pass/cancel; 3 active passes do not hide the ad choice. Cancel spends nothing.
Pass selection is single-flight and failures offer retry. The badge wraps at
320px/2x text. All 53 widget tests, Flutter analyze, and visual capture pass.
Current previews and evidence limits are in `daegil_app/design-qa.md`.
This is native-only; no web design/deployment changes were made in this step.

2026-09-05 AdMob SSV: correct publisher is Edge Google session `authuser=1`.
The saved Android callback incorrectly pointed to Google's public-key JSON.
Fixed signature input (exclude leading `?`), numeric/full ad-unit mapping, and
signed `timestamp` handling; deployed `admob-ssv` v11. Google's signed synthetic
test now passes. Saved the correct callback and verified it after reload:
`https://nbdgwssdikmzitebqwkq.supabase.co/functions/v1/admob-ssv`.
Console placeholder-unit callbacks are signature-verified, then acknowledged as
HTTP 200 rejected without DB/reward work; invalid signatures remain 400.
Five actual-handler ECDSA tests pass. Android overview still says `검토 필요`;
real ad display and reward grants remain unverified.

2026-09-05 auth recovery follow-up: native registration completion now stops
waiting after 15 seconds and remains on the registration gate for retry. OAuth
stream errors release the pending-login UI using a normalized error, and late
registration results cannot update disposed state or enter the app after timeout.
All 50 widget tests and Flutter analysis pass; the three new regressions each
failed before their respective fixes. This is native recovery coverage, not proof
of the reported live web login root cause. The deployed web callback contains the
existing single-handler and 15-second timeout fix; live error callbacks terminate.
Successful web account login still needs the user's own age/legal confirmation.
No browser password store was read. Continue the separate advertising and design
work; the overall app goal is not complete.

Latest native debug APK was rebuilt with real Supabase auth enabled (public
client configuration only): `daegil_app/build/app/outputs/flutter-apk/app-debug.apk`.
SHA-256: `7AD2770A17B839692A5E723D22B1BE2501B4ED0FA39FB8D142AD4639503A0ECB`.
Build, harness lint, repo guard, and Master audit pass. ADB still lists no device;
this is an installable development build, not a production-ready/store release.

2026-09-05 continuation: verified the app directory is intact and Git was clean
at entry; sandbox access denial had misleadingly appeared as deleted files.
Fixed concurrent rewarded-ad CTA handling and stopped preparation after failed
preload. Both regressions failed before the fix; all 47 widget tests and Flutter
analysis pass afterward. No Android device is currently attached (`adb devices`).
Real ad display, successful live OAuth completion, production readiness, and the
requested visual refinement still require verification. Do not mark the overall
app goal complete from these controller tests.

Live Edge probe: `https://apps.admob.com/` redirects the current default Google
session to `https://admob.google.com/signup/info/user-age-missing?sac=true`.
The page says the Google account needs a birth date. It is not yet established
that this default account is the publisher account previously configured; check
the account selection before diagnosing the actual publisher account. Do not
invent a birth date or infer a missing/approved ad unit from this screen.

```text
Phase 0 scaffold and native verification are complete.
Flutter 3.41.9 / Dart 3.11.5 are installed at C:\tools\flutter; this shell prepends that path for commands.
Phase 1 app foundation/design is complete.
Phase 2 migration/RPC/RLS skeleton is present; server-driven registration RPCs were added, pushed to the linked Dev project, and remote endpoints were verified.
Phase 3 mock-first auth/legal foundation is present; Flutter now loads legal requirements from Supabase and syncs registration after auth, while release IDs and physical callback QA remain manual.
Phase 4 Cat Home and birth profile foundation is present; the owner-provided cat MP4 is connected for development and native build verification.
Phase 5 Rewarded Ad service interface and fake flow is present; real AdMob SDK/console integration remains a production gate.
Phase 6 MockFortuneProvider/provider architecture is complete with strict validation, generation fencing, and budget boundaries; OpenRouter Nemotron server adapter, Supabase secrets, Dev provider registry, and protected internal generation worker are deployed as DEV_APPROVED.
Phase 7 SSV webhook is deployed with Google ECDSA/P-256 verification. Android callback URL is saved and console-verified; real device reward delivery remains unverified.
Phase 8 pass ledger is bound to `use_my_fortune_pass()` and `use-fortune-pass`; active cap, reserve/redeem, recovery restore, and backend pass count are server-owned.
Phase 9 Fortune Result is bound to `get_my_app_state()`; only server-derived `UNLOCKED` payloads render, while locked/generating/recovery/failed states do not fall back to mock content in remote mode.
Phase 10 notification settings now persist server preferences and cancel local schedules on logout/deletion; native permission/channel and physical time-boundary QA remain.
Phase 11 Supabase AI-consent withdrawal and `delete-account` Edge Function are implemented; OAuth provider revocation and remote migration retry remain gates.
Phase 12 telemetry opt-in/opt-out now clears unsent crash reports where the abstraction supports it and rejects sensitive/oversized parameters; Firebase native wiring remains manual.
Phase 13 security hardening audit and client secret scan pass; live adversarial/RLS race execution remains follow-up validation.
Phase 14 production config now fails closed unless Firebase project/app IDs and existing production approvals are present; actual credentials/console approvals remain manual.
Phase 15 release audit is complete: automated artifact/security checks pass, a Dev release APK was built, and remote migration `202608160004` is applied; production identities, credentials, physical QA, signing, store, and legal gates remain open.
Continue by resolving `MANUAL_ACTION_REQUIRED` release gates; then run the physical P0 matrix.

Android QA follow-up: a `Pixel_6_x86` AVD was created from the x86_64 system image, but cold boot still fails because the Windows host does not expose CPU virtualization acceleration. BIOS/UEFI or Windows Hypervisor Platform changes remain owner-only; no security setting was changed automatically.

Latest UI follow-up: phone-width clipping was fixed with a shared `LunaPageFrame`, the Auth brand is `대길`, and all Fortune sentence/action output is now required to end in natural 냥체. The supplied cat-oracle concept was applied with warm cream/peach tokens, generated cat mascot artwork, paw accents, and a Cat Home navigation bar. `generate-fortune` was redeployed to Dev; Flutter analyze/test and web preview capture pass.

Latest benchmark-design follow-up: all nine app screens now use the supplied paper-illustration benchmark's restrained warm-paper field, thin brown outlines, cream cards, compact accents, and muted-pink CTA. Floating image-corner paws, circular backplates, repeated result artwork, and shadows were removed. The mascot edge tone is aligned to the page and `PaperBlendImage` fades only the outer opaque paper pixels inside the fitted asset bounds. The 320 px overflow suite, 45 functional tests plus visual capture, design QA, repository/security guards, and debug APK build pass. Final previews are under `C:/Users/every/.codex/visualizations/2026/08/29/daegil-benchmark-final`; the APK SHA-256 is `80ED34143ED45BA35F76F6D8D9C39965628469DC9F56ED6E553407A3233FE119`.

Android OAuth follow-up: the prior callback scheme reused the underscored application ID and was not a valid URI scheme. Mobile Auth now uses `com.example.daegilapp://login-callback/` directly; the Android manifest, Supabase Site URL/allowlist, and relay fallback are aligned. Install the APK built after this change before physical verification.
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

Current local runtime note:

- The current implementation is `daegil_app`; root-level Windows files generated during diagnosis were removed.
- `daegil_app` analyze/test/web release pass. Windows runtime remains gated by OS Developer Mode symlink support (`ERR-202608160006`).

Latest web follow-up:

- Added an independent `daegil_web` Next.js package for Vercel/Netlify deployment. It uses the existing Supabase auth/RPC/Edge Function contract, adds the additive `platform=web` path for `prepare-ad-session`, and copies the approved cat artwork without changing `daegil_app`.
- `daegil_web` typecheck, production build, local HTTP smoke test, Flutter analyze/test, harness lint, repository guard, and Master contract audit pass.
- GitHub `origin` now points to `https://github.com/Shinjaewook-work/deagil.web.git`; Edge/Git Credential Manager re-authentication as `Shinjaewook-work` succeeded and the web commits are pushed to the remote.

Latest Vercel deployment diagnosis:

- Vercel project `jeawook/deagil-web-gj8b` was configured with Root Directory `.` and Framework `Other`, so the project domain returned `X-Vercel-Error: NOT_FOUND` while the actual Next.js package lives under `daegil_web`.
- Framework was updated to Next.js and SSO deployment protection was disabled for public access. The latest web commit `cda2ba2` is on both `codex/daegil-web` and `main`.
- Root Directory is now set remotely to `daegil_web`. Production deployment `dpl_GMQnDK6mbEFvYaRWcGiiDWpF25pR` from `main` is `READY`; both its deployment URL and `https://deagil-web-gj8b.vercel.app/` return HTTP 200. Production Branch remains `codex/daegil-web` in the Vercel Git link and should be changed to `main` in Environments > Production > Branch Tracking if automatic pushes to `main` are desired.
- Vercel now has `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` for Production/Preview; the redeployed bundle contains the Supabase project URL and the public registration-requirements RPC returns HTTP 200. `NEXT_PUBLIC_WEB_REWARDED_AD_UNIT` remains unset because no real Google Ad Manager web rewarded unit was found; the existing mobile AdMob unit is not a valid browser GPT path.
