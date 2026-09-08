# Phase 6 — raw visual review

Date: 2026-09-05. Local Flutter renders, not physical-device approval.

## Reference and method

Figma handoff nodes: Profile 81:3767 / 81:3838; Notifications 81:3897 / 81:3979; Settings 81:4042 / 81:4077; Report 81:4149 / 81:4194; Football 81:4235 / 81:4310; Premium 81:4393 / 81:4433. Wide compositions were inspected in the authenticated read-only browser. A subsequent design-context connector attempt requested reauthentication; it did not provide new measurements. Existing reviewed references and packaged assets were used as allowed by the request. This is not a claim of fresh connector/pixel-perfect certification.

Every raw PNG in docs/visual-validation/v9_2_phase6 was individually opened: **35/35**. No contact sheet substituted for review.

## Matrix

| Screen | 800×360 | 844×390 | 915×412 | 1280×720 | 1366×768 |
|---|---|---|---|---|---|
| Profile | reviewed | reviewed | reviewed | reviewed | reviewed |
| Notifications | reviewed | reviewed | reviewed | reviewed | reviewed |
| Settings | reviewed | reviewed | reviewed | reviewed | reviewed |
| Report | reviewed | reviewed | reviewed | reviewed | reviewed |
| Football | reviewed | reviewed | reviewed | reviewed | reviewed |
| Premium | reviewed | reviewed | reviewed | reviewed | reviewed |

Additional 844×390 states individually opened: profileUnavailable, notificationsEmpty, footballEmpty, premiumActive, premiumUnavailable.

## Findings

Identity/stat hierarchy is readable; Profile's secondary football choices intentionally scroll at 800×360. Settings has all eight rows/version in the 1280×720 viewport and scrolls on compact screens. Notifications retain right-aligned hierarchy and left-side dates. Football uses rights-safe badges, textual selection check and full save CTA. Report's optional description and full submit are visible in ordinary compact viewport; keyboard interaction is separately widget-tested. Premium headline, short real value, two plans, localized price and full 48px subscribe CTA fit 800×360 and 844×390; restore remains accessible.

Initial renders caught a Material/ColoredBox ink-layer assertion on profile/football rows; fixed in the shared utility composition, then regenerated only Phase 6 baselines. Original Thmanyah Sans 400/500/700/900 and required icon fonts are loaded. No unrelated baseline was regenerated.

Differences from prototype are deliberate functional truth: no demo statistics, no unsupported tabs/actions, no report attachments, one supported league/club workflow, no fabricated plan prices or benefits. Packaged existing Player 11 artwork and profile backdrop are retained; no new raster asset was authored. Product Owner visual approval is still required.
