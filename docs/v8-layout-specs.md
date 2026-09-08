# AHDASH 11 - V8 Measurement System and Layout Specs

Status: design specification only; no implementation has started.  
Coordinate system: logical pixels, origin at the viewport top-left, RTL first.  
Reference viewports: 844x390 and 1280x720. Stress viewports: 800x360, 915x412 and 1366x768.

## 1. V8 design measurements

### Spacing

Base unit: 4.

| Token | Value | Use |
|---|---:|---|
| `space-1` | 4 | Optical/internal micro gap only |
| `space-2` | 8 | Icon-label, compact vertical gap |
| `space-3` | 12 | Related controls |
| `space-4` | 16 | Default component padding |
| `space-5` | 20 | Compact page gutter |
| `space-6` | 24 | Standard page gutter / section gap |
| `space-8` | 32 | Wide page gutter / major section gap |
| `space-10` | 40 | Extra-wide gutter / hero separation |
| `space-12` | 48 | Major composition separation only |

No new 13, 19, 27 or 37 values. Optical exceptions must be documented at the component.

### Responsive frame

| Constraint | Horizontal gutter | Vertical inset | Top bar | Content max width |
|---|---:|---:|---:|---:|
| width < 850 or height <= 390 | 20 | 8 | 48 | 804 at 844 |
| width 850-1179 | 24 | 12 | 48 | available width - 48 |
| width 1180-1365 | 32 | 16 | 52 | 1216 at 1280 |
| width >= 1366 | 40 | 16 | 52 | 1286 at 1366, hard max 1366 |

Reference usable frames:

- 844x390: `x=20, y=8, w=804, h=374`; body after top bar and 4 gap: `x=20, y=60, w=804, h=322`.
- 1280x720: `x=32, y=16, w=1216, h=688`; body after top bar and 8 gap: `x=32, y=76, w=1216, h=628`.

### Core component sizing

| Component | Compact | Standard/wide |
|---|---:|---:|
| Primary button | 48 high | 52 high |
| Secondary button | 44-48 high | 48 high |
| Text input | 48 high | 52 high |
| Icon glyph | 20 default, 24 emphasis | 20 default, 24 emphasis |
| Icon hit target | 44 minimum, 48 preferred | 48 |
| Segmented/tab target | 44 high | 48 high |
| List row | 52 minimum | 56-60 |
| Avatar | 72 identity / 48 list | 104-128 identity / 52 list |
| Small radius | 8 | 8 |
| Medium radius | 12 | 12 |
| Large media radius | 16 | 16 |
| Pill | status/filter only | status/filter only |

### Typography

| Role | Compact | Wide | Max lines |
|---|---:|---:|---:|
| Display/hero | 28-32 | 38-44 | 2 |
| Screen title | 22-24 | 28-32 | 1 |
| Section title | 18-20 | 20-24 | 1-2 |
| Game question | 24-30 | 30-38 | 4 |
| Answer option | 15-17 | 16-18 | 2, adaptive layout after that |
| Body | 14-15 | 15-16 | defined per component |
| Metadata | 11-12 | 12-13 | 1 |
| Button | 15-16 | 16-17 | 1 |
| Score | 26-32 | 36-48 | 1, tabular figures |

Important Arabic copy is never silently clipped. Ellipsis is allowed only for secondary metadata, category titles after two lines and identifiers in dense lists.

### Surface and divider policy

- One continuous page canvas by default.
- Surfaces communicate interaction/state, not empty space.
- Dividers are limited to list separation and bracket connections.
- No whole-page dashboard grid.
- One primary focal point per screen.

### Motion

- Input acknowledgement: 120 ms.
- Standard state change: 200 ms.
- Emphasized entrance/reveal: 300 ms.
- Celebration: 520 ms maximum.
- Image fade: 180 ms.
- No continuous decorative loops. Reduced-motion mode removes transforms and uses direct fades/state changes.

## 2. Primary screen layout specs

