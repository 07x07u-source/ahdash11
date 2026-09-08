# AHDASH | 11 - V9 Complete Screen Audit

## Status

This audit is the required pre-implementation gate for V9. No application UI was changed before completing it.

- Source of truth: the 43-screen V8.2 inventory in `tools/build_v8_2_screen_catalog_pdf.py`.
- Evidence: raw Golden PNG files, opened directly at original detail in Light and Dark at 1280x720.
- Compact evidence: raw 844x390 Goldens where they exist.
- Phone-size check: compact Goldens were read at their native logical size; 1280-only screens were also reviewed through reduced-size contact presentation to expose micro-text and weak touch hierarchy.
- Detailed field-by-field records:
  - `docs/v9-screen-audit/screens-01-15.md`
  - `docs/v9-screen-audit/screens-16-29.md`
  - `docs/v9-screen-audit/screens-30-43.md`

Each detailed record includes: SCREEN, PURPOSE, PRIMARY TASK, PRIMARY ACTION, SECONDARY ACTIONS, FIRST VISUAL FOCUS, CURRENT PROBLEMS, EMPTY SPACE, CONTENT SCALE, TYPOGRAPHY, IMAGE SCALE, PICTOGRAM SCALE, UTILITY ICON COUNT, BUTTON SIZE, INPUT SIZE, ALIGNMENT, RTL, LIGHT MODE, DARK MODE, RESPONSIVE QUALITY, GAME FEEL, LEGACY DNA, DENSITY, and DECISION.

## Audit caveat: hollow-square utility glyphs

Several V8.2 checkpoint images show Cupertino utility glyphs as empty squares. The app declares `cupertino_icons`, and the other visual harnesses explicitly load `packages/cupertino_icons/CupertinoIcons`. `v8_2_checkpoint_golden_test.dart` loads Material Icons but omits the Cupertino font. Therefore these squares are at least partly a validation-harness defect. V9 must load the correct font and regenerate the affected Goldens before judging icon shape or production behavior.

## Global findings

1. Important content is often compact-sized inside a 1280x720 canvas. The dominant problem is composition, not missing decoration.
2. Repeated max-width constraints, master-detail rails, equal cards, long bordered panels, and `VisualDensity.compact` preserve web/dashboard DNA.
3. Auth remains visually split even with a full-bleed image. Home remains a sports hero rather than a game launcher.
4. Party setup loses energy through small inputs, remote CTAs, repeated category art, and weak score/state hierarchy.
5. Tournament progression is not yet expressed as a true RTL bracket. Semifinal and Final are duplicate Bracket states, not routes.
6. Light mode is frequently Paper-on-Paper with little tonal hierarchy. Dark mode is frequently one near-black sheet.
7. Many secondary actions, tabs, segmented controls, and compact CTAs visually fall below 44 logical pixels.
8. Compact proof is incomplete: most non-checkpoint screens have no 844x390 Golden. Team Challenge is captured at 1280x760 rather than the required 1280x720.
9. Custom Ahdash pictograms are a strong retained asset. Generic utility icons should remain sparse and receive guaranteed 48px targets.
10. No new product feature is needed to solve these screens. The work is hierarchy, scale, grouping, crop, state, and responsive prioritization.

## Screen decisions

