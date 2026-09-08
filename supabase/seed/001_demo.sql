-- Idempotent, clearly fictional demo content. It intentionally creates no auth users.
insert into public.categories(slug, name_ar, name_en, description_ar, icon_key, keywords, sort_order)
values
  ('eagle-eye', 'عين الصقر', 'Eagle Eye', 'أسئلة بصرية وتعرّف.', 'eye', array['شعار','قميص','لون','عين الصقر'], 10),
  ('transfers', 'سوق الانتقالات', 'Transfer Market', 'مسيرات وانتقالات اللاعبين.', 'swap', array['انتقال','انتقل','مسيرة','النادي السابق'], 20),
  ('leagues', 'الدوريات والبطولات', 'Leagues & Tournaments', 'بطولات محلية وقارية وعالمية.', 'trophy', array['دوري','بطولة','كأس','دوري الأبطال'], 30),
  ('locker-room', 'غرفة الملابس', 'Locker Room', 'مدربون وأرقام وتشكيلات.', 'shirt', array['مدرب','رقم القميص','تشكيلة','غرفة الملابس'], 40),
  ('stadiums', 'الملاعب', 'Stadiums', 'أسماء الملاعب ومواقعها وسعاتها.', 'stadium', array['ملعب','مدرج','سعة','الملاعب'], 50),
  ('individual-awards', 'الجوائز الفردية', 'Individual Awards', 'جوائز وهدافون وإنجازات فردية.', 'medal', array['جائزة','هداف','الكرة الذهبية','الجوائز'], 60)
on conflict (slug) do update set
  name_ar = excluded.name_ar,
  name_en = excluded.name_en,
  description_ar = excluded.description_ar,
  icon_key = excluded.icon_key,
  keywords = excluded.keywords,
  sort_order = excluded.sort_order,
  is_active = true;

with children(parent_slug, slug, name_ar, name_en, keywords, sort_order) as (
  values
    ('eagle-eye', 'club-identification', 'التعرف على النادي', 'Club Identification', array['شعار','نادي'], 1),
    ('eagle-eye', 'player-identification', 'التعرف على اللاعب', 'Player Identification', array['لاعب','صورة'], 2),
    ('transfers', 'player-careers', 'مسيرات اللاعبين', 'Player Careers', array['مسيرة','انتقل'], 1),
    ('leagues', 'saudi-league', 'دوري روشن السعودي', 'Saudi Pro League', array['روشن','السعودي'], 1),
    ('leagues', 'premier-league', 'الدوري الإنجليزي', 'Premier League', array['الإنجليزي','premier'], 2),
    ('leagues', 'la-liga', 'الدوري الإسباني', 'La Liga', array['الإسباني','laliga'], 3),
    ('leagues', 'serie-a', 'الدوري الإيطالي', 'Serie A', array['الإيطالي','serie'], 4),
    ('leagues', 'bundesliga', 'الدوري الألماني', 'Bundesliga', array['الألماني','bundesliga'], 5),
    ('leagues', 'ligue-1', 'الدوري الفرنسي', 'Ligue 1', array['الفرنسي','ligue'], 6),
    ('leagues', 'champions-league', 'دوري أبطال أوروبا', 'Champions League', array['دوري الأبطال','أوروبا'], 7),
    ('leagues', 'world-cup', 'كأس العالم', 'World Cup', array['كأس العالم','المنتخب'], 8),
    ('leagues', 'euro', 'اليورو', 'EURO', array['اليورو','أوروبا'], 9),
    ('locker-room', 'coaches', 'المدربون', 'Coaches', array['مدرب','خطة'], 1),
    ('locker-room', 'shirt-numbers', 'أرقام القمصان', 'Shirt Numbers', array['رقم','قميص'], 2),
    ('stadiums', 'stadium-facts', 'معلومات الملاعب', 'Stadium Facts', array['ملعب','سعة','مدينة'], 1),
    ('individual-awards', 'award-history', 'سجل الجوائز', 'Award History', array['جائزة','فائز','هداف'], 1)
)
insert into public.categories(parent_id, slug, name_ar, name_en, keywords, sort_order)
select p.id, c.slug, c.name_ar, c.name_en, c.keywords, c.sort_order
from children c join public.categories p on p.slug = c.parent_slug
on conflict (slug) do update set
  parent_id = excluded.parent_id,
  name_ar = excluded.name_ar,
  name_en = excluded.name_en,
  keywords = excluded.keywords,
  sort_order = excluded.sort_order,
  is_active = true;

