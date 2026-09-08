# AHDASH | 11 — V9 Checkpoint Report

## Gate result

- Scope: 18 key screens/states.
- Raw outputs: 72 PNG files (18 screens × Light/Dark × 844×390/1280×720).
- Automated result: 72/72 passed with no RenderFlex overflow or uncaught exception.
- Font harness: Material Icons, Thmanyah Sans/Serif and Cupertino Icons loaded explicitly.
- Visual review: raw PNGs opened directly, plus four contact sheets.
- Decision: **PASS — continue to wave two.**

## Visual scorecard

Scores are out of 5. Any critical category below 4 would block continuation.

| Screen | Hierarchy | Balance | Type | Spacing | Images | Pictograms | Touch | RTL | Brand | Game feel |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Launch | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 4 |
| Sign in | 5 | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 4 |
| Create account | 5 | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 4 |
| Home | 5 | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 5 |
| Categories | 5 | 4 | 4 | 4 | 4 | 4 | 5 | 5 | 5 | 5 |
| Team setup | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 5 | 5 |
| Ready | 5 | 4 | 5 | 4 | 4 | 5 | 5 | 5 | 5 | 5 |
| Board | 5 | 5 | 5 | 5 | 4 | 4 | 5 | 5 | 5 | 5 |
| Text question | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 5 | 5 |
| Final result | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 5 | 5 |
| Tournament hub | 5 | 4 | 5 | 5 | 4 | 5 | 5 | 5 | 5 | 5 |
| Tournament bracket | 5 | 5 | 4 | 5 | 4 | 4 | 5 | 5 | 5 | 5 |
| Tournament match | 5 | 4 | 5 | 5 | 4 | 4 | 5 | 5 | 5 | 5 |
| Champion | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 5 | 5 |
| Profile | 5 | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 4 |
| Settings / Privacy | 5 | 4 | 5 | 5 | 4 | 4 | 5 | 5 | 5 | 4 |
| Football preferences | 5 | 4 | 5 | 5 | 4 | 4 | 5 | 5 | 5 | 4 |
| Premium | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 5 | 4 |

## Evidence paths

- Raw Goldens: `docs/visual-validation/v9-checkpoint/`
- Contact sheets:
  - `contact-sheet_844x390_light.png`
  - `contact-sheet_844x390_dark.png`
  - `contact-sheet_1280x720_light.png`
  - `contact-sheet_1280x720_dark.png`
- Harness: `mobile/test/visual/v9_checkpoint_golden_test.dart`

## Resolved issues

- Removed the duplicate launch identity unit.
- Auth is one continuous full-bleed scene with a single task stack.
- Home now makes Start Game dominant; resume is tertiary and state-dependent.
- Categories use three readable columns, larger titles and a connected selection tray.
- Board score/turn and point hierarchy are readable at 844×390.
- Questions use line-count-aware sizing.
- Tournament Bracket uses RTL convergence paths on wide layouts and round focus on compact layouts.
- Settings uses horizontal implemented groups; blocked players now lives under Privacy while retaining its route.
- Football preferences is a two-step league → club flow instead of permanent master-detail.
- Premium displays only real store plans supplied by the purchase service.
- The missing Cupertino font in the old V8.2 harness is fixed in V9.

## Non-blocking follow-ups

- Validate wave-two screens at 800×360, 915×412 and 1366×768.
- Add the club-grid state to the final client catalog in addition to the league step.
- Revisit Tournament Match optical scale only if the 1366×768 raw frame still feels under-filled.
