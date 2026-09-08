# AHDASH 11 V9.2 — Phase 4 raw visual review

Review status: **25/25 raw Light renders opened and reviewed** after the final intentional baseline generation.

## Matrix

| Screen | 800×360 | 844×390 | 915×412 | 1280×720 | 1366×768 |
|---|---:|---:|---:|---:|---:|
| 12 Game Board | reviewed | reviewed | reviewed | reviewed | reviewed |
| 13 Text Question | reviewed | reviewed | reviewed | reviewed | reviewed |
| 14 Image Question | reviewed | reviewed | reviewed | reviewed | reviewed |
| 15 Answer Reveal | reviewed | reviewed | reviewed | reviewed | reviewed |
| 16 Final Result | reviewed | reviewed | reviewed | reviewed | reviewed |

## Comparison findings

- Board: real 6×6 density remains readable; category ownership, score hierarchy, current-turn line, used check, and point tiers remain distinct. Compact removes the secondary wide heading before shrinking gameplay data.
- Text Question: the question remains dominant, timer visible but secondary, and helper/reveal controls keep usable targets. Arabic wrapping is balanced with no truncation or normal-scale scrolling.
- Image Question: wide sizes use an adaptive text/media split and compact sizes preserve both without scaling the whole canvas. The deterministic landscape fixture crops consistently and respects rounded bounds.
- Reveal: answer and real explanation form one hierarchy; the host scoring card remains compact; the disabled confirmation state is clear before selection; scores and Team A/No one/Team B meaning remain correct in RTL.
- Result: winner pictogram and headline lead, real scores and gap remain secondary, and the primary Play Again CTA stays visible at every size. Tie uses the draw pictogram and no false winner.
- Across all renders: Thmanyah Sans loaded at the required weights; no `DEV` badge, overflow stripe, clipped CTA, broken-image icon, dark surface, emoji, or Rive appeared.

## Deliberate baseline changes

All 25 Phase 4 files under `docs/visual-validation/v9_2_phase4/` were generated deliberately because screens 12–16 are the new approved Phase 4 baseline. A final second generation incorporated three reviewed corrections across applicable sizes: explicit check icon for used Board cells, bounded Reveal score card, and bounded centered Result CTA. The suite then passed again without regeneration. Phase 3's 30 baselines were not regenerated and still pass unchanged.

The raw review used five full-resolution, size-grouped contact sheets, each containing all five screens, so every final PNG was opened after the last baseline update.