Bounds are `x, y, width, height`. Image bounds are omitted when no image has a verified task.

### 2.1 Sign In

Primary focus: fastest valid entry method plus Ahdash identity. Full-bleed image is the canvas, not a separate half-panel.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Full-bleed image `0,0,844,390`; directional scrim from x=344 to 844. Auth zone `424,44,380,302`, max form width 380. Logo/headline overlay `28,238,348,104`, secondary and decorative copy removed. Inputs 48 high, 8 gaps. Primary/guest row `424,256,380,48`; provider row appears only when configured and replaces secondary prose rather than shrinking controls. |
| 1280x720 | Full-bleed image `0,0,1280,720`; focal image safe zone `0,0,760,720`; auth zone `790,88,420,544`, max width 420. Logo/story `72,176,520,250`, max text width 460. Inputs 52 high, 12 gaps. Primary CTA `790,438,420,52`; guest/social actions below with 48 targets. |

Image: admin/fallback login artwork only, `BoxFit.cover`, directional focal point away from the auth zone, dark/light scrim independently tuned. Network error uses the existing local artwork with no layout shift.

### 2.2 Create Account

Primary focus: create account with only supported fields: username, email, password.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Same full-bleed canvas as Sign In. Form zone `404,32,400,326`; three 48-high inputs in one vertical stack with 8 gaps. Primary CTA `404,232,400,48`; return/guest row `404,288,400,48`. Story is reduced to logo only at `28,28,180,40`. Error region may grow to 40 high and pushes secondary actions, never ellipsizes a critical error. |
| 1280x720 | Form zone `780,72,430,576`; title block 72 high; three 52-high inputs with 12 gaps; inline error up to 56; primary CTA `780,430,430,52`; return and guest actions below. Image safe zone `0,0,740,720`. |

No phone, DOB, city, gender, club or league. No forgot-password or email-sent UI until the open decisions are resolved.

### 2.3 Home

Primary focus: Start Game. Create Tournament is the only co-primary destination; content is contextual and secondary.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Frame `20,8,804,374`. Minimal top bar `20,8,804,44`. Visual zone `20,60,372,282`. Primary launcher zone `420,60,404,282`: optional active-session row `420,60,404,48`; logo/copy `420,116,404,92`; Start Game `420,216,256,48`; Tournament `684,216,140,48`; no thumbnail rail. |
| 1280x720 | Frame `32,16,1216,688`. Top bar `32,16,1216,52`. Football visual `32,92,620,556`. Launcher `704,116,500,420`: logo `704,116,220,52`; headline `704,184,500,108`; Start Game `704,316,320,52`; Create Tournament `1036,316,168,52`. Context rail maximum three real items `704,548,500,104`; hidden if data is absent. |

Image: one rights-cleared Ahdash football atmosphere, not article thumbnails. Motion: logo, primary CTA and one image reveal only.

### 2.4 Party Category Selection

Primary focus: selected count and scannable category choice.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`. Status/search row `20,60,804,48`: counter 88, search 260, random 144, remaining space team instruction. Filter rail `20,112,804,40`, horizontally scrollable with 44 hit targets. Category viewport `20,156,804,166`, three tiles at 256x166 with 12 gaps. Selected tray/CTA `20,330,804,52`; CTA width 168, selected slots use remaining width. |
| 1280x720 | Top bar `32,16,1216,52`. Status/search `32,76,1216,52`; filters `32,136,1216,44`. Category grid `32,192,1216,420`, four columns, tile width 295, two visible rows, 12 gaps. Selected tray/CTA `32,620,1216,68`; CTA `1024,628,192,52`. |

Tile requirements: cover recognition, two-line title, favourite target 48, selected number and team colour. Unique media is data/admin responsibility; fallback remains neutral and category-labelled.

### 2.5 Team Setup

Primary focus: Team A - VS - Team B.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`. Matchup `20,72,804,222`: Team A `20,72,338,222`, VS `370,128,104,96`, Team B `486,72,338,222`. Name input 48 high; colour row 48 hit targets but only 24 visible swatches. Footer `20,306,804,76`; random split at start, primary CTA `628,330,196,48`. |
| 1280x720 | Top bar `32,16,1216,52`. Matchup `104,136,1072,400`: Team panels 430x400, VS 140x160 centred. Name input 52; optional member preview only from real current state. Footer CTA `928,580,248,52`; random split `104,584,180,48`. |

