# عقد صيغ الأسئلة

## فصل المفاهيم

- `question_type`: وسيط العرض الأساسي الحالي (`text` أو `image`).
- `gameplay_type`: عقد اللعب القديم/المتصل (`classic` أو `true-false`) ولا يُستخدم وحده لتحديد واجهة party.
- `question_format`: صيغة renderer في لعبة الجلسة.

هذا التوسع يستخدم جدولي `questions` و`question_options` الحاليين ولا ينشئ `questions_v3`.

## الصيغ المنفذة

| الصيغة | السلوك في Party | متطلبات النشر |
|---|---|---|
| `open_answer` | سؤال كبير ثم كشف الإجابة | `correct_answer`، ولا خيارات |
| `multiple_choice` | يعرض الخيارات ضمن renderer عند تعريفها | 4 خيارات وخيار صحيح مملوك للسؤال |
| `true_false` | يعرض «صح/خطأ» | خياران بالترتيب الثابت وإجابة صحيحة |
| `image` | الصورة هي العنصر الرئيسي مع fallback واضح | رابط صورة، إجابة، وحالة حقوق موثقة |

## Question Renderer Engine

تستقبل الشاشة `PartyQuestionSnapshot` واحدًا، ثم تختار renderer حسب `format`. بقية الشاشة—القسم، النقاط، الفريق، المؤقت، المساعدات، وزر الكشف—مشتركة. إضافة صيغة لاحقة لا تستدعي نسخ شاشة السؤال.

## حقول snapshot

`id`, `category_id`, `text`, `answer`, `alternative_answers`, `explanation`, `difficulty`, `point_value`, `format`, `options`, `image_url`, `used`.

## صيغ مخطط لها وليست منفذة

`audio`, `video`, `ordering`, `zoom_image`, `career_path`, `guess_player`, `guess_club`, `guess_league`, `who_scored`, `lineup`, `multi_clue`, `where_ball`, `comparison`.

لا تُفعّل هذه القيم في قاعدة البيانات قبل وجود renderer، تحقق import، media rights، offline fallback، واختبارات مناسبة.
