# AHDASH V9 — RAW GOLDEN AUDIT — SCREENS 01–15

## Scope and evidence

- Audited only screens 01–15 in the exact order of SCREENS from tools/build_v8_2_screen_catalog_pdf.py.
- Opened the raw Golden PNG files themselves at original detail, not the PDF catalog.
- Reviewed Light and Dark at 1280×720 for all 15 screens.
- Also reviewed Light and Dark at 844×390 for Sign in, Create account, Home, Helpers, and Ready; no compact Golden exists in the catalog source for the other screens.
- All pixel measurements below are visual approximations from the raw 1280×720 or 844×390 raster.
- No implementation or product file was changed as part of this audit.
- **Checkpoint glyph evidence caveat:** Hollow-square utility glyphs in checkpoint screens are attributable at least in part to a validation-harness defect: `v8_2_checkpoint_golden_test.dart` loads `MaterialIcons` but does not load `packages/cupertino_icons/CupertinoIcons`, while the other relevant Golden tests do. Regenerate after font-loader parity; the squares alone do not prove a production rendering defect.

## 01 — Launch

- PURPOSE: Brand/boot transition before entering the product.
- PRIMARY TASK/ACTION: No user action; recognize Ahdash and wait for the next route.
- FIRST FOCUS: The centered canonical logo.
- CURRENT PROBLEMS: The logo occupies only about 17% of the width and feels small inside the canvas; a second micro mark beneath it duplicates identity without adding meaning; the decorative outer frame and center seam imply a split layout but do not create a strong launch moment; no motion state is visible in the static Golden.
- EMPTY SPACE: Roughly 85–90% of the canvas is unstructured empty space. The space does not create suspense because the focal unit is too small.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Main logo is approximately 220×50; secondary mark is approximately 16–22 px. No text, image, or meaningful launch pictogram. The canonical logo needs a larger optical scale and the 11 animation should form one brand unit.
- UTILITY ICONS: 0.
- BUTTON/INPUT/TOUCH: No controls.
- ALIGNMENT/RTL: Main logo is geometrically centered, but the vertical center seams visually cut through it. RTL is not applicable.
- LIGHT/DARK: Light places the logo directly on Paper; Dark puts it inside a large beige rectangle and puts the micro mark in another beige tile. The two modes communicate different logo treatments instead of one coherent launch system; Dark is otherwise a flat near-black sheet.
- RESPONSIVE: No 844×390 Golden; compact behavior is unverified.
- GAME FEEL: Low. It reads as a static brand splash, not a premium kickoff.
- LEGACY DNA: Canonical Ahdash wordmark and 11 motif are present but under-expressed.
- DENSITY: FOCUS.
- DECISION: REBUILD.

## 02 — Onboarding

- PURPOSE: Explain the core party-game loop to a first-time player.
- PRIMARY TASK/ACTION: Understand the three concepts, then press ابدأ الآن.
- FIRST FOCUS: The three large pictograms on the left compete with the large but mostly empty panel on the right; the CTA is not the first actionable focus.
- CURRENT PROBLEMS: It still reads as a content list beside an empty visual panel; the right panel reserves about 430×568 px but places only a tiny label at the top and copy at the bottom; the header/logo and supporting note are small; the CTA is detached at the opposite bottom corner; separators make the left side feel instructional/form-like rather than visual and playful.
- EMPTY SPACE: The majority of the right panel and broad bands around the left list are unused. This is dead space because the imagery and copy do not scale to own it.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: The three Ahdash pictograms are approximately 70–90 px and are the strongest retained element. Step copy is about 22–24 px and readable. Header/meta copy is about 10–16 px. There is no meaningful hero visual in the large right surface.
- UTILITY ICONS: 0; the logo is identity, not utility.
- BUTTON/INPUT/TOUCH: Primary CTA is about 240×46 and meets height guidance, but its far-left placement disconnects it from the content and reading endpoint.
- ALIGNMENT/RTL: Local Arabic alignment is correct, but the overall reading path moves from a right panel to a left list and then to a far-left bottom action with no cohesive visual flow. Long dividers overstate the list structure.
- LIGHT/DARK: Both modes preserve hierarchy; Dark has slightly better surface separation, while Light is very flat beige-on-beige. Neither fixes the empty panel.
- RESPONSIVE: No 844×390 Golden; compact behavior is unverified.
- GAME FEEL: Medium-low. Custom pictograms provide DNA, but the page behaves like an instruction brochure.
- LEGACY DNA: Strong in the three original pictograms and green accent.
- DENSITY: MEDIUM by purpose, visually sparse in execution.
- DECISION: REBUILD. Retain this route only if onboarding is still a verified product requirement; otherwise REMOVE.

