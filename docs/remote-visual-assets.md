# Remote Visual Assets

آخر تحديث: 2026-08-29.

تم رفع 14 ملفًا فعليًا إلى bucket `app-content` تحت `app-content/landscape-2026-27/`، ثم تسجيلها وربطها بخانات `app_content` المنشورة عبر migration `20260829000300_publish_landscape_assets.sql`. تحقق RPC المرتبط من 14 uploaded و14 published و14 slot.

الخانات: login hero، signup hero، home hero، ستة أغلفة Play، premium hero، وثلاث حالات empty، وخلفية profile. التطبيق يحمّل URL المنشور مع cache وfallback محلي إذا غابت الشبكة أو فشل الملف. مكتبة الإدارة تعرض slot، الحقوق، الحالة والإصدار وتسمح بالتفعيل/الأرشفة.

الحقوق لكل هذه الملفات `generated-safe` أو fallback إجرائي؛ لا شعارات أندية أو أطقم أو رعاة أو أشخاص حقيقيين. صُورتا `login_landscape_v2.webp` و`premium_landscape_v2.webp` أنشأهما Codex built-in ImageGen كتصميمين أصليين 16:9 ثم حُوّلتا إلى WebP. ملخصا الطلبين: هوية دخول كروية سينمائية مجردة بعلامة 11، وهوية Premium خيالية للاعب/لاعبة 11؛ بلا شعارات رسمية أو نصوص أو watermarks.
