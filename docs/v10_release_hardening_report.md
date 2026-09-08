# AHDASH | 11 — V10 Release Hardening Report

Date: 2026-09-06 (Asia/Riyadh)  
Scope: source/static/automated hardening only; physical QA remains owned by the product owner.  
Result: **PASS — AUTOMATED HARDENING GATE**, with the external and backend blockers below. No production deployment or release build was performed.

## Executive result

- The known legal-link P2 is now truthful and fail-safe. Because no production Terms or Privacy URLs exist in repository/runtime configuration, its final status is **BLOCKED — LEGAL URL CONFIGURATION REQUIRED** rather than a fabricated PASS.
- Invalid/partial Supabase configuration no longer reaches SDK startup; Google and Apple buttons cannot appear without a valid backend configuration.
- All auth actions now share one duplicate-submission gate. This covers email, guest, Google, and Apple races.
- A RevenueCat SDK initialization failure now falls back to the disabled purchase service, so purchase actions are not exposed behind an uninitialized SDK.
- FCM token-refresh persistence failures are contained rather than becoming unhandled asynchronous errors.
- Maintained automated suite: **379/379 PASS** (previous baseline 370; nine focused tests added).
- `flutter analyze`: **No issues found**.
- Android Debug APK: **PASS**, 258,677,084 bytes, SHA-256 `2CF7672D9FE40DBA889528AECE4D5694753DFFA9860F3AA1D5D0AF9AE491CB7A`.

## A–C. Known P2 and legal URLs

**A. Phase F P2:** converted safely into an explicit external configuration blocker. The settings sheet no longer presents missing/invalid legal links as working actions.

**B. Terms URL:** `TERMS_URL` is absent from `mobile/.env`. Status: **BLOCKED — LEGAL URL CONFIGURATION REQUIRED**.

**C. Privacy URL:** `PRIVACY_POLICY_URL` is absent from `mobile/.env`. Status: **BLOCKED — LEGAL URL CONFIGURATION REQUIRED**.

The new centralized legal-link service trims and parses the value, accepts only a complete HTTPS URI with a host, opens it in the external browser, contains platform exceptions, and returns safe Arabic feedback for missing, invalid, or failed launches. No URL was invented.

## D. Configuration audit

| Area | Sanitized finding | Runtime behavior |
|---|---|---|
| Supabase | URL/key are set; values not printed | complete HTTPS URL plus non-placeholder key required |
| Google | enabled flag set; Android/iOS client configuration present | shown only on native mobile with valid Supabase config |
| Apple | enable flag absent; iOS Sign in with Apple entitlement absent | hidden/fail-safe; external setup blocked |
| Firebase/FCM | enabled flag and platform integration present | optional initialization is contained; delivery unverified |
| RevenueCat | Android/iOS keys empty | Noop service; no fabricated plans/prices/actions |
| Legal | Terms/Privacy runtime values absent | disabled links with truthful explanatory subtitle |
| Deep links | native scheme is `com.ahdash.eleven`; sample env keys are not consumed | strict allow-list resolver; malformed/Online links cannot activate Online |
| Package identity | Android `com.ahdash.eleven`; iOS bundle setting uses project identifier | consistent with callback scheme in source |
| Environment | `APP_ENV` set; compile-time `--dart-define-from-file` contract | placeholders/partial Supabase values rejected |

P3 configuration debt: deep-link scheme/host remain duplicated between native manifests and Dart OAuth code instead of being generated from the sample environment contract. They are currently consistent; changing platform identifiers during hardening was intentionally avoided.

## E–J. Authentication and RevenueCat

**E. Google code hardening:** native flow has bounded initialization/auth/authorization, typed cancellation/network/timeout/config errors, token presence checks, Supabase exchange validation, safe local sign-out, session restore, and the unified duplicate-action gate. Static/code status: **IMPLEMENTED IN CODE**. Physical-device PASS is not claimed.

**F. Apple code hardening:** Supabase OAuth redirect uses the SDK-managed OAuth state/callback flow; redirect startup resets UI loading, duplicate taps are blocked, restored sessions are identified, and provider/sign-out failures do not trap the application session. A native ID-token flow is not used, so a client-side raw nonce is not applicable to the current redirect architecture. Code status: **IMPLEMENTED IN CODE**.

**G. Apple external blocker:** `APPLE_AUTH_ENABLED` is absent, Supabase reports the provider disabled, and `Runner.entitlements` lacks the Apple sign-in capability. Status: **BLOCKED — EXTERNAL CONFIG**.

**H. Email Auth:** sign-in/sign-up validation, loading/error rendering, safe raw-error suppression, session restore, sign-out, and duplicate-submit protection are covered. Network/provider failures resolve to safe Arabic UI. The current product contract has no forgot-password method/surface; adding a new recovery flow was outside this no-new-scope phase and remains a product/back-end decision.

**I. RevenueCat code hardening:** missing keys select `NoopPurchaseService`; SDK initialization failure now also disables the service. Empty offering/packages produce no fabricated plan; prices come only from the store; cancellation, purchase failure, restore, entitlement confirmation, account identity, sign-out, stale-account epoch checks, and repeated actions are handled.

