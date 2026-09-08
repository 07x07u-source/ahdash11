# Production Configuration Audit

## Existing architecture

- Flutter configuration is compile-time through `String.fromEnvironment`, `bool.fromEnvironment`, and `int.fromEnvironment` in `mobile/lib/core/config/app_config.dart`.
- The established local build input is an env file passed with `--dart-define-from-file`.
- Codemagic uses protected environment groups and explicit `--dart-define` arguments.
- There are no Android product flavors; `APP_ENV` selects development, staging, or production behavior.
- Bootstrap initializes Supabase, Firebase/Analytics/Crashlytics/FCM, AdMob, and RevenueCat only when their existing configuration permits it.
- The Android manifest receives `ADMOB_ANDROID_APP_ID` through Gradle process environment configuration.

## Current gate

| Check | Status |
| --- | --- |
| `APP_ENV` | INVALID — currently development |
| `SUPABASE_URL` | PRESENT — HTTPS Production project URL |
| `SUPABASE_ANON_KEY` | PRESENT — public/anon client key, not service role |
| `FIREBASE_ENABLED` | PRESENT |
| `GOOGLE_AUTH_ENABLED` | PRESENT |
| `REVENUECAT_ANDROID_API_KEY` | MISSING |
| `REVENUECAT_ENTITLEMENT_ID` | PRESENT — `premium` |
| `ADMOB_ENABLED` | INVALID — currently false |
| `ADMOB_ANDROID_APP_ID` | MISSING |
| `ADMOB_REWARDED_ANDROID_ID` | MISSING |
| `ADMOB_INTERSTITIAL_ANDROID_ID` | MISSING |
| `ADMOB_INTERSTITIAL_EVERY_MATCHES` | MISSING from explicit Production config |
| `PRIVACY_POLICY_URL` | MISSING |
| `TERMS_URL` | MISSING |
| Firebase Android file/package metadata | PRESENT |
| Release signing material | PRESENT |

## Fail-closed enforcement

`scripts/check-release-integrations.mjs` rejects a non-Production environment, missing or placeholder values, localhost/non-HTTPS URLs, secret Supabase keys, Google test AdMob IDs, enabled voucher gates, incomplete Firebase metadata, and incomplete signing.

`mobile/android/app/build.gradle.kts` rejects Release tasks when the intended signing material is incomplete, when the AdMob App ID is missing, or when the Google test publisher is used. It no longer falls back to debug signing for Release.

`scripts/build-production-apk.ps1` runs the validator before invoking Flutter and stops when validation fails.

## Supabase

The mobile URL matches the existing locally linked intended Production project. The client uses only the public/anon key. No Supabase database command, SQL, migration change, link change, or Production mutation was performed in this phase.
