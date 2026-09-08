# تقرير التسليم النهائي — أحدعش | 11

التاريخ: 2026-08-28  
النطاق: Product Polish + gameplay contract v2 + Android Release APK.  
القيود الملتزم بها: لم يُشغّل Emulator، لم يُثبّت APK، لم تُطبّق migrations على Supabase، ولم تتغير هوية الحزمة أو مفاتيح التوقيع.

## A — التصميم

- طُوّر نظام التصميم الحالي بدل إنشاء نظام موازٍ، مع ألوان دلالية ومسافات وحواف وحركة موحدة.
- صُممت الشاشات كلعبة كرة قدم عربية mobile-first، مع استغلال أفضل للمساحة على المقاسات الصغيرة.
- بقيت الحالات loading/empty/offline/error صريحة، ولم تُخفَ الوظائف غير المكتملة خلف مسارات مكسورة.

## B — الخطوط واللغة

- أضيف Noto Kufi Arabic وTajawal محليًا من مصدر OFL رسمي، بلا تحميل runtime من Google Fonts.
- دُعمت RTL، الأرقام المختلطة، التفاف السؤال، text scaling، وواجهات عربية رسمية واضحة.

## C — التنقل

- شريط رئيسي من خمس وجهات: الرئيسية، العب، الاستراحة/الفرق، الترتيب، الملف الشخصي.
- المتجر بقي وجهة ثانوية، والمسارات القديمة بقيت متوافقة.

## D — الرئيسية

- أصبحت game-first مع زر «العب الحين» واضح، وأنواع اللعب والتحديات والمحتوى في ترتيب بصري أوضح.
- أضيفت معالجة صريحة لحالات البيانات البعيدة والانقطاع.

## E — Play Hub والإعداد

- فُصل Game Type عن Game Format.
- Classic وSpeed وTrue/False مفعّلة بالعقود المنفذة، بينما Ordering وClub Guess وEagle Eye تظهر «قريبًا» بلا route مكسور.
- التدريب المحلي موسوم بوضوح بأنه غير مصنف وبلا مكافآت تنافسية.

## F — محرك اللعب

- أضيف Flame `1.38.2` للمسرح والمؤثرات فقط، مع بقاء النص العربي الطويل والأزرار وSemantics في Flutter.
- `GameSessionController` يقفل الإدخال قبل الطلب، ويحمل idempotency key وclient sequence، ويصحح ساعة الخادم، ويعيد نفس payload بعد النتيجة المجهولة، ويتجاهل النتائج المتأخرة بعد dispose.
- `GameWidget` ثابت، والجسيمات محدودة وتصبح صفرًا عند Reduced Motion.

## G — أنماط اللعب

- Classic: أربعة خيارات وعقد تنافسي آمن.
- Speed: يستخدم pool Classic مع مهلة خادم 7 ثوانٍ.
- True/False: خياران ثابتان «صح/خطأ»، pool مستقل، ومهلة خادم 10 ثوانٍ.
- لم يُدّع اكتمال الأنماط الثلاثة المؤجلة.

## H — Player 11

- أضيف اختيار Player11 ذكر/أنثى ويحفظ محليًا ويظهر في onboarding/profile/settings/social.
- الأصول static وآمنة كبديل؛ لا ادعاء Rive أو Spine لعدم وجود ملفات مرخصة فعلية.

## I — الأصول

- `player11-male-card.png`: ‏2,115,482 bytes، SHA-256 `E12C0929598CA470AC21912BEBD56C6CE3B16BA32A01DA48B3EDDB9EAFB0663D`.
- `player11-female-card.png`: ‏1,893,746 bytes، SHA-256 `2349A7D589A4F59296101449E5131C1F3F6F7724264788D0D053DE2B025C6C95`.
- لا نصوص أو شعارات أندية أو أطقم رسمية أو شبه شخص حقيقي في هذين الأصلين. تفاصيل المصدر والاستخدام في `docs/game-assets-map.md`.

## J — Onboarding

- اختيار Player11 محفوظ، ويمكن تأجيل اختيار الدوري والنادي بوضوح إلى ما بعد الدخول.
- بقيت استعادة المسار والمصادقة ضمن العقود الحالية.

## K — الدوريات

- وُثقت المصادر الرسمية لست دوريات، لكن عدد سجلات الدوريات المحلية المزروعة في هذه الجولة هو `0`.
- لم يُفحص عدد سجلات مشروع Supabase البعيد لأن remote access/push خارج النطاق.