| # | Screen | Purpose / primary task | Main evidence and first-focus failure | Density | Decision |
|---:|---|---|---|---|---|
| 01 | Launch | Brand recognition while routing | Small logo unit in 85%+ unstructured space; duplicate micro-mark | FOCUS | REBUILD |
| 02 | Onboarding | Explain the Party loop and start | Pictogram list competes with an empty visual panel; CTA is remote | MEDIUM | REBUILD; REMOVE only if product confirms onboarding is obsolete |
| 03 | Sign in | Authenticate or enter as guest | Football art wins over the task; fixed image/form split remains | FOCUS | REBUILD |
| 04 | Create account | Create the minimum account | Sign-in clone with one field; compact primary/guest actions under-scaled | FOCUS | REBUILD |
| 05 | Home | Start Party; create tournament; resume real state | Ball/website header and resume strip beat Start Game | MEDIUM | REBUILD |
| 06 | Party categories | Select six recognizable categories | Repeated art, four small columns, micro filters and detached Next | DENSE | RECOMPOSE |
| 07 | Category detail | Understand category and try a question | Tall image, content, and CTA form three disconnected zones | FOCUS | RECOMPOSE |
| 08 | Team setup | Name Team A/B and continue | Correct VS skeleton, but tiny form clusters float in huge halves | MEDIUM | RECOMPOSE |
| 09 | Team splitter | Enter players, split, inspect result | Mixed before/after states, ghost 01/02, tiny text, extreme dead space | MEDIUM | REBUILD |
| 10 | Helpers | Select three helpers per team | Strong pictograms; description strip too wide and remote | MEDIUM | REFINE |
| 11 | Ready | Confirm setup and start | Matchup is correct focus, but categories/meta/Start remain footer-scale | MEDIUM | RECOMPOSE |
| 12 | Board | Choose an available 6x6 point cell | Grid is efficient but spreadsheet-like; scores/turn are too weak | DENSE | REFINE |
| 13 | Text question | Read, answer, reveal | Strong question; state and actions are fragmented into corners | FOCUS | REFINE |
| 14 | Image question | Inspect media, answer, reveal | Rigid split; invalid repeated cover image; question shrinks | FOCUS | REBUILD |
| 15 | Answer reveal | Read answer and award points | Strong answer, disconnected 36px award controls across the width | FOCUS | RECOMPOSE |
| 16 | Final result | Announce winner and choose next step | Correct win focus; action closure and score hierarchy are fragmented | FOCUS | REFINE |
| 17 | How to play | Teach four gameplay steps | Documentation diagram, duplicate pictograms, tiny step details | MEDIUM | REBUILD |
| 18 | Saved games | Resume a real saved session | One micro row suspended in a large empty canvas | DENSE/LIST | RECOMPOSE |
| 19 | Tournament hub | Continue an active tournament | Title/pictogram beat tiny round, progress, next match and CTA state | MEDIUM | REBUILD |
| 20 | Create tournament | Complete a focused setup step | One field and thin CTA in 60%+ dead space; Dark pictogram contrast failure | FOCUS/STEP | REBUILD |
| 21 | Tournament teams | Review participants and continue | Administrative bordered cards with small identity and repeated checks | DENSE/LIST | REBUILD |
| 22 | Tournament draw | Confirm readiness and run the draw | Core composition and custom pictogram work; event states need weight | FOCUS/MEDIUM | REFINE |
| 23 | Tournament bracket | Understand rounds and open active match | Boxes do not form a bracket; no RTL convergence or winner path | DENSE | REBUILD |
| 24 | Tournament semifinal | Show semifinal round | Same Bracket screen/state; extreme empty space; no standalone route | ROUND STATE | MERGE into Bracket |
| 25 | Tournament final | Show final round | Same Bracket state; one tiny card; no standalone route | ROUND STATE | MERGE into Bracket |
| 26 | Tournament match | Start or record a tournament match | Readable matchup, but under-scaled with a 40px compact CTA | FOCUS | RECOMPOSE |
| 27 | Champion | Celebrate and close/share tournament | Strong gold pictogram; title/score/actions do not form one victory unit | FOCUS | RECOMPOSE |
| 28 | Match setup | Choose format after game type | Four equal empty cards; action sits under the wrong visual column | MEDIUM | MERGE selection into Play; retain compatibility route during transition |
| 29 | Solo setup | Configure a real solo challenge | Required function, but categories/settings form a separate dashboard system | MEDIUM | MERGE category intent, then REBUILD with Party language |
| 30 | Online lobby | Choose matchmaking/room path and become ready | Multiple competing paths, blank panels, small state/actions | MEDIUM | REBUILD |
| 31 | Online match | Answer a live question | Functional but a second visual system with giant empty answer surfaces | FOCUS | MERGE visually with Party Question shell |
| 32 | Private room | Share code, see players, ready/start | Table-like players and code panels; readiness is footer-scale | MEDIUM | REBUILD |
| 33 | Team challenge | Answer a team challenge | Good question scale, but hard split, line-only answers and 1280x760 fixture | FOCUS | REBUILD on shared Question shell |
| 34 | Ranking | Read Top 3 and the ranked list | Good podium direction; avatars small, rows huge, thin desktop rail | DENSE | RECOMPOSE |
| 35 | Friends | Search/add or manage friend states | Giant bordered empty panel around a small pictogram/copy group | DENSE/FOCUS | REBUILD empty and data states |
| 36 | Blocked players | Review and unblock players | Useful privacy function presented as a sparse standalone destination | LIST | MOVE under Settings > Privacy; keep route/backend compatibility |
| 37 | Team detail | Read team identity and manage members/games/activity | Three-column dashboard, decorative green block, 8+ utilities | DENSE | REBUILD with identity header + tabs |
| 38 | Profile | Read Player11 identity and real stats | Identity is improved; hero remains website-like and actions under 44px | MEDIUM | REFINE |
| 39 | Notifications | Read notification states / empty state | Correct branded empty unit, but too small wide and top utilities are noisy | DENSE/FOCUS | REFINE |
| 40 | Settings | Change implemented preferences | Desktop rail/master-detail, weak grouping, Privacy misplaced | MEDIUM | REBUILD as real grouped settings |
| 41 | Report problem | Choose type, describe, submit | Focused width is now correct; labels/footer/short-height behavior need work | FOCUS | RECOMPOSE |
| 42 | Football preferences | Choose league, then club, then save | Master-detail control panel and empty pane; no visual club grid state | MEDIUM/DENSE | REBUILD as two visual steps |
| 43 | Premium | Understand value, choose real plan, subscribe/restore | Strong headline/pictogram; commerce hierarchy and 36px CTA are weak | MEDIUM | RECOMPOSE |

