# AHDASH V9 - RAW GOLDEN AUDIT - SCREENS 30-43

## نطاق الفحص

- تم فحص أزواج RAW Golden PNG الفاتح والداكن مباشرة بالحجم الأصلي للشاشات 30-43 كما عرّفتها قائمة `SCREENS` في `tools/build_v8_2_screen_catalog_pdf.py`.
- تم فحص 844x390 للشاشات التي يتوفر لها فعلا: Profile وNotifications وPremium.
- بقية الشاشات لا تملك Golden مدمجا في الكتالوج، ولذلك لا تعتبر جودة 844x390 مثبتة.
- Team Challenge مصدرها الفعلي 1280x760، لا 1280x720؛ هذه فجوة تحقق يجب إصلاحها في الجولة التالية.
- المقاسات المذكورة أدناه تقديرات بصرية من الـPNG الخام وليست قياسات من صفحة الكتالوج المصغرة.

### Evidence note - hollow-square utility glyphs

ظهور hollow-square utility glyphs في checkpoint Goldens الخاصة بـProfile وNotifications وPremium يرجع - على الأقل جزئيا - إلى أن `mobile/test/visual/v8_2_checkpoint_golden_test.dart` لا يحمّل `packages/cupertino_icons/CupertinoIcons`، بينما اختبارات Golden الأخرى تحمّله. لذلك فهذا دليل على validation harness defect يحتاج إصلاح بيئة التحقق وإعادة توليد/فحص الصور؛ ولا يثبت تلقائيا وجود العيب نفسه في production قبل إعادة التحقق.


---

## 30. Online lobby - `onlineLobby`

- **PURPOSE:** بوابة اللعب المباشر: مواجهة سريعة، إنشاء غرفة، أو الانضمام برمز.
- **PRIMARY TASK/ACTION:** اختيار نوع الدخول ثم بدء البحث أو إنشاء/الانضمام إلى غرفة. الإجراء الأساسي الحالي غير محسوم بصريا بين `ابدأ البحث` و`انضمام` وخياري إنشاء 1 ضد 1 / 2 ضد 2.
- **FIRST FOCUS:** بصريا تسحب الكتلة البيج الطويلة يسارا الانتباه قبل حالة الغرفة؛ المفترض أن يكون قرار اللاعب أو حالة الغرفة هو البطل.
- **CURRENT PROBLEMS:** مساران مختلفان محشوران في صفحة واحدة؛ quick match يبدو بطاقة عمودية معطلة، وإنشاء الغرفة عبارة عن أزرار صغيرة ملتصقة بأسفل فراغ هائل. لا توجد حالة غرفة/لاعبين/جاهزية واضحة. الهرمية لا تقول أين يبدأ اللاعب.
- **EMPTY SPACE:** مفرط جدا، خصوصا منتصف ويمين الصفحة وفوق عناصر الإنشاء. الكتلة اليسرى نفسها أكبر بكثير من محتواها.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** العنوان مقبول، لكن الشرح والخيارات أصغر من كتلة الصفحة. لا توجد صورة. pictogram الغرفة والمواجهة بحجم تقريبي 64-72 وهو جيد كأصل، لكنه غير مدمج مع الإجراء.
- **UTILITY ICONS:** لا ازدحام أيقوني؛ لا توجد أداة تنقل واضحة أيضا. الشعار ليس بديلا عن رجوع واضح.
- **BUTTON/INPUT/TOUCH:** حقل الرمز والإجراء السفلي قريبان من 48-52، لكن زري نوع المواجهة أقرب إلى 36-38 وأقل من الحد المرغوب. زر البحث معطل بصريا بلا تفسير حالة. الإجراءات الأساسية متفرقة.
- **ALIGNMENT/RTL:** وضع تكوين الغرفة يمينا والمواجهة السريعة يسارا منطقي RTL، لكن المحاور الرأسية غير مترابطة، وصف الإجراءات السفلي منفصل عن عنوانه. لا يوجد مسار رجوع ظاهر.
- **LIGHT/DARK:** Light مسطح جدا والفروق بين Canvas/Surface ضعيفة. Dark أوضح قليلا لكنه ورقة سوداء كبيرة مع كتلة رمادية منفصلة.
- **RESPONSIVE:** لا يوجد 844x390 خام. هذا التخطيط ذو العمودين والبطاقة الطويلة معرض للانهيار أو تصغير النص والأزرار بدلا من إعادة التركيب.
- **GAME FEEL:** منخفض؛ pictograms تحمل DNA أحدعش، لكن التجربة تبدو نموذج اتصال/غرفة ويب لا lobby لعبة.
- **LEGACY DNA:** مرتفع: split layout + panels + micro controls داخل Canvas كبير.
- **DENSITY:** MEDIUM منطقيا، لكنه SPARSE فعليا.
- **DECISION:** **REBUILD** حول اختيار واحد واضح ثم حالة الغرفة/اللاعبين/الجاهزية، مع إجراء رئيسي واحد في كل حالة.

## 31. Online match - `onlineMatch`