## L — الأندية

- البحث يدعم العربي/الإنجليزي/aliases ومسار fallback إجرائي.
- عدد سجلات الأندية المحلية المزروعة في هذه الجولة هو `0`؛ البعيد غير معلوم دون اتصال بالمشروع الحقيقي.

## M — الحقوق

- عرض الشعار مربوط بحالة الحقوق `licensed/custom/fallback`، ولا يُعرض شعار غير موثق تلقائيًا.
- لم تُنسخ شعارات أو صور أطقم رسمية جديدة.

## N — الإعدادات

- هيدر حساب مع Player11، اختيار كرة القدم، مجموعات مظهر/صوت/اهتزاز/حركة/إشعارات، ومنطقة الخطر في النهاية.
- القيمة الافتراضية للترويج بقيت off عند غياب القيمة.

## O — الملف الشخصي

- أعيد تنظيمه كبطاقة لاعب: الهوية والمستوى وXP ثم الهوية الكروية والأداء والمحتوى.

## P — الأسئلة وAdmin

- محرر Admin ينشئ Classic بأربعة خيارات أو True/False بخياري «صح/خطأ» عبر RPC ذري ومقيّد بالدور.
- فُصل `gameplay_type` عن نوع الوسائط `text|image`، وصُححت مطابقة import من index صفري إلى موضع DB يبدأ من 1.
- أضيف فصل بين الأسئلة التنافسية وأسئلة التدريب ذات مفتاح الإجابة المحلي.

## Q — النتائج

- النتائج التنافسية تعرض قيم الخادم فقط، ولا يخمّن العميل coins/XP/rank.
- نتائج Practice منفصلة وموسومة بأنها محلية وغير مصنفة.

## R — الصوت واللمس

- استُخدم SystemSound وhaptics فقط؛ لم تُضف ملفات صوت غير مرخصة ولم يُضف `flame_audio` بلا حاجة.

## S — الجسيمات والمؤثرات

- مؤثرات Flame محدودة، وتُعطّل مع Reduced Motion.
- لا shaders ثقيلة ولا ادعاء أداء GPU قبل القياس على جهاز حقيقي.

## T — Tiled

- لم يُضف؛ لا توجد خريطة tile-based تبرر الاعتماد.

## U — Forge2D

- لم يُضف؛ الفيزياء المطلوبة لهذه الجولة بسيطة ولا تحتاج محرك أجسام.

## V — الاجتماعي والترتيب

- صُقلت الاستراحة والأصدقاء والفريق والتحديات وMVP دون تغيير صلاحيات الخادم.
- يظهر موقع المستخدم في بطاقة ثابتة حتى إن كان خارج أول 100.
- إرسال Team Challenge أصبح idempotent، ويحتفظ العميل بنفس الاختيار والمفتاح والتسلسل عند نتيجة شبكة مجهولة ويتيح «إعادة آمنة».

## W — الأمان وسلطة الخادم

- migration الجديدة فقط: `20260828000400_gameplay_contract_v2.sql`؛ migration المطبقة السابقة لم تتغير.
- لا يتسرب مفتاح الإجابة في payload التنافسي، والوقت والنتيجة والثوابت الحسابية من الخادم.
- إعدادات الغرف والمباريات allowlisted، وقيم scoring المرسلة من العميل تُتجاهل.
- قيد معروف: عداد `assert_rate_limit` داخل transaction فاشلة قد يتراجع مع rollback؛ محاولات النجاح محدودة، لكن invalid-spam يحتاج rate limit عند حد غير قابل للتراجع مثل Edge/platform قبل وصفه مكتملًا بالكامل.

## X — الأداء

- فُحصت البنية static: لا rebuild كامل لـGameWidget كل tick، الجسيمات محدودة، والـlisteners/timers تُنظف.
- APK النهائي 84.37 MiB، بزيادة 4.75 MiB عن النسخة المرجعية، وأقل من حد المراجعة 110MB.
- frame time وANR والذاكرة وstartup و60fps تبقى اختبارات profile يدوية على هاتف حقيقي.

## Y — الاختبارات الآلية

