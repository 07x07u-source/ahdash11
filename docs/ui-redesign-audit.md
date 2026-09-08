# تدقيق إعادة تصميم أحدعش | 11

تاريخ التدقيق: 2026-08-28  
النطاق: `mobile`, `admin`, `supabase`, والأصول الموجودة محليًا.  
الحالة: Baseline موثق قبل جولة Flutter + Flame. لا يتضمن هذا الملف ادعاء اختبار على جهاز حقيقي.

> ملاحظة التنفيذ: عمود `Status` في جدول التدقيق أدناه يسجل حالة الشاشة لحظة التدقيق قبل التعديل. الجدول التالي هو الحالة الفعلية بعد التنفيذ، وهو المرجع الأحدث.

## حالة التنفيذ بعد الجولة

| area | after | accessibility / security outcome | status |
|---|---|---|---|
| Design system | Noto Kufi Arabic + Tajawal محليًا، semantic colors/motion/spacing، Light/Dark/System | لا runtime fonts؛ reduced-motion tokens | Implemented |
| Navigation | خمسة tabs: الرئيسية، العب، الاستراحة، الترتيب، حسابي؛ المتجر route ثانوي | labels وselected semantics؛ routes القديمة محفوظة | Implemented |
| Home | CTA لعب واضح، Player11/football/team/challenge/rank hierarchy | loading/error/offline states واختبارات 360px | Implemented |
| Play Hub / Setup | Game Type منفصل عن Format؛ Classic/TrueFalse/Speed مفعلة والبقية `قريبًا` | disabled tiles لا تستقبل taps؛ large text يتحول لعمود | Implemented |
| Classic online | `GameSessionController` مستقل + Flame stage ثابت + Flutter Arabic overlay | input lock، server clock، idempotency، reconnect، no answer key | Implemented locally; remote migration pending |
| True/False | خياران فقط، 10 ثوانٍ، pool/schema/admin مستقل | publish trigger وsafe payload وtests | Implemented locally; remote migration/content pending |
| Speed | Classic renderer مع 7 ثوانٍ وفصل matchmaking | duration من الخادم، no fake 60-second claim | Implemented locally; remote migration pending |
| Practice | Classic/TrueFalse/Speed محلي صريح بلا rewards | answer-key pool معزول عن competitive؛ bundled demos | Implemented |
| Player11 | اختيار male/female محفوظ ويظهر في onboarding/profile/settings/social fallbacks | أصول أصلية بلا شعارات/أشخاص حقيقيين؛ semantic labels | Implemented static fallback |
| Football preferences | استعادة القيم الخاصة، بحث عربي/إنجليزي مؤجل، rights label/fallback | RPC owner-only؛ logo URLs gated server-side | Implemented locally; catalog data unknown |
| Ranking | podium مع بطاقة موقع اللاعب حتى خارج أول 100 | rank نصي ورقمي لا يعتمد على اللون | Implemented |
| Friends / الاستراحة / MVP | hierarchy كروية، دعوات خاصة، team badge، weekly MVP | membership/roles تبقى server-authoritative | Implemented/polished |
| Team challenge | server clock وretry بنفس المفتاح؛ لا تبديل بعد نتيجة مجهولة | stored receipt + ownership + idempotency | Implemented locally; remote migration pending |
| Admin questions | محرر ذري لـClassic/TrueFalse ومسار تنافسي/تدريب منفصل | role-checked RPC؛ validation؛ import contract أصلح 0→1 based | Implemented locally |
| Ordering / Club Guess / Eagle Eye | tiles ظاهرة بوضوح كـ`قريبًا` ولا routes مكسورة | لا claims أو media غير مرخصة | Feature-flagged / Not implemented |

## القيود المحمية

- Package ID يبقى `com.ahdash.eleven`.
- migration `20260828000300_social_football_v1.sql` مطبّقة Remote ولا يجوز تعديلها.
- لا `supabase db push`، لا Emulator، لا تثبيت APK، ولا تغيير keystore.
- Git repository بلا commits حاليًا وملفات المشروع غير متتبعة؛ لذلك لا يجوز `clean/reset/checkout` أو حذف تغييرات المستخدم.

## Baseline القابل للتحقق