- **PURPOSE:** سؤال مباشر متعدد الخيارات بين لاعبين/فرق مع وقت وجولة.
- **PRIMARY TASK/ACTION:** قراءة السؤال ثم لمس إجابة؛ إنهاء/الخروج إجراء ثانوي.
- **FIRST FOCUS:** شريط التقدم الأخضر الطويل يسبق السؤال بصريا؛ السؤال يجب أن يكون أول تركيز، والوقت داعما له.
- **CURRENT PROBLEMS:** السؤال معزول داخل لوحة ضخمة، والإجابات أسماء صغيرة في مراكز أربع مساحات هائلة. البنية صحيحة وظيفيا لكن لا تشترك بصريا مع Party Question، ما ينشئ نظام لعب ثانيا. حالة الاختيار/الضغط/القفل غير مقروءة من الـGolden.
- **EMPTY SPACE:** ليس فراغ Canvas، لكنه فراغ داخلي مبالغ داخل لوحة السؤال وبطاقات الإجابات.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** السؤال نحو 24-26 ومقبول لكنه يستطيع أن يكون 28-32. الإجابات نحو 15-17 وصغيرة مقابل target الذي يملأ ربع الشاشة. لا صورة ولا pictogram؛ هذا مقبول لسؤال نصي.
- **UTILITY ICONS:** 2 مفيدان: إغلاق + شبكة/لوحة. عداد الوقت والجولة معلومات حالة لا utility icons.
- **BUTTON/INPUT/TOUCH:** مناطق الإجابة ضخمة ومريحة للمس، لكن affordance ضعيف بسبب الأسطح الفارغة والحدود الخفيفة. زر الإغلاق glyph صغير ويحتاج ضمان target 44-48. لا inputs.
- **ALIGNMENT/RTL:** السؤال يمينا والإجابات يسارا ترتيب RTL مفهوم، وترقيم 1-4 واضح. يجب التأكد من اتجاه تقدم الوقت وحالات الإجابة المختلطة، ومن عدم اعتبار `X` بديلا غير آمن للانسحاب المؤكد.
- **LIGHT/DARK:** Light بيج فوق بيج وفروق الأسطح محدودة. Dark أفضل في الفصل لكن قريب من sheet أسود واحد.
- **RESPONSIVE:** لا 844x390 خام. مخاطر واضحة: ضيق السؤال الجانبي، وتقلص grid أو النص. المطلوب layout adaptive لا تصغير ثابت.
- **GAME FEEL:** متوسط؛ الوقت والجولة والجواب الفوري يعطيان لعبا، لكن البطاقات تبدو wireframe.
- **LEGACY DNA:** متوسط: grid/panel قديم مع حالة لعب حديثة فوقه.
- **DENSITY:** FOCUS.
- **DECISION:** **MERGE** بصريا ومكونيا مع Party Question shell، مع الاحتفاظ بحالة الشبكة/الخادم فقط.

## 32. Private room - `roomLobby`

- **PURPOSE:** مشاركة رمز الغرفة، رؤية اللاعبين، إعلان الجاهزية، ثم بدء المباراة عند تحقق الشروط.
- **PRIMARY TASK/ACTION:** الانضمام/الجاهزية؛ للمضيف البدء. الإجراء المرئي الحالي `أنا مستعد` ضعيف جدا.
- **FIRST FOCUS:** لوحة رمز الغرفة الكبيرة يمينا، لكن الرمز نفسه صغير نسبيا؛ حجم اللوحة لا يتحول إلى أهمية للمعلومة.
- **CURRENT PROBLEMS:** الشاشة table-like كما وصف المالك. صفا اللاعبين بارتفاع ضخم ومحتوى صغير، لوحة الرمز شبه فارغة، ولا يظهر CTA مضيف واضح. `Rating` إنجليزي وmetadata صغيرة. الجاهزية تبدو شريطا سفليا رفيعا.
- **EMPTY SPACE:** حرج؛ أكثر من نصف لوحتي اللاعبين والرمز غير مستخدم، والفراغ لا يصنع تركيزا.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** الرمز 110011 بحجم يقارب 36 ويجب أن يكون وحدة hero مع عنوان/نسخ/مشاركة. pictogram الأشخاص نحو 32-40 وهو صغير جدا داخل اللوحة. الصور الرمزية نحو 44-48 جيدة؛ النصوص 13-16 صغيرة قياسا بارتفاع الصف.
- **UTILITY ICONS:** إغلاق، أشخاص، نسخ، تحديث = 4؛ علامتا الجاهزية status icons وليستا زخرفة. العدد مقبول لكن copy/refresh صغيران وغير متمركزين مع task.
- **BUTTON/INPUT/TOUCH:** `أنا مستعد` بارتفاع يقارب 36-38 وأقل من 44. `نسخ الرمز` text action صغير. صفوف اللاعبين كبيرة للمس لكنها ليست أفعالا واضحة. لا input.
- **ALIGNMENT/RTL:** معلومات الغرفة يمينا واللاعبون يسارا ترتيب جيد، لكن status اللاعب يدفع إلى أقصى الطرف الآخر فيقرأ كجدول إداري. العنوان والإغلاق أعلى اليمين متقاربان، ولا يظهر رجوع واضح.
- **LIGHT/DARK:** Light منخفض التباين جدا. Dark يفصل السطحين لكن ما زال admin panel داكنا واسعا.
- **RESPONSIVE:** لا 844x390 خام؛ عمودان ثابتان وصفوف 142px تقريبا خطر كبير على الارتفاع القصير.
- **GAME FEEL:** منخفض؛ غرفة اجتماعية بلا إحساس انتظار/استعداد/بدء مباراة.
- **LEGACY DNA:** مرتفع جدا: two-column admin/table shell.
- **DENSITY:** MEDIUM، SPARSE فعليا.
- **DECISION:** **REBUILD**؛ اجعل الرمز + حالة الغرفة + اللاعبين + ready/start وحدة واحدة متماسكة.

## 33. Team challenge - `teamChallenge`