insert into public.tags(slug, name_ar, name_en)
values
  ('demo', 'محتوى تجريبي', 'Demo content'),
  ('clubs', 'أندية', 'Clubs'),
  ('players', 'لاعبون', 'Players'),
  ('transfers', 'انتقالات', 'Transfers'),
  ('stadiums', 'ملاعب', 'Stadiums'),
  ('awards', 'جوائز', 'Awards')
on conflict (slug) do update set name_ar = excluded.name_ar, name_en = excluded.name_en;

insert into public.system_opponents(slug, name_ar, difficulty_label, correct_probability, average_response_ms, response_jitter_ms)
values
  ('easy', 'المبتدئ', 'easy', 0.45, 10500, 2500),
  ('medium', 'المنافس', 'medium', 0.65, 8000, 1800),
  ('hard', 'الخبير', 'hard', 0.82, 5600, 1300),
  ('legend', 'الأسطورة', 'legend', 0.94, 3500, 900)
on conflict (slug) do update set
  name_ar = excluded.name_ar,
  correct_probability = excluded.correct_probability,
  average_response_ms = excluded.average_response_ms,
  response_jitter_ms = excluded.response_jitter_ms,
  is_active = true;

insert into public.game_settings(key, value, description_ar, is_public, validation)
values
  ('match.default_question_count', '15', 'عدد الأسئلة الافتراضي للمباراة', true, '{"type":"integer","min":1,"max":50}'),
  ('match.question_duration_ms', '15000', 'مدة السؤال بالمللي ثانية', true, '{"type":"integer","min":3000,"max":120000}'),
  ('scoring.base_score', '100', 'نقاط الإجابة الصحيحة', true, '{"type":"integer","min":0,"max":10000}'),
  ('scoring.max_speed_bonus', '50', 'أقصى مكافأة للسرعة', true, '{"type":"integer","min":0,"max":10000}'),
  ('questions.difficulty_min_sample', '50', 'أقل عينة لإعادة تقييم الصعوبة', false, '{"type":"integer","min":20,"max":10000}'),
  ('rewards.match_finish_xp', '50', 'نقاط الخبرة لإنهاء مباراة', true, '{"type":"integer","min":0,"max":10000}'),
  ('rewards.win_xp', '25', 'مكافأة خبرة الفوز', true, '{"type":"integer","min":0,"max":10000}'),
  ('rewards.match_finish_coins', '10', 'عملات إنهاء المباراة', true, '{"type":"integer","min":0,"max":10000}'),
  ('rewards.win_coins', '10', 'مكافأة عملات الفوز', true, '{"type":"integer","min":0,"max":10000}'),
  ('ads.interstitial_every_matches', '3', 'الحد الأدنى للمباريات بين الإعلانات', true, '{"type":"integer","min":1,"max":20}'),
  ('ads.rewarded_coins', '25', 'عملات الإعلان المكتمل بعد تحقق الخادم', true, '{"type":"integer","min":1,"max":10000}')
on conflict (key) do update set
  value = excluded.value,
  description_ar = excluded.description_ar,
  is_public = excluded.is_public,
  validation = excluded.validation;