## Route and legacy decisions

### Confirmed

- Tournament Semifinal and Tournament Final are not independent routes. They are `TournamentBracketScreen` round states. Merge them into the rebuilt Bracket and remove their standalone catalog treatment. Preserve tournament state and match data.
- `BlockedPlayersScreen` is reached only from Settings in the current UI. Move it under Privacy while preserving its route, provider, repository and backend operations for compatibility.
- Solo configuration is real and must remain. Merge incoming category intent and reuse Party visual language; do not remove its controller or routes before a complete replacement flow exists.
- Match format branching is real. Integrate it into Play if the merged flow remains clear, but keep `/play/setup/:gameType` as a compatibility/deep-link route during transition.

### Live routes absent from the 43-screen source catalog

The router also exposes live product surfaces not represented as independent items in the V8.2 43-screen catalog, including `/play`, `/categories`, `/solo/match`, `/solo/result`, and `/teams`. They must not be removed or redesigned based on inference alone.

**UNCERTAIN - NOT IMPLEMENTED:** Their final merge/removal decisions are deferred until raw V9 Goldens are added and their production entry paths are reviewed. The first checkpoint will not invent behavior to fill this catalog gap.

## First checkpoint scope

The first V9 implementation checkpoint is limited to these 18 key screens/states:

1. Launch
2. Sign in
3. Create account
4. Home
5. Category selection
6. Team setup
7. Ready
8. Board
9. Text question
10. Final result
11. Tournament hub
12. Tournament bracket
13. Tournament match
14. Champion
15. Profile
16. Settings
17. Football preferences
18. Premium

No second-wave screen is approved for random polishing before this checkpoint passes its visual score gate.