## 03 — Sign in

- PURPOSE: Authenticate an existing player.
- PRIMARY TASK/ACTION: Enter email/password and sign in; secondary actions are account creation and guest entry.
- FIRST FOCUS: The giant gold 11 and football image, not the sign-in action.
- CURRENT PROBLEMS: Although the image technically spans the canvas, the hard directional scrim and isolated right-side stack still read as image area + form area; the form resembles a desktop web component; the large hero, logo, and tagline compete with the auth hierarchy; the generic field/guest glyphs render as identical hollow squares and look broken or undefined; account creation is bright green and competes with the primary CTA.
- EMPTY SPACE: The cinematic image uses the left area well, but the right half below the guest action is unused and the form is visibly allocated its own column rather than floating in intentional negative space.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Headline is approximately 28–30 px, body 13–14 px, legal copy about 10–11 px. Full-bleed image and focal 11 are visually strong; canonical logo is approximately 196×60. No Ahdash content pictogram is used in the auth unit.
- UTILITY ICONS: 3 generic glyphs in desktop (email, password, guest); all appear as nearly identical hollow squares, so recognition fails.
- BUTTON/INPUT/TOUCH: Desktop inputs are approximately 48 px high and primary CTA approximately 52 px, both acceptable; guest is about 36 px high and too small. At 844, both login and guest buttons are only about 36 px high, below the 44–48 target, while inputs remain about 47 px.
- ALIGNMENT/RTL: Form text is correctly right-aligned, but the composition is a fixed left-visual/right-form split. The compact two-button row weakens primary/secondary separation.
- LIGHT/DARK: Raw Light and Dark are visually almost identical because the same dark image/scrim/form treatment is used; there is no meaningful theme adaptation.
- RESPONSIVE: 844×390 retains logo, headline, fields, primary and guest/create actions, but removes the short line/legal context and shrinks the action buttons. The fixed split remains, rather than allowing the auth stack to float over negative space.
- GAME FEEL: The football atmosphere is strong; the interaction still feels like a website login.
- LEGACY DNA: Strong image, 11, and canonical logo; weak in form behavior.
- DENSITY: FOCUS.
- DECISION: REBUILD.

## 04 — Create account

- PURPOSE: Create the minimum required player account.
- PRIMARY TASK/ACTION: Enter player name, email, and password, then create the account; secondary actions are sign in and guest entry.
- FIRST FOCUS: The gold 11/football scene remains stronger than the registration CTA.
- CURRENT PROBLEMS: It is essentially Sign in with one extra field and therefore lacks a registration-specific composition; the same rejected image/form split remains; generic field/guest glyphs appear as identical hollow squares; the compact logo jumps to the upper-left unlike the Sign in placement, creating auth inconsistency. The three fields themselves are appropriately minimal and should not be expanded with preferences.
- EMPTY SPACE: The image is meaningfully occupied, but the right side is a fixed form column with unused lower area. The content does not feel naturally anchored to the image.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Headline is approximately 28–30 px; body 13–14 px; legal copy 10–11 px. Full-bleed image is strong. No branded content pictogram participates in registration.
- UTILITY ICONS: 4 generic glyphs (three fields + guest), all visually unresolved as hollow squares.
- BUTTON/INPUT/TOUCH: Desktop inputs are approximately 48 px and primary CTA approximately 52 px; guest is about 36 px. At 844, primary Create and guest buttons are both about 36 px high and fail the compact touch target; inputs remain approximately 47 px.
- ALIGNMENT/RTL: Form alignment is correctly RTL, but the composition remains a rigid two-column template. Compact actions are equal-height side-by-side buttons, weakening the create-account primary hierarchy.
- LIGHT/DARK: Light and Dark are effectively the same dark cinematic treatment with no theme-specific hierarchy.
- RESPONSIVE: 844×390 preserves required fields and actions, but shrinks controls and drops supporting/legal copy. Image crop is good; composition remains a split.
- GAME FEEL: Strong football scene, weak registration interaction; feels web-auth rather than game onboarding.
- LEGACY DNA: Strong in image/logo/11, limited inside the form.
- DENSITY: FOCUS.
- DECISION: REBUILD.

