# أحدعش | 11 — Party V2 Visual Before / After

تاريخ بدء الجولة: 2026-08-31.

## دليل Before المحفوظ

حُفظت 100 لقطة Golden قبل التعديل في `docs/visual-validation/party-v2-before/`، وتشمل 10 شاشات × خمسة مقاسات × Light/Dark. الصور الأصلية لم تُلتقط من Emulator؛ هي render حقيقي من Flutter widget tests.

## تدقيق Before

| الشاشة | الملاحظة البصرية | التصنيف |
|---|---|---|
| Home | نصف الشاشة قائمة من ثلاث panels والنصف الآخر hero؛ العين تتنقل بين كتلتين ولا توجد جملة «جاهزين للتحدي؟» | REDESIGN |
| Categories | ستة مستطيلات ذات borders قوية ومعلومات دائمة وأيقونتا action داخل كل عنصر؛ تبدو لوحة إدارة محتوى | REDESIGN |
| Teams | ثلاثة panels متساوية: فريق/فريق/تقسيم؛ مثال مباشر على quadrant/dashboard composition | REDESIGN |
| Helpers | panel كامل لكل فريق، وكل أداة صف/بطاقة مع description دائم؛ كثافة عالية وfocus مزدوج | REDESIGN |
| Ready | فرق وقواعد داخل panels مستقلة؛ يلزم اختزالها إلى أسماء/chips/icons | REDESIGN |
| Board | مقروءة لكنها 36 زرًا boxed مع header boxed لكل عمود؛ يلزم تحويلها إلى scoreboard متصل بفواصل خفيفة | REDESIGN |
| Question | التركيز جيد والسؤال ليس داخل Card؛ يحتاج انتقال reveal وحالة media أكثر نضجًا وreport action | SIMPLIFY/POLISH |
| Reveal | واضح، لكن الانتقال route-like والأزرار منفصلة عن حركة score | REDESIGN |
| Result | بسيط نسبيًا؛ يحتاج hierarchy أوضح وحركة صغيرة تحترم reduced motion | POLISH |
| How to Play | أربع cards متساوية بعيدة عن بعضها؛ تبدو dashboard وتفتقد demo بصريًا متتابعًا | REDESIGN |

## معايير After

- surface بصري واحد متصل في كل شاشة.
- focus أساسي واحد فقط، ثم actions ثانوية، ثم معلومات مساندة.
- Card محجوزة لمحتوى قابل للاختيار مثل Category، ومن دون Card داخل Card.
- Home في شاشة واحدة بلا scroll أو widgets قديمة.
- Team setup وHelpers وReady بلا تقسيم الشاشة إلى مربعات مستقلة.
- Question text مباشرة على Canvas، مع max width وRTL طبيعي.
- حركة موحّدة: press 100–120ms، page/reveal 180–260ms، shuffle ≤900ms، score 300–500ms، intro ≤600ms.
- reduced motion يعطل bounce/parallax/confetti/large transitions.
- Light warm off-white وDark deep charcoal، مع lime للحالة الفعالة فقط وgold للإنجاز.

## After evidence

- أُنشئت 130 لقطة نشطة: 13 شاشة × خمسة مقاسات × Light/Dark داخل `docs/visual-validation/party/`.
- الشاشات المغطاة: Home، Categories، Category detail، Teams، Team splitter، Helpers، Ready، Board، Question text، Question image، Answer، Result، How to Play.
- تم فحص لقطات compact dark وwide light لكل الشاشات، ثم فُحصت فرديًا Category detail وTeams وHome وBoard وQuestion image وReady وHow to Play وHelpers وPremium.
- عولجت نتيجة الفحص الفعلي: تمديد فن الفئة داخل Category detail، إزالة overflow في Ready على العرض الضيق، وضمان تحميل صورة Question image في أول Golden مظلم.
- اجتازت كل الـGoldens النشطة الاختبار ضمن تشغيل Flutter الكامل. ملفات `reveal_*` العشرة الأقدم باقية كسجل بصري تاريخي فقط وليست جزءًا من عقد V2 النشط.

## الحكم البصري النهائي

لا تستخدم Home أو Setup تكوين dashboard رباعي، ولا يُحاط السؤال ببطاقة عملاقة. لكل شاشة نقطة تركيز واحدة، ويقتصر استعمال الشبكة على Board لأنها جزء طبيعي من اللعبة. التباين والقراءة سليمان في Light/Dark والمقاسات الخمسة التي يغطيها الاختبار، مع مساحة أكثر اتساعًا في الشاشات العريضة بدل ملئها بعناصر غير لازمة.
