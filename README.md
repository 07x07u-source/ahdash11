# أحدعش | 11

منصة مسابقات كرة قدم عربية أولًا، مبنية كتطبيق Flutter ولوحة إدارة Next.js وخلفية Supabase. يوفّر المستودع مسارًا فعليًا من إدارة السؤال واستيراده إلى التدريب الفردي، وQuick Match، وغرف 1v1 و2v2، والأصدقاء والإشعارات والمتجر والترتيب، مع خادم صاحب القرار في النتائج والاقتصاد.

> المحتوى الرياضي المزروع في بيئة التطوير موسوم بوضوح كمحتوى تجريبي، وليس مرجعًا لحقائق رياضية. لا تُرفع وسائط أندية أو لاعبين إلا إذا كان لديك حق استخدامها.

## بنية المستودع

```text
.
├── mobile/       Flutter + Riverpod + go_router + Drift
├── admin/        Next.js + TypeScript + Tailwind
├── supabase/     PostgreSQL migrations, RLS, seed, Edge Functions
├── docs/         المعمارية وقاعدة البيانات والاستيراد والنشر
├── brand-package/ أصول الهوية المرفقة (مصدر التصميم)
└── codemagic.yaml Android/iOS CI/CD
```

## المتطلبات

- Flutter stable (الموصى به 3.32 أو أحدث) مع Android Studio/Android SDK.
- Node.js 22 أو أحدث وnpm 10 أو أحدث.
- Docker Desktop وSupabase CLI للتشغيل المحلي للخلفية.
- Firebase project عند تفعيل الإشعارات والتحليلات وCrashlytics.
- حسابات RevenueCat وAdMob عند تفعيل الاشتراك والإعلانات.
- Git وCodemagic لبناء iOS من Windows.

تم التحقق محليًا من تحليل Flutter واختباراته ومن لوحة الإدارة ووظائف Deno وبنية SQL. لا يتوفر Android SDK أو Docker في بيئة العمل الحالية، لذلك يبقى بناء AAB وتشغيل قاعدة Supabase/اختبارات pgTAP الفعلية من مهام CI أو جهاز التطوير المجهّز قبل الإصدار.

## بدء سريع

1. انسخ `.env.example` إلى الملفات المناسبة دون الالتزام بها في Git.
2. شغّل Supabase محليًا وطبّق المهاجرات.
3. شغّل لوحة الإدارة.
4. شغّل تطبيق Flutter بوضع development؛ عند غياب مفاتيح الخدمات يستخدم المشروع موفّرات تطوير واضحة بدل التوقف.

### Supabase محليًا

```bash
supabase start
supabase db reset
supabase functions serve --env-file supabase/.env.local
```

بعد `supabase start` انسخ عنوان API ومفتاح anon إلى `admin/.env.local` وإلى `--dart-define` لتطبيق Flutter. لا تستخدم service-role في المتصفح أو التطبيق مطلقًا.

### تطبيق Flutter على Windows

```bash
cd mobile
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d windows \
  --dart-define=APP_ENV=development \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=YOUR_LOCAL_ANON_KEY
```

لتشغيل Android استبدل `-d windows` بمعرّف المحاكي من `flutter devices`. يمكن تشغيل وضع العرض التجريبي دون بيانات اعتماد باستخدام قيم افتراضية فارغة؛ يظهر ذلك بوضوح داخل التطبيق ولا يُستخدم في production.

### لوحة الإدارة

```bash
cd admin
npm install
copy .env.example .env.local
npm run dev
```

افتح `http://localhost:3000`. في الإنتاج يجب أن يكون المستخدم مسجّلًا ويحمل دور `moderator` أو أعلى في `profiles.role`; الحماية موجودة في middleware وRLS وليست إخفاءً بصريًا فقط.

## رحلة تجريبية

1. نفّذ `supabase db reset` لتحميل الأقسام والأسئلة التجريبية.
2. افتح التطبيق واختر «الدخول كضيف».
3. من الرئيسية اضغط «ابدأ اللعب» واختر الأقسام والصعوبة.
4. أجب عن الأسئلة حتى شاشة النتيجة؛ يحتسب محرك النتيجة النقاط والسرعة، ويسجل التاريخ عندما تكون الخلفية متصلة.
5. للمباريات عبر الشبكة، يرسل العميل الاختيار فقط إلى وظيفة الخادم؛ لا تُرسل الإجابة الصحيحة مسبقًا.
6. من الملف الشخصي افتح «الأصدقاء والطلبات» للبحث والدعوات، ومن الجرس افتح مركز الإشعارات والانضمام إلى الغرف.

