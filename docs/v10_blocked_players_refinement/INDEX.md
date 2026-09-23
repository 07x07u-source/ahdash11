# AHDASH 11 — 13 Blocked players refinement

## التحسينات

- بطاقة خصوصية مختصرة بألوان أخضر داكن وعاجي، مع رسم حصري شفاف يجمع الدرع ولاعب الكرة ويعبّر عن مساحة شخصية مريحة بدل الإحساس التحذيري.
- حالة فارغة برسم شفاف مستقل: درع مفتوح وكرة ولمسة ليمونية، بلا بطاقة أو مستطيل خلفي وبلا نص داخل الصورة.
- فصل بيانات اللاعب عن فك الحظر: صورة 48px، اسم حتى سطرين، معرف باتجاه LTR، وحالة منفصلة عن زر الإجراء.
- زر فك الحظر بحد أدنى 44px، يتعطل أثناء الطلب، مع حارس يمنع تكرار الطلب ونص حالة معلن لقارئ الشاشة.
- مفتاح ثابت لكل حساب حتى لا تنتقل حالة الانتظار إلى صف آخر عند تحديث القائمة.
- تمرير للقائمة كاملة، وعدّاد حقيقي، وتحديث بالسحب أو بزر واضح.
- حالات مستقلة للقائمة الفارغة والتحميل والخطأ وعدم توفر الخدمة. عدم توفر الخدمة لا يعرض قائمة فارغة على أنها نتيجة مؤكدة.
- الحفاظ على استدعاء unblock_player الحالي: لا نافذة تأكيد جديدة، ولا تغييرات على بيانات الحظر أو قواعد الحسابات أو الخلفية.
- الأسماء والنتائج الظاهرة في اللقطات بيانات اختبار محلية، وليست بيانات حسابات Production.

## التحقق

- 70/70 focused tests PASS, 0 FAIL, 0 SKIP.
- 36 render cases: 390×844 / 360×800; text scaling 100% / 130% / 200%; six states.
- Additional checks: rapid unblock submits once; disabled pending action; removal after successful response; failure preserves row and hides internal errors; retry recovers; refresh reloads; Friends/Phase D regressions.
- flutter analyze --no-pub: No issues found.
- git diff --check for changed source/test files: clean.
- Full unfiltered suite was not run. Golden PNG baselines were not updated; archived V9/V9.2 assets were not touched.
- No deployment, production mutation, APK/AAB build or Online activation.

## اللقطات

- [القائمة — 390×844](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/populated_390x844_scale1.0.png) · [360×800](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/populated_360x800_scale1.0.png)
- [القائمة الفارغة — 390×844](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/empty_390x844_scale1.0.png) · [360×800](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/empty_360x800_scale1.0.png)
- [التحميل — 390×844](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/loading_390x844_scale1.0.png) · [360×800](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/loading_360x800_scale1.0.png)
- [تعذر التحميل — 390×844](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/error_390x844_scale1.0.png) · [360×800](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/error_360x800_scale1.0.png)
- [جارٍ فك الحظر — 390×844](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/busy_390x844_scale1.0.png) · [360×800](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/busy_360x800_scale1.0.png)
- [الخدمة غير متاحة — 390×844](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/unavailable_390x844_scale1.0.png) · [360×800](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/unavailable_360x800_scale1.0.png)

[قبل التعديل](C:/dev/ahdash11/docs/v10_blocked_players_refinement/before/populated_390x844.png)

![القائمة بعد التعديل](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/populated_390x844_scale1.0.png)

![القائمة الفارغة](C:/dev/ahdash11/docs/v10_blocked_players_refinement/account/empty_390x844_scale1.0.png)

## الملفات المعدلة في هذه الجولة

- mobile/lib/features/social/presentation/blocked_players_screen.dart
- mobile/assets/visuals/blocked_privacy_hero_v1.png (transparent generated hero artwork)
- mobile/assets/visuals/blocked_empty_calm_v1.png (transparent generated empty-state artwork)
- mobile/test/fixtures/fake_social_repository.dart (blocked-list error/load-count controls for tests only)
- mobile/test/features/social/friends_block_workflow_test.dart (retry/refresh regression)
- mobile/test/visual/blocked_players_refinement_test.dart (new review renders and state tests)
- mobile/test/visual/v10_phase_d_golden_test.dart (precache the new artwork in the existing visual harness)
- docs/v10_blocked_players_refinement/ (report, preserved before screenshot, 36 current screenshots)
- docs/v10_complete_ui_atlas/13_blocked_players/ (two current preview screenshots)

Existing unrelated workspace changes preserved. The two new raster assets were generated in built-in ImageGen mode and verified to contain real alpha transparency.

## Reproduce

flutter test --no-pub --dart-define=UI_REVIEW_DIR=C:\\dev\\ahdash11\\tmp\\blocked_players_final test/visual/blocked_players_refinement_test.dart test/features/social/friends_block_workflow_test.dart test/v10_phase_d/phase_d_widgets_test.dart --reporter expanded

flutter analyze --no-pub