insert into public.store_items(sku, type, name_ar, name_en, description_ar, price_coins, revenuecat_product_id, consumable, ranked_allowed, sort_order)
values
  ('hint-5050', 'hint', 'تلميح 50/50', '50/50 Hint', 'يزيل خيارين في الأنماط المسموحة.', 120, null, true, false, 10),
  ('hint-extra-time', 'hint', 'وقت إضافي', 'Extra Time', 'يضيف وقتًا للسؤال خارج Ranked.', 90, null, true, false, 20),
  ('hint-skip', 'hint', 'تخطي السؤال', 'Skip Question', 'يتخطى سؤالًا في الوضع الفردي.', 150, null, true, false, 30),
  ('frame-electric-green', 'cosmetic', 'إطار الأخضر الكهربائي', 'Electric Green Frame', 'إطار ملف شخصي تجميلي.', 900, null, false, true, 40),
  ('frame-gold', 'cosmetic', 'إطار البطل الذهبي', 'Champion Gold Frame', 'إطار ذهبي تجميلي.', 1600, null, false, true, 50),
  ('nameplate-stadium', 'cosmetic', 'لوحة اسم الملعب', 'Stadium Nameplate', 'لوحة اسم بطابع الملعب.', 700, null, false, true, 60),
  ('victory-confetti-green', 'cosmetic', 'احتفال القصاصات', 'Green Confetti', 'تأثير فوز تجميلي.', 1200, null, false, true, 70),
  ('coins-small', 'coin_pack', 'حزمة عملات صغيرة', 'Small Coin Pack', 'حزمة افتراضية للاختبار عبر RevenueCat.', null, 'ahdash_coins_small', true, true, 80),
  ('premium-badge', 'cosmetic', 'شارة 11 Premium', '11 Premium Badge', 'شارة تجميلية للمشترك.', null, 'ahdash_premium_monthly', false, true, 90)
on conflict (sku) do update set
  name_ar = excluded.name_ar,
  name_en = excluded.name_en,
  description_ar = excluded.description_ar,
  price_coins = excluded.price_coins,
  revenuecat_product_id = excluded.revenuecat_product_id,
  consumable = excluded.consumable,
  ranked_allowed = excluded.ranked_allowed,
  sort_order = excluded.sort_order,
  is_active = true;

insert into public.seasons(slug, name_ar, name_en, status, starts_at, ends_at, rewards)
values ('demo-season', 'الموسم التجريبي', 'Demo Season', 'active', '2026-08-01T00:00:00+03', '2026-09-30T23:59:59+03', '[{"rank_max":10,"reward":"demo-gold-frame"}]')
on conflict (slug) do update set name_ar = excluded.name_ar, rewards = excluded.rewards;

do $$
declare
  demo record;
  category_value uuid;
  subcategory_value uuid;
  question_value uuid;
  correct_option_value uuid;
  existing_question uuid;
  option_text_value text;
  option_position integer;
  normalized_value text;
  hash_value text;
