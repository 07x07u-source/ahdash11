# V10 Phase F — Physical Device QA + External Services Release Gate

## الحكم التنفيذي

**Phase F: غير مجتاز حاليًا.** لا يوجد جهاز Android مادي أو iPhone متصل بالمضيف، ولا Android AVD مثبت. لذلك لم تُمنح أي نتيجة `PASS — PHYSICAL DEVICE`، ولا يمكن استيفاء شرط المرحلة الأدنى الخاص بجهاز Android حقيقي.

هذا ليس فشلًا مثبتًا في تطبيق Flutter؛ إنه نقص في بيئة الاختبار. اكتملت البوابة الآلية، تدقيق إعدادات الخدمات، وبناء Android Debug فقط.

## بيئة الاختبار والأدلة

| العنصر | الحالة | البيئة/الدليل |
|---|---|---|
| Android physical device | NOT TESTED | `flutter devices` وADB لم يعثرا على أي جهاز |
| iOS physical device | NOT TESTED | لا جهاز iOS، والمضيف Windows لا يبني iOS |
| Android emulator | NOT TESTED | `flutter emulators`: لا AVD sources |
| Windows/Chrome/Edge inventory | PASS — AUTOMATED ONLY | متاحة، لكنها ليست بديلًا لجهاز Android/iOS المطلوب |
| Format | PASS — AUTOMATED ONLY | 228 ملفًا، 0 تغييرات |
| Analyze | PASS — AUTOMATED ONLY | `No issues found!`، 10.5s |
| Maintained suite | PASS — AUTOMATED ONLY | 370/370، 2m32s |
| Android Debug build | PASS — AUTOMATED ONLY | `app-debug.apk`، 217,989,326 bytes، SHA-256 `3CB42ADFEF0FF36C26FE0B4C7ABA02DFCF163B07610F17DD753EF86DBFE210D3` |
| APK package/orientation | PASS — AUTOMATED ONLY | package `com.ahdash.eleven`، MainActivity portrait (`screenOrientation=1`) |
| APK permission audit | PASS — AUTOMATED ONLY | لا Contacts ولا Phone/Call؛ توجد صلاحيات الشبكة/FCM/Billing المتوقعة |

## مصفوفة QA الرئيسية

