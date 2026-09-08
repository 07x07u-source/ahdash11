# AHDASH | 11 - V9 Measurement and Composition Plan

## Principle

Important things must feel important. V9 will not solve empty screens with more cards, icons, fake data, or decorative features. It will solve them through scale, grouping, crop, alignment, state and responsive prioritization.

## Spacing and layout tokens

All values are logical pixels and follow a 4px base grid.

| Token | Value |
|---|---:|
| Space 1 | 4 |
| Space 2 | 8 |
| Space 3 | 12 |
| Space 4 | 16 |
| Space 5 | 20 |
| Space 6 | 24 |
| Space 7 | 32 |
| Space 8 | 40 |
| Space 9 | 48 |
| Space 10 | 64 |

Adaptive page gutters:

| Viewport width | Horizontal gutter | Vertical inset |
|---|---:|---:|
| 800-915 | 20-24 | 8-12 |
| 916-1199 | 24-32 | 12 |
| 1200-1366+ | 32-40 | 16 |

Constraints remain task-specific:

- Auth floating content: 360-430 wide.
- Focused support/form column: 480-620 wide.
- Core game stage: up to 1120 wide; do not constrain a 6x6 board to a desktop-form width.
- Lists and event stages: 960-1120 when the data benefits from width.
- Negative space is allowed only after the primary unit reaches the intended optical scale.

## Typography hierarchy

| Role | Compact | Standard | Wide |
|---|---:|---:|---:|
| Display | 30 | 36 | 40 |
| Screen title | 24 | 28 | 30 |
| Major hero | 28 | 32 | 36 |
| Short question | 28 | 30 | 32 |
| Long question | 24 | 26 | 28 |
| Team name | 24 | 28 | 32 |
| Score / VS | 34 | 40 | 44 |
| Section | 18 | 20 | 22 |
| Body | 15 | 16 | 17 |
| Button | 15 | 16 | 18 |
| Metadata | 12 | 13 | 14 |

Arabic rules:

- Primary Arabic text never drops below the intended phone-readable tier.
- Tertiary descriptions are removed before primary text is shrunk on low-height layouts.
- Mixed Latin/Arabic identifiers use stable baselines and tabular figures where relevant.
- Question type is line-count aware, not viewport-scale-only.

## Controls and touch

| Control | Compact | Standard / wide |
|---|---:|---:|
| Primary action | 48 | 52-54 |
| Secondary action | 46-48 | 48-50 |
| Text input | 48 | 52-54 |
| Settings/list row | 48 | 52-56 |
| Segmented/tab target | 44 | 44-48 |
| Utility icon target | 48 | 48 |
| Utility glyph | 20 | 20-22 |
| Interactive chip/filter | 40 minimum | 44 preferred |

Labels remain visible. Placeholders are hints, never the only label. A visible 18-22px glyph still receives a 44-48px target.

## Radius system

| Role | Radius |
|---|---:|
| Hairline/subtle element | 6 |
| Interactive surface/control | 10 |
| Raised content group | 14 |
| Hero/media crop | 16 |
| Pill/status only | 999 |

Radius does not create hierarchy. Most sections should use alignment, spacing and a separator rather than another card.

## Surface hierarchy

### Light

| Role | Color |
|---|---|
| Canvas / Paper 0 | `#FBF7EF` |
| Subtle Surface / Paper 1 | `#F4EBDD` |
| Raised Surface / Paper 2 | `#EBDFC9` |
| Interactive Surface | `#F7F0E3` |
| Selected Surface | `#E9F5CF` |
| Primary text | `#191714` |
| Muted text | `#756E63` |

### Dark

| Role | Color |
|---|---|
| Canvas | `#171613` |
| Subtle Surface | `#211F1B` |
| Raised Surface | `#292620` |
| Interactive Surface | `#342F28` |
| Selected Surface | `#303821` |
| Primary text | `#F4EBDD` |
| Muted text | `#AAA091` |

Green is reserved for active, selected, primary game action and success. Gold is reserved for winner, champion, Premium and special achievement. Dark remains warm-neutral, not blue-black.

## Pictogram scale

| Role | Range |
|---|---:|
| Inline | 32-40 |
| Helper | 52-68 |
| Small feature | 64-80 |
| Empty state | 80-104 |
| Result | 104-136 |
| Tournament draw | 104-136 |
| Premium | 96-120 |
| Champion | 128-160 |

Pictograms always belong to a content unit: pictogram + title + supporting state/action. No large icon is placed alone to occupy empty space.

## Motion and feedback