begin
  for demo in
    select * from (values
      (1, 'eagle-eye', 'club-identification', '[تجريبي] في هوية نادي الصقور الافتراضي، ما اللون الثانوي للشعار؟', array['ذهبي','أزرق','أحمر','بنفسجي'], 1, 'easy'),
      (2, 'eagle-eye', 'club-identification', '[تجريبي] يظهر في شعار نادي الموج الافتراضي رمز مائي؛ ما هو؟', array['موجة','جبل','نخلة','صقر'], 1, 'easy'),
      (3, 'eagle-eye', 'club-identification', '[تجريبي] قميص نادي القلعة الافتراضي مخطط بلونين؛ أي ثنائية مذكورة في البطاقة؟', array['أسود وأبيض','أحمر وأزرق','أخضر وأصفر','برتقالي وبنفسجي'], 1, 'easy'),
      (4, 'eagle-eye', 'player-identification', '[تجريبي] اللاعب رقم 11 في فريق الواحة الافتراضي يلعب جناحًا؛ ما اسمه في السيناريو؟', array['سالم','مازن','ناصر','راكان'], 1, 'easy'),
      (5, 'eagle-eye', 'player-identification', '[تجريبي] بطاقة اللاعب مازن تصفه بحارس مرمى؛ ما مركزه؟', array['حارس مرمى','قلب دفاع','ظهير','مهاجم'], 1, 'easy'),
      (6, 'eagle-eye', 'club-identification', '[تجريبي] أي رمز يميز نادي النخيل الافتراضي في الدليل البصري؟', array['نخلة','مرساة','نجمة','برج'], 1, 'easy'),
      (7, 'eagle-eye', 'club-identification', '[تجريبي] يحمل قائد فريق الريح شارة بأي لون في النموذج؟', array['أصفر','أخضر','أسود','فضي'], 1, 'easy'),
      (8, 'eagle-eye', 'player-identification', '[تجريبي] تصف البطاقة اللاعب راكان بقدم يمنى مميزة؛ ما قدمه المفضلة؟', array['اليمنى','اليسرى','كلتاهما','غير مذكورة'], 1, 'easy'),
      (9, 'transfers', 'player-careers', '[تجريبي] انتقل سامي من نادي الواحة إلى نادي القلعة؛ ما وجهته؟', array['نادي القلعة','نادي الموج','نادي النخيل','نادي الريح'], 1, 'easy'),
      (10, 'transfers', 'player-careers', '[تجريبي] كان نادي الموج المحطة الثانية في مسيرة مازن؛ ما ترتيبه؟', array['الثانية','الأولى','الثالثة','الرابعة'], 1, 'medium'),
      (11, 'transfers', 'player-careers', '[تجريبي] بدأ ناصر مسيرته في نادي النخيل؛ ما ناديه الأول؟', array['نادي النخيل','نادي القلعة','نادي الريح','نادي الواحة'], 1, 'easy'),
      (12, 'transfers', 'player-careers', '[تجريبي] في سيناريو الانتقال، أعار نادي الصقور اللاعب راكان لموسم واحد؛ ما نوع الصفقة؟', array['إعارة','انتقال نهائي','تجديد','اعتزال'], 1, 'medium'),
      (13, 'transfers', 'player-careers', '[تجريبي] رتب مسيرة سالم: الواحة ثم الموج ثم القلعة؛ ما المحطة الأخيرة؟', array['القلعة','الواحة','الموج','النخيل'], 1, 'hard'),
      (14, 'transfers', 'player-careers', '[تجريبي] صفقة مازن الافتراضية تمت في نافذة الشتاء؛ في أي نافذة؟', array['الشتاء','الصيف','قبل الموسم','بعد الاعتزال'], 1, 'easy'),
      (15, 'transfers', 'player-careers', '[تجريبي] ذكر الملف أن قيمة انتقال سامي هي 11 مليون عملة افتراضية؛ ما القيمة؟', array['11 مليون','7 ملايين','15 مليون','20 مليون'], 1, 'easy'),
      (16, 'leagues', 'saudi-league', '[تجريبي] في بطولة الرياض الافتراضية، كم نقطة للفوز وفق اللائحة؟', array['3','1','2','4'], 1, 'easy'),
      (17, 'leagues', 'premier-league', '[تجريبي] يضم دوري الجزيرة الافتراضي 20 فريقًا؛ كم فريقًا؟', array['20','18','16','24'], 1, 'easy'),
      (18, 'leagues', 'la-liga', '[تجريبي] يقام نهائي كأس الشمس الافتراضي في مدينة نور؛ ما المدينة؟', array['نور','سحاب','واحة','مرسى'], 1, 'easy'),
      (19, 'leagues', 'serie-a', '[تجريبي] بطل دوري القلاع الافتراضي يحصل على درع فضي؛ ما مادة الدرع؟', array['فضة','ذهب','خشب','نحاس'], 1, 'easy'),
      (20, 'leagues', 'bundesliga', '[تجريبي] ما اسم جولة الحسم في دوري السهول الافتراضي؟', array['جولة القمة','جولة الافتتاح','جولة الوداع','جولة النجوم'], 1, 'medium'),
      (21, 'leagues', 'ligue-1', '[تجريبي] شعار دوري الأنهار الافتراضي هو «السرعة والمهارة»؛ ما الكلمة الثانية؟', array['المهارة','القوة','الوحدة','الدقة'], 1, 'easy'),
      (22, 'leagues', 'champions-league', '[تجريبي] يصعد متصدرا كل مجموعة في بطولة القمم الافتراضية؛ كم فريقًا؟', array['2','1','3','4'], 1, 'easy'),
      (23, 'leagues', 'world-cup', '[تجريبي] تشارك 32 دولة في كأس الكوكب الافتراضي؛ كم دولة؟', array['32','24','16','40'], 1, 'easy'),
      (24, 'leagues', 'euro', '[تجريبي] تقام بطولة القارة الافتراضية كل أربع سنوات؛ كم الفاصل؟', array['4 سنوات','سنتان','3 سنوات','5 سنوات'], 1, 'easy'),
      (25, 'leagues', 'saudi-league', '[تجريبي] تنص لائحة دوري الواحة على هبوط فريقين؛ كم فريقًا؟', array['2','1','3','4'], 1, 'easy'),
      (26, 'leagues', 'premier-league', '[تجريبي] حسم فريق الجسر اللقب بـ 70 نقطة؛ كم رصيده؟', array['70','60','75','80'], 1, 'easy'),
      (27, 'leagues', 'champions-league', '[تجريبي] انتهى نهائي بطولة النجوم 2-1؛ كم هدفًا سُجل؟', array['3','2','1','4'], 1, 'easy'),
      (28, 'leagues', 'world-cup', '[تجريبي] منتخب السهل يرتدي الأخضر في كأس الكوكب؛ ما لونه؟', array['أخضر','أزرق','أحمر','أبيض'], 1, 'easy'),
      (29, 'locker-room', 'coaches', '[تجريبي] يعتمد المدرب عادل خطة 4-3-3؛ كم مهاجمًا في الخط الأمامي؟', array['3','2','1','4'], 1, 'easy'),
      (30, 'locker-room', 'coaches', '[تجريبي] طلب المدرب سعد ضغطًا عاليًا؛ أي أسلوب طلب؟', array['الضغط العالي','التراجع الكامل','إضاعة الوقت','لعب طويل فقط'], 1, 'easy'),
      (31, 'locker-room', 'shirt-numbers', '[تجريبي] يرتدي قائد نادي الصقور الرقم 8؛ ما رقمه؟', array['8','7','10','11'], 1, 'easy'),
      (32, 'locker-room', 'shirt-numbers', '[تجريبي] خصص نادي الموج الرقم 1 للحارس؛ ما الرقم؟', array['1','12','22','30'], 1, 'easy'),
      (33, 'locker-room', 'coaches', '[تجريبي] في التشكيلة الافتراضية يلعب مازن خلف رأس الحربة؛ ما دوره؟', array['صانع لعب','حارس','قلب دفاع','ظهير'], 1, 'medium'),
      (34, 'locker-room', 'shirt-numbers', '[تجريبي] أي رقم يظهر على قميص سالم في البطاقة؟', array['11','9','6','4'], 1, 'easy'),
      (35, 'locker-room', 'coaches', '[تجريبي] من يقود تدريب نادي القلعة في السيناريو؟', array['المدرب عادل','المدرب سعد','المدرب نواف','المدرب فهد'], 1, 'easy'),
      (36, 'locker-room', 'coaches', '[تجريبي] بدأ المدرب المباراة بأربعة مدافعين؛ كم مدافعًا؟', array['4','3','5','2'], 1, 'easy'),
      (37, 'stadiums', 'stadium-facts', '[تجريبي] يقع ملعب الواحة الافتراضي في مدينة نور؛ أين يقع؟', array['مدينة نور','مدينة سحاب','مدينة القمم','مدينة المرسى'], 1, 'easy'),
      (38, 'stadiums', 'stadium-facts', '[تجريبي] سعة ملعب الصقر هي 30 ألف متفرج؛ كم سعته؟', array['30 ألف','20 ألف','40 ألف','50 ألف'], 1, 'easy'),
      (39, 'stadiums', 'stadium-facts', '[تجريبي] أرضية ملعب الموج من العشب الطبيعي؛ ما نوع الأرضية؟', array['عشب طبيعي','عشب صناعي','رمل','خشب'], 1, 'easy'),
      (40, 'stadiums', 'stadium-facts', '[تجريبي] يضم ملعب القلعة أربعة مدرجات رئيسية؛ كم مدرجًا؟', array['4','2','3','5'], 1, 'easy'),
      (41, 'stadiums', 'stadium-facts', '[تجريبي] افتتح ملعب النخيل في الموسم الخامس للبطولة؛ ما رقم الموسم؟', array['5','4','6','7'], 1, 'medium'),
      (42, 'stadiums', 'stadium-facts', '[تجريبي] البوابة الشمالية هي بوابة الجمهور في ملعب الريح؛ أي بوابة؟', array['الشمالية','الجنوبية','الشرقية','الغربية'], 1, 'easy'),
      (43, 'individual-awards', 'award-history', '[تجريبي] فاز سالم بجائزة نجم الموسم التجريبي؛ من الفائز؟', array['سالم','مازن','ناصر','راكان'], 1, 'easy'),
      (44, 'individual-awards', 'award-history', '[تجريبي] سجل مازن 18 هدفًا ونال الحذاء الذهبي؛ كم هدفًا؟', array['18','15','20','22'], 1, 'easy'),
      (45, 'individual-awards', 'award-history', '[تجريبي] جائزة القفاز الفضي مخصصة لحراس المرمى؛ لأي مركز؟', array['حارس المرمى','المهاجم','المدافع','لاعب الوسط'], 1, 'easy'),
      (46, 'individual-awards', 'award-history', '[تجريبي] اختير ناصر أفضل لاعب صاعد؛ ما الجائزة؟', array['أفضل لاعب صاعد','أفضل مدرب','أفضل حارس','هداف الموسم'], 1, 'easy'),
      (47, 'individual-awards', 'award-history', '[تجريبي] حصل راكان على جائزة أجمل هدف بعد تسديدة بعيدة؛ ما سبب الجائزة؟', array['تسديدة بعيدة','ركلة جزاء','ضربة رأس','هدف عكسي'], 1, 'medium'),
      (48, 'individual-awards', 'award-history', '[تجريبي] جمع سالم 5 تمريرات حاسمة وفاز بجائزة صانع اللعب؛ كم تمريرة؟', array['5','3','7','9'], 1, 'easy'),
      (49, 'individual-awards', 'award-history', '[تجريبي] صوّت الجمهور لمازن لنيل جائزة لاعب الشهر؛ من فاز؟', array['مازن','سالم','ناصر','عادل'], 1, 'easy'),
      (50, 'individual-awards', 'award-history', '[تجريبي] منحت لجنة البطولة جائزة اللعب النظيف لفريق الواحة؛ لمن منحت؟', array['فريق الواحة','فريق الموج','فريق القلعة','فريق النخيل'], 1, 'easy')
    ) as rows(sequence_number, category_slug, subcategory_slug, question_text, options, correct_position, difficulty)
  loop
    select id into category_value from public.categories where slug = demo.category_slug;
    select id into subcategory_value from public.categories where slug = demo.subcategory_slug;
    normalized_value := public.normalize_question_text(demo.question_text);
    hash_value := encode(extensions.digest(convert_to(normalized_value, 'UTF8'), 'sha256'), 'hex');
    select id into existing_question from public.questions where content_hash = hash_value and status <> 'archived';
    if existing_question is not null then
      continue;
    end if;

    insert into public.questions(
      question_text, question_type, category_id, subcategory_id, difficulty,
      status, needs_review, published_at
    ) values (
      demo.question_text, 'text', category_value, subcategory_value,
      demo.difficulty::public.question_difficulty, 'published', false, now()
    ) returning id into question_value;

    option_position := 0;
    foreach option_text_value in array demo.options loop
      option_position := option_position + 1;
      insert into public.question_options(question_id, option_text, position)
      values (question_value, option_text_value, option_position)
      returning id into correct_option_value;
      if option_position = demo.correct_position then
        update public.questions set correct_option_id = correct_option_value where id = question_value;
      end if;
    end loop;

    insert into public.question_tags(question_id, tag_id)
    select question_value, id from public.tags where slug = 'demo'
    on conflict do nothing;
  end loop;
end;
$$;

-- Profiles reference auth.users and are generated by the auth hook. The seed deliberately
-- avoids brittle inserts into Supabase Auth internals; system_opponents provide four demo rivals.