- **PURPOSE:** سؤال تحدي فريق مع نقاط ووقت/تقدم وإجابات متعددة.
- **PRIMARY TASK/ACTION:** فهم السؤال واختيار الإجابة بسرعة.
- **FIRST FOCUS:** السؤال الكبير وpictogram أحدعش هما أفضل تركيز في هذه المجموعة؛ شريط الحالة العلوي ينافسهما قليلا.
- **CURRENT PROBLEMS:** split dashboard واضح: سؤال يمينا وأربعة خطوط إجابة يسارا مع فاصل رأسي قاس. الإجابات لا تبدو أزرارا، والجزء السفلي بأكمله فارغ. metadata العلوية والسفلية صغيرة جدا. التصميم لا يعيد استعمال shell السؤال الأساسي.
- **EMPTY SPACE:** حرج في النصف السفلي من جانبي الشاشة، خصوصا تحت الإجابات.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** السؤال نحو 32-36 وقوي. pictogram نحو 60-68 ومفيد. الإجابات نحو 16-18 فقط مع أرقام 11-12؛ تلميح الأسفل قرابة 11-12. لا صورة.
- **UTILITY ICONS:** رجوع واحد فقط، لكن السهم ظاهر متجها لليسار على حافة RTL اليمنى ويحتاج تدقيق mirroring. البقية status لا utilities.
- **BUTTON/INPUT/TOUCH:** مساحة كل إجابة المحتملة كبيرة، لكن الخط السفلي لا يوضح target ولا حالات hover/press/selected. لا CTA منفصل ولا input.
- **ALIGNMENT/RTL:** ترتيب 01/02 ثم 03/04 صحيح بصريا RTL، لكن سهم الرجوع غير معكوس، والفاصل المركزي يقسم المهمة بدلا من توحيدها.
- **LIGHT/DARK:** Light أنظف من عدة شاشات أخرى، لكنه قريب من لون واحد. Dark يصبح sheet أسود مع خطوط بنية خافتة.
- **RESPONSIVE:** الـGolden الفعلي 1280x760 لا 1280x720، ولا 844x390. لا يمكن اعتماد الاستجابة، وفرق الارتفاع نفسه يخفي مشاكل fit.
- **GAME FEEL:** متوسط إلى جيد في السؤال/pictogram، منخفض في طريقة عرض الإجابات والحالة.
- **LEGACY DNA:** مرتفع: quiz داخل split dashboard.
- **DENSITY:** FOCUS.
- **DECISION:** **REBUILD** باستخدام Question shell موحد، وتوزيع إجابات adaptive يملأ الارتفاع المفيد.

## 34. Ranking - `ranking`

- **PURPOSE:** عرض المتصدرين وترتيب اللاعب وربما التنقل بين سياقات التصنيف.
- **PRIMARY TASK/ACTION:** قراءة Top 3 ثم متابعة المراكز التالية؛ التحديث إجراء ثانوي.
- **FIRST FOCUS:** podium والمرتبة الأولى؛ الاتجاه العام صحيح.
- **CURRENT PROBLEMS:** Top 3 avatars/names صغيرة فوق قواعد ضخمة، وصفا #4/#5 بارتفاع يقارب 150 لكل منهما مع البيانات محصورة في شريط علوي. الشريط الجانبي نحيف وdesktop-like. تكرار صورة اللاعب يجعل fixtures غير مقنعة بصريا حتى لو كانت deterministic.
- **EMPTY SPACE:** مرتفع داخل منصات podium وصفوف الترتيب؛ الجزء السفلي أيضا غير مستغل.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** الصور الرمزية نحو 48-54 ويمكن رفع Top 3 بوضوح. أسماء 13-15 والنتائج 12-14 صغيرة. لا pictogram مميز؛ podium نفسه هو التكوين.
- **UTILITY ICONS:** تحديث + نحو 5 عناصر side rail = 6، كثافة أعلى من الحاجة. icons/text في rail صغيرة قياسا بالعرض والصفحة.
- **BUTTON/INPUT/TOUCH:** أهداف rail عموديا واسعة على الأرجح، لكن glyphs صغيرة وبدون وضوح بصري كاف. زر التحديث عار من surface ولا يظهر target 44. لا inputs.
- **ALIGNMENT/RTL:** #2 يمين و#3 يسار مناسب، ومعلومات الصف يمينا والنتيجة يسارا. العنوان لا يصطف بصريا مع عرض المحتوى، والrail يفصل الصفحة كواجهة سطح مكتب.
- **LIGHT/DARK:** Light مسطح. Dark يعطي podium عمقا أفضل، لكنه قريب من الأسود الموحد، والحدود أضعف من اللازم.
- **RESPONSIVE:** لا 844x390 خام؛ podium + rail + صفوف 150px لن تناسب ارتفاع 390 من دون إعادة تكوين حقيقية.
- **GAME FEEL:** متوسط؛ podium والذهبي يدعمان المنافسة، لكن rows تبدو قاعدة بيانات.
- **LEGACY DNA:** متوسط/مرتفع: sidebar dashboard مع cards واسعة.
- **DENSITY:** DENSE منطقيا، لكنه منخفض المعلومات حاليا.
- **DECISION:** **RECOMPOSE** مع الإبقاء على فكرة podium، تكبير Top 3، وتقليل ارتفاع الصفوف وإزالة rail النحيف.

## 35. Friends - `friends`

