# AHDASH 11 V9.2 — Phase 2 report

Date: 2026-09-04  
Scope completed: screens 01–05 only

## A. Screens implemented

1. Launch — wide `81:131`, compact `81:147`.
2. Onboarding — wide `81:168`, compact `81:215`.
3. Sign In — wide `81:268`, compact `81:298`.
4. Create Account — wide `81:327`, compact `81:362`.
5. Home — wide `81:394`, compact `81:433`.

Phase 3 work was not started.

## B. Existing functionality preserved

- Launch resolves the real onboarding preference and restored auth/guest state before choosing Onboarding, Auth, or Home.
- Onboarding completion persists through `AppPreferencesController`; widgets do not access SharedPreferences directly.
- Sign In/Create Account retain the real Supabase-backed controller contract, email/password validation, configured social providers, guest entry, loading, safe errors, and success routing.
- Home reads the real Party/Tournament restore state. It never invents a resumable session.
- Published app-content media remains authoritative with exact bundled V9.2 images as stable fallbacks.

## C. Routes and actions connected

| Action | Existing route/behavior |
|---|---|
| Launch state decision | `/onboarding`, `/auth`, or `/home` |
| Onboarding skip/finish | persists completion, then `/auth` |
| Sign In/Create Account success or guest | `/home` |
| Switch auth mode | local state inside the shared `/auth` family |
| Start a Party game | `/party/teams` (existing pre-Phase-3 order preserved) |
| Create a tournament | `/tournaments/create` |
| Resume Party | existing `partyResumeRoute` |
| Resume tournament | `/tournaments/bracket` |
| How to play | `/how-to-play` |
| Settings | `/settings` |

No parallel Navigator flow or Online navigation was added.

## D. Thmanyah and wrapping

- Thmanyah Sans is used from the first render with registered 400/500/700/900 faces.
- Responsive type sizes and explicit line-height constraints keep Arabic headings, metadata, button labels, and form labels readable at short landscape heights.
- Compact auth uses a keyboard-safe scroll surface instead of reducing text below the V9.2 bounds.

## E. Shared components reused or changed

- Reused: `BrandScaffold`, `AhdashBrandLogo`, `AhdashImage`, `AhdashPictogramView`, V9.2 metrics/actions/inputs, theme/color/type tokens, and the existing auth/party/tournament providers.
- `BrandScaffold` now permits the development badge to be disabled explicitly; all five production screens disable it.
- `AppPreferences` gained an owned, persisted onboarding-completion flag and controller action.
- Added the shared password-hidden icon mapping used by the auth family.

## F. Assets reused or exported

- Reused the canonical transparent Ahdash raster logo and existing Ahdash pictograms; neither was redrawn.
- Exported only the approved original Auth stadium from node `81:268` to `mobile/assets/images/backgrounds/v9_2_auth_stadium.png`.
- Exported only the approved original Home stadium from node `81:394` to `mobile/assets/images/backgrounds/v9_2_home_stadium.png`.
- Both are 1344×768 PNG files, use existing declared asset directories, and are documented in `v9_2_asset_map.md`.
- No full-screen screenshot, temporary Figma URL, fake thumbnail, emoji, Rive file, or audio asset was added.

## G. Coin and Wallet on Home

Home contains no Coin balance, Wallet balance/history, XP, fake ranking, shop shortcut, or Coin reward/CTA. Legacy surfaces outside screens 01–05 were not migrated in this phase and are not exposed by the new Home.

## H. Responsive sizes tested

Every screen was rendered and visually reviewed at 800×360, 844×390, 915×412, 1280×720, and 1366×768. Layouts switch between compact and wide composition; no global scale factor is used.

## I. RTL and accessibility

- True RTL direction, header/action ordering, onboarding progression, field alignment, and mixed email text were verified.
- Shared 48dp targets, tooltips/semantic labels, decorative-image exclusion, keyboard actions, view-inset scrolling, focus source order, contrast scrims, and reduced motion are present.
- No required CTA, input, or Arabic label overflowed the five target viewports.

## J. Tests

- Pre-Phase-2 non-Golden baseline: **140 passed; 2 stale UI assertions failed** (the old Auth/Onboarding expectations replaced in this phase).
- Targeted Phase 2 unit/widget/auth tests: **21/21 passed**.
- Complete relevant existing non-Golden suite after Phase 2: **152/152 passed across 41 files**.
- Tests are deterministic and do not use live Supabase/Firebase network services.

## K. Goldens

- Phase 2 Golden matrix: **25/25 passed**.
- Five screens × five required landscape sizes, with Thmanyah Sans, Material/Cupertino icon fonts, deterministic local images, provider overrides, and no analytics.
- Old incompatible Golden suites were not regenerated.

## L. Raw screenshot review

All **25/25** raw PNGs were opened at original resolution and compared with their approved Figma wide/compact composition. Details and intentional differences are recorded in `v9_2_phase2_visual_review.md`.

## M. Files changed for Phase 2

### Production

- `mobile/lib/core/settings/app_preferences.dart`
- `mobile/lib/core/theme/ahdash_icons.dart`
- `mobile/lib/shared/presentation/brand_scaffold.dart`
- `mobile/lib/features/onboarding/presentation/launch_screen.dart`
- `mobile/lib/features/onboarding/presentation/onboarding_screen.dart`
- `mobile/lib/features/auth/presentation/auth_screen.dart`
- `mobile/lib/features/home/presentation/home_screen.dart`
- `mobile/assets/images/backgrounds/v9_2_auth_stadium.png`
- `mobile/assets/images/backgrounds/v9_2_home_stadium.png`

### Tests and visual baselines

- `mobile/test/features/onboarding/launch_screen_test.dart`
- `mobile/test/features/onboarding/onboarding_screen_test.dart`
- `mobile/test/features/auth/auth_screen_test.dart`
- `mobile/test/features/home/home_screen_test.dart`
- `mobile/test/visual/v9_2_phase2_golden_test.dart`
- `docs/visual-validation/v9-2-phase2/*.png` (25 files)

### Documentation

- `docs/v9_2_asset_map.md`
- `docs/v9_2_figma_flutter_implementation_map.md`
- `docs/v9_2_phase2_visual_review.md`
- `docs/v9_2_phase2_report.md`

## N. Known limitations

- The approved Party order change starts in Phase 3. Home deliberately enters the current `/party/teams` route so saved sessions, restoration, and validation remain compatible.
- Compact onboarding scrolls horizontally to the fourth card; it does not shrink all four cards below readable bounds.
- Native social providers appear only when configured. Platform-specific sign-in and verification handoff require device testing.
- Remote published hero media can replace the bundled fallback at runtime by design; Golden tests intentionally use the deterministic local originals.
- Settings/Premium and legacy Store/Wallet route cleanup are outside the five-screen Phase 2 migration; the new Home exposes none of those obsolete affordances.

## O. Manual-device-only tests

Still require an approved physical-device pass in a later release gate: software-keyboard pan/resize behavior, native Google/Apple provider handoff, email verification/deep-link return, screen-reader spoken order, hardware back behavior, extreme system text scale, and real safe-area cutouts. No device or emulator was used in this phase.

## P. Confirmation

- No Emulator.
- No APK build.
- No Supabase push.
- No database migration.
- No fake production data.
- No Online routes reactivated.
