# AHDASH | 11 — Integrations

**Scope:** external-service contracts and validation state  
**Last verified:** 12 September 2026  
**Backend truth:** [05_BACKEND_SUPABASE.md](./05_BACKEND_SUPABASE.md)  
**Release verdict:** [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md)

## Evidence and secret policy

This document records variable names only. It must never contain API keys, private keys, service-account contents, webhook secrets, keystore passwords, or provider tokens.

`OPERATOR_VERIFIED` facts come from the verified 12 September 2026 release/provider session; repository-only inspection cannot independently reconstruct provider-console state. A configured value is not proof of live device, provider, or store behavior.

## Integration matrix

| Integration | Platforms | Code state | Required variable/config names only | Repository evidence | Operator-verified evidence | External/device/store work | Status |
|---|---|---|---|---|---|---|---|
| Supabase | Mobile, Desktop Web, Admin, backend | Auth clients, RLS/RPC schema, migrations, Edge Functions | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`; service-role credential only in authorized server runtime | Clients, 27 migrations, tests, and functions exist | Linked Production history matches 27/27 through `20260908000100`; linked lint 0 errors/16 warnings; no repair | Client/role E2E, selected security/concurrency, function versions/secrets/schedules | `IMPLEMENTED_NOT_RELEASE_READY` |
| Firebase Core | Android, iOS | Bootstrap-gated Firebase integration | `FIREBASE_ENABLED`, `FIREBASE_ANDROID_CONFIG`, `FIREBASE_IOS_CONFIG` | iOS CI decodes the protected plist to `Runner`, validates its metadata/Bundle ID, synchronizes Google callback metadata, and Xcode bundles it | Android Release injection passed; package and Release fingerprint contract verified; ignored local iOS metadata matches the existing project relationship | Verify the protected iOS value in CI, then runtime on TestFlight/device | `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION` |
| Google Sign-In | Mobile, Desktop Web | Native mobile token exchange plus Supabase web OAuth PKCE through `/auth/callback` | `GOOGLE_AUTH_ENABLED` for mobile; web OAuth credentials remain provider-side and must never be browser variables | iOS Release passes the existing flag; CI derives `GIDClientID` and the reversed URL scheme from the injected existing Firebase plist; cancellation/error/session tests pass | Android Firebase Release configuration and matching Release certificate are verified; iOS provider state is not console-verified | Existing Firebase/Google/Supabase provider confirmation and TestFlight device E2E | `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION` |
| Apple Sign-In | iOS mobile, Desktop Web | iOS Supabase PKCE redirect flow exists and auth-state callbacks now establish the app session | `APPLE_AUTH_ENABLED` for mobile; Apple Services ID/private key/client secret remain provider-side | Runner carries the standard Sign in with Apple entitlement, Release references it, CI passes the flag, and callback-session behavior is tested | Apple/Supabase provider state is not console-verified | Confirm Apple capability/profile and existing Supabase provider, then TestFlight device E2E | `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION` |
| FCM | Android, iOS, Admin dispatch | Token lifecycle, permission, inbox/deep link, foreground/background/terminated architecture, campaigns, delivery records, dispatch function | `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, `FCM_PRIVATE_KEY`, `NOTIFICATION_DISPATCH_SECRET`, plus platform Firebase config | iOS Runner retains profile-driven `aps-environment`; Firebase plist path and messaging bootstrap are wired | Android Firebase config injection is verified; delivery is not | Apple Push capability/profile, APNs key in existing Firebase project, and device lifecycle delivery | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` |
| Analytics | Android, iOS | Firebase wrapper and event calls, bootstrap-gated | `FIREBASE_ENABLED` and platform Firebase config | iOS config injection and Production enablement path are validated | Android Firebase configuration is verified | Consent/policy plus real Production event verification on TestFlight/device | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` |
| Crashlytics | Android, iOS | Firebase crash wrapper, bootstrap-gated | `FIREBASE_ENABLED` and platform Firebase config | iOS Release/Profile includes the Firebase Crashlytics dSYM upload build phase | Android Firebase configuration is verified | Confirm macOS archive symbols and real nonfatal/fatal symbolication; retain the separate sanitization review | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` |
| RevenueCat | Android, iOS, webhook | Monthly/annual package loading, `premium` entitlement, purchase/restore/status/management, webhook source | `REVENUECAT_ANDROID_API_KEY`, `REVENUECAT_IOS_API_KEY`, `REVENUECAT_ENTITLEMENT_ID`, `REVENUECAT_WEBHOOK_AUTH` | iOS public SDK key and entitlement paths reach the IPA command and validator; entitlement must be `premium` | Android public SDK key and entitlement `premium` configured for the Play app | Verify iOS public value, App Store products/offering, Sandbox purchase/restore/cancel/expiry | `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION` |
| AdMob | Android, iOS, SSV | Consent, interstitial, rewarded service, Premium bypass, SSV function | `ADMOB_ENABLED`, `ADMOB_ANDROID_APP_ID`, `ADMOB_INTERSTITIAL_ANDROID_ID`, `ADMOB_REWARDED_ANDROID_ID`, `ADMOB_INTERSTITIAL_EVERY_MATCHES`, `ADMOB_IOS_APP_ID`, `ADMOB_INTERSTITIAL_IOS_ID`, `ADMOB_REWARDED_IOS_ID` | iOS CI injects the app ID, passes both unit IDs/cadence, and validates Production values before signing/build | Android app/interstitial/rewarded IDs configured, ads enabled, cadence 3, Production validator passed | Verify iOS protected values, consent, live fill, cadence, dismissal/failure, Premium bypass, and SSV on device | `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION` |
| Google Play | Android | Signed build automation exists; publishing is not configured | `NEXT_PUBLIC_GOOGLE_PLAY_URL`; Play Console and Codemagic publishing integration are external | AAB/APK build paths and website link gate exist | Signed AAB and APK are proven; Release certificate verified | Developer identity/address verification, app/listing, metadata, Data Safety, rating, track, monthly/annual products, official URL, review | `CONFIGURED_EXTERNAL_SETUP_REQUIRED`; `STORE_VERIFICATION_PENDING` |
| App Store / TestFlight | iOS | IPA/Internal TestFlight workflow source exists; App Store Production submit remains off | `FIREBASE_IOS_CONFIG`, `REVENUECAT_IOS_API_KEY`, iOS AdMob variables, legal URLs; App Store Connect integration is external | Bundle/signing references, non-visual tests, Firebase/Google sync, Production validator, IPA flags, artifacts, and Internal Testers submission are configured | Shared legal URL variables are configured; no current-tree IPA/TestFlight proof exists | Provider/signing confirmation, green macOS CI/IPA, TestFlight/device matrix, listing/privacy/rating/screenshots/products/review | `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION`; store `BLOCKED` |
| Codemagic | Android, iOS, PR checks | Release and check workflows exist | `APP_ENV`, Supabase/Firebase/Google/Apple/RevenueCat/AdMob/legal variables; signing/provider integrations | iOS Release now aligns with the 74-file non-visual policy, fails closed on required public config, enables Google/Apple, and keeps Production App Store submission disabled | Earlier Android release run on `main` passed and produced verified signed artifacts | New green runs/artifacts for the current tree; iOS signing/provider/TestFlight proof; store review | Android infrastructure `OPERATOR_VERIFIED`; iOS source `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION` |

## Android operator-verified facts

- Application/package ID: `com.ahdash.eleven`.
- Firebase Android Release configuration injection passed in Codemagic.
- Android RevenueCat public SDK key is configured; entitlement is `premium`.
- Android AdMob application/interstitial/rewarded configuration is present, enabled, with initial cadence 3.
- Android signing, Production configuration validation, signed AAB, and signed APK generation are proven.
- Shared `PRIVACY_POLICY_URL` and `TERMS_URL` are configured in Codemagic.

Exact artifact and certificate evidence is owned by [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md).

## Current external boundaries

- Google Play publication is **not complete**. Proven artifacts do not equal a store release.
- RevenueCat configuration does not prove Play products or real purchase/restore behavior.
- AdMob configuration does not prove consent, live fill, frequency, dismissal, or SSV.
- Firebase configuration does not prove device sign-in, push, Analytics, or Crashlytics delivery.
- iOS repository integration/auth configuration is ready for external validation, but Apple/Firebase/Supabase/provider values, signing, IPA/TestFlight, and physical-device behavior remain independently unverified and must not inherit Android readiness.
- Desktop Google and Apple OAuth code paths are implemented, but provider-console enablement, allowed Production redirect URLs, and real deployed-domain sign-in/logout/session E2E are still required.
- Legal URL configuration does not replace final legal approval.
