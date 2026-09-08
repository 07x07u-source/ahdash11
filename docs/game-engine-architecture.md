# معمارية محرك لعبة أحدعش | 11

الحالة: Decision baseline — 2026-08-28.  
الهدف: فصل authority والمنطق عن العرض، مع إبقاء النص العربي وaccessibility في Flutter واستخدام Flame استعمالًا حقيقيًا ومحدودًا.

## حدود الطبقات

```text
Flutter shell / Flutter gameplay overlays
        │ user intents + view state
        ▼
GameSessionController (Application)
        │ domain requests/results
        ▼
GameSessionGateway / Supabase Edge + RPC
        │ authoritative validation/rewards
        ▼
PostgreSQL + RLS + ledgers

GameSessionController ──visual cues──> AhdashGame (Flame)
```

## دور Flutter

- app shell، navigation، auth، onboarding، profile، social، store، settings.
- السؤال العربي الطويل، answer buttons، semantics، focus، text scale، RTL/mixed-direction، dialogs.
- loading/offline/error/reconnect overlays.
- يستقبل `GameViewState` ولا يحسب صحة الإجابة أو reward.

## دور Flame

- gameplay stage/background energy.
- non-text HUD accents، timer danger visualization، transitions.
- bounded particles/effects/camera cue عند correct/wrong/win عندما Reduced Motion غير مفعّل.
- لا network calls، لا scoring، لا correct answer، لا wallet/XP/rank.

`GameWidget` يبقى instance مستقرًا داخل الشاشة مع `RepaintBoundary`. لا يعاد إنشاؤه لكل tick. Flutter overlay يوضع في `Stack` فوقه أو عبر overlay builder، مع clipping صريح عند الحاجة.

## Domain

### GameType

`classic`, `trueFalse`, `speed`, ثم مستقبلًا `ordering`, `clubGuess`, `eagleEye`.

### GameFormat

`practice`, `solo`, `oneVsOne`, `twoVsTwo`, `teamChallenge`, `dailyChallenge`, `quickPlay`.

Game Type renderer منفصل عن Format rules؛ لا class لكل combination.

### Game session state

```text
bootstrapping
countdown
presentingQuestion
acceptingInput
lockingInput
submittingAnswer
revealingVerdict
transitioning
paused
reconnecting
completed
failed
```

قواعد invariant:

1. intent answer مقبول فقط في `acceptingInput`.
2. أول intent ينتقل فورًا إلى `lockingInput` قبل أي await.
3. submission يحمل idempotency key ثابتًا للمحاولة و`client_sequence` متزايدًا.
4. response يجب أن يطابق session/question/sequence الحالي؛ stale response يهمل.
5. correctness لا يظهر قبل server verdict.
6. timeout/retry/resume لا تمنح reward محليًا ولا تعيد الإرسال بمفتاح جديد.

## GameSessionController

مسؤول عن orchestration فقط:

- bootstrap/recover session عبر gateway.
- تحويل server envelope إلى immutable `GameViewState`.
- input lock، submission، retry بنفس idempotency key.
- server clock offset وdeadline.
- lifecycle intents: background/resume/reconnect/dispose.
- إصدار visual cues غير authoritative إلى Flame بعد رد الخادم.
- إلغاء timers/subscriptions/polls عند dispose.

لا يعتمد على `BuildContext`, Widget، أو Flame Component. يمكن اختباره بـfake gateway وfake clock.

## GameClock

واجهة قابلة للحقن تعيد monotonic/client time. عند وصول `server_now` تحسب offset، والوقت المتبقي:

```text
remaining = expires_at - (client_now + server_offset)
```

- online/multiplayer server deadline لا يتوقف عند background.
- local pause يوقف rendering/audio فقط، ثم resume يجلب authoritative state.
- Practice يمكنه pause محليًا لأنه غير مصنف، لكن لا يختلط مع competitive result.
- frame `dt` يستخدم للحركة فقط، لا authority timer.

## Infrastructure contracts

### Start / recover

يجب أن يعيد: session/question IDs، `game_type`, public payload، `started_at`, `expires_at`, `server_now`, round/format state. لا answer key.

### Submit

Request: IDs، public answer payload، elapsed display metric، idempotency key، client sequence.  
Response: accepted/verdict/server score/correct public reveal بعد submission/next state/server now.

### Finish

server result فقط: score/accuracy/speed/streak/XP/coins/rank/team contribution، مع pending state عند عدم اكتمال ledger.

## الواقع المنفذ وخطة التوافق

- Practice RPC يعيد `correct_option_index` ويُخزن محليًا؛ يبقى unranked/no rewards.
- Online match flow يخفي answer قبل reveal ويحسب score server-side؛ هو أساس Classic.
- migration المحلية `20260828000400_gameplay_contract_v2.sql` تضيف idempotency/sequence/server_now، timeout rows الصحيحة، competitive-pool isolation وgame-type payloads من دون تعديل migration مطبقة.
- `submit-answer`, `queue-matchmaking`, و`create-room` تدعم العقود الجديدة، ولا تسجل answer/private payload. لم تُدفع migration أو Edge Functions إلى Remote.
- Team Challenge يملك submission v2 بإيصال مخزن وإعادة آمنة، وساعة خادم للاستئناف؛ Flutter يمنع تبديل الإجابة بعد نتيجة شبكة مجهولة.

## Flutter/Flame visual adapter

`AppGameTheme` يحوي قيمًا framework-agnostic قدر الإمكان: colors، durations، effect density، reduced-motion flag. `FlameGameThemeAdapter` يحول `Color`/tokens إلى paints/config للمكونات. لا تستورد presentation Widgets داخل domain/application.

