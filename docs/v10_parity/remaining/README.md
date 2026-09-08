# V10 Phase H — remaining visual parity evidence

This directory compares the 40 canonical local V10 references in
`docs/v10_figma_reference/remaining` with deterministic renders of the real
production Flutter widgets.

- `before/`: preserved pre-fix Flutter baselines where available.
- `after/`: final Flutter captures, normalized only for unpainted OS chrome.
- `side_by_side/`: canonical Figma reference on the left, Flutter on the right.
- `overlay/`: 50/50 image overlays.
- `diff/`: absolute pixel differences.
- `metrics.csv`: before/after mean-difference parity scores.

System status/navigation bars and the OS keyboard are copied from the canonical
reference during metric calculation because Flutter widget goldens deliberately
do not render platform chrome. No application-content region is masked. Dynamic
Figma sample content remains test-only; production continues to use real domain
providers and rights-safe media fallbacks.
