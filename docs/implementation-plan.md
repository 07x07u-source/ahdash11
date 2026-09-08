# خطة تنفيذ إعادة تصميم اللعبة

تاريخ التحديث: 2026-08-28. هذه خطة تنفيذ مرتبطة بالتدقيق الفعلي، وليست قائمة ادعاءات.

## مبادئ القرار

1. authority/security قبل الشكل.
2. تطوير المكونات الحالية بدل parallel rewrite.
3. vertical slice واحد قابل للاختبار قبل توسيع المودات.
4. mode غير مكتمل يكون feature-flagged أو `قريبًا` بلا route مكسور.
5. لا build release قبل انتهاء الفحوصات؛ لا Emulator أو remote push.

## Phase 0 — Audit and research

- [x] حماية working tree وقراءة القيود.
- [x] route/screen/theme/dependency/asset/test inventory.
- [x] data flow وRLS/admin audit.
- [x] baseline analyze/test/APK facts.
- [x] بحث رسمي تقني وUX وfootball sources موثق.
- [x] قرارات Flutter/Flame وRive/Spine في ADRs.

Exit: وثائق audit/research/architecture/plan موجودة؛ لا visual rewrite بدأ قبل هذا القرار.

## Phase 1 — Design system and typography

- [x] إضافة Noto Kufi Arabic وTajawal محليًا من مصدر OFL رسمي مع license files، بأقل weights عملية.
- [x] تطوير `AppTypography`, semantic palette, motion tokens، وFlame visual adapter.
- [x] مكونات foundation: game tile/header/timer/score/answer/player11/badges/states.
- [x] tests لـRTL/text scale/reduced motion/theme في الشاشات الأساسية.

Exit: لا runtime Google Fonts؛ sample components تستخدم tokens ولا hex/random spacing جديدة.

## Phase 2 — Information architecture

- [x] AppShell tabs: home/play/teams/ranking/profile.
- [x] store بقي route ثانوي؛ deep links الحالية بقيت.
- [x] Home game-first مع CTA فوق الطي وحالات data.
- [x] Play Hub يفصل Game Type عن Game Format.
- [x] Game setup موحد مع progressive disclosure؛ practice واضح، والـcompetitive يستعمل server flow.
- [x] route/navigation وlarge-text tests.

Exit: خمسة tabs، CTA واضح، no broken route، 360px/large-text قابلان للبناء.

## Phase 3 — Classic vertical slice

- [x] Domain: `GameType`, `GameFormat`, session/view state، answer submission/verdict.
- [x] Application: controller مستقل، clock قابل للحقن، input lock، idempotency/sequence، reconnect.
- [x] Infrastructure: adapter فوق online match gateway؛ migration/Edge changes محلية فقط.
- [x] Presentation: `GameWidget` ثابت للمسرح والمؤثرات وFlutter overlay للسؤال والأجوبة.
- [x] Results تعرض server values فقط؛ Practice results منفصلة.
- [x] unit/widget/flame tests.

Exit: لا correct-answer leak في contract، tap واحد، server verdict، recovery/error states. إن لم تطبق migration Remote فلا يوصف E2E remote بأنه مكتمل.

## Phase 4 — Core modes

1. [x] True/False: خياران، 10 ثوانٍ، pool مستقل، payload/validation/admin/tests.
2. [x] Speed: يعيد Classic بأجل خادم 7 ثوانٍ وفصل matchmaking.
3. [ ] Ordering ثم Club Guess ثم Eagle Eye: ظاهرة `قريبًا` بلا route مكسور حتى اكتمال data/admin/rights.

كل mode يمر Definition of Done. الافتراضي عند نقص backend/admin/data هو flag off و`Partial`.

## Phase 5 — Player 11 and feedback

- [x] أصول male/female original/generated-safe بالحجم الموثق.
- [x] static fallback؛ Rive مؤجل لأنه لا يوجد `.riv` فعلي.
- [x] SystemSound/haptics فقط؛ لا `flame_audio` بلا أصول.
- [x] Flame particles bounded مع reduced motion؛ لا shader/camera effect ثقيل.

Exit: paths/rights/sizes/use sites موثقة، lifecycle/dispose tested.

## Phase 6 — Product screens

- [x] onboarding يختار Player11 ويحفظه، مع تأجيل الدوري/النادي الصريح لما بعد الدخول.
- [x] profile كـplayer card.
- [x] grouped settings + notification defaults fix + danger zone.
- [x] league/club picker يستعيد القيم الخاصة ويبحث عربي/إنجليزي مع rights-aware badges.
- [x] results polish.

## Phase 7 — Social/football/admin

- [x] الاستراحة/friends/team/leaderboard/MVP hierarchy polish دون تغيير permissions.
- [x] موقع اللاعب مثبت في leaderboard حتى إن كان خارج أول 100.
- [x] official six-league source mapping موثق؛ لا seed قبل validation/rights.
- [x] admin editor يدعم Classic وTrue/False فقط، وهما المودان ذوا عقود أسئلة فعلية.
- [x] كل schema change في `20260828000400_gameplay_contract_v2.sql` محليًا، بلا remote push.

## Phase 8 — Hardening and release

- [x] `dart format .`
- [x] `flutter analyze --fatal-infos`
- [x] `flutter test`
- [x] Admin: `npm test`, `npm run lint`, `npm run typecheck`, `npm run build`.
- [x] Edge عند التغيير: `deno fmt`, `deno check`.
- [x] SQL parser/PLpgSQL/security/RLS/search_path tools المحلية؛ live pgTAP بقي صريحًا pending.
- [x] asset/APK size review؛ النتيجة 84.37 MiB وأقل من 110MB.
- [x] build واحد نهائي: `flutter build apk --release --dart-define-from-file=.env`.
- [x] package/signature/certificate/size/hash verification؛ بلا install أو Emulator.

## مسار التراجع الآمن

- كل feature جديدة لها flag أو route-compatible fallback.
- عدم تعديل migrations القديمة يتيح تطبيق migration الجديدة صراحة لاحقًا.
- Practice لا يعتمد على competitive API؛ تعطيل engine الجديد لا يفقد التدريب الحالي.
- لا حذف للأصول القديمة قبل إثبات عدم استخدامها وحفظ بديل.
