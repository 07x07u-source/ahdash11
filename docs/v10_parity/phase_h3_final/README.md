# Phase H.3 final parity evidence

This directory contains the completed comparison for all 24 immutable Phase H.3
V10 exports. `before` preserves the first H.3 Flutter render; `after`,
`side_by_side`, `overlay`, `diff`, and `metrics.csv` contain the final rerender
and evidence at the identical viewport.

Reference integrity was checked against
`docs/v10_figma_reference/phase_h3_final/hashes.csv`: **24/24 SHA-256 entries
matched**. The reference PNG files were never modified.

The score is `100 - normalized mean absolute RGB pixel difference`. Only
unpainted OS safe-area chrome and platform-owned keyboard pixels are normalized;
application content is never masked. Results: **15/24 >=95.00%**, with the
remaining **9/24** documented as objective Category B/C exceptions in
`docs/v10_phase_h_parity_exceptions.md`. Category A and unclassified counts are
both zero.

The full maintained suite passed **490/490**, `flutter analyze` returned
**No issues found**, responsive/keyboard coverage passed, and the Android Debug
APK was built successfully. No Figma connector, Supabase operation, Online
activation, Production AAB, or publishing operation was used.
