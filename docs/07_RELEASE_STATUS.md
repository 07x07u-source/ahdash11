# AHDASH | 11 — Canonical Release Status

**Authority:** sole current release-readiness authority  
**Last verified:** 12 September 2026  
**Rule:** a successful build is evidence, not by itself a release approval.  
**Test policy and current validation:** [09_TESTING_STRATEGY.md](./09_TESTING_STRATEGY.md)

## Evidence distinction

- The earlier successful Android release run is `OPERATOR_VERIFIED` for its known commit and artifacts.
- The 12 September current tree is `LOCAL_NON_VISUAL_TEST_GATE_GREEN`: static analysis and the shared Android/iOS Release-equivalent non-visual suite pass locally; Friends and Online remain removed from the active mobile product.
- A Codemagic release artifact for the current tree is still pending. The earlier signed artifacts do not represent the current tree.
- Provider configuration does not replace physical-device validation.
- A signed AAB/APK does not replace Google Play account, listing, track, products, publication, or review.
- Production migration deployment does not replace client, Edge Function, security, or operational validation.

## Current verdict

| Platform | State | Current truth |
|---|---|---|
| Android | **PARTIALLY READY** | Release infrastructure and earlier signed AAB/APK are proven, and the new football-Party product-scope tree has a green local analysis/non-visual gate; a current-tree Codemagic artifact, device, purchase, provider-runtime, Play, and final review gates remain. |
| iOS | **PARTIALLY READY** | Repository-side iOS integration/auth blockers are resolved and the state is `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION`; Apple/provider/signing confirmation, a macOS CI-signed IPA, TestFlight, physical iPhone validation, and App Store completion remain. |
| Desktop Web | **PARTIALLY READY** | Phase 1 identity/auth remains intact, and Phase 2 implements guest-capable local Party plus Solo/Classic using existing Supabase content contracts and mobile-compatible rules. Real catalog start-to-result, deployed browser/provider, accessibility/security, and later cloud-feature phases remain. |
| Admin | **PARTIALLY READY** | Broad guarded data tools exist; several areas are read-only/absent and Production role/workflow/provider validation remains. |
| Backend | **PARTIALLY READY** | Production schema is operator-verified at 27/27 with linked lint at 0 errors/16 warnings; client, Edge Function, and selected operational/security validation remains. |

## Android — PARTIALLY READY

### Proven release infrastructure

- Application ID: `com.ahdash.eleven`.
- Codemagic `android-release` workflow exists and fails closed for missing release signing or invalid Production AdMob application configuration.
- The workflow injects Firebase Android configuration, validates Production integrations, and builds signed artifacts.
- A successful release workflow ran on `main` from an earlier known commit. Static analysis, selected non-visual tests, Firebase configuration, Android signing, Production validation, and signed AAB build passed.
- A later workflow revision also added and proved signed APK generation.
- Verified outputs: `app-release.aab` and `app-release.apk`.
- Downloaded AAB SHA-256: `4456CEBEA870B826D79B670267C3D587E42BA80A39D43FD4C59E089D5EC2D4E4`.
- Verified Release certificate:
  - SHA-1: `1E:25:C3:09:0A:F3:1E:20:54:46:C5:5D:6B:B2:7D:45:17:77:B8:C7`
  - SHA-256: `43:47:5F:35:4B:73:F4:D2:C9:AD:45:66:3A:BF:D6:DF:FA:86:25:93:03:F9:1D:1B:2E:D6:A4:93:83:C1:86:47`
- Firebase Android Release injection and matching package/certificate contract are `OPERATOR_VERIFIED`.
- Android RevenueCat SDK configuration and `premium` entitlement are `OPERATOR_VERIFIED`.
- Android AdMob configuration, enablement, and cadence 3 are `OPERATOR_VERIFIED`.
- Shared privacy and terms URL variables are configured in Codemagic.
- After the iOS readiness changes, the current local working tree passed `flutter analyze --fatal-infos` with no issues in 112.0 seconds and passed the shared Android/iOS Release-equivalent non-visual suite with coverage: 74 files selected, 24 visual files excluded, **584 passed / 0 failed / 0 skipped** in 306.3 seconds. Visual/Golden tests were not run or regenerated in this gate.
- The earlier **661 passed / 0 failed** result is historical and superseded for Release Candidate decisions by this new green result.

