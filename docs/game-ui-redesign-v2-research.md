# AHDAH 11 — Game UI Redesign V2 Research

تاريخ التحقق: 2026-08-29 (Asia/Riyadh). البحث سبق أي تعديل V2. استخدمت المصادر الرسمية للمبادئ التقنية، ومواقع المنتجات الرسمية لفهم hierarchy فقط؛ لا أصول أو تخطيطات أو ألوان منسوخة.

## المصادر الرسمية والدروس

| المصدر | ما تعلمته | ما سيطبق في أحدعش |
|---|---|---|
| [Apple — Designing for Games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games) | عالم اللعبة والواجهة يجب أن يتصرفا كوحدة واحدة مع تفاعل مباشر وواضح | Game surface مستمر، عناصر أساسية مباشرة بدل صفحات business |
| [Apple — Game Controls](https://developer.apple.com/design/human-interface-guidelines/game-controls) | إظهار التحكم المتاح في سياقه، 44×44pt للتحكم المتكرر، وحالة ضغط مرئية/لمسية | hit targets ≥44 مع visual footprint أصغر، progressive details، press feedback |
| [Apple — Motion](https://developer.apple.com/design/human-interface-guidelines/motion) | الحركة قصيرة وهادفة واختيارية ولا تحمل المعنى وحدها | 100–220ms، Reduced Motion، icon/text مع الحركة |
| [Apple — Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) | semantics والتباين والنص القابل للتكبير جزء من اللعبة | scroll fallback فقط عند text scale الكبير، labels لكل control |
| [Android — Google Play Games guidelines](https://developer.android.com/games/guidelines) | Landscape يملأ 4:3 و16:10 و21:9 بلا letterbox ويظل تفاعليًا | Compact/Standard/Wide مع zones مرنة واحترام safe insets |
| [Android — Adapt layouts](https://developer.android.com/design/ui/mobile/guides/layout-and-content/adapt-layout) | إعادة تدفق controls أفضل من تكبير/تصغير شاشة واحدة | pane count وgrid density يتغيران حسب المساحة المتاحة |
| [Flutter — Adaptive approach](https://docs.flutter.dev/ui/adaptive-responsive/general) | افصل data/state عن composition المتكيفة | نفس controllers/backend مع compositions جديدة |
| [Flutter — Performance](https://docs.flutter.dev/perf/best-practices) | تجنب saveLayer/opacity/clips الزائدة وintrinsic passes، واعزل rebuilds | CustomPainter بسيط، RepaintBoundary، const، grids محددة، بلا blur عام |
| [Flame — GameWidget](https://docs.flame-engine.org/latest/flame/game_widget.html) | Flame surface يمكن أن يملأ المنطقة وFlutter overlays تدير HUD/controls | canvas للسطح الحي، Flutter للأسئلة والإجابات والوصول |
| [Flame — Camera & World](https://docs.flame-engine.org/latest/flame/camera.html) | HUD يمكن تثبيته في viewport والحركة تخص العالم | camera micro-effects في gameplay فقط |
| [Flame — Effects](https://docs.flame-engine.org/latest/flame/effects/effects.html) و[Particles](https://docs.flame-engine.org/latest/flame/rendering/particles.html) | effects محدودة العمر وتزال من lifecycle | bursts قصيرة للإجابة/النتيجة، بلا جسيمات مستمرة ثقيلة |

## دراسة منتجات الألعاب — hierarchy فقط

- [EA SPORTS FC Mobile](https://www.ea.com/en/games/ea-sports-fc/fc-mobile): mode-first entry، ملعب/منافسة في المركز، معلومات ثانوية حوله. نأخذ وضوح الأولوية فقط.
- [eFootball](https://www.konami.com/efootball/en-us/): فصل واضح بين mode selection واللعب. نأخذ progressive disclosure فقط.
- [Brawl Stars Teams](https://support.supercell.com/brawl-stars/en/articles/friendly-games-4.html): slots، ready state، team code، ودعوة الأصدقاء تظهر كأفعال قصيرة. نأخذ نموذج الحالة لا شكل الشاشة.
- [Kahoot Team Experience](https://support.kahoot.com/hc/en-us/articles/4408679135891-Team-experience-How-to-play-kahoot-in-groups): score/podium واضحان وحالة الفريق مرئية أثناء اللعب. نأخذ وضوح score/team state فقط.

## الاتجاه المطبق

1. `AhdashGameSurface`: طبقات gradient + pitch geometry + إيقاع نجدي/Sadu تجريدي + motif 11، بلا poster.
2. `GamePanel`, `HudStrip`, `GameSelectionTile`, `PlayerSlot`, `TeamSlot`, `RankingRow`: أسطح cut-corner وخطوط اتجاهية، وليست Cards متشابهة.
3. navigation dock بعرض 56–64، والنص يظهر عند المساحة القياسية فقط.
4. Typography أكثر كثافة: display 24–30، section 18–22، body 14–17، caption 11–13، score 22–32.
5. No-scroll الطبيعي: tabs، grids، page controls، side panels وoverlays. Scroll لا يظهر إلا كـaccessibility fallback.
6. Lime للحالة النشطة/CTA/score/progress فقط؛ sand/gold للتنبيه والرتبة.

## ما رُفض

- نسخ أي screenshot، asset، icon، mascot، colors، motion curve أو exact layout من لعبة أخرى.
- hero/poster يأخذ نصف الشاشة، glass في كل سطح، nested cards، neon dashboard، bottom navigation عريض، وinfinite vertical lists.
- shaders/post-processing العام قبل profile قياسه على جهاز؛ لا ادعاء 60FPS من الاختبارات المكتبية.
- تحويل Flame إلى طبقة للنص العربي أو forms؛ Flutter يبقى مسؤولًا عن semantics والقراءة.
