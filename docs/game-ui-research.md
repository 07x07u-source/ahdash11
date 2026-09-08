# بحث واجهة وتجربة لعبة أحدعش | 11

`checked_at`: 2026-08-28 (Asia/Riyadh).  
المنهج: مصادر رسمية/أولية قدر الإمكان. لم تُنسخ screenshots أو layouts أو assets أو ألوان أو لغة بصرية محمية؛ استُخرجت مبادئ عامة فقط.

## سجل المصادر التقنية

| source_title | source_url | source_type | checked_at | principle_learned | how_applied_in_ahdash | copyright_boundary |
|---|---|---|---|---|---|---|
| Apple Human Interface Guidelines | https://developer.apple.com/design/human-interface-guidelines | Official platform guidance | 2026-08-28 | hierarchy، harmony، consistency، وتهيئة app/game للمنصة | CTA لعب واحد، تدرج بصري، ومكونات platform-aware | لا Apple assets أو layouts منسوخة |
| Apple HIG — Games | https://developer.apple.com/design/human-interface-guidelines/games | Official design guidance | 2026-08-28 | اللعب يجب أن يبقى المحتوى الأساسي مع controls واضحة | navigation خفيفة وgame stage في مركز جلسة السؤال | مبادئ فقط؛ لا Game Center art أو UI copy |
| Apple HIG — Game Center | https://developer.apple.com/design/human-interface-guidelines/game-center | Official design guidance | 2026-08-28 | social identity/achievement feedback يحتاج وضوحًا واتساقًا | Player 11، MVP، ranking وteam identity بدون نسخ badges | لا Game Center marks/icons |
| Apple HIG — Motion | https://developer.apple.com/design/human-interface-guidelines/motion | Official design guidance | 2026-08-28 | motion purposeful/brief/optional، وتوفير بدائل وتقليل الحركة | motion tokens قصيرة، reduced motion يلغي particles/shake/transitions الكبيرة | لا animations منسوخة |
| Apple HIG — Materials | https://developer.apple.com/design/human-interface-guidelines/materials | Official design guidance | 2026-08-28 | المواد تخدم hierarchy ولا تطغى على القراءة | layers واضحة وتقليل blur/shadows | لا إعادة إنتاج مواد Apple الخاصة |
| Apple HIG — Layout | https://developer.apple.com/design/human-interface-guidelines/layout | Official design guidance | 2026-08-28 | layout يتكيف مع المساحة والنص | game tiles تتحول من عمودين لواحد وanswers من 2×2 إلى vertical | لا نسخ layout حرفي |
| Apple HIG — Accessibility | https://developer.apple.com/design/human-interface-guidelines/accessibility | Official accessibility guidance | 2026-08-28 | لا تعتمد المعلومة على اللون/الحركة/الصوت وحدها | icon+label+shape للحكم، semantics، text scale، reduced motion | لا assets |
| Apple — Adapting game UI for smaller screens | https://developer.apple.com/documentation/Metal/adapting-your-game-interface-for-smaller-screens | Official developer documentation | 2026-08-28 | labels adaptable، avoid fixed sizes، واختبار مختلف الشاشات/RTL | Flutter overlays للنص العربي بدل Canvas text ثابت | لا code/assets منسوخة |
| Flutter Performance Best Practices | https://docs.flutter.dev/perf/best-practices | Official framework docs | 2026-08-28 | قلل expensive work/rebuilds وراقب rendering | GameWidget ثابت، state selectors، const widgets، decode-size مناسب | أمثلة مفاهيمية فقط |
| Flutter UI performance | https://docs.flutter.dev/perf/ui-performance | Official framework docs | 2026-08-28 | jank يقاس في profile على جهاز وليس بالادعاء | static/profile-oriented optimization فقط؛ القياس الحقيقي manual QA | لا أرقام FPS مختلقة |
| Flutter Animations | https://docs.flutter.dev/ui/animations | Official framework docs | 2026-08-28 | implicit/explicit animation حسب الحاجة مع lifecycle سليم | implicit transitions للمكونات البسيطة وFlame effects للمسرح | لا نسخ demo styling |
| Flutter Games Toolkit | https://docs.flutter.dev/resources/games-toolkit | Official framework docs | 2026-08-28 | Flutter مناسب للـUI ويمكن دمجه مع game engine | shell/forms/social في Flutter؛ gameplay visual layer في Flame | لا template منسوخ |
| Flutter Accessibility | https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility | Official framework docs | 2026-08-28 | semantics، contrast، large text، 48dp targets | answers ≥48dp، semantics tests، no color-only verdict | لا assets |
| Flutter Adaptive & Responsive | https://docs.flutter.dev/ui/adaptive-responsive | Official framework docs | 2026-08-28 | responsive يملأ المساحة، adaptive يغير composition | two-column only when width/text scale allow | لا layout منسوخ |
| Flame GameWidget | https://docs.flame-engine.org/latest/flame/game_widget.html | Official engine docs | 2026-08-28 | GameWidget هو bridge ويدعم loading/error/background/overlays وRepaintBoundary | game stage embedded، Flutter question/answers overlay، explicit loading/error | code samples لم تُنسخ حرفيًا |
| Flame Overlays | https://docs.flame-engine.org/latest/flame/overlays.html | Official engine docs | 2026-08-28 | Flutter widgets فوق game canvas للحوار/menus/HUD | النص العربي والـsemantics في Flutter overlays | لا visual assets |
| Flame Components | https://docs.flame-engine.org/latest/flame/components/components.html | Official engine docs | 2026-08-28 | component lifecycle/mount/remove وفصل المسؤوليات | components بصرية فقط ولا scoring/network logic | لا code large-copy |
| Flame Effects | https://docs.flame-engine.org/latest/flame/effects/effects.html | Official engine docs | 2026-08-28 | effects declarative وتزال عند الانتهاء | pulse/scale/wrong-shake bounded، `removeOnFinish` | لا demo art |
| Flame Particles | https://docs.flame-engine.org/latest/flame/rendering/particles.html | Official engine docs | 2026-08-28 | particles لها lifespan وتزال تلقائيًا | أشكال 11/Najdi قصيرة فقط عند correct/win | لا particle artwork منقول |
| Flame Lifecycle / FlameGame | https://docs.flame-engine.org/latest/flame/game.html | Official engine docs | 2026-08-28 | `onLoad/onMount/update/render/onRemove` وضرورة cleanup/caches | explicit dispose/remove/listener cleanup | لا code نسخ مباشر |
| Flame Testing | https://docs.flame-engine.org/latest/flame/testing.html | Official engine docs | 2026-08-28 | game/component behavior يمكن اختباره دون جهاز | `flame_test` للمount/effect/remove وreduced motion | لا fixture منسوخ |
| Flame Shaders/Post Processing | https://docs.flame-engine.org/latest/flame/rendering/post_processing.html | Official engine docs | 2026-08-28 | post processing قوي لكنه مكلف ويجب أن يكون موضعيًا | لا shader في P0؛ optional victory/timer فقط بعد profiling | لا shader code منقول |
| Android Core App Quality | https://developer.android.com/docs/quality-guidelines/core-app-quality | Official platform guidance | 2026-08-28 | critical flows، rendering، lifecycle وجودة أساسية | QA matrix لحالات الشبكة/background/rotation/text scale | لا assets |
| Android Adaptive App Quality | https://developer.android.com/develop/adaptive-apps/quality-guidelines/adaptive-app-quality | Official platform guidance | 2026-08-28 | compatibility عبر sizes/window states | phone targets 360×800/390×844/412×915 الآن، large-screen لاحقًا | لا layouts منسوخة |
| Android Technical Quality | https://developer.android.com/quality/technical | Official platform guidance | 2026-08-28 | startup/rendering/app size والبطارية جزء من الجودة؛ 60fps هدف لا claim | asset budget، bounded effects، manual frame profiling مطلوب | لا benchmark claim قبل جهاز |
| Android Accessibility Principles | https://developer.android.com/guide/topics/ui/accessibility/principles | Official platform guidance | 2026-08-28 | descriptive labels/actions وحوافز غير لونية | semantics لكل action وverdict icon/text | لا UI copy منسوخة |

