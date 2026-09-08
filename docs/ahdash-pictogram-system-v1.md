# AHDASH Pictogram System V1

## Purpose

AHDASH pictograms are compact brand images for memory, identity, emotion, and orientation. They are not navigation icons and they do not replace familiar utility symbols. Back, close, search, settings, share, volume, favorite, add/remove, chevrons, and refresh remain small system-style utilities when they materially improve clarity.

The product-owner direction for this implementation is raster imagery, so the production masters are transparent PNG files rather than SVG files.

## Visual construction

- Master canvas: 256 × 256 px RGBA PNG.
- Safe area: 20 px on every side; visible geometry is optically centered inside the remaining 216 × 216 px field.
- Geometry: solid, bold silhouettes with paired cuts, split geometry, and two related forms derived subtly from the AHDASH `11` mark.
- Color stored in the file: neutral black geometry only. Flutter applies one semantic tint at render time.
- Background: true alpha; no beige/black rectangle, badge, circle, gradient, glow, shadow, text, emoji, photo, or 3D treatment.
- Optical rule: preserve recognizable large shapes; avoid detail that disappears below 32 px.
- Family rule: one hero pictogram per screen in normal use.

## Runtime sizes

| Role | Size |
|---|---:|
| Inline identity | 24–32 px |
| Helper action | 40–56 px |
| Small state / educational | 40–64 px |
| Hero | 64–96 px |
| Rare champion hero | up to 112 px |

The renderer caps decoded raster size to the requested logical size × device pixel ratio and keeps the interaction target independent from the visible image.

## Runtime color tokens

| Tone | Flutter source | Light | Dark | Use |
|---|---|---|---|---|
| `standard` | `AhdashColors.textPrimary` | `#191714` | `#F4EBDD` | Default brand imagery |
| `achievement` | `AhdashColors.gold` | `#FFC857` | `#FFC857` | Win, champion, Premium only |
| `inverse` | `AhdashColors.primaryForeground` | `#191714` | `#171613` | Controlled inverse surfaces |
| `success` | `AhdashColors.success` | `#527F0C` | `#78A91B` | Selected/confirmed helper state only |
| `muted` | `AhdashColors.disabled` | `#A89F93` | `#71695E` | Consumed or unavailable state |

## Asset inventory and use

| Asset | Purpose | Main screen(s) | Typical size | Tone | Motion |
|---|---|---|---:|---|---|
| `ahdash_win.png` | Victory identity | Party Result, How To win step | 58–88 | achievement in Result; achievement in win education | Short scale/reveal in Result |
| `ahdash_champion.png` | Tournament champion | Tournament Champion | 64–128 bounded by layout | achievement | Short reveal |
| `ahdash_tournament.png` | Tournament identity | Tournament Hub/Create | 36–82 | standard | Static |
| `ahdash_draw.png` | Bracket draw/re-pairing | Tournament Draw | 36–64 | standard | Static in current build; structure permits later path motion |
| `ahdash_premium.png` | Premium identity | Premium | 34–48 | achievement | Static |
| `ahdash_categories_step.png` | Choose categories | Onboarding, How To | 38–72 | standard | Static |
| `ahdash_teams_step.png` | Build two teams | Onboarding, How To | 38–72 | standard | Static |
| `ahdash_question_step.png` | Choose/answer a question | Onboarding, How To | 38–72 | standard | Static |
| `ahdash_empty_games.png` | No saved game | Saved Party Games | 64 | muted/standard | Static |
| `ahdash_empty_friends.png` | No friends yet | Friends | 56 | muted | Static |
| `helpers/ahdash_two_chances.png` | فرصتين | Party Helpers/game action | 24–64 | standard/success/muted | Selection scale only |
| `helpers/ahdash_call_friend.png` | استنجد | Party Helpers/game action | 24–64 | standard/success/muted | Selection scale only |
| `helpers/ahdash_risk.png` | مخاطرة | Party Helpers/game action | 24–64 | standard/success/muted | Selection scale only |
| `helpers/ahdash_bench.png` | على الدكة | Party Helpers/game action | 24–64 | standard/success/muted | Selection scale only |
| `helpers/ahdash_pass.png` | مرّرها | Party Helpers/game action | 24–64 | standard/success/muted | Selection scale only |

## Usage rules

### Do

- Use a pictogram for a memorable AHDASH feature, achievement, educational step, or justified empty state.
- Let nearby text carry the detailed meaning.
- Use the same PNG geometry in Light and Dark themes and tint it through `AhdashPictogramView`.
- Exclude decorative imagery from semantics. Add a semantic label only when no adjacent text communicates the meaning.
- Keep Back/Search/Refresh/Close and similar actions as familiar utility symbols.

### Do not

- Do not add a pictogram beside every title, number, metadata label, or button.
- Do not put pictograms in navigation.
- Do not add colored circle backgrounds, persistent badges, shadows, glow, or multi-color fills.
- Do not recolor normal educational imagery lime; green is reserved for an actual selected/success state.
- Do not create a new asset without an identified screen, purpose, size, and semantic color.

## Accessibility and RTL

The geometry is centered and direction-neutral unless a future action requires direction. `AhdashPictogramView` is decorative by default (`excludeFromSemantics: true`). A meaningful pictogram opts into a concise `semanticLabel`; adjacent explanatory text avoids duplicate announcements.

## Production and rights record

The 15 concepts were generated specifically for AHDASH through the built-in ImageGen workflow using original prompts that prohibited copying Apple, Material, Lucide, Fluent, sports brands, text, and logos. Image generation returned raster concepts with a baked preview checkerboard, so a deterministic local cleanup removed the light background, converted geometry to a true alpha mask, normalized optical bounds, and exported 256 × 256 RGBA PNG masters. No third-party icon asset or sports-brand artwork is included.

The normalization script is `tools/normalize_pictograms.ps1`. The runtime renderer is `mobile/lib/shared/presentation/ahdash_pictograms.dart`.

## Validation

- Contact sheet: `docs/visual-validation/ahdash-pictograms-contact-sheet.png`.
- Tested sizes: 24, 32, 48, 64, and 96 px.
- Themes: Light Ink, Dark warm inverse, Gold achievement, controlled success, and muted.
- Asset/semantics test: `mobile/test/shared/presentation/ahdash_pictograms_test.dart`.
- Checkpoint goldens: `docs/visual-validation/v8-1-pictograms/`.