| البند | النتيجة قبل التعديل |
|---|---|
| Flutter / Dart | Flutter 3.47.2 stable، Dart 3.13.2 |
| `flutter analyze --fatal-infos` | PASS، بلا issues، نحو 254 ثانية |
| `flutter test` | PASS، 58/58 بعد تحرير generated caches فقط |
| Release APK الموجود مسبقًا | `mobile/build/app/outputs/flutter-apk/app-release.apk` |
| حجم APK الموجود | 83,487,790 bytes / 79.62 MiB |
| SHA-256 الموجود | `6080A6BD4F6BF153DBC4787EFB07C3B7F16C09DEFA7EDB5385D776F13679DCA5` |
| Package / signing | `com.ahdash.eleven`، signed؛ certificate SHA-256 `43475f354b73f4d2c9ad45663abfd6dffa86259303f91d1b2ed6a49383c18647` |
| Flame / Rive | غير موجودين |
| Local fonts | غير موجودة؛ theme يعتمد fallback system fonts |

ملاحظة تشغيلية: أول تشغيل للاختبارات توقف بسبب امتلاء القرص. حُذفت فقط caches مولّدة وقابلة للاستعادة (`mobile/build/app/intermediates`, test caches، أجزاء من `admin/.next` وFlutter temp)، مع الحفاظ على APK والمصادر، ثم نجحت الاختبارات.

## خريطة Routes الحالية

| Route | الشاشة | الرحلة الحالية | قرار التوافق |
|---|---|---|---|
| `/launch` | Launch | bootstrap/session routing | يبقى |
| `/onboarding` | Onboarding | 3 شرائح تسويقية قبل auth | يعاد بناء المحتوى مع الحفاظ على route |
| `/auth` | Auth | email/password وGoogle عند التفعيل | يبقى بلا كسر |
| `/home` | Home | hub قائم على cards | يعاد تصميمه |
| `/play` | Play | اختيار format أولًا | يتحول إلى Game Type hub |
| `/categories` | Categories | قائمة الفئات | يبقى deep link ويندمج من Play/Home |
| `/solo` | Solo setup | practice category/setup | يبقى كـPractice واضح |
| `/solo/match` | Question | local/offline practice | يبقى غير مصنف وغير مكافأ |
| `/solo/result` | Results | practice result | يبقى مع تسمية authority واضحة |
| `/online` | Online lobby | matchmaking/format | يبقى |
| `/online/match/:matchId` | Online match | server-backed classic | أساس vertical slice التنافسي |
| `/room/:roomId` | Room lobby | private room | يبقى |
| `/ranking` | Ranking | ranking list | يصبح tab رابع |
| `/store` | Store | store/wallet | يبقى route ثانوي داخل الحساب |
| `/profile` | Profile | player/profile cards | يصبح tab خامس ويعاد تصميمه |
| `/friends` | Friends | friends/invites | يبقى وينطلق من الاستراحة |
| `/football-preferences` | Football preferences | chips/list | يبقى ويعاد تصميم picker |
| `/teams` | Social hub | فريق الاستراحة/social | يصبح tab ثالث |
| `/blocked-players` | Blocked players | privacy/social | يبقى داخل settings/social |
| `/teams/:teamId` | Team | team details | يبقى |
| `/challenges/:challengeId` | Team challenge | server-backed challenge | يبقى، لا يوسّع authority محليًا |
| `/settings` | Settings | preferences cards | يبقى داخل profile |
| `/report-problem` | Support | report flow | يبقى |
| `/notifications` | Notifications | notification inbox | يبقى |

الـrouter مسطح حاليًا، ولا توجد redirects/guards مركزية. `AppShell` يحدد tab index داخل كل شاشة؛ أي migration للملاحة يجب أن يحافظ على deep links بدل إعادة تسمية routes.

## Bottom navigation الحالية

- Before: `الرئيسية / العب / الترتيب / المتجر / حسابي`.
- Main problem: المتجر يحتل tab أساسي بينما «فريق الاستراحة» ميزة هوية واجتماع أساسية.
- Proposed change: `الرئيسية / العب / الاستراحة / الترتيب / حسابي`، مع نقل المتجر إلى profile/home secondary action.
- Accessibility: semantics موجودة، لكن label size 10 ثابت يحتاج فحص text scale.
- Risk: indices موزعة داخل الشاشات؛ يجب تحديثها باختبارات route migration.
- Acceptance: خمسة tabs فقط، routes القديمة تعمل، selected semantics صحيحة، ولا overflow عند 360px وtext scale كبير.

## تدقيق الشاشات

الحالة `Planned` تعني أن المشكلة ثبتت في الكود، وليست ميزة منجزة.