| الفحص | الحالة | النتيجة/الدليل |
|---|---|---|
| Portrait startup/rotation/background | NOT TESTED | يحتاج جهازًا ماديًا؛ manifest وFlutter orientation مقيدان بالعمودي آليًا |
| Safe area/notch/navigation bar | NOT TESTED | لا جهاز فعلي |
| Keyboard screens 03/04/06/08/09/20/35/41/42 | NOT TESTED | اختبارات 360×800 و390×844/insets خضراء: `PASS — AUTOMATED ONLY`، لكن soft keyboard الحقيقي لم يُختبر |
| Compact 360×800 | PASS — AUTOMATED ONLY | مصفوفات V10 عند 1.0/1.2/1.3 خضراء؛ لا نتيجة جهازية |
| Google Sign-In | NOT TESTED | Google مفعّل في Supabase و`.env`، وgoogle-services يطابق package وله Android/Web OAuth clients؛ لا جهاز/chooser فعلي |
| Google account switch | NOT TESTED | عزل providers وsign-out مغطى آليًا فقط |
| Apple Sign-In | BLOCKED — EXTERNAL CONFIG | Supabase Apple=false، `APPLE_AUTH_ENABLED=false`، ولا Sign in with Apple entitlement؛ redirect code موجود فقط |
| Email auth | NOT TESTED | Email provider متاح وsignup مفعّل في Supabase؛ لا حساب اختبار/جهاز |
| Forgot Password | NOT TESTED | لا reset-password flow فعّال في الواجهة الحالية |
| Deep links cold/warm/background | NOT TESTED | allowlist والمسارات غير المدعومة خضراء آليًا فقط؛ APK يحوي callback وteam/tournament schemes |
| Party E2E/Board/Question/Helpers | NOT TESTED | gameplay والـduplicate guards والـanswer hiding خضراء آليًا؛ لا لعب مادي |
| Party timer lifecycle/lock | NOT TESTED | منطق lifecycle مغطى باختبارات، دون background فعلي |
| Party force-close restoration | NOT TESTED | resolver/session restoration خضراء آليًا، دون force-stop فعلي |
| Tournament UI E2E | NOT TESTED | UI/regression خضراء آليًا؛ لا جهاز |
| Tournament unsafe remote mutation | BLOCKED — BACKEND SECURITY GATE | بقيت fail-closed ولم تُنفذ migration أو workaround |
| Solo LIMITED | NOT TESTED | المسار المدعوم مغطى آليًا فقط ولم يُوسّع |
| Team Challenge | NOT TESTED | wiring الحقيقي مغطى آليًا، بلا حسابات/حالة اجتماعية فعلية |
| Ranking | PASS — AUTOMATED ONLY | لا demo fallback؛ محاولة RPC العامة غير المصادق عليها لم تُعامل كبيانات إنتاج |
| Friends/Blocked/Team Detail | NOT TESTED | no-presence/no-fake-stats وعزل الأخطاء خضراء آليًا فقط |
| FCM initialization/token | NOT TESTED | `FIREBASE_ENABLED=true` وملفات Android/iOS موجودة؛ token/permission يحتاج جهازًا |
| FCM foreground/background/terminated | BLOCKED — EXTERNAL CONFIG | لا جهاز ولا test push source مصرح |
| Notification privacy/routing | PASS — AUTOMATED ONLY | allowlist واختبارات redaction خضراء؛ لا delivery فعلي |
| RevenueCat SDK/config | BLOCKED — EXTERNAL CONFIG | مفتاحا Android وiOS فارغان في بيئة QA؛ entitlement الافتراضي `premium` فقط |
| RevenueCat offering/localized price | BLOCKED — EXTERNAL CONFIG | لا يمكن تحميل offering/store price بلا مفتاح ومتجر جهاز |
| Sandbox purchase/cancel/pending/failure | BLOCKED — EXTERNAL CONFIG | لا مفاتيح، لا حساب متجر sandbox، ولا جهاز؛ لم تُجر عملية مالية |
| Restore Purchases/reinstall | BLOCKED — EXTERNAL CONFIG | wiring واختبارات mock خضراء فقط |
| Premium account isolation | PASS — AUTOMATED ONLY | RevenueCat logIn/logOut وaccount epoch مختبران؛ لا sandbox فعلي |
| `/store` و`/wallet` | PASS — AUTOMATED ONLY | `/store` → Premium و`/wallet` → `/store`؛ لا Coins UI فعّال |
| Football load | PASS — AUTOMATED ONLY | Supabase الفعلي متاح و`list_football_leagues` أعاد 6 صفوف منشورة؛ search/save الموثقان لم يُختبرا بجهاز/حساب |
| Football keyboard/search/save/reload | NOT TESTED | provider والبحث والحفظ مغطاة آليًا فقط |
| Media slow/offline/404 | NOT TESTED | fallbacks والحقوق مغطاة بالكود/الاختبارات، دون شبكة جهاز |
| Network matrix | NOT TESTED | لا جهاز للتحكم بالشبكة/lifecycle |
| Report Problem physical submit/rate limit | NOT TESTED | validation/duplicate/timeout و5 تقارير/24h مدققة آليًا؛ لم يُرسل spam أو بلاغ إنتاجي |
| Settings persistence/terms/sign-out | NOT TESTED | persistence/sign-out آليًا فقط؛ روابط Terms/Privacy غير مهيأة في `.env` الحالية |
| Sound/Haptics hardware | NOT TESTED | لا عتاد مادي |
| Accessibility/screen reader/touch | NOT TESTED | text scale 1.0/1.2/1.3 آليًا فقط |
| RTL/mixed Arabic/English/prices | PASS — AUTOMATED ONLY | مصفوفات widgets/goldens خضراء؛ لا فحص جهاز |
| Cold launch/background/force-stop/lock | NOT TESTED | لا جهاز |
| Crashlytics live receipt | NOT TESTED | تهيئة Firebase موجودة؛ لم يُولّد crash إنتاجي |
| Account deletion disposable account | NOT TESTED | لم يُمنح حساب disposable أو تفويض حذف |
| Online inactive | PASS — AUTOMATED ONLY | `/online` يحول إلى `/home`، والـMatch Setup يعرضه غير متاح |

## تدقيق الخدمات الخارجية

- Supabase auth settings الفعلية: endpoint متاح، Google=true، Email=true، Apple=false، Phone=false، signup متاح، email autoconfirm=false.
- Android Google configuration: package مطابق، Android OAuth client وWeb client موجودان. هذا يثبت الإعداد الساكن فقط، لا نجاح account chooser أو exchange على جهاز.
- iOS: Bundle ID هو `com.ahdash.eleven`، وAPS environment مضبوط حسب build configuration. لا Apple Sign-In entitlement ولا provider خارجي مفعل.
- FCM: foreground listener وbackground-open وterminated initial-message code موجود، مع token rotation/deactivation. لا token أو delivery تم اختباره.
- RevenueCat: الكود يستخدم current offering وmonthly/annual و`priceString` وentitlement واحد؛ مفاتيح QA فارغة، لذلك الحالة الصحيحة هي الحظر الخارجي.
- Supabase migration SHA-256 لم يتغيرا: gameplay `C4968EA1824A3D9BBE942BABD3DE27F0F3267AF88DD834A4458861424267CCD1`، tournament `E4422D46197D187B50F544A2828667B3492F96F3C55BE7786420CCB122559E14`.

## سجل القضايا

