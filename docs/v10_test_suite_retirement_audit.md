# V10 maintained test-suite retirement audit

## Result

The H.1 baseline was 608 completed results: 476 pass, 132 fail. A fresh
machine-readable run after Team Splitter changes produced 590 pass and 124
fail completion events. Exactly 121 current failures belonged to obsolete
visual suites (six legacy `setUpAll` failures plus 115 V9.2 Golden mismatches).
Three failures were maintained tests with stale copy assertions; those were
updated in place and were not archived.

Ten obsolete sources were preserved verbatim at
`docs/archive/testing/v9_v9_2/source/`. They declare 940 generated tests; many
never emitted individual results because the removed Serif failed `setUpAll`.
No Golden was regenerated, no font was restored, and no assertion was skipped.

| Old test / exact group inventory | Declared | Obsolete reason | Active V10 replacement | Unique coverage preserved? | Action |
|---|---:|---|---|---|---|
| `all_pages_golden_test.dart`: `gallery {17 pages} {800x360,844x390,915x412,1280x720,1366x768} {light,dark}` + `gallery portrait smoke {17 pages}` | 187 | Pre-V10 gallery; four Landscape families, Dark mode and removed Serif; `setUpAll` failed. | V10 Phase A-E Goldens + maintained feature widget tests. | Yes; portrait/state/error behavior has stricter active owners. | Archived source. |
| `image_first_golden_test.dart`: 12 named screens × six sizes × light/dark | 144 | Pre-V10 image-first experiment, Landscape/Dark and removed Serif; `setUpAll` failed. | V10 A/D/E Goldens + Auth/Home/Match/Profile/Premium tests. | Yes; image comparison only. | Archived source. |
| `party_game_golden_test.dart`: `party {home,howTo,categories,categoryDetail,teams,teamSplitter,helpers,ready}` × five Landscape sizes × light/dark | 80 | V9-era Party contact set and removed Serif; `setUpAll` failed. | V10 Phase B + Party setup/flow/controller/gameplay tests. | Yes; optional splitter and real behavior remain asserted. | Archived source. |
| `v7_checkpoint_golden_test.dart`: V7 checkpoint; V8 checkpoint/phases 2-4; V8.1 pictograms; V8.2 checkpoint at 844x390/1280x720 light/dark | 272 | Explicit V7/V8 Landscape baseline history and removed Serif; `setUpAll` failed. | V10 A-E, active pictogram Golden, feature/contract tests. | Yes; fixtures contain no unique domain rule. | Archived source. |
| `v8_2_checkpoint_golden_test.dart`: 13 screens × 844x390/1280x720 × light/dark | 52 | Explicit V8.2 Landscape/Dark checkpoint and removed Serif; `setUpAll` failed. | V10 A-E and Party/Tournament/Account regressions. | Yes. | Archived source. |
| `v9_checkpoint_golden_test.dart`: `V9 checkpoint {18 screens}` × two Landscape sizes × light/dark + `V9 portrait smoke {18 screens}` | 90 | Explicit V9 baselines and removed Serif; `setUpAll` failed. Portrait smoke only checked no exception. | V10 A-E Goldens and portrait contracts. | Yes; active responsive tests are stricter. | Archived source. |
| `v9_2_phase2_golden_test.dart`: `V9.2 Phase 2 {launch,onboarding,signIn,createAccount,home}` × five Landscape sizes | 25 | All 25 obsolete V9.2 Golden comparisons failed. | V10 A + Auth/Home/Onboarding feature and portrait tests. | Yes. | Archived source. |
| `v9_2_phase3_golden_test.dart`: `V9.2 Phase 3 {categories,categoryDetail,teams,splitter,helpers,ready}` × five Landscape sizes | 30 | All 30 obsolete V9.2 Golden comparisons failed. | V10 B + Party setup/flow/controller tests. | Yes; Team Splitter also covers five portrait sizes, text 1.0/1.2/1.3, long Arabic names and 300px keyboard. | Archived source. |
| `v9_2_phase4_golden_test.dart`: `V9.2 Phase 4 {board,textQuestion,imageQuestion,reveal,result}` × five Landscape sizes | 25 | All 25 obsolete V9.2 Golden comparisons failed. | V10 B + Party gameplay/question/controller tests. | Yes. | Archived source. |
| `v9_2_phase6_golden_test.dart`: six account/utility screens × five Landscape sizes + five 844x390 state variants | 35 | All 35 obsolete V9.2 Golden comparisons failed. | V10 D/E + maintained account/utility feature tests. | Yes; loading/empty/unavailable states remain active. | Archived source. |

Retirement total: `187+144+80+272+52+90+25+30+25+35 = 940` declared tests in 10 sources.

## Still-valid maintained assertions found

- `test/features/game/play_hub_widget_test.dart`: two active tests retained their
  Team/Solo, deferred Online, CTA, large-Arabic-text and no-overflow assertions;
  only retired labels were synchronized with production V10.
- `test/features/onboarding/onboarding_screen_test.dart`: the four-concept test
  remains active and now asserts `اختار الفئات`, `كوّن الفرق`, `جاوب`, and
  `احسم الفوز`; persistence, skip and navigation assertions are unchanged.

No still-valid assertion existed only in the archived sources.

## Maintained full-suite certification

After archival and assertion synchronization, the normal unfiltered command
`flutter test --reporter compact --concurrency=1` completed **490/490 passed,
0 failed, 0 skipped**. `flutter analyze` completed with **No issues found**.
