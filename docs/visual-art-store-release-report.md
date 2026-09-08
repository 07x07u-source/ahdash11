# VISUAL ART + STORE RELEASE REPORT

الحالة: مكتمل محليًا مع APK Release موقعة؛ لا Supabase push ولا Emulator ولا تثبيت APK.

## A. VISUAL DIRECTION

تحولت Home وPlay والمتجر من شبكة Flutter متساوية إلى Hero وصور edge-to-edge وطبقات نصية واضحة. `AhdashPageBackground` و`AhdashHeroArtwork` و`AhdashImageTile` و`AhdashImageEmptyState` توحّد الصور والـscrim والـSemantics من دون Design System موازٍ.

## B. COIN IDENTITY

هوية ذهبية أصلية تحمل `11` وهندسة كرة قدم ولمسة Lime. الملفات والمقاسات والاستخدامات موثقة في `docs/coin-identity.md`. المكونات: `AhdashCoinIcon/Balance/Price/Reward`، مع count-up/haptic واحترام Reduced Motion.

## C–E. BACKGROUNDS / HOME / PLAY HUB

ثماني خلفيات محلية مختلفة، وثلاثة mode artworks. Home لها focal Hero وCTA ومكافأة/team/rank banners؛ Play يفصل Classic بصريًا عن True/False وSpeed، ولا يفعّل الأنماط المؤجلة.

## F. STORE

Hero متجر لعبة، رصيد وWallet CTA، المميز/الجديد/مقتنياتي وثماني فئات، 20 منتجًا مختلفًا بصريًا، grid lazy بنسبة صورة تقارب 70%، وBottom Sheet للمعاينة والسعر والموقع التجميلي والحالة. Premium مفصول عن الكوينز ويستخدم RevenueCat الحالي مع Restore Purchases، ولا يحاكي نجاح دفع.

## G–H. INVENTORY / WALLET

الملكية والتجهيز يأتيان من `user_inventory`. «مقتنياتي» لا تعرض غير المملوك، وتعرض `مملوك/مستخدم`. Wallet تقرأ ledger فقط وتعرض balance/history؛ Flutter لا يخصم الرصيد ولا يضيف ملكية محليًا.

## I. STORE SECURITY

المmigration الجديدة `20260829000100_visual_store_v1.sql` تزرع الكتالوج وتضيف `purchase_store_item_v2` و`equip_store_item_v2` وreceipts محجوبة بـRLS. الخادم يقفل المحفظة، يقرأ السعر والحالة، يمنع double purchase قبل debit، يعيد receipt لنفس key، ويفصل equip حسب category. Edge Function ترسل فقط item id وidempotency key وclient sequence. لا يوجد p_price أو quantity تجميلية من العميل.

## J–K. ASSETS / ICON REDUCTION

49 ملف runtime جديدًا بحجم 1,865,947 bytes / 1.78 MiB؛ الإجمالي موثق تفصيليًا في `docs/game-assets-map.md`. Home: 14→1 icons، Store: 22→0، Profile: 35→20، Team detail: 32→20، Play: 0 decorative icons. المصدر غير المضغوط للعملة غير معلن في pubspec ولا يدخل APK.

## L. ACCESSIBILITY

RTL أصلي، النص العربي Flutter وليس داخل الصور، decorative images مستبعدة من Semantics، صور المنتجات لها labels نصية، الحالات لا تعتمد على اللون وحده، touch targets من Theme، Light/Dark scrims، وReduced Motion في مكون الرصيد. الـGolden harness يحمّل Tajawal/Noto Kufi فعليًا.

## M. PERFORMANCE

WebP 720² للبطاقات و768×1152 للخلفيات، `cacheWidth` في الصور المشتركة، SliverGrid lazy، لا precache لجميع المنتجات. Runtime assets أصبحت 17,740,016 bytes مقابل baseline 15,874,069: زيادة 1,865,947 bytes فقط. APK أصبح 86.33 MiB مقابل 84.37 MiB تقريبًا: زيادة 1.96 MiB، وتحت هدف 100 MiB وحد 110 MiB.

## N. TESTS

- PostgreSQL parser: PASS.
- PL/pgSQL parser: PASS، 2/2 functions hydrated.
- `deno fmt` و`deno check`: PASS.
- Visual goldens: 30/30 PASS؛ 3 مقاسات × Light/Dark × 5 شاشات/حالات.
- `dart format .`: PASS، 138 ملفًا مفحوصًا.
- `flutter analyze --fatal-infos`: PASS، بلا issues.
- `flutter test`: PASS، 108/108.
- pgTAP security suite: الملف `006_visual_store_v1_security.sql` أُنشئ واجتاز parser، لكنه لم يُنفذ لعدم توفر PostgreSQL/Docker محلي؛ لا يُدّعى نجاحه runtime.

## O. MIGRATIONS

`supabase/migrations/20260829000100_visual_store_v1.sql` فقط. لم تُعدل migration قديمة ولم يُنفذ `supabase db push`.

## P. APK

- Path: `C:\dev\ahdash11\mobile\build\app\outputs\flutter-apk\app-release.apk`
- Build: Release Signed، APK Signature Scheme v2 verified.
- Size: 90,525,382 bytes / 86.33 MiB.
- SHA-256: `0B3396434E8C3F22C722D47CB8BB73DDE4F16C8DBC66DBD6B7D03D30D05FA1C1`.
- Package: `com.ahdash.eleven`، versionName `0.1.0`، versionCode `1`.
- Certificate SHA-256: `43475f354b73f4d2c9ad45663abfd6dffa86259303f91d1b2ed6a49383c18647`.
- Build command استخدم `--dart-define-from-file=.env`؛ ملف `.env` نفسه غير موجود داخل APK.
- فحص الحزمة وجد 4/4 أصول Coin و20/20 product previews، ولم يجد token source PNG.
- إعدادات Release الحالية: `GOOGLE_AUTH_ENABLED=true` و`FIREBASE_ENABLED=true` من دون طباعة قيم سرية؛ `google-services.json` وGradle plugin و`firebase_messaging` موجودة، وSupabase URL/anon-key غير فارغين.

## Q. KNOWN LIMITATIONS

- لم تُختبر عملية شراء Coins أو RevenueCat أو equip على Supabase حقيقي في هذه الجولة؛ الاختبار اليدوي مطلوب.
- pgTAP لم يُنفذ محليًا لغياب Docker/PostgreSQL؛ migration لم تُدفع إلى أي مشروع.
- لا توجد Goldens فعلية بعد لـProfile/Results/Team/Leaderboard أو مصفوفة large-text لكل لقطة؛ توجد تغييرات خلفية واختبارات widget عامة، ولا يُدّعى اكتمال المصفوفة المطلوبة.
- الأصول مولدة وآمنة بحسب القيود المستخدمة، لكن مراجعة بشرية للحقوق قبل النشر التجاري تظل مطلوبة.
- لا يدّعي البناء أن Google Sign-In/FCM/1v1/2v2 تعمل؛ هذه تكاملات اختبار جهاز حقيقي.
