# Release Report — Landscape + Premium + Football 2026/27

Date: 2026-08-29 (Asia/Riyadh)

## Outcome

- Android is Landscape-only (`landscapeLeft`/`landscapeRight`) with a side dock and responsive multi-pane layouts.
- Home, Play, Question, Auth, Settings and Premium received the landscape composition. No emulator was launched.
- `/store` is now Premium and `/wallet` redirects to it. Legacy wallet/store backend and source remain for compatibility, but coins are absent from the active public flow.
- RevenueCat supplies monthly/yearly packages and localized real prices; the client does not hardcode subscription prices or grant competitive advantages.
- Six 2026/27 leagues and 114 clubs are published remotely: 18 Saudi, 20 Premier League, 20 LaLiga, 20 Serie A, 18 Bundesliga, 18 Ligue 1.
- Fourteen remote visual objects are uploaded, registered and published across fourteen content slots, with local fallbacks and rights metadata.

## Database and remote verification

Applied migrations:

- `20260829000200_landscape_premium_football.sql`
- `20260829000300_publish_landscape_assets.sql`
- `20260829000400_republish_rpc_type_fixes.sql`

The last migration republishes the already-corrected RPC bodies so the remote database receives explicit `smallint`, enum and initialized-array casts. It changes no game logic. `supabase migration list` matches local and remote through `20260829000400`. `supabase db lint --linked --level warning` reports no errors; remaining output is legacy static warnings only.

Actual linked RPC counts: 6 leagues / 114 clubs; 14 uploaded / 14 published / 14 slots.

## Validation

- Flutter analyzer: success, zero issues with `--fatal-infos`.
- Flutter tests: 115/115 passed.
- Landscape golden tests: 30/30 passed over 5 resolutions × 2 themes × 3 screens.
- Admin: 43/43 tests, ESLint, TypeScript and production Next.js build passed.
- PostgreSQL parser: 19 migration files / 897 statements passed; SQL tests 6 files / 242 statements passed.
- Edge Functions: 13 files formatting check passed; 11 entry points passed `deno check`.
- Supabase linked lint: zero errors after migration 004.

## Android artifact

- APK: `C:\dev\ahdash11\mobile\build\app\outputs\flutter-apk\app-release.apk`
- Type: Release Signed
- Package read from APK: `com.ahdash.eleven`
- Size: 90,376,630 bytes (86.19 MiB)
- SHA-256: `39DFD2CA7C300ED6F6EC6781BBCF2AEEE5BA4C3638569C6C78D5851AA63DAE39`
- Signature: `apksigner` verified one signer using APK Signature Scheme v2; the referenced release keystore exists.
- Build input: `flutter build apk --release --dart-define-from-file=.env`.
- Google: `GOOGLE_AUTH_ENABLED` is enabled, `google-services.json` exists, and an OAuth client is present.
- Firebase/FCM: Firebase project/app/API configuration is present and the built APK declares the C2DM receive permission.

## Manual device scope

Build/configuration success does not prove live Google login, store purchase/restore, FCM delivery, Supabase flows, 1v1/2v2, offline behavior or frame performance. Those remain explicit manual checks on a physical Android device with real accounts and store/network conditions.
