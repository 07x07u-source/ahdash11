# نظام صور الفئات والأسئلة — V5

## المسار

Media Library وSupabase Storage الحاليان هما المصدر الوحيد. الفئة تستخدم `cover_media_id` و`image_url` الموجودين أصلًا، وأضاف V5 فقط `cover_focal_x/y`. لا توجد منظومة وسائط موازية.

1. يرفع المحرر JPEG/PNG/WebP إلى bucket `app-content` ضمن مجموعة `categories` أو`app-content`.
2. يتحقق الخادم من bytes وMIME والأبعاد والحجم، ويخزن alt، الحقوق، المصدر، attribution، الإصدار.
3. يختار المحرر الأصل داخل قسم «صورة الفئة»، ويراجع 3:2 و4:3 ويضبط focal point.
4. المسودة قد تبقى بلا صورة. الانتقال إلى `published + active` يحتاج أصلًا active وحقوقًا معتمدة.
5. لا يمكن أرشفة أصل يغطي فئة منشورة نشطة.

## ترحيل آمن

المهاجرة `20260831000300_editorial_brand_category_media_v5.sql` لا تغيّر الصفوف القديمة ولا تجعل العمود `NOT NULL`. Trigger التحقق يعمل عند الإدخال المنشور، الانتقال إلى النشر/التفعيل، أو تغيير الغلاف؛ لذلك يمكن تنفيذ backfill قبل لمس الفئات القديمة.

## تدقيق Remote بتاريخ 2026-08-31

المشروع البعيد لم يكن قد طبّق Party V2 وقت التدقيق (عمود `editorial_status` غير موجود)، لذلك اعتُبرت الفئات ذات `is_active=true` هي المنشورة تشغيليًا.

| الفئة | slug | الغلاف | الإجراء |
|---|---|---|---|
| عين الصقر | eagle-eye | موجود | راجع الحقوق ثم Ready |
| التعرف على النادي | club-identification | مفقود | Needs media |
| مسيرات اللاعبين | player-careers | مفقود | Needs media |
| دوري روشن السعودي | saudi-league | مفقود | Needs media |
| المدربون | coaches | مفقود | Needs media |
| سجل الجوائز | award-history | مفقود | Needs media |
| معلومات الملاعب | stadium-facts | مفقود | Needs media |
| الدوري الإنجليزي | premier-league | مفقود | Needs media |
| أرقام القمصان | shirt-numbers | مفقود | Needs media |
| التعرف على اللاعب | player-identification | مفقود | Needs media |
| الدوري الإسباني | la-liga | مفقود | Needs media |
| الدوري الإيطالي | serie-a | مفقود | Needs media |
| الدوري الألماني | bundesliga | مفقود | Needs media |
| الدوري الفرنسي | ligue-1 | مفقود | Needs media |
| دوري أبطال أوروبا | champions-league | مفقود | Needs media |
| كأس العالم | world-cup | مفقود | Needs media |
| اليورو | euro | مفقود | Needs media |
| سوق الانتقالات | transfers | مفقود | Needs media |
| الدوريات والبطولات | leagues | مفقود | Needs media |
| غرفة الملابس | locker-room | مفقود | Needs media |
| الملاعب | stadiums | مفقود | Needs media |
| الجوائز الفردية | individual-awards | مفقود | Needs media |

الإجمالي: 22؛ مع غلاف: 1؛ مفقود: 21. شرط «Published without image = 0» هو Release readiness gate بعد إدخال أصول مملوكة/مرخصة، وليس ادعاءً بأن البيانات الحالية اكتملت. لا يختلق هذا التغيير صورًا أو حقوقًا.

## أسئلة الوسائط

المحرك المنشور يدعم `open_answer` و`multiple_choice` و`true_false` و`image`. سؤال `image` الجديد يختار أصلًا من Media Library ويحفظ `image_media_id` والتعليق وfocal point؛ النشر يتطلب URL وحقوقًا معتمدة. الصيغ المستقبلية مثل zoom/audio/video لا يقبلها قيد قاعدة البيانات ولا Renderer الحالي، لذلك تبقى غير قابلة للنشر حتى يضاف نوع asset وRenderer واختبارات أمان كاملة.

