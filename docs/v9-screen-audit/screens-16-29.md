# AHDASH V9 - RAW GOLDEN AUDIT - SCREENS 16-29

## Scope and evidence

- Audited the exact screen order from `SCREENS` in `tools/build_v8_2_screen_catalog_pdf.py`.
- Opened 38 RAW Golden PNGs at original resolution: Light and Dark for all 14 screens at 1280x720, plus Light and Dark at 844x390 for screens 16, 19, 22, 26, and 27.
- No judgment below is based on the scaled PDF catalog.
- No application or test file was changed.
- Compact status is explicitly marked unverified when a 844x390 Golden does not exist.
- **Checkpoint glyph evidence caveat:** The hollow-square utility glyphs in checkpoint screens are attributable at least in part to a validation-harness defect: `v8_2_checkpoint_golden_test.dart` loads `MaterialIcons` but does not load `packages/cupertino_icons/CupertinoIcons`, while the other relevant visual Golden tests do. These squares require regeneration and re-verification after font-loader parity; they are not, by themselves, automatic proof of a production rendering defect.

## Decision summary

| # | Screen | Decision | Density |
|---|---|---|---|
| 16 | Party - final result | REFINE | FOCUS |
| 17 | How to play | REBUILD | MEDIUM |
| 18 | Saved party games | RECOMPOSE | DENSE / LIST |
| 19 | Tournament hub | REBUILD | MEDIUM |
| 20 | Create tournament | REBUILD | FOCUS PER STEP |
| 21 | Tournament teams | REBUILD | DENSE / LIST |
| 22 | Tournament draw | REFINE | FOCUS before draw; MEDIUM after draw |
| 23 | Tournament bracket | REBUILD | DENSE |
| 24 | Tournament semifinal | MERGE into Bracket | MEDIUM stage |
| 25 | Tournament final | MERGE into Bracket | FOCUS stage |
| 26 | Tournament match | RECOMPOSE | FOCUS |
| 27 | Tournament champion | RECOMPOSE | FOCUS |
| 28 | Match setup | REBUILD | MEDIUM |
| 29 | Solo setup | REBUILD | MEDIUM |

---

## 16 - Party - final result

- **PURPOSE:** Close a Party game, announce the winner and score, then route the players to their next session.
- **PRIMARY TASK/ACTION:** Understand who won; current visual primary action is `لعبة جديدة`. Secondary actions are `إعادة بنفس الفرق` and `الرئيسية`.
- **FIRST FOCUS:** The winner statement `الكأس لـ صقور الجزيرة`, supported by the custom gold win pictogram. This is the correct first focus.
- **CURRENT PROBLEMS:** The emotional result group and the three next actions behave as separate zones. `لعبة جديدة` is isolated at bottom-left while two text actions float at bottom-right. Winner, team score, and answered-question count do not form a fully resolved hierarchy; the last line is micro-text.
- **EMPTY SPACE:** At 1280, a roughly 380x270 result cluster sits inside a mostly unused canvas. Negative space is excessive rather than celebratory. Compact is better proportioned.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Winner type is strong at roughly display scale; team names and scores are only medium; metadata is about 12px. The wide pictogram is visually meaningful at roughly 100px, but becomes closer to 80px compact. There is no image, which is acceptable for this focus state.
- **UTILITY ICONS:** 0 generic utility icons. This is good; the branded result pictogram carries the moment.
- **BUTTON / INPUT / TOUCH:** The filled action is about 95x46 and meets minimum height. The two text actions have no visible touch container and read as footer links. No inputs.
- **ALIGNMENT / RTL:** The centered result group is optically stable and score order is understandable in RTL. Bottom actions have no shared baseline or action group, which breaks the composition and makes priority ambiguous.
- **LIGHT / DARK:** Both themes are consistent, but each is almost one flat sheet. Lime text on the light beige is less readable than the dark-mode equivalent. Gold use is appropriate here.
- **RESPONSIVE:** 844x390 preserves the result and does not scroll. It appropriately makes the result larger relative to the canvas, but bottom actions sit close to the edges, link hit areas remain unclear, and the pictogram shrinks.
- **GAME FEEL:** Medium. The custom trophy gives ownership, but there is no celebratory depth, transition, or compact action closure.
- **LEGACY DNA:** Strong Ahdash DNA in the pictogram and Arabic headline; weak generic footer-action behavior remains.
- **DENSITY:** FOCUS.
- **DECISION:** **REFINE.** Keep the pictogram and winner statement; recompose score plus winner as one emotional unit and group the three next actions by clear primary/secondary priority.

