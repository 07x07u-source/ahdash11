# AHDASH V10 — Phase A portrait migration report

Date: 2026-09-05  
Scope: foundation, orientation, keyboard safety, Launch, Onboarding, Sign In, Create Account, Home. Party V10 is intentionally not started.

## A–F — platform and shared foundation

**A. Orientation before/after.** Before Phase A, `main.dart` allowed `portraitUp`, `portraitDown`, `landscapeLeft`, and `landscapeRight`. After Phase A the active Flutter application requests only `DeviceOrientation.portraitUp`.

**B. Android orientation.** `mobile/android/app/src/main/AndroidManifest.xml` now declares `android:screenOrientation="portrait"` on `MainActivity`. Existing `singleTop`, `adjustResize`, deep-link intent filters, and OAuth callback scheme are unchanged.

**C. iOS orientation.** `mobile/ios/Runner/Info.plist` keeps `UIInterfaceOrientationPortrait` only for both iPhone and iPad. URL schemes, bundle configuration, and callback handling are unchanged.

**D. Shared V10 responsive widgets.** Added `AhdashV10Metrics`, `AhdashV10Frame`, `AhdashV10KeyboardScroll`, `AhdashV10PrimaryButton`, and `AhdashV10ScreenTitle` in `mobile/lib/shared/presentation/v10_portrait.dart`. They reuse the existing palette, spacing, typography, radius, and motion tokens; no parallel design-token system was created.

**E. Keyboard-safe architecture.** `AhdashV10KeyboardScroll` combines real `SafeArea`, `LayoutBuilder`, `SingleChildScrollView`, `MediaQuery.viewInsets.bottom`, a viewport-derived minimum height, and drag dismissal. Auth fields use `next`/`done`; tapping outside unfocuses the field. The form is never shrunk to hide content.

**F. Scroll strategy.** Sign In/Create Account always use the reusable keyboard scroll surface. Onboarding art/content can scroll inside its allocated portrait region. Home uses bounded vertical scrolling as an accessibility/short-height fallback while remaining a single-screen launcher under normal portrait sizes.

## G–K — screens 01–05

**G. Launch.** Migrated to the V10 warm Paper treatment with the 160px canonical badge, Arabic wordmark, `A H D A S H`, gold tagline, restrained reveal, Reduced Motion support, and unchanged destination-resolution/session initialization.

**H. Onboarding.** Migrated to a portrait-native single-step composition with 220px art surface, brand/skip header, progress, full-width next CTA, real persistence, and truthful Party concepts. The final copy continues to describe the current highest-score win rule instead of the illustrative “first to eleven” claim.

**I. Sign In.** Implemented the V10 stadium hero and rounded Paper form card, Google and Apple provider actions, email/password fields, safe loading/error states, guest entry, and real vertical reachability.

**J. Create Account.** Implemented the compact V10 composition with both enabled providers, name/email/password only, password visibility, account CTA, and sign-in link. Content remains scrollable at 360×800 and with a keyboard.

**K. Home.** Implemented the portrait game-launcher composition with stadium/scrim, canonical identity, 96px trophy treatment, primary “ابدأ لعبة جديدة” card, secondary custom Tournament card, resume state, and safe scrolling. Party start still calls `beginNewGame()` then the canonical `/party/categories` route; Tournament still routes to `/tournaments/create`.

## L–R — authentication status

**L. Google Sign-In.** **Implemented in code:** the V10 action reuses `AuthController` → existing `AuthRepository` → native Google client/Supabase ID-token exchange. Loading and a synchronous cross-provider double-launch guard are retained and tested. **Configured externally:** client IDs and Supabase provider settings remain environment responsibilities. **Physically tested:** not tested on a physical device in this phase.

**M. Apple Sign-In code.** **Implemented in code:** the V10 Apple action reuses the existing `OAuthProvider.apple` Supabase redirect and the same guarded controller/deep-link return architecture. Failure/cancel paths never create a fake user in production.

**N. Apple external configuration.** **Configured externally:** not verified here. Apple Developer App/Service ID association, return URL, key/team configuration, and Supabase Apple-provider settings must be confirmed for `com.ahdash.eleven`. `Runner.entitlements` currently contains push entitlement only; no native Sign in with Apple capability was invented. **Physically tested:** not tested on device.

**O. Email/password.** Existing Supabase sign-in/sign-up calls are preserved. Submits expose loading, block button re-entry, navigate only when controller state contains a real user, and map failures to safe Arabic UI without raw backend strings.

**P. Forgot password.** No real reset flow exists in the repository, so the illustrative Figma link was not enabled. This is an explicit product gap, not a fake success path.