- **PURPOSE:** البحث عن لاعبين، إدارة الأصدقاء والطلبات الواردة/المرسلة، وإظهار empty/data states.
- **PRIMARY TASK/ACTION:** البحث/الإضافة عند الفراغ؛ لاحقا تصفح القائمة وإدارة الطلبات.
- **FIRST FOCUS:** حقل البحث الطويل، ثم إطار فارغ عملاق؛ empty state نفسه لا يملك الوزن الكافي.
- **CURRENT PROBLEMS:** giant bordered empty panel يعيد wireframe/dashboard DNA. التبويبات صغيرة ومفصولة عن العنوان، ولا يوجد CTA إضافة واضح داخل الحالة رغم أن النص يطلب استعمال البحث. العنوان الداخلي والعداد metadata صغيرة.
- **EMPTY SPACE:** مفرط جدا داخل الإطار، بينما pictogram/heading/copy مجموعة صغيرة في الوسط.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** pictogram نحو 64-72 ويحتاج 80-104. العنوان نحو 22 جيد لكنه يحتاج وحدة أقوى مع الإجراء؛ copy 14-15. لا صور في empty state.
- **UTILITY ICONS:** تحديث، أصدقاء أعلى الصفحة، بحث، إضافة شخص = 4؛ بعضها مكرر دلاليا أو بعيد عن المهمة. pictogram المركزي branded وليس utility.
- **BUTTON/INPUT/TOUCH:** البحث بارتفاع يقارب 48 جيد. شريط التبويب أقرب إلى 32 وأقل من touch target. الأيقونات العليا عارية، ولا CTA 48-54 في empty state.
- **ALIGNMENT/RTL:** البحث يمتد يمينا بينما tabs محشورة يسارا، فيبدو الشريط مقسوما. ترتيب tabs داخليا RTL مقبول، لكن مكان المجموعة لا يرتبط بعنوان القائمة يمينا.
- **LIGHT/DARK:** Light الإطار بالكاد يفصل عن Canvas. Dark يصبح مستطيلا أسود داخل أسود وحدوده هي العنصر الأوضح بلا داع.
- **RESPONSIVE:** لا 844x390 خام؛ شريط البحث + أربع tabs أفقية مرشح للتصغير الشديد بدلا من overflow/scroll مدروس.
- **GAME FEEL:** منخفض؛ الهوية في pictogram فقط.
- **LEGACY DNA:** مرتفع: boxed empty table.
- **DENSITY:** DENSE عند وجود بيانات / FOCUS في empty state؛ الحالي لا ينجح في أي منهما.
- **DECISION:** **REBUILD** لحالتي empty/data: pictogram أكبر، copy مختصر، بحث/إضافة واضح، وقائمة بلا giant border.

## 36. Blocked players - `blockedPlayers`

- **PURPOSE:** مراجعة المحظورين وفك الحظر.
- **PRIMARY TASK/ACTION:** العثور على اللاعب ثم `فك الحظر`.
- **FIRST FOCUS:** العنوان والشرح أعلى اليمين؛ صف اللاعب صغير جدا ولا يصنع قائمة ذات حضور.
- **CURRENT PROBLEMS:** شاشة مستقلة شبه فارغة، بلا رجوع ظاهر، وaction مفصول مئات البكسلات عن هوية اللاعب. تعرض ID تقنيا `blocked_11` بدلا من هوية مفيدة. لا يوجد سبب بصري يجعلها destination رئيسية.
- **EMPTY SPACE:** الأعلى والأسفل والمنتصف فارغ؛ صف واحد صغير داخل max width 820 لا يستخدمه.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** avatar نحو 48 ومقبول، لكن الاسم/action 14-16 وmetadata 13. لا pictogram في حالة البيانات. في empty state يجب استعمال pictogram 80-104 إن بقيت الشاشة.
- **UTILITY ICONS:** لا utilities ظاهرة ولا رجوع؛ avatar glyph ليس utility.
- **BUTTON/INPUT/TOUCH:** `فك الحظر` text button صغير بصريا حتى لو كان hitbox الداخلي أكبر. الصف 76 مناسب، لكن الفصل المكاني يضعف العلاقة. لا input.
- **ALIGNMENT/RTL:** هوية اللاعب يمينا وaction بعيدا جدا يسارا؛ هذا جدول واسع لا row مقروء. غياب رجوع صريح مشكلة تنقل.
- **LIGHT/DARK:** كلاهما شديدا التسطيح؛ Dark sheet أسود طويل، وLight ورقة فارغة.
- **RESPONSIVE:** لا 844x390 خام. قائمة بسيطة قابلة للتجاوب، لكن الـGolden لا يثبت ذلك.
- **GAME FEEL:** غير مطلوب بقوة لشاشة خصوصية، لكن DNA أحدعش شبه غائب.
- **LEGACY DNA:** مرتفع: standalone utility route داخل shell واسع.
- **DENSITY:** DENSE كقائمة / FOCUS عند الفراغ؛ الحالي SPARSE.
- **DECISION:** **MOVE** تحت Settings -> Privacy. احتفظ بالبيانات وعمليتي load/unblock؛ يمكن إبقاء route داخليا/للتوافق لكن لا يبقى destination مستقلا بارزا.

## 37. Team detail - `socialTeam`

- **PURPOSE:** هوية الفريق، الأعضاء، التحديات، النشاط، الدعوة/الرمز.
- **PRIMARY TASK/ACTION:** معرفة حالة الفريق ثم اختيار Members/Games/Activity أو بدء تحد/دعوة عضو.
- **FIRST FOCUS:** اللوحة الخضراء الكبيرة يمينا، لا اسم الفريق/أهم فعل؛ اللون والمساحة يطغيان على كل شيء.
- **CURRENT PROBLEMS:** أوضح Dashboard DNA في المجموعة: ثلاثة أعمدة مستقلة، عدة panels، بطاقة تحد وحيدة، بطاقتا عضو، وكتلة هوية عملاقة. المحتوى موزع بلا تسلسل. الأخضر مستخدم كزخرفة مساحة لا كحالة selected/action. كثرة الأدوات تزيد الضوضاء.
- **EMPTY SPACE:** حرج داخل الأعمدة الثلاثة، ولا سيما تحت الأعضاء والتحديات وداخل بطاقة الهوية.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** avatars 44-48 جيدة، لكن النص 13-17 صغير. شارة `SN` نحو 76 ليست هوية فريق مقنعة. لا cover/image purposeful؛ النمط الأخضر زخرفي أكثر من كونه محتوى. لا pictogram مركزي.
- **UTILITY ICONS:** 8+ تقريبا: تحديث، إضافة، تشغيل، علم، دعوة، مفتاح/رمز، kebab، شارة/برق. العدد مرتفع وبعضها أصغر من أهميته.
- **BUTTON/INPUT/TOUCH:** دعوة/رمز بارتفاع يقارب 36-38 وأقل من 44. play دائرة صغيرة، kebab صغير، وبطاقات الأعضاء/التحدي targets غير واضحين. لا inputs.
- **ALIGNMENT/RTL:** identity يمينا ثم challenges ثم members يسارا ترتيب وظيفي لكنه يجزئ القراءة. التبويبات محصورة في العمود الأيسر ولا تبدل الصفحة كلها. العنوان العام منفصل أعلى اليمين والتحديث منفصل أقصى اليسار.
- **LIGHT/DARK:** Light يغسل معظم panels بينما الأخضر يطغى. Dark أفضل تباينا لكنه يجعل البطاقة الخضراء كتلة ثقيلة وغير منضبطة دلاليا.
- **RESPONSIVE:** لا 844x390 خام؛ ثلاثة أعمدة مستحيلة هاتفيا بلا تحويل إلى header + tabs + body.
- **GAME FEEL:** منخفض/متوسط؛ تحد واحد موجود، لكن الصفحة إدارة فريق لا مساحة فريق حيّة.
- **LEGACY DNA:** الأعلى في المجموعة: three-column dashboard.
- **DENSITY:** DENSE منطقيا، لكنه fragmented/SPARSE فعليا.
- **DECISION:** **REBUILD** إلى Team identity header ثم Tabs: Members / Games / Activity، مع CTA سياقي واحد.

