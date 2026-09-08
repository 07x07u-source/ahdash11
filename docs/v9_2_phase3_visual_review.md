# AHDASH 11 V9.2 — Phase 3 visual review

Status: **30/30 Phase 3 raw renders reviewed**.

The six Light Mode screens were rendered at all five required sizes. Every raw PNG under `docs/visual-validation/v9_2_phase3/` was opened for review, grouped into one six-screen contact sheet per size for direct cross-screen comparison. The approved wide/compact handoff extracts were used as the visual anchors. A fresh Figma MCP fetch was attempted but was unavailable because the connector required OAuth; no screen was approximated from prompt text alone.

| Screen | 800×360 | 844×390 | 915×412 | 1280×720 | 1366×768 |
|---|---:|---:|---:|---:|---:|
| 06 Category Selection | reviewed | reviewed | reviewed | reviewed | reviewed |
| 07 Category Detail | reviewed | reviewed | reviewed | reviewed | reviewed |
| 08 Team Setup | reviewed | reviewed | reviewed | reviewed | reviewed |
| 09 Team Splitter | reviewed | reviewed | reviewed | reviewed | reviewed |
| 10 Helpers | reviewed | reviewed | reviewed | reviewed | reviewed |
| 11 Ready | reviewed | reviewed | reviewed | reviewed | reviewed |

## Review results

- Thmanyah Sans renders with the approved 400/500/700/900 registrations; Arabic team/category/helper labels do not clip at the tested sizes.
- RTL header, progress, team order, `VS`, player lists, helper ownership, category rail, and primary/secondary actions are visually coherent.
- The four core screens (Teams, Splitter, Helpers, Ready) fit without normal vertical scrolling or Flutter overflow at all five target sizes.
- Category Selection intentionally scrolls its real catalog. Compact layouts keep three readable image-led tiles in view and retain search, real filters, selected count, ownership tray, random action, and Continue.
- Category Detail uses a balanced landscape image/information composition. Wide renders include real metadata chips; compact renders reduce those secondary details before reducing title/action legibility.
- Remote category media uses focal alignment, stable crop, loading behavior, and a category-colored fallback with its own initial; unrelated repeated imagery and broken-image chrome are absent.
- Team color remains secondary to the always-visible name/label. No decorative `01`/`02` numerals or normal-flow gold treatment remains.
- Splitter before/after state is understandable, with actual names only, balanced columns, visible `VS`, Skip/re-split/edit/confirm actions, and reduced-motion-compatible transition behavior.
- All five helpers use distinct Ahdash pictograms. Selected/disabled/consumed semantics are textual as well as chromatic.
- Ready prioritizes both teams, real category ownership, helper summaries, optional players, timer, validation feedback, and the Start CTA. Compact footer and dropdown widths do not overflow.
- No Coin, Wallet, XP, Online, Dark Mode, Rive, or audio affordance appears in the Phase 3 renders.

## Deliberate functional differences from static handoff data

- Category names, covers, availability, counts, favorites, premium locks, and filters come from the real repository/catalog; deterministic fixtures are used only by Goldens. Figma prototype names are never production defaults.
- Search and supported filters remain visible because they are required functional controls. Unsupported visual-only filters were not invented.
- Category Detail omits a trial/answer preview because no safe complete trial contract exists; no answer key is exposed.
- Helper labels/descriptions follow the domain/backend identifiers and effects rather than prototype marketing copy.
- The optional splitter is a routed step only when requested; the basic two-team game can skip it.

## Golden evidence

`mobile/test/visual/v9_2_phase3_golden_test.dart` passed 30/30 without `--update-goldens`. The raw artifacts are in `docs/visual-validation/v9_2_phase3/` and cover six screens multiplied by five required sizes.