**Q. Guest.** Preserved because the existing production architecture genuinely supports it. Guest remains on Sign In and is not used as a substitute for provider/email success.

**R. Provider branding.** Apple uses the platform Apple glyph and explicit provider wording. The Figma placeholder `G` was deliberately not exported. Google uses explicit official provider naming without a fabricated glyph; a future approved Google brand asset can be added without changing auth behavior.

## S–W — product truth, RTL, accessibility

**S. Fake-data cleanup.** No XP, level, coins, wallet, rating, accuracy, fake presence, fake auth result, or fake price was added to any Phase A surface. Home does not synthesize a profile identity.

**T. Online routes.** Online is not surfaced by Home. Existing `/online`, `/online/match/:matchId`, and `/room/:roomId` fail-safe redirects remain unchanged.

**U. Thmanyah Sans.** Existing original binaries and registered 400/500/700/900 weights are unchanged and remain the production family. No Cairo or replacement font was added.

**V. RTL.** All Phase A compositions retain RTL direction. Email and `A H D A S H` keep intentional mixed-direction handling; provider names are not mirrored as graphics.

**W. Accessibility.** Safe areas are runtime-derived; controls retain 44–54px+ targets; password visibility has a changing Arabic tooltip; errors are live regions; provider controls have explicit text; disabled/loading behavior is visible; Reduced Motion is respected.

## X–AC — verification

**X. Responsive sizes tested.** Automated keyboard/foundation matrix covers 360×800, 390×844, 393×852, 412×915, and 430×932 at text scales 1.0, 1.2, and 1.3. Screen Goldens cover the two primary sizes.

**Y. Keyboard sizes tested.** Sign In and Create Account Goldens cover simulated 300px `viewInsets` at 360×800 and 390×844. The focused password and CTA remain reachable through actual scrolling.

**Z. Goldens.** 14/14 V10 Phase A states pass: Launch, representative Onboarding, Sign In, Sign In keyboard, Create Account, Create Account keyboard, and Home at both primary sizes. All 14 raw PNGs were opened and manually reviewed after explicit image precaching and Cupertino icon-font loading.

**AA. Widget/focused tests.** Focused coverage includes platform orientation files, five portrait sizes × three text scales, `viewInsets`/scroll reachability, Sign In/Create Account validation/loading/error/navigation, Google and Apple double-launch protection, onboarding persistence, Home Party/Tournament routes, and absence of Online/XP/Coins/Wallet affordances.

**AB. Broad tests.** Broad non-visual suite: **307/307 passed**. Phase A focused and existing Auth/Home/Onboarding tests are included in that result.

**AC. Analyze.** `flutter analyze`: **No issues found**.

## AD–AF — files, blockers, safety confirmation

**AD. Files changed.** Phase A changes are confined to:

- `mobile/lib/main.dart`
- `mobile/android/app/src/main/AndroidManifest.xml`
- `mobile/ios/Runner/Info.plist`
- `mobile/lib/shared/presentation/v10_portrait.dart`
- `mobile/lib/features/onboarding/presentation/launch_screen.dart`
- `mobile/lib/features/onboarding/presentation/onboarding_screen.dart`
- `mobile/lib/features/auth/presentation/auth_screen.dart`
- `mobile/lib/features/home/presentation/home_screen.dart`
- `mobile/test/features/auth/auth_screen_test.dart`
- `mobile/test/features/auth/social_auth_test.dart`
- `mobile/test/features/home/home_screen_test.dart`
- `mobile/test/features/onboarding/onboarding_screen_test.dart`
- `mobile/test/v10_phase_a/v10_portrait_contract_test.dart`
- `mobile/test/visual/v10_phase_a_golden_test.dart`
- `mobile/test/visual/goldens/v10_phase_a/*.png` (14 files)
- `docs/v10_phase_a_portrait_migration_report.md`

**AE. Known blockers.** Physical Google/Apple OAuth verification and external Apple/Supabase provider configuration are outside local Phase A evidence. A real forgot-password service/route is absent. These are documented without simulated success.

**AF. Confirmation.** No Supabase migration or push was run. No Tournament remote deployment occurred. Tournament remote mutation remains fail-closed. Online was not activated. No Dark Mode, Coins, Wallet, or XP was added. No release APK/AAB was built. The two pending migration hashes remain unchanged:

- `gameplay_depth_v1`: `C4968EA1824A3D9BBE942BABD3DE27F0F3267AF88DD834A4458861424267CCD1`
- `tournament_bracket_safety_v2`: `E4422D46197D187B50F544A2828667B3492F96F3C55BE7786420CCB122559E14`
