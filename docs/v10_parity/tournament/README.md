# Phase H — Tournament visual parity

Canonical authority: the frozen V10 exports under `docs/v10_figma_reference/tournament`. The reference PNGs were read-only throughout this pass. System-owned status/navigation areas are excluded from scoring; the keyboard-owned area is excluded for the keyboard state.

| Screen | Viewport/state | Before | After |
|---|---|---:|---:|
| 19 Tournament Hub | 390×844 | 89.22% | 97.38% |
| 19 Tournament Hub | 360×800 | 87.31% | 95.36% |
| 20 Create Tournament | 390×844 | 93.30% | 98.32% |
| 20 Create Tournament | 390×844 keyboard | 91.50% | 97.88% |
| 21 Tournament Teams | 390×844 | 92.26% | 97.83% |
| 22 Tournament Draw | 390×844 | 90.80% | 97.43% |
| 23 Tournament Bracket | 390×844 | 93.65% | 97.60% |
| 23 Tournament Bracket | 360×800 | 92.00% | 95.35% |
| 26 Tournament Match | 390×844 | 91.11% | 97.91% |
| 27 Tournament Champion | 390×844 | 94.02% | 97.41% |

## Recovered discrepancies

- Rebuilt the portrait header, safe-area rhythm, gutters, typography hierarchy, buttons, cards, and content anchors to the V10 compositions.
- Matched Create Tournament's field, capacity choices, CTA, and keyboard-shifted layout while preserving keyboard-safe scrolling.
- Matched team rows, draw pairings, four bracket round tabs, match cards, score display, match focus, and champion hierarchy.
- Kept all production callbacks and existing Tournament → Party flow intact; deterministic fixture data only supplies the exact visual states used by the canonical frames.

## Evidence

Every case has `figma`, `flutter`, `side_by_side`, `overlay`, and `diff` PNGs under `before/` and `after/`. `metrics.csv` in each directory contains the immutable before scores and final after scores. In side-by-side images, Figma is on the left and Flutter is on the right.

## Intentional residuals

- Tournament Match does not invent a venue because no authoritative venue field exists in the domain. It retains the real advancement note instead.
- The organizer-only external-result action remains available because it is supported production behavior even though the canonical composition does not show it.
- Minor glyph/font rasterization differences remain, including the app's trophy glyph versus the thin Figma pictogram.