## 38. Profile - `profile`

- **PURPOSE:** إبراز هوية Player11، الاسم/النادي، الإحصاءات، والهوية الكروية.
- **PRIMARY TASK/ACTION:** قراءة الهوية ثم تعديل الملف أو فتح البطولات؛ تعديل الهوية الكروية ثانوي.
- **FIRST FOCUS:** اللاعب والاسم داخل hero؛ هذا تحسن واضح. في Light الخلفية الشديدة الغسل تقلل القوة، وفي Dark الهوية أفضل.
- **CURRENT PROBLEMS:** hero مستطيل عريض ما زال website-like، وأزرار `تعديل الميول/بطولاتي` منفصلة في أقصى يساره. أسفل stat strip يوجد فراغ كبير قبل بيانات الهوية الكروية. أعلى الصفحة تظهر utility glyphs كمربعات فارغة غير قابلة للتعرف. هوية اللاعب جيدة لكن البيئة ما زالت تنافسها.
- **EMPTY SPACE:** متوسط/مرتفع في نصف الصفحة السفلي عند 1280؛ أقل بكثير ومقبول في 844.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** avatar نحو 108 في 1280 ونحو 86-92 في 844؛ جيد مع إمكانية تكبير بسيط wide. الاسم 32-34 قوي، metadata 14-16. stat values نحو 28-30 جيدة. hero image purposeful لكن Light crop/overlay باهت. badges 48-52 مقبولة. لا pictogram مطلوب.
- **UTILITY ICONS:** نحو 3 أعلى الصفحة، لكنها تظهر كمربعات outline مبهمة؛ هذا defect بصري لا مجرد تفضيل. لا تكثرها قبل إصلاح المعنى.
- **BUTTON/INPUT/TOUCH:** زر التعديل نحو 36-38 في المقاسين وأقل من 44؛ `بطولاتي` text action ضعيف. لا inputs. tabs/links الثانوية تحتاج hit targets مؤكدة.
- **ALIGNMENT/RTL:** الهوية يمينا والإجراءات يسارا داخل hero منطقي، لكن المسافة بينهما مفرطة. stat strip متوازن RTL. بيانات النادي/الدوري يمينا والفئات يسارا مفهومة، لكنها مفصولة جدا على wide.
- **LIGHT/DARK:** Dark أنضج ويعطي الصورة عمقا. Light washed وPaper levels متقاربة. خطوط/حدود Dark منخفضة قليلا لكن مقروءة.
- **RESPONSIVE:** 844x390 ينجح في fit ويحافظ على الاسم/avatar/stats/الهوية دون scroll. تبقى أزرار 36px والمربعات الغامضة، والنص السفلي أصغر من المثالي عند عرض الهاتف الحقيقي.
- **GAME FEEL:** متوسط إلى جيد بسبب Player11 والإحصاءات؛ يحتاج أن تكون الشخصية أهم من hero environment.
- **LEGACY DNA:** متوسط: sports website profile hero، لا dashboard كامل.
- **DENSITY:** MEDIUM.
- **DECISION:** **REFINE** لا over-redesign: قو الهوية، اضبط hero/actions، كبّر touch، وأصلح utility glyphs.

## 39. Notifications - `notifications`

