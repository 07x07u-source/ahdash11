# أحدعش | 11 — تدقيق الشاشات والمسارات V7

تاريخ التدقيق: 2026-09-01

## معايير القرار

- **KEEP**: الوظيفة والتكوين صالحان مع ضبط نظام V7.
- **REBUILD**: الوظيفة صحيحة لكن العرض يعاد من الصفر.
- **SIMPLIFY**: تبقى الشاشة مع تقليل الخطوات/الطبقات.
- **MERGE**: تُدمج داخل تدفق آخر.
- **MOVE TO SECONDARY**: لا تظهر في المسار الأساسي.
- **HIDE**: خلف feature flag أو وصول غير مباشر.
- **REMOVE FROM PUBLIC UX**: يزال المدخل العام مع حفظ العقد عند الحاجة.
- **KEEP BACKEND ONLY**: يبقى النموذج/الخدمة بلا واجهة عامة.

## الشاشات والمسارات العامة

| الشاشة / المسار | الهدف والفعل الأساسي | المشكلة الحالية | فراغ/صناديق/أعمدة/نص/أيقونات | Legacy | القرار |
|---|---|---|---|---|---|
| Launch `/launch` | تهيئة التطبيق ثم المتابعة | هوية تحميل ثابتة أكثر من كونها لحظة منتج | فراغ كبير؛ لا حالة fallback واضحة | لا | SIMPLIFY |
| Onboarding `/onboarding` | شرح القيمة ثم البدء | أربع صفحات أقدم من تدفق Party الحالي | شرائح منفصلة ونصوص كثيرة | نعم جزئيًا | MERGE |
| Auth `/auth` | الدخول/إنشاء حساب/ضيف | 50/50 form مقابل hero، وbanner تجريبي بعرض كامل | تقسيم واضح؛ form ممتد؛ Material icons مختلطة | debug banner | REBUILD |
| Home `/home` | بدء Party فورًا | صورة + نص + rail سفلي + كتلة بطولة؛ تشبه بوابة محتوى | مناطق متنافسة وفراغ يمين | لا | REBUILD |
| Play `/play` | اختيار نمط اللعب | يكرر مدخل Party وsolo/online | بطاقات modes وصندوقية | نعم | MERGE |
| Game Setup `/play/setup/:gameType` | إعداد نمط قديم | تدفق مستقل عن Party | نموذج تقليدي وازدواج منطق UX | نعم | MOVE TO SECONDARY |
| Categories `/categories` | استعراض محتوى عام | يتقاطع مع اختيار فئات Party | لا يقود إلى فعل لعبة واضح | نعم جزئيًا | MERGE |
| Party Games `/party/games` | استئناف ألعاب Party | مفيد لكن يبدو أرشيفًا منفصلًا | صفوف/بطاقات تحتاج اختصارًا | لا | MOVE TO SECONDARY |
| How to Play `/how-to-play` | شرح Party | تعليم بصري طويل نسبيًا | أقسام متعددة بلا demo مميز | لا | REBUILD |

## تدفق Party الأساسي

