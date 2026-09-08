# أحدعش | 11 — تقرير الإصدار V5

التاريخ: 2026-08-31  
الحالة: **جاهز للاختبار اليدوي على جهاز Android حقيقي**

## نتيجة البناء

- BUILD STATUS: SUCCESS
- النوع: Release Signed
- الحزمة: `com.ahdash.eleven`
- APK: `C:\dev\ahdash11\mobile\build\app\outputs\flutter-apk\app-release.apk`
- الحجم: 93,627,177 بايت (89.29 MiB)
- SHA-256: `EBB7A6B7C0E1DBBAB9E3C158064FF72355CE8CEC26BF314C9C9B1A7F8CF5D471`
- التوقيع: تحقق `apksigner` بنجاح؛ APK Signature Scheme v2 مفعّل.
- البيئة: بُنيت النسخة بالأمر `flutter build apk --release --dart-define-from-file=.env`.

نجاح البناء يؤكد سلامة التجميع ووجود الإعدادات، ولا يُعد إثباتًا أن Google Sign-In أو FCM أو Supabase أو أطوار اللعب تعمل فعليًا على الشبكة. هذه النقاط تتطلب الاختبار اليدوي على الهاتف.

## إعدادات Release الموجودة

- ملف `android/app/google-services.json` يحتوي عميل Android للحزمة الصحيحة وعميل OAuth Web.
- موارد `google_app_id` و`default_web_client_id` و`gcm_defaultSenderId` موجودة داخل APK.
- `FirebaseInitProvider` وخدمة `FlutterFirebaseMessagingService` موجودتان في Manifest المجمّع.
- `GOOGLE_AUTH_ENABLED` و`FIREBASE_ENABLED` مفعّلان في ملف البيئة المستخدم للبناء.
- إعدادا Supabase URL وAnon Key موجودان في ملف البيئة المستخدم، من دون تسجيل قيمهما في هذا التقرير.
- استُخدمت إعدادات التوقيع والـkeystore الموجودة أصلًا؛ لم تُنشأ أو تُستبدل مفاتيح.

## الهوية البصرية

- المصدر القانوني للشعار: `brand-package/ahdash_11_brand_package/assets/branding/`.
- نسخ التشغيل في Flutter وAdmin مطابقة بايتًا للمصدر.
- أُزيل الشعار المرسوم برمجيًا؛ كل مواضع الهوية تستخدم أصل الشعار الرسمي أو قيمة Branding Center المنشورة مع fallback رسمي.
- SHA-256 للشعار الأفقي: `A08C946F52F43D1D27AE48E591997CABD1B4629169723CF0E8DF16236CBCCC6B`.
- SHA-256 للـwordmark: `C5D46F52E34462102B4CEF122C47820EE29ADD06847B065F72186C222EB59882`.
- SHA-256 للرمز: `68F5F95D25F0785751976FB28D830CCACDEC78A199727A35371F9798163EB310`.

## نظام التصميم التحريري

- Light: ورق `#F4EBDD`، سطح `#FBF7EF`، سطح مرتفع `#FFFCF7`، muted `#E8DCC8`، حبر `#1B1916`، حبر ثانوي `#38332C`، خط فاصل `#D5C8B6`.
- Dark: خلفية دافئة `#171613`، سطح `#211F1B`، مرتفع `#292620`، حبر فاتح `#F4EBDD`، ثانوي `#D7C6AC`.
- الأخضر أصبح لون فعل/حالة مضبوطًا (`#5F8F0F` و`#78A91B`) بدل تغطية الواجهات؛ بقي في CTA اللعب، الاختيار، النجاح، والمؤشرات الرياضية.
- الذهبي مقيّد بـPremium والبطولة/البطل والحالات الفاخرة.
- قلّت البطاقات والظلال والتدرجات والزوايا الكبيرة، واعتمدت الواجهات أسطحًا مسطحة وخطوطًا تحريرية رفيعة.
- الخط: Thmanyah Sans بأوزان Regular وMedium وBold وBlack في Flutter وAdmin، مع أدوار عرض Serif المرخصة حيث يلزم.

## الشاشات المنفذة

