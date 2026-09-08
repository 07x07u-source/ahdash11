# AHDASH 11 V9.2 — Phase 2 visual review

Review date: 2026-09-04  
Scope: screens 01–05 only  
Figma file: `1tbYuMwiC8b9vCj12TzbAA`

## Sources and rendered matrix

| Screen | Wide node | Compact node | Raw renders reviewed |
|---|---:|---:|---|
| 01 Launch | `81:131` | `81:147` | 800×360, 844×390, 915×412, 1280×720, 1366×768 |
| 02 Onboarding | `81:168` | `81:215` | 800×360, 844×390, 915×412, 1280×720, 1366×768 |
| 03 Sign In | `81:268` | `81:298` | 800×360, 844×390, 915×412, 1280×720, 1366×768 |
| 04 Create Account | `81:327` | `81:362` | 800×360, 844×390, 915×412, 1280×720, 1366×768 |
| 05 Home | `81:394` | `81:433` | 800×360, 844×390, 915×412, 1280×720, 1366×768 |

All 25 raw PNGs under `docs/visual-validation/v9-2-phase2` were opened at original resolution and reviewed, not only compared by the Golden matcher.

## Screen-by-screen findings

### 01 Launch

- The light paper identity, centered canonical mark/wordmark, negative space, restrained progress treatment, tagline, and CTA hierarchy match the wide and compact references.
- Compact keeps the primary CTA pinned and fully visible at 800×360; wide keeps the brand moment centered.
- The progress bar is intentionally indeterminate: no fabricated percentage or network claim appears.

### 02 Onboarding

- Wide presents the four product-approved concepts in one row. Compact uses a horizontal RTL step rail with the current card fully visible and adjacent content providing a deliberate carousel cue.
- The owner-approved fourth concept, “win by score”, is retained even where the visual reference shows fewer simultaneous cards; this is a truthful content correction, not a new game rule.
- Next, back, skip, and finish states remain visible at short heights. Existing Ahdash pictograms replace emoji and decorative images stay silent to screen readers.

### 03 Sign In

- The approved stadium is full-bleed with a right-biased directional scrim and controlled form width; there is no generic Material card or dashboard composition.
- Inputs, password visibility, primary CTA, account switch, guest entry, and only configured social providers use the real auth controller.
- The compact form remains usable at 800×360. Its scroll container and view insets keep focused fields and the primary action keyboard-safe.

### 04 Create Account

- Wide belongs to the same full-bleed auth family; compact deliberately shifts to the approved split composition with the form and stadium occupying distinct regions.
- Only display name, email, and password are present. Validation/error/loading states do not expose backend exception text.
- All fields and actions fit at 800×360 without vertical or horizontal overflow.

### 05 Home

- The Saudi stadium visual, directional dark treatment, canonical brand lockup, compact utility cluster, and right-aligned action hierarchy match the V9.2 anchors.
- Only the real primary and secondary actions are always visible. Resume is conditional on an actual Party or Tournament state.
- Coin, Wallet, XP, fake ranking, and Online affordances are absent. The cinematic black bands are part of the approved exported source image, not accidental layout padding.

## Typography, RTL, accessibility, and motion

- All product text uses the registered Thmanyah Sans faces (400/500/700/900). Arabic wrapping, line height, button labels, form labels, and mixed email text were checked at every target size.
- Directionality is true RTL. Header/action order, form alignment, progress order, carousel direction, and route affordances were checked in the raw renders and widget tests.
- Interactive controls preserve at least the shared 48dp target where applicable. Important controls and progress have semantic labels; decorative hero images and pictograms are excluded from duplicate speech.
- Focus follows the source order, form fields have keyboard actions, and content respects view insets. Contrast is provided by the measured directional scrims.
- Launch/Auth/Home entrance motion and onboarding state motion are bounded and stop; reduced-motion disables them. No loop, Rive placeholder, or unapproved SFX was added.

## Visual validation result

- Golden verification: **25/25 passed**.
- Raw renders manually reviewed: **25/25**.
- Approved anchors: 844×390 and 1280×720.
- Critical additional renders: 800×360, 915×412, and 1366×768.
- Observed overflow, missing CTA, broken asset, or clipped required text: **none**.

## Intentional implementation differences

1. Thmanyah Sans replaces any placeholder font metadata in the handoff, per the approved brand decision.
2. Onboarding keeps four truthful gameplay concepts and scrolls compact content instead of shrinking type.
3. Social auth controls render only when their real configuration exists; no unavailable method is drawn to mimic a static frame.
4. Remote published Home/Auth media remains supported, with the exact approved Figma originals packaged only as stable fallbacks.
5. Home omits Coin/Wallet/XP/Online material and does not fabricate a resume card.

No screenshot was exported as an implementation surface; the UI remains native Flutter and responsive.