| ID | الشدة | الحالة | الوصف |
|---|---|---|---|
| ENV-F-001 | Release-gate blocker | مفتوح | لا Android physical device؛ يمنع Phase F PASS |
| ENV-F-002 | Release-gate blocker | مفتوح | لا iPhone/iOS host؛ يمنع أي اعتماد iOS مادي |
| EXT-F-001 | External blocker | مفتوح | Apple provider/feature غير مهيأ |
| EXT-F-002 | External blocker | مفتوح | RevenueCat API keys/sandbox store غير مهيأة |
| EXT-F-003 | External blocker | مفتوح | لا test push source/device لـFCM delivery matrix |
| P2-F-001 | P2 | يحتاج مراجعة | `PRIVACY_POLICY_URL` و`TERMS_URL` فارغان؛ روابط Settings القانونية لن تُفتح في QA الحالية |
| P3-F-001 | P3 | مؤجل | Flutter نبّه إلى قرب انتهاء دعم Gradle 8.14، AGP 8.11.1، Kotlin 2.2.20؛ البناء الحالي نجح |

لا توجد P0 أو P1 مكتشفة في النطاق الآلي، لكن لا يمكن نفي عيوب runtime المادية قبل تنفيذ المصفوفة على جهاز.

## الملخص A–AZ

- **A–C الأجهزة:** لا أجهزة مادية؛ Android/iOS `NOT TESTED`.
- **D الاختبارات:** 370/370 `PASS — AUTOMATED ONLY`.
- **E analyze:** `No issues found!`.
- **F–H Portrait/Safe-area/Keyboard:** `NOT TESTED` ماديًا؛ العقود الآلية خضراء.
- **I Google:** `NOT TESTED` على جهاز؛ الإعداد الخارجي الساكن متاح.
- **J Apple:** `BLOCKED — EXTERNAL CONFIG`.
- **K Email:** `NOT TESTED`؛ provider متاح.
- **L Forgot Password:** `NOT TESTED`؛ لا flow فعّال.
- **M Deep links:** `PASS — AUTOMATED ONLY`، والحالات cold/warm/background غير مختبرة.
- **N–R Party:** `NOT TESTED` ماديًا؛ E2E/Board/Timer/Helpers/Restore آلية فقط.
- **S Tournament:** `NOT TESTED` ماديًا.
- **T Tournament gate:** `BLOCKED — BACKEND SECURITY GATE`.
- **U Solo:** `NOT TESTED` ماديًا، ويبقى LIMITED.
- **V Team Challenge:** `NOT TESTED` ماديًا.
- **W Ranking:** `PASS — AUTOMATED ONLY` بلا demo rows.
- **X Social:** `NOT TESTED` ماديًا.
- **Y–AB FCM:** initialization/delivery `NOT TESTED`؛ delivery عمليًا `BLOCKED — EXTERNAL CONFIG`.
- **AC–AI RevenueCat:** offering/price/purchase/cancel/pending/restore `BLOCKED — EXTERNAL CONFIG`؛ isolation `PASS — AUTOMATED ONLY`.
- **AJ Football:** public league load `PASS — AUTOMATED ONLY`؛ بقية المسار `NOT TESTED` ماديًا.
- **AK Media/network:** `NOT TESTED`.
- **AL Report:** `NOT TESTED` ماديًا؛ `PASS — AUTOMATED ONLY` للعقود.
- **AM Settings:** `NOT TESTED` ماديًا؛ persistence آلي، مع P2 للروابط القانونية الفارغة.
- **AN Sound/Haptics:** `NOT TESTED`.
- **AO Accessibility:** `NOT TESTED` ماديًا؛ text-scale آلي فقط.
- **AP Lifecycle:** `NOT TESTED`.
- **AQ Account isolation:** `PASS — AUTOMATED ONLY`؛ تبديل حسابين حقيقيين غير مختبر.
- **AR Online:** `PASS — AUTOMATED ONLY` أنه غير فعّال.
- **AS P0:** 0 مكتشفة آليًا.
- **AT P1:** 0 مكتشفة آليًا.
- **AU P2:** واحدة: الروابط القانونية غير مهيأة.
- **AV P3:** واحدة: ترقية toolchain مستقبلية.
- **AW الملفات:** هذا التقرير وAndroid Debug APK مولّد؛ لا تعديل Product UI ولا Goldens.
- **AX الحواجز الخارجية:** الأجهزة، Apple، RevenueCat، FCM test push، حسابات اختبار Auth/Store.
- **AY backend blockers:** Tournament mutation gate المقصود فقط؛ لم يُتجاوز.
- **AZ التأكيد:** لا Supabase db push، لا migration deployment، لا Online activation، لا Coins/Wallet/XP، لا Dark Mode، لا publishing، ولا final release AAB.

## المطلوب لاستئناف Phase F

توصيل جهاز Android مع USB debugging وموافقة ADB، وتوفير حسابات Google/Email تجريبية. لاختبارات الخدمات يلزم test push source مصرح وRevenueCat sandbox credentials. عندها تُنفذ المصفوفة المادية ويُحدّث هذا التقرير بدل منح اعتماد نظري.
