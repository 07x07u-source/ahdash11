# النشر والتشغيل

## البيئات

استخدم مشاريع Supabase/Firebase منفصلة لـdevelopment وstaging وproduction. خزّن secrets في مدير أسرار المنصة وCodemagic groups، ولا في Git. مفاتيح anon وFirebase app config عامة بطبيعتها، لكنها تبقى منفصلة حسب البيئة؛ service-role وFCM private key أسرار خادم حقيقية.

## Supabase

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase migration list
supabase db push --dry-run
supabase db push
supabase functions deploy submit-answer
supabase functions deploy create-room
supabase functions deploy join-room
supabase functions deploy queue-matchmaking
supabase functions deploy wallet-transaction
supabase functions deploy import-validate
supabase functions deploy import-commit
supabase functions deploy delete-account
supabase functions deploy dispatch-notifications --no-verify-jwt
supabase functions deploy revenuecat-webhook --no-verify-jwt
supabase functions deploy admob-reward --no-verify-jwt
```

يجب أن يظهر `20260828000100_app_content_and_media.sql` ضمن الـmigrations المعلّقة قبل الدفع. ينشئ هذا migration محتوى التطبيق القابل للنشر ومكتبة الوسائط وسياسات RLS وStorage وعمليات التدقيق؛ لا تعدّل migration مطبّقة سابقًا. راجع ناتج `--dry-run` أولًا، ثم نفّذ `db push` يدويًا على البيئة المقصودة.

ينشئ migration حاوية `app-content` العامة للقراءة. الرفع والاستبدال محصوران بالمشرفين، وبصور JPEG/PNG/WebP حتى 8MB وبأبعاد من 64 إلى 6000 بكسل ومسارات مصنفة آمنة. لا ترفع أسرارًا أو ملفات خاصة إلى هذه الحاوية.

عيّن أسرار الخادم عبر `supabase secrets set`: حساب خدمة FCM (`FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, `FCM_PRIVATE_KEY`)، سر `NOTIFICATION_DISPATCH_SECRET`، سر Webhook الخاص بـRevenueCat، `REVENUECAT_ENTITLEMENT_ID`، ومعرّفات وحدات rewarded في AdMob. لا تُرسل هذه القيم إلى تطبيق Flutter باستثناء مفاتيح SDK العامة ومعرّفات الوحدات العامة.

وجّه RevenueCat إلى `/functions/v1/revenuecat-webhook` مع `Authorization: Bearer <REVENUECAT_WEBHOOK_AUTH>`. وجّه AdMob SSV إلى `/functions/v1/admob-reward`؛ تتحقق الوظيفة من توقيع ECDSA ومفتاح Google الدوّار والوحدة والطابع الزمني ومعرّف العملية قبل قيد العملات. أنشئ Schedule كل دقيقة يستدعي `/functions/v1/dispatch-notifications` بجسم `{}` وترويسة Bearer لسر الإرسال؛ الإرسال يحترم تفضيلات المستخدم وساعات الهدوء ويكمل الحملات الكبيرة على دفعات idempotent.

قبل الإنتاج: راجع migration diff، شغّل الاختبارات، افحص RLS بحسابات أدوار مختلفة، عيّن secrets، فعّل PITR/backup المناسب، ثم نفّذ smoke test على staging.

## لوحة الإدارة

يمكن نشر `admin` على Vercel أو منصة Node متوافقة. عيّن `NEXT_PUBLIC_SUPABASE_URL` و`NEXT_PUBLIC_SUPABASE_ANON_KEY` فقط للمتصفح؛ العمليات التي تحتاج service-role توضع في Edge Functions لا في environment قابل للوصول إلى client bundle. اربط نطاق admin وافرض HTTPS وMFA للمشرفين.

## Android

سجّل package `com.ahdash.eleven`، أضف SHA-1 وSHA-256 لمفاتيح debug/upload/Play App Signing إلى Firebase، وتأكد أن `google-services.json` يحتوي Android OAuth client وWeb OAuth client اللذين يستخدمهما Google Sign-In وSupabase. فعّل Google provider في Supabase وأضف OAuth client IDs الصحيحة للبيئة. جهز Play App Signing وupload key، واضبط AdMob app ID وروابط الخصوصية، ثم شغّل `android-release` في Codemagic. يبدأ النشر كمسودة في internal track.

فعّل الزر في Flutter وقت البناء بـ`--dart-define=GOOGLE_AUTH_ENABLED=true`. هذا العلم عام وليس سرًا؛ لا تضع Google client secret داخل تطبيق الهاتف.

## iOS من Windows

1. أنشئ App ID وApp Store Connect app وbundle identifier مطابقًا.
2. أنشئ App Store Connect API key واربطه بـCodemagic integration.
3. اسمح لـCodemagic بإدارة certificate/profile أو ارفعها يدويًا.
4. خزّن `GoogleService-Info.plist` كـ`FIREBASE_IOS_CONFIG` base64، وتأكد أنه مضاف إلى Target `Runner` وأن `GIDClientID` وreversed client URL scheme موجودان في `Info.plist`.
5. فعّل Google provider في Supabase وأدرج iOS/Web OAuth client IDs الصحيحة، ثم ابنِ مع `--dart-define=GOOGLE_AUTH_ENABLED=true`.
6. شغّل `ios-release`; الناتج IPA ويرفع إلى مجموعة TestFlight الداخلية.
7. اختبر تسجيل Google فعليًا على iPhone، ثم اختبر الحذف والإشعارات والمشتريات وفعّل submission إلى App Store يدويًا.

مسار Apple الحالي يبقى OAuth عبر المتصفح، ويظهر زر Apple على iOS فقط عند البناء بـ`--dart-define=APPLE_AUTH_ENABLED=true`.

## Rollback

- Mobile: أوقف rollout في المتجر؛ لا تفترض إمكانية سحب binary ثبت للمستخدم.
- Admin: أعد نشر آخر build معروف.
- Database: migrations forward-only. أنشئ migration إصلاحية بعد حفظ نسخة احتياطية بدل تعديل migration مطبقة أو reset production.
- Feature flags و`game_settings` توقف الإعلانات/المتجر/نمط مباراة دون إصدار جديد.
