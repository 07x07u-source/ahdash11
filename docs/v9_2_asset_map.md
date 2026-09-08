# AHDASH 11 V9.2 — Asset map

## Phase 6 utility screens (2026-09-05)

Screens 38–43 reuse existing Player 11 artwork, profile_background.webp, logo, Premium/empty pictograms and Thmanyah Sans 400/500/700/900. No production raster/font/audio asset was added. Football logo URLs are used only for licensed/custom visual status; all 114 clubs in the read-only catalog audit used fallback. The 35 PNGs in docs/visual-validation/v9_2_phase6 are deterministic test baselines, not production content. /store is now Premium and /wallet redirects there; legacy coin artwork remains inactive.

## Phase 5 Tournament decision (2026-09-05)

Screens 19–27 reuse the original packaged logo, Tournament/Draw/Champion Ahdash pictograms and Thmanyah Sans 400/500/700/900. No production image, font, Rive or audio asset was added. Warm beige surfaces, tabs, match connectors, progress and team rows are code-native UI, not exported whole-screen artwork. Figma design context informed composition; prototype Cairo and demo roster/score data were not imported into the app.

The 45 Light-mode Tournament PNGs under `mobile/test/visual/goldens/tournament` are deterministic test baselines only. Legacy Dark PNGs remain on disk but are not part of the Phase 5 suite or active UI. No asset deletion was needed.

## Existing approved/local foundations

| Purpose | Existing source | Phase 1 decision |
|---|---|---|
| Canonical logo | `assets/branding/logo-symbol.png`, `logo-horizontal.png`, `logo-wordmark.png`, app icon | reuse; never recreate with text or generic icons |
| Brand texture | `assets/branding/brand-pattern.png` | reuse only where the approved frame includes texture |
| Thmanyah | `assets/fonts/thmanyah/*.otf` | active registration limited to Sans 400/500/700/900 |
| Player 11 | `assets/player11/player11-male-card.png`, `player11-female-card.png` | reuse symbolic avatar; no realistic portrait substitute |
| Branded pictograms | win, champion, tournament, draw, premium, setup steps, empty games/friends PNGs | reuse at feature/result scale through `AhdashPictogramView` |
| Party helpers | two chances, call friend, risk, bench, pass PNGs | bind to real helper IDs/availability; do not use Figma demo helpers |
| Existing screen media | login/home/profile/premium/question/team/leaderboard backgrounds and mode/result art | evaluate screen-by-screen against Figma before replacement |
| Category covers | Supabase media URL with `AhdashImage`; Drift/bundled last-known fallback | remote published media is authoritative; never hardcode Figma thumbnails |

## Image delivery contract

Remote media continues through the shared cached-image layer with stable aspect ratio, decode sizing where possible, crop/focal behavior, loading placeholder, and branded error fallback. Core gameplay must not show the platform broken-image icon. A previously cached or bundled fallback may be used only when it does not misrepresent category/question content.

## Assets not to activate in V9.2

Currency, wallet, and store imagery exists in the repository, but the approved active UX explicitly excludes Coins/Wallet. Presence on disk is not permission to expose it. Old store surfaces and routes are a product-scope risk to resolve in a later phase.

No `.riv` file exists, so no Rive dependency or placeholder animation is added. No bundled audio/SFX catalog or `audioplayers` dependency exists; media questions currently use their real URLs while UI feedback uses system sounds.

## Missing/candidate source assets

- A canonical vector logo file is not present under `mobile/assets`; only raster PNG variants are packaged. If the design owner has the approved SVG master, export that source once and preserve its geometry.
- The inspected Figma uses photographic stadium/hero treatments on Auth/Home/Profile/Premium. Existing licensed WebP/PNG assets may already satisfy these roles, but visual comparison is required during each screen phase.
- If a Figma master contains unique licensed hero art not represented in the repository, export only that original image at an appropriate density. Do not export whole-screen screenshots or prototype category thumbnails.

## Figma export queue

No Figma raster/vector was exported in Phase 1 because screen bodies are intentionally deferred. During the relevant phase, compare and export only if absent:

1. Canonical logo vector master (preferred SVG), if approved for app packaging.
2. Unique Auth/Home hero media from nodes `81:268`/`81:298` and `81:394`/`81:433` only if it differs from existing licensed backgrounds.
3. Unique Profile/Premium hero media from nodes `81:3767`/`81:3838` and `81:4393`/`81:4433` only if it differs from existing assets.
4. Any unique branded pictogram only after confirming the existing Ahdash catalog lacks it.

Do not export Apple SF Symbols, generic utility icons, text rendered as images, entire frames, team names/scores, prices, friend/profile data, or category thumbnails.

## Phase 2 approved exports

| Packaged asset | Figma source | Export | Usage and fallback policy |
|---|---|---|---|
| `mobile/assets/images/backgrounds/v9_2_auth_stadium.png` | Flutter Handoff node `81:268` (same visual used by compact node `81:298`) | Original PNG, 1344×768 | Sign In and Create Account bundled fallback. A published app-content URL remains authoritative when configured; the local file prevents a broken or unstable auth hero. |
| `mobile/assets/images/backgrounds/v9_2_home_stadium.png` | Flutter Handoff node `81:394` (same visual used by compact node `81:433`) | Original PNG, 1344×768 | Home bundled fallback. A published app-content URL remains authoritative when configured. The source contains its intentional black cinematic bands. |

No whole-screen raster, logo, generic icon, rendered text, prototype data, category thumbnail, Coin/Wallet art, or replacement pictogram was exported. The packaged canonical logo and Ahdash pictogram catalog remain the implementation sources.

## Phase 3 asset decision

No new production image, vector, font, Rive, or audio asset was added for screens 06–11.

| Phase 3 usage | Source and policy |
|---|---|
| Category cover/detail image | Real published category `imageUrl` through `AhdashImage`, preserving focal alignment and cache/decode behavior. |
| Category error fallback | Code-native category accent treatment, football mark, and category initial; it is category-aware and does not repeat an unrelated photograph. |
| Helper pictograms | Existing bundled Ahdash assets mapped one-to-one to `two_chances`, `call_friend`, `risk`, `bench`, and `pass`. |
| Team/Ready identity | Existing Ahdash team/setup pictogram plus the persisted team name and approved team color model. |
| Golden media | Deterministic test fixtures only; never wired into production repositories. |

The static Figma category thumbnails were not exported or hardcoded because the published catalog and its rights/readiness state are authoritative. Category Detail likewise uses no exported whole-screen artwork. Phase 3 added no random SFX and no `.riv` dependency.

## Phase 4 asset decision

No new production image, vector, font, Rive, or audio asset was added for screens 12–16.

| Phase 4 usage | Source and policy |
|---|---|
| Question media | Real session snapshot URL/metadata through cached network delivery, bounded decode dimensions, focal alignment, stable aspect ratio, loading state, and safe retry. |
| Media failure | Code-native branded fallback only; no unrelated substitute image and no platform broken-image icon. |
| Image semantics | Constant safe label `وسائط السؤال`; URL, filename, answer, and debug metadata are never announced. |
| Gameplay helpers | Existing bundled Ahdash pictograms mapped one-to-one to the five real helper IDs. |
| Final result | Existing Ahdash win pictogram for a winner and draw pictogram for a tie. |
| Golden-only image | Existing bundled `v9_2_home_stadium.png` provides deterministic image rendering in tests only; production still reads the question snapshot. |

No Contacts/Phone asset or platform integration was introduced for `call_friend`. No `.riv`, random SFX, or new media dependency was added.
