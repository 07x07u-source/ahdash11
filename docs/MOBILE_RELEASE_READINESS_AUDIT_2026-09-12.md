# AHDASH | 11 — Mobile Release Readiness Audit

التاريخ: 2026-09-12  
النطاق: Android وiOS فقط  
نوع العمل: تدقيق أصلي، ثم مصالحة جاهزية iOS المصدرية غير البصرية؛ لم تتغير أي لوحة مزود أو قاعدة بيانات  
حالة واجهة Flutter: مجمدة بالكامل

## 1. الملخص التنفيذي

| المنصة | الحكم النهائي | الخلاصة |
|---|---|---|
| Android | **PARTIALLY_READY** | بنية المصدر الأساسية قوية، والتحليل والبوابة المشتركة الحالية ذات 584 اختبارًا غير بصري نجحت، كما توجد أدلة تاريخية على توقيع AAB/APK. لا يوجد artifact موقّع للشجرة الحالية، ولا اعتماد للصور المرجعية الحالية، ولا اختبار فعلي مكتمل للخدمات والأجهزة والمتجر. |
| iOS | **PARTIALLY_READY** | الحالة المصدرية هي `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION`: توحّدت سياسة الاختبارات، ووصلت Google/Apple flags إلى IPA، وأضيف Apple entitlement وربط callback والجودة/validator. ما زال يلزم macOS/Codemagic وApple/provider confirmation وIPA/TestFlight واختبار iPhone والمتجر. |

لا يوجد دليل كافٍ يمنح أي منصة حالة READY. نجاحات Codemagic السابقة تخص إصدار Android سابقًا ولا تثبت الشجرة الحالية، وإثبات إعداد مزود خارجي لا يثبت التشغيل على جهاز، ووجود كود متجر لا يثبت تجهيز Play Console أو App Store Connect.

### نموذج الأدلة المستخدم

| فئة الدليل | الحالة |
|---|---|
| CURRENT_TREE_LOCAL_EVIDENCE | الفرع main، الالتزام 4a9e275b7c71b0f68731373cd4add5f4a871084a، والشجرة متسخة مسبقًا بـ1464 مدخلًا قبل إنشاء هذا التقرير. التحليل وبوابة الاختبارات غير البصرية أُعيدا على الشجرة الحالية. |
| HISTORICAL_CODEMAGIC_EVIDENCE | يوجد إثبات سابق لبناء Android Release موقّع وإنشاء AAB وAPK واجتياز validator والاختبارات المختارة. لا يُعد artifact للشجرة الحالية. |
| OPERATOR_VERIFIED_PROVIDER_EVIDENCE | Supabase Production مطابق 27/27 حتى 20260908000100، وإعداد Firebase Android وRevenueCat entitlement باسم premium وAdMob cadence=3 والروابط القانونية موثقة من المشغّل. لم يُفتح أي Console في هذا التدقيق. |
| DEVICE_EVIDENCE | لا يوجد اختبار Android أو iOS فعلي للشجرة الحالية. |
| STORE_EVIDENCE | لا يوجد إثبات حالي كافٍ لقائمة متجر مكتملة أو منتجات اشتراك جاهزة أو مسار اختبار/مراجعة أو رابط متجر رسمي. |

## 2. حكم Android حسب طبقات الجاهزية

| الطبقة | الحالة | الدليل أو القصور |
|---|---|---|
| SOURCE | PARTIALLY_READY | نطاق Party الأساسي منفذ، لكن Solo يرجع إلى demoQuestions في Production عند فراغ/فشل RPC، ومسار /premium/voucher المباشر ما زال موجودًا، وتوجد عبارة مستخدم تشير إلى الأصدقاء. |
| TESTS | PARTIALLY_READY | analyze ناجح والبوابة المشتركة الحالية 584/584 اختبارًا غير بصري؛ الصور المرجعية الحالية غير معتمدة، ولا توجد E2E فعلية كافية. |
| BUILD | PARTIALLY_READY | يوجد بناء Codemagic تاريخي؛ لم يُبنَ Release للشجرة الحالية، والبناء المحلي لم يُشغّل لأن متغيرات Production المحمية غير متاحة محليًا. |
| SIGNING | PARTIALLY_READY | مسار التوقيع fail-closed ودليل الشهادة التاريخي مطابق؛ لا يوجد CURRENT_TREE_SIGNED_ARTIFACT. |
| AUTH | PARTIALLY_READY | Email وGuest وGoogle منفذة في المصدر؛ استعادة كلمة المرور غير منفذة، وGoogle غير مختبر على جهاز Release. |
| BACKEND | PARTIALLY_READY | ترحيلات Production موثقة 27/27؛ يلزم E2E حقيقي للعقود وRLS وEdge Functions والتزامن. |
| FIREBASE | PARTIALLY_READY | التهيئة وملف Android والعقود موجودة؛ وصول Analytics/Crashlytics/FCM على جهاز غير مثبت. |
| PUSH | BLOCKED | لا token أو permission أو foreground/background/terminated delivery مثبت على جهاز. |
| ANALYTICS / CRASHLYTICS | PARTIALLY_READY | التهيئة والأحداث موجودة؛ لا إثبات وصول Production، وCrashlytics يرسل الخطأ الخام دون sanitizer مماثل لمسار AppErrorReporter. |
| REVENUECAT | PARTIALLY_READY | Monthly/Annual وpremium وpurchase/restore/status منفذة؛ المنتجات والعروض والشراء والاستعادة الفعلية وwebhook غير مثبتة. |
| ADMOB | PARTIALLY_READY | UMP وinterstitial cadence وPremium bypass والحالات الفاشلة منفذة؛ لا عرض فعلي أو consent/no-fill مثبت، وprivacy-options revisit غير موصول بواجهة نشطة. |
| DEEP LINKS | PARTIALLY_READY | allowlist آمنة ومسارات Teams/Tournaments/Auth موجودة؛ المخطط المخصص غير Android App Link موثّق ملكيته، ولم تُختبر حالات cold/warm/background. |
| OFFLINE / RESUME | PARTIALLY_READY | Drift وحفظ Party والتاريخ والتفضيلات موجودة؛ fresh-install offline غير مضمون، ومزامنة البلاغات/إجابات Solo لا تُستدعى تلقائيًا كما توحي بعض التعليقات. |
| SECURITY | PARTIALLY_READY | لا أسرار متتبعة أو cleartext أو service-role في العميل؛ تبقى مخاطر Crashlytics الخام والمخطط المخصص ومسار القسيمة المباشر بحاجة إغلاق أو قبول موثق. |
| PRIVACY / LEGAL | BLOCKED | الروابط موثقة كمهيأة لدى المشغّل، لكن Data Safety ومراجعة قانونية وحقوق الوسائط وإفصاحات المزودين غير مثبتة. |
| STORE REQUIREMENTS | BLOCKED | بيانات Google Play ومسارات الاختبار والمنتجات والتصنيف والإفصاحات والمراجعة غير مثبتة. |
| DEVICE VALIDATION | BLOCKED | لم تُنفذ المصفوفة الفعلية. |
| ACCESSIBILITY | PARTIALLY_READY | RTL وSemantics وReduced Motion وتغطية responsive موجودة؛ TalkBack واللمس والتباين والنص الكبير الفعلي غير مختبرة، والتكبير مقيد إلى 1.6. |
| PERFORMANCE / FAILURE HANDLING | PARTIALLY_READY | توجد timeouts وحماية lifecycle واسعة؛ حجم assets كبير نسبيًا ولا يوجد benchmark أو قياس startup/memory/ANR على جهاز. |

### RELEASE_BLOCKERS — Android

1. منع fallback أسئلة Solo التجريبية في Production أو اعتمادها صراحة كمنتج؛ الواقع الحالي يخالف حقيقة المحتوى الإنتاجي.
2. إغلاق تسربات النطاق المؤجل/المزال: الوصول المباشر إلى /premium/voucher، وعبارة “يمكن للأصدقاء رؤية اختيارك”.
3. مراجعة خصوصية Crashlytics ومنع انتقال أخطاء/stack traces خام قد تحمل بيانات حساسة قبل تفعيله إنتاجيًا.
4. مطابقة Premium مع الحقيقة المعتمدة “فئات حصرية” و“بدون إعلانات”؛ عبارة “فئات أكثر. إعلانات أقل.” توحي بإعلانات أقل لا تجربة خالية منها.
5. اعتماد Goldens عبر تشغيل بصري مضبوط؛ الحالة الحالية تحتوي baselines معدلة/غير متتبعة و892 صورة failure.
6. إنتاج AAB/APK موقّعين من الشجرة المراد إصدارها بعد commit معروف واجتياز validator.
7. إتمام التحقق الفعلي للخدمات والأجهزة وBackend/RLS/Edge Functions.
8. إتمام Google Play وData Safety والإعلانات والتصنيف والاشتراكات والقانون وحقوق الوسائط.