## استيراد Excel/CSV

القالب الأدنى:

```text
السؤال,الخيار الأول,الخيار الثاني,الخيار الثالث,الخيار الرابع,الإجابة الصحيحة,الصورة - اختياري
```

من لوحة الإدارة افتح **الاستيراد**، ارفع CSV أو XLSX، راجع الأخطاء والتكرار والتصنيف المقترح، ثم اعتمد الصفوف. التصنيف الحالي rule-based ويستخدم الكلمات المفتاحية واسم الملف وبيانات الأقسام. أي نتيجة منخفضة الثقة تحمل `needs_review=true` ولا تُنشر تلقائيًا. راجع [دليل الاستيراد](docs/question-import.md).

## الاختبارات والجودة

```bash
# Flutter
cd mobile
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage

# Admin
cd admin
npm run lint
npm test
npm run build

# Supabase
supabase db reset
supabase test db
deno test supabase/functions --allow-env
```

## بناء Android

1. ثبّت package ID الافتراضي `com.ahdash.eleven` أو غيّره في Android وiOS وFirebase وCodemagic وSupabase معًا قبل النشر النهائي.
2. أنشئ upload keystore وخزّنه خارج Git.
3. وفّر `android/key.properties` محليًا أو استخدم Android signing في Codemagic.
4. أضف `google-services.json` الصحيح.
5. شغّل:

```bash
cd mobile
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

الناتج في `mobile/build/app/outputs/bundle/release/`.

## بناء iOS عبر Codemagic

اربط GitHub بـCodemagic، ثم أنشئ مجموعات المتغيرات المذكورة في `codemagic.yaml`. أضف App Store Connect integration وbundle identifier وشهادة التوزيع/provisioning، وضع `GoogleService-Info.plist` كمتغير base64. يشغّل workflow الاختبارات والتحليل، يبني IPA موقّعًا، ثم يرفعه إلى TestFlight. راجع [دليل النشر](docs/deployment.md).

## إعداد Firebase وRevenueCat وAdMob

- Firebase: أنشئ تطبيق Android وiOS، أضف ملفات الإعداد خارج Git، فعّل FCM/Analytics/Crashlytics، ثم اختبر event تجريبيًا.
- RevenueCat: أنشئ entitlement باسم `premium` ومنتجات المتاجر، وضع مفاتيح SDK العامة فقط في التطبيق، ثم وجّه Webhook إلى `revenuecat-webhook` بترويسة Bearer المطابقة للسر المحفوظ.
- AdMob: استخدم test IDs في التطوير، فعّل UMP/consent، ولا تعرض إعلانًا أثناء السؤال. اضبط SSV لوحدة rewarded على `admob-reward`؛ لا يمنح الهاتف العملات مباشرة، بل بعد تحقق ECDSA على الخادم. الـfrequency cap يأتي من `game_settings`.
- FCM: اضبط حساب خدمة Firebase وأسراره، وجدول `dispatch-notifications` كل دقيقة لالتقاط الحملات المجدولة ومتابعة حملات fan-out على دفعات.

## قائمة الإنتاج

- [ ] استبدال كل مفاتيح وعناوين placeholder وربط بيئات dev/staging/prod منفصلة.
- [ ] تفعيل RLS وفحصه بحساب user/moderator/admin وservice-role.
- [ ] تشغيل Flutter analyze/tests وAdmin lint/test/build وSupabase tests في CI.
- [ ] التحقق من عدم وصول correct option إلى عميل online قبل إغلاق السؤال.
- [ ] إعداد سياسات الخصوصية والشروط وحذف الحساب وروابط المتاجر.
- [ ] التحقق من ملكية جميع الوسائط والأسئلة.
- [ ] إعداد signing وFirebase وRevenueCat وAdMob وUMP في المتجرين.
- [ ] اختبار أجهزة Android صغيرة/كبيرة وiPhone وRTL وtext scaling وoffline/reconnect.
- [ ] تشغيل مراقبة Crashlytics والتنبيهات ونسخ PostgreSQL الاحتياطية.
- [ ] مراجعة App Store/Google Play data-safety وعمليات حذف الحساب.

## الوثائق

- [المعمارية](docs/architecture.md)
- [قاعدة البيانات](docs/database.md)
- [استيراد الأسئلة](docs/question-import.md)
- [النشر والتشغيل](docs/deployment.md)
- [نموذج الأمان](docs/security.md)
- [أصول الهوية والوسائط](docs/assets.md)
- [الهوية والمراقبة التشغيلية](docs/monitoring-and-branding.md)