## 17 - How to play

- **PURPOSE:** Explain the Party loop in four steps.
- **PRIMARY TASK/ACTION:** Learn the active step and move with `التالي`; `السابق` and back are secondary.
- **FIRST FOCUS:** Competing focuses: the four-pictogram timeline across the top, the large empty diagram panel, and the duplicated active-step pictogram on the right. There is no single first focus.
- **CURRENT PROBLEMS:** It reads as documentation/diagram rather than quick visual onboarding. The active step is duplicated in the timeline and body. The lower-left panel contains six small category tiles inside a very large frame, while the explanatory copy is separated on the right. Tiny repeated glyphs beside `فئة 1..6` add noise.
- **EMPTY SPACE:** Large unused zones exist inside the bordered diagram panel and around its centered six-tile grid. The container is large, but the meaningful content is not.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Main pictograms are appropriately recognizable at roughly 80-90px, but headings, body, step labels, and diagram details are small. No actual mini-game imagery is used, even though it would teach faster than the diagram.
- **UTILITY ICONS:** 1 navigation chevron, plus 6 tiny repeated category glyphs that behave as visual clutter. Branded pictograms should not be counted as utility icons.
- **BUTTON / INPUT / TOUCH:** `التالي` is around 46px high and usable; `السابق` is a faint text action without a visible hit area. No inputs. The timeline labels do not clearly signal whether they are tappable.
- **ALIGNMENT / RTL:** The conceptual step order runs right-to-left correctly, but connector strokes do not communicate progression. The body split is poorly tied to the active step. The back chevron sits on the right but points left; directional semantics need an RTL audit.
- **LIGHT / DARK:** Light has a subtle panel tone; dark collapses panel and canvas into nearly the same black. Lime active state is clear in both, but muted text and boundaries in dark are weak.
- **RESPONSIVE:** **UNVERIFIED** - no 844x390 Golden. The four-step horizontal timeline plus two-column body is high-risk at compact height and should not be assumed to adapt.
- **GAME FEEL:** Low. It feels like a help document, not a short game tutorial.
- **LEGACY DNA:** Original Ahdash pictograms are valuable; the surrounding documentation layout is legacy/web-like.
- **DENSITY:** MEDIUM, with four concise visual steps.
- **DECISION:** **REBUILD.** Use four short visual gameplay steps, one focal visual per step, minimal copy, and one clear action.

## 18 - Saved party games

- **PURPOSE:** Resume a current/saved Party game and create a new one.
- **PRIMARY TASK/ACTION:** Continue the current game with `كمّل`. `لعبة جديدة` and back are secondary.
- **FIRST FOCUS:** The single current-game row, specifically the matchup and 700-500 score, but it is too small to command the page.
- **CURRENT PROBLEMS:** One compact row is suspended in a huge canvas. Team names, score, progress, saved-device note, and status dot do not create a strong saved-session identity. No designed empty state or multi-row behavior is demonstrated.
- **EMPTY SPACE:** Roughly two-thirds of the canvas is unused. The row width is reasonable, but its visual scale and placement do not justify the page.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Screen title and matchup are about 18-20px; the green progress line is micro-text near 11px. No saved-game thumbnail, pictogram, or stronger session marker exists.
- **UTILITY ICONS:** 1 back chevron. The blue dot is a status marker, not a meaningful icon.
- **BUTTON / INPUT / TOUCH:** `كمّل` is about 53x46 and technically tappable, but visually cramped. `لعبة جديدة` is a text action beside the brand mark with no clear button surface. No inputs.
- **ALIGNMENT / RTL:** Row order from matchup on the right to score/action on the left is understandable. The new-game action at the top center is disconnected from both header and list.
- **LIGHT / DARK:** Dark is one near-black sheet; Light is one beige sheet. Lime micro-copy is notably weak on Light. Row separators are visible but make it feel table-like.
- **RESPONSIVE:** **UNVERIFIED** - no 844x390 Golden. The simple row may fit, but actual text and tap readability have not been proven.
- **GAME FEEL:** Low. It resembles a sparse database/list state rather than a saved game ready to resume.
- **LEGACY DNA:** Weak; only the logo and palette identify Ahdash.
- **DENSITY:** DENSE / LIST in the intended system, even when fixture data contains one row.
- **DECISION:** **RECOMPOSE.** Build a proper saved-session row language with meaningful scale, state and clear resume priority, plus a designed empty state.

