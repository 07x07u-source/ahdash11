# أحدعش | 11 — UI & Motion Research

تاريخ المراجعة: 2026-08-28

## المصادر الرسمية والأساسية

- [Apple HIG — Motion](https://developer.apple.com/design/human-interface-guidelines/motion): الحركة تشرح العلاقة والنتيجة، ويجب تجنب الحركة المستمرة أو الكبيرة غير الضرورية واحترام Reduce Motion.
- [Apple HIG — Materials](https://developer.apple.com/design/human-interface-guidelines/materials): المواد الشفافة طبقة وظيفية للتنقل والتحكم، وليست خلفية لكل المحتوى؛ الوضوح والتباين أولوية.
- [Apple — Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/): استخدام المادة كطبقة متكيفة حول عناصر التحكم، مع فصل المحتوى عنها.
- [Apple HIG — Layout](https://developer.apple.com/design/human-interface-guidelines/layout): التخطيط يتكيف مع المساحة، ويحافظ على ترتيب القراءة الصحيح في RTL، ولا يفترض مقاس شاشة واحدًا.
- [Flutter — Introduction to animations](https://docs.flutter.dev/ui/animations): البدء بالـimplicit animations، واستخدام physics/explicit controllers فقط عندما تحتاج الحالة إلى تحكم فعلي؛ Hero وstaggered patterns متاحة أصلًا.
- [Flutter — Performance best practices](https://docs.flutter.dev/perf/best-practices): حصر rebuilds، تجنب `saveLayer` وopacity/clipping غير الضروريين، واستخدام lazy lists وصور بالحجم المناسب.
- [Flutter — Rendering performance](https://docs.flutter.dev/perf/rendering-performance): القياس في Profile على جهاز حقيقي، وفصل الرسم المتغير عند الحاجة بدل افتراض أن كثرة المؤثرات مجانية.
- [Material 3 — Motion](https://m3.material.io/styles/motion/overview): الحركة تعبر عن الاستمرارية والاستجابة والهرمية، مع easing ودُدد متسقة بدل قيم عشوائية.
- [Android — Adaptive apps](https://developer.android.com/develop/adaptive-apps): قرارات التخطيط مبنية على المساحة المتاحة، لا اسم الجهاز؛ العرض والارتفاع يعالجان كلٌ على حدة.
- [Android — Supporting different display sizes](https://developer.android.com/develop/adaptive-apps/guides/support-different-display-sizes): استخدام breakpoints مركزية وتمرير قرار التخطيط إلى المكونات، بدل شروط متفرقة في كل شاشة.
- [Rive — Flutter runtime](https://rive.app/docs/runtimes/flutter/flutter) و[State machines](https://rive.app/docs/runtimes/state-machines): state machines قادرة على التوقف عند الاستقرار لتوفير الطاقة، لكن runtime/renderer يضيفان تكلفة واختلافات محتملة مع Impeller.
- [Kahoot — Single-screen gameplay](https://kahoot.com/blog/2022/08/08/tech-tip-single-screen/): السؤال والإجابات يجب أن يبقيا مقروءين على جهاز اللاعب نفسه؛ هذا مهم للوصول وللعب دون شاشة مضيفة.
- [Kahoot — Live game flow](https://support.kahoot.com/hc/en-us/articles/360039900153-Tips-for-hosting-a-live-game): lobby واضح، ثم سؤال، ثم reveal/feedback، ثم leaderboard/result؛ كل مرحلة لها لحظة تركيز واحدة.
- [Duolingo — Streak milestone animation](https://blog.duolingo.com/streak-milestone-design-animation/): الاحتفال يزداد فقط عند milestones المهمة، والتوقيت جزء من المعنى وليس زخرفة دائمة.
- [Apple HIG — Activity rings](https://developer.apple.com/design/human-interface-guidelines/activity-rings): progress visual يجب أن يمثل قيمة فعلية ومسمّاة، لا أن يستخدم كديكور؛ كما تمنع Apple نسخ Activity Rings لبيانات أخرى.

## المبادئ المستخلصة لأحدعش

1. **المساحة ملعب وليست فراغًا:** شاشة السؤال تستخدم الارتفاع كاملًا: status/timer ثابتان أعلى الشاشة، السؤال في منطقة مرنة، والإجابات تتمدد إلى المساحة المتبقية مع حد أدنى للمس.
2. **لحظة واحدة مهيمنة:** في Home تكون CTA المنافسة هي البطل؛ في Lobby يكون رمز الغرفة وحالة اللاعبين؛ في اللعب يكون السؤال والإجابة؛ في النتائج تكون النتيجة.
3. **Feedback متدرج وحقيقي:** press محلي فوري، ثم lock/wait، ثم correct/wrong من نتيجة السيرفر. اللون مدعوم بأيقونة ونص وشكل.
4. **Motion tokens موحدة:** micro `140ms`، standard `240ms`، emphasized `380ms`، مع ease-out للحضور وease-in للخروج وspring خفيف للضغط/العودة.
5. **الحركة تقل عند الطلب:** `MediaQuery.disableAnimationsOf` يعطل parallax/stagger/celebration ويُبقي تغير الحالة واضحًا وفوريًا.
6. **Glass انتقائي:** يسمح به في navigation/status overlays فقط. البطاقات والمحتوى تستخدم surfaces عادية وحدودًا وظلالًا خفيفة لتقليل كلفة GPU.
7. **RTL أولًا:** `AlignmentDirectional` و`EdgeInsetsDirectional` وترتيب قراءة عربي، مع بقاء الأرقام والرموز الرياضية LTR حين يلزم.
8. **Game feedback لا يغير السلطة:** النقاط والسرعة والمكافآت المعروضة تأتي من state/RPC الموجودة، ولا يعاد حسابها في Flutter.
9. **الاحتفال له قيمة:** النتيجة الفائزة تستعمل light burst وحركة نتيجة قصيرة؛ لا confetti دائم ولا particles ثقيلة.
10. **الصور محسوبة:** `cacheWidth/cacheHeight`، placeholders، ومساحات ذات aspect ratio ثابت لمنع قفز التخطيط.

## ما سيُستخدم

- Flutter native implicit/explicit animations، `AnimatedSwitcher`، `TweenAnimationBuilder`، و`Hero` عند وجود عنصر مشترك فعلي.
- Pressable surface واحدة مشتركة للزر والبطاقة مع scale صغير وhaptic اختياري.
- stagger خفيف في Home، وحركة دخول اللاعب في Lobby، وحالات answer/reveal وscore feedback، ونتيجة قصيرة.
- top progress track واضح بدل نسخ Activity Rings، لأنه يستغل العرض ويترك السؤال والإجابات تتمدد عموديًا.
- layout decisions مبنية على `LayoutBuilder` والارتفاع المتاح للأحجام 360×800، 390×844، 412×915.

## ما لن يُستخدم ولماذا

- **لن نضيف Rive الآن:** لا يوجد أصل `.riv` أصلي ومختبر يضيف قيمة لا تحققها Flutter native؛ إضافة runtime بلا أصل فعلي تزيد الحجم ومخاطر Impeller ولا تحسن المنتج.
- **لن ننسخ Liquid Glass على كل بطاقة:** يضر الوضوح والأداء، ويخالف فكرة أن المادة طبقة تحكم/تنقل.
- **لن ننسخ Apple Activity Rings:** إرشادات Apple تحصرها في Move/Exercise/Stand؛ سيستخدم أحدعش progress track خاصًا به.
- **لن ننسخ ألوان/أشكال إجابات Kahoot أو شخصيات Duolingo:** نأخذ وضوح المراحل والـfeedback فقط، ونحافظ على هوية أحدعش السعودية والليمونية.
- **لن نضيف parallax/blur/particles دائمًا:** تُحجز للحظات المهمة وتُلغى مع Reduce Motion للحفاظ على البطارية و60fps.