No empty horizontal team lanes. Team colour is secondary to visible/editable name.

### 2.6 Helpers

Primary focus: five understandable helper controls and the active helper description.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`; team switch `20,60,804,44`; helper rail `20,112,804,84` with five 72 visual controls and 48 minimum hit targets; detail area `20,204,804,94`; footer count `20,306,220,48`, CTA `628,330,196,48`. |
| 1280x720 | Top bar `32,16,1216,52`; team switch `284,88,712,48`; helper rail `152,168,976,116` with five 88 visual controls; selected helper detail `248,308,784,148`; footer CTA `928,580,248,52`, count/instruction aligned opposite. |

One helper expands; five separate large cards are forbidden. Selection count remains explicit for both teams.

### 2.7 Ready

Primary focus: match introduction and confidence before starting.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`; matchup `80,84,684,126`; category strip `20,222,804,48`; helper indicators `180,282,484,36`; Start CTA `628,330,196,48`. Secondary copy removed. |
| 1280x720 | Top bar `32,16,1216,52`; matchup `220,136,840,248`; category strip `136,416,1008,72`; helpers `296,508,688,48`; Start CTA `516,580,248,52`. |

Team names, VS and real selected configuration only. No giant blank canvas.

### 2.8 Party Board

Primary focus: score/turn and the 6x6 question board.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Score/turn bar `20,8,804,48`; grid `20,60,804,322`. Six columns, each 132-134 wide. Category header 48 high. Six value cells 44 high with 2 gaps. Values 18-20; category 12-14. Helper/exit actions live inside score bar as 48 targets. |
| 1280x720 | Score/turn bar `32,16,1216,76`; grid `32,108,1216,580`. Six columns ~198 wide with 8 gaps. Header 92 high. Value cells 72 high with 4 gaps. Values 24-28; category 16-18. |

Use scoreboard hierarchy: team name/score strongest, current turn next, category art/name next, then values. Borders only separate actionable cells; selected/used states cannot rely on colour alone.

### 2.9 Party Question

Primary focus: question text.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Status bar `20,8,804,48`; question bounds `88,72,668,94`, max text width 668; media when present `20,72,260,170` and question shifts to `304,72,520,94`; answer area `72,182,700,116`; footer controls `20,330,804,48`. |
| 1280x720 | Status bar `32,16,1216,60`; question `220,124,840,172`, max text width 760 centred; media when present `88,108,420,300`, question/answers `556,108,636,420`; answer area without media `220,328,840,220`; footer `32,620,1216,52`. |

Short options may use 2x2; long options switch to one column/two rows. Glyph 20-24, hit target 48. Timer and helpers remain visible but cannot compete with the question.

### 2.10 Answer Reveal

Primary focus: correct answer, explanation and score assignment as one state.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Score bar `20,8,804,48`; reveal group `116,80,612,178`: answer 52, explanation up to 72, points 24. Assignment controls `144,270,556,48`; next-state/footer `20,330,804,48`. |
| 1280x720 | Score bar `32,16,1216,60`; reveal group `260,132,760,300`; answer 72, explanation up to 112, points 32. Assignment controls `312,456,656,52`; next-state footer `32,620,1216,52`. |

No isolated answer floating above distant buttons. Team buttons use team colour plus label/icon/state.

### 2.11 Party Result

Primary focus: winner and final score.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Header `20,8,804,44`; celebration group `132,68,580,206`; restrained visual 72x72, winner 32, score 30. Actions `252,302,340,48` for rematch/new game; home as 48 icon target. |
| 1280x720 | Header `32,16,1216,52`; celebration group `300,116,680,396`; visual 120x120, winner 42, score 40. Actions `380,548,520,52`; no stats dashboard. |