## 05 — Home

- PURPOSE: Primary game entry point and access to tournament creation; optionally resume a real active session.
- PRIMARY TASK/ACTION: ابدأ لعبة must be the dominant action; أنشئ بطولة is secondary; كمل لعبتك is contextual only when a real session exists.
- FIRST FOCUS: The huge foreground football and the bright green كمل لعبتك strip. ابدأ لعبة is not the first interactive focus.
- CURRENT PROBLEMS: It still reads as a sports website hero; the upper-left utility/navigation cluster reinforces website behavior; the resume strip has stronger color than the actual Start Game CTA; the Start CTA is pale/outlined and Create Tournament is only a small secondary web button; the UI appears pasted over the right half rather than integrated into image depth.
- EMPTY SPACE: Stadium negative space is visually intentional, but the main interaction remains confined to a fixed right column. Large image territory does not help the primary gameplay action.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Headline is about 34–36 px desktop and 28–30 px compact; metadata 14–16 px. Resume is about 52 px high and Start about 54 px desktop. Full-bleed ball/stadium crop is strong. No separate content pictogram beyond the logo/11 language.
- UTILITY ICONS: About 3 generic upper-left items; all are tiny square-like glyphs, and Premium is given navigation-level prominence.
- BUTTON/INPUT/TOUCH: Start meets desktop/compact height guidance (about 54/49 px). Create Tournament is about 36–37 px high in both sizes and is below the touch target. Top utility hit areas are not visibly 44 px.
- ALIGNMENT/RTL: Main copy is properly right-aligned. The Create Tournament + كيف نلعب؟ row spreads secondary destinations horizontally like website navigation and breaks the dominant gameplay stack.
- LIGHT/DARK: Light and Dark raw Goldens are pixel-visually identical; the screen is always a dark hero with no theme adaptation.
- RESPONSIVE: 844×390 preserves all key content and crops the image competently, but simply compresses the same split. Secondary controls remain under-sized.
- GAME FEEL: Football atmosphere is high; product/game-home clarity is only medium because the Start action loses to hero art and Resume.
- LEGACY DNA: Strong canonical logo, 11 geometry, lime accents, and football image.
- DENSITY: MEDIUM.
- DECISION: REBUILD.

## 06 — Party — Category selection

