# AHDASH | 11 — iOS External Linking Checklist

**Scope:** verification and completion against the existing Production services  
**Bundle ID authority:** `mobile/ios/Runner.xcodeproj/project.pbxproj`  
**Rule:** do not create replacement Supabase or Firebase projects and do not store private keys, client secrets, certificates, or profiles in Git.

## A. Current identifiers

| Item | Current state |
|---|---|
| iOS Bundle ID | `com.ahdash.eleven` |
| Supabase | **EXISTING PRODUCTION PROJECT** — preserve its URL, anon key, auth users, and deployed 27/27 migration history |
| Firebase | **EXISTING PROJECT** — preserve it and verify its existing iOS app registration |
| Mobile auth callback | `com.ahdash.eleven://login-callback` |
| RevenueCat entitlement | `premium` |

## B. Firebase iOS

| What to verify | Where | Expected relationship/state |
|---|---|---|
| Existing iOS app registration | Existing Firebase project → Project settings → Your apps | Bundle ID is exactly `com.ahdash.eleven`; do not create a second Firebase project |
| Protected iOS config | Firebase iOS app and Codemagic `FIREBASE_IOS_CONFIG` | Base64-decoded value is the current `GoogleService-Info.plist` for that same iOS app |
| Config metadata | Decoded plist, without publishing values | `BUNDLE_ID` matches; `PROJECT_ID` belongs to the existing Production Firebase project; `GOOGLE_APP_ID` is present |
| Google iOS OAuth metadata | Decoded plist and Google/Firebase authentication configuration | `CLIENT_ID` and `REVERSED_CLIENT_ID` are present and belong to the same iOS registration |
| Google callback | Final built `Runner.app/Info.plist` | `GIDClientID` equals plist `CLIENT_ID`; a URL scheme equals plist `REVERSED_CLIENT_ID` |
| Google provider state | Firebase/Google Cloud console used by the existing project | Google sign-in is enabled and the iOS OAuth client is associated with `com.ahdash.eleven` |
| APNs connection | Existing Firebase project → Project settings → Cloud Messaging → Apple app configuration | Valid APNs authentication key or certificate is linked for the same Apple team/app; Team ID and Key ID match Apple Developer |
| Final archive contents | Successful Codemagic archive/IPA | Exactly one correct `GoogleService-Info.plist` is bundled and Firebase initializes without a configuration error |

Repository evidence: the ignored local iOS config matches `com.ahdash.eleven` and the existing Android config's Firebase project relationship. The protected Codemagic value remains **EXTERNAL_VALUE_VERIFICATION_REQUIRED** until the macOS workflow validates it.

## C. Supabase Auth

Verify these items in the **existing Production Supabase project** only.

| Where | Expected state |
|---|---|
| Authentication → Providers → Email | Enabled according to the current email sign-up/sign-in policy; current confirmation settings are documented for TestFlight testers |
| Authentication → Providers → Anonymous Sign-Ins | Enabled because the current guest implementation calls Supabase anonymous sign-in; no fake-user system is required |
| Authentication → Providers → Google | Enabled with the existing Google web client credentials required by Supabase; provider state is **EXTERNAL_PROVIDER_VERIFICATION_REQUIRED** |
| Authentication → Providers → Apple | Enabled with the identifiers/secret generated from the matching Apple Developer configuration; provider state is **EXTERNAL_PROVIDER_VERIFICATION_REQUIRED** |
| Authentication → URL Configuration | The approved redirect allow-list contains `com.ahdash.eleven://login-callback` exactly; retain existing web callbacks that belong to the same Production product |
| Authentication → Users / Logs | TestFlight sign-in creates/restores the expected user and no duplicate identity is created during callback or relaunch |

Never place a Supabase service-role key in Flutter or Codemagic client build variables.

## D. Apple Developer

