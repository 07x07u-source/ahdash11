# AHDASH 11 — Party setup hero refinement

## النتيجة

تحسين بصري للأجزاء الأربعة المطلوبة فقط. صور قمصان وتشكيلة بخلفية شفافة فعلية، وملعب هادئ لمعاينة المواجهة. لم تتغير قواعد التوزيع، أسماء الفرق، ألوانها المختارة، عدد اللاعبين، سقف المساعدات، أو بدء الجلسة.

- شريط الفريقين: منطقتا لمس واضحتان، حالة selected لقارئ الشاشة، اسم مستقل عن عداد المساعدات، وشارة اكتمال مرتبطة بالعدد الحقيقي.
- بطاقتا الفرق والتشكيلة: صور زخرفية منفصلة عن النصوص والبيانات، ارتفاع يتكيف مع تكبير الخط، ومسافات موحدة.
- معاينة المواجهة: ملعب جديد، تباين هادئ، شارات بتدرج من لون الفريق الحقيقي، أسماء حتى سطرين، وحالة عدد اللاعبين الحقيقية.
- إخفاء صورة تكوين الفرق عند فتح لوحة المفاتيح لتخصيص المساحة للإدخال.
- اختبار لوحة المفاتيح أصبح يستخدم أبعاد View الحقيقية ويمرر للحقل قبل لمسه؛ لم تُحذف اختبارات الوصول أو تضعف شروطها.

## اللقطات

Flutter widget renders from current code using fixture data, not production data and not Figma exports. Keyboard renders simulate a 300px inset; they do not include a real OS keyboard.

### تكوين الفرق

[390×844](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/08_teams_390x844_scale1.0.png) · [360×800](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/08_teams_360x800_scale1.0.png)

![تكوين الفرق](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/08_teams_390x844_scale1.0.png)

### تقسيم اللاعبين

[390×844](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/09_splitter_390x844_scale1.0.png) · [360×800](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/09_splitter_360x800_scale1.0.png)

![تقسيم اللاعبين](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/09_splitter_390x844_scale1.0.png)

### اختيار المساعدات

[390×844](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/10_helpers_390x844_scale1.0.png) · [360×800](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/10_helpers_360x800_scale1.0.png)

![اختيار المساعدات](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/10_helpers_390x844_scale1.0.png)

### المجلس جاهز

[390×844](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/11_ready_390x844_scale1.0.png) · [360×800](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/11_ready_360x800_scale1.0.png)

![المجلس جاهز](C:/dev/ahdash11/docs/v10_party_setup_heroes_final/party/11_ready_390x844_scale1.0.png)


36 renders cover 390×844 and 360×800 at 100%, 130%, and 200%, including team-name and splitter keyboard states. Long content scrolls; decorative artwork is excluded from screen-reader semantics.

## Validation

- Focused run: 83 passed, 0 failed, 0 skipped (36 render checks + 47 existing widget/domain/flow checks).
- flutter analyze --no-pub: No issues found.
- No Golden PNG was regenerated in this iteration; archived V9/V9.2 references untouched. This is a visual review iteration, not a full-suite or visual-baseline approval claim.
- Existing Drift diagnostic about multiple in-memory database instances appeared in tests; it did not fail the tests.
- No backend changes, deployment, APK/AAB, or release actions.

Command: flutter test --no-pub --dart-define=UI_REVIEW_DIR=C:\\dev\\ahdash11\\tmp\\party_setup_hero_final test/visual/party_setup_hero_screenshot_test.dart test/features/party/party_setup_widget_test.dart test/features/party/party_setup_flow_test.dart test/features/party/party_helpers_full_qa_test.dart test/v10_phase_b/v10_party_portrait_contract_test.dart --reporter expanded

## Files changed in this refinement

- mobile/lib/features/party/presentation/party_setup_screens.dart
- mobile/test/features/party/party_setup_widget_test.dart
- mobile/test/visual/v10_phase_b_golden_test.dart (optional case registration for the dedicated screenshot harness; default golden groups unchanged)
- mobile/test/visual/party_setup_hero_screenshot_test.dart
- Three assets listed below.
- This report, 36 screenshots, and four matching current atlas previews.

## Generated assets and final prompts

Mode: built-in image generation, separate generate request per asset. No fallback CLI. Project copies preserve generated alpha. The illustrative jerseys do not represent live team-color choices; actual team badges continue using state colors.

### party_team_duo_v1.png

[Saved asset](C:/dev/ahdash11/mobile/assets/visuals/party_team_duo_v1.png)

```text
Use case: stylized-concept. Create an actual transparent-alpha PNG cutout for AHDASH 11, a refined Arabic football trivia mobile game. Two miniature sculptural football jerseys floating beside each other, one muted raspberry pink and one deep emerald green, soft matte fabric with subtle realistic seams, tasteful warm ivory collar accents. Slightly angled toward one another, friendly competition, premium modern restrained 3D product illustration. Centered compact readable silhouette at 90 pixels, landscape 3:2, objects occupy 85 percent. No skin, people, hangers, names, numerals, lettering, logos, badge, platform, surrounding card, background panel, floor, glow, backdrop, checkerboard, watermark or confetti. Genuinely transparent empty pixels outside both jerseys. Soft dimensional lighting without heavy shadows.
```

### party_roster_tokens_v1.png

[Saved asset](C:/dev/ahdash11/mobile/assets/visuals/party_roster_tokens_v1.png)

```text
Use case: stylized-concept. Actual transparent-alpha cutout illustration for AHDASH 11 football team roster setup. Six elegant rounded miniature football tactics player tokens, three in acid lime #B6FF3B and three warm ivory, staggered in two balanced opposing groups of three with tasteful depth, viewed three-quarter from above. A tiny charcoal soccer ball between the groups. Premium tactile matte 3D, soft controlled studio light, simple compact composition readable at 100 pixels. Landscape 3:2, subject fills 85 percent. No pitch board, card, container, base, floor, background, backdrop, glow, checkerboard, text, letters, numbers, logos, confetti or watermark. Real transparent alpha around the individual pieces. Friendly organized football game aesthetic, not a detailed diagram.
```

### party_kickoff_arena_v1.png

[Saved asset](C:/dev/ahdash11/mobile/assets/visuals/party_kickoff_arena_v1.png)

```text
Use case: stylized-concept. Background artwork for AHDASH 11 football match READY preview. Modern minimal empty football stadium viewed from pitch-level near midfield, perfectly balanced broad perspective. Deep forest emerald and charcoal, softly glowing champagne floodlights high at upper corners, slender restrained lime center line leading toward far dark grandstand. Calm anticipation just before kickoff. Premium clean cinematic sports-game environment, subtle depth and matte detail without clutter. Landscape 3:2. Middle and lower two thirds very dark low-contrast, specifically reserved for two editable circular team badges and editable UI text. Edge-to-edge scene, no framing card or border, no players, people, ball, trophy, uniforms, words, numerals, logos, watermark, fireworks or confetti.
```