## Question presenters

- Classic: 4 answers، 2×2 عند النص القصير والمساحة الكافية، وإلا vertical.
- True/False: زران، pool محتوى مستقل، 10 ثوانٍ من الخادم، ونفس submission pipeline.
- Speed: يعيد استخدام Classic presenter مع 7 ثوانٍ من الخادم وفصل matchmaking. لا يوجد combo server contract، لذلك لا يُدّعى وجوده.
- Ordering/Club Guess/Eagle Eye تبقى feature-flagged حتى وجود payload/admin/rights/validation كامل.

## Player 11

Static generated-safe male/female foundation أولًا. states يمكن تمثيلها بأصول/poses ثابتة وانتقالات Flutter/Flame محدودة. Rive مؤجل لأن `.riv` وstate machine غير موجودين؛ لا dependency حتى توفر artifact فعلي.

## Audio وhaptics

- لا `flame_audio` حاليًا لغياب sound pack مرخص.
- feedback يستعمل SystemSound/Haptics الحالية، محكومًا بإعدادات user/reduced motion.
- لا music toggle بلا music asset.

## Particles/shaders/camera

- particles procedural قصيرة فقط: correct/combo/victory/rank/MVP.
- reduced motion = no particles ولا shake/zoom كبير.
- لا shader في P0؛ لا قيمة مبررة أمام كلفة profiling.
- tiny wrong shake وsmall victory zoom فقط بعد real-device QA.

## Tiled وForge2D

- Tiled: not required for current game modes.
- Forge2D: not needed for current release.
- لا physics لتقرير coins/XP حتى في mini-game مستقبلية؛ server يبقى authority.

## Lifecycle

| event | controller | Flame | Flutter overlay |
|---|---|---|---|
| background | يوقف local scheduling ويحفظ attempt metadata | pause visual loop/effects | يعرض state محفوظ بلا claim |
| resume | recover authoritative session | resync cue بعد recovery | reconnect/loading ثم latest state |
| network loss | `reconnecting`، لا key جديد | ambient منخفض/متوقف | banner + retry semantics |
| screen dispose | cancel all, ignore late responses | `dispose/onRemove`, remove children/effects | remove observers/listeners |
| expired question | server decides | timeout cue بعد response/recovery | input locked، no repeat submission |

## Security boundaries

- Flutter/Flame لا يقرآن private answer payload.
- RLS/Edge يتحقق من ownership/membership/stale state.
- unique/idempotency guards تمنع duplicate rewards؛ key يجب أن يكون bound إلى payload.
- timeout rows يجب أن تدخل زمنًا كاملًا كي لا يفوز non-answer tie-break بزمن صفر.
- room settings تُطبّع server-side؛ custom/short rooms غير ranked/reward-eligible افتراضيًا.
- rate limit لا يعتمد على counter يrollback مع exception؛ يطبق عند Edge/gateway أو structured non-rollback design.

## Testing strategy

- Pure Dart: state machine, clock offset/deadline, double tap, idempotent retry, stale response, reconnect, completion.
- Widget: Arabic long text, 360×800، text scale 1.6/2.0، RTL/mixed numbers، semantics، reduced motion.
- Flame: mount/update/cue/remove/dispose، zero effects under reduced motion.
- SQL: parser + pgTAP contracts for leak/idempotency/timeout/fairness/reward eligibility/RLS/search_path.
- Edge: Deno check and request mapping tests، no sensitive logs.

## Performance policy

- preload only current-stage procedural/compact assets.
- no 4K textures، use decode size/cacheWidth.
- GameWidget stable; no full rebuild per timer tick.
- bounded effects self-remove.
- static/profile-oriented optimization can be completed locally؛ real-device frame measurement remains manual QA.

## Party host-mode engine (2026-08-30)

Party لعبة محلية غير مصنفة ومقصودة لجهاز مضيف واحد؛ لذلك تفصل عن authority الخاصة بـ1v1/2v2، لكنها تعيد استخدام كتالوج `questions` نفسه بحد أمان واضح:

```text
PartyCatalogProvider
  ├─ answer-free category health RPC
  ├─ offline-safe, non-competitive Party pack RPC
  └─ validated local Party cache / bundled fallback
             ↓
PartyGameEngine → immutable 6×6 Session Snapshot
             ↓
PartyGameController → choose / helper / reveal / score / undo / persist
             ↓
Board + renderer + result/tie-breaker
```

- `PartyGameEngine` وحده يفرض 6 أقسام، 36 ID فريدًا، 2/2/2، الملكية 3+3، وأهلية Classic/True-False.
- `PartyHelpEngine` يمنع التوقيت الخاطئ، double-use، والمساعدة غير المختارة؛ `PartyScoreEngine` يعيد deltas قابلة للعكس.
- Session Snapshot يضم السؤال/الإجابة لأن Host mode مصنف صراحة offline-safe، ويضم تعريفات المساعدات والمؤقت والسجل. لا يدخل هذا المسار أي Competitive answer key.
- الـRPC الأولي يمكن أن يكون محدودًا، لكن Start يعيد جلب الحزمة للأقسام الستة تحديدًا؛ لذلك لا يجعل حجم الكتالوج العالمي أقسامًا جاهزة تبدو ناقصة.
- حالة الاستئناف تُقرأ محليًا أولًا، ثم تدمج المفضلة البعيدة بمهلة محدودة؛ فشل الشبكة لا يحجب الجولة المحفوظة.
- سؤال التعادل يُختار احتياطيًا من سؤال مؤهل غير مستخدم ولا يُضاف إلى بلاطات 6×6، ويظهر فقط عند التعادل وتفعيل Remote Config.