| الشاشة | Before | Main problem / information priority | Visual & game-feel problem | Accessibility problem | Proposed change / dependencies / risk | Acceptance criteria | Status |
|---|---|---|---|---|---|---|---|
| Launch | شعار وانتظار ثم branching | onboarding يسبق auth ولا يراعي profile completion بعد التسجيل | لحظة bootstrap لا تشرح الحالة عند البطء | لا وصف غني لحالة الاستعادة | الحفاظ على bootstrap، فصل auth عن onboarding الشخصي؛ يعتمد auth/profile state؛ خطر redirect loop | مسار session واحد قابل للاختبار ولا loop | Planned |
| Onboarding | 3 صفحات تسويقية + حقل نادي حر غير محفوظ | لا display name/username/avatar/league/club | لا Player 11 ولا progress حقيقي | الحقول والاختيار غير مكتملين للـsemantics | رحلة خطوات محفوظة، بعد auth، مع Skip للدوري/النادي؛ يعتمد profile/football repos | استئناف progress، validation، RTL/text scale | Planned |
| Auth | form + providers | جيد وظيفيًا؛ يجب ألا يختفي Google عند release config | هوية app أكثر من game | رسائل الأخطاء تحتاج إعلانًا واضحًا | صقل typography فقط، بلا تغيير auth contract | email/Google config يبقيان، لا secrets جديدة | Planned |
| Home | header + hero + formats/team/categories/rank cards | CTA يبدأ `/solo` بدل Play Hub، وأوزان الأقسام متقاربة | أقرب dashboard من game hub | CTA قد يهبط مع text scale | CTA `العب الحين` إلى `/play`، preview game types ثم challenge/team/categories/rank؛ يعتمد content states | CTA فوق الطي على 360×800، حالات offline/loading/error | Planned |
| Play | أربع tiles: bot/1v1/2v2/room | يخلط Game Format مع Game Type | cards متشابهة بلا هوية mode | layout لا يتبدل صراحة عند large text | hub بعنوان `وش ودك تلعب؟`، types أولًا وformats داخل setup؛ feature flags للمودات الناقصة | enabled/coming-soon صريح، لا route مكسور | Planned |
| Categories | قائمة content categories | جزء من setup وليس destination رئيسيًا | content list أكثر من game selection | فحص long names/text scale | إعادة استخدامه picker داخل setup مع route القديم | اختيار واضح وعودة آمنة | Planned |
| Solo setup | category/difficulty/question count | هذا Practice محلي، لا session تنافسية | setup منفصل عن types | وصف authority غير بارز | إعادة تسميته Practice غير مصنف، بلا rewards؛ لا تغيير منطق التمرين | لا ادعاء coins/rank/server authority | Planned |
| Practice question | Flutter timer + local correct answer/scoring | `correctOptionIndex` مخزن محليًا ويحسب النتيجة على العميل | بلا Flame stage | lifecycle لا يراقب background؛ timer wall clock | يبقى Practice فقط؛ shared visual components ممكنة دون خلطه بالcompetitive | banner غير مصنف، لا reward، timer lifecycle موثق | Planned |
| Practice results | score/accuracy/training disclaimer | لا XP/coins/rank وهذا صحيح لمسار التدريب | لا Player 11/static state | stats تحتاج semantics grouping | صقل النتيجة مع إبقاء disclaimer وعدم اختلاق rewards | القيم محلية موسومة Practice بوضوح | Planned |
| Online lobby | matchmaking + current format | type غير ممثل | lobby أقرب form/cards | ready/connection states تحتاج cues غير اللون | صقل slots وPlayer 11 وnetwork status لاحقًا؛ server decides completeness | لا client-side completion/result | Planned |
| Online match | سؤال آمن نسبيًا + poll/RPC submit/reveal/advance | logic/timers داخل Widget، لا controller أو idempotency key/server offset | لا Flame vertical slice | reconnect/background ناقصان | Controller مستقل + Flame stage + Flutter overlay؛ يعتمد contract backend v2 | double tap واحد، stale guarded، resume authoritative | Planned |
| Room lobby | code/join state | لا game type/setup موحد | lobby بصري تقليدي | code directionality/focus | إبقاء contract وصقل composition بعد vertical slice | room code واضح في RTL، retry works | Planned |
| Ranking | list + current metrics | مكان المستخدم والـtop 3 ليسا دائمًا بارزين | لا podium/MVP game feel | لا يعتمد الترتيب على اللون فقط جزئيًا | podium أصلي + pinned self row؛ يعتمد current leaderboard repo | ranking number/text/icon cues | Planned |
| Store | wallet/products | ليس tab رئيسيًا | كثافة cards | purchase state/error semantics تحتاج manual QA | يبقى route ثانوي داخل profile؛ لا تغيير economy | لا pay-to-win، لا interstitial أثناء سؤال | Planned |
| Profile | stadium poster + profile sections | الإحصاءات والهوية متقاربة الوزن | Player 11 صورة poster وليست mascot states | hero كبير قد يزاحم content/text scale | player card: mascot/name/level/XP ثم football identity ثم performance/content | لا overflow، assets آمنة، settings/store reachable | Planned |
| Friends | contacts/invites | يحتاج CTA challenge وteam context | أقرب contacts app | actions/empty states تحتاج labels | تسمية «ربعك» مع level/team/challenge CTA | empty/error/loading قابلة للفهم | Planned |
| Football preferences | league chips + club rows | ليست game tiles/grid ولا normalization/aliases متكاملين | badge/logo path قد يعرض URL دون visual-right gate محلي | اختيار/search needs semantics | league tiles + searchable 2–3-column club grid + procedural fallback | عربي/English search، no unlicensed logo | Planned |
| Social hub | team/activities | مناسب كأساس tab الاستراحة | ما زال cards، Player 11 poster | hierarchy كبيرة للشاشة الصغيرة | banner/team/challenge/MVP/friends ordering | team/challenge state honest | Planned |
| Team | members/challenges/moderation | جيد وظيفيًا | badge/slots تحتاج game identity | role/status cues ليست لونًا فقط | procedural badge + player slots، مع إبقاء permissions | server membership/roles unchanged | Planned |
| Team challenge | server-backed Q&A | authority جيدة لكن no idempotency/retrieve previous verdict | لا shared game stage | reconnect/retry race | لا تفعيله كـnew mode قبل contract idempotent | stale/replay rejected، resume known | Planned |
| Blocked players | privacy list | ثانوي وصحيح | لا يحتاج gameification | confirm/focus/manual QA | cleanup visual فقط | unblock confirm and error states | Planned |
| Settings | cards تبدأ بالمظهر | لا grouped hierarchy/header/football/game tips/SFX | كل setting يبدو card | promotions null/default bug؛ controls labels | grouped lists + header + danger zone آخرًا؛ إصلاح default | reduced motion/haptics/theme persist; promotions off default | Planned |
| Notifications | inbox | وظيفة ثانوية | list عادية مقبولة | unread semantics/deep links | token-level polish فقط | deep link allowlist remains safe | Planned |
| Report problem | form | جيد وظيفيًا | لا يحتاج gameification | error/success announcements | الحفاظ على formal Arabic/security | no sensitive payload/logging | Planned |

