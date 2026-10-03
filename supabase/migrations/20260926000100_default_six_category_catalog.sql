-- Default football catalogue for a fresh or empty Party installation.
-- The seed is intentionally conditional: an existing ready catalogue is never
-- replaced. If categories exist but have no playable content, these six
-- editorial categories receive a small, answer-keyed starter pack.

-- Text-only catalogues use icon_key as their visual identity. Keep the strict
-- managed-media rule for visual categories, but do not require an uploaded
-- cover before a multiple-choice-only category can be published.
create or replace function public.validate_published_category_media_v5()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  should_validate boolean := false;
  requires_cover boolean := false;
begin
  if tg_op = 'INSERT' then
    should_validate := new.is_active and new.editorial_status = 'published';
  else
    should_validate := new.is_active
      and new.editorial_status = 'published'
      and (
        old.is_active is distinct from new.is_active
        or old.editorial_status is distinct from new.editorial_status
        or old.cover_media_id is distinct from new.cover_media_id
        or old.image_url is distinct from new.image_url
      );
  end if;

  if not should_validate then
    return new;
  end if;

  requires_cover := new.mechanic_type in ('image', 'image_crop', 'image_blur')
    or new.question_formats && array[
      'image', 'image_crop', 'image_blur', 'zoom_image', 'focus_memory',
      'player_crop', 'silhouette', 'kit'
    ]::text[];

  if new.cover_media_id is null and new.image_url is null and not requires_cover then
    return new;
  end if;

  if new.cover_media_id is null or new.image_url is null then
    raise exception using
      errcode = '23514',
      message = 'Published visual categories require a cover image';
  end if;

  if not exists (
    select 1
    from public.media_assets as media
    where media.id = new.cover_media_id
      and media.status = 'active'
      and media.mime_type in ('image/jpeg', 'image/png', 'image/webp')
      and media.rights_status in ('original', 'generated', 'licensed')
      and media.asset_group in ('categories', 'app-content')
  ) then
    raise exception using
      errcode = '23514',
      message = 'Published category cover is inactive, invalid, or lacks approved rights';
  end if;

  return new;
end;
$$;

comment on function public.validate_published_category_media_v5() is
  'Requires managed cover media for visual categories; text-only catalogues may use icon_key.';

do $$
declare
  ready_category_count integer;