**J. RevenueCat external blocker:** both QA keys are empty. Status: **BLOCKED — EXTERNAL CONFIG**. No real-money transaction was attempted.

## K–P. FCM, links, async, duplicate actions, and network states

**K. FCM code hardening:** permission states, token retrieval/refresh, user association, sign-out deactivation, foreground/background/terminated event mapping, subscription disposal, and strict payload routing are present. Token-refresh write errors are now contained. Full tokens are not printed.

**L. FCM physical blocker:** no physical device/test-push source was available. Status: **REQUIRES MANUAL QA**.

**M. Deep-link audit:** only exact safe routes, UUID team/challenge routes, and sanitized join codes are accepted. Schemes, authorities, fragments, backslashes, invalid UUIDs/codes, sensitive query parameters, and unsupported routes fall back to Notifications. `/online`, `/online/match/*`, and `/room/*` remain tombstones redirecting to Home.

**N. Async/race fixes:** auth now uses one controller-level in-flight gate across all login methods; mounted/context guards already protect post-await navigation; RevenueCat uses account/epoch validation; tournament mutations preserve pending/idempotent state; FCM refresh errors are contained.

**O. Duplicate-action fixes:** email, guest, Google, Apple, legal-link launch, settings actions, purchase/restore, reports, team/social mutations, Party state transitions, and Tournament state-changing actions either disable while busy or reject re-entry. A new direct controller test proves duplicate email submission produces one repository call.

**P. Network/error-state review:** Categories, Saved Party, Tournament, Friends, Blocked Players, Team Detail, Notifications, Football Preferences, Premium, and Report retain truthful loading/empty/error behavior and retry only where meaningful. State-changing operations are not automatically replayed; Tournament explicitly preserves uncertain pending state and asks for same-value retry. Raw Supabase/Postgres/RevenueCat errors are not rendered to users.

## Q–X. Product-domain hardening findings

**Q. Party:** domain/controller guards cover invalid drafts, missing catalog/question/media, repeated Board/Reveal/score actions, timer pause/resume, unavailable helpers, bench/pass/risk constraints, session restoration, and Play Again reset. Rules and host authority were unchanged.

**R. Answer leak:** pre-reveal widget tests assert that the active answer is absent from both visible text and semantics. Answer content is mounted only on the Reveal surface. No production logging/analytics includes the answer.

**S. Tournament:** deterministic engine/flow tests cover invalid bracket/team/match states, stale deep links, restore, return from Party, draw stability, duplicate results, authority, and fail-closed error handling. No rules changed.

**T. Backend gate:** remote bracket/result writes still depend exclusively on `save_tournament_bracket_v2` and `confirm_tournament_match_result_v2`; no unsafe legacy RPC fallback exists. Migrations were not run or edited. Hashes remain:

- `20260902000100_gameplay_depth_v1.sql`: `C4968EA1824A3D9BBE942BABD3DE27F0F3267AF88DD834A4458861424267CCD1`
- `20260905000100_tournament_bracket_safety_v2.sql`: `E4422D46197D187B50F544A2828667B3492F96F3C55BE7786420CCB122559E14`

**U. Solo:** remains **LIMITED** and does not claim unavailable online/backend depth.

**V. Team Challenge:** remains implemented with real repository state, guarded actions, safe failure recovery, and no fabricated challenge success.

**W. Friends/Blocked/Team Detail:** missing-user/null handling, account-backed repositories, busy guards, and truthful errors remain. No fake presence, level, or team statistics are introduced.

**X. Football/media:** leagues/clubs are repository-driven with loading/search/empty/error/save states. Shared/cached image widgets retain null, invalid URL, loading, and decode fallbacks without adding unlicensed assets or hardcoded counts.

## Y–AH. Isolation, lifecycle, UI, privacy, and cleanup

**Y. Account isolation:** auth identity is propagated separately to notifications, purchases, and crash reporting. Premium rejects stale account completions by account ID/epoch; Tournament pending create verifies organizer identity; user-backed repositories remain scoped to the authenticated client.

**Z. Sign-out:** FCM association is deactivated, RevenueCat identity is logged out when enabled, crash identity is cleared, Supabase/local provider session is cleared, and failures in optional integrations cannot prevent sign-out.

**AA. Startup/lifecycle:** Firebase, Ads, notification initialization, and RevenueCat are optional and contained; failed RevenueCat initialization now disables purchasing. Party timers/session and Tournament state have explicit restore/background-safe contracts. Device cold-start/resume remains manual QA.

**AB. Routing:** route catalog has no duplicate paths. Online compatibility paths redirect to Home; Wallet redirects to Premium/Store. Party and Tournament routes validate/restored state before entry. Notification links use a separate allow list. Legacy Online implementation files remain compiled but unreachable from production routes.

**AC. Portrait/legacy landscape:** Android and iOS advertise portrait-only orientation. V10 portrait scaffolds remain unchanged. Legacy landscape helpers are still referenced by compiled compatibility/legacy surfaces, so they were not deleted without a dedicated removal migration.

