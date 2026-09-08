# تدقيق التحول إلى Image-led UI

آخر تحديث: 2026-08-29. العدّ هو ظهور `Icons.` و`Card/AhdashCard` داخل ملف الشاشة، وليس حكمًا على جودة التصميم وحده. أرقام «قبل» هي القياسات التي سُجلت في التدقيق الأولي قبل التعديل؛ `—` يعني أن القياس التاريخي لم يُحفظ ولا يتم اختلاقه.

| الشاشة/الملف | Icons قبل → بعد | Cards قبل → بعد | الصورة/الخلفية الجديدة | التغيير الفعلي |
|---|---:|---:|---|---|
| Home / `home_screen.dart` | 14 → 1 | — → 0 | home + mode art + reward | Hero رئيسي، CTA واحد، mode strip وصور تحدي/فريق/ترتيب بدل dashboard |
| Play Hub / `play_screen.dart` | — → 0 | — → 0 | play hub + 3 mode artworks | Classic كبير وTrue/False/Speed بصور؛ الأنماط غير المنفذة تبقى «قريبًا» |
| Game Setup / `game_setup_screen.dart` | 21 → 3 | — → 2 | mode hero | نوع اللعب يُشرح بصورته، لا بدائرة icon كبيرة |
| Store / `store_screen.dart` | 22 → 0 | — → 2 | locker-room + 20 previews | Hero، فلاتر، Grid lazy، Preview، Owned/Equipped، مقتنياتي وPremium منفصل |
| Wallet / `wallet_screen.dart` | جديد → 0 | جديد → 1 | vault + coin stack | Hero للرصيد وسجل ledger؛ لا واجهة بنكية ولا تعديل محلي |
| Profile / `profile_screen.dart` | 35 → 20 | — → 7 | profile background | بيئة Player Card وStats بلا icon لكل رقم؛ بقيت أيقونات روابط مباشرة ووظائف |
| Leaderboard / `ranking_screen.dart` | — → 2 | — → 0 | podium background | ترتيب بصري وTop 3 مع focal point واحد |
| Results / `results_screen.dart` | — → 9 | — → 1 | victory/draw/defeat variants | النتيجة تقودها صورة الحالة؛ بقيت أيقونات المقاييس والإجراءات الوظيفية |
| Fariq hub / `social_hub_screen.dart` | — → 8 | — → 3 | team background | Hero اجتماعي وTeam banner؛ بقيت إدارة الدعوة والخصوصية وظيفية |
| Team detail / `social_team_screen.dart` | 32 → 20 | — → 5 | team background | راية وفريق/MVP في المقدمة، مع تقليل الزخرفي والإبقاء على الإدارة |
| Splash / `launch_screen.dart` | 0 → 0 | 0 → 0 | home tunnel | شعار داخل مشهد اللعبة بدل خلفية مسطحة |
| Onboarding / `onboarding_screen.dart` | 0 → 0 | 0 → 0 | 5 image-led steps | الاسم/Player11/الدوري/النادي/الاستعداد بصور ونص Flutter |
| Question / `question_screen.dart` | وظيفية | وظيفية | quiet pitch background | scrim قوي؛ لا Artwork مزدحمة خلف السؤال |
| Friends empty / `friends_screen.dart` | حالة icon → صورة | — | inventory empty art | الحالة تعتمد على صورة ونص، لا icon منفردة |
| Notifications empty / `notifications_screen.dart` | حالة icon → صورة | — | store empty art | صورة ونص مع بقاء أيقونات نوع الإشعار وظيفية |

## ما دُمج أو أزيل

- أزيل نمط `icon circle + title + description` من Home وPlay والمتجر بالكامل.
- أزيلت Material icons الخاصة بالعملة واستبدلت بهوية `AhdashCoin`.
- لم تُنشأ أنماط لعب جديدة؛ Ordering وClub Guess وEagle Eye ما زالت غير مفعلة.
- Settings لم تُحمّل بصور؛ بقيت قائمة نظامية لأن الأيقونات هناك وظيفية.
- بقيت Back/Close/Search/Notifications/Bottom navigation وإدارة الفريق لأنها أفعال مباشرة، وليست Artwork.

## تحقق القياسات

`mobile/test/visual/image_first_golden_test.dart` ينتج 30 Golden فعلية لـHome وPlay وStore وProduct details وWallet عند 360×800 و390×844 و412×915 في Light/Dark وRTL. اكتشف الاختبار overflow حقيقيًا في Home/Store وتم إصلاحه. اختبارات المشروع الحالية تغطي large text وdisableAnimations لشاشة Play؛ مصفوفة Golden كاملة للـProfile/Results/Team/Leaderboard تبقى ضمن القيود المعروفة في تقرير الإصدار ولا يُدّعى أنها أُنتجت.
