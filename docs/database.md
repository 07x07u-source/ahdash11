# قاعدة البيانات

المهاجرات في `supabase/migrations` هي مصدر الحقيقة. جميع جداول المجال تستخدم UUID، مفاتيح أجنبية، قيودًا صريحة، `created_at` و`updated_at` حيث يلزم، وفهارس لمسارات القراءة الساخنة.

## المجالات

- **Identity:** `profiles`, `device_tokens`, notification preferences.
- **Content:** `categories` ذات parent، `questions`, `question_options`, `tags`, `question_tags`, `question_history`, `question_reports`.
- **Matches:** `matches`, `match_players`, `match_questions`, `match_answers`, `rooms`, `room_members`.
- **Social:** `friend_requests`, `friends`.
- **Progress:** `seasons`, `player_season_stats`, profile XP/rating/stats.
- **Economy:** `wallets`, append-only `wallet_transactions`, `store_items`, `user_inventory`, `subscriptions`.
- **Operations:** `import_batches`, `import_rows`, `game_settings`, notifications, `notification_deliveries`, `ad_reward_claims`.

## قواعد مهمة

- كل سؤال منشور يملك أربعة خيارات بالضبط، لكن هذا invariant يُفحص عند النشر/الاستيراد لأن PostgreSQL لا يستطيع فرض عدد أبناء بــCHECK بسيط.
- صف الإجابة الصحيحة محمي عن المستخدم العادي. عرض/دالة منفصلة تعيد الخيارات من دون `is_correct` للمباراة online.
- `match_answers` فريد على `(match_question_id, match_player_id)` لتحقيق idempotency.
- `wallet_transactions` append-only؛ الرصيد يتغير داخل transaction/function محمية بقيد يمنع الرصيد السالب.
- علاقات الصداقة canonical بحيث يكون UUID الأصغر في `user_a_id` لتفادي التكرار العكسي.
- device token فريد ويمكن تعطيله من دون حذفه للحفاظ على trace تشغيلي محدود.

## الصلاحيات

الدور محفوظ في `profiles.role` كـ enum: user/moderator/admin/super_admin. helper functions تستخدم `auth.uid()` و`security definer` مع `search_path` ثابت. سياسات RLS تفصل:

- القراءة العامة للمحتوى المنشور غير الحساس.
- المالك لبياناته الخاصة.
- المشاركون لبيانات المباراة المسموح بها.
- moderator لمراجعة المحتوى والبلاغات.
- admin لإدارة المستخدمين والإعدادات والمتجر.
- super_admin لإدارة الأدوار الحساسة.

service-role يستخدم فقط في CI/Functions ولا يصل إلى Next.js client أو Flutter.

## اختيار السؤال

تؤخر الدالة الأسئلة الحديثة في `question_history`، ثم توازن الأقسام والصعوبة وتقلل تكرار `club/player`. الاختيار العشوائي محصور في مجموعة الأسئلة المنشورة المؤهلة؛ عند نمو البنك إلى حجم كبير يجب استبداله بعينات مفهرسة/مسبقة التقسيم ومراقبة خطة الاستعلام.

## صعوبة تكيفية

لا تعاد التقييمات قبل `difficulty_min_sample_size` من الإعدادات. بعد ذلك تستخدم نسبة الإجابات الصحيحة مع hysteresis لتجنب التذبذب: مرتفع جدًا قد يخفض درجة واحدة، ومنخفض جدًا قد يرفع درجة واحدة، ضمن easy…expert. تُسجل الأرقام الخام دائمًا.
