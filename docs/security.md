# نموذج الأمان

## حدود الثقة

الهاتف والمتصفح والوقت القادم منهما غير موثوقة. Supabase Auth يثبت الهوية، وRLS يحدد الصفوف، وRPC/Edge Functions تحسب النتائج والتقييم والعملات وتتحقق من idempotency والوقت باستخدام الخادم.

## المباريات

- قبل lock: payload يحتوي السؤال والخيارات والوسائط والموعد فقط.
- الإجابة تسجل مرة واحدة مع server timestamp.
- score = base + bounded speed bonus من deadline/start server timestamps.
- نتيجة السؤال لا تظهر إلا عند lock أو بعد إجابة كل المشاركين وفق الوضع.
- reconnect يجلب state الحالي؛ لا يقبل العميل الانتقال إلى حالة جديدة.
- rate limits على join/answer/import/account/social، مع idempotency keys وحماية replay حيث تنشأ آثار مالية أو تنافسية.

## الاقتصاد

لا توجد عملية `set balance`. كل تغيير يمر بدالة ledger مع reference/idempotency key. الدوال الشرائية تتحقق من السعر والمخزون والملكية في transaction واحدة. RevenueCat webhook يتحقق من Bearer secret ثم يحدّث entitlement دون السماح لحدث أقدم بالكتابة فوق الأحدث. AdMob rewarded لا يمنح العملات إلا بعد تحقق ECDSA من callback وtransaction فريد.

## الإدارة

- RLS وrole helpers هي الحماية الأساسية.
- moderator لا يغيّر الأدوار أو settings الحساسة.
- تغييرات المحتوى والاستيراد والban تحفظ actor/time/reason في audit metadata.
- يوصى بـMFA وsession timeout للمشرفين.

## الخصوصية والحذف

قلّل PII؛ لا تسجل البريد في analytics. حذف الحساب يلغي tokens والجلسات، يحذف/يجهّل profile والبيانات الاجتماعية، ويحتفظ فقط بالسجلات المالية/نزاهة المباراة المجهلة إذا اقتضى الالتزام القانوني. يجب توثيق مدة الاحتفاظ الفعلية في سياسة الخصوصية قبل النشر.
