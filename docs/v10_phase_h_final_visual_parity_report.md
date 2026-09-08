# AHDASH | 11 — Phase H final visual parity report

Date: 2026-09-06  
Reference authority: immutable local V10 Phase H.3 pack  
Final gate: **AHDASH | 11 — PHASE H VISUAL PARITY COMPLETE**

## Phase H.3 coverage

- Canonical files found and SHA-256 verified: **24/24**
- Identical-viewport before/after comparisons: **24/24**
- Side-by-side, overlay, and absolute-diff evidence: **24/24**
- Direct numeric passes (>=95.00%): **15**
- Approved evidence-backed B/C exceptions: **9**
- Category A: **0**
- Unclassified or unexplained sub-95 references: **0**
- Average score: **90.59% → 94.37%**

Only platform-owned safe-area/keyboard pixels were normalized. No application
content was masked and no Golden was used as design authority.

## Final reference results

| Reference | Before | After | Gate |
|---|---:|---:|---|
| 03 Sign In — Compact | 89.08 | 93.85 | approved C: malformed/incomplete canonical compact raster |
| 04 Create Account — Compact | 77.31 | 94.45 | approved B: complete accessible form and native raster |
| 06 Category Search — Keyboard | 83.74 | 85.18 | approved C: contradictory compact state + platform keyboard |
| 06 Category Selection — Compact | 78.44 | 89.76 | approved C: six-count/four-selected reference contradiction |
| 06 Category Selection — Primary | 84.12 | 95.21 | PASS |
| 07 Category Detail — Compact | 81.07 | 88.59 | approved C: missing/inconsistent back navigation |
| 07 Category Detail — Primary | 82.11 | 92.75 | approved B: provider data/rights-safe media raster |
| 08 Team Setup — Compact | 92.32 | 96.53 | PASS |
| 08 Team Setup — Primary | 94.04 | 96.83 | PASS |
| 10 Helpers — Compact | 91.09 | 95.61 | PASS |
| 10 Helpers — Primary | 92.69 | 95.06 | PASS |
| 11 Ready — Compact | 90.57 | 96.24 | PASS |
| 11 Ready — Primary | 92.29 | 95.10 | PASS |
| 18 Saved Games — Primary | 90.87 | 94.17 | approved C: illustrative records vs real persisted data |
| 29 Solo Setup — Primary | 96.81 | 96.81 | PASS |
| 33 Team Challenge — Primary | 96.80 | 96.80 | PASS |
| 35 Friends — Primary | 92.65 | 92.65 | approved C: static avatar/data vs server truth |
| 35 Friends Search — Keyboard | 93.03 | 93.03 | approved C: server truth + platform keyboard |
| 12 Game Board — Primary | 96.61 | 96.78 | PASS |
| 12 Game Board — Compact | 95.67 | 95.87 | PASS |
| 13 Text Question — Primary | 95.64 | 95.83 | PASS |
| 13 Text Question — Compact | 95.14 | 95.35 | PASS |
| 14 Image Question — Primary | 96.27 | 96.44 | PASS |
| 14 Image Question — Compact | 95.70 | 95.89 | PASS |

Exact exception evidence is recorded in
`docs/v10_phase_h_parity_exceptions.md`. Image evidence and raw metrics are in
`docs/v10_parity/phase_h3_final/`.

## Genuine Flutter discrepancies fixed

- Rebuilt Category Selection and Category Detail portrait composition, search,
  footer, media treatment, and responsive spacing.
- Aligned Team Setup cards, header, colours, player summary, and primary action.
- Corrected all helper labels and art mapping to the approved five-helper domain
  contract without changing helper behavior.
- Aligned Ready summary, team circles/cards, and compact footer.
- Made the Party scaffold header/footer responsive at compact sizes.
- Corrected Auth portrait spacing, field hints, title, and create action while
  keeping providers, validation, scrolling, and keyboard safety real.
- Changed Saved Games visual state to render genuine current/history session
  shapes rather than fake production records.
- Preserved Friends as server-derived data with no invented presence/avatar URL.
- Fixed long Arabic Team Splitter header overflow while retaining optional skip,
  add/remove, colour selection, distribution, and confirmation behavior.

## Product-truth certification

Party remains 6 categories, 36 questions, 2 teams, and 3 of 5 helpers per team.
The approved helpers are `two_chances`, `call_friend` (internal timer only),
`risk`, `bench`, and `pass`; no stale identity was restored. Team Splitter stays
optional, Solo stays LIMITED, Team Challenge stays implemented, Saved Games uses
real persistence, Friends uses server data, and Auth uses real provider actions.

Unsupported active UI findings: **0**. No XP, coins, wallet, fake ranking,
presence, statistics, or hardcoded Premium price/discount was added.

## Regression, responsiveness, and build

- Normal complete command `flutter test`: **490/490 passed**, 0 failures.
- Focused Party setup suite: **20/20 passed**.
- `flutter analyze`: **No issues found**.
- Layouts exercised at 360×800, 390×844, 393×852, 412×915, and 430×932.
- Text scale exercised at 1.0, 1.2, and 1.3, including long Arabic names.
- Keyboard screens exercised with approximately 300 px inset; no overflow.
- Android Debug APK built at
  `mobile/build/app/outputs/flutter-apk/app-debug.apk` (258,770,474 bytes;
  SHA-256 `4F59463A5943F19AD4658B6FC263E3E776DCEE080CD5A29BFF7F3DA85E5D320B`).

## Locks confirmed

- Online 30–32 remains deferred and inactive.
- No Figma tool or connector was called.
- No Figma reference was modified.
- No Supabase deploy, migration, remote SQL, RLS, or RPC operation occurred.
- No Production AAB, signing, publishing, or release deployment occurred.
- Archived V9/V9.2 Goldens and tests were not restored or rewritten.

Phase H is closed. Do not start the Supabase Security Gate automatically.
