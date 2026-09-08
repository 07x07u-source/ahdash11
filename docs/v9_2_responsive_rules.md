# AHDASH 11 V9.2 — Responsive, landscape, RTL rules

## Reference sizes and implementation targets

Figma supplies intentional compositions at 1280×720 (wide) and 844×390 (compact). Flutter validation must also cover 800×360, 915×412, and 1366×768. `AhdashV9Metrics` currently treats width below 916 or height at/below 412 as compact, width at/above 1200 with usable height as wide, and detects portrait separately.

| Target | Mode | Horizontal gutter | Priority |
|---|---|---:|---|
| 800×360 | compact landscape | 20 | primary task only; suppress tertiary copy |
| 844×390 | compact landscape/Figma anchor | 24 | match compact frame composition |
| 915×412 | compact boundary | 24–28 | verify no threshold overflow |
| 1280×720 | wide/Figma anchor | 32 | match wide frame composition |
| 1366×768 | wide | 40 | cap content width; do not stretch controls |
| portrait devices | portrait fallback | 16 | recompose/scroll utility surfaces safely |

## Composition rules

1. Use `LayoutBuilder`, constraints, `Flexible`, `Expanded`, `Wrap`, and max-width containers. Never apply a single global scale transform.
2. Compact is a distinct composition. Remove decorative media, secondary description, tertiary metadata, and redundant header labels before shrinking the question, team identity, score, or main CTA.
3. Core Party and Tournament gameplay should fit standard landscape heights without normal page scrolling. Utility screens may use bounded internal scrolling.
4. `AhdashV9Frame` owns safe-area padding and a 1366 max width. Do not add a second unconditional screen gutter inside it.
5. Maintain 44–48 px hit areas even when visible icons are 18–24 px.
6. Premium compact must show its primary purchase CTA in the initial 844×390 viewport.

Representative inspected differences:

- Home rearranges priorities and media between wide and compact rather than scaling the whole hero.
- Game Board compact suppresses nonessential header copy and maximizes the board.
- Settings wide exposes all intended categories while compact uses intentional internal scrolling where needed.
- Tournament Bracket compact focuses on the current round; semifinal/final remain states, not routes.

## RTL and BiDi

- The application is Arabic-first RTL. Back/forward affordances must use the existing directional icon abstraction rather than hard-coded LTR arrows.
- Row order, team sides, bracket progression, tabs, and progress are checked semantically, not blindly mirrored.
- Arabic/English football names remain in the RTL layout. Pure numeric score pairs use an LTR text isolate, with an Arabic semantic label.
- Inputs inherit app direction, while email, code, URL, and numeric fields may explicitly isolate their entered value.

## Safe areas and system UI

Respect display cutouts, rounded corners, status/navigation/gesture regions, and platform overlays. `SafeArea` is part of the V9 frame contract. Background media may bleed behind a composition only where the inspected Figma frame does so and content padding remains safe.

## Text scaling and overflow

- Test default and enlarged text. At compact heights, allow secondary content to disappear/reflow before reducing primary text below the approved role floor.
- Arabic headings and questions require line-count-aware sizing, bounded lines where the design requires it, and no clipped diacritics.
- Buttons must keep labels legible; use flexible width or alternate composition instead of tiny fonts.
- Long team, player, club, and league names use a clear overflow rule and preserve the full value in semantics/tooltips where appropriate.

## Validation gate for later phases

For each migrated screen: render 844×390 and 1280×720, then inspect raw images. Critical gameplay/auth/profile/settings/premium screens also render 800×360, 915×412, and 1366×768. Passing a golden hash alone is not visual approval.