## 19 - Tournament hub

- **PURPOSE:** Serve as the active tournament home and show what must happen next.
- **PRIMARY TASK/ACTION:** Continue the current tournament with `كمّل البطولة`. `بطولة جديدة` is secondary.
- **FIRST FOCUS:** Tournament pictogram plus `بطولة أحدعش الليلية`; this is directionally correct, but the actual active-event information is secondary.
- **CURRENT PROBLEMS:** Current round, progress, next match and matchup are rendered as small metadata/rows. The CTA is extremely wide but only about minimum height, reinforcing a form layout. The screen does not feel like a live competition.
- **EMPTY SPACE:** At 1280, a large blank band separates header from the tournament group, and another remains below the CTA. Compact uses space much better.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Tournament title is strong around 38-40px. Current-round/progress text is roughly 12-14px. The custom tournament pictogram is only around 75-85px and should participate more strongly. No cover/image exists.
- **UTILITY ICONS:** 1 ambiguous hollow-square glyph at top-right. Its meaning is not recognizable at actual size.
- **BUTTON / INPUT / TOUCH:** Wide CTA is approximately 744x44; compact is approximately 484x39 and falls below the target. The new-tournament text action has no visible touch container. No inputs.
- **ALIGNMENT / RTL:** Hero title/pictogram align well. Progress, `المباراة التالية`, team names, and CTA use different visual axes and do not form one event block. The square navigation glyph is not RTL-readable.
- **LIGHT / DARK:** CTA inversion is clear. Otherwise both themes are flat; Dark lacks canvas/surface differentiation and Light relies heavily on beige plus thin rules.
- **RESPONSIVE:** 844x390 is substantially better proportioned and correctly preserves title, progress, next match and CTA. It does not merely scale, but CTA height and header/utility legibility regress.
- **GAME FEEL:** Low-to-medium. Custom tournament identity exists, but active-event energy does not.
- **LEGACY DNA:** Strong pictogram; form-like progress and row treatment weaken the Ahdash signature.
- **DENSITY:** MEDIUM.
- **DECISION:** **REBUILD.** Make tournament name, current round/progress, next match, and Continue one dominant active-event composition.

## 20 - Create tournament

- **PURPOSE:** Create a tournament through a focused setup flow.
- **PRIMARY TASK/ACTION:** Name the tournament and continue to rules with `التالي: القواعد`; back is secondary.
- **FIRST FOCUS:** The horizontal 1/2 progress line competes with `سمّ طريق الكأس`; the field/action group is too weak to become the focus.
- **CURRENT PROBLEMS:** One field and one thin button occupy a small central strip in a huge screen. `1/2` is stranded at the far left. The field label is cramped against the border. The current two-step representation does not communicate the richer setup flow described for V9. Most critically, the black tournament pictogram visible beside the heading in Light disappears against Dark.
- **EMPTY SPACE:** More than 60% of the canvas is unassigned above and below the narrow form band.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Heading is around 24-26px, field content about 16px, label about 12px. The custom pictogram is only around 35-40px in Light and has a Dark contrast/rendering failure. No imagery.
- **UTILITY ICONS:** 1 back chevron. One branded tournament pictogram, but it is not theme-safe.
- **BUTTON / INPUT / TOUCH:** Input is approximately 48px high and meets the lower bound, but is needlessly 820px wide. CTA is about 43px high, slightly below target. Back target is visually tiny.
- **ALIGNMENT / RTL:** The active progress segment starting on the right is correct for RTL. Counter position, heading/pictogram baseline, and full-width field/button do not form a refined step composition. Back chevron direction needs RTL review.
- **LIGHT / DARK:** Light is legible but flat. Dark has the serious pictogram disappearance and low-contrast field border; both lack selected/interactive surface depth.
- **RESPONSIVE:** **UNVERIFIED** - no 844x390 Golden. Wide fixed-looking measures are high risk and cannot be accepted without a compact render.
- **GAME FEEL:** Very low; it is a desktop form step.
- **LEGACY DNA:** Custom wording and pictogram hint at Ahdash, but the form pattern dominates.
- **DENSITY:** FOCUS PER STEP.
- **DECISION:** **REBUILD.** Use a real focused wizard composition, explicit step context, 48-54px controls, and theme-safe branded art.