| What to verify/complete | Where | Expected state or secret handling |
|---|---|---|
| Explicit App ID | Apple Developer → Certificates, Identifiers & Profiles → Identifiers | Bundle ID exactly `com.ahdash.eleven` |
| Sign in with Apple capability | The matching App ID | Enabled; it must agree with the repository entitlement `com.apple.developer.applesignin = Default` |
| Push Notifications capability | The matching App ID | Enabled; the distribution profile must authorize the app's `aps-environment` entitlement |
| APNs authentication | Apple Developer → Keys, then existing Firebase Cloud Messaging settings | **VALUE NEEDED:** APNs `.p8` key, Key ID, and Team ID. **WHERE TO GET IT:** the authorized Apple Developer account. **WHERE TO ENTER IT:** the existing Firebase project's Apple app configuration. Never add the key to Git |
| App Store distribution signing | Apple Developer/Codemagic signing integration | Valid distribution certificate and App Store provisioning profile for `com.ahdash.eleven`; private certificate material stays in Codemagic/Apple, not Git |
| Provisioning profile capabilities | Apple Developer/Codemagic | Profile includes Sign in with Apple and Push Notifications and is regenerated/refreshed after capability changes |
| Services ID, only if required by the configured Supabase Apple OAuth flow | Apple Developer → Identifiers → Services IDs | **VALUE NEEDED:** Services ID matching the Supabase provider client-id configuration. **WHERE TO GET IT:** the authorized Apple Developer account. **WHERE TO ENTER IT:** existing Supabase Apple provider settings; do not place a private key in Flutter |
| Sign in with Apple key, only if required by that provider flow | Apple Developer → Keys | **VALUE NEEDED:** Apple key ID, Team ID, and `.p8` private key used to generate the provider client secret. **WHERE TO GET IT:** authorized Apple Developer account. **WHERE TO ENTER IT:** existing Supabase Apple provider secret fields or approved secret-management process; never Git/Codemagic dart-defines |

The current mobile flow uses Supabase browser OAuth with the custom callback. Provider-side Services ID/key requirements therefore depend on the existing Supabase Apple configuration and must be confirmed there rather than duplicated in the app.

## E. Google iOS Auth

Confirm one continuous identity chain:

1. The existing Firebase iOS app has Bundle ID `com.ahdash.eleven`.
2. Its iOS OAuth client is the source of `CLIENT_ID` and `REVERSED_CLIENT_ID` in the protected plist.
3. Codemagic decodes that plist to `mobile/ios/Runner/GoogleService-Info.plist`.
4. Before the IPA build, Codemagic writes the plist `CLIENT_ID` to `GIDClientID` and its `REVERSED_CLIENT_ID` to the Google URL scheme.
5. Flutter acquires the Google ID token through the native iOS client and exchanges it with the existing Supabase Google provider.
6. The Supabase provider's Google credentials belong to the same existing Google/Firebase project configuration; the iOS client must not be replaced with the Android OAuth client.
7. Verify chooser, cancel, failure, success, logout, account switch, persistence, and guest-to-account behavior on TestFlight.

No Google client secret belongs in the mobile binary.

## F. Codemagic

The iOS workflow uses groups `ahdash_shared`, `firebase`, `revenuecat`, and `admob`, the `ios_signing` configuration, and the `ahdash11_app_store` App Store Connect integration.