## سجل مراجع UX والمنتج

| source_title | source_url | source_type | checked_at | principle_learned | how_applied_in_ahdash | copyright_boundary |
|---|---|---|---|---|---|---|
| Seen Jeem / سين جيم | https://seenjeemkw.com/ | Official product site | 2026-08-28 | وضوح اختيار الفئات، عدد أسئلة مفهوم، وتجربة جماعية حول جلسة واحدة | category/setup مختصر و«فريق الاستراحة» كحلقة اجتماعية سعودية أصلية | لا screenshots، questions، helpers، layouts أو brand styling منسوخة |
| Kahoot Team Experience | https://support.kahoot.com/hc/en-us/articles/4408679135891-Team-experience-How-to-play-kahoot-in-groups | Official help center | 2026-08-28 | team slots/lineups/ready state والتعامل مع drop/rebalance يجب أن يكون ظاهرًا | lobby slots، team A/B، ready/connection state؛ server decides membership | لا Kahoot shapes/colors/sounds أو exact lobby |
| Kahoot Points | https://support.kahoot.com/hc/en-us/articles/115002303908-How-points-work | Official help center | 2026-08-28 | سرعة الإجابة قد تؤثر على scoring لكن القاعدة يجب أن تكون معلومة وعادلة | Speed config server-authoritative؛ لا formula في client | لم تُنسخ معادلة أو scoring model |
| Duolingo Core Tabs Redesign | https://blog.duolingo.com/core-tabs-redesign/ | Official product/design blog | 2026-08-28 | نظام headers قابل للتوسع وتوزيع واضح لـquests/leaderboards/friend activity | خمسة tabs، hierarchy مختلفة لكل tab، challenge/rank/social loops دون ازدحام | لا mascots، illustrations، cards، colors أو copy منسوخة |

## المبادئ المستخلصة المطبقة

1. **يفهم خلال ثانيتين:** CTA اللعب ونوع لعبة واحد ظاهر فوق الطي.
2. **Type قبل Format:** المستخدم يختار «كلاسيك» ثم Solo/1v1/2v2، لا العكس.
3. **تأخير التفاصيل:** category/difficulty/count داخل setup تدريجي، لا form طويل.
4. **Authority visible:** waiting/reconnecting/pending reward حالات صريحة بدل أرقام محلية وهمية.
5. **Text belongs to Flutter:** السؤال العربي الطويل والأجوبة/semantics ليست Canvas text.
6. **Game feel bounded:** Flame stage/energy/particles قصيرة ولا تعطل input أو الانتقال.
7. **Social identity:** فريق الاستراحة، ربعك، MVP، والنادي المفضل حلقات مرئية، مع server membership.
8. **Copyright boundary:** الأيقونات والمقاطع والألوان والشخصية أصلية؛ لا شعار دوري/نادي ولا لاعب حقيقي دون ترخيص.

## ما لم يُستنتج من البحث

- لم نعتبر popularity أو شكل منتج منافس دليلًا لنسخه.
- لم نستنتج أن 60fps قيس فعليًا.
- لم نستنتج حق استخدام شعارات/صور من مجرد ظهورها في المواقع الرسمية.
- لم نعتبر وثائق Flame سببًا لإضافة Forge2D/Tiled/audio/Rive بلا حاجة وأصول فعلية.
