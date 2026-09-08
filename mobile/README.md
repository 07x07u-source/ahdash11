# تطبيق أحدعش | 11

تطبيق Flutter عربي أولًا لمسابقات كرة القدم. يحتوي هذا المجلد على تجربة فردية كاملة تعمل دون أسرار خارجية، مع طبقات تكامل اختيارية لـ Supabase وFirebase وRevenueCat وAdMob. اللعب الشبكي مصمم ليكون server-authoritative ولا يرسل الإجابة الصحيحة ضمن حمولة السؤال العامة.

## التشغيل

1. ثبّت Flutter stable وتأكد من `flutter doctor`.
2. نفّذ `flutter pub get` داخل هذا المجلد.
3. شغّل `flutter run` للحصول على وضع التطوير المحلي.
4. لتفعيل Supabase مرّر القيم:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

لا تُمرّر `service_role` إلى التطبيق. عند غياب الإعدادات يستخدم التطبيق Drift/SQLite وبيانات Demo معلّمة بوضوح. البيانات التجريبية ليست ادعاءات رياضية موثقة.

## الخدمات الاختيارية

Firebase لا يبدأ إلا عند `FIREBASE_ENABLED=true` وبعد إضافة `google-services.json` أو `GoogleService-Info.plist`. RevenueCat يحتاج `REVENUECAT_ANDROID_API_KEY` أو `REVENUECAT_IOS_API_KEY`. AdMob يحتاج `ADMOB_ENABLED=true` ومعرّفات التطبيقات والوحدات الإعلانية الخاصة بالبيئة. التطبيق يطلب موافقة UMP قبل الإعلان، ومكافأة rewarded لا تُضاف من الهاتف بل عبر AdMob SSV الموثّق. جميع المفاتيح العامة تُمرّر عبر `--dart-define` أو إعداد CI؛ لا تحفظ الأسرار في Git.

## الاختبارات والبناء

```bash
flutter analyze
flutter test
flutter test integration_test
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

لبناء iOS استخدم خط Codemagic في جذر المستودع بعد إضافة App Store Connect API key والشهادات إلى فريق Codemagic. معرّف الحزمة الافتراضي `com.ahdash.eleven` ويجب تثبيته في Apple Developer وFirebase وRevenueCat قبل الإطلاق.

## حدود الأمان

حساب النقاط المحلي خاص باللعب الفردي فقط. المطابقات المصنفة والغرف ترسل اختيار اللاعب إلى RPC/Edge Function، ويجب أن يتحقق الخادم من التوقيت والجواب والنقاط والمحفظة. لا يُستخدم fallback المحلي لإيهام المستخدم بوجود matchmaking.