### Remaining blockers

1. A new Codemagic Android release run and signed artifact are required for the current tree; the earlier operator-verified AAB/APK cover only their earlier known commit.
2. Physical-device Production E2E remains pending for authentication, Google sign-in, deep links, tournaments/teams/ranking, account deletion, weak networks, FCM delivery, Analytics, Crashlytics, ads, and Premium.
3. Google Play developer identity/address verification is unresolved.
4. Play Console app/listing, metadata, Data Safety, content rating, internal/release track, monthly/annual products, official Play URL, and store review remain `STORE_VERIFICATION_PENDING`.
5. RevenueCat purchase, restore, cancellation, expiry, offering, and webhook behavior are not validated against the Play sandbox.
6. AdMob consent, live fill, cadence, frequency, dismissal/failure, and SSV are not physically validated.
7. Final legal content and media-rights approval remain `LEGAL_APPROVAL_PENDING`.

### Decision

Android release infrastructure and the earlier signed artifacts remain proven for their known commit. The current local tree has a green analysis/non-visual gate, but its Codemagic artifact is pending and its device, provider-runtime, Play, purchase, legal, and final review gates remain. Android therefore remains **PARTIALLY READY** and the current tree must not be treated as a Production Play artifact.

## iOS — PARTIALLY READY

### Repository readiness

- Bundle ID is `com.ahdash.eleven`.
- Runner Debug/Profile/Release use the same Bundle ID and reference `Runner/Runner.entitlements`.
- Runner retains profile-driven push entitlement and now includes the standard Sign in with Apple entitlement.
- The minimum iOS deployment target is 15.0, matching the active Firebase plugin floor.
- Email and anonymous guest auth remain intact. Native Google token exchange is ready, and Apple uses the existing Supabase PKCE redirect flow; the auth controller now observes the returned external session.
- The callback remains `com.ahdash.eleven://login-callback`; Google client/scheme metadata is synchronized from the injected existing Firebase plist during CI.
- Codemagic passes both `GOOGLE_AUTH_ENABLED=true` and `APPLE_AUTH_ENABLED=true` to `flutter build ipa`.
- Codemagic injects Firebase and iOS AdMob configuration, validates required public Production inputs, applies App Store signing, builds an IPA, and targets internal TestFlight testers.
- iOS Release excludes `test/visual/**` while retaining every non-visual test. The current local equivalent passed 584/584 with coverage.
- Crashlytics includes a Release/Profile dSYM upload phase. RevenueCat iOS public key/`premium` entitlement and AdMob iOS app/unit paths reach the build and validator.
- App Store Production submission remains intentionally disabled.
- No mobile UI, visual source, brand asset, or Golden baseline was changed.

### External proof still required

1. Confirm the existing Firebase iOS app/protected plist, existing Supabase Google/Apple providers, and Apple identifiers/capabilities without creating replacement projects.
2. Confirm Apple App ID, Sign in with Apple and Push capabilities, APNs linkage, distribution certificate/profile, and the current App Store Connect integration.
3. Confirm iOS RevenueCat public key, monthly/annual App Store products/current offering/`premium` entitlement, and iOS AdMob Production app/unit values.
4. Run the existing iOS Release workflow on macOS/Codemagic and retain green validator/build logs, a signed IPA, dSYMs, and successful internal TestFlight delivery.
5. Complete the 25-step physical-iPhone matrix in [IOS_EXTERNAL_LINKING_CHECKLIST.md](./IOS_EXTERNAL_LINKING_CHECKLIST.md), including Email/guest/Google/Apple sessions, callbacks, push lifecycle, Party/Solo, purchases/restore, ads/Premium bypass, and deletion.
6. Complete App Store listing, App Privacy disclosures, age rating, screenshots, review information, subscription review data, final legal approval, and the separately authorized release decision.

### Decision

The repository is `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION`, but iOS is not release-ready and remains **PARTIALLY READY** until the independent provider, signing, IPA/TestFlight, physical-device, privacy, subscription, and store evidence exists. Android evidence is not used as iOS runtime proof. Windows validation cannot be labeled an IPA build; `IOS_BUILD_REQUIRES_MACOS_CI`.