## 21 - Tournament teams

- **PURPOSE:** Review/add tournament participants and advance to the draw.
- **PRIMARY TASK/ACTION:** Review the participant set and continue with `مراجعة القرعة`; `أضف فريقاً` is secondary.
- **FIRST FOCUS:** The 2x3 grid of bordered team cards. It reads as an admin list rather than participants in an event.
- **CURRENT PROBLEMS:** Six large boxes contain small right-aligned text and large internal voids. Borders, number circles, and repeated green checks create visual bureaucracy. Ordinary team sequence numbers use gold, contrary to the restricted gold role. The primary action is pushed to bottom-left, while the count is detached at top-right.
- **EMPTY SPACE:** Large blank band above the grid, large band below it, and unnecessary empty left space inside every card.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Team names are around 17px; member/status metadata around 12px; number badge around 44px. No team image/cover or branded participant pictogram. The box scale is large but content scale is not.
- **UTILITY ICONS:** About 9 generic utility/status glyphs: back, plus, 6 checkmarks, and the CTA chevron. This is too much repeated utility language for six simple rows.
- **BUTTON / INPUT / TOUCH:** `أضف فريقاً` is about 37px high and fails the minimum. The CTA is about 43px high and borderline. Cards are large enough to touch but do not clearly advertise an edit/select action. No inputs shown.
- **ALIGNMENT / RTL:** Grid sequence correctly reads 1,2 then 3,4 then 5,6 from right to left. Primary action placement at the far left contradicts RTL progression and appears attached to the left column only.
- **LIGHT / DARK:** Lime metadata is weaker in Light; Dark cards have only slight tonal separation from canvas. Thin borders remain dominant in both themes.
- **RESPONSIVE:** **UNVERIFIED** - no 844x390 Golden. A 2-column, 3-row grid plus header/actions is high-risk at compact height.
- **GAME FEEL:** Low; administrative participant management.
- **LEGACY DNA:** Mostly palette/logo. No strong Ahdash event character.
- **DENSITY:** DENSE / LIST.
- **DECISION:** **REBUILD.** Replace bordered admin boxes with clean participant rows, larger team identity/status, fewer icons, and one correctly aligned progression action.

## 22 - Tournament draw

- **PURPOSE:** Confirm ready teams and run the tournament draw.
- **PRIMARY TASK/ACTION:** Trigger `اعمل القرعة وابدأ`; back/exit is secondary.
- **FIRST FOCUS:** Custom draw pictogram and `ثبّت طريق البطولة`, balanced against the ready-team list. This is the clearest pre-draw composition in the tournament set.
- **CURRENT PROBLEMS:** Event feeling is static and the four pill rows are repetitive. The supporting sentence is small and mixes `BYE` into Arabic. Only the before-draw state is demonstrated; pairings-as-hero after the draw is not visible here.
- **EMPTY SPACE:** Wide view retains large vertical breathing room, but it is more intentional than other screens because the two sides form a balanced event stage. Compact removes the tertiary sentence appropriately.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Pictogram is roughly 105-110px wide and significant; compact reduces it to around 80px. Wide title is around 32-34px. Team labels and support copy are modest. No image is required.
- **UTILITY ICONS:** 1 ambiguous hollow-square glyph in the top-right. No unnecessary icons in the team list.
- **BUTTON / INPUT / TOUCH:** CTA is approximately 360x72 wide and 360x56 compact - the strongest touch treatment in this set. Team rows are about 43px wide-view and 36px compact; acceptable if display-only, too small if interactive.
- **ALIGNMENT / RTL:** Teams on the right and draw action on the left create a valid right-to-left read. Main content axes are coherent. The navigation square remains ambiguous.
- **LIGHT / DARK:** High contrast and consistent inversion. Dark still uses one near-black canvas and relies on outlines, but the pictogram remains theme-safe.
- **RESPONSIVE:** Good. 844x390 reflows proportions and removes tertiary copy rather than shrinking the title/CTA. Header and row text are still small, but core action remains 56px.
- **GAME FEEL:** Medium and the best among screens 19-27; a controlled draw animation and post-draw hero pairing are still needed.
- **LEGACY DNA:** Strong custom Ahdash draw pictogram and concise Arabic headline.
- **DENSITY:** FOCUS before draw; MEDIUM after pairings exist.
- **DECISION:** **REFINE.** Preserve the core composition/pictogram; improve event states, motion, ready-team treatment, and post-draw pairings.

