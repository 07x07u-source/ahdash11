# Phase H.3 — final parity exceptions

Metric source: `docs/v10_parity/phase_h3_final/metrics.csv`. Threshold: 95.00%.
All 24 references have before/after, side-by-side, overlay, and absolute-diff
evidence under `docs/v10_parity/phase_h3_final/`.

## Closure summary

- Direct passes: **15**
- Approved Category B exceptions: **3**
- Approved Category C reference-specific exceptions: **6**
- Category A: **0**
- Unclassified sub-95 references: **0**

The nine sub-95 results below were inspected individually. They are retained
only where copying the raster literally would break accessibility, real domain
data, navigation, or a complete input flow, or where the supplied reference is
internally inconsistent/corrupt.

| Reference | Before | After | Classification | Exact evidence and decision |
|---|---:|---:|---|---|
| 03 Sign In — Compact | 89.08 | 93.85 | C | The canonical PNG becomes a narrow vertical glyph stream below the divider and does not depict a usable complete form. Flutter retains the real provider actions, fields, validation, scrolling, and minimum targets. This is a reference-specific raster defect, not a fixable Flutter mismatch. |
| 04 Create Account — Compact | 77.31 | 94.45 | B | The remaining 0.55 points are provider-icon/native text-field raster metrics and accessible field spacing. Compressing three real fields, provider actions, legal copy, errors, and the CTA further fails the verified 1.2/1.3 text-scale and 300 px keyboard-inset contract. |
| 06 Category Search — Keyboard | 83.74 | 85.18 | C | The corrected keyboard reference inherits the compact selection contradiction and a platform keyboard raster. Flutter keeps the real searchable six-category state and focused-field reachability. Application content is not masked from the score. |
| 06 Category Selection — Compact | 78.44 | 89.76 | C | The PNG footer says six selected while only four tiles are visually selected, and its back-navigation placement conflicts with the primary frame. Flutter consistently renders six real categories, real selection state, RTL navigation, and reachable controls. |
| 07 Category Detail — Compact | 81.07 | 88.59 | C | The compact PNG omits/moves the back-navigation affordance relative to the primary reference. Removing the production back action would create a navigation trap. Remaining pixels are artwork crop and platform text raster differences. |
| 07 Category Detail — Primary | 82.11 | 92.75 | B | Structure, content hierarchy, CTA, and real category data align. Remaining delta is the supplied illustrative artwork crop plus font/image rasterization. Production keeps provider-backed data and a rights-safe fallback instead of embedding reference-only sample content. |
| 18 Saved Games — Primary | 90.87 | 94.17 | C | The reference contains illustrative fixed sessions/dates. Production must render only genuinely persisted sessions and real loading/empty/error states. The deterministic test fixture now uses restorable production-shaped data; inventing exact reference records is prohibited. |
| 35 Friends — Primary | 92.65 | 92.65 | C | The reference contains static avatar art/data that are absent from the deterministic server fixture. Production rows remain server-derived and do not invent avatar URLs or presence. |
| 35 Friends Search — Keyboard | 93.03 | 93.03 | C | Same server-data/avatar constraint as the primary state, plus platform-owned keyboard raster differences. The real search field remains reachable at the required inset. |

## Direct passes

The other 15 references score 95.06%–96.83%. This includes both Team Setup
states, both Helpers states, both Ready states, Category Selection Primary, Solo
Setup, Team Challenge, and all six Party helper-delta Board/Text/Image states.

Approved helper identities remain exactly:

- `two_chances` — جاوب جوابين
- `call_friend` — اتصال بصديق (internal gameplay timer only)
- `risk` — الحفرة
- `bench` — استريح
- `pass` — الفخ

Each team selects three of five. No stale helper identity was restored.

## Final gate

There is no fixable visual mismatch left in the Phase H.3 set, no Category A
reference, and no unexplained sub-95 result. These evidence-backed B/C rows close
the corrected-reference gate without weakening production truth or accessibility.