## Desktop Web — PARTIALLY READY

### Proven

- Typecheck, lint, **16 test files / 81 tests**, and the Production build passed after Website Rebuild Phase 2. Phase 2 adds 18 focused gameplay/access tests across Party, Solo, and website-boundary suites; the Phase 1 foundation suite remains green.
- The public player website now uses the approved AHDASH identity and accurately presents Local Party without claiming browser parity.
- Supabase Email sign-in/registration/recovery/reset remain implemented. Google and Apple web OAuth code paths now use the shared PKCE callback and allow-listed internal return paths.
- Public desktop routes, guarded player routes, profile name/username update, problem reporting, and knockout-only tournament create/join paths exist.
- Fixture championship discovery, unsupported league/group choices, Friends/Store exposure, inactive account placeholders, and unsupported Premium benefits were removed from active website surfaces.
- Phone browsers receive the app-download experience.
- The four-hard-coded-question Production path is gone. Local Party now covers exact six-category selection, two teams, optional player distribution, helpers, ready summary, validated 36-question pack, board, question/timer/steal/reveal/scoring, undo, versioned local resume, result, and replay.
- Solo/Classic now loads the existing Solo RPC and implements category/difficulty/count setup, timer, scoring, answer/reveal, result, replay, best-effort answer history, and browser-local personal best.
- Local gameplay is guest-capable through a real Supabase anonymous identity. Anonymous identities are explicitly rejected by private player/tournament guards.

### Blockers

- The locally connected environment returned no displayable published category rows during Phase 2 visual QA; a deployed real-catalog start-to-result E2E remains unproven.
- Championship discovery is not implemented; the former fixture cards and inert filters are gone.
- Full organizer/bracket/match/result/champion Desktop flows are absent.
- Google and Apple require Supabase/provider-console configuration plus real deployed-domain callback/session/logout E2E.
- Remaining visible account areas include partial browser-local or limited workflows and must not be called mobile parity.
- Premium is informational only; no real website checkout or entitlement enforcement exists.
- Official store URLs are absent from the download experience.
- Deployed-domain, cross-browser/accessibility, interruption/resume, security, and real user E2E remain incomplete.
- Legal documents need final review.

### Decision

Phase 2 provides a real local gameplay implementation on top of the Phase 1 identity/auth foundation and is suitable for controlled internal desktop validation. It is not full mobile parity or a public-product launch; real catalog/deployed E2E, provider validation, accessibility/security QA, and later cloud-feature phases remain. Desktop Web stays **PARTIALLY READY**.

## Admin — PARTIALLY READY

### Proven

- Server-side page protection and independent API role guards exist.
- Broad data-backed tools cover content, questions, imports, media, tournaments, moderation, notifications, Party configuration, errors, reports, audit, health, and settings.
- Typecheck, lint, unit tests, and Production build passed in the approved source audit.

### Blockers

- Real moderator/admin role boundaries, RLS, audit, destructive actions, and failure recovery need Production validation.
- Users, Matches, Store, and Question Reports are read-only; role/status management and general Premium management are absent.
- Tournament operations are limited; notification/provider/media/import workflows need operational E2E.
- Vouchers remain gated OFF and `DEFERRED`.

### Decision

Suitable for controlled internal validation, not yet approved as an unrestricted Production operations console.

## Backend — PARTIALLY READY

### Operator-verified

- Linked Production history matches local history 27/27.
- Latest migration is `20260908000100_fix_review_tournament_registration_enum.sql`.
- The four newest migrations are deployed; no migration repair was used.
- The explicit enum-cast migration fixed the historical tournament registration issue.
- `db lint --linked` returned 0 errors and 16 warnings.

### Remaining validation

- Client E2E against the deployed schema.
- Selected JWT/RLS/direct-DML/catalog/ACL/rate-limit and real concurrency checks.
- Review of the 16 linked-lint warnings.
- Edge Function deployed versions, secrets, schedules, provider behavior, and monitoring.
- Voucher gates remain OFF; Online is removed from the active mobile product, while its backend infrastructure is retained. Store/economy remains deferred.

### Decision

Do not reapply the four newest migrations and do not use migration repair. Validate the already-deployed schema and active runtime paths. Backend is partially ready, not blocked by migration deployment.