## 23 - Tournament bracket

- **PURPOSE:** Explain round progression, winners, byes, and the next playable match.
- **PRIMARY TASK/ACTION:** Understand the bracket and open/select the relevant match. The current screen exposes no clear primary action beyond small round tabs.
- **FIRST FOCUS:** Four separate match boxes. There is no visible path that makes any one progression or active match the hero.
- **CURRENT PROBLEMS:** This is not a convincing bracket. Cards in two columns do not connect. A long horizontal line with a central vertical stub and `يتأهل إلى نصف النهائي` is detached from the matches. Round ownership is unclear, winner path is absent, `BYE` is untranslated, and ordinary progression is outlined in gold. Tabs are tiny.
- **EMPTY SPACE:** The middle and lower canvas contain large gaps without meaningful connector paths. Cards themselves are tall but contain only two small lines.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Team names are about 15-16px; tabs about 13-14px. Card height is roughly 112px, but content does not use it. No imagery/pictogram is needed; the missing visual is the bracket geometry itself.
- **UTILITY ICONS:** 2: back chevron and active-tab checkmark.
- **BUTTON / INPUT / TOUCH:** Round tabs appear near 30px high and fail touch minimum. Match cards are large but their clickability and current status are not apparent. No clear primary CTA.
- **ALIGNMENT / RTL:** A true RTL bracket should visibly progress from early rounds on the right toward the final on the left. Current columns and center line do not express direction or convergence.
- **LIGHT / DARK:** Dark offers slight card separation but still depends on borders. Gold outlines are overused in normal bracket states; active green is too subtle.
- **RESPONSIVE:** **UNVERIFIED** - no 844x390 Golden. This layout cannot be assumed to fit; round-focused mode is necessary for larger brackets and low height.
- **GAME FEEL:** Low. It feels like four boxes and a note, exactly the stated failure condition.
- **LEGACY DNA:** Weak; no recognizable Ahdash bracket language beyond colors/logo.
- **DENSITY:** DENSE.
- **DECISION:** **REBUILD.** Use actual connectors, RTL round progression, active/winner paths, clear match states, and round-focused responsive behavior.

## 24 - Tournament semifinal

- **PURPOSE:** Show the semifinal stage and its two pairings.
- **PRIMARY TASK/ACTION:** Understand or open one of the semifinal matches. No current action/status makes either pairing actionable.
- **FIRST FOCUS:** Two equal outlined match boxes; neither is active.
- **CURRENT PROBLEMS:** It is the Bracket shell with fewer boxes, not a distinct screen. Two pairings sit high on the canvas and a detached `يتأهل إلى النهائي` line/button sits far below. No score, match status, schedule, or action exists. Tabs remain tiny.
- **EMPTY SPACE:** More than 60% of the canvas is empty; the large gap between matches and final connector carries no progression information.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Team names are around 15-16px inside 112px-high cards. No imagery or pictogram. Visual scale comes from borders rather than competition information.
- **UTILITY ICONS:** 2: back chevron and selected-round checkmark.
- **BUTTON / INPUT / TOUCH:** Round tabs are about 30px high and fail touch minimum. The `يتأهل إلى النهائي` element reads like a button but does not explain whether it is interactive.
- **ALIGNMENT / RTL:** Pairings are horizontally balanced but do not converge into a final in either RTL or LTR direction. The connector is centered and unrelated to card edges.
- **LIGHT / DARK:** Same flat/border-heavy behavior as Bracket; normal matches are unnecessarily gold-outlined.
- **RESPONSIVE:** **UNVERIFIED** - no 844x390 Golden. The emptiness would persist even if it technically fit.
- **GAME FEEL:** Very low; no semifinal tension or active-match state.
- **LEGACY DNA:** Redundant bracket-state DNA, not a distinct product screen.
- **DENSITY:** MEDIUM as a focused stage inside Bracket.
- **DECISION:** **MERGE into Tournament bracket.** Evidence: the Golden test maps both `bracket` and `semifinal` to the same `TournamentBracketScreen`; the router has only `/tournaments/bracket`, not a semifinal route. Retain semifinal as a round state/tab, not as a standalone screen/catalog entry.