### DEVICE_BLOCKERS — Android

- لا fresh install/upgrade/lifecycle/keyboard/TalkBack/weak-network/offline موثق.
- لا Google Sign-In أو Email/Guest upgrade موثق على Release موقّع.
- لا FCM أو Analytics أو Crashlytics أو RevenueCat أو AdMob موثق على جهاز.
- لا Party/Tournament/Teams/Challenge/account deletion E2E بحسابات Production-like.

### STORE_BLOCKERS — Android

- لا إثبات قائمة Google Play كاملة، Data Safety، Ads declaration، content rating، target audience، app access، مسار اختبار، منتجات Monthly/Annual أو review submission.
- Codemagic Android يولّد artifacts لكنه لا يحتوي نشرًا إلى Google Play.

### EXTERNAL_PROVIDER_BLOCKERS — Android

- نجاح Google/Firebase/FCM/Analytics/Crashlytics/RevenueCat/AdMob وwebhook وEdge Functions غير مثبت end-to-end.
- إثبات المشغّل للمتغيرات لا يساوي إثبات التشغيل أو صحة Console الحالية.

### NON_BLOCKING_IMPROVEMENTS — Android

- توفير Android App Links HTTPS موثقة بدل الاعتماد على custom scheme فقط.
- قياس startup وAPK/AAB size وذاكرة الصور وتقليل assets الكبيرة وفق نتائج القياس.
- إتاحة إعادة فتح خيارات خصوصية UMP من Settings.
- عدم تقييد system text scaling فوق 1.6 إذا أثبت اختبار الوصول الحاجة.
- تنظيف ملفات Online/Friends/landscape الخاملة في مرحلة إزالة منفصلة بعد إثبات عدم الاعتماد.

## 3. حكم iOS حسب طبقات الجاهزية

| الطبقة | الحالة | الدليل أو القصور |
|---|---|---|
| SOURCE | PARTIALLY_READY | معظم Flutter مشترك مع Android، لكن موانع Solo/voucher/Friends/Crashlytics تنطبق أيضًا. |
| TESTS | CODE_READY | iOS Release يستبعد test/visual مثل Android؛ البوابة المحلية الحالية اختارت 74 ملفًا واستبعدت 24 ملفًا بصريًا ونجحت 584/584 مع coverage. |
| BUILD | BLOCKED | IOS_BUILD_REQUIRES_MACOS_CI. لا IPA حالي ولا سجل نجاح للشجرة الحالية. |
| SIGNING | BLOCKED | YAML يتوقع App Store signing، لكن الشهادة/profile/App ID الخارجية ونجاح تطبيقها غير مثبتة. |
| AUTH | CODE_READY_EXTERNAL_VALIDATION_PENDING | Email/Guest محفوظان، وGoogle/Apple يصلان إلى أمر IPA، وApple entitlement موجود، وعودة OAuth تحدّث جلسة التطبيق؛ المزود والجهاز خارجيان. |
| BACKEND | PARTIALLY_READY | نفس Supabase المشترك؛ E2E/RLS/Functions على iOS غير مثبت. |
| FIREBASE | CODE_READY_EXTERNAL_VALIDATION_PENDING | CI يحقن plist في Runner ويتحقق من bundle/metadata ويزامن Google client/scheme؛ القيمة المحمية والتشغيل الفعلي غير مثبتين بعد. |
| PUSH | CODE_READY_EXTERNAL_VALIDATION_PENDING | aps-environment محفوظ والتهيئة/lifecycle/inbox/deep-link موجودة؛ profile/capability/APNs/FCM delivery تحتاج المزود والجهاز. |
| ANALYTICS / CRASHLYTICS | CODE_READY_EXTERNAL_VALIDATION_PENDING | المصدر والتهيئة موجودان، وأضيف dSYM upload لـRelease/Profile؛ الوصول الفعلي وsymbolication والخصوصية تحتاج التحقق الخارجي. |
| REVENUECAT | CODE_READY_EXTERNAL_VALIDATION_PENDING | مفتاح iOS العام وentitlement `premium` يصلان للبناء والvalidator؛ المنتجات/offering/purchase/restore/sandbox خارجية. |
| ADMOB | CODE_READY_EXTERNAL_VALIDATION_PENDING | CI يستبدل app ID ويمرر الوحدات/cadence ويفشل عند قيم Production غير الصالحة؛ consent والعرض الفعلي والجهاز خارجية. |
| DEEP LINKS | CODE_READY_EXTERNAL_VALIDATION_PENDING | auth custom scheme وGoogle reversed scheme جاهزان وعودة OAuth مغطاة بالاختبار؛ lifecycle والجهاز خارجيان، وUniversal Links تحسين منفصل غير مانع. |
| OFFLINE / RESUME | PARTIALLY_READY | نفس التخزين المشترك؛ لا تحقق iOS background/termination. |
| SECURITY | PARTIALLY_READY | لا أسرار متتبعة؛ يلزم إغلاق مخاطر custom scheme وCrashlytics الخام والقسيمة. |
| PRIVACY / LEGAL | BLOCKED | App Privacy/Nutrition Labels وATT decision ومراجعة قانونية وحقوق الوسائط غير مثبتة. |
| STORE REQUIREMENTS | BLOCKED | App Store Connect/TestFlight/IAP/review metadata غير مثبتة. |
| DEVICE VALIDATION | BLOCKED | لا iPhone/iPad أو TestFlight evidence. |
| ACCESSIBILITY | PARTIALLY_READY | تغطية Flutter موجودة؛ VoiceOver/Dynamic Type/touch/contrast غير مختبرة. |
| PERFORMANCE / FAILURE HANDLING | PARTIALLY_READY | لا Instruments أو startup/memory/background/crash validation. |

### REMAINING EXTERNAL RELEASE PROOF — iOS

1. تأكيد App ID/Apple capabilities/profile وSupabase Apple/Google providers وFirebase iOS/APNs والقيم المحمية الحالية وفق [IOS_EXTERNAL_LINKING_CHECKLIST.md](./IOS_EXTERNAL_LINKING_CHECKLIST.md).
2. تنفيذ build/sign/IPA/TestFlight ناجح للشجرة المرشحة على macOS/Codemagic.
3. إتمام APNs/FCM/Auth/RevenueCat/AdMob/Analytics/Crashlytics على iPhone وSandbox.
4. إتمام App Store privacy، age rating، screenshots، support/privacy URLs، IAP، review information والمراجعة القانونية.

موانع المنتج المشتركة المسجلة في التدقيق الأصلي لم تُعالج ضمن مهمة iOS integration/auth المحددة، ولا يجوز تفسير `IOS_CODE_READY_FOR_EXTERNAL_VALIDATION` على أنها اعتماد إصدار المنتج كاملًا.

### DEVICE_BLOCKERS — iOS

- لا TestFlight install أو iPhone/iPad lifecycle وVoiceOver/Dynamic Type موثق.
- لا Apple/Google/Email Auth فعلي.
- لا APNs/FCM foreground/background/terminated behavior.
- لا iOS purchase/restore/management أو ads/consent.

### STORE_BLOCKERS — iOS

- Apple Developer App ID/capabilities/certificates/profiles وApp Store Connect app غير مثبتة خارجيًا.
- لا TestFlight build ولا Monthly/Annual products ولا Sandbox receipts/webhook.
- لا App Privacy/Nutrition Labels/age rating/listing/screenshots/support URL/review information/official URL.

### EXTERNAL_PROVIDER_BLOCKERS — iOS

- Apple provider/capability/profile يحتاج تأكيدًا خارجيًا؛ entitlement ومسار CI أصبحا جاهزين.
- Firebase iOS وGoogle iOS وAPNs وRevenueCat وAdMob جاهزة مصدرًا، لكنها ليست تشغيلًا مثبتًا حتى Codemagic/TestFlight/iPhone.

### NON_BLOCKING_IMPROVEMENTS — iOS

- Universal Links وAssociated Domains للروابط المملوكة.
- قرار موثق بشأن ATT إذا أصبح الإعلان المخصص/التتبع مستخدمًا.
- قياس iPhone/iPad performance وmemory وbackground lifecycle.
- مراجعة دعم iPad الفعلي؛ المشروع يعلن device family 1,2 لكنه يفرض portrait فقط.

