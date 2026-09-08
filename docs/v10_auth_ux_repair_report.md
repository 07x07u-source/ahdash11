# AHDASH | 11 — V10 Auth UX repair report

Date: 2026-09-06  
Scope: Auth only — screens 03 and 04  
Implementation status: code-side blocker repaired; **Physical QA not complete**

## Root cause of the missing Google button

The issue was a Flutter build-configuration defect, not a missing Google or
Supabase provider:

1. `AppConfig.googleAuthEnabled` defaults to `false` unless the compile-time
   `GOOGLE_AUTH_ENABLED` define is supplied.
2. `AuthScreen` correctly gates Google on that flag, a valid Supabase backend,
   and a native mobile platform.
3. The Android Codemagic build passed Supabase and Firebase defines but omitted
   `--dart-define=GOOGLE_AUTH_ENABLED=true`; a local Debug build without
   `--dart-define-from-file=.env` had the same result. The UI therefore omitted
   Google before native initialization could run.
4. The checked Android `google-services.json` matches `com.ahdash.eleven` and
   contains Android and Web OAuth clients. A read-only `/auth/v1/settings` check
   reports Google enabled in Supabase and Apple disabled.

The Android Codemagic command now passes the Google flag. The fresh Debug APK
was built from `.env`, so its real Android configuration exposes Google.

## Structural repair

Before, both Auth screens used a dark full-screen layer with a large unused
upper region and a low paper card. Branding was weak, the provider mark was a
drawn `G`, Create Account and Guest competed in dense actions, and long/keyboard
states depended on compressed geometry.

After:

- the full portrait surface uses Paper0 with a compact AHDASH | 11 brand row;
- a bordered Paper1 content sheet begins near the top instead of after a dead
  40–50% region;
- Sign In has a clear title/support line, Google, optional Apple, divider,
  labelled email/password fields, primary action, account creation, and a
  separately outlined Guest action;
- Create Account uses only the real name/email/password contract, real
  validation, Google availability, a clear existing-account action, and
  reachable legal copy;
- every field keeps autofill hints, email keyboard, next/done actions, focus and
  error borders, password visibility, and 52 px controls;
- scroll position no longer survives between Auth modes, and initial content is
  explicitly settled at the top on a normal physical state.

## Provider behavior

- Android + valid configuration: active Google button is visible.
- During social authentication: the same 52 px button remains in place with a
  progress indicator, preventing layout jump and duplicate taps.
- Configuration/provider failure: the button remains visible and an Arabic safe
  message is shown; raw exceptions are not exposed.
- Google uses the official four-colour mark from Google's pre-approved asset
  bundle, not a fabricated letter icon.
- Apple appears only on iOS when `APPLE_AUTH_ENABLED`, a valid backend, and
  platform support all agree. Supabase currently reports Apple disabled, so it
  is not advertised on the Android APK and was not faked.

## Visual comparison

| Variant | Before | After | Decision |
|---|---:|---:|---|
| 03 Sign In Primary | 94.86 | 67.65 | intentional physical-UX override |
| 03 Sign In Compact | 93.85 | 69.90 | intentional physical-UX override |
| 03 Sign In Keyboard | 89.87 | 82.19 | keyboard-safe physical composition |
| 04 Create Account Primary | 93.52 | 69.09 | intentional physical-UX override |
| 04 Create Account Compact | 94.45 | 72.17 | intentional physical-UX override |
| 04 Create Account Keyboard | 88.37 | 90.95 | improved, still platform/layout exception |

The normal-state score drop is dominated by replacing the large black reference
region with intentional warm-paper UI and moving the card substantially higher,
as explicitly required by the physical-device repair brief. Reproducing those
pixels would restore the blocker. The inner form hierarchy remains based on V10;
physical usability and truthful Android provider state take precedence.

Evidence: `docs/v10_parity/auth_ux_repair/`.

## Validation

- Auth-focused behavior/responsive/visual tests: **97/97 passed**.
- Normal complete `flutter test`: **560/560 passed**, 0 failures.
- `flutter analyze`: **No issues found**.
- Tested sizes: 360x800, 390x844, 393x852, 412x915, 430x932.
- Tested text scales: 1.0, 1.2, 1.3.
- Every size/scale was exercised both normally and with approximately 300 px
  keyboard inset for Sign In and Create Account; no overflow.

## Debug APK

`mobile/build/app/outputs/flutter-apk/app-debug.apk`  
Size: 258,774,599 bytes  
SHA-256: `57E0FE340E78CF8125E90A1D4C9D00BF2902307E76F76E75B6A4142E91F50CB8`

Built with `--dart-define-from-file=.env`; no Production AAB was built.

## Files changed

- `mobile/lib/features/auth/presentation/auth_screen.dart`
- `mobile/assets/images/providers/google_g_light.png`
- `mobile/pubspec.yaml`
- `codemagic.yaml`
- `mobile/test/features/auth/auth_screen_test.dart`
- `mobile/test/visual/auth_ux_repair_golden_test.dart`
- `mobile/test/visual/v10_phase_a_golden_test.dart`
- Auth Golden PNGs under `mobile/test/visual/goldens/`
- evidence under `docs/v10_parity/auth_ux_repair/`
- `docs/v10_auth_ux_repair_report.md`
- `docs/v10_figma_flutter_parity_matrix.md`

No Supabase schema/deploy/migration/RLS/RPC operation occurred. No Production
release, signing, publishing, or unrelated-screen change occurred.
