# V10 Phase H — Account / Utility / Premium parity

Canonical source: `docs/v10_figma_reference/account_premium`. The source PNGs were not modified. Scores use mean absolute RGB difference after masking only the operating-system status/navigation regions and the canonical keyboard pixels.

| Screen | Viewport | Before | After |
|---|---:|---:|---:|
| Profile | 390×844 | 88.85% | 95.76% |
| Profile | 360×800 | 87.53% | 95.23% |
| Notifications | 390×844 | 95.45% | 95.24% |
| Settings | 390×844 | 94.20% | 97.51% |
| Report | 390×844 | 92.09% | 96.26% |
| Report keyboard | 390×844 | 87.33% | 96.40% |
| Football Preferences | 390×844 | 89.75% | 95.15% |
| Football Preferences keyboard | 390×844 | 88.24% | 95.59% |
| Premium | 390×844 | 91.75% | 95.84% |
| Premium | 360×800 | 89.17% | 95.07% |

Notifications started above the threshold; its small numerical change reflects replacing the empty fixture with the canonical real-item state and is accepted because the final score remains above 95%.

Truth-preserving residuals: the football domain supports one favourite club, so Flutter intentionally does not reproduce the reference's two simultaneous selected club cards. Profile renders real remote avatars when present and a packaged Player 11 fallback when absent. Premium prices and availability remain store-backed; no price, discount, benefit, entitlement, or successful operation is fabricated.

Evidence is under `before/` and `after/`, each containing `figma/`, `flutter/`, `side_by_side/`, `overlay/`, `diff/`, and `metrics.csv`.