| Moment | Duration |
|---|---:|
| Press / micro feedback | 120ms |
| Selection change | 180-200ms |
| Standard entrance | 240-300ms |
| Reveal / draw | 360-420ms |
| Win / champion | 500-560ms |
| Launch identity | 400-700ms total |

- 1-3 meaningful moments per normal screen.
- No decorative loops.
- Respect reduced motion.
- Haptics/audio only for selection, score, draw, win and critical state, and only when preferences permit.

## Density classes

- FOCUS: Auth, Question, Reveal, Result, Tournament Match, Champion. One dominant unit, minimal tertiary content.
- MEDIUM: Home, Team Setup, Helpers, Ready, Profile, Settings, Premium. One primary unit plus one clear supporting layer.
- DENSE: Categories, Board, Ranking and lists. Higher information density with strong grouping, readable rows and fewer full borders.

## Responsive contract

Required validation sizes:

- 800x360
- 844x390
- 915x412
- 1280x720
- 1366x768

When height becomes scarce, remove or defer description, decorative media and tertiary metadata before shrinking the question, team names, score or CTA. Ready, Board, Question, Reveal, Result and Tournament Match must fit normal play without vertical scrolling.

## Composition plan for the 18-screen checkpoint

| Screen | Approved V9 composition |
|---|---|
| Launch | One canonical logo/11 unit at meaningful scale; subtle 400-700ms identity reveal; remove duplicate micro-mark and decorative split frame. |
| Sign in | One continuous full-bleed scene. A 360-430px auth stack floats in intentional negative space; logo, headline, short line, inputs, dominant sign-in, create-account and guest/social hierarchy. No visual 50/50 split. |
| Create account | Same world, registration-specific anchor and only player name/email/password. No football preferences. Compact keeps 48px inputs/actions. |
| Home | One game-launch composition integrated with image depth. Start Game is dominant, Create Tournament secondary, Resume appears only with real state, and tertiary destinations are discreet. |
| Category selection | Fewer readable columns, differentiated covers/fallbacks, larger titles, controlled filters, visible selection progress and one connected Next action. |
| Team setup | Team A - VS - Team B owns the screen. Names become identity; inputs integrate into the matchup; colors and splitter are secondary; Next remains attached to the flow. |
| Ready | Large matchup plus compact categories/helpers summary and one decisive Start CTA. Remove footer-like micro information. |
| Board | Preserve 6x6 rules. Build a true scoreboard with strong team scores/turn, visual category headers, larger point hierarchy, reduced grid borders and unmistakable consumed state. |
| Text question | Preserve the strong focus, increase line-aware question range, consolidate state, helpers, report and Reveal into a coherent secondary band. |
| Final result | Pictogram, winner name and score form one emotional unit; next actions become one clear primary plus secondary group. |
| Tournament hub | Active event composition: tournament identity, current round/progress, next match and Continue dominate; Create New is secondary. |
| Tournament bracket | True RTL convergence with connecting paths, round progression, active/winner path, clear match states and a round-focused compact mode. Semifinal/final remain states, not pages. |
| Tournament match | Team A - VS/score - Team B fills the center; round metadata secondary; primary CTA 48-54; meaningful team identity rather than duplicated decoration. |
| Champion | Tournament title, gold pictogram, champion, final score and Share/Done form one victory unit. Use gold only here. |
| Profile | Keep the improved direction. Make Player11 identity stronger than the environment, tighten the stat/story relationship and lift actions to compliant targets. |
| Settings | Replace the desktop rail with implemented groups and 48-56px rows. Move blocked players into Privacy while retaining compatibility. |
| Football preferences | Two visual steps: choose league, then choose club via badge grid + search. Avoid an empty detail pane and footer control pile. |
| Premium | Premium pictogram, value, real localized plans/prices when available, 48-54px CTA, benefits and Restore. No fake price and no icon per benefit. |

## Validation gate

The checkpoint must render all 18 screens in Light and Dark at 844x390 and 1280x720, with the raw PNGs opened directly. The V9 harness must load Material, Thmanyah and Cupertino fonts. Score each screen on Hierarchy, Balance, Typography, Spacing, Images, Pictograms, Touch, RTL, Brand and Game Feel. Any critical category below 4/5 blocks continuation.

## Uncertain - not implemented

- Final removal/merge decisions for live routes absent from the 43-screen catalog.
- New category editorial assets where no approved real image exists.
- New stats, badges, achievements, online presence or progress data.
- Any database, Supabase or backend change.
- Any animation beyond the approved static composition until the checkpoint passes.