## 25 - Tournament final

- **PURPOSE:** Show the final pairing and route the player to the actual final match.
- **PRIMARY TASK/ACTION:** Understand/open the final. The current state provides neither a clear open-match action nor match status.
- **FIRST FOCUS:** One 480x111 outlined card containing two small team names.
- **CURRENT PROBLEMS:** This is the emptiest screen in the audited set. It duplicates both the Final tab inside Bracket and the pairing shown by Tournament Match, but removes VS, match metadata and CTA. Header still says `4 فرق`, which does not help the final context. There is no final-event emphasis.
- **EMPTY SPACE:** More than 80% of the 1280x720 canvas is unused around a single small card.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Team names remain about 15-16px. No image, pictogram, score or stage visual. The card is larger than its content but the final itself feels tiny.
- **UTILITY ICONS:** 2: back chevron and selected-round checkmark.
- **BUTTON / INPUT / TOUCH:** Round tabs are near 30px high and fail touch minimum. The final card has no visible action affordance.
- **ALIGNMENT / RTL:** Centering is mechanically clean, but there is no directional progression or relationship to the actual Tournament Match screen.
- **LIGHT / DARK:** Same flat/border-heavy state; gold outline is used without winner/special achievement yet.
- **RESPONSIVE:** **UNVERIFIED** - no 844x390 Golden. A compact render would merely expose the same missing content unless merged.
- **GAME FEEL:** Near zero; it does not feel like a final.
- **LEGACY DNA:** Pure duplicate/state artifact.
- **DENSITY:** FOCUS if represented as the final round inside Bracket.
- **DECISION:** **MERGE into Tournament bracket and remove as a standalone catalog screen.** Evidence: `finalMatch` Golden uses the same `TournamentBracketScreen(initialRound: 2)` and there is no final route. Starting/playing the final belongs to `TournamentMatchScreen`.

## 26 - Tournament match

- **PURPOSE:** Present a ready tournament pairing, start its game, or record an external result.
- **PRIMARY TASK/ACTION:** `ابدأ المباراة`; `تسجيل نتيجة خارجية` is secondary.
- **FIRST FOCUS:** Gold VS and the two team names. The hierarchy is understandable.
- **CURRENT PROBLEMS:** At 1280 the whole competition occupies a narrow center cluster. The same eagle pictogram is repeated for both teams, so it adds decoration rather than identity. Gold is used for normal team/VS content despite the restricted gold role. Round metadata is tiny, and the CTA contains the same ambiguous hollow-square glyph seen in navigation.
- **EMPTY SPACE:** More than half of the wide canvas is unused around the centered matchup. Compact is far more balanced.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Wide team names are roughly 36-40px and VS about 54px; pictograms around 55-60px; player names/rules/round metadata are 12-16px. Individual elements are readable, but the entire unit remains too small for the canvas. Compact reduces team/pictogram/action scale.
- **UTILITY ICONS:** 2 ambiguous hollow-square glyphs: top-right navigation and inside the primary CTA. Team eagles are pictograms, not utilities.
- **BUTTON / INPUT / TOUCH:** CTA is approximately 312x44 wide and 236x40 compact; compact falls below target. Secondary action is a lime text link without a visible target. No inputs.
- **ALIGNMENT / RTL:** Symmetry and right-team/left-team order are understandable. Round metadata, matchup, rules, and action row use separate vertical groups and need tighter event composition. Utility icon semantics are unclear in RTL.
- **LIGHT / DARK:** Both are highly legible but flat. Gold contrast is strong yet semantically overused. Dark has no surface depth.
- **RESPONSIVE:** 844x390 correctly preserves team names, VS, rules and CTA without scroll and is one of the better compact layouts. It still shrinks CTA to 40px and keeps tertiary metadata/utility icons too small.
- **GAME FEEL:** Medium. VS gives competition, but the static, undersized group lacks match-event presence.
- **LEGACY DNA:** Custom tournament pictogram direction is present, but duplicated team art and generic square icons reduce ownership.
- **DENSITY:** FOCUS.
- **DECISION:** **RECOMPOSE.** Enlarge and unify Team A - VS/score - Team B, make round metadata secondary, use meaningful team identity, and make the CTA unmistakable.

## 27 - Tournament champion