Celebration motion 520 ms max and disabled by reduced motion.

### 2.12 Profile

Primary focus: player identity, not environmental artwork.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`; identity `20,64,804,126`: avatar 80, name max width 320, club/league badge and Premium state. Verified stat strip `20,202,804,52`. Tab/content area `20,266,804,116`; only one visible content row at compact. Background accent may occupy at most left 38% with low contrast. |
| 1280x720 | Top bar `32,16,1216,52`; identity `80,100,1120,228`: avatar 128, name block max 480, football identity and Premium adjacent. Stat strip `160,352,960,64`. Tabs `160,436,960,48`; content `160,496,960,176`. Background art limited to `32,76,480,596` and cannot reduce identity contrast. |

Verified stat strip: matches, wins, tournaments played, tournaments won (or accuracy only if product chooses it). No fake activity feed.

### 2.13 Settings

Primary focus: clearly grouped implemented settings with 48 targets.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`; category rail `20,64,168,318` with 48-high rows; active group list `204,64,620,318`, row height 52. Account identity is the first Account row, not a floating centre element. Destructive actions remain at the list end and use text plus icon. |
| 1280x720 | Top bar `32,16,1216,52`; category rail `176,92,224,596`; group list `432,92,672,596`, row height 56-60, max list width 672. Optional help description uses the remaining margin, not another panel. |

Categories appear only when implemented: account, game, sound/haptics, appearance, notifications, privacy/help. Cupertino semantic icons, 20-22 glyph, 48 hit target.

### 2.14 Premium

Primary focus: real value and real store plan/action.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`; value statement `424,72,400,82`; benefit rail `20,72,380,188` with verified benefits only; purchase state `424,166,400,164`; subscribe/disabled action `424,330,400,48`. Restore is a 48 target in top bar. |
| 1280x720 | Top bar `32,16,1216,52`; value/benefits `96,112,500,468`; purchase panel `688,132,456,420`; plan controls 56 high, primary CTA 52, legal/store copy max width 456. Decorative gold mark may occupy <15% visual weight. |

Prices and savings derive only from store plan data. When plans are unavailable, show a proportionate status with retry/restore only if supported; never display an invented price.

### 2.15 Tournament Hub

Primary focus: live tournament state or clear create action.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`; active tournament `84,76,676,206`: name, round, progress, next match. Continue CTA `588,294,236,48`; create secondary `20,294,180,48`. If no tournament, one empty-state group `174,92,496,190` plus create CTA. |
| 1280x720 | Top bar `32,16,1216,52`; live state `152,116,976,392`; progress rail 72 high; next-match line 96 high; Continue `832,544,296,52`; Create `152,548,220,48`. |

All displayed values come from `Tournament.status`, teams and matches. No fake audience/activity.

### 2.16 Create Tournament Wizard

Primary focus: one supported decision per step.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`; compact progress `20,60,804,32`; current step form `192,104,460,180`; navigation `192,306,460,48`. Only the active step is visible. Inputs 48. |
| 1280x720 | Top bar `32,16,1216,52`; step rail `144,108,212,520`; current step `404,116,520,420`; contextual review `956,116,180,420` only when backed by current draft; navigation `404,560,520,52`. Inputs 52. |

Supported steps: name; teams; rules (capacity, players/team, visibility, timer, helpers/tiebreaker); categories; draw; review. Seeding appears only where the current engine supports it. Captain is excluded.

### 2.17 Tournament Draw

Primary focus: `سو القرعة` and revealed pairs.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`; prepared-team rail `20,72,804,72`; draw action `292,158,260,64`; result pairs `60,238,724,92`; footer `20,334,804,48`. During draw, the action area uses one 300 ms controlled reveal, no loop. |
| 1280x720 | Top bar `32,16,1216,52`; prepared teams `136,116,1008,112`; draw focal action `436,252,408,88`; revealed pairs `176,372,928,180`; continue `928,580,216,52`. |

