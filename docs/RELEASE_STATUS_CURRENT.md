# AHDASH | 11 — Current Release Status

**Verified:** 12 September 2026  
**Rule:** `READY` means repository, configuration evidence, automated gates, external dependencies, and required Production/device validation are all sufficient for release. A successful build alone is not `READY`.

**Evidence rule:** repository/current-tree checks are `REPO_VERIFIED`; facts from the actual Codemagic, provider, signing, and linked-Supabase session are `OPERATOR_VERIFIED`. Device, store, legal, and current-tree gates are tracked separately as `DEVICE_VERIFICATION_PENDING`, `STORE_VERIFICATION_PENDING`, `LEGAL_APPROVAL_PENDING`, and `CURRENT_TREE_TEST_GATE_FAILING`. Operator-verified facts below were verified on 12 September 2026; the repository alone cannot independently reconstruct provider-console state.

## ANDROID — PARTIALLY READY

### Ready in source

- Package/application ID is `com.ahdash.eleven`.
- `codemagic.yaml` has an `android-release` workflow.
- Codemagic signing reference is `ahdash11_keystore`.
- CI creates `mobile/android/key.properties` from Codemagic signing variables.
- Release Gradle configuration fails closed when signing is absent and forbids a test/missing AdMob app ID.
- CI injects `mobile/android/app/google-services.json` from `FIREBASE_ANDROID_CONFIG`.
- CI runs `flutter analyze --fatal-infos` and the non-visual test selection, then builds signed AAB and APK artifacts.
- `scripts/check-release-integrations.mjs` validates Production Supabase, Firebase, Google auth, RevenueCat, AdMob, legal URLs, signing, Firebase metadata, OAuth SHA, and voucher-off gates.
- Local validator confirms the Firebase Android package/project/sender/OAuth data and signing certificate/SHA configuration are internally consistent.
- Historical local evidence reports a signed Release APK with APK Signature Scheme v2.

### Operator-verified release evidence

- A successful Codemagic Android release workflow ran on branch `main` from an earlier known commit. Static analysis, selected non-visual tests, Firebase Android configuration injection, Android signing configuration, the Production Android validator, and the signed AAB build passed.
- A later workflow revision also added and proved signed APK generation. Verified outputs include `app-release.aab` and `app-release.apk`.
- Downloaded AAB SHA-256: `4456CEBEA870B826D79B670267C3D587E42BA80A39D43FD4C59E089D5EC2D4E4`.
- The AAB certificate matches the intended Release certificate:
  - SHA-1: `1E:25:C3:09:0A:F3:1E:20:54:46:C5:5D:6B:B2:7D:45:17:77:B8:C7`
  - SHA-256: `43:47:5F:35:4B:73:F4:D2:C9:AD:45:66:3A:BF:D6:DF:FA:86:25:93:03:F9:1D:1B:2E:D6:A4:93:83:C1:86:47`
- Firebase Android configuration for package `com.ahdash.eleven` is injected through `FIREBASE_ANDROID_CONFIG`; that step passed, and the Release fingerprints above are verified.
- Codemagic has the Android RevenueCat public SDK key and `REVENUECAT_ENTITLEMENT_ID=premium` for the `AHDASH | 11` Play app.
- Codemagic's `admob` group has the Android app/interstitial/rewarded IDs, `ADMOB_ENABLED=true`, and initial interstitial cadence 3; the Production validator passed.
- The shared Production environment has `PRIVACY_POLICY_URL` and `TERMS_URL`; the verified privacy URL is `https://ahdash11.shaghafjob.com/privacy-policy`.

### Exact blockers

1. The current Android-CI-equivalent Flutter non-visual suite fails three tests: guest settings routing, Team Detail source contract, and Profile source contract. Result: 580 passed, 3 failed.
2. The successful operator-verified Codemagic run predates later UI/product changes. No new artifact should be accepted from the current dirty tree until the three tests are fixed and the exact release selection is green again.
3. The local workstation validator lacks several values that are present in Codemagic. That local result is not evidence that the Codemagic RevenueCat, AdMob, Firebase, or legal URL variables are missing.
4. Google Play publishing is not configured in `codemagic.yaml`; proven AAB/APK artifacts do not constitute a Play release.
5. Google Play developer identity/address verification is unresolved. The Play Console app/listing, store metadata, Data Safety, content rating, internal/release track, monthly/annual products, release notes, official Play URL, and final review remain `STORE_VERIFICATION_PENDING`.
6. RevenueCat configuration is present, but Google Play developer/product completion and real purchase, cancellation, expiry, restore, offering, and webhook behavior are not verified against the store sandbox.
7. AdMob configuration is present, but consent, live serving/fill, configured cadence, frequency, dismissal/failure paths, and SSV are not verified on a physical device.
8. Firebase Auth/Google Sign-In, FCM foreground/background/terminated delivery, Analytics, Crashlytics, deep links, account deletion, weak-network behavior, and all Supabase-backed features need physical-device/Production validation.
9. The Production schema is deployed at 27/27, but authenticated clients still need E2E validation against it; relevant Edge Function versions/secrets/schedules must be validated separately.
10. Legal URLs are configured in Codemagic, but policy content, ownership/contact/effective dates, and final legal/media-rights approval remain `LEGAL_APPROVAL_PENDING`.

