# المعمارية

## حدود النظام

يتكون أحدعش من ثلاثة تطبيقات مستقلة بعقود مشتركة:

1. **Flutter mobile** يعرض التجربة ويحتفظ بكاش محلي، لكنه لا يملك سلطة النتيجة أو العملات أو التصنيف.
2. **Next.js admin** يدير المحتوى والاستيراد والمراجعة، ويعمل بمفتاح anon وجلسة المشرف. العمليات ذات الصلاحية المرتفعة تمر عبر RLS/Functions.
3. **Supabase** هو مصدر الحقيقة: Auth وPostgreSQL وStorage وRealtime وEdge Functions/RPC.

```text
Mobile/Admin
   │ JWT + anon key
   ▼
Supabase API ── RLS ── PostgreSQL
   │              │
   ├─ Realtime    ├─ authoritative match state
   ├─ Storage     ├─ wallet ledger
   ├─ Functions   ├─ question history / ranking
   └─ Providers   └─ FCM / RevenueCat / verified AdMob SSV
```

## تطبيق Flutter

البنية feature-first:

```text
lib/
├── app.dart             MaterialApp and global RTL setup
├── core/                bootstrap, routing, config, services, theme, local DB
├── shared/              reusable UI and models
└── features/
    └── feature_name/
        ├── data/         DTOs, repositories, data sources
        ├── domain/       entities and pure business rules
        └── presentation/ Riverpod controllers and widgets
```

- Riverpod يعزل dependencies ويسمح باستبدال Supabase بمخزن development.
- go_router ينسق التنقل وdeep links، بينما تتحقق كل عملية حساسة مجددًا عبر JWT وRLS/RPC.
- Drift/SQLite يخزن categories وحزم الأسئلة الفردية والتاريخ المحلي والإعدادات.
- online ranked لا يعمل دون اتصال ولا يحسب النتائج محليًا.
- localization عربية أولًا وواجهة التطبيق RTL، مع مفاتيح قابلة لإضافة الإنجليزية.

## دورة السؤال الفردي

1. يطلب الـrepository حزمة أسئلة متوازنة وفق الأقسام والصعوبة والتاريخ.
2. تُحفظ الحزمة محليًا للوضع الفردي فقط.
3. يقود `MatchController` آلة الحالة created → lobby → ready → countdown → question → answersLocked → result → nextQuestion → finished.
4. يحسب محرك النتيجة الفردي preview فوريًا ويسجل تاريخ السؤال عند الاتصال. هذا وضع تدريب Offline ولا يمنح عملات أو تصنيفًا دائمًا.
5. كل نتيجة wallet تتم كقيد ledger ذري، لا كتعديل رصيد من العميل.

## دورة السؤال عبر الشبكة

```text
server creates match + selects question ids
  → client receives text/options/media/deadline only
  → client submits match_question_id + selected_option_id
  → server uses received_at and validates membership/deadline/idempotency
  → server stores score + returns reveal payload after lock
```

لا تحتوي DTO التي تصل قبل الإغلاق على `is_correct` أو `correct_option_id`. Realtime ينقل الحالة والنتيجة المصرح بها فقط. إعادة الاتصال تجلب snapshot من قاعدة البيانات بدل إعادة تشغيل مؤقت الهاتف.

## التوسع

`match_mode` وعضوية الفريق و`team` وsettings data-driven تسمح بإضافة 3v3 والبطولات دون تغيير شكل السؤال. وظيفة اختيار السؤال تقبل عدد الأقسام وعدد الأسئلة، وتحتفظ بقيود التنوع والتاريخ في طبقة مستقلة.

## Observability

- أخطاء domain تتحول إلى رسائل عربية آمنة للمستخدم.
- الأخطاء غير المتوقعة ترسل إلى Crashlytics بعد إزالة البيانات الحساسة.
- Analytics events تحمل IDs تقنية وخصائص مجمّعة، لا نص السؤال أو البريد أو الاسم.
- Functions تسجل request ID وuser ID وoperation type، ولا تسجل JWT أو secrets.
- RevenueCat لا يكتب حالة الاشتراك مباشرة؛ Webhook موثّق يمر عبر RPC يرفض الأحداث الأقدم.
- مكافآت AdMob تُقيد مرة واحدة بمعرّف transaction بعد تحقق توقيع Google، وإرسال FCM يسجل نتيجة كل جهاز دون كشف token في السجلات العامة.