## 4. جدول موانع Android

| ID | النوع | المانع | الدليل الحالي | شرط الإغلاق |
|---|---|---|---|---|
| AND-SRC-01 | RELEASE | Solo قد يستخدم demoQuestions في Production | SupabaseQuestionRepository يرجع DriftQuestionRepository عند empty/error، والأخير يدمج demoQuestions | سياسة Production fail-closed أو محتوى معتمد واختبارات جديدة |
| AND-SRC-02 | RELEASE | Voucher مؤجل لكن route مباشر موجود | /premium/voucher يبني PremiumVoucherScreen؛ المدخل المرئي مخفي بالبوابة فقط | منع المسار إنتاجيًا والتحقق من deep links |
| AND-SRC-03 | RELEASE | تسرب copy للأصدقاء | football_preferences_screen.dart يعرض “يمكن للأصدقاء رؤية اختيارك” | إزالة/استبدال لاحقة بعد رفع freeze |
| AND-SRC-04 | RELEASE | Premium copy يخالف المنفعة المعتمدة | premium_screen.dart يعرض “فئات أكثر. إعلانات أقل.” بدل ad-free | توحيد النص مع “فئات حصرية” و“بدون إعلانات” بعد رفع freeze |
| AND-SEC-01 | RELEASE | Crashlytics يسجل Object وStackTrace خامين | FirebaseCrashReporter يستدعي recordError مباشرة | sanitizer/تصنيف بيانات واختبار Privacy |
| AND-VIS-01 | RELEASE | مرجع بصري غير معتمد | 209 baseline، منها 110 tracked modified و7 untracked، و892 failure image | تشغيل مضبوط ومراجعة واعتماد دون regeneration عشوائي |
| AND-BLD-01 | RELEASE | لا artifact موقّع للشجرة الحالية | الشجرة غير نظيفة ولم تُبن في Codemagic | commit معلوم + CI أخضر + SHA/artifact |
| AND-DEV-01 | DEVICE | لا QA فعلي | لا Device evidence | تنفيذ المصفوفة أدناه |
| AND-EXT-01 | PROVIDER | تكاملات Production غير مثبتة فعليًا | إعدادات/متغيرات موثقة فقط | اختبارات حسابات وأجهزة ولوحات مزودين |
| AND-BE-01 | BACKEND | لا E2E حالي لـRLS/Functions/concurrency | تطابق migrations لا يثبت السلوك | اختبار Production-like متعدد الحسابات |
| AND-STORE-01 | STORE | Play Console غير مكتمل الإثبات | لا Store evidence | إكمال checklist والمتطلبات والمراجعة |
| AND-LEGAL-01 | STORE/LEGAL | الإفصاحات والمراجعة القانونية وحقوق الوسائط غير مكتملة | روابط مشغل فقط | موافقة قانونية وData Safety وحقوق |
| AND-AUTH-01 | PRODUCT | Password recovery غير منفذ | لا mobile recovery/reset flow | تنفيذه لاحقًا أو قرار منتج موثق بإزالة Email password |

## 5. جدول موانع iOS

| ID | النوع | المانع | الدليل الحالي | شرط الإغلاق |
|---|---|---|---|---|
| IOS-BLD-01 | RELEASE | لا IPA/TestFlight حالي | Windows محليًا ولا نجاح CI للشجرة الحالية | Codemagic macOS أخضر وIPA موقّع |
| IOS-SIGN-01 | RELEASE | signing الخارجي غير مثبت | تعريف YAML فقط | App ID/cert/profile صالح وCI proof |
| IOS-DEV-01 | DEVICE | لا iOS device evidence | لا TestFlight/iPhone/iPad run | تنفيذ المصفوفة |
| IOS-EXT-01 | PROVIDER | APNs/Firebase/Google/RevenueCat/AdMob غير مثبتة | paths/config only | provider + Sandbox + device proof |
| IOS-STORE-01 | STORE | App Store Connect غير مكتمل | لا listing/privacy/IAP/review evidence | إكمال checklist |
| IOS-COMMON-01 | RELEASE | موانع المصدر المشتركة | Solo/voucher/Friends/Crashlytics | إغلاقها في مرحلة إصلاح منفصلة |
| IOS-LINK-01 | NON_BLOCKING | لا Universal Links/Associated Domains | custom auth scheme صالح ومقيد حاليًا | اختبار تهديد/قرار لاحق للروابط المملوكة |

## 6. أدلة الاختبارات الحالية

### Flutter static analysis

- الأمر: flutter analyze --fatal-infos
- المسار: C:\dev\ahdash11\mobile
- النتيجة: **PASS**
- الخرج النهائي: No issues found!
- مدة Flutter المعلنة: 163.1 ثانية.
- مدة الأمر الكلية المرصودة، شاملة resolution/startup: 202.8 ثانية.
- أخطاء/تحذيرات fatal: صفر.

### Shared Android/iOS non-visual release-equivalent gate — current tree

