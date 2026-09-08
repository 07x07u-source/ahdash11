# أحدعش | 11 — تدقيق وإزالة واجهات الاتجاه القديم

تاريخ التدقيق: 2026-08-31. هذا التصنيف يغطي كل شاشات Flutter العامة الموجودة وقت بدء Party Game V2. إزالة العنصر من المسار العام لا تعني حذف backend أو إسقاط جدول.

## ملخص القرار

- التجربة الأساسية الوحيدة الظاهرة من Home هي: Home → Categories → Teams → Helpers → Ready → Board → Question → Reveal → Result.
- لا NavigationRail دائم داخل Home أو Party.
- Classic وTrue/False وSpeed وOrdering وClub Guess وEagle Eye لا تُعرض كألعاب رئيسية؛ يبقى منطقها المفيد وصيغها خلف المسار القديم.
- 1v1 و2v2 وRooms وSocial وRanking تبقى شيفرتها وواجهاتها وbackend محفوظة، لكنها ليست جزءًا من Home أو Party V2.
- `/wallet` يبقى redirect إلى Premium ولا تظهر Coins أو Wallet أو coin rewards في التجربة الأساسية.

## تصنيف الشاشات

| الشاشة / المسار | القرار | الظهور في Party V2 | ملاحظة |
|---|---|---|---|
| Launch | KEEP | قبل الدخول فقط | bootstrap واتجاه الشاشة محفوظان |
| Onboarding | SIMPLIFY لاحقًا | قبل Home فقط | لا يكرر Player 11 داخل Party |
| Auth | KEEP | عند الحاجة للحساب | Party المحلية لا تجعل الحساب جدارًا بصريًا |
| Home | REDESIGN | Primary | إزالة dashboard panels والـXP/social/online links |
| Party Categories | REDESIGN | Primary | gallery محتوى، اختيار 6، search/latest/favorites/random/trial |
| Party Teams | REDESIGN | Primary | composition واحد، لا Team A/Team B panels |
| Team Splitter | REDESIGN | Modal/Sheet | chips وصفوف خفيفة، لا Card لكل لاعب |
| Party Helpers | REDESIGN | Primary | tokens وأداة واحدة موصوفة، لا panel لكل فريق |
| Party Ready | REDESIGN | Primary | أسماء/chips/icons فقط |
| Party Board | REDESIGN | Primary | scoreboard واحد متصل؛ الشبكة هي الاستثناء الطبيعي |
| Party Question | REDESIGN | Primary | السؤال مباشرة على Canvas بلا giant card |
| Party Reveal | REDESIGN | Primary | reveal داخل نفس اللغة البصرية مع award targets بسيطة |
| Party Result | REDESIGN | Primary | فائز واحد واضح وحركة احتفال خفيفة |
| How to Play | REDESIGN | Secondary visible | أربع مشاهد متتابعة بلا أربع cards متساوية |
| My Games | SIMPLIFY | Secondary visible | الجولة الحالية والسجل بلا dashboard |
| Premium | SIMPLIFY | Secondary | اشتراك شهري/سنوي؛ لا Hero panel ولا pay-per-game |
| Profile | KEEP | Secondary | الحساب وPlayer 11/cosmetics فقط |
| Settings | KEEP | Secondary | theme/sound/haptics/reduced motion/support |
| Notifications | KEEP | Secondary | لا تظهر widget منها في Home |
| Problem report | KEEP | Secondary | بلاغ السؤال يُطلق من Question/Reveal |
| Legacy Categories | HIDE | غير ظاهر | المسار محفوظ للتوافق فقط |
| Play Hub | HIDE | غير ظاهر | بوابة الاتجاه القديم؛ لا link في Home |
| Legacy Game Setup | HIDE | غير ظاهر | المنطق محفوظ ولا يعرض كألعاب مستقلة |
| Solo Setup/Question/Result | HIDE | غير ظاهر | backend/engine محفوظان |
| Online Lobby/Match/Room | HIDE | غير ظاهر | 1v1/2v2/Rooms محفوظة تقنيًا |
| Ranking | HIDE | غير ظاهر | لا rank قبل بدء اللعبة |
| Football Preferences | HIDE | غير ظاهر | تبقى في الحساب عند الحاجة |
| Friends | HIDE | غير ظاهر | Social backend محفوظ |
| Social Hub/Team/Challenge/Blocked | HIDE | غير ظاهر | ليست ضمن core party flow |
| Store/Wallet legacy | REMOVE FROM PRIMARY / REDIRECT | غير ظاهر | `/wallet` → `/store`/Premium؛ لا Coins UX |

## ما حُذف فعليًا وما بقي

### Removed from public UI

- Home dashboard modules، روابط اللعب المتصل، الأقسام القديمة، XP/Rank/Leaderboard/Social/Coins/Wallet.
- أي side dock من المسار الأساسي.
- عرض game formats كأنها ألعاب رئيسية مستقلة.

### Hidden / secondary

- Online، غرف، 1v1، 2v2، Social، Ranking، Football preferences، وإشعارات الحساب.
- Premium والحساب والإعدادات تبقى actions صغيرة أو ثانوية.

### Backend preserved

- Supabase tables/RLS/RPCs الخاصة بالمباريات والغرف والأصدقاء والفرق الاجتماعية والترتيب والمحفظة القديمة.
- match engines وonline gateways والـroutes اللازمة للتوافق/deep links.
- RevenueCat وGoogle Sign-In وFirebase/FCM/Crashlytics.

### Actually deleted

- لا database table حُذفت.
- لا engine مفيد حُذف.
- يحذف فقط dead presentation code أو assets بعد إثبات عدم وجود أي reference، ويُسجل ذلك في تقرير الإصدار النهائي.