begin
  select count(*)
    into ready_category_count
  from public.categories c
  where c.parent_id is null
    and c.is_active
    and c.editorial_status = 'published'
    and exists (
      select 1
      from public.questions q
      where q.category_id = c.id
        and q.status = 'published'
        and q.needs_review = false
        and q.offline_practice_eligible
        and not q.competitive_eligible
        and q.gameplay_type = 'classic'
        and q.question_format = 'multiple_choice'
      group by q.category_id
      having count(*) filter (where q.difficulty = 'easy') >= 2
         and count(*) filter (where q.difficulty = 'medium') >= 2
         and count(*) filter (where q.difficulty in ('hard', 'expert')) >= 2
    );

  if ready_category_count > 0 then
    return;
  end if;

  insert into public.categories(
    slug, name_ar, name_en, description_ar, icon_key, keywords,
    sort_order, is_active, group_key, question_formats,
    is_favorite_eligible, access_tier, is_featured, is_new,
    editorial_status, is_free_rotation, tags, audience_codes,
    popularity_score, is_recommended, mechanic_type
  ) values
    ('eagle-eye', 'عين الصقر', 'Eagle Eye', 'تفاصيل الأندية والقمصان والشعارات.', 'eye', array['شعار','قميص','هوية'], 10, true, 'images', array['multiple_choice'], true, 'free', true, true, 'published', true, array['شعار','قميص','هوية'], array['general'], 70, true, 'multiple_choice'),
    ('transfers', 'سوق الانتقالات', 'Transfer Market', 'مسيرات اللاعبين والصفقات التي صنعت الفرق.', 'swap', array['انتقال','صفقة','مسيرة'], 20, true, 'players', array['multiple_choice'], true, 'free', true, true, 'published', true, array['انتقال','صفقة','مسيرة'], array['general'], 80, true, 'multiple_choice'),
    ('leagues', 'الدوريات والبطولات', 'Leagues & Tournaments', 'من البطولات المحلية إلى ليالي القارة.', 'trophy', array['دوري','بطولة','كأس'], 30, true, 'competitions', array['multiple_choice'], true, 'free', true, true, 'published', true, array['دوري','بطولة','كأس'], array['general'], 90, true, 'multiple_choice'),
    ('locker-room', 'غرفة الملابس', 'Locker Room', 'الأرقام والمراكز وتفاصيل التشكيلات.', 'shirt', array['مركز','قميص','تشكيلة'], 40, true, 'other', array['multiple_choice'], true, 'free', true, true, 'published', true, array['مركز','قميص','تشكيلة'], array['general'], 65, true, 'multiple_choice'),
    ('stadiums', 'الملاعب', 'Stadiums', 'ملاعب شهيرة، مدن وذكريات كروية.', 'stadium', array['ملعب','مدينة','مدرج'], 50, true, 'other', array['multiple_choice'], true, 'free', true, true, 'published', true, array['ملعب','مدينة','مدرج'], array['general'], 60, true, 'multiple_choice'),
    ('individual-awards', 'الجوائز الفردية', 'Individual Awards', 'الهدافون والجوائز والإنجازات الكبيرة.', 'medal', array['جائزة','هداف','إنجاز'], 60, true, 'players', array['multiple_choice'], true, 'free', true, true, 'published', true, array['جائزة','هداف','إنجاز'], array['general'], 75, true, 'multiple_choice')
  on conflict (slug) do update set
    name_ar = excluded.name_ar,
    name_en = excluded.name_en,
    description_ar = excluded.description_ar,
    icon_key = excluded.icon_key,
    keywords = excluded.keywords,
    sort_order = excluded.sort_order,
    is_active = true,
    group_key = excluded.group_key,
    question_formats = excluded.question_formats,
    is_favorite_eligible = true,
    access_tier = 'free',
    is_featured = excluded.is_featured,
    is_new = excluded.is_new,
    editorial_status = 'published',
    is_free_rotation = true,
    tags = excluded.tags,
    audience_codes = excluded.audience_codes,
    popularity_score = greatest(public.categories.popularity_score, excluded.popularity_score),
    is_recommended = true,
    mechanic_type = excluded.mechanic_type;

  create temporary table _default_seed_questions (
    question_key text primary key,
    category_slug text not null,
    question_text text not null,
    difficulty public.question_difficulty not null,
    options text[] not null,
    correct_position smallint not null,
    explanation text not null,
    source_name text not null,
    source_url text not null
  ) on commit drop;

  insert into _default_seed_questions(question_key, category_slug, question_text, difficulty, options, correct_position, explanation, source_name, source_url) values
    ('seed-v1:eagle-eye:01', 'eagle-eye', 'ما اللونان الأساسيان لقميص نادي برشلونة؟', 'easy', array['الأزرق والأحمر','الأخضر والأبيض','الأصفر والأسود','الأسود والذهبي'], 1, 'ألوان برشلونة التقليدية هي الأزرق والأحمر.', 'FC Barcelona', 'https://www.fcbarcelona.com/en/club/history'),
    ('seed-v1:eagle-eye:02', 'eagle-eye', 'ما اللقب الشهير لنادي ليفربول الإنجليزي؟', 'easy', array['الريدز','المدفعجية','الشياطين الحمر','البلوز'], 1, 'يُعرف ليفربول بلقب الريدز.', 'Liverpool FC', 'https://www.liverpoolfc.com/history'),
    ('seed-v1:eagle-eye:03', 'eagle-eye', 'أي نادٍ يلعب مبارياته على ملعب سانتياغو برنابيو؟', 'medium', array['ريال مدريد','أتلتيكو مدريد','إشبيلية','فالنسيا'], 1, 'سانتياغو برنابيو هو ملعب ريال مدريد.', 'Real Madrid', 'https://www.realmadrid.com/en/the-club/santiago-bernabeu-stadium'),
    ('seed-v1:eagle-eye:04', 'eagle-eye', 'ما اسم ملعب نادي بايرن ميونخ؟', 'medium', array['أليانز أرينا','سيغنال إيدونا بارك','فولكسباركشتاديون','مرسيدس بنز أرينا'], 1, 'بايرن ميونخ يلعب في أليانز أرينا.', 'FC Bayern', 'https://fcbayern.com/en/club/allianz-arena'),
    ('seed-v1:eagle-eye:05', 'eagle-eye', 'أي نادٍ يلقب بالسيدة العجوز؟', 'hard', array['يوفنتوس','ميلان','إنتر ميلان','روما'], 1, 'السيدة العجوز لقب تاريخي لنادي يوفنتوس.', 'Juventus FC', 'https://www.juventus.com/en/club/history/'),
    ('seed-v1:eagle-eye:06', 'eagle-eye', 'أي منتخب ارتبط تاريخياً بالقميص البرتقالي؟', 'hard', array['هولندا','إيطاليا','الأرجنتين','البرتغال'], 1, 'المنتخب الهولندي معروف بلقبه البرتقالي.', 'KNVB', 'https://www.knvb.com/'),

    ('seed-v1:transfers:01', 'transfers', 'من انتقل إلى نادي النصر السعودي في ديسمبر 2022؟', 'easy', array['كريستيانو رونالدو','لوكا مودريتش','نيمار','محمد صلاح'], 1, 'وقّع كريستيانو رونالدو مع النصر في نهاية 2022.', 'Saudi Pro League', 'https://www.spl.com.sa/en'),
    ('seed-v1:transfers:02', 'transfers', 'من انتقل إلى إنتر ميامي في عام 2023؟', 'easy', array['ليونيل ميسي','كريم بنزيما','إيرلينغ هالاند','سون هيونغ مين'], 1, 'انضم ليونيل ميسي إلى إنتر ميامي في 2023.', 'Inter Miami CF', 'https://www.intermiamicf.com/'),
    ('seed-v1:transfers:03', 'transfers', 'إلى أي نادٍ انتقل إرلينغ هالاند من بوروسيا دورتموند في 2022؟', 'medium', array['مانشستر سيتي','تشيلسي','بايرن ميونخ','أرسنال'], 1, 'انتقل هالاند إلى مانشستر سيتي في صيف 2022.', 'Manchester City', 'https://www.mancity.com/'),
    ('seed-v1:transfers:04', 'transfers', 'من أي نادٍ انتقل محمد صلاح إلى ليفربول في 2017؟', 'medium', array['روما','تشيلسي','بازل','فيورنتينا'], 1, 'انضم صلاح إلى ليفربول قادماً من روما.', 'Liverpool FC', 'https://www.liverpoolfc.com/history'),
    ('seed-v1:transfers:05', 'transfers', 'من أي نادٍ انتقل زين الدين زيدان إلى ريال مدريد في 2001؟', 'hard', array['يوفنتوس','بوردو','مارسيليا','ليون'], 1, 'انتقل زيدان من يوفنتوس إلى ريال مدريد.', 'Real Madrid', 'https://www.realmadrid.com/en/the-club/history/football'),
    ('seed-v1:transfers:06', 'transfers', 'أي نادٍ انتقل منه نيمار إلى باريس سان جيرمان في 2017؟', 'hard', array['برشلونة','سانتوس','ريال مدريد','مانشستر سيتي'], 1, 'انتقل نيمار إلى باريس سان جيرمان قادماً من برشلونة.', 'UEFA', 'https://www.uefa.com/uefachampionsleague/'),

    ('seed-v1:leagues:01', 'leagues', 'كم منتخباً شارك في كأس العالم FIFA 2022؟', 'easy', array['32','24','36','48'], 1, 'شارك 32 منتخباً في نسخة 2022.', 'FIFA', 'https://www.fifa.com/tournaments/mens/worldcup'),
    ('seed-v1:leagues:02', 'leagues', 'ما البطولة القارية الأهم للأندية في أوروبا؟', 'easy', array['دوري أبطال أوروبا','الدوري الأوروبي','دوري الأمم','كأس السوبر الأوروبي'], 1, 'دوري أبطال أوروبا هي المسابقة الأبرز للأندية الأوروبية.', 'UEFA', 'https://www.uefa.com/uefachampionsleague/'),
    ('seed-v1:leagues:03', 'leagues', 'ما المنتخب الذي فاز بكأس العالم 2022؟', 'medium', array['الأرجنتين','فرنسا','البرازيل','كرواتيا'], 1, 'توجت الأرجنتين بكأس العالم 2022.', 'FIFA', 'https://www.fifa.com/tournaments/mens/worldcup/qatar2022'),
    ('seed-v1:leagues:04', 'leagues', 'في أي ملعب أقيم نهائي كأس العالم 2022؟', 'medium', array['ملعب لوسيل','استاد خليفة الدولي','ملعب الجنوب','ملعب أحمد بن علي'], 1, 'أقيم النهائي في ملعب لوسيل.', 'FIFA', 'https://www.fifa.com/tournaments/mens/worldcup/qatar2022'),
    ('seed-v1:leagues:05', 'leagues', 'من فاز بأول نسخة من كأس أوروبا للأندية البطلة؟', 'hard', array['ريال مدريد','بنفيكا','ميلان','برشلونة'], 1, 'فاز ريال مدريد بأول نسخة في موسم 1955-1956.', 'UEFA', 'https://www.uefa.com/uefachampionsleague/history/'),
    ('seed-v1:leagues:06', 'leagues', 'ما المنتخب الأكثر تتويجاً بكأس العالم؟', 'hard', array['البرازيل','ألمانيا','إيطاليا','الأرجنتين'], 1, 'تتصدر البرازيل سجل كأس العالم بخمسة ألقاب.', 'FIFA', 'https://www.fifa.com/tournaments/mens/worldcup'),

    ('seed-v1:locker-room:01', 'locker-room', 'كم لاعباً يبدأ المباراة لكل فريق داخل الملعب؟', 'easy', array['11','9','10','12'], 1, 'يبدأ كل فريق المباراة بأحد عشر لاعباً.', 'The IFAB', 'https://www.theifab.com/laws/latest/the-players/'),
    ('seed-v1:locker-room:02', 'locker-room', 'ما مركز اللاعب الذي يحمي المرمى؟', 'easy', array['حارس المرمى','قلب الدفاع','الجناح','المهاجم'], 1, 'حارس المرمى هو المسؤول عن حماية المرمى.', 'The IFAB', 'https://www.theifab.com/laws/latest/the-players/'),
    ('seed-v1:locker-room:03', 'locker-room', 'ما رقم القميص المرتبط غالباً بالمهاجم الصريح؟', 'medium', array['9','1','5','11'], 1, 'الرقم 9 ارتبط تقليدياً بالمهاجم الصريح.', 'FIFA', 'https://www.fifa.com/technical'),
    ('seed-v1:locker-room:04', 'locker-room', 'ما البطاقة التي تعني طرد اللاعب؟', 'medium', array['الحمراء','الصفراء','الزرقاء','الخضراء'], 1, 'البطاقة الحمراء تعني الطرد من المباراة.', 'The IFAB', 'https://www.theifab.com/laws/latest/method-of-scoring/'),
    ('seed-v1:locker-room:05', 'locker-room', 'كم دقيقة مدة المباراة الأصلية دون وقت بدل الضائع؟', 'hard', array['90','80','100','120'], 1, 'تتكون المباراة من شوطين مدة كل منهما 45 دقيقة.', 'The IFAB', 'https://www.theifab.com/laws/latest/the-duration-of-the-match/'),
    ('seed-v1:locker-room:06', 'locker-room', 'ما رقم القانون الذي يتناول التسلل في قوانين اللعبة؟', 'hard', array['القانون 11','القانون 3','القانون 7','القانون 15'], 1, 'التسلل هو موضوع القانون رقم 11.', 'The IFAB', 'https://www.theifab.com/laws/latest/offside/'),

    ('seed-v1:stadiums:01', 'stadiums', 'في أي مدينة يقع ملعب ويمبلي؟', 'easy', array['لندن','مانشستر','ليفربول','برمنغهام'], 1, 'يقع ملعب ويمبلي في العاصمة البريطانية لندن.', 'Wembley Stadium', 'https://www.wembleystadium.com/'),
    ('seed-v1:stadiums:02', 'stadiums', 'ما اسم ملعب ريال مدريد؟', 'easy', array['سانتياغو برنابيو','كامب نو','أولد ترافورد','أنفيلد'], 1, 'ملعب ريال مدريد هو سانتياغو برنابيو.', 'Real Madrid', 'https://www.realmadrid.com/en/the-club/santiago-bernabeu-stadium'),
    ('seed-v1:stadiums:03', 'stadiums', 'ما اسم ملعب مانشستر يونايتد؟', 'medium', array['أولد ترافورد','الاتحاد','ستامفورد بريدج','آنفيلد'], 1, 'يلعب مانشستر يونايتد في أولد ترافورد.', 'Manchester United', 'https://www.manutd.com/en/visit-old-trafford'),
    ('seed-v1:stadiums:04', 'stadiums', 'ما الاسم الشائع لملعب نادي برشلونة؟', 'medium', array['كامب نو','مونتجويك','ميستايا','سان ماميس'], 1, 'كامب نو هو الاسم التاريخي لملعب برشلونة.', 'FC Barcelona', 'https://www.fcbarcelona.com/en/club/facilities/spotify-camp-nou'),
    ('seed-v1:stadiums:05', 'stadiums', 'في أي مدينة يقع ملعب ماراكانا؟', 'hard', array['ريو دي جانيرو','ساو باولو','برازيليا','بوينس آيرس'], 1, 'يقع ماراكانا في مدينة ريو دي جانيرو.', 'Brazil Football Confederation', 'https://www.cbf.com.br/'),
    ('seed-v1:stadiums:06', 'stadiums', 'ما السعة التقريبية المعلنة لملعب لوسيل؟', 'hard', array['نحو 89 ألف متفرج','نحو 45 ألف متفرج','نحو 120 ألف متفرج','نحو 20 ألف متفرج'], 1, 'تبلغ سعة ملعب لوسيل قرابة 89 ألف متفرج.', 'Supreme Committee Qatar', 'https://www.qatar2022.qa/en/stadiums/lusail-stadium'),

    ('seed-v1:individual-awards:01', 'individual-awards', 'ما الجائزة السنوية لأفضل لاعب في العالم من فرانس فوتبول؟', 'easy', array['الكرة الذهبية','الحذاء الذهبي','القفاز الذهبي','جائزة بوشكاش'], 1, 'الكرة الذهبية هي جائزة فرانس فوتبول الأشهر.', 'France Football', 'https://www.francefootball.fr/ballon-d-or/'),
    ('seed-v1:individual-awards:02', 'individual-awards', 'ما الجائزة التي تمنح لهداف كأس العالم؟', 'easy', array['الحذاء الذهبي','الكرة الذهبية','القفاز الذهبي','جائزة اللعب النظيف'], 1, 'يحصل هداف كأس العالم على الحذاء الذهبي.', 'FIFA', 'https://www.fifa.com/tournaments/mens/worldcup'),
    ('seed-v1:individual-awards:03', 'individual-awards', 'ما الجائزة الفردية التي تمنح لأفضل لاعب شاب في كأس العالم؟', 'medium', array['جائزة أفضل لاعب شاب','الحذاء الذهبي','الكرة الذهبية','القفاز الذهبي'], 1, 'تخصص FIFA جائزة لأفضل لاعب شاب في البطولة.', 'FIFA', 'https://www.fifa.com/tournaments/mens/worldcup'),
    ('seed-v1:individual-awards:04', 'individual-awards', 'من الجهة التي تمنح جائزة الكرة الذهبية؟', 'medium', array['فرانس فوتبول','الاتحاد الدولي للتاريخ والإحصاء','يويفا','الاتحاد الآسيوي'], 1, 'تنظم مجلة فرانس فوتبول جائزة الكرة الذهبية.', 'France Football', 'https://www.francefootball.fr/ballon-d-or/'),
    ('seed-v1:individual-awards:05', 'individual-awards', 'من اللاعب الأكثر فوزاً بالكرة الذهبية حتى نسخة 2023؟', 'hard', array['ليونيل ميسي','كريستيانو رونالدو','ميشيل بلاتيني','يوهان كرويف'], 1, 'رفع ليونيل ميسي رصيده إلى ثماني كرات ذهبية في 2023.', 'France Football', 'https://www.francefootball.fr/ballon-d-or/palmares/'),
    ('seed-v1:individual-awards:06', 'individual-awards', 'من فاز بالحذاء الذهبي في كأس العالم 2022؟', 'hard', array['كيليان مبابي','ليونيل ميسي','جوليان ألفاريز','أوليفييه جيرو'], 1, 'أنهى كيليان مبابي البطولة هدافاً بثمانية أهداف.', 'FIFA', 'https://www.fifa.com/tournaments/mens/worldcup/qatar2022')
  on conflict (question_key) do nothing;

  create temporary table _default_seed_inserted (
    id uuid primary key,
    question_key text unique not null
  ) on commit drop;

  insert into public.questions(
      question_text, question_type, category_id, difficulty, correct_answer,
      explanation, source_url, source_name, verified_at, point_value,
      normalized_text, content_hash, status, needs_review, gameplay_type,
      question_format, media_rights_status, offline_practice_eligible,
      competitive_eligible, published_at
    )
    select
      s.question_text,
      'text'::public.question_type,
      c.id,
      s.difficulty,
      s.options[s.correct_position],
      s.explanation,
      s.source_url,
      s.source_name,
      now(),
      case s.difficulty when 'easy' then 100 when 'medium' then 200 else 300 end,
      lower(btrim(regexp_replace(s.question_text, '[[:space:]]+', ' ', 'g'))),
      s.question_key,
      'published'::public.question_status,
      false,
      'classic',
      'multiple_choice',
      'none',
      true,
      false,
      now()
    from _default_seed_questions s
    join public.categories c on c.slug::text = s.category_slug
    on conflict (content_hash) where status <> 'archived' do nothing
    ;

  -- The existing question trigger normalizes and replaces content_hash. Track
  -- the seed by its stable question_key instead of assuming the hash survives.
  insert into _default_seed_inserted(id, question_key)
  select q.id, s.question_key
  from public.questions q
  join _default_seed_questions s on s.question_text = q.question_text
  join public.categories c on c.slug::text = s.category_slug and c.id = q.category_id
  where q.status <> 'archived'
  on conflict (question_key) do nothing;

  insert into public.question_options(question_id, option_text, position)
  select i.id, option_row.option_text, option_row.position::smallint
  from _default_seed_inserted i
  join _default_seed_questions s on s.question_key = i.question_key
  cross join lateral unnest(s.options) with ordinality as option_row(option_text, position)
  on conflict (question_id, position) do nothing;

  update public.questions q
  set correct_option_id = qo.id,
      correct_answer = qo.option_text
  from _default_seed_inserted i
  join _default_seed_questions s on s.question_key = i.question_key
  join public.question_options qo
    on qo.question_id = i.id
   and qo.position = s.correct_position
  where q.id = i.id;
end;
$$;