## Design system الحالي

- موجود: semantic `AhdashColors` light/dark، spacing tokens 4/8/12/16/20/24/32/40/48، radius، motion، opacity/blur/elevation.
- الفجوات: لا `AppTypography` صريح بخطوط محلية، لا `AppGameTheme` أو Flame adapter، وبعض durations أطول من motion brief، واستخدام fonts fallback فقط.
- palette الأساسية موجودة (`#0B0F14`, `#131922`, `#B6FF3B`, `#F7F9FB`, `#8E98A7`, `#FFC857`) وتحتاج supporting tones وأدوار `dangerTimer`, `teamA`, `teamB`, `focus` بدل hex في widgets.
- المخاطرة: إنشاء نظام موازٍ؛ القرار هو تطوير الملفات الحالية لا نسخها.

## Gameplay وserver authority

### Practice الحالي

`get_solo_question_pack` يعيد `correct_option_index`، و`QuizQuestion` يحمله، و`SoloMatchController` يحسب correctness/score محليًا ويحفظ pack في Drift. هذا مسموح فقط كـPractice غير مصنف وبلا rewards، وهو ما تقوله نتائج التدريب حاليًا. لا يجوز استعماله لتحدي/ترتيب/coins/XP.

### Online الحالي

`start_solo_match`/match payload الآمن + `submit-answer` + `reveal_match_question` + `advance_match` أفضل أساس موجود: source IDs والإجابة الخاصة غير معروضة قبل reveal، وتوجد unique answer ownership checks. الفجوات: لا `idempotency_key`, `client_sequence`, `server_now` offset، recovery لرد سابق، أو Controller مستقل. Polling وwall-clock display داخل الشاشة.