Before draw, show only real prepared teams. After draw, use clear paired relationships, not plain administration rows.

### 2.18 Tournament Bracket

Primary focus: current round and winner progression.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`; round tabs `20,60,804,44`; current-round bracket `40,116,764,214`; footer action `588,334,236,48`. Two match nodes per row, 56 high, with visible progression line/next slot. Horizontal swipe changes round only when more rounds exist. |
| 1280x720 | Top bar `32,16,1216,52`; round tabs `160,88,960,48`; bracket stage `96,156,1088,444`; 2-4 round columns according to capacity, node 220x64, connectors 2 px; current round has primary contrast. Match action `928,620,256,52`. |

The mobile default is current-round focus. Do not fit a 64-team desktop bracket into 844x390.

### 2.19 Tournament Match

Primary focus: the two competing teams.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Top bar `20,8,804,48`; round/match metadata `232,64,380,32`; competition axis `72,108,700,142`: Team A 254 wide, VS/score 160, Team B 254. Rules/status `172,262,500,40`; primary CTA `304,322,236,52`; manual-result secondary is text/48 target only when supported. |
| 1280x720 | Top bar `32,16,1216,52`; metadata `388,92,504,40`; competition `164,156,952,300`: Team panels 360, centre score/VS 200. Status `340,480,600,44`; primary CTA `484,552,312,52`; secondary result action `820,554,220,48`. |

No three boxes. Team names 28/38, VS or real score 48/72, all tabular scoring. Competition remains the hero in empty/ready/live/completed states.

### 2.20 Champion

Primary focus: real champion and tournament conclusion.

| Viewport | Composition and exact bounds |
|---|---|
| 844x390 | Brand/tournament line `20,16,804,44`; celebration `132,72,580,218`: trophy 72, champion name 36, final score 26. Done CTA `588,330,236,48`; share is absent until approved. |
| 1280x720 | Brand/tournament line `32,24,1216,52`; celebration `280,112,720,420`: trophy 128, champion 48, final score 36, short tournament label. Done CTA `500,564,280,52`. |

Gold is limited to trophy, key rule and CTA edge. No giant watermark shapes. Celebration motion uses one 520 ms entrance and respects reduced motion.

## 3. Adaptive rules for stress sizes

### 800x360

- Horizontal gutter stays 20; vertical inset becomes 4 only if safe area permits.
- Remove secondary copy and tertiary metadata before reducing headline/question/team/score.
- Primary controls stay >=44 high; icons remain >=18 with >=44 hit target.
- Category grid shows three tiles; filters scroll horizontally.
- Board retains 44-high value targets by reducing gaps to 0-2 and header to 44.

### 915x412

- Horizontal gutter 24, vertical 8.
- Use compact composition with modestly increased text width; do not switch to wide multi-panel structures solely from width.
- Auth remains overlay-based; Home may show one contextual item.

### 1366x768

- Horizontal gutter 40, vertical 16; hard content max 1286.
- Forms remain capped at 340-460 and readable text at 560-760.
- Extra width goes to intentional visual balance, not stretched inputs or giant gaps.

## 4. Accessibility and state requirements

- Every interactive control: semantic label, 44 minimum effective target, 48 preferred.
- Back/forward chevrons use directional icons and mirror correctly in RTL.
- Mixed Arabic/English fields keep Arabic layout while email/password/code values use LTR where needed.
- Text scale up to 1.28 stays in the primary composition; above that, existing accessibility fallback may scroll rather than clip.
- Loading keeps stable geometry; no full-screen spinner for a partial fetch.
- Errors stay adjacent to the affected control/region and never expose raw Supabase/provider details.
- Empty states scale to the viewport: icon/visual, headline, one sentence and only an evidence-backed CTA.
- Dark mode uses semantic surface/text roles; no default Material blue/purple is allowed.