- PURPOSE: Select exactly six categories for the party game.
- PRIMARY TASK/ACTION: Select six recognizable categories and proceed; secondary actions are search, filter, favorite, info, and random selection.
- FIRST FOCUS: The repetitive four-column grid and large search bar; the Next action is visually remote.
- CURRENT PROBLEMS: All six unrelated categories reuse the same eye/ball stadium art; four columns make names, badges, and metadata small at actual viewing scale; filter chips form a tiny ribbon; the bottom selected-category strip repeats all six names at micro scale; Random and selection count sit away from the grid; the primary Next CTA is isolated in the bottom-left.
- EMPTY SPACE: With six items, the second row occupies only the right half, leaving a large blank left block; more importantly, selected state and Next are pushed to the extreme bottom instead of using that space compositionally.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Cards are approximately 294×195, but card titles are only about 13–15 px, metadata/new badges about 9–11 px, and chips about 12 px. Images are large enough in area but not unique enough to aid recognition. No branded category pictograms.
- UTILITY ICONS: Approximately 17 visible utilities: back, search, shuffle, filter check/heart, plus info and favorite on each of six cards. This is too many at equal visual presence.
- BUTTON/INPUT/TOUCH: Next is about 95×46 and meets height but is visually underweight; Random is about 118×37 and under target; filters are about 30 px high; favorite/info glyphs are 14–18 px and their 44 px hit areas are not evident. Search is about 40 px high, below the preferred input target.
- ALIGNMENT/RTL: Header, filter, and grid order are RTL-consistent; left-side forward action is defensible for RTL progression, but it is too detached. Selection count lacks alignment with the main selection unit.
- LIGHT/DARK: Both are legible. Dark has slightly better surface separation; Light relies on dark image cards over a very flat beige canvas. Repeated black covers make both modes monotonous.
- RESPONSIVE: No 844×390 Golden. A four-column system at 844 is therefore unverified and conflicts with the requirement to reduce column count instead of shrinking.
- GAME FEEL: Medium-low; behaves like a content marketplace/catalog, not a bold category draft.
- LEGACY DNA: The eye/ball artwork is recognizably Ahdash but is overused until categories lose individual identity.
- DENSITY: DENSE.
- DECISION: RECOMPOSE.

## 07 — Party — Category detail

- PURPOSE: Explain a selected category and allow a sample question.
- PRIMARY TASK/ACTION: Understand the category and press جرّب سؤال.
- FIRST FOCUS: The tall right-side visual.
- CURRENT PROBLEMS: The CTA is at x≈20 while the title/content starts around x≈473 and the visual starts around x≈774, creating three disconnected zones; there is no visible route/header context; the fixed tall image produces a rigid split; the CTA is tiny relative to the image and sits at the far edge.
- EMPTY SPACE: Most of the left half and lower content area are unused. This is not intentional focus because the CTA and copy do not form a single unit with the visual.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Image is approximately 486×680 and dominates height, but its narrow portrait treatment is not justified by the category asset. Title is about 21–22 px, description 14 px, and chips 12–13 px. No content pictogram.
- UTILITY ICONS: 1 eye icon inside the CTA; it is not necessary for comprehension.
- BUTTON/INPUT/TOUCH: CTA is approximately 116×47 and technically meets height guidance, but its small width and remote placement make it weak. Chips are about 30 px high; if interactive, they fail touch guidance.
- ALIGNMENT/RTL: Text is locally right-aligned, yet the CTA breaks all content alignment lines and sits across a roughly 600 px gap. The Arabic reading path is fragmented.
- LIGHT/DARK: Light is flat Paper with one dark image; Dark becomes one nearly-black sheet and the dark visual merges into it. Neither adds meaningful surface hierarchy.
- RESPONSIVE: No 844×390 Golden. Fixed portrait behavior and missing adaptive media treatment are unverified.
- GAME FEEL: The artwork has football atmosphere; the page itself feels like a sparse marketing detail route.
- LEGACY DNA: Present mainly through the eye/ball asset; category-specific DNA is absent.
- DENSITY: FOCUS.
- DECISION: RECOMPOSE.

## 08 — Party — Team setup

- PURPOSE: Establish two team identities, optional player names, and colors before play.
- PRIMARY TASK/ACTION: Name Team A and Team B, then continue; color choice and automatic split are secondary.
- FIRST FOCUS: The gold VS, followed by two small input clusters rather than strong team identities.
- CURRENT PROBLEMS: Inputs and metadata float inside two huge outlined halves; team names exist only inside form fields instead of becoming identity; player names are micro text; color selectors are tiny dots; the قسمنا action is a small corner link; decorative vertical team lines dominate more than the actual content.
- EMPTY SPACE: Approximately 65–70% of both team zones is empty. The page has the correct Team A / VS / Team B skeleton but not the required scale.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: VS is approximately 64 px and strong; team-name text is about 18 px; player metadata 11–13 px; visible color dots about 24 px. Large faint team pictograms behind the controls are too low-contrast to contribute. No image.
- UTILITY ICONS: About 6 utilities: back, two group icons in inputs, two group icons by player lists, and shuffle/split. Group icons are repeated without adding clarity.
- BUTTON/INPUT/TOUCH: Inputs are approximately 369×48 and acceptable. Next is about 130×46 and acceptable. Visible color targets are only about 24 px and no larger hit area is evident. The split link is too small as a touch action.
- ALIGNMENT/RTL: Team 01 is correctly on the right and Team 02 on the left; main symmetry and baseline are clean. Header, split action, and Next are detached from the central composition.
- LIGHT/DARK: Dark introduces faint team color tints but they are almost imperceptible; Light is very flat. The hidden/faint pictograms are weaker in Dark.
- RESPONSIVE: No 844×390 Golden; compact team-name, VS, and color behavior are unverified.
- GAME FEEL: Medium. VS and team colors hint at competition, but the screen still behaves like a sparse form.
- LEGACY DNA: Faint custom team imagery and color pairing are present but not visually significant.
- DENSITY: MEDIUM by purpose, visually sparse.
- DECISION: RECOMPOSE.