### ثغرة تعاقدية حرجة

الأسئلة المنشورة وخياراتها قابلة للقراءة للمستخدم المصادق، وoffline solo pack يعيد المفتاح. ويمكن لـTeam Challenge اختيار pool `solo`. يمكن إذن مطابقة نص السؤال التنافسي بمخزن التدريب واستخراج جوابه. الحل يجب أن يعزل competitive pools أو يغلق المفتاح عن الأسئلة التنافسية في migration جديدة؛ لا يكفي إخفاؤه في Flutter.

### Backend inventory

- 14 migrations، آخرها الاجتماعية المطبقة والـimmutable.
- 11 Edge Functions: matchmaking/room/submit-answer/import/wallet/ads/revenuecat/notifications/delete-account.
- 4 pgTAP security suites.
- Online rewards النهائية server-authoritative مع row locks وwallet ledger idempotency؛ Team Challenge scoring server-side لكن submission recovery/idempotency ناقصان.
- question schema يعبّر حاليًا عن `text|image` ويفرض 4 options؛ لا game types/payload contracts/media rights للصور العامة.

## Admin audit

- `/questions` table + bulk status، وليس محرر type-aware أو preview.
- import pipeline يدعم 4-option MCQ فقط، ويوجد mismatch بين `multiple_choice` في parser و`text|image` في DB validator.
- football data manager يدعم `fallback|custom|licensed` وlicense reference validation.
- `media_assets` و`questions.image_url` بلا rights/provenance/expiry enforceable؛ publish لا يمنع media unknown-rights.
- المطلوب لاحقًا: editor/preview/validation حسب type، مع private payload server-only. لا يُفعّل mode إنتاجيًا قبل هذا.

## Assets inventory

| المجموعة | الملفات | الحجم |
|---|---:|---:|
| Branding | 7 | 4,482,926 bytes تقريبًا |
| Visuals | 4 | 6,756,233 bytes تقريبًا |
| الإجمالي | 11 | 11,239,159 bytes / 10.72 MiB |

الصور الكبيرة تفك إلى نحو 6MiB لكل صورة في الذاكرة. ملفات غير مستخدمة runtime لكنها packaged تشمل brand guidelines وبعض wordmarks و`ASSET_MAP.txt`. صورة Player 11 الحالية poster/photorealistic ولا تحقق mascot/state requirement. لا fonts/audio/rive/svg/webp حاليًا.

## Dependencies الحالية ذات الصلة

Flutter/Riverpod/go_router/Supabase/Firebase/Drift موجودة. Flame و`flame_test` غير موجودتين. لا حاجة حاليًا إلى Rive، Spine، `flame_audio`, Forge2D أو Tiled. قرار الإضافة المبدئي: Flame فقط بسبب vertical slice فعلي، مع version يحافظ على SDK lower bound؛ Rive مؤجل حتى وجود `.riv` مرخص وstate machine.

## المخاطر المرتبة

1. **P0 Security:** leakage عبر offline question pack والمطابقة النصية مع الأسئلة التنافسية.
2. **P0 Integrity:** غياب idempotency key/sequence/recovery للـonline submissions.
3. **P0 Product:** الأنواع المطلوبة غير موجودة في schema/admin/session contract.
4. **P0 Lifecycle:** timers/polling داخل Widgets ولا server clock offset أو resume coordinator.
5. **P0 Accessibility:** لا local typography hierarchy، وPlayer 11/Flame canvas يجب ألا يحمل النص العربي الطويل.
6. **P1 Rights:** media questions بلا rights enforcement، وlogo URLs تحتاج gate.
7. **P1 Size/memory:** PNGs كبيرة وpackaged assets غير مستخدمة.

## قرار المرحلة

- Classic التنافسي سيُبنى فوق online match contract بعد تقويته؛ practice المحلي يبقى منفصلًا وصريحًا.
- True/False وSpeed لا يمكن وصفهما `Completed` قبل schema/admin/session/server validation والاختبارات؛ يوضعان خلف feature flags حتى ذلك.
- Flutter مسؤول عن النص/الأزرار/semantics، Flame عن المسرح البصري والمؤثرات فقط.
- لا Rive claim دون `.riv` فعلي، ولا club crest دون `licensed/custom` rights.
