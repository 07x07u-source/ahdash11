# الهوية والمراقبة التشغيلية

## Branding Center

يعتمد قسم «هوية التطبيق» على `app_content` وMedia Library الحاليين. كل قيمة تمر بمسار Draft ثم Publish، وتصل إلى Flutter عبر RPC المحتوى المنشور مع cache محلي وfallback ثابت. القيم البعيدة محدودة إلى أصول بصرية ونصوص تسويقية ولون Hex ترويجي ومفاتيح عرض غير أمنية؛ لا تتحكم في الصلاحيات أو النتيجة أو الاقتصاد.

أيقونة التطبيق المصدرية تُحفظ تحت المفتاح `branding.appicon.master` ويجب أن تكون مربعة وبأبعاد 1024×1024 على الأقل. اعتمادها لا يغير Launcher Icon المثبتة. لاستخدامها في نسخة لاحقة:

```powershell
cd C:\dev\ahdash11\mobile
# نزّل الأصل المعتمد يدويًا من Branding Center إلى المسار التالي:
# assets\branding\app-icon.png
dart run flutter_launcher_icons
flutter build apk --release --dart-define-from-file=.env
```

راجع الناتج بصريًا قبل الإصدار ولا تشغّل مولّد الأيقونات أثناء تعديل محتوى Remote عادي.

## طبقات رصد الأخطاء

- Crashlytics: الأعطال وFlutter/Platform uncaught errors وnon-fatals المهمة.
- Supabase operational errors: أعطال تشغيلية مختارة يحتاج فريق التشغيل لرؤيتها داخل Admin.
- User Reports: وصف اختياري يرسله المستخدم من الإعدادات مع الشاشة والإصدار والمنصة فقط.

يقوم Flutter بتنقيح البيانات قبل الإرسال، ثم يعيد PostgreSQL التنقيح ويقبل سياقًا محدود المفاتيح. لا تُرسل tokens أو authorization headers أو كلمات مرور أو بيانات دفع. تجمع المشكلة بواسطة fingerprint وتُحدّث `first_seen` و`last_seen` والعدد بدل إنشاء صف مشكلة لكل occurrence.

## تطبيق migration يدويًا

لا تنفذ هذه الخطوات إلا على المشروع والبيئة المقصودين وبعد مراجعة النسخة الاحتياطية:

```powershell
cd C:\dev\ahdash11
npx supabase db push
npx supabase test db
```

الملف الجديد هو:

`supabase/migrations/20260828000200_operational_monitoring_and_branding.sql`

لم ينفذ Codex أي `db push` بعيد في هذه الجولة.