## 09 — Party — Team splitter

- PURPOSE: Enter a player list and randomly produce two clear teams.
- PRIMARY TASK/ACTION: Before split, enter one name per line and press قسّم الفرق; after split, inspect the two team groups.
- FIRST FOCUS: The right-side list headings and the two team names at the top; the giant ghost 01/02 numbers also compete despite having no task value.
- CURRENT PROBLEMS: The Golden mixes input/list and already-split team results without a clear before/after state; player and helper text is tiny; the multiline input is represented mainly by a bottom underline far from its instruction; VS is microscopic; giant ghost 01/02 numerals consume the lower-left area; CTA is isolated in the far-left corner; no shuffle transition is communicated.
- EMPTY SPACE: More than 65% of the canvas is unused between the top lists and bottom controls.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Team headings are about 18–20 px, player rows about 13–16 px, VS about 14 px, while ghost numerals exceed 100 px. The hierarchy is inverted. No meaningful image or Ahdash pictogram.
- UTILITY ICONS: 3: close, shuffle in the heading, shuffle in the CTA. The shuffle icon is duplicated.
- BUTTON/INPUT/TOUCH: Split CTA is approximately 118×46 and meets height. Close appears as an exposed 16–18 px glyph with no clear 44 px target. The multiline input’s interactive bounds are not visually clear and its baseline is detached from the list.
- ALIGNMENT/RTL: Player-list instruction is correctly right-aligned and Team 01 precedes Team 02 in RTL order, but columns lack a shared structural container and input-to-result flow is unclear.
- LIGHT/DARK: Dark makes the ghost numbers nearly invisible but leaves the dead composition intact; both themes are flat, with insufficient state/surface differentiation.
- RESPONSIVE: No 844×390 Golden; the three-zone layout is unverified and likely fragile on compact width.
- GAME FEEL: Low. It is a static data arrangement rather than a shuffle/reveal moment.
- LEGACY DNA: Low; team color dots are the only distinctive trace.
- DENSITY: MEDIUM by task, visually sparse.
- DECISION: REBUILD.

## 10 — Party — Helpers

- PURPOSE: Let each team select three helpers for the round.
- PRIMARY TASK/ACTION: Select exactly three helpers and continue when both teams are ready.
- FIRST FOCUS: The selected custom فرصتين pictogram and its selected tile.
- CURRENT PROBLEMS: The desktop composition preserves nearly compact-sized controls inside a much taller canvas; the selected explanation is in an overly wide 976×140 strip far below the selected item; selection counts are repeated in the segmented team control and lower-right summary; labels/header/meta remain small; five helpers still read partly like a toolbar row rather than a deliberate game choice.
- EMPTY SPACE: Desktop has large unintentional bands above the team selector and below the explanation. Compact uses the canvas far better.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Custom pictograms are approximately 52–72 px, with selected treatment around 64–80 px, and should be kept. Labels are about 14–16 px desktop and near 12 px compact; description about 14 px. No photographic image.
- UTILITY ICONS: 1 navigation glyph plus 1 selected-state check. The five custom pictograms are content choices, not utility icons.
- BUTTON/INPUT/TOUCH: Next is approximately 108×46 desktop and 108×45 compact, acceptable. Helper items appear to have roughly 80–96 px interactive zones. The team segmented control is only about 32 px high and is under touch guidance if switchable.
- ALIGNMENT/RTL: Team 01 is correctly on the right, helpers read RTL, and explanation is right-aligned. The explanation width and vertical gap weaken its relationship to the selected helper.
- LIGHT/DARK: Surface differentiation is acceptable in Dark; selected/team states remain clear. Logo treatment differs—bare mark in Light versus a beige tile in Dark—creating header inconsistency.
- RESPONSIVE: 844×390 is materially better composed and retains all essential actions, but title supporting copy is reduced/removed and the same small text sizes remain. Controls are not dangerously shrunk except the already-small segment.
- GAME FEEL: Medium-high because the original pictograms are distinctive; selection behavior needs more weight and grouping.
- LEGACY DNA: Strong; this is one of the best uses of the Ahdash pictogram system.
- DENSITY: MEDIUM.
- DECISION: REFINE.

