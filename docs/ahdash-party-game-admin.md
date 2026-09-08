# Admin — مركز لعبة الجلسة

## الأسئلة

محرر المسودة يدعم الآن: النص، الإجابة، البدائل، الصيغة، الصعوبة، النقاط، القسم، التفسير، المصدر، الموسم، رابط الصورة، وحالة الحقوق. الصيغة الافتراضية `open_answer`. الحفظ يستدعي `create_admin_party_question` ويضع السؤال Draft + needs_review.

## الأقسام

بطاقة القسم تعرض العدد الإجمالي وتوزيع سهل/متوسط/صعب وحالة READY/NEEDS QUESTIONS/MEDIA ISSUE/RIGHTS ISSUE/ARCHIVED. الاستعلام الصحي يحصي فقط المنشور والمراجع والمؤهل للجلسة وغير التنافسي.

## المساعدات

صفحة `/party-game` تدير الاسم والوصف ومفتاح الأيقونة والتوقيت والحالة و`rule_config` للكتالوج الثابت من خمس أدوات. يقرأ Flutter الكتالوج الفعّال، ويطبق زمن «استنجد» ومضاعفات «مخاطرة/مرّرها»، ثم ينسخ التعريفات إلى Session Snapshot حتى لا تتغير جولة جارية بعد تعديل Admin.

## الاستيراد

CSV/XLSX يدعم: القسم، السؤال، الإجابة، البدائل، الصعوبة، 100/200/300، الصيغة، الوسيط، المصدر، الشرح، الموسم، الحالة وحقوق الوسائط. يستخدم Admin الدالة `commit_party_import_batch` كي تحفظ الأسئلة المفتوحة بلا خيارات وهمية. الصف غير الصالح أو المكرر أو المحتاج مراجعة لا يُنشر تلقائيًا.

## الإعدادات المركزية

تظهر مفاتيح `party.*` في صفحة إعدادات اللعب الحالية:

- `party.categories_per_game = 6`
- `party.questions_per_category = 6`
- `party.helpers_per_team = 3`
- `party.default_timer_seconds = 30`
- `party.easy_points = 100`
- `party.medium_points = 200`
- `party.hard_points = 300`
- `party.tiebreaker_enabled`
- `party.free.daily_games`
- `party.free.monthly_games`
- `party.free.rotating_categories_enabled`
- `party.free.ad_supported_enabled`

الأرقام البنيوية 6×6 و3 مساعدات وقيم 100/200/300 تبقى عقدًا مركزيًا في `PartyGameRules` حتى لا تتشوه جولة محفوظة. مفتاح السؤال الفاصل وكتالوج المساعدات يُقرآن ديناميكيًا. مفاتيح Free هي تهيئة مستقبلية فقط وقيمتها صفر/غير مفعلة؛ لا تفرض سياسة مجانية جديدة في هذا الإصدار.

## الأمان

- API يتطلب Moderator لإنشاء سؤال وAdmin لإدارة المساعدات/الإعدادات.
- Service Role لا يصل إلى المتصفح.
- party pack يحتاج مستخدمًا نشطًا، بما في ذلك Supabase anonymous guest.
- pack لا يعيد إلا `offline_practice_eligible` وغير `competitive_eligible`.
- الكاش المحلي يحفظ حزمة Party الآمنة فقط، ولا يخلط answer keys الخاصة بالمخزون التنافسي.
- RPCs والـ snapshots التنافسية لم تُغيّر.

## Migration

الملف الجديد الوحيد: `20260830000100_party_game_content.sql`. لا تعدّل migrations المطبقة حتى `20260829000400`. يجب parser/lint وdry-run قبل أي push، ولا يُنفذ push ضمن هذه الجولة تلقائيًا.