### Release decision

Android release infrastructure and signed artifacts are proven. Do not treat the current dirty tree as release-ready or upload a new artifact from it to a Production Play track. First restore a green Android test gate, validate clients and Edge Functions against the deployed backend, complete physical-device QA and Play account/listing/product setup, and run the explicit publishing/review process.

## IOS — BLOCKED

### Ready in source

- Bundle ID is `com.ahdash.eleven`.
- `codemagic.yaml` defines App Store distribution signing, Firebase injection, AdMob app ID injection, IPA build, and TestFlight submission to `Internal Testers`.
- `submit_to_app_store` is intentionally false.
- The app contains the login callback URL scheme and push entitlement placeholder.
- RevenueCat and Firebase/FCM client code support iOS variables.

### Exact blockers

1. `mobile/ios/Runner/Runner.entitlements` contains only `aps-environment`; it does not contain the Sign in with Apple entitlement.
2. The iOS workflow does not pass `APPLE_AUTH_ENABLED=true`; current release builds therefore do not expose Apple sign-in.
3. Apple Developer App ID capability, Supabase Apple provider, Services ID/redirects, certificate/profile, App Store Connect integration state, and TestFlight app state are external and unverified.
4. `FIREBASE_IOS_CONFIG`, `ADMOB_IOS_APP_ID`, rewarded/interstitial iOS IDs, and `REVENUECAT_IOS_API_KEY` are referenced but their usable values are not verified. Shared privacy/terms URL variables are operator-verified in Codemagic, but that does not prove iOS runtime/provider readiness or legal approval.
5. iOS CI runs unfiltered `flutter test --coverage`, unlike Android. It can include the visual suite; no current green iOS workflow proves the intended test policy.
6. No current signed IPA, TestFlight upload, review, or physical iPhone/iPad test result is available.
7. Purchase/restore/subscription management, push permissions/delivery, Google auth on iOS, Apple auth, deep links, ads/consent, account deletion, and Supabase flows require device tests.
8. App Store listing, privacy nutrition labels, age rating, screenshots, review information, final legal approval, and official App Store URL are not verified.
9. The Production schema is deployed, but iOS client E2E against it and relevant Edge Function/provider behavior remain unverified.

### Release decision

No iOS release or TestFlight readiness claim is supported today. Complete capabilities/provider configuration, align the CI test policy, validate against the deployed backend, produce a green signed/TestFlight run, and execute physical-device QA first.

## DESKTOP WEB — PARTIALLY READY

### Ready in source

- One Next.js 16 application contains public player routes, player authentication, desktop-only shell, phone download page, legal/support pages, and protected account/play/tournament routes.
- Phone user agents are rewritten to `/mobile-app`; narrow-screen CSS provides a fallback.
- Supabase email login, registration, recovery, reset, PKCE callback, session refresh, and server-side player guards are implemented.
- Profile name/username update and user problem report submission are real.
- Tournament create/join forms call real RPCs.
- `npm run typecheck`, `npm run lint`, `npm test` (55/55), and `npm run build` pass in this audit.

### Exact blockers

1. Desktop gameplay is an experimental four-question local prototype per type, not production content or authoritative gameplay.
2. Ordering, Club Guess, Eagle Eye, team challenge, local Party, and daily challenge do not implement their promised distinct mechanics.
3. Championship discovery uses four hard-coded cards; filters are inert.
4. League/groups are offered in tournament creation, but the backend engine is knockout-only.
5. Desktop tournament management ends after create/join; organizer registration review, draw, bracket, match, result, and champion flows are absent.
6. Ranking and notifications are fixtures; teams and blocked players are placeholders; settings are in-memory; Store and Premium checkout are nonfunctional; friends is send-only; football preferences use a hard-coded list/direct profile field.
7. Desktop Premium copy advertises unapproved benefits: broader stats, tournament options, and appearance. Approved truth is exclusive categories and ad-free only.
8. Website Home says “without download” and “supports mobile” although the full site is desktop-only and phones receive the download page.
9. Official App Store and Google Play URLs are missing, so phone download buttons are disabled.
10. Deployment host, Production Supabase session/email callback, rate limits/RLS, monitoring, cache/security headers, accessibility/browser matrix, and real user E2E are unverified.
11. Legal copy requires final owner/contact/effective-date and counsel review.

### Release decision

The website can build and can support an internal desktop preview. Do not market or launch it as full product parity until placeholders and unsupported claims are removed or implemented and Production E2E/security validation passes.

## ADMIN — PARTIALLY READY

### Ready in source