- **PURPOSE:** عرض دعوات/طلبات/تحديات/مكافآت؛ الـGolden حالة فارغة.
- **PRIMARY TASK/ACTION:** فهم أن القائمة فارغة؛ عند وجود بيانات تصفح الإشعارات. لا CTA إلزامي في الحالة الحالية.
- **FIRST FOCUS:** pictogram ثم `لا توجد إشعارات`، والهرمية واضحة لكن صغيرة على 1280.
- **CURRENT PROBLEMS:** empty group مصغرة داخل Canvas ضخم، والعنوان العلوي/الكicker micro. utility glyphs في الأعلى تظهر كمربعات فارغة غير مفهومة. لا توجد tonal surfaces تجعل Dark أكثر من sheet واحد.
- **EMPTY SPACE:** الفراغ مقصود لحالة فارغة لكنه أكثر من اللازم على 1280 لأن الوحدة نفسها لا تصل إلى empty-state scale المطلوب.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** pictogram يقارب 72-80 في 1280 و58-64 في 844؛ المطلوب wide 80-104 مع heading/copy أكبر قليلا. العنوان نحو 22-24، copy 14-15. لا صورة.
- **UTILITY ICONS:** 2 مربعات غامضة في app bar؛ يجب التعرف على الوظيفة أو حذفها. pictogram المركزي branded وليس utility.
- **BUTTON/INPUT/TOUCH:** لا أزرار ولا inputs في الحالة الفارغة. app-bar targets غير قابلة للحكم بصريا ويجب ضمان 44-48.
- **ALIGNMENT/RTL:** empty state مركزي جيد، والعنوان RTL صحيح. الـkicker قريب جدا من العنوان في 844، والمربعات العليا تضعف الاتزان.
- **LIGHT/DARK:** Light نظيف لكنه بلا عمق. Dark تباينه النصي جيد لكن Canvas واحد شبه أسود.
- **RESPONSIVE:** 844x390 fits جيدا والنص مقروء، والمجموعة تبدو أنسب نسبيا من 1280. لا تكبر wide بنفس النسبة على compact؛ استخدم 64-72 pictogram compact و88-96 wide.
- **GAME FEEL:** متوسط منخفض؛ pictogram أحدعش جيد، لكن الحالة ساكنة جدا.
- **LEGACY DNA:** منخفض/متوسط؛ المشكلة micro-scale/topbar أكثر من dashboard.
- **DENSITY:** DENSE عند البيانات / FOCUS في empty state.
- **DECISION:** **REFINE** بتكبير الوحدة wide، تنظيف top utilities، وتعريف data-state بنفس القوة.

## 40. Settings - `settings`

- **PURPOSE:** إدارة الحساب واللعب والصوت/الاهتزاز والمظهر والإشعارات والخصوصية والمساعدة، حسب ما هو منفذ فعلا.
- **PRIMARY TASK/ACTION:** اختيار مجموعة ثم تغيير إعداد أو فتح شاشة فرعية.
- **FIRST FOCUS:** بطاقة الحساب المختارة الكبيرة في rail يمينا تنافس عنوان الإعدادات ومحتوى الحساب، بدل أن يقود التركيز إلى الخيارات.
- **CURRENT PROBLEMS:** desktop master-detail unfinished: rail عريض بفئة مختارة 224x105 تقريبا، فئات أخرى كنصوص متباعدة عموديا، ومحتوى حساب يسارا ثم فراغ هائل. الهرمية ضعيفة ولا توجد مجموعة Privacy رغم أن المحظورين خصوصية. حذف الحساب يبدو قريب الوزن من الإجراءات العادية.
- **EMPTY SPACE:** حرج أسفل content والrail وبين عناصر الفئات. لا ينتج عنه هدوء بل شاشة غير مكتملة.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** avatar 88-92 جيد، لكن rows 14-17 فقط، kicker 12-13. لا صورة ولا pictograms مطلوبة. قوة الاسم داخل بطاقة الحساب أفضل من بقية الصفحة.
- **UTILITY ICONS:** رجوع + نحو 4 chevrons في حالة Account. لا icons لكل مجموعة وهذا جيد، لكن اتجاه chevrons/الرجوع يحتاج إصلاح RTL.
- **BUTTON/INPUT/TOUCH:** action rows تقارب 56 وتحقق اللمس، لكن rail labels لا تملك affordance موحد. لا inputs في الحالة المصورة. يجب ألا تنخفض rows عن 48-56.
- **ALIGNMENT/RTL:** rail يمينا/content يسارا مفهوم على wide، لكن سهم الرجوع على يمين الصفحة ظاهر باتجاه اليسار، وchevrons الصفوف تبدو باتجاه اليمين؛ كلاهما يحتاج semantic mirroring. المحاور لا تستخدم عرض 928 بذكاء.
- **LIGHT/DARK:** Light flat، والبطاقة المختارة شاحبة. Dark selected surface أوضح لكنه ما زال panel أخضر داكنا وسط sheet أسود.
- **RESPONSIVE:** لا 844x390 خام. master-detail بعرض rail 168 compact مذكور في التنفيذ لكنه غير مثبت بصريا، ومن المرجح أن يضغط المحتوى أكثر من اللازم.
- **GAME FEEL:** منخفض، وهو مقبول جزئيا للإعدادات، لكن ما زال يجب أن يشعر كأحدعش لا control panel.
- **LEGACY DNA:** مرتفع جدا: desktop settings rail.
- **DENSITY:** MEDIUM.
- **DECISION:** **REBUILD** كقائمة مجموعات حقيقية فقط: Account / Game / Sound / Haptics / Appearance / Notifications / Privacy / Help حسب التنفيذ، بصفوف 48-56.

## 41. Report a problem - `reportProblem`