- الاختيار: جميع test/**/*_test.dart مع استبعاد test/visual/**.
- ملفات مختارة: 74.
- ملفات بصرية مستبعدة: 24.
- حالات ناجحة: 584.
- حالات فاشلة: 0.
- حالات skipped: 0.
- أحداث loader مخفية: 78، ولا تُحسب كحالات منتج.
- النتيجة: **PASS — 584/584**.
- مدة الأمر الكلية المرصودة: 306.3 ثانية.
- coverage كُتب إلى مجلد مؤقت خارج المستودع؛ لم يتغير mobile/coverage.

### الملفات الـ74 المختارة

1. test/contracts/supabase_model_contracts_test.dart
2. test/core/app_config_hardening_test.dart
3. test/core/app_error_sanitizer_test.dart
4. test/core/feedback_service_test.dart
5. test/core/legal_link_service_test.dart
6. test/core/notification_navigation_test.dart
7. test/core/settings/player11_preferences_test.dart
8. test/core/theme/thmanyah_typography_test.dart
9. test/core/theme/v9_2_design_system_test.dart
10. test/features/auth/auth_screen_test.dart
11. test/features/auth/guest_capability_policy_test.dart
12. test/features/auth/guest_routing_test.dart
13. test/features/auth/social_auth_test.dart
14. test/features/categories/category_discovery_test.dart
15. test/features/content/app_content_test.dart
16. test/features/content/demo_catalog_test.dart
17. test/features/football/football_preferences_screen_refinement_test.dart
18. test/features/football/football_preferences_test.dart
19. test/features/game/ahdash_game_test.dart
20. test/features/game/game_rules_and_mechanics_test.dart
21. test/features/game/game_session_controller_test.dart
22. test/features/game/play_hub_widget_test.dart
23. test/features/game/speed_contract_test.dart
24. test/features/home/home_refinement_test.dart
25. test/features/home/home_screen_test.dart
26. test/features/match/difficulty_engine_test.dart
27. test/features/match/match_state_machine_test.dart
28. test/features/match/online_match_contract_test.dart
29. test/features/match/question_and_results_widget_test.dart
30. test/features/match/question_engine_test.dart
31. test/features/match/scoring_engine_test.dart
32. test/features/match/solo_setup_screen_widget_test.dart
33. test/features/notifications/notifications_screen_widget_test.dart
34. test/features/onboarding/launch_screen_test.dart
35. test/features/onboarding/onboarding_screen_test.dart
36. test/features/party/party_game_controller_test.dart
37. test/features/party/party_game_engine_test.dart
38. test/features/party/party_gameplay_widget_test.dart
39. test/features/party/party_helpers_full_qa_test.dart
40. test/features/party/party_question_renderer_test.dart
41. test/features/party/party_setup_flow_test.dart
42. test/features/party/party_setup_widget_test.dart
43. test/features/party/saved_games_states_test.dart
44. test/features/phase6/phase6_contracts_test.dart
45. test/features/phase6/phase6_widgets_test.dart
46. test/features/premium/premium_models_test.dart
47. test/features/premium/premium_voucher_test.dart
48. test/features/ranking/ranking_screen_widget_test.dart
49. test/features/settings/notification_preferences_controller_test.dart
50. test/features/settings/settings_screen_refinement_test.dart
51. test/features/social/challenge_submission_test.dart
52. test/features/social/friends_block_workflow_test.dart
53. test/features/social/join_flows_widget_test.dart
54. test/features/social/social_entities_test.dart
55. test/features/social/team_challenge_screen_widget_test.dart
56. test/features/social/team_detail_screen_widget_test.dart
57. test/features/store/wallet_ledger_test.dart
58. test/features/support/question_report_repository_test.dart
59. test/features/support/report_problem_screen_test.dart
60. test/features/tournament/tournament_controller_test.dart
61. test/features/tournament/tournament_engine_test.dart
62. test/features/tournament/tournament_flow_test.dart
63. test/features/tournament/tournament_party_context_test.dart
64. test/features/tournament/tournament_registration_model_test.dart
65. test/features/tournament/tournament_widgets_test.dart
66. test/qa/v10_full_feature_fixture_contract_test.dart
67. test/shared/presentation/ahdash_pictograms_test.dart
68. test/v10_phase_a/v10_portrait_contract_test.dart
69. test/v10_phase_b/v10_party_portrait_contract_test.dart
70. test/v10_phase_c/v10_tournament_portrait_contract_test.dart
71. test/v10_phase_d/phase_d_widgets_test.dart
72. test/v10_phase_d/v10_phase_d_contract_test.dart
73. test/v10_phase_e/phase_e_widgets_test.dart
74. test/v10_phase_e/v10_phase_e_contract_test.dart

### الملفات البصرية الـ24 المستبعدة

achievement_hero_screenshot_test.dart، ahdash_pictograms_golden_test.dart، auth_simple_rounded_screenshot_test.dart، auth_ux_repair_golden_test.dart، blocked_players_refinement_test.dart، global_refinement_responsive_test.dart، illustrated_empty_states_screenshot_test.dart، notifications_refinement_test.dart، party_setup_hero_screenshot_test.dart، settings_report_refinement_test.dart، team_challenge_states_golden_test.dart، team_detail_refinement_test.dart، tournament_golden_test.dart، v10_advanced_refinement_screenshot_test.dart، v10_complete_atlas_auth_states_test.dart، v10_entry_refinement_golden_test.dart، v10_full_feature_state_screenshot_test.dart، v10_gameplay_visual_refinement_screenshot_test.dart، v10_home_premium_design_refinement_screenshot_test.dart، v10_phase_a_golden_test.dart، v10_phase_b_golden_test.dart، v10_phase_d_golden_test.dart، v10_phase_e_golden_test.dart، v10_social_voucher_refinement_screenshot_test.dart.

### تدقيق الصور المرجعية

| القياس | النتيجة |
|---|---|
| ملفات visual test | 24 |
| baseline PNG داخل test/visual/goldens | 209 |
| baseline متتبعة ومعدلة | 110 |
| baseline غير متتبعة | 7 |
| failure PNG داخل test/visual/failures | 892 |
| هل baselines الحالية معتمدة/حديثة؟ | لا يمكن اعتبارها كذلك؛ الشجرة تحتوي تعديلات وفشلًا بصريًا كبيرًا دون سجل اعتماد مضبوط. |
| اعتمادها على المنصة | حساسة لنسخة Flutter، الخطوط، rasterization، DPR، locale وحجم viewport؛ المقارنة يجب أن تتم في بيئة مثبتة. |
| Android CI | مستبعدة صراحة. |
| iOS Release CI | مستبعدة صراحة؛ يشغّل جميع الملفات غير البصرية فقط مع coverage. |
| PR checks | مشمولة حاليًا لأن الأمر flutter test غير مفلتر. |
| المطلوب | تشغيل بصري controlled ومراجعة بشرية واعتماد واضح بعد رفع freeze؛ لا regeneration ضمن هذا التدقيق. |

### Integration tests

- الموجود: ملف واحد فقط، integration_test/app_smoke_test.dart.
- ما يثبته: cold launch أساسي، تخطي onboarding، والوصول إلى زر دخول الضيف باستخدام preferences mock وخدمات noop.
- ما لا يثبته: جهاز فعلي، providers، login/signup الحقيقي، Google/Apple، Party E2E، Solo، Tournaments، Teams/Challenges، FCM، Analytics، Crashlytics، RevenueCat، AdMob، deep links، offline/resume، account deletion.

## 7. أدلة البناء والتوقيع وCodemagic

### Android

- applicationId وnamespace: com.ahdash.eleven.
- minSdk: 24، targetSdk: 36، compileSdk: 36.
- NDK: 28.2.13676358، Java/Kotlin target: 17.
- versionName/versionCode مصدرهما Flutter/pubspec؛ القيمة الحالية 0.1.0+1، وCodemagic يستبدل build number بـPROJECT_BUILD_NUMBER.
- release signing يفشل مغلقًا إذا غاب key.properties أو أحد الحقول الأربعة أو ملف keystore.
- release يرفض ADMOB_ANDROID_APP_ID الفارغ أو Google test publisher ID.
- R8/minifyEnabled وshrinkResources مفعّلان مع ProGuard.
- Manifest المصدر: INTERNET، ACCESS_NETWORK_STATE، POST_NOTIFICATIONS؛ allowBackup=false، usesCleartextTraffic=false، portrait.
- Android 13+ notification permission موجودة. targetSdk 36 يضع المشروع ضمن متطلبات النظام الحديثة، لكنه لا يثبت سلوك Android 14/15/16 على جهاز.
- intent filters: custom scheme com.ahdash.eleven لـlogin-callback وTeams/Tournaments. autoVerify على custom scheme ليس إثبات Android App Link HTTPS.
- package visibility يحتوي PROCESS_TEXT.

### دليل التوقيع

- package: com.ahdash.eleven.
- SHA-1 الموثق: 1E:25:C3:09:0A:F3:1E:20:54:46:C5:5D:6B:B2:7D:45:17:77:B8:C7.
- SHA-256 الموثق: 43:47:5F:35:4B:73:F4:D2:C9:AD:45:66:3A:BF:D6:DF:FA:86:25:93:03:F9:1D:1B:2E:D6:A4:93:83:C1:86:47.
- HISTORICAL_SIGNED_ARTIFACT: AAB وAPK سابقان، وAAB SHA-256 = 4456CEBEA870B826D79B670267C3D587E42BA80A39D43FD4C59E089D5EC2D4E4.
- CURRENT_TREE_SIGNED_ARTIFACT: **غير موجود**.
- البناء المحلي: لم يُشغّل. signing وFirebase files موجودان محليًا ومهملان من Git، لكن validator المحلي يفتقد مفاتيح RevenueCat/AdMob/cadence/legal URLs المحمية. الحالة: **LOCAL_RELEASE_BUILD_NOT_RUN_PRODUCTION_VARIABLES_EXTERNAL**.
- نتيجة validator المحلي المعقمة: Supabase URL/anon وFirebase/Google وpackage/signing/certificate metadata موجودة؛ القيم غير المتاحة محليًا هي REVENUECAT_ANDROID_API_KEY، ADMOB_ANDROID_APP_ID، ADMOB_REWARDED_ANDROID_ID، ADMOB_INTERSTITIAL_ANDROID_ID، ADMOB_INTERSTITIAL_EVERY_MATCHES، PRIVACY_POLICY_URL، وTERMS_URL. انتهى validator بحالة فشل كما يجب، لذلك لم يُبن artifact مضلل.

### Android Codemagic

| العنصر | الحالة |
|---|---|
| runner | mac_mini_m2 |
| Flutter/Xcode/CocoaPods | stable/latest/default |
| tests | 74 ملفًا غير بصري منطقيًا؛ test/visual مستبعد |
| Firebase | FIREBASE_ANDROID_CONFIG مطلوب ويُحقن |
| signing | ahdash11_keystore وCM_* مطلوبة، fail-closed |
| Production validator | موجود، ويُشغّل مع Firebase/Google/AdMob |
| artifacts | signed AAB، signed APK، mapping، coverage |
| publishing | لا يوجد نشر Google Play في workflow |
| current-tree proof | لا يوجد |
| historical proof | موجود لإصدار سابق فقط |

### iOS project

- Bundle ID: com.ahdash.eleven.
- deployment target: iOS 15، بما يطابق الحد الأدنى لمكونات Firebase الفعلية الحالية.
- Podfile موجود وCocoaPods مستخدم.
- targeted device family: iPhone وiPad، مع portrait orientations فقط.
- Info.plist يحتوي remote-notification background mode.
- Runner.entitlements يحافظ على aps-environment ويحتوي Sign in with Apple بالقيمة القياسية `Default`؛ لا Associated Domains لأن التدفق الحالي يستخدم custom scheme.
- URL schemes تشمل auth callback، ويزامن CI Google reversed client scheme من Firebase iOS plist المحقون.
- GoogleService-Info.plist المحلي متسق ساكنًا مع bundle/client، لكنه ملف مهمل ويُستبدل في CI.
- Info.plist المحلي يحتوي Google AdMob test app ID؛ CI يستبدله بقيمة Production مطلوبة.
- لا NSCamera/NSMicrophone/NSLocation/NSPhoto descriptions لأن الكود الحالي لا يستخدم هذه القدرات.
- لا NSUserTrackingUsageDescription؛ يلزم قرار ATT إذا استُخدم tracking/personalized ads.
- app icon وlaunch storyboard موجودان.
- version/build من Flutter، وCI يمرر PROJECT_BUILD_NUMBER.
- لا بناء محلي: **IOS_BUILD_REQUIRES_MACOS_CI**.

### iOS Codemagic

| العنصر | الحالة |
|---|---|
| runner | mac_mini_m2 |
| signing | app_store، bundle com.ahdash.eleven، xcode-project use-profiles |
| App Store Connect | integration باسم ahdash11_app_store معرفة في YAML؛ صحتها الخارجية غير مثبتة |
| tests | جميع الملفات غير البصرية تُشغّل مع coverage؛ test/visual مستبعد صراحة |
| Firebase | FIREBASE_IOS_CONFIG مطلوب ويُحقن إلى Runner، وتُفحص metadata/bundle وتُزامن Google callback |
| Production validator | يتحقق من Supabase/Firebase/Google/Apple/RevenueCat/AdMob/legal ومن مراجع مشروع iOS قبل signing/build |
| AdMob | GADApplicationIdentifier يُستبدل؛ unit IDs وcadence تمرر للبناء وتُفحص |
| RevenueCat | REVENUECAT_IOS_API_KEY وentitlement `premium` يمران ويُفحصان |
| Google Auth | GOOGLE_AUTH_ENABLED=true يُمرر إلى IPA |
| Apple Auth | APPLE_AUTH_ENABLED=true يُمرر إلى IPA |
| Crashlytics | dSYM upload phase موجود لـRelease/Profile |
| artifact | IPA متوقع |
| publishing | submit_to_testflight=true، Internal Testers؛ submit_to_app_store=false |
| current-tree proof | لا يوجد IPA أو TestFlight run مثبت |

## 8. مصفوفة جاهزية الميزات

| الميزة | التصنيف | حقيقة المصدر الحالية | ما ينقص للإصدار |
|---|---|---|---|
| Guest | LIVE | Home/How-to/Local Party/Local Solo/Local Settings متاحة؛ الميزات السحابية محمية fail-closed | جهاز، upgrade إلى حساب، ومحاولات deep links |
| Email login/signup/logout | IMPLEMENTED | Supabase حقيقي، validation/error/busy guards وتنظيف logout | جهاز، provider runtime، session expiry؛ recovery/reset غير منفذ |
| Google Android | PARTIAL | كود native وتبادل tokens وcancel/error موجود؛ CI يفعّله | Release device/provider proof |
| Google iOS | CODE_READY_EXTERNAL_VALIDATION_PENDING | native token/Supabase exchange وCI gate وplist-derived scheme موجودة | existing provider/Firebase value ثم TestFlight device proof |
| Apple iOS | CODE_READY_EXTERNAL_VALIDATION_PENDING | OAuth redirect وsession callback وCI gate وentitlement موجودة | capability/provider/Services ID إن تطلبه الإعداد/signing/device |
| Session restore | PARTIAL | يعتمد current Supabase session | expired/refresh/revocation E2E لا توجد |
| Party categories | LIVE | Production لا يستخدم demo fallback لمسار Party، مع remote/cache وحالة empty | fresh-install offline وProduction pack proof |
| Party selection | LIVE | ست فئات بالضبط | جهاز |
| Party pack/board | LIVE | 6 أسئلة لكل فئة: 2 easy + 2 medium + 2 hard = 36، مع duplicate/recent guards | Backend pack + device E2E |
| Team setup | LIVE | فريقان، تقسيم تلقائي/يدوي اختياري | جهاز/keyboard |
| Helpers | LIVE | اختيار 3 لكل فريق، consumption/availability وقواعد pass/risk/steal | جهاز/lifecycle |
| Ready/board/question | LIVE | Ready، board، text/image، timer أو disabled | media/network/device |
| Opponent/reveal/scoring | LIVE | opponent window، reveal، single award، undo، turn/completion/tie behavior | E2E |
| Result/replay | LIVE | result وreplay/reset | E2E |
| Party save/resume | PARTIAL | active session/draft/history/favorites/recent usage محلي، وcorrupt state يُتجاهل بأمان | kill/reopen وfresh-install/offline |
| Solo setup/game | PARTIAL | category/difficulty/count/timer/scoring/reveal/result/replay/local best، لا خصم وهمي | إزالة Production demo fallback، جهاز |
| Solo ads/Premium | PARTIAL | interstitial على النتيجة وPremium bypass | AdMob/RevenueCat device proof |
| Tournaments | PARTIAL | discover/create/join/register/review/teams/draw/bracket/Party match/result/champion؛ knockout فقط | real multi-account E2E، RLS/concurrency/Functions |
| Teams | PARTIAL | create/join/code/invites/member roles/removal/rotation/leave | multi-account E2E؛ لا Friends مطلوب في المسار النشط |
| Team Challenges | PARTIAL | start/question/answer/result وidempotency guards | backend/device/concurrency |
| Ranking | PARTIAL | leaderboard server query، بلا fallback وهمي | Production data/RLS/device |
| Profile | PARTIAL | server summary وتournament stats | تحرير name/username/avatar غير منفذ |
| Football Preferences | PARTIAL | RPC load/save وPlayer11 محلي | device/account؛ copy للأصدقاء متسرب |
| Blocks/Reports | PARTIAL | block/unblock/report RPCs، question report queue، problem report، delete-account Function | syncPending غير موصول تلقائيًا؛ Function/device proof |
| Notifications | PARTIAL | init/token/rotation/permission/inbox/read/preferences/deep-link mapping | provider/scheduler/device delivery |
| Premium | PARTIAL | Monthly/Annual فقط، store-localized prices، premium entitlement، purchase/restore/status/expiry/cancel/manage، category/ad access | products/offering/sandbox/webhook/device؛ hero copy يحتاج مراجعة منفعة |
| AdMob | PARTIAL | consent، cadence، interstitial، failures، Premium bypass؛ rewarded SSV موجود بلا مدخل economy نشط | device/consent/no-fill؛ rewarded economy يبقى inactive |
| Settings/legal/delete | PARTIAL | validated HTTPS links وlogout/delete access | operator/store/legal/device proof |
| Friends/Online/1v1/2v2/Rooms | REMOVED_ACTIVE | routes القديمة tombstones إلى Home، ولا entries نشطة أو notification allowlist | إزالة copy للأصدقاء ومسح routes/direct surfaces دوريًا |
| Store/Wallet/Coins/Cosmetics | DEFERRED | /store يعرض Premium و/wallet يحول له؛ لا economy نشطة | لا تُحسب كميزة |
| Vouchers | DEFERRED_WITH_LEAK | المدخل المرئي مخفي والمutation fail-closed عند gates off | route مباشر يجب إغلاقه |
| Ordering/Club Guess/Eagle Eye/Daily | DEFERRED | ليست مسارات منتج نشطة | لا تُحسب كميزة |

## 9. مصفوفة جاهزية التكاملات

| التكامل | Android | iOS | الدليل الحالي | الحكم |
|---|---|---|---|---|
| Supabase Core/Auth | PARTIAL | PARTIAL | URL/anon config وعقود؛ Production migrations 27/27 operator-verified | runtime/RLS/E2E pending |
| Email Auth | PARTIAL | PARTIAL | source implemented | device/provider pending؛ reset absent |
| Google Auth | PARTIAL | CODE_READY_EXTERNAL_VALIDATION_PENDING | iOS native/Supabase source وCI flag وFirebase-derived callback جاهزة | existing provider + device proof |
| Apple Auth | N/A | CODE_READY_EXTERNAL_VALIDATION_PENDING | OAuth/session callback وCI flag وRunner entitlement جاهزة | capability/provider/signing/device |
| Firebase Core | PARTIAL | CODE_READY_EXTERNAL_VALIDATION_PENDING | Android operator config؛ iOS injection/metadata/project references جاهزة | protected value + runtime pending |
| FCM/APNs | BLOCKED_DEVICE | BLOCKED_DEVICE | source wiring وaps entitlement | token/delivery/lifecycle/provider |
| Analytics | PARTIAL | PARTIAL | gated events، لا delivery proof | device/console/privacy |
| Crashlytics | PARTIAL_RISK | CODE_READY_EXTERNAL_VALIDATION_PENDING | fatal/nonfatal/root wiring وiOS dSYM phase؛ raw error review مستقل | archive symbols/privacy/device |
| RevenueCat | PARTIAL | CODE_READY_EXTERNAL_VALIDATION_PENDING | premium entitlement، Monthly/Annual code، iOS key path/validator | store products/offering/sandbox/webhook |
| AdMob | PARTIAL | CODE_READY_EXTERNAL_VALIDATION_PENDING | Production fail guards/injection/UMP وiOS app/unit paths | real IDs runtime/device/disclosure |
| Deep links | PARTIAL | CODE_READY_EXTERNAL_VALIDATION_PENDING | custom auth/Google schemes + allowlists + callback session observer | cold/warm/background؛ owned links تحسين لاحق |
| Edge Functions | PARTIAL | PARTIAL | delete-account وغيرها referenced | deployment/runtime/auth proof |
| Notification dispatcher/scheduler | PARTIAL | PARTIAL | client ready | backend/provider scheduling proof |
| Google Play | BLOCKED_STORE | N/A | no publish workflow/store proof | console checklist |
| App Store/TestFlight | N/A | BLOCKED_STORE | workflow configured only | credentials/build/IAP/listing |

ملاحظة Backend: إثبات المشغّل يذكر تطابق 27/27 migration حتى 20260908000100 ونتيجة lint صفر أخطاء و16 تحذيرًا. هذا يثبت حالة نشر/فحص سابقة موثقة، ولا يثبت وحده سلوك RLS وRPC وEdge Functions تحت التزامن وحسابات متعددة على الشجرة المرشحة.

### تفاصيل Notifications وAnalytics وCrash وAds

- Notifications: التهيئة gated، وطلب الإذن وtoken الأولي والتحديث والتعطيل عند logout وforeground/background/terminated mapping وinbox/read/preferences موجودة. أنواع friend/social تُصفّى من الصندوق الفعلي، والـallowlist لا تعيد Friends/Online. dispatch/scheduler والوصول الفعلي غير مثبتين.
- Analytics: يتعطل إلى noop عند تعطيل Firebase، وتوجد أحداث Auth وParty وSolo وNotifications وTournaments وPreferences وPremium وReports. لا يوجد screen observer شامل، ولا consent runtime مستقل عن config gate. المعلمات التي شوهدت وصفية وليست tokens، لكن وصول Production غير مثبت.
- Crashlytics: root zone وFlutterError وPlatformDispatcher وfatal/nonfatal وidentify/clear موجودة، مع noop عند التعطيل. مسار Firebase الخام يحتاج sanitizer ومراجعة PII كما سبق.
- RevenueCat: لا أسعار hard-coded ولا خصم وهمي؛ السعر من المتجر. Monthly/Annual فقط في current offering، وإدارة active/cancelled/grace/billing/expired وrestore/manage URL موجودة. webhook والمتجر وsandbox غير مثبتة.
- AdMob: UMP consent وcanRequestAds وحالات load/show/dismiss/fail/no-fill وcadence وPremium bypass موجودة. rewarded SSV code موجود بلا مدخل مستخدم نشط أو اقتصاد مفعّل؛ يجب أن يبقى كذلك. لا يوجد مسار واجهة نشط لإعادة فتح privacy options.

## 10. نتائج الأمن والخصوصية

### نتائج إيجابية مثبتة

- لا ملفات .env أو key.properties أو google-services.json أو GoogleService-Info.plist أو keystore/private key متتبعة.
- لا service-role key أو webhook secret في عميل الإنتاج؛ البحث أعاد ذكرًا توثيقيًا فقط.
- لا HttpOverrides أو certificate bypass، وAndroid usesCleartextTraffic=false.
- أخطاء Supabase الظاهرة للمستخدم تمر عبر معالجة آمنة، وAppErrorSanitizer يحجب Bearer/JWT/credentials/email في مساره.
- الروابط الداخلية والإشعارات تستخدم allowlists وUUID/join-code validation، ولا يوجد فتح URL اعتباطي.
- logout يعطل ارتباط الإشعارات، وينظف RevenueCat/Crash identity وSupabase/provider session ضمن حدود فشل الخدمات الاختيارية.
- logs التشخيصية محكومة بـkDebugMode ولا يظهر مسح المصدر طباعة tokens/passwords/report bodies/answers.

### مخاطر تتطلب إغلاقًا أو قبولًا

| ID | الشدة | النتيجة | الأثر |
|---|---|---|---|
| SEC-01 | Release blocker | FirebaseCrashReporter يرسل error/stack الخام مباشرة | قد تحتوي استثناءات مزودين على PII أو تفاصيل حساسة؛ يلزم sanitizer وسياسة retention/consent |
| SEC-02 | Release blocker/acceptance | auth/team/tournament تعتمد custom scheme غير مملوك مثل HTTPS App/Universal Link | احتمال interception وتعارض handler؛ يلزم device threat test أو انتقال لروابط مملوكة |
| SEC-03 | Product scope blocker | /premium/voucher مباشر رغم تأجيل القسائم | يعرض وظيفة مؤجلة؛ mutation fail-closed لا يلغي تسرب الواجهة |
| SEC-04 | Validation blocker | RLS/Functions/concurrency لم تُختبر على حسابات فعلية في هذا التدقيق | لا يجوز استنتاج العزل من migrations وحدها |
| SEC-05 | Privacy/store blocker | Data Safety/App Privacy/ads/analytics/crash disclosures غير معتمدة | خطر رفض متجر أو إفصاح غير مطابق |

لم تُطبع أي قيمة سرية. جميع النتائج مبنية على مسارات المصدر والحالة المعقمة.

### ملاحظات الأداء والاستقرار

- mobile/assets يحتوي 143 ملفًا بحجم إجمالي 68,910,013 بايت، قرابة 65.7 MiB؛ منها 76 صورة raster.
- لا توجد صورة raster تتجاوز 4 megapixels وفق جرد الملفات، لكن عدة صور 1536×1024 أو 1024×1536 وحجم الملف المفرد يقارب 1.1–2.27 MB. هذا خطر حجم/فك ترميز محتمل يحتاج قياس artifact وذاكرة جهاز، وليس إثبات عطل بحد ذاته.
- لم يُنفذ benchmark لـcold start أو frame jank أو memory أو DB أو ANR.
- مراجعة المصدر لم تكشف timer/subscription leak واضحًا في المسارات النشطة؛ timers وlisteners الرئيسية تملك cancellation/disposal، لكن device lifecycle الطويل ما زال مطلوبًا.
- توجد timeouts وحالات empty/error/retry في غالبية الشبكات، مع حواجز mounted/context واسعة. لا يجوز تحويل هذا إلى ادعاء استقرار فعلي قبل weak-network/background/kill testing.

## 11. نتائج الصلاحيات

### Android

| الصلاحية | المصدر | السبب المحتمل | استخدام التطبيق | الإفصاح/المراجعة |
|---|---|---|---|---|
| INTERNET | مباشر | Supabase/Firebase/media/RevenueCat/AdMob | مستخدمة | Data Safety/Privacy حسب البيانات |
| ACCESS_NETWORK_STATE | مباشر | معرفة توفر الشبكة والإعلانات | مستخدمة | عادة لا إذن runtime؛ توثيق الغرض |
| POST_NOTIFICATIONS | مباشر | FCM على Android 13+ | مستخدمة | إذن runtime وشرح توقيت الطلب |
| WAKE_LOCK | transitive | FCM/SDK background work | غير مستدعاة مباشرة | أكدها من merged manifest الحالي |
| AD_ID | transitive | AdMob/attribution | Ads SDK | Ads declaration وData Safety؛ راجع حذفها فقط إذا تغير نموذج الإعلانات |
| ACCESS_ADSERVICES_AD_ID/ATTRIBUTION/TOPICS | transitive | Android Privacy Sandbox/Ads SDK | dependency-added | راجع الإفصاح وmerged manifest |
| C2DM RECEIVE | transitive | Firebase Messaging | مستخدمة عبر FCM | Push disclosure |
| INSTALL_REFERRER | transitive | attribution/analytics SDK | لا استدعاء مباشر | Data Safety/provider review |
| USE_BIOMETRIC/USE_FINGERPRINT | transitive | Google credentials/auth dependency | لا استخدام مباشر في كود المنتج | مرشح مراجعة/إزالة فقط بعد اختبار Google Auth |
| BILLING | transitive | RevenueCat/Google Play Billing | مستخدمة للاشتراك | products/payments disclosure |
| FOREGROUND_SERVICE | transitive | dependency background behavior | لا استدعاء مباشر واضح | تحقق من AAB merged manifest وسياسة Play |

ملاحظة: ملفات merged manifest الموجودة محليًا قديمة زمنيًا عن الشجرة الحالية، لذلك القائمة transitive استدلال من artifacts/dependencies وليست بديلًا عن فحص manifest للـAAB الحالي. MainActivity exported=true متوقع لأنه launcher/deep-link entry؛ بقية components غالبًا من المكتبات ويجب إعادة تدقيق exported flags في artifact الحالي.

### iOS

| العنصر | الحالة | الحكم |
|---|---|---|
| aps-environment | موجود | مطلوب للإشعارات؛ صلاحية profile وAPNs غير مثبتة |
| remote-notification background mode | موجود | يلزم lifecycle/device validation |
| Camera/Microphone/Location/Photos descriptions | غير موجودة | لا يوجد استخدام مباشر مطابق؛ لا تُضف بلا حاجة |
| NSUserTrackingUsageDescription | غير موجود | يلزم قرار ATT إذا أصبحت الإعلانات/القياس tracking |
| Sign in with Apple entitlement | موجود بالقيمة `Default` | جاهز مصدرًا؛ يلزم توافق App ID/profile خارجيًا |
| Associated Domains | غير موجود | لا Universal Links |
| App Transport Security override | لا استثناء غير آمن ظاهر | إيجابي؛ يستمر التحقق في IPA النهائي |

## 12. مصفوفة اختبارات الأجهزة المطلوبة

جميع الصفوف التالية حالتها **NOT_RUN** ما لم يذكر غير ذلك. يجب تسجيل الجهاز/OS/build/account/time والدليل لكل حالة.

### Android

| المجال | الاختبارات المطلوبة |
|---|---|
| التثبيت | fresh install، upgrade من آخر إصدار منشور، launch/crash-free، package/version/signature |
| Onboarding/Guest | onboarding، guest Home، guest Party، guest Solo، منع الميزات الخاصة، upgrade إلى حساب |
| Email Auth | signup، login، logout، switch account، wrong password/network، session restore/expiry |
| Google Auth | chooser، cancel، failure، login، logout، switch، release SHA، guest upgrade/linking behavior |
| Party | 6 categories، 36 pack، auto/manual teams، 3 helpers، ready، text/image، timer، steal، reveal، scoring، undo، tie/completion، replay |
| Party persistence | background/resume، lock/unlock، force-stop، kill/reopen، corrupt/old draft، offline cached pack، fresh-install offline |
| Solo | كل difficulty/count، timers، scoring/reveal/result/replay/best، إثبات عدم demo في Production، لا خصم وهمي |
| Tournaments | discover/create/join/register/review/approve/reject/teams/draw/bracket/Party match/confirm/champion/reopen، حسابات متعددة |
| Teams/Challenges | create/join/invite code/roles/remove/rotate/leave، challenge start/answer/result/idempotency |
| Profile/Ranking/Preferences | data truth، empty/error، save/reload، Player11 local، عدم ظهور Friends |
| Blocks/Reports/Delete | block/unblock/player report/question queued+sync/problem report/rate-limit/account deletion |
| Deep links | auth callback، team join/detail، tournament، notification، cold/warm/background، malformed/removed routes |
| FCM | permission allow/deny/settings، token/rotation/logout، foreground/background/terminated، tap routing/privacy |
| Analytics | event arrival، disabled behavior، parameters بلا PII، consent/config behavior |
| Crashlytics | nonfatal/fatal receipt في build مصرح، symbolication، sanitizer/PII review، disabled behavior |
| RevenueCat | offering، localized Monthly/Annual، purchase/success/cancel/pending/failure، restore/reinstall/account switch/expiry/grace/billing، manage |
| Premium | exclusive categories، ad-free، no purchase CTA when active، entitlement after restart، webhook reconciliation |
| AdMob | UMP consent، privacy options، interstitial cadence=3، load/display/dismiss/no-fill/failure، Premium bypass، no rewarded economy |
| Network | Wi-Fi/mobile، weak/timeout/offline/reconnect، retry truth، no duplicate mutations |
| Accessibility | TalkBack، Arabic RTL focus، touch targets، text scale حتى النظام، contrast، reduced motion، keyboard/insets |
| Performance | cold/warm startup، image memory، scrolling، DB operations، ANR/jank، long Party session |

### iOS

نفّذ المكافئ الكامل للمصفوفة السابقة، إضافة إلى:

| المجال | الاختبارات المطلوبة |
|---|---|
| TestFlight | رفع IPA، install/update، build metadata، crash-free launch |
| Apple Sign-In | first login، cancel/failure، relay email، revoke credential، logout/account switch/guest upgrade |
| Google iOS | URL callback، chooser/cancel، Supabase exchange، logout/switch |
| Push/APNs | prompt، token، foreground/background/terminated، tap routing، badge/state، reinstall |
| Lifecycle | background، lock، memory pressure، termination، Party timer/resume، deep links بكل حالات التطبيق |
| RevenueCat iOS | Sandbox Monthly/Annual، Ask to Buy/pending إن أمكن، cancel/failure/restore/reinstall/manage/expiry |
| Ads/Consent | UMP/consent flow، ATT decision إن كان applicable، interstitial/no-fill/Premium bypass |
| Accessibility | VoiceOver، Dynamic Type، RTL focus، reduced motion، contrast، keyboard/safe area/notch |
| iPad | layout/portrait/keyboard/multitasking policy أو قرار إزالة الدعم إذا لم يكن معتمدًا |

## 13. قائمة Google Play

| المتطلب | الحالة | الدليل/العمل المتبقي |
|---|---|---|
| Developer account verification | UNKNOWN | لا Console evidence في التدقيق |
| App existence in Play Console | UNKNOWN | لا app record evidence |
| Package name | REPO_READY | com.ahdash.eleven |
| App signing | OPERATOR_VERIFIED | historical signed artifact والشهادة موثقان |
| Upload certificate association | UNKNOWN | بصمة الشهادة معروفة؛ ارتباطها بحساب Play غير مثبت |
| Title/short/full description | STORE_SETUP_PENDING | لا اعتماد listing |
| App icon | REPO_READY | assets/native config موجودة؛ يجب فحص artifact |
| Feature graphic | STORE_SETUP_PENDING | لا asset معتمد كمتطلب متجر |
| Phone/tablet screenshots | STORE_SETUP_PENDING | صور الاختبارات ليست تلقائيًا screenshots متجر |
| Privacy Policy | OPERATOR_VERIFIED_CONFIG / LEGAL_PENDING | URL موثق لدى المشغّل؛ النشر وصحة النص القانونية غير مثبتين |
| Data Safety | STORE_SETUP_PENDING | يجب مطابقة Supabase/Firebase/FCM/Analytics/Crashlytics/AdMob/RevenueCat/reports |
| Ads declaration | STORE_SETUP_PENDING | التطبيق يحتوي إعلانات |
| Content rating | STORE_SETUP_PENDING | لا إثبات استبيان/تصنيف |
| Target audience | STORE_SETUP_PENDING | لا إثبات |
| App access instructions | STORE_SETUP_PENDING | يلزم حساب/شرح للميزات الخاصة والمراجعين |
| Internal testing | STORE_SETUP_PENDING | لا track/build evidence للشجرة الحالية |
| Closed/open testing | UNKNOWN | تحقق من متطلبات الحساب الحالية في Console |
| Release track | STORE_SETUP_PENDING | Android workflow لا ينشر تلقائيًا |
| Monthly product | STORE_SETUP_PENDING | لا product ID/active status evidence |
| Annual product | STORE_SETUP_PENDING | لا product ID/active status evidence |
| Store listing contact | STORE_SETUP_PENDING | لا إثبات |
| Official Play URL | UNKNOWN | لا رابط إصدار رسمي مثبت |
| Review submission | STORE_SETUP_PENDING | لم يتم |

الحكم: **GOOGLE PLAY READINESS = BLOCKED_STORE**، مع أن package/signing source والتاريخي متقدمان.

## 14. قائمة App Store وTestFlight

| المتطلب | الحالة | الدليل/العمل المتبقي |
|---|---|---|
| Apple Developer App ID | UNKNOWN | Bundle ID في المصدر لا يثبت App ID الخارجي |
| Bundle ID | REPO_READY | com.ahdash.eleven |
| Sign in with Apple capability | EXTERNAL_VERIFICATION_REQUIRED | entitlement جاهز مصدرًا؛ يلزم تأكيد capability وprofile لنفس App ID |
| Push capability/APNs | PARTIAL | aps entitlement موجود؛ profile/provider غير مثبت |
| Certificates | UNKNOWN | YAML فقط |
| Provisioning profiles | UNKNOWN | use-profiles معرف؛ نجاحه غير مثبت |
| App Store Connect app | UNKNOWN | integration name لا يثبت app record |
| TestFlight workflow | REPO_READY_CONFIG | submit_to_testflight=true وInternal Testers |
| TestFlight build | BLOCKED | لا IPA/run حالي |
| App Privacy | STORE_SETUP_PENDING | لا إثبات |
| Nutrition Labels | STORE_SETUP_PENDING | لا إثبات |
| Age rating | STORE_SETUP_PENDING | لا إثبات |
| Screenshots | STORE_SETUP_PENDING | لا صور متجر معتمدة |
| Support URL | STORE_SETUP_PENDING | لا إثبات |
| Privacy URL | OPERATOR_VERIFIED_CONFIG / LEGAL_PENDING | URL موثق كمتغير؛ App Store field والمحتوى غير مثبتان |
| Review information | STORE_SETUP_PENDING | حساب/ملاحظات المراجع غير مثبتة |
| Sign in with Apple review requirement | CODE_READY_STORE_REVIEW_PENDING | المصدر/entitlement/CI جاهزة؛ يلزم provider/device ومراجعة Apple |
| Monthly subscription | STORE_SETUP_PENDING | لا IAP product evidence |
| Annual subscription | STORE_SETUP_PENDING | لا IAP product evidence |
| Sandbox testing | BLOCKED | لم ينفذ |
| Official App Store URL | UNKNOWN | لا إصدار مثبت |
| Submit to App Store | REPO_READY_AS_DISABLED | submit_to_app_store=false، وهو صحيح لمرحلة TestFlight لكنه ليس نشرًا |

الحكم: **APP STORE / TESTFLIGHT READINESS = BLOCKED**.

## 15. ترتيب التنفيذ الموصى به بدقة

هذا ترتيب لمرحلة إصلاح/إصدار لاحقة ويتطلب تفويضًا جديدًا؛ لم يُنفذ منه شيء في هذا التدقيق:

1. تثبيت baseline: اختيار commit مرشح نظيف، حصر الملفات المقصودة، ومنع خلط تغييرات Desktop أو artifacts.
2. إغلاق موانع المصدر المشتركة: Solo Production demo fallback، direct voucher route، Friends copy، Crashlytics sanitization، وقرار password recovery.
3. إغلاق iOS auth/config: Apple App ID/capability/entitlement/provider/redirect/profile، ثم تمرير Google/Apple gates في IPA بعد نجاح الإعداد.
4. اعتماد الروابط القانونية وحقوق جميع الصور/المحتوى، وصياغة Data Safety/App Privacy/Ads declarations.
5. توثيق provider dashboards دون أسرار: Supabase، Firebase Android/iOS، Google، Apple، RevenueCat، AdMob، webhook، APNs/FCM.
6. تشغيل backend verification المصرح: migrations 27/27، RLS، RPCs، Edge Functions، concurrency/idempotency بحسابات اختبار.
7. تشغيل Goldens في بيئة Flutter/fonts/render مثبتة، مراجعة الفروق بشريًا، واعتماد baseline واحد؛ توحيد Android/iOS/PR test policy.
8. تشغيل format check إن كان ضمن بوابة الفريق، ثم analyze --fatal-infos، ثم 74 ملفًا غير بصري، ثم integration tests الموسعة.
9. commit المرشح ومراجعته؛ لا يُقبل build من working tree غير معروفة.
10. تشغيل Codemagic Android: validator، AAB/APK موقّعان، capture SHA/certificate/merged manifest/mapping/version.
11. فحص AAB النهائي: package، min/target/compile، permissions، exported components، test IDs، cleartext، signature، size.
12. تنفيذ Android device matrix كاملة على أكثر من مستوى API وحسابين على الأقل.
13. إعداد Google Play listing/products/tracks والسياسات، ثم internal test، ثم closed/open حسب المتطلبات، ثم مراجعة staged rollout.
14. تشغيل Codemagic iOS بعد توحيد الاختبارات: signed IPA، symbols/logs، ورفع Internal TestFlight.
15. تنفيذ iOS device matrix على iPhone، وiPad إن بقي الدعم، مع Apple/Google/Auth/APNs/IAP/Ads/VoiceOver.
16. إكمال App Store Connect listing/privacy/IAP/review metadata، ثم TestFlight acceptance ومراجعة release candidate.
17. مراقبة Analytics/Crashlytics/FCM/RevenueCat/AdMob وbackend في staged rollout مع rollback/kill-switch plan موثق.
18. بعد اكتمال جميع الأدلة فقط، إعادة تدقيق نهائي مستقل ومنح READY أو إبقاء المنع.

## 16. موانع الإصدار مقابل التحسينات غير المانعة

### موانع إصدار مؤكدة

- Solo demo fallback في Production.
- direct voucher route وتسرب Friends copy ضمن حقيقة منتج جديدة.
- عدم وجود artifact موقّع للشجرة الحالية.
- Goldens غير معتمدة وتبقى خارج Release؛ iOS Release أصبح متسقًا مع Android، بينما PR ما زال أوسع.
- عدم وجود Device E2E للخدمات واللعب والحذف والـlifecycle.
- عدم اكتمال store/legal/privacy/media rights.
- عدم إثبات Backend RLS/Functions/concurrency فعليًا.
- مراجعة Crashlytics الخام قبل تفعيل Production.
- iOS: gates وApple entitlement جاهزة مصدرًا؛ provider/capability/signing وIPA/TestFlight والجهاز ما زالت غير مثبتة خارجيًا.
- Email password recovery غير منفذ؛ يلزم إصلاح أو قرار منتج صريح قبل اعتبار Email Auth كاملة.

### تحسينات غير مانعة بذاتها

- App/Universal Links مملوكة بدل custom scheme، ما لم تقرر مراجعة التهديد أنها مانع.
- تنظيف dormant Online/Friends/landscape code بعد مرحلة إزالة مثبتة.
- تحسين حجم assets بعد benchmark فعلي.
- دعم text scale فوق 1.6 وتحسينات touch/contrast بناء على QA.
- ربط privacy-options revisit في Settings.
- إضافة screen-view analytics إذا كانت مطلوبة لخطة القياس وبموافقة الخصوصية.
- توسيع integration tests لتقليل الاعتماد على QA اليدوي، مع بقاء اختبارات الأجهزة ضرورية.

## 17. حدود الأدلة

- التدقيق تم على Windows؛ لم يُبن iOS ولم يُفتح Xcode أو App Store Connect.
- لم يُفتح Firebase/Supabase/RevenueCat/AdMob/Google Play/Apple Developer Console. حالة المشغّل مأخوذة من الأدلة الموثقة وليست تحققًا مستقلًا مباشرًا.
- لم يُشغّل Android Release محليًا لأن متغيرات Production المحمية غير متاحة؛ لم يُنشأ توقيع وهمي.
- لم يُشغّل Codemagic ولم يُنشأ current-tree artifact.
- لم يوجد جهاز Android أو iOS مستخدم في هذا التدقيق.
- لم تُجدد Goldens أو screenshots، ولم تُقبل الفروق البصرية.
- نجاح widget/unit tests لا يثبت provider runtime أو RLS أو store purchase أو push delivery أو lifecycle.
- artifacts المدمجة القديمة لا تثبت manifest النهائي للشجرة الحالية؛ يلزم فحص AAB/IPA النهائيين.
- مراجعة الخصوصية والقانون وحقوق الوسائط المذكورة هنا تقنية وليست موافقة قانونية.
- الشجرة كانت متسخة قبل التدقيق؛ تم الحفاظ على جميع تغييرات المستخدم. أضيفت لاحقًا تغييرات iOS المحددة وقائمة الربط الخارجية دون commit أو push.

## النتيجة النهائية

- ANDROID: **PARTIALLY_READY**
- IOS: **PARTIALLY_READY — IOS_CODE_READY_FOR_EXTERNAL_VALIDATION**
- البناء الفعلي: **IOS_BUILD_REQUIRES_MACOS_CI**. لا يُعد هذا اعتمادًا للإصدار أو إثباتًا لـTestFlight/iPhone.
