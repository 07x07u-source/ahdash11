# V10 Phase D + E — Final Product Surfaces Report

## Phase D

**A. الشاشات:** 17، 18، 28، 29، 33، 34، 35، 36، 37 نُقلت إلى V10 Portrait.

**B. How to Play:** العقد المعروض هو 6 فئات/36 سؤالًا/فريقان/3 فئات لكل فريق، مع اختيار المساعدات وكشف المضيف ومنحه النقاط.

**C–D. Saved Games:** المصدر هو persistence الحالي لجلسات Party؛ الاستئناف يمر عبر resolver نفسه ولا يعيد بناء جلسة من بيانات البطاقة.

**E–F. Match/Online:** Classic وTrue/False وSpeed فعالة. البقية «قريبًا». Online مؤجل ومساراته لا تنشّط gameplay.

**G–H. Solo:** دُقق controller/service/session/result. القرار **LIMITED**: المحرك حقيقي، والواجهة تقصر الخيارات على الموجود فعليًا.

**I–J. Team Challenge:** route/provider/repository/RPC وقواعد المحاولة والنتيجة موجودة؛ القرار **IMPLEMENTED** مع fail-closed عند غياب الخادم.

**K–M. Ranking:** مصدر production الحقيقي فقط، بلا tabs شكلية وبلا demo leaderboard.

**N–Q. Friends:** Social repository الحقيقي، بحث خادمي keyboard-safe، لا presence، وCTA التحدي متسق مع Team Challenge الفعّال.

**R–S. Blocked:** block-list الحقيقي؛ فك الحظر محمي من التكرار ولا يعرض raw error أو نجاحًا كاذبًا.

**T–V. Team Detail:** بيانات الفريق والأعضاء الحقيقية والدور والدعوة فقط. member count مشتق من المجموعة. لا stats أو levels أو recent results مصطنعة.

**W–X. الاستجابة والكيبورد:** 360×800، 390×844، 393×852، 412×915، 430×932 × 1.0/1.2/1.3؛ وبحث Friends عند 360 و390 مع inset 300.

**Y–Z. Goldens:** 20/20؛ راجعت يدويًا How to Play، Saved، Match، Solo، Team Challenge، Ranking، Friends Keyboard، Blocked وTeam Detail.

**AA–AB. الاختبارات:** Phase D المركزة 21/21؛ الانحدار الموجه 201/201. بوابة broad النهائية موثقة أدناه.

## Phase E

**AC–AD. Profile:** `get_my_profile_summary` وبيانات الحساب/تفضيلات الكرة الفعلية؛ لا XP/Level/fake stats، ومع Player 11 الرمزي.

**AE–AG. Notifications/FCM:** المستودع الحقيقي وحالات empty/loading/error وread/deep-link الآمن. FCM مهيأ برمجيًا للforeground/background/terminated، لكن الاختبار الفيزيائي مؤجل.

**AH–AI. Settings:** الصوت والاهتزاز وتقليل الحركة وتفضيلات الإشعارات والحساب والكرة وPremium والدعم/القانون. أزيل/غاب Power Saving وDark Mode والاقتصاد. الصوت والاهتزاز persisted، ولا optimistic success عند الفشل.

**AJ. عزل الحساب:** auth state يعيد بناء providers؛ sign-out ينظف notifications وRevenueCat وcrash identity وSupabase. اختبارات in-flight epoch تمنع تسرب نتائج الحساب السابق.

**AK–AM. Report:** RPC الحقيقي، sanitization، حد 5/24h، duplicate guard وtimeout غير مؤكد، مع scroll/insets وCTA قابل للوصول.

**AN–AQ. Football:** RPCs المنشورة، بحث حقيقي ولا أعداد ثابتة. URL لا يُستخدم إلا لحالة حقوق مرخصة/مخصصة وإلا badge ثابت. الحفظ ينتظر RPC، وprovider مربوط بالحساب.

**AR–AU. Premium source/prices:** RevenueCat current offering وentitlement `premium` الافتراضي. الشهري/السنوي حسب توافر package، والأسعار من `StoreProduct.priceString` المحلي فقط.

**AV–AY. Premium behavior:** وصف غير تنافسي فقط؛ purchase/restore/cancel/failure/entitlement refresh حقيقية على مستوى الكود. restore لا ينجح بلا entitlement. account epoch وRevenueCat logIn/logOut يمنعان الحالة القديمة.

**AZ–BB. Economy routes:** لا Coins/Wallet UX فعّال. `/store` → `PremiumScreen`، و`/wallet` → `/store`.

**BC–BD. Auth:** Google لم يتغير. Apple مطبق في الكود، بينما إعداد المزود والتحقق على جهاز حقيقي غير مُدّعى.

**BE–BF. الاستجابة والكيبورد:** الأحجام الخمسة × 1.0/1.2/1.3؛ Report وFootball Search عند 360/390 مع inset 300.

**BG–BH. Goldens:** 18/18؛ راجعت Profile bottom، Notifications empty، Settings، Report Keyboard، Football Keyboard/long names، Premium compact/CTA/price/loading.

**BI. الاختبارات المركزة:** 24/24.

## Final Global

**BJ–BM. الانحدار:** Auth/Home وParty وTournament وPhase D ضمن المجموعة النهائية أدناه، مع بقاء اختبارات Party وTournament الموجهة خضراء قبل البوابة النهائية.

**BN. Broad suite:** 370/370 نجحت في التشغيل المتسلسل الكامل: `contracts/core/features/shared/v10_phase_a..e`.

**BO. Analyze:** `No issues found!` (92.2s).

**BP. Landscape cleanup:** أزيلت التركيبات الفعالة Landscape-only لهذه الأسطح، واستُبدل shell النشط بشريط تنقل سفلي عمودي. بقي domain/repository/provider والتوافق القديم غير الفعّال.

**BQ. الملفات:** shared V10 scaffold/panel/title/message state/app shell، وشاشات Party/Match/Solo/Ranking/Social في D، وشاشات Profile/Notifications/Settings/Report/Football/Premium في E، واختبارات/Goldens/التقارير الخاصة بالمرحلتين.

**BR. Figma:** الوصول المباشر للملف `1tbYuMwiC8b9vCj12TzbAA` غير مصادق (`UNAUTHORIZED`)؛ استُخدمت مواصفة V10 المقفلة والأساس المشترك كما يسمح الطلب.

**BS–BU. القيود المتبقية:** اختبارات FCM وRevenueCat وGoogle/Apple والكيبورد والتثبيت/انتهاء entitlement على أجهزة فعلية تنتظر مرحلة Physical Device QA. migrationا gameplay وtournament ما زالتا pending؛ SHA-256 بقيتا `C4968EA1824A3D9BBE942BABD3DE27F0F3267AF88DD834A4458861424267CCD1` و`E4422D46197D187B50F544A2828667B3492F96F3C55BE7786420CCB122559E14`.

**BV. التأكيد:** لم يحدث Supabase db push، ولا migration deployment، ولا Online activation، ولا Dark Mode، ولا Coins/Wallet/XP، ولا APK/AAB، ولا نشر.