- **PURPOSE:** إرسال بلاغ دعم بنوع ووصف مع metadata فنية مفيدة.
- **PRIMARY TASK/ACTION:** اختيار نوع المشكلة، وصفها، ثم `إرسال البلاغ`.
- **FIRST FOCUS:** العنوان `ساعدنا نفهم المشكلة` ثم form؛ هذه الهرمية أوضح من بقية شاشات الدعم.
- **CURRENT PROBLEMS:** العرض الحالي وصل فعليا إلى نحو 620px، لكن shell المحيط كبير وفارغ، لا يوجد رجوع ظاهر، والtextarea تعتمد على placeholder بدل label دائم. footer يعرض `/settings` وإصدارا/شاشة بصيغة تقنية صغيرة وغير مصقولة للمستخدم. النص يحذر من بيانات الدفع لكنه لا يوضح حالة الإرسال/المرفقات إن لم تكن مدعومة.
- **EMPTY SPACE:** الفراغ الجانبي مقبول نسبيا لأن المهمة focused؛ الإطار الكامل وdecorative goal lines غير ضروريين. المسافات العمودية شديدة الضيق عند أسفل CTA/footer.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** headline نحو 30 جيد، body 15-16، field labels 11-12 صغيرة، placeholder 16. لا صورة ولا pictogram، وهذا صحيح لهذه المهمة.
- **UTILITY ICONS:** سهم dropdown واحد؛ لا رجوع واضح. الشعار ليس navigation.
- **BUTTON/INPUT/TOUCH:** dropdown نحو 48، CTA نحو 52، وعرض form نحو 620: جيدة. textarea ضخمة نحو 375 ارتفاعا لكنها بلا label ثابت. footer tiny. يجب إبقاء focused column 480-620 مع موازنة الارتفاع.
- **ALIGNMENT/RTL:** الحقول والنص RTL جيدان، وسهم القائمة يسارا صحيح كعنصر trailing في field. العمود centered وواضح، لكن header منفصل عنه ولا يملك leading.
- **LIGHT/DARK:** Light واضح لكنه مسطح. Dark fields تفصل أفضل قليلا، والـCTA الفاتح بارز؛ الحدود ما زالت منخفضة.
- **RESPONSIVE:** لا 844x390 خام؛ textarea الحالية لن تلائم 390 من دون تقليص مدروس/scroll للـsupport screen، مع الحفاظ على CTA 44-48.
- **GAME FEEL:** غير مطلوب؛ brand feel بسيط لكن generic support form.
- **LEGACY DNA:** متوسط منخفض: form ويب، لكنه focused وليس dashboard.
- **DENSITY:** FOCUS.
- **DECISION:** **RECOMPOSE** لا إضافة features: label دائم، رجوع، footer أنظف، واستجابة ارتفاع قصيرة.

## 42. Football preferences - `club_picker`

- **PURPOSE:** اختيار الدوري ثم النادي وضبط ظهور التفضيل، ثم الحفظ.
- **PRIMARY TASK/ACTION:** Step 1 اختيار الدوري، Step 2 اختيار النادي بصريا، ثم حفظ.
- **FIRST FOCUS:** قائمة الدوريات يمينا، لكن split control panel والفراغ الهائل يسارا يضعفان إحساس الخطوات.
- **CURRENT PROBLEMS:** ما زالت Control Panel: قائمة يمين + detail pane يسار، search معطل قبل الاختيار، empty shield صغير، وإعداد الظهور/حالة الاختيار/الحفظ محشورة في footer. badges مجرد أحرف دول وليست غنية بصريا، ولا توجد club badge grid في الحالة المصورة.
- **EMPTY SPACE:** حرج في pane النادي قبل اختيار الدوري؛ الفراغ يبتلع الوحدة الإرشادية. لا ينبغي ملؤه بزخرفة، بل تحويل flow إلى خطوة مركزة.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** league badges 40 تقريبا، أقل من club target 48-64. empty shield 52-58 وheading 18 صغيران. rows 84 تقريبا جيدة، search text 15. لا صور/شعارات أندية في الحالة الحالية.
- **UTILITY ICONS:** رجوع، بحث، سهما pagination = 4؛ إضافة إلى toggle/status. العدد مقبول لكن pager صغير ومنفصل، وسهم الرجوع يحتاج mirroring RTL.
- **BUTTON/INPUT/TOUCH:** search نحو 48 جيد، league rows مريحة، save نحو 44 لكنه disabled ومنخفض التباين، toggle جيد. `لاحقا` text action يحتاج target واضح. footer controls كثيرة وغير مترابطة.
- **ALIGNMENT/RTL:** تسلسل Step 1 يمينا ثم Step 2 يسارا صحيح، لكن السهم أعلى اليمين يتجه لليسار، والfooter يسار الصفحة لا يتبع تدفق الخطوات. المزج بين العربية وSA/EN/ES/IT مقبول إن كان مضبوط baseline.
- **LIGHT/DARK:** Light مسطح جدا. Dark أوضح في قائمة الدوريات لكن مساحة النادي sheet سوداء. ألوان badges مميزة دون إفراط أخضر.
- **RESPONSIVE:** لا 844x390 خام. split 35/65 والfooter المتعدد معرضان للضغط؛ يجب تحويلهما إلى step-by-step أو stacked/adaptive grid.
- **GAME FEEL:** منخفض؛ حاليا settings tool لا اختيار كروي بصري.
- **LEGACY DNA:** مرتفع جدا: master-detail/control panel.
- **DENSITY:** DENSE في club grid / MEDIUM في خطوة الدوري؛ الحالي SPARSE.
- **DECISION:** **REBUILD** كخطوتين بصريتين: league selector ثم club badge grid + search، بأحجام badges 48-64.

## 43. Premium - `premium`

