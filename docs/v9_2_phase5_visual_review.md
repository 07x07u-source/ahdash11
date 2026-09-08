# V9.2 Phase 5 — raw visual review

Date: 2026-09-05. Scope: screens 19–27 only, Light mode. **45/45 final raw PNGs opened individually and inspected**, not inferred from a contact sheet or a passing Golden comparison. The active Golden suite also passed 45/45 without update mode after the intentional baseline refresh.

Reference: Figma file `1tbYuMwiC8b9vCj12TzbAA`, handoff nodes Hub `81:2009/2065`, Create `81:2121/2156`, Teams `81:2189/2258`, Draw `81:2313/2360`, Bracket `81:2408/2466`, Match `81:2525/2571`, Champion `81:2617/2643`. Direct retrieved design context/screenshots were used for the seven wide compositions with compact counterparts identified in the map. This is a visual implementation review, not a claim of pixel identity with prototype text/assets.

## Final raw matrix

All files are `mobile/test/visual/goldens/tournament/{state}_{width}x{height}_light.png`.

| Screen/state | 800×360 | 844×390 | 915×412 | 1280×720 | 1366×768 |
|---|---|---|---|---|---|
| 19 hub — real live fixture | reviewed | reviewed | reviewed | reviewed | reviewed |
| 20 create — name step | reviewed | reviewed | reviewed | reviewed | reviewed |
| 21 teams — six eligible teams | reviewed | reviewed | reviewed | reviewed | reviewed |
| 22 draw — pre-commit eligible roster | reviewed | reviewed | reviewed | reviewed | reviewed |
| 23 bracket — early round with BYE | reviewed | reviewed | reviewed | reviewed | reviewed |
| 24 semifinal — embedded round | reviewed | reviewed | reviewed | reviewed | reviewed |
| 25 finalMatch — embedded final | reviewed | reviewed | reviewed | reviewed | reviewed |
| 26 match — ready actual pairing | reviewed | reviewed | reviewed | reviewed | reviewed |
| 27 champion — confirmed final fixture | reviewed | reviewed | reviewed | reviewed | reviewed |

## Findings and intentional changes

- Hub: tournament identity and continuation dominate on the right, next real pairing is secondary on the left; progress excludes automatic byes. No decorative green dashboard wash.
- Create: focused name/rules steps, bounded input and clear primary action. Compact tertiary header copy is removed before shrinking the primary text.
- Teams: full-width numbered rows, real roster counts and readiness, explicit staged-entry message. At 800×360 the last row is partially visible inside the intentional scroll region; the primary action stays visible.
- Draw: approved draw pictogram and event action face a bounded eligible-roster list. Compact lists scroll to remaining entries; they are not a truncated/fake sample. Wide sizes show all six fixture teams.
- Bracket: underline tabs, two real feeder matches and their advancement destination; current/winner treatment is distinct. Early rounds paginate; Semifinal and Final stay in the same screen. Logical next-match/slot relationships are not reversed for RTL.
- Match: real team names, VS, actual round/match metadata, primary Party action and separate external-result action. No ordinary vertical scrolling at standard scale on any target.
- Champion: confirmed real winner and final score, selective gold original pictogram, clear Done/history actions. Reduced compact pictogram and title spacing corrected earlier clipping; the history link was changed from low-contrast inherited lime to Ink. No ordinary vertical scrolling at standard scale.
- Original Thmanyah Sans 400/500/700/900 and required icon fonts are loaded. No Cairo/Serif or prototype data was added to production. Long/mixed Arabic-English names and scale 1.3 were exercised in widget tests separately from these deterministic images.

## Baseline change policy and limits

All 45 Phase 5 Light baselines intentionally replace the legacy Tournament composition. The final follow-up update touched only the five Champion baselines to improve history-link contrast, then the whole Phase 5 suite was compared without update mode. Phase 3/4 baselines were not regenerated and their combined 55 comparisons passed. Historical Dark images were not activated or deleted.

Automated fixtures are not production data. Raw review covers the matrix states above, not every network/error/modal combination. Physical-device screen-reader behavior, native keyboard behavior and pixel-perfect Figma overlay measurement were not tested; no emulator/install/APK was run. Main text and actions are readable in the reviewed renders; subtle decorative gold and hairlines are not used as the only status signal. Owner visual acceptance remains pending.