| Existing name/config | Workflow status | External value status / expected relationship |
|---|---|---|
| `BUNDLE_ID` | `ALREADY_REFERENCED` | Fixed to `com.ahdash.eleven`; must match signing, Firebase, and App Store Connect |
| `PROJECT_BUILD_NUMBER` | `ALREADY_REFERENCED` | Codemagic-provided monotonically valid build number |
| `SUPABASE_URL` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: existing Production project URL |
| `SUPABASE_ANON_KEY` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: public anon key for the same Production project; never service-role |
| `FIREBASE_IOS_CONFIG` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: base64 plist for the existing Firebase iOS app and exact Bundle ID |
| `APP_ENV` | `ALREADY_REFERENCED` | Workflow literal passed as `production` |
| `FIREBASE_ENABLED` | `ALREADY_REFERENCED` | Workflow literal passed as `true` |
| `GOOGLE_AUTH_ENABLED` | `ALREADY_REFERENCED` | Workflow literal passed to `flutter build ipa` as `true` |
| `APPLE_AUTH_ENABLED` | `ALREADY_REFERENCED` | Workflow literal passed to `flutter build ipa` as `true` |
| `REVENUECAT_IOS_API_KEY` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: RevenueCat public iOS SDK key for this App Store app |
| `REVENUECAT_ENTITLEMENT_ID` | `ALREADY_REFERENCED` | Must be exactly `premium` |
| `ADMOB_ENABLED` | `ALREADY_REFERENCED` | Workflow literal passed as `true` |
| `ADMOB_IOS_APP_ID` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: Production iOS app ID for this Bundle ID; validator rejects Google's test publisher |
| `ADMOB_INTERSTITIAL_IOS_ID` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: Production iOS interstitial unit |
| `ADMOB_REWARDED_IOS_ID` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: Production iOS rewarded unit |
| `ADMOB_INTERSTITIAL_EVERY_MATCHES` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: approved positive cadence |
| `PRIVACY_POLICY_URL` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: final reachable HTTPS Production policy |
| `TERMS_URL` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: final reachable HTTPS Production terms |
| `ios_signing` for `com.ahdash.eleven` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: valid App Store certificate/profile with Apple and push capabilities |
| `app_store_connect: ahdash11_app_store` | `ALREADY_REFERENCED` | `VALUE_VERIFICATION_REQUIRED`: active API integration authorized for the matching App Store Connect app/team |

`MISSING_FROM_WORKFLOW`: **none among the currently required iOS Release inputs**. Confirm protected values in Codemagic without copying them into this checklist or logs.

## G. App Store Connect

After the first successful signed IPA only:

- Verify the existing app record; create it only if no record exists, using Bundle ID `com.ahdash.eleven`.
- Confirm the uploaded build appears in TestFlight and assign it first to the configured Internal Testers group.
- Complete export compliance and any encryption questions accurately.
- Configure the monthly and annual auto-renewable subscriptions, subscription group, localization, price, review screenshot, and status required for RevenueCat's current monthly/annual packages.
- Link both products to the current RevenueCat offering and entitlement `premium`, then verify Sandbox product loading.
- Complete App Privacy disclosures from actual SDK/data behavior; do not infer them solely from repository manifests.
- Complete age rating, review contact, demo/test instructions, support URL, privacy URL, terms/EULA relationship, screenshots, description, and rights declarations.
- Keep Production submission manual. The workflow must retain `submit_to_app_store: false` until a separately authorized release decision.

## H. First TestFlight device test

1. Install the internal build from TestFlight on a physical iPhone.
2. Perform a fresh launch and verify bootstrap/onboarding and safe failure behavior.
3. Start a guest session and confirm only guest-allowed local surfaces are available.
4. Create an Email account and complete any configured confirmation step.
5. Sign in with Email and verify expected error handling with invalid/expired credentials.
6. Log out and verify protected account/cloud surfaces are no longer accessible.
7. Complete Google Sign-In, including account chooser and successful Supabase session.
8. Log out from Google, then verify cancellation and account-switch behavior.
9. Complete Sign in with Apple, including consent/relay-email behavior and cancellation.
10. Kill and reopen the application.
11. Verify the authenticated session restores without duplicate identity or stuck loading state.
12. Request notification permission and verify allow/deny behavior.
13. Send an FCM test notification to the registered iOS token.
14. Verify foreground receipt, presentation, inbox state, and navigation.
15. Verify background receipt and notification navigation.
16. Verify terminated-state receipt and notification navigation after cold start.
17. Play a complete local Party game and verify guest/authenticated behavior.
18. Play a complete local Solo game and verify resume/failure behavior.
19. Open Premium and verify the current RevenueCat offering exposes monthly and annual packages.
20. Complete a monthly Sandbox purchase and confirm entitlement `premium`.
21. Reinstall or use the approved test account and restore the purchase.
22. Confirm Premium category/content access follows the active entitlement.
23. Confirm ads are removed for Premium and non-Premium consent/ad paths behave correctly.
24. Delete the test account and verify local/session cleanup and relaunch behavior.
25. Re-test Apple OAuth and all supported auth/notification deep-link callbacks, including invalid callback safety and confirmation that removed Friends/Online/1v1/2v2/rooms remain unreachable.