## 11 — Party — Ready

- PURPOSE: Confirm the complete party setup and create a kickoff moment.
- PRIMARY TASK/ACTION: Review teams/categories/helpers and press يلا نبدأ.
- FIRST FOCUS: Team A / VS / Team B, which is correct, but the Start action is not visually strong enough to become the next focus.
- CURRENT PROBLEMS: Desktop central energy is still under-scaled and surrounded by broad blank bands; selected categories are rendered as six small labels/lines across the bottom like a table; time and question/point metadata are tiny; Start is a narrow corner button; the setup summary competes horizontally rather than forming a kickoff stack.
- EMPTY SPACE: About 35–40% of desktop height is unintentional dead space around the central matchup and bottom summary. Compact density is much better.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Desktop team names are approximately 34–38 px, team pictograms 60–70 px, VS 64–68 px, helper pictograms around 28–36 px. Compact names drop to about 25–28 px and pictograms to about 40–46 px. Category labels are only 12–14 px.
- UTILITY ICONS: 1 navigation glyph; team helper marks are branded content pictograms, not utilities.
- BUTTON/INPUT/TOUCH: Start is about 66×46 desktop and 66×45 compact—adequate height but far too weak in width/visual weight for the decisive action. Time selector is about 170×40 and below target.
- ALIGNMENT/RTL: Team 01 is correctly on the right and the matchup is centered. Bottom category/metadata rows share baselines but are detached from the matchup; Start is isolated at far left.
- LIGHT/DARK: Team colors and lime action remain readable; Dark is otherwise a flat single sheet with little depth. Header mark again uses different Light/Dark treatment.
- RESPONSIVE: 844×390 is much more efficient and preserves the matchup, categories, metadata, and Start. The time selector crowds/overlaps the bottom information band and the CTA remains visually minor.
- GAME FEEL: Central matchup has good game DNA, but the page lacks the final kickoff energy because the primary CTA and summary are weak.
- LEGACY DNA: Strong through team pictograms, helper pictograms, color coding, and VS treatment.
- DENSITY: MEDIUM.
- DECISION: RECOMPOSE.

## 12 — Party — Board