| الشاشة | Primary Action | المشكلة الحالية | Dead Space | Boxes / Columns | النص/الأيقونات/الصور | القرار |
|---|---|---|---|---|---|---|
| Category Selection `/party/categories` | اختيار 6 فئات | شبكة متساوية وصورة eye نفسها مكررة، مع selected hero كعمود ثالث | متوسط | نعم؛ 3 أعمدة واضحة | عناوين صغيرة وأيقونات Material كثيرة | REBUILD |
| Category Detail (sheet) | فهم/تجربة الفئة | sheet منفصل كبير ومكرر للمعلومات | متوسط | card داخل sheet | صورة fallback متكررة | SIMPLIFY |
| Team Setup `/party/teams` | تسمية الفريقين وتقسيم اللاعبين | إعدادات كثيرة في مشهد واحد | مرتفع في المقاسات الواسعة | مناطق متوازية | control density أعلى من لعبة جلسة | REBUILD |
| Player Splitter (داخل teams) | توزيع اللاعبين | يظهر كأداة ضمن form طويل | مرتفع | بطاقات أسماء متعددة | drag/tap affordance ضعيف | REBUILD |
| Helpers `/party/helpers` | اختيار 3 وسائل لكل فريق | خيارات صغيرة وسط مساحات كبيرة | نعم | أعمدة فريقين + cards | icon set غير موحد | REBUILD |
| Ready `/party/ready` | بدء المباراة | مقارنة فريقين أقرب إلى score dashboard | نعم | 3 مناطق/VS | لا صورة/إيقاع احتفالي كافٍ | REBUILD |
| Board `/party/board` | اختيار قيمة سؤال | جدول صحيح وظيفيًا لكنه spreadsheet-like؛ side controls ثابتة | قليل | 6 أعمدة لازمة للعبة، لكن الخطوط مفرطة | thumbnails مكررة؛ نقاط صغيرة | REBUILD |
| Question `/party/question` | قراءة السؤال ثم كشف الجواب | giant card غير مرئي الحدود فعليًا وعلامة `100` عملاقة | مرتفع | split بصري للنص/الرقم | السؤال بعيد وأزرار صغيرة | REBUILD |
| Reveal `/party/reveal` | تحديد من أجاب ومنح النقاط | خطوة مستقلة ثقيلة وتكرر النتيجة | متوسط | مناطق نتيجة متعددة | أيقونات/ألوان حالة أكثر من اللازم | MERGE |
| Result `/party/result` | فهم الفائز ثم إعادة اللعب/الخروج | `01/02` ضخمة وCTA عديدة | مرتفع | تقسيم فريقين متساوٍ | زخرفة أكبر من النتيجة | REBUILD |

ملاحظة: الأعمدة الستة في لوحة الأسئلة ليست “3-column dashboard”؛ هي بنية اللعبة. إعادة البناء تستبقي 6×6 ولكن تحولها إلى لوحة مسابقة ذات scoreboard واحد، headers قصيرة، حالات مستخدمة واضحة، وأدوات مؤقتة في sheets بدل dock دائم.

## البطولات

| الشاشة / المسار | الفعل الأساسي | المشكلة الحالية | Legacy/ازدواج | القرار |
|---|---|---|---|---|
| Tournament Hub `/tournaments` | متابعة البطولة النشطة | بطاقات بطولة كبيرة ومتناثرة | لا | REBUILD |
| Create `/tournaments/create` | إنشاء البطولة | form طويل وتكوين إداري | لا | REBUILD |
| Teams `/tournaments/teams` | إدارة الفرق | form وقائمة متجاوران | لا | REBUILD؛ الإضافة في sheet |
| Draw `/tournaments/draw` | تنفيذ القرعة | لحظة هوية ضعيفة وزر/قائمة | لا | REBUILD |
| Bracket `/tournaments/bracket` | فهم المسار والمباراة التالية | تنقل وأعمدة صغيرة | لا | REBUILD |
| Match `/tournaments/match/:matchId` | بدء المباراة/اعتماد نتيجتها | ثلاثة أعمدة، `01/02` ضخمة، entry مزدوج | نتيجة مستقلة ضمن الشاشة | REBUILD |
| Champion `/tournaments/champion` | الاحتفال والمشاركة | split presentation بدل لحظة واحدة | لا | REBUILD |
| Standalone semifinal/final result entry | إدخال نتيجة | يكرر Match ويفصل advance عن اللعبة | نعم | REMOVE FROM PUBLIC UX؛ winner advances ضمن Match |

## الملف والإعدادات والاشتراك

| الشاشة | الفعل الأساسي | المشكلة الحالية | القرار |
|---|---|---|---|
| Profile `/profile` | رؤية الهوية وتعديلها | poster يمين + stats grid + ثلاث كتل badge؛ dashboard واضح | REBUILD |
| Football Preferences `/football-preferences` | اختيار دوري/نادي | شبكات كبيرة متعددة الصفحات | SIMPLIFY؛ تدخل من تعديل الملف |
| Settings `/settings` | تعديل تفضيل واحد بسرعة | tabs + لوحتان مثل desktop settings | REBUILD |
| Premium `/store` | فهم العرض ثم شراء/استعادة | ورث اسم store وبعض لغة الاقتصاد | REBUILD |
| Wallet `/wallet` | قديم | redirect موجود إلى premium | REMOVE FROM PUBLIC UX؛ redirect KEEP |
| Coin Store / currency widgets | اقتصاد قديم | يعيد coins والـwallet إلى الواجهة | KEEP BACKEND ONLY حتى قرار منتج منفصل |