- الرئيسية: masthead رسمي، قصة لعب رئيسية 57/43، قصة بطولة ثانوية، وصفوف فئات مصوّرة.
- الفئات: قصة مصوّرة مميزة وصفوف تحريرية بدل شبكة بطاقات متساوية.
- اختيار فئات Party: صورة مميزة، صفوف غير متماثلة، focal point، وحد اختيار رفيع.
- لوحة Party: رؤوس فئات مصوّرة، نقاط وخطوط دقيقة، وحالة فريق واضحة.
- السؤال والكشف: السؤال عنوان تحريري، تقسيم مخصص للصورة، وكشف إجابة واضح بلا بطاقة زائدة.
- Auth وProfile وPremium وSettings وHow-to وTournament وLaunch: الشعار الرسمي والسطوح والألوان والخط V5.
- Admin: محرر صورة الفئة، اختيار Media Library، preview واسع/مدمج، focal X/Y، metadata والحقوق، وحالة media health.
- محرر السؤال المصوّر يختار أصلًا من Media Library مع caption وfocal point بدل رابط صورة عشوائي.

## الفئات والوسائط

- التدقيق البعيد القرائي قبل تطبيق migrations: 22 فئة نشطة، فئة واحدة لها cover، و21 فئة بلا cover.
- الفئة ذات الصورة الحالية: «عين الصقر»؛ حقوق أصلها تحتاج مراجعة من Admin لأن صلاحية join لم تكن متاحة للـanon audit.
- Migration V5 لا يعطّل الصفوف المنشورة القديمة تلقائيًا. يفرض الصورة والحقوق عند النشر الجديد، الانتقال إلى Published/Active، أو تغيير الصورة.
- بوابة الجاهزية التحريرية: يجب تزويد الفئات الـ21 بصور أصلية/مولدة/مرخصة قبل اعتبار المحتوى المصوّر مكتملًا.
- الصيغ المدعومة فعليًا الآن: open answer، multiple choice، true/false، وimage.
- zoom/audio/video غير مفعلة للنشر لأن renderer وأنواع الوسائط الخاصة بها غير مكتملة؛ لم تُعلن دعمًا غير موجود.

## قاعدة البيانات

- Migration الجديدة: `20260831000300_editorial_brand_category_media_v5.sql`.
- PostgreSQL parser فعلي: 23 migration و135 جسم PL/pgSQL نجحت، بما فيها 007 و008 و009 وV5.
- `supabase db push --dry-run` نجح، ولم يُنفذ أي push فعلي.
- migrations المعلّقة حسب dry-run:
  - `20260831000100_party_v2_category_controls.sql`
  - `20260831000200_tournaments_v1.sql`
  - `20260831000300_editorial_brand_category_media_v5.sql`
- ترتيب النشر المطلوب: migrations أولًا ثم Admin/Mobile، لأن واجهات Admin الجديدة تعتمد الأعمدة وRPCs الجديدة.

## التحقق النهائي

- `flutter analyze --fatal-infos`: ناجح بلا ملاحظات.
- `flutter test`: 427 اختبارًا ناجحًا.
- Goldens: 110 صورة للشاشات العامة + 130 صورة Party + 80 صورة Tournament، عبر 800×360 و844×390 و915×412 و1280×720 و1366×768، Light وDark.
- تمت مراجعة لقطات فعلية للرئيسية والفئات وAuth وProfile وPremium وSettings وParty وTournament.
- Admin Vitest: 11 ملفات و52 اختبارًا ناجحًا.
- Admin ESLint: ناجح.
- Admin TypeScript: ناجح.
- Admin Production Build: ناجح.
- لم يُشغّل Emulator، ولم يُثبّت APK تلقائيًا، ولم يُنفذ Supabase migration فعلي.

## قائمة الاختبار اليدوي

يُختبر على الجهاز الحقيقي: إنشاء الحساب والدخول، Google Sign-In، Supabase والمحتوى الديناميكي والصور، Light/Dark، 1v1 و2v2 واللعب ضد النظام عند إتاحته، Wallet/Coins، FCM وتسجيل Device Token والإشعارات، Offline/Loading/Error، RTL والعربية، والأداء والتنقل.