- PURPOSE: Present the 6×6 game board, current turn, category choices, point values, and team scores.
- PRIMARY TASK/ACTION: The active team selects an available point cell.
- FIRST FOCUS: The 6×6 grid. Team scores are too small to act as the second key focus.
- CURRENT PROBLEMS: It reads as a spreadsheet/table; score hierarchy is weak top metadata; every category repeats the same visual; full cell borders dominate; category owner/meta lines are cramped; active turn is a tiny center label. This fixture shows every cell in the same available state, so a clearly consumed state cannot be validated.
- EMPTY SPACE: Almost none; the canvas is efficiently used. The problem is visual density/hierarchy, not lack of content.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Point values are approximately 30–32 px and readable. Category names are about 17–20 px; sublabels 11–13 px. Scores are only about 20 px and team names about 15–17 px. Category images are approximately 196×92 but all use the same eye asset. Helper pictogram is about 28 px in a 48 px circle.
- UTILITY ICONS: 2 generic utilities (close and undo) plus 1 branded helper action. Utility count is controlled, but exposed close/undo targets are not visibly 44 px.
- BUTTON/INPUT/TOUCH: Cells are roughly 196×78 and excellent touch targets. Category headers are large. Close/undo glyphs appear small; their hit areas are unclear.
- ALIGNMENT/RTL: Grid alignment is precise. Team 01 score is correctly right and Team 02 left. Tiny active-turn/category text at center lacks alignment weight relative to scores.
- LIGHT/DARK: Dark has slightly clearer tonal cell/column separation; Light column accents are extremely subtle. Both preserve too many grid borders and repeated header art.
- RESPONSIVE: No 844×390 Golden; fixed 6×6 compact behavior is unverified.
- GAME FEEL: Medium. The Jeopardy-like board is recognizable, but the scoreboard and state treatment do not yet feel like a game show.
- LEGACY DNA: Moderate through colors, helper pictogram, and eye art; repeated eye headers weaken category identity.
- DENSITY: DENSE.
- DECISION: REFINE; retain the 6×6 rules and core board structure.

## 13 — Party — Text question

- PURPOSE: Present a text question for the active team.
- PRIMARY TASK/ACTION: Read/answer verbally, then reveal the answer; secondary actions are report and helper use.
- FIRST FOCUS: The centered question, correctly.
- CURRENT PROBLEMS: Active-team/category/point metadata is only 12–14 px; Reveal is detached in the lower-left instead of following the reading path; report and helper actions are distributed across opposite corners; state information is weaker than the excellent question typography.
- EMPTY SPACE: Large negative space is mostly intentional for focus. A smaller portion becomes dead because controls are pushed to corners rather than forming a secondary action band.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Question is approximately 40–44 px across two lines and is one of the strongest scales in V8.2; it should not shrink. Shorter questions could scale slightly larger. No image. Two helper pictograms are about 24–30 px inside 48 px circles.
- UTILITY ICONS: 2 generic utilities (eye in Reveal, report flag) plus 2 branded helper actions. Count is reasonable, but distribution is fragmented.
- BUTTON/INPUT/TOUCH: Reveal is approximately 133×46 and meets guidance. Helper circles are about 48 px. Report appears as a small text link with no evident 44 px hit target.
- ALIGNMENT/RTL: Question is centered and RTL shaping is correct. Category/points are at upper-right and active team upper-left, but the action endpoint is far from both the question and helper cluster.
- LIGHT/DARK: Both have excellent question contrast. Dark is a flat sheet, which is acceptable for a focused question but needs better state/action integration.
- RESPONSIVE: No 844×390 Golden; line-count-aware compact typography is unverified.
- GAME FEEL: Strong quiz tension through scale and restraint; game state and action placement keep it from feeling fully resolved.
- LEGACY DNA: Moderate through lime action and custom helper pictograms.
- DENSITY: FOCUS.
- DECISION: REFINE.

## 14 — Party — Image question

- PURPOSE: Ask the active team to identify something from an image.
- PRIMARY TASK/ACTION: Inspect the image, answer verbally, then reveal; secondary actions are report and helpers.
- FIRST FOCUS: The portrait image.
- CURRENT PROBLEMS: A rigid image-right/text-left split is forced by a full-height divider; question text falls to about 22–24 px and becomes much weaker than the text-question screen; most of the left panel is empty. Critically, the shown abstract eye/stadium image contains no visible player although the question asks which player appears, so the raw Golden demonstrates a content/fixture mismatch and not a valid image-question state.
- EMPTY SPACE: About 60% of the text half is unused, while the media half is fixed. This is an aspect-ratio/layout failure rather than intentional focus.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Portrait media is approximately 438×548 and visually significant, but treated as one fixed ratio. Question is under-scaled at about 22–24 px; metadata is 12–14 px. Two helper pictograms are about 24–30 px inside 48 px circles.
- UTILITY ICONS: 2 generic utilities (eye, report flag) plus 2 branded helper actions.
- BUTTON/INPUT/TOUCH: Reveal is approximately 133×46 and helpers about 48 px. Report text has no obvious compliant target.
- ALIGNMENT/RTL: Image-first on the right is a logical RTL entry, but the centered question sits far away in a separate panel. The divider makes the composition feel like two pages.
- LIGHT/DARK: In Dark, the already-dark image merges into the canvas and loses edge separation. Light has clearer separation but remains rigid.
- RESPONSIVE: No 844×390 Golden; portrait, landscape, and square adaptive compositions are entirely unverified.
- GAME FEEL: Medium-low in this Golden because the displayed content does not answer the visual premise; a valid football image could make the moment strong.
- LEGACY DNA: Helper pictograms and eye artwork are recognizable, but reusing the category cover as question media damages authenticity.
- DENSITY: FOCUS.
- DECISION: REBUILD.