## Solo / Online / Social

| الشاشة / المسار | الوظيفة | المشكلة الحالية | القرار |
|---|---|---|---|
| Solo Setup `/solo` | إعداد لعب فردي | نمط مستقل يشتت Party-first | MOVE TO SECONDARY |
| Solo Match `/solo/match` | سؤال فردي | تصميم مختلف عن Party question | MERGE visual language |
| Solo Result `/solo/result` | نتيجة فردية | شاشة قديمة منفصلة | SIMPLIFY |
| Online Lobby `/online` | matchmaking | نظام ثانوي مع لوحة إعداد | HIDE خلف feature flag |
| Room Lobby `/room/:roomId` | انتظار الغرفة | كثافة status/controls | HIDE ثم REBUILD عند تفعيل online |
| Online Match `/online/match/:matchId` | مباراة online | هوية مختلفة عن Party | HIDE ثم MERGE visual language |
| Friends `/friends` | البحث/الطلبات/الأصدقاء | وظائف كثيرة في سطح واحد | MOVE TO SECONDARY + SIMPLIFY |
| Social Hub `/teams` | فرق اجتماعية | dashboard مستقل | REMOVE FROM PUBLIC UX أو HIDE |
| Social Team `/teams/:teamId` | تفاصيل فريق | route عميق مفيد فقط للميزة الاجتماعية | HIDE |
| Team Challenge `/challenges/:challengeId` | تحدي فريق | محرك واجهة مستقل | HIDE |
| Blocked Players `/blocked-players` | إدارة الحظر | قائمة ثانوية سليمة وظيفيًا | MOVE TO SECONDARY |
| Ranking `/ranking` | ترتيب اللاعبين | podium panel + list panel متساويان | REBUILD كمشهد top 3 واحد ثم صفوف؛ secondary |

## الدعم والإشعارات

| الشاشة / المسار | الفعل الأساسي | المشكلة الحالية | القرار |
|---|---|---|---|
| Notifications `/notifications` | قراءة التنبيهات | empty state داخل مساحة محاطة كبيرة | REBUILD/SIMPLIFY |
| Report Problem `/report-problem` | إرسال بلاغ | form تقليدي مع تفاصيل تقنية ظاهرة | SIMPLIFY |

## المكوّنات الرئيسية

| المكوّن | المشكلة | القرار |
|---|---|---|
| `EditorialPageFrame` / `EditorialScreenHeader` | يحمل DNA V6 وخطوط تقسيم كثيرة | REPLACE تدريجيًا بـV7 primitives |
| `AhdashBrandLogo` | remote/local fallback جيد | KEEP |
| `AhdashImage` | استراتيجية صحيحة عمومًا | KEEP وتوحيد الاستثناءات المباشرة |
| `AppShell` | مفيد لكن يحتاج icon mapping وقلّة الظهور أثناء اللعب | SIMPLIFY |
| Party side actions | dock دائم داخل اللعب | MOVE TO SHEET/OVERLAY مؤقت |
| Currency widgets | تعيد الاقتصاد القديم إلى المنتج | REMOVE FROM PUBLIC UX |
| Generic cards/panels | مستخدمة كتركيب افتراضي | REDUCE جذريًا |

## تدقيق المسارات

- لا توجد auth guards مركزية حاليًا؛ launch/auth يتحكمان في التوجيه خارجيًا.
- لا يوجد route مفقود من الشاشة العامة الموجودة في `mobile/lib/features` ضمن التدقيق أعلاه.
- `/wallet` redirect صحيح كحماية legacy مؤقتة.
- حذف route فعلي مؤجل حتى إضافة اختبارات deep links/redirects؛ إخفاء المدخل العام يسبق الحذف.
- مسارات online/social تبقى ثانوية ولا تظهر في Home V7 الأساسي.

## بوابة قبول الشاشات المرجعية

لا يتوسع التنفيذ لبقية الشاشات حتى تمر Login وHome وCategory Selection وGame Board وText Question وProfile وTournament Match في 844×390 و1280×720، Light وDark، مع فتح الصور وفحصها يدويًا. أي شاشة ما زالت قابلة للوصف “يمين + وسط + يسار” تعاد قبل التوسع.