| الفحص | النتيجة |
|---|---|
| `dart format .` | 133 files، 0 changed، exit 0 |
| `flutter analyze --fatal-infos` | No issues found، exit 0 |
| `flutter test` | 78 passed، 0 failed، exit 0 |
| Admin lint | exit 0، بلا warnings |
| Admin typecheck | exit 0 |
| Admin tests | 10 files / 43 tests passed |
| Admin production build | نجح، 16/16 static pages |
| Deno fmt | 13 files checked، exit 0 |
| Deno check | 12 TypeScript files، exit 0 |
| PostgreSQL parser | كل 15 migrations و5 pgTAP files، 20/20 passed |

## Z — قاعدة البيانات

- لم يحدث `supabase db push` ولم يتغير المشروع البعيد.
- migration 007 و008 و009 وكل SQL المحلي مرّ عبر PostgreSQL `libpg_query` parser فعلي.
- اختبار pgTAP الجديد يحتوي 42 assertion، لكنه لم يُنفذ على PostgreSQL حي لعدم توفر instance محلي؛ التطبيق والتكامل على مشروع Supabase الحقيقي ما زالا pending.

## AA — Android APK

- **BUILD STATUS:** SUCCESS
- **APK:** `C:\dev\ahdash11\mobile\build\app\outputs\flutter-apk\app-release.apk`
- **APK SIZE:** 88,470,244 bytes / 84.37 MiB
- **BUILD TYPE:** Release Signed
- **PACKAGE:** `com.ahdash.eleven`
- **APK SHA-256:** `15B9AA72EDE790BC6EE9EE862C6E99D1D841AB0C98182931A3EC20AEDFD51513`
- `apksigner` verification: valid، APK Signature Scheme v2 = true.
- certificate SHA-256: `43475f354b73f4d2c9ad45663abfd6dffa86259303f91d1b2ed6a49383c18647`، ومطابق للنسخة المرجعية؛ لم يتغير keystore.
- بُني بالأمر المطلوب حرفيًا: `flutter build apk --release --dart-define-from-file=.env`.
- إعدادات Google Sign-In موجودة ومفعلة في Release، وموارد `default_web_client_id` و`google_app_id` موجودة داخل APK.
- إعدادات Firebase/FCM موجودة ومفعلة، وموارد `gcm_defaultSenderId` موجودة داخل APK.
- وجود الإعداد لا يعني أن تسجيل Google أو FCM يعمل فعليًا؛ ذلك يتطلب اختبار الهاتف والمشروع البعيد.

## AB — قائمة الاختبار اليدوي

- تثبيت نظيف ثم إنشاء حساب/دخول email وGoogle.
- Home والمحتوى والصور من Supabase، ثم Offline/Loading/Error.
- Light/Dark/System، RTL، TalkBack، text scale، Reduced Motion.
- Practice و1v1 و2v2 والنظام إن كان متاحًا، مع قطع الشبكة والخلفية والاستئناف.
- Wallet/coins/rewards، FCM token، استقبال الإشعار، وdeep links.
- مراقبة startup/frame time/memory/ANR على الجهاز الحقيقي.

## AC — الحدود الصريحة

- لم يُشغّل Emulator ولم يُثبّت التطبيق تلقائيًا.
- لم تُختبر Google Sign-In أو FCM أو 1v1/2v2 فعليًا على جهاز أو Supabase بعيد.
- Ordering وClub Guess وEagle Eye غير مكتملة ومقفلة كـ«قريبًا».
- لا claim لعدد بيانات بعيد، 60fps، Rive، Spine، Tiled، Forge2D، أو صوت مخصص.
- تحذيرات البناء مستقبلية فقط حول Gradle 8.14.0 وAGP 8.11.1 وKotlin 2.2.20؛ لم تُرفع الإصدارات لأن البناء نجح ولا توجد ضرورة حالية.

## AD — أهم الملفات المتغيرة

- Flutter: design system، shell/navigation، Home/Play/setup، online/practice game، Player11، settings/profile/social/ranking/football.
- Admin: question editor، import DB contract، question APIs/tests.
- Supabase: migration `20260828000400_gameplay_contract_v2.sql`، pgTAP `005_gameplay_contract_v2_security.sql`، ووظائف matchmaking/room/answer.
- التوثيق: audit، architecture، assets، football sources، ADRs، QA matrix، وهذا التقرير.

## AE — تغييرات الاعتماد

- `flame: 1.38.2`
- `flame_test: 2.3.1`
- `uuid: ^4.5.2`
- لم تُضف Rive/Spine/flame_audio/Tiled/Forge2D.