- **PURPOSE:** Celebrate the champion and close/share the tournament.
- **PRIMARY TASK/ACTION:** Current primary is `تم`; `سجل البطولة` is secondary. Required final score/share actions are absent.
- **FIRST FOCUS:** Gold champion pictogram followed by `الأساطير`. This is the strongest Ahdash focus in the tournament sequence.
- **CURRENT PROBLEMS:** The group remains a narrow stack in a huge wide canvas. Tournament title lives separately in the header rather than forming the winning unit. Final score and Share are missing. Actions are small and asymmetric, and the moment is static rather than celebratory.
- **EMPTY SPACE:** More than half of the wide canvas is unused. Compact is better filled but reveals scale compromises.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Wide gold pictogram is around 128px and meets the intended champion range; compact reduces it to roughly 85-90px. Champion name is strong at display size; result metadata is small. No image is necessary, but the pictogram/name/title/score must act as one unit.
- **UTILITY ICONS:** 1 ambiguous top-right hollow-square glyph. Share is absent, so there is no valid share control to audit.
- **BUTTON / INPUT / TOUCH:** `تم` is approximately 280x44 wide and 236x40 compact. Compact misses the touch minimum. `سجل البطولة` is a text link without a visible hit area. No inputs.
- **ALIGNMENT / RTL:** Center alignment of the winning unit is stable, but the header title and action row are disconnected. Secondary action sits left of the CTA without an integrated action hierarchy.
- **LIGHT / DARK:** Gold is semantically correct and consistent in both themes. Both canvases remain flat; Dark especially needs subtle depth/event lighting without becoming blue-black.
- **RESPONSIVE:** 844x390 fits cleanly without scroll, but shrinks the champion pictogram and CTA below the intended scale and still lacks score/share.
- **GAME FEEL:** Medium. It communicates a winner but not a full tournament victory moment.
- **LEGACY DNA:** Strongest original Ahdash DNA in this audit segment.
- **DENSITY:** FOCUS.
- **DECISION:** **RECOMPOSE.** Keep the gold pictogram; integrate tournament title, champion name, final score, Share and Done into one larger victory composition.

## 28 - Match setup

- **PURPOSE:** Choose a match format and begin the selected mode.
- **PRIMARY TASK/ACTION:** Current selection is `تدريب فردي`, followed by `يلا نبدأ التدريب`. Other formats are secondary choices.
- **FIRST FOCUS:** `كيف ودك تلعب؟` and the lime-selected rightmost card. However, four equal columns compete almost equally.
- **CURRENT PROBLEMS:** Four tall equal boxes are template-driven and mostly empty. Meaningful labels sit at the bottom of each card, forcing long eye travel. Selection is conveyed by a radio plus a large green slab, not by meaningful mode identity. A tiny `موثقة` chip and footer line are detached/near the lower frame, and the CTA sits under the far-left card rather than the selected rightmost mode.
- **EMPTY SPACE:** Most card area is blank; empty space has been converted into empty containers rather than meaningful composition.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Main heading is strong around 36-38px; mode names about 20px; descriptions about 13-14px. No mode imagery or Ahdash pictograms. Radios are small relative to huge cards.
- **UTILITY ICONS:** 4 radio/status circles. They are generic and do not provide mode recognition.
- **BUTTON / INPUT / TOUCH:** Cards are large touch targets and CTA is around 300x51, but CTA placement falsely associates it with the left card. Radio glyphs are about 22px. No inputs.
- **ALIGNMENT / RTL:** Mode order reads right-to-left correctly. The primary action at bottom-left is misaligned with the selected rightmost card and breaks the decision flow. Lower chip/footer alignment appears clipped or accidental.
- **LIGHT / DARK:** Selected state is clear, but Light uses a large pale-green slab and Dark a large dull-green slab. Outer/card borders dominate; unselected Dark cards blend into canvas.
- **RESPONSIVE:** **UNVERIFIED** - no 844x390 Golden. Four columns plus heading/footer is very high-risk at compact height and likely requires a different composition, not scaling.
- **GAME FEEL:** Low. It is a generic mode selector, not a confident game launch.
- **LEGACY DNA:** Weak; logo/lime are the only recognizable traits.
- **DENSITY:** MEDIUM.
- **DECISION:** **REBUILD.** Give one primary mode dominant treatment and secondary modes a compact, purposeful hierarchy; do not retain four equal tall cards.

## 29 - Solo setup

