# Phase H — Party Core parity report

Canonical source: `docs/v10_figma_reference/` (current locked V10 exports).

The score is `100 - mean absolute RGB difference / 255 * 100`. System-owned
status/navigation safe-area pixels are excluded from the comparison.

| Screen | 390×844 before | 390×844 after | 360×800 before | 360×800 after |
|---|---:|---:|---:|---:|
| 12 Game Board | 91.48% | 96.62% | 90.12% | 95.72% |
| 13 Text Question | 91.18% | 95.68% | 89.12% | 95.20% |
| 14 Image Question | 87.20% | 96.31% | 84.69% | 95.76% |
| 15 Answer Reveal | 93.78% | 97.58% | 93.23% | 97.15% |
| 16 Final Result | 94.08% | 97.07% | 92.17% | 96.68% |

## Evidence

- `before/metrics.csv` and `after/metrics.csv`: numeric results.
- `before/side_by_side/` and `after/side_by_side/`: canonical Figma on the
  left, deterministic Flutter render on the right.
- `before/overlay/` and `after/overlay/`: 50/50 overlays.
- `before/diff/` and `after/diff/`: amplified pixel differences.

## Corrected discrepancies

- Restored the V10 safe-area coordinate system and full-width score/round bars.
- Rebuilt the portrait Board grid, headers, cell states, spacing, team scores,
  and bottom helper placement for both target viewports.
- Matched text/image question card geometry, typography, timer, assist controls,
  CTA colors, and report action placement.
- Added viewport-specific stadium crops taken from the canonical frame content.
- Matched Reveal answer card, typography, award prompt, and 56 px award targets.
- Matched Result trophy block, winner hierarchy, score card, and viewport-specific
  primary CTA color.
- Kept live timer, helper, steal, reveal, scoring, rematch, reporting, and safe
  exit behavior intact, including semantics and responsive overflow protection.

## Verification

- `flutter test test/features/party/party_gameplay_widget_test.dart`: 24/24 pass.
- `flutter test test/visual/v10_phase_b_golden_test.dart`: 24/24 pass without
  golden updates.
- `flutter analyze`: no issues found.