- **PURPOSE:** شرح قيمة Premium، عرض الخطة/السعر الحقيقي عند توفر المتجر، الاشتراك، والاستعادة.
- **PRIMARY TASK/ACTION:** فهم القيمة ثم اختيار الخطة والاشتراك؛ استعادة المشتريات ثانوية.
- **FIRST FOCUS:** headline `Premium بسيط وواضح` مع pictogram الذهبي، لكن الخطة/السعر/CTA في الجهة الأخرى أضعف بكثير.
- **CURRENT PROBLEMS:** يشبه information + disabled button أكثر من subscription experience. لا monthly/yearly أو سعر لأن المتجر غير متاح، وهذا أفضل من اختلاق سعر، لكن حالة عدم التوفر لا تعطي مسارا واضحا. benefits grid نصي جيد من ناحية تقليل الأيقونات لكنه منفصل عن plan. app-bar utilities تظهر كمربعات outline غامضة.
- **EMPTY SPACE:** مرتفع في 1280 حول نصفي المحتوى، أقل وأفضل كثيرا في 844. الخطة نفسها مساحة ضحلة لا توازن hero.
- **SCALE/TYPOGRAPHY/IMAGE/PICTOGRAM:** headline نحو 34-36 wide و28-30 compact؛ جيد. pictogram نحو 88-96 wide ونحو 68-76 compact، يحتاج wide 96-120. benefits 15-17. plan title 15 وcopy 14، footnote 10-11 صغير جدا. لا صورة وهذا مناسب.
- **UTILITY ICONS:** 2 مربعان غامضان قرب الاستعادة/حافة العنوان؛ أصلح المعنى أو احذف. لا generic icon بجانب كل benefit، وهذا قرار صحيح.
- **BUTTON/INPUT/TOUCH:** CTA بارتفاع يقارب 36 في 1280 و844، أقل بوضوح من 48-54، وهو disabled بلا بديل. restore text action يحتاج target 44. لا plan selector في الحالة الحالية.
- **ALIGNMENT/RTL:** الخطة يمينا والرسالة/الفوائد يسارا يمكن أن يعمل RTL، لكن الانفصال كبير. خلط Premium/Player11/NO PAY-TO-WIN يحتاج ضبط baseline والوزن، لا تعريب قسري.
- **LIGHT/DARK:** Gold مضبوط ومحصور في premium. Dark أكثر عاطفية وتباينا. Light نظيف لكنه مسطح، والزر المعطل يختفي تقريبا.
- **RESPONSIVE:** 844x390 يعيد توزيع المساحة جيدا ويحافظ على المحتوى، لكن CTA يبقى 36 والfootnote صغير، وpictogram أصغر من الهوية المرغوبة. لا overflow ظاهر.
- **GAME FEEL:** متوسط؛ gold pictogram وNO PAY-TO-WIN يضيفان شخصية، لكن commerce hierarchy ضعيفة.
- **LEGACY DNA:** متوسط: marketing/spec sheet أكثر من Premium moment.
- **DENSITY:** MEDIUM.
- **DECISION:** **RECOMPOSE** حول pictogram + value + real plans/prices عند توفرها + CTA 48-54 + benefits + restore، بلا سعر وهمي.

---

## تدقيق ضرورة المسارات

### Match Setup - `/play/setup/:gameType`

- **الدليل الحالي:** `PlayScreen` يفتح `/play/setup/${type.slug}`. الشاشة هي نقطة تشعب حقيقية: practice -> `/solo`، و1v1/2v2/private -> `/online`. كما يعيد `OnlineMatchScreen` اللاعب إلى `/play/setup/classic?format=1v1` في أحد المسارات.
- **الحكم:** وظيفة اختيار format ضرورية، لكن الشاشة المستقلة الحالية ليست بالضرورة ضرورية؛ `PlayScreen` اختار Game Type أصلا ثم تعرض شاشة ثانية بأربع بطاقات متساوية، بينما Categories تذهب مباشرة إلى `/solo` وتتجاوزها.
- **القرار:** **MERGE** اختيار format داخل Play/detail أو flow موحد بعد اختيار النوع، مع إبقاء redirect/compatibility للمسار القديم مؤقتا. لا تحذف branching logic أو deep links قبل migration.

### Solo Setup - `/solo`

- **الدليل الحالي:** Categories تفتح `/solo` من featured tile ومن category tiles. الشاشة تختار categories + difficulty + opponent level + question count، تبني `SoloMatchRequest`، تبدأ `soloMatchController`، ثم تذهب إلى `/solo/match`. النتيجة تعود إليها أيضا.
- **الحكم:** الوظيفة مطلوبة ولا يمكن REMOVE. لكن اختيار categories مكرر بين Categories وSolo Setup، والواجهة الحالية dashboard منفصل عن Party language.
- **القرار:** **MERGE** category intent مع Solo flow أو تمرير category المحدد إلى setup، ثم **REBUILD** التكوين بلغة Party. أبق route/controller/backend إلى أن يثبت flow بديل كامل.

### Blocked Players - `/blocked-players`

- **الدليل الحالي:** route معرف، والمدخل المرئي الوحيد في `mobile/lib` هو Settings Account. الشاشة تستدعي `get_blocked_players` وتدعم `unblockPlayer`، لذلك القدرة والبيانات لازمتان.
- **الحكم:** ليست destination رئيسية مستقلة؛ هي Privacy utility. وجودها الحالي تحت Account لا يطابق النموذج الذهني، وغياب رجوع ظاهر يزيد سوء المسار.
- **القرار:** **MOVE** إلى Settings -> Privacy. يمكن إبقاء route داخليا/للتوافق أو تحويله إلى subroute، مع إبقاء repository/provider/backend. لا تلمع standalone shell الحالية.

---

## أهم 5 مشكلات حرجة في الشاشات 30-43

1. **Team Detail يحتاج rebuild كامل:** ثلاثة أعمدة dashboard، فراغات ضخمة، أخضر زخرفي، و8+ utility icons؛ لا توجد مهمة واحدة واضحة.
2. **Online/Private Lobby لا يملكان مركز قرار:** مساحات كبيرة مع أزرار/حالات صغيرة، وready/start/room state غير ذات وزن؛ تجربة الاتصال تبدو form/table لا لعبة.
3. **Settings وFootball Preferences ما زالا desktop control panels:** rails/panes وفراغات ومجموعات ضعيفة، مع Privacy في المكان الخطأ واتجاه أسهم RTL يحتاج تصحيحا.
4. **micro-UI/navigation defects ظاهرة:** أزرار 36-38 في Private Room/Profile/Premium/Team Detail، tabs أقل من 44، مربعات utility غير مفهومة في Profile/Notifications/Premium، وغياب رجوع واضح في Blocked/Report.
5. **الاستجابة غير مثبتة:** 844x390 متوفر فقط لـProfile/Notifications/Premium ضمن هذه المجموعة، وTeam Challenge حتى ليس 1280x720 بل 1280x760. لا يجوز اعتماد بقية التركيبات قبل Goldens فعلية 800x360/844x390/915x412.