- **PURPOSE:** Choose categories and challenge settings, then start a Solo challenge.
- **PRIMARY TASK/ACTION:** Select one or more categories and press `ابدأ التحدي`; difficulty, opponent level and question count are secondary configuration.
- **FIRST FOCUS:** Two competing systems: category selection on the right and a large settings panel on the left. Neither owns the flow.
- **CURRENT PROBLEMS:** It looks like a settings/dashboard. Two giant category rows contain tiny labels/icons and large voids. The left panel contains tiny segmented controls separated by empty space, while `0 محدد` floats outside its top edge. Repeated generic football icons do not create category identity. The screen does not reuse Party category/game language.
- **EMPTY SPACE:** Large empty zones inside both category rows and through the middle of the settings panel. Content is small despite the panel occupying roughly one-third of the page.
- **SCALE / TYPOGRAPHY / IMAGE / PICTOGRAM:** Page title is around 26-28px; panel title about 22px; control labels about 12-15px. Category rows are roughly 136px high but contain no covers/images. Generic football glyphs are about 20px and too small/repetitive to be category pictograms.
- **UTILITY ICONS:** About 7 generic glyphs: 2 radios, 2 football category icons, dropdown arrow, question-count icon, and football icon in the CTA.
- **BUTTON / INPUT / TOUCH:** CTA is roughly 354x37 and fails the minimum. Segmented rows are about 32px high and also fail. Category rows are large enough to touch; question-count selector is closer to acceptable height.
- **ALIGNMENT / RTL:** Labels and category names are right-aligned, but the settings panel on the left and start action at its bottom interrupt the natural select-right-to-configure-to-start flow. Selected count is not aligned to the panel header.
- **LIGHT / DARK:** Raised settings panel has some tonal separation, but the main canvas remains flat. Lime `0 محدد` is weak on Light. Dark segmented selected states are subtle and utility outlines are low contrast.
- **RESPONSIVE:** **UNVERIFIED** - no 844x390 Golden. The fixed two-column dashboard is high-risk; a compact flow should stack/reprioritize without shrinking controls.
- **GAME FEEL:** Very low; it is a control panel.
- **LEGACY DNA:** Strong legacy/admin DNA. The route is active, but visually it is a separate old Solo system rather than Ahdash Party language.
- **DENSITY:** MEDIUM.
- **DECISION:** **REBUILD.** If Solo remains, reuse the Party category visual language and present only the essential settings around one clear start action.

---

## Semifinal / Final product decision

The visual and route audit resolves the ambiguity:

1. `semifinal` and `finalMatch` are not independent routes.
2. The Golden harness renders `bracket` and `semifinal` with the same `TournamentBracketScreen`; `finalMatch` is the same screen with `initialRound: 2`.
3. The router exposes `/tournaments/bracket`, `/tournaments/match/:matchId`, and `/tournaments/champion`; it has no semifinal/final route.
4. Therefore, the useful product states are **Bracket round states/tabs**, not screens 24 and 25 as separate catalog entries.

**Final decision:** MERGE both into the rebuilt Bracket, keep their round state/data, and remove their standalone screen/catalog treatment. Do not spend a separate polishing pass on them.

## Five most critical issues

1. **Bracket architecture fails visually:** Screen 23 has no real connectors, RTL progression, active winner path, or obvious playable match. Screens 24/25 amplify the same failure with extreme emptiness.
2. **Administrative/form composition dominates:** Create Tournament, Tournament Teams, Match Setup and Solo Setup use small content inside huge fields/cards/panels. They feel like web/admin tooling, not a game.
3. **Primary action hierarchy is fragmented:** Result actions split across opposite corners; Hub uses an ultra-wide thin CTA; Teams places progression bottom-left; Champion omits score/share; Match/Champion compact CTAs drop to about 40px.
4. **Scale is inconsistent with the canvas:** Saved Games, Hub, Create, Tournament Match and Champion rely on narrow central clusters or micro-metadata while large areas remain unused. Large containers often hide tiny typography rather than making content important.
5. **Responsive/theme/accessibility proof is incomplete:** Nine of these fourteen screens have no 844x390 Golden. Existing compact renders expose sub-44px controls; several screens use ambiguous hollow-square utility glyphs; Create Tournament loses its pictogram in Dark; Dark surfaces are frequently one flat sheet; lime micro-text is weak in Light.

