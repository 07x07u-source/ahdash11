# AHDASH 11 V9.2 — Flutter design system

This document describes the Phase 1 foundation derived from the inspected `V9.2 — Flutter Handoff` Figma page. It does not claim that all production screens have been migrated.

## Theme scope

- Active product scope is light-only. `AhdashApp` now uses `ThemeMode.light`.
- `AppTheme.dark` and the persisted `AppThemePreference` remain as legacy infrastructure for old isolated previews and compatibility. The visible theme selector was removed from Settings.
- Material 3 remains the rendering foundation, customized through `ThemeData`, `ColorScheme`, component themes, `AhdashColors`, and Ahdash presentation primitives.
- Dark photographic areas in approved Auth/Home compositions are local media treatments, not a second product theme.

## Color tokens

| Token | Value | Intended use |
|---|---:|---|
| Paper 0 | `#FBF7EF` | app background |
| Paper 1 | `#F4EBDD` | base surface |
| Paper 2 | `#EBDFC9` | raised surface |
| Paper 3 | `#DDCEB5` | muted/disabled grouping |
| Ink | `#191714` | primary text and dark foreground |
| Ink Soft | `#35312B` | secondary text |
| Muted | `#756E63` | metadata |
| Hairline | `#D3C6B2` | borders/dividers |
| Primary Green | `#B6FF3B` | primary action, selected/current/success emphasis |
| Team A Pink | `#E84B8A` | Team A identity only |
| Team B Blue | `#4B8DE8` | Team B identity only |
| Gold | `#FFC857` | champion/winner/premium moments |

The tokens are defined in `AppColors` and exposed contextually by `AhdashColors.light`. Raw values should not be repeated in migrated screens.

## Spacing, radius, sizing

- Spacing follows the approved 4 px rhythm: `4, 8, 12, 16, 20, 24, 32, 40, 48, 64` through `AppSpacing`.
- Active radii are restrained: small `8`, medium `12`, large/media `16`. `pill` is reserved for genuinely pill-shaped controls.
- Minimum interaction target is 44 logical pixels. The standard target is 48.
- Primary action: 48 compact, 52 wide. Secondary action: 46 compact, 48 wide. Input: 48 compact, 52 wide.
- Visible utility glyph: 20 compact, 22 wide.

## Typography and verified font metadata

Active production roles use one Flutter family: `ThmanyahSans`. The Figma substitute font is not copied into Flutter.

| Binary | Internal family/style metadata | Full name | PostScript name | OS/2 weight | Flutter registration |
|---|---|---|---|---:|---:|
| `thmanyahsans-Regular.otf` | family `thmanyah sans`, style `Regular` | `thmanyah sans Regular` | `thmanyahsans-Regular` | 400 | 400 |
| `thmanyahsans-Medium.otf` | family `thmanyah sans Med`, style `Regular` | `thmanyah sans Medium` | `thmanyahsans-Medium` | 500 | 500 |
| `thmanyahsans-Bold.otf` | family `thmanyah sans`, style `Bold` | `thmanyah sans Bold` | `thmanyahsans-Bold` | 700 | 700 |
| `thmanyahsans-Black.otf` | family `thmanyah sans Black`, style `Regular` | `thmanyah sans Black` | `thmanyahsans-Black` | 900 | 900 |

`thmanyahsans-Light.otf` was also inspected (family `thmanyah sans Light`, style `Regular`, PostScript `thmanyahsans-Light`, OS/2 300) but is not required by active roles and is not registered. Serif binaries remain in the asset directory because they are user-supplied/licensed files, but are not registered in `pubspec.yaml`. Compatibility aliases for older call sites now resolve to `ThmanyahSans`.

Responsive role ranges encoded by `AhdashTypography` and `AhdashV9Metrics`:

| Role | Compact–wide range |
|---|---:|
| Display | 30–40 |
| Screen title | 24–30 |
| Hero/question emphasis | 28–36 (question content remains line-aware) |
| Team | 24–32 |
| Score | 34–44 |
| Section | 18–22 |
| Body | 15–17 |
| Button | 15–17 |
| Metadata | 12–14 |

Mixed Arabic/English names and numerical scores must preserve RTL container order while using LTR isolation for score strings.

## Shared foundation

Existing components retained rather than duplicated:

- `BrandScaffold`, `AhdashV7Canvas`, shared accessibility viewport
- `AhdashButton`, `AhdashCard`, `GamePanel`, message/loading/error states
- `AhdashImage` for remote/local media fallback behavior
- `AhdashPictogramView` and the canonical Ahdash pictogram catalog
- `AhdashPlayer11Avatar` and social identity cards

V9.2 primitives created/refined in `measured_v9.dart`:

- `AhdashV9Metrics`, `AhdashV9Frame`, `AhdashV9TopBar`, `AhdashV9IconButton`
- `AhdashV9PrimaryAction`, `AhdashV9SecondaryAction`
- `AhdashV9Surface`, `AhdashV9Input`, `AhdashV9ChoiceChip`, `AhdashV9Tab`
- `AhdashV9TeamIdentity`, `AhdashV9ScoreDisplay`, `AhdashV9TournamentMatchup`

Feature state, routing, validation, repositories, timers, and score authority remain owned by their current feature layers.

## Component states and accessibility

Material state resolution supplies default, pressed, selected, disabled, and focus behavior. Feature-owned loading/error/completed/consumed/unread states should use the existing Ahdash state system during their screen phases. Selection is never communicated by color alone: tabs and chips retain semantic selected state, team identity includes names, and scores have semantic Arabic labels. Reduced Motion remains a real user preference.

## Migration rule

Migrate screen-by-screen after approval. Prefer a V9.2 primitive when it expresses the exact contract; otherwise refine an existing Ahdash component. Do not wrap every old widget solely to change its name, and do not move provider or repository responsibilities into presentation primitives.