## 15 — Party — Answer reveal

- PURPOSE: Reveal the correct answer/explanation and assign points.
- PRIMARY TASK/ACTION: Decide whether Team 01, Team 02, or no one receives the point; reporting is secondary.
- FIRST FOCUS: The large lime correct answer, correctly.
- CURRENT PROBLEMS: The answer/explanation group is isolated at center; النقطة لمين؟ is at the far bottom-right while all award controls sit at the far bottom-left; team scores remain tiny top metadata; award buttons are only about 36 px high; report is inserted between content and scoring controls; no single reveal/award unit or visible motion moment exists.
- EMPTY SPACE: More than half the lower/middle canvas is unused even though the scoring decision is spatially disconnected. This is not productive focus space.
- SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM: Answer is approximately 48–52 px and strong; original question about 18–20 px; explanation about 14 px; result metadata 12–13 px; team scores about 20 px. No image or custom reveal pictogram.
- UTILITY ICONS: 1 report flag.
- BUTTON/INPUT/TOUCH: Team buttons are approximately 164×36 and لا أحد about 81×36; all fail the 44–48 height target. Color coding is clear, but the options and prompt do not form one control group.
- ALIGNMENT/RTL: Central answer alignment is good. Score-assignment RTL flow is broken across the entire width: prompt right, options left, report between them.
- LIGHT/DARK: Correct-answer contrast is strong in both. Dark is again a single near-black sheet with no surface/interaction depth.
- RESPONSIVE: No 844×390 Golden; scoring-control wrapping and compact reveal behavior are unverified.
- GAME FEEL: The reveal headline has some payoff; the actual point-award interaction feels administrative and weak.
- LEGACY DNA: Low-to-moderate, limited to lime, team colors, and typography; no distinctive Ahdash reveal element.
- DENSITY: FOCUS.
- DECISION: RECOMPOSE.

## Five most critical problems across screens 01–15

1. FOUNDATION COMPOSITION FAILURE: Sign in and Create account still visibly use the rejected image/form split, while Home still behaves like a sports website hero. On all three, the intended primary action is not the first visual focus.
2. SCALE AND TOUCH SYSTEM FAILURE: The same small content often floats in 1280×720 while 844×390 simply compresses it. Multiple primary/secondary controls are only 30–40 px high: compact auth actions, Home secondary CTA, category filters/random, Ready time selector, and all Answer award buttons.
3. PARTY FLOW DEAD SPACE: Onboarding, Team setup, Team splitter, and Ready contain large unstructured blank regions and corner-isolated CTAs. Team Splitter is the worst offender because ghost 01/02 numbers and mixed before/after states invert the hierarchy.
4. MEDIA/CONTENT AUTHENTICITY FAILURE: Category cards repeat one eye/ball asset for unrelated categories, Category Detail forces it into a tall treatment, and Image Question displays the same abstract cover even though the prompt asks for a visible player. Adaptive aspect-ratio behavior is absent/unverified.
5. GAME-STATE HIERARCHY FAILURE: Board scores/turn are tiny above a spreadsheet-like grid, while Answer scoring actions are tiny and disconnected from the reveal. Across the group, utility glyphs also repeatedly render as undefined hollow squares, which must be treated as a real visual defect until proven otherwise.