- Every dashboard route is protected server-side by `requireAdminPage`; APIs independently require moderator/admin roles.
- Dashboard, categories, questions/options, CSV/Excel import, media, content/branding, tournament monitoring, social moderation, notification campaigns, Party helpers, vouchers, errors, football data, user problem reports, audit, health, and settings have real data paths.
- Mutations reject cross-origin requests where implemented and use schema validation/RPCs or protected Supabase writes.
- Typecheck, lint, tests, and Production build pass in this audit.

### Exact blockers

1. Real moderator/admin/super-admin accounts and role boundaries have not been exercised against Production RLS.
2. Production migrations are operator-verified at 27/27 through `20260908000100`; Admin role/RLS/data workflows and relevant Edge Functions still require Production E2E validation.
3. Users are read-only; role/status management has no approved UI/API workflow.
4. Matches are read-only; tournament operations are limited to monitoring and cancel/reopen.
5. Admin Store is read-only even though copy says it manages items/prices/availability.
6. Question reports are read-only; user problem reports are the only complete review workflow.
7. There is no general Premium subscription/customer-support management surface.
8. Voucher actions are correctly disabled pending policy and database approval; they cannot be counted as live.
9. Notification campaigns require deployed dispatch function, FCM service account, secret/scheduler, delivery monitoring, and real send validation.
10. Media Storage buckets, rights workflow, import batches, audit capture, health probes, and failure recovery need Production validation.

### Release decision

Suitable for controlled internal/Production validation against the deployed schema. Not approved as a Production operations console until role/RLS, destructive actions, reporting, notifications, imports, media and audit behavior are tested with real staff accounts.

## BACKEND — PARTIALLY READY

### Ready in source

- 27 ordered SQL migrations; latest is `20260908000100_fix_review_tournament_registration_enum.sql`.
- Parser passes 27 migrations and 146 PL/pgSQL bodies, with two pre-existing catalog-less `_record` warnings.
- Schema covers content/media, profiles/auth support, matches/rooms, social, tournaments, notifications, subscription/economy, vouchers, monitoring, reports, audit and settings.
- Repository scan finds 76 RLS-enable statements and 126 policy declarations across migration history.
- Sensitive flows use protected RPCs, fixed search paths, explicit grants/revokes, rate limits, row locking, idempotency, and/or compare-and-set where relevant.
- 11 Edge Functions exist for rooms/matchmaking/answers, imports, notifications, RevenueCat, AdMob reward, wallet transactions, and deletion.
- Current static security checks pass 59/59; enum checks 9/9 and 8/8; embedded tournament checks 29/29; embedded voucher checks 11/11.
- Nine pgTAP SQL suites exist.
- Operator-verified on 12 September 2026: all 27 migrations are deployed to linked Production through `20260908000100`; local and remote migration history matched 27/27.
- The four newest migrations (`20260902000100`, `20260905000100`, `20260907000100`, `20260908000100`) are deployed. The explicit enum-cast migration fixed the historical tournament registration enum issue. No migration repair was used.
- `db lint --linked` completed with 0 errors and 16 warnings.

### Exact blockers

1. The repository-audit environment did not run the nine real pgTAP suites or fresh/upgrade database scenarios. Selected JWT/RLS/direct-DML/rate-limit and two-connection tournament/voucher checks remain pending as validation of the deployed schema, not as prerequisites to reapply it.
2. Real server-catalog ownership, function ACL, rate-limit timing, month/year/time behavior, and account-deletion preservation are not fully proven by the operator evidence supplied here.
3. Edge Function deployed versions, secrets, cron schedules, Storage buckets, and Auth providers require service-specific operational verification; migration history does not establish them.
4. The 16 linked-lint warnings require review even though linked lint had 0 errors.
5. Mobile, Desktop Web, and Admin authenticated flows need E2E validation against the deployed schema, including tournament registration/review/bracket/result behavior.
6. Voucher runtime and policy gates must remain OFF despite the schema being deployed.
7. Online room/matchmaking infrastructure exists but the product intentionally defers its client routes.

### Release decision

Do not reapply the four newest migrations and do not use migration repair; Production history already matches 27/27. Review the linked-lint warnings, run the still-required client/device and selected security/concurrency validations against authorized environments, and verify Edge Function/provider operations separately. The backend is partially ready rather than blocked by migration deployment.

## Cross-platform release order

1. Restore the Flutter non-visual test gate.
2. Validate the already-deployed Supabase schema through selected real security/concurrency checks; do not reapply or repair migrations.
3. Verify mobile, Desktop Web, Admin, and relevant Edge Functions against linked Production or an authorized equivalent environment.
4. Correct desktop/guide product claims and remove or clearly label placeholders.
5. Preserve the operator-verified Android provider and legal URL configuration; complete still-missing store products, iOS/provider setup, and final legal approval.
6. Run Android and iOS physical-device E2E, including auth, notifications, purchases, ads, offline, tournaments and social.
7. Preserve the verified earlier Android artifacts and obtain a new green Codemagic artifact for the later working tree.
8. Complete legal/media-rights and store-listing review.
9. Configure internal Play/TestFlight distribution and official website store URLs.
10. Approve Production release separately per platform.