**AD. Accessibility/RTL:** maintained tests cover Arabic RTL, mixed names/prices, 360–430 px portrait widths, text scales through 1.3, keyboard insets, semantic live regions, disabled/busy actions, and answer secrecy. Provider logos are not mirrored. Physical TalkBack/VoiceOver remains manual QA.

**AE. Logging/privacy:** no password, authorization code, identity/access/refresh token, FCM token, answer, or full report body is intentionally logged. `AppErrorSanitizer` tests cover credentials, bearer tokens, JWT-like values, and emails; user-visible errors remain sanitized.

**AF. TODO/FIXME:** production Dart contains no active TODO/FIXME markers. Matches for “placeholder” are image-loading UI or configuration validation, not fabricated production data.

**AG. Dead/legacy code:** no risky broad deletion was performed. Unreachable Online screens and some landscape utilities are known legacy candidates but remain because they compile against compatibility/domain code and need a dedicated removal proof.

**AH. Dependencies:** reviewed without major upgrades. No package upgrade was performed. Flutter reports 43 newer incompatible versions; Gradle 8.14.0, AGP 8.11.1, and Kotlin 2.2.20 produce future-support warnings only. This is P3 maintenance debt, not a current build failure.

## AI–AM. Verification and changed files

**AI. New tests:** nine focused test cases:

- five legal-link cases: valid Terms, valid Privacy, missing config, invalid URI, launcher rejection/exception;
- three configuration cases: complete HTTPS Supabase, provider/backend coupling, legal HTTPS parsing;
- one duplicate email submission race test.

Existing answer-leak, route safety, malformed data, error recovery, account switch, purchase race, Tournament fail-closed, media, and responsive tests were retained. No Goldens were regenerated because no locked visual composition changed.

**AJ. Final maintained automated count:** **379/379 PASS**, exit 0, command covering `test/contracts`, `test/core`, `test/features`, `test/shared`, and `test/v10_phase_a..e`.

**AK. Analyze:** **No issues found**, exit 0.

**AL. Android Debug:** `flutter build apk --debug --dart-define-from-file=.env` succeeded. Artifact: `mobile/build/app/outputs/flutter-apk/app-debug.apk`. No release APK/AAB was built.

**AM. Files changed in this phase:**

- `mobile/lib/core/config/app_config.dart`
- `mobile/lib/core/services/legal_link_service.dart`
- `mobile/lib/core/bootstrap/app_bootstrap.dart`
- `mobile/lib/core/services/notification_service.dart`
- `mobile/lib/features/auth/presentation/auth_controller.dart`
- `mobile/lib/features/auth/presentation/auth_screen.dart`
- `mobile/lib/features/settings/presentation/settings_screen.dart`
- `mobile/test/core/legal_link_service_test.dart`
- `mobile/test/core/app_config_hardening_test.dart`
- `mobile/test/features/auth/social_auth_test.dart`
- `docs/v10_release_hardening_report.md`

## AN–AT. Remaining items and stop gate

**AN. P0 remaining:** none found in code/static/automated scope.

**AO. P1 remaining:** none knowingly unresolved in code/static/automated scope.

**AP. P2 remaining:** production Terms and Privacy URLs are absent (external legal blocker). Password recovery is absent from the current Auth repository/UI contract and requires an explicit product/backend decision rather than being invented in hardening.

**AQ. P3 remaining:** future Flutter toolchain compatibility warnings; duplicated native/Dart deep-link constants; dedicated proof before legacy Online/landscape source deletion.

**AR. Product-owner manual QA:** install/cold start; Google and Email end-to-end; Apple after configuration; FCM permission/token/foreground/background/terminated delivery; RevenueCat offering/purchase/cancel/restore/account switch after QA keys; browser launch after real legal URLs; lifecycle/timer/background; TalkBack/VoiceOver; keyboard/large text; poor/offline network; visual/RTL checks on target devices.

**AS. External configuration blockers:** real Terms URL, real Privacy URL, Apple provider/capability/credentials, RevenueCat QA keys/offerings, and a physical FCM test environment. Google/Email are configured but still require physical verification.

**AT. Backend blockers:** gameplay/tournament migrations and their security tests remain pending the separately authorized Supabase security/release gate. No `db push`, migration apply, remote SQL/RPC replacement, or RLS deployment occurred.

## Acceptance gate

- Legal P2: **PASS AS EXPLICIT EXTERNAL BLOCKER**.
- No known code P0/P1: **PASS**.
- Missing optional configuration fails safely: **PASS**.
- No fake success/package/legal state introduced: **PASS**.
- No token/secret leakage found in audited production logging: **PASS**.
- Online inactive and Tournament fail-closed: **PASS**.
- No XP/Coins/Wallet/Dark Mode/new product scope introduced: **PASS**.
- V10 Portrait intact; maintained suite/analyze/Debug build pass: **PASS**.

**STOP:** hardening is complete within the authorized automated scope. Physical/manual verification, legal/provider configuration, Supabase migration deployment, and final publishing were not performed.
