-- Ahdash party game content contract. This extends the existing question bank;
-- it does not alter competitive match snapshots or expose their answer keys.

alter table public.questions
  add column if not exists question_format text not null default 'multiple_choice',
  add column if not exists correct_answer text,
  add column if not exists alternative_answers text[] not null default '{}',
  add column if not exists explanation text,
  add column if not exists source_url text,
  add column if not exists source_name text,
  add column if not exists verified_at timestamptz,
  add column if not exists point_value integer,
  add column if not exists media_rights_status text not null default 'none';

update public.questions q
set question_format = case
      when q.gameplay_type = 'true-false' then 'true_false'
      when q.question_type = 'image' then 'image'
      else 'multiple_choice'
    end,
    correct_answer = coalesce(
      q.correct_answer,
      (
        select qo.option_text
        from public.question_options qo
        where qo.id = q.correct_option_id
          and qo.question_id = q.id
      )
    ),
    point_value = coalesce(
      q.point_value,
      case q.difficulty
        when 'easy'::public.question_difficulty then 100
        when 'medium'::public.question_difficulty then 200
        else 300
      end
    )
where q.correct_answer is null
   or q.point_value is null
   or q.question_format is null;

alter table public.questions
  alter column point_value set default 200,
  alter column point_value set not null,
  add constraint questions_party_format_check check (
    question_format in ('open_answer', 'multiple_choice', 'true_false', 'image')
  ),
  add constraint questions_party_point_value_check check (
    point_value between 50 and 1000 and point_value % 50 = 0
  ),
  add constraint questions_party_correct_answer_length check (
    correct_answer is null or char_length(btrim(correct_answer)) between 1 and 500
  ),
  add constraint questions_party_explanation_length check (
    explanation is null or char_length(explanation) <= 1200
  ),
  add constraint questions_party_source_url_check check (
    source_url is null or source_url ~ '^https://'
  ),
  add constraint questions_party_media_rights_check check (
    media_rights_status in ('none', 'original', 'generated', 'licensed')
  );

create index if not exists questions_party_pool_idx
  on public.questions(status, offline_practice_eligible, category_id, difficulty, question_format);

create or replace function public.assert_question_publishable()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  target_question public.questions%rowtype;
  target_question_id uuid;
  option_count integer;
  expected_option_count integer;
  true_false_label_count integer := 0;
  correct_question_id uuid;
begin
  if tg_table_name = 'questions' then
    target_question_id := coalesce(new.id, old.id);
  else
    target_question_id := coalesce(new.question_id, old.question_id);
  end if;

  select q.* into target_question
  from public.questions q
  where q.id = target_question_id;

  if not found or target_question.status <> 'published' then
    return null;
  end if;

  select count(*) into option_count
  from public.question_options qo
  where qo.question_id = target_question.id;

  select qo.question_id into correct_question_id
  from public.question_options qo
  where qo.id = target_question.correct_option_id;

  if target_question.question_format in ('open_answer', 'image') then
    if nullif(btrim(target_question.correct_answer), '') is null then
      raise exception using
        errcode = '23514',
        message = 'Published open-answer and image questions require a correct answer';
    end if;
    if target_question.question_format = 'image'
       and target_question.image_url is null then
      raise exception using
        errcode = '23514',
        message = 'Published image questions require an image URL';
    end if;
    if option_count not in (0, 4) then
      raise exception using
        errcode = '23514',
        message = 'Open-answer and image questions require zero or four options';
    end if;
    if option_count = 4
       and (
         target_question.correct_option_id is null
         or correct_question_id is distinct from target_question.id
       ) then
      raise exception using
        errcode = '23514',
        message = 'Questions with options require one owned correct option';
    end if;
    return null;
  end if;

  expected_option_count := case
    when target_question.question_format = 'true_false' then 2
    else 4
  end;

  if target_question.question_format = 'true_false' then
    select count(*) into true_false_label_count
    from public.question_options qo
    where qo.question_id = target_question.id
      and (
        (qo.position = 1 and qo.option_text = 'صح')
        or (qo.position = 2 and qo.option_text = 'خطأ')
      );
  end if;

  if option_count <> expected_option_count
     or target_question.correct_option_id is null
     or correct_question_id is distinct from target_question.id
     or (
       target_question.question_format = 'true_false'
       and true_false_label_count <> 2
     ) then
    raise exception using
      errcode = '23514',
      message = format(
        'Published %s questions require exactly %s options and one owned correct option',
        target_question.question_format,
        expected_option_count
      );
  end if;
  return null;
end;
$$;

-- The original constraint trigger only watched status and correct_option_id.
-- Party formats add answer/media fields that can independently make a
-- published question invalid, so recreate that trigger with the full input
-- contract covered.
drop trigger if exists questions_publishable_after_question on public.questions;
create constraint trigger questions_publishable_after_question
after insert or update of
  status,
  correct_option_id,
  question_format,
  correct_answer,
  image_url
on public.questions
deferrable initially deferred
for each row execute function public.assert_question_publishable();

create or replace function public.create_admin_party_question(
  p_question_text text,
  p_question_format text,
  p_category_id uuid,
  p_difficulty public.question_difficulty,
  p_correct_answer text,
  p_alternative_answers text[] default '{}'::text[],
  p_options text[] default '{}'::text[],
  p_correct_position smallint default null,
  p_point_value integer default 200,
  p_explanation text default null,
  p_source_url text default null,
  p_source_name text default null,
  p_season text default null,
  p_image_url text default null,
  p_media_rights_status text default 'none'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  clean_question_text text;
  clean_answer text;
  clean_options text[];
  expected_option_count integer;
  question_id_value uuid;
  inserted_option_id uuid;
  option_value text;
  option_position integer;
begin
  caller := public.require_active_user();
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Moderator role required';
  end if;
  if p_question_format not in ('open_answer', 'multiple_choice', 'true_false', 'image') then
    raise exception using errcode = '22023', message = 'Unsupported question format';
  end if;
  if p_point_value not between 50 and 1000 or p_point_value % 50 <> 0 then
    raise exception using errcode = '22023', message = 'Point value must be between 50 and 1000 in steps of 50';
  end if;
  if p_source_url is not null and p_source_url !~ '^https://' then
    raise exception using errcode = '22023', message = 'Source URL must use HTTPS';
  end if;
  if p_media_rights_status not in ('none', 'original', 'generated', 'licensed') then
    raise exception using errcode = '22023', message = 'Unsupported media rights status';
  end if;
  if p_question_format = 'image'
     and (p_image_url is null or p_media_rights_status = 'none') then
    raise exception using errcode = '22023', message = 'Image questions require rights-cleared media';
  end if;

  clean_question_text := btrim(
    regexp_replace(coalesce(p_question_text, ''), '[[:space:]]+', ' ', 'g')
  );
  clean_answer := btrim(
    regexp_replace(coalesce(p_correct_answer, ''), '[[:space:]]+', ' ', 'g')
  );
  if char_length(clean_question_text) not between 5 and 1000
     or char_length(clean_answer) not between 1 and 500 then
    raise exception using errcode = '22023', message = 'Question or answer length is invalid';
  end if;

  select coalesce(
    array_agg(
      btrim(regexp_replace(source.option_text, '[[:space:]]+', ' ', 'g'))
      order by source.ordinality
    ),
    '{}'::text[]
  )
  into clean_options
  from unnest(coalesce(p_options, '{}'::text[]))
    with ordinality as source(option_text, ordinality);

  expected_option_count := case
    when p_question_format = 'true_false' then 2
    when p_question_format = 'multiple_choice' then 4
    else 0
  end;
  if cardinality(clean_options) <> expected_option_count then
    raise exception using errcode = '22023', message = 'Option count does not match question format';
  end if;
  if expected_option_count > 0
     and (p_correct_position is null or p_correct_position not between 1 and expected_option_count) then
    raise exception using errcode = '22023', message = 'Correct option position is invalid';
  end if;
  if p_question_format = 'true_false'
     and clean_options is distinct from array['صح', 'خطأ']::text[] then
    raise exception using errcode = '22023', message = 'True/False options must be صح then خطأ';
  end if;
  if expected_option_count > 0 and (
    exists (
      select 1
      from unnest(clean_options) as cleaned(option_text)
      where char_length(cleaned.option_text) not between 1 and 300
    )
    or (
      select count(distinct cleaned.option_text)
      from unnest(clean_options) as cleaned(option_text)
    ) <> expected_option_count
  ) then
    raise exception using errcode = '22023', message = 'Options must be non-empty and unique';
  end if;

  insert into public.questions(
    question_text,
    question_type,
    category_id,
    difficulty,
    status,
    needs_review,
    created_by,
    gameplay_type,
    offline_practice_eligible,
    competitive_eligible,
    question_format,
    correct_answer,
    alternative_answers,
    explanation,
    source_url,
    source_name,
    season,
    image_url,
    point_value,
    media_rights_status
  ) values (
    clean_question_text,
    case when p_question_format = 'image' then 'image'::public.question_type else 'text'::public.question_type end,
    p_category_id,
    p_difficulty,
    'draft',
    true,
    caller.id,
    case when p_question_format = 'true_false' then 'true-false' else 'classic' end,
    true,
    false,
    p_question_format,
    clean_answer,
    coalesce(p_alternative_answers, '{}'::text[]),
    nullif(btrim(p_explanation), ''),
    nullif(btrim(p_source_url), ''),
    nullif(btrim(p_source_name), ''),
    nullif(btrim(p_season), ''),
    nullif(btrim(p_image_url), ''),
    p_point_value,
    p_media_rights_status
  ) returning id into question_id_value;

  for option_value, option_position in
    select source.option_text, source.ordinality::integer
    from unnest(clean_options) with ordinality as source(option_text, ordinality)
  loop
    insert into public.question_options(question_id, option_text, position)
    values (question_id_value, option_value, option_position::smallint)
    returning id into inserted_option_id;
    if option_position = p_correct_position then
      update public.questions
      set correct_option_id = inserted_option_id,
          correct_answer = option_value
      where id = question_id_value;
    end if;
  end loop;

  return jsonb_build_object(
    'id', question_id_value,
    'status', 'draft',
    'question_format', p_question_format,
    'needs_review', true
  );
end;
$$;

revoke all on function public.create_admin_party_question(
  text, text, uuid, public.question_difficulty, text, text[], text[], smallint,
  integer, text, text, text, text, text, text
) from public, anon;
grant execute on function public.create_admin_party_question(
  text, text, uuid, public.question_difficulty, text, text[], text[], smallint,
  integer, text, text, text, text, text, text
) to authenticated;

create or replace function public.get_party_question_pack(
  p_limit integer default 250,
  p_category_ids uuid[] default null
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
begin
  caller := public.require_active_user();
  if p_limit not between 1 and 250 then
    raise exception using errcode = '22023', message = 'Party pack limit must be between 1 and 250';
  end if;

  return query
  select jsonb_build_object(
    'id', q.id,
    'question_text', q.question_text,
    'question_type', q.question_type,
    'question_format', q.question_format,
    'gameplay_type', q.gameplay_type,
    'image_url', q.image_url,
    'category_id', q.category_id,
    'subcategory_id', q.subcategory_id,
    'difficulty', q.difficulty,
    'point_value', q.point_value,
    'options', coalesce((
      select jsonb_agg(qo.option_text order by qo.position)
      from public.question_options qo
      where qo.question_id = q.id
    ), '[]'::jsonb),
    'correct_option_index', coalesce((
      select qo.position - 1
      from public.question_options qo
      where qo.id = q.correct_option_id
        and qo.question_id = q.id
    ), 0),
    'correct_answer', q.correct_answer,
    'alternative_answers', to_jsonb(q.alternative_answers),
    'explanation', q.explanation,
    'tags', coalesce((
      select jsonb_agg(t.slug order by t.slug)
      from public.question_tags qt
      join public.tags t on t.id = qt.tag_id
      where qt.question_id = q.id
    ), '[]'::jsonb),
    'season', q.season,
    'club', q.club,
    'player', q.player,
    'competition', q.competition,
    'country', q.country
  )
  from public.questions q
  left join public.question_history h
    on h.question_id = q.id
    and h.user_id = caller.id
  where q.status = 'published'
    and q.needs_review = false
    and q.offline_practice_eligible
    and not q.competitive_eligible
    and q.gameplay_type in ('classic', 'true-false')
    and q.question_format in ('open_answer', 'multiple_choice', 'true_false', 'image')
    and q.correct_answer is not null
    and (
      q.question_type <> 'image'
      or q.media_rights_status in ('original', 'generated', 'licensed')
    )
    and (
      p_category_ids is null
      or cardinality(p_category_ids) = 0
      or q.category_id = any(p_category_ids)
    )
  order by h.last_seen_at nulls first, q.times_played, q.id
  limit p_limit;
end;
$$;

revoke all on function public.get_party_question_pack(integer, uuid[])
  from public, anon;
grant execute on function public.get_party_question_pack(integer, uuid[])
  to authenticated;

-- A compact, answer-free health view lets the category chooser work across a
-- large catalog without downloading a globally truncated question pack.
create or replace function public.get_party_category_health()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
begin
  caller := public.require_active_user();
  return query
  select jsonb_build_object(
    'category_id', c.id,
    'total', count(q.id),
    'easy_count', count(q.id) filter (where q.difficulty = 'easy'),
    'medium_count', count(q.id) filter (where q.difficulty = 'medium'),
    'hard_count', count(q.id) filter (
      where q.difficulty in ('hard', 'expert')
    )
  )
  from public.categories c
  left join public.questions q
    on q.category_id = c.id
    and q.status = 'published'
    and q.needs_review = false
    and q.offline_practice_eligible
    and not q.competitive_eligible
    and q.gameplay_type in ('classic', 'true-false')
    and q.question_format in ('open_answer', 'multiple_choice', 'true_false', 'image')
    and q.correct_answer is not null
    and (
      q.question_type <> 'image'
      or q.media_rights_status in ('original', 'generated', 'licensed')
    )
  where c.parent_id is null
    and c.is_active
  group by c.id
  order by c.id;
end;
$$;

revoke all on function public.get_party_category_health() from public, anon;
grant execute on function public.get_party_category_health() to authenticated;

create table public.party_category_favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, category_id)
);

alter table public.party_category_favorites enable row level security;
create policy party_category_favorites_select_own
  on public.party_category_favorites for select
  to authenticated
  using (user_id = (select auth.uid()));
create policy party_category_favorites_insert_own
  on public.party_category_favorites for insert
  to authenticated
  with check (user_id = (select auth.uid()));
create policy party_category_favorites_delete_own
  on public.party_category_favorites for delete
  to authenticated
  using (user_id = (select auth.uid()));
create policy party_category_favorites_update_own
  on public.party_category_favorites for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create table public.party_help_tools (
  id text primary key,
  name_ar text not null,
  description_ar text not null,
  icon_key text not null,
  timing text not null check (timing in ('before_question', 'after_question')),
  uses_per_game smallint not null default 1 check (uses_per_game between 1 and 3),
  rule_config jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  sort_order smallint not null default 0,
  updated_at timestamptz not null default now()
);

insert into public.party_help_tools(
  id, name_ar, description_ar, icon_key, timing, rule_config, sort_order
) values
  ('two_chances', 'فرصتين', 'يسمح للفريق بإعطاء إجابتين', 'looks_two', 'after_question', '{}', 1),
  ('call_friend', 'استنجد', 'استعانة بصديق لمدة 20 ثانية', 'phone', 'after_question', '{"seconds":20}', 2),
  ('risk', 'مخاطرة', 'مضاعفة عند الصواب وخصم القيمة عند الخطأ', 'trending_up', 'before_question', '{"correct_multiplier":2,"wrong_multiplier":-1}', 3),
  ('bench', 'على الدكة', 'إبعاد لاعب من الخصم لهذا السؤال', 'event_seat', 'after_question', '{"requires_player_names":true}', 4),
  ('pass', 'مرّرها', 'تمرير السؤال للفريق الآخر', 'redo', 'after_question', '{"wrong_multiplier":-1}', 5)
on conflict (id) do update
set name_ar = excluded.name_ar,
    description_ar = excluded.description_ar,
    icon_key = excluded.icon_key,
    timing = excluded.timing,
    rule_config = excluded.rule_config,
    sort_order = excluded.sort_order;

alter table public.party_help_tools enable row level security;
create policy party_help_tools_read_active
  on public.party_help_tools for select
  to authenticated
  using (is_active or public.has_role('moderator'));
create policy party_help_tools_manage_admin
  on public.party_help_tools for all
  to authenticated
  using (public.has_role('admin'))
  with check (public.has_role('admin'));

create table public.party_game_settings (
  singleton boolean primary key default true check (singleton),
  categories_per_game smallint not null default 6 check (categories_per_game = 6),
  questions_per_category smallint not null default 6 check (questions_per_category = 6),
  helpers_per_team smallint not null default 3 check (helpers_per_team between 1 and 5),
  timer_options_seconds integer[] not null default array[15, 20, 30, 45, 60],
  default_timer_seconds integer default 30,
  point_tiers integer[] not null default array[100, 200, 300],
  tiebreaker_enabled boolean not null default true,
  risk_rule jsonb not null default '{"correct_multiplier":2,"wrong_multiplier":-1}'::jsonb,
  pass_rule jsonb not null default '{"wrong_multiplier":-1}'::jsonb,
  updated_at timestamptz not null default now()
);

insert into public.party_game_settings(singleton) values (true)
on conflict (singleton) do nothing;

alter table public.party_game_settings enable row level security;
create policy party_game_settings_read
  on public.party_game_settings for select
  to authenticated
  using (true);
create policy party_game_settings_manage_admin
  on public.party_game_settings for all
  to authenticated
  using (public.has_role('admin'))
  with check (public.has_role('admin'));

grant select, insert, update, delete on public.party_category_favorites to authenticated;
grant select, update on public.party_help_tools to authenticated;
grant select on public.party_game_settings to authenticated;

insert into public.game_settings(key, value, description_ar, is_public, validation)
values
  ('party.categories_per_game', '6'::jsonb, 'عدد الأقسام في لعبة الجلسة', true, '{"min":6,"max":6}'::jsonb),
  ('party.questions_per_category', '6'::jsonb, 'عدد الأسئلة لكل قسم', true, '{"min":6,"max":6}'::jsonb),
  ('party.helpers_per_team', '3'::jsonb, 'عدد المساعدات لكل فريق', true, '{"min":1,"max":5}'::jsonb),
  ('party.default_timer_seconds', '30'::jsonb, 'المؤقت الافتراضي للسؤال', true, '{"min":0,"max":60}'::jsonb),
  ('party.easy_points', '100'::jsonb, 'نقاط السؤال السهل', true, '{"min":50,"max":1000,"step":50}'::jsonb),
  ('party.medium_points', '200'::jsonb, 'نقاط السؤال المتوسط', true, '{"min":50,"max":1000,"step":50}'::jsonb),
  ('party.hard_points', '300'::jsonb, 'نقاط السؤال الصعب', true, '{"min":50,"max":1000,"step":50}'::jsonb),
  ('party.tiebreaker_enabled', '1'::jsonb, 'تفعيل السؤال الفاصل عند التعادل', true, '{"min":0,"max":1}'::jsonb),
  ('party.free.daily_games', '0'::jsonb, 'حد يومي مستقبلي للجولات المجانية؛ صفر يعني غير مفعّل', true, '{"min":0,"max":100}'::jsonb),
  ('party.free.monthly_games', '0'::jsonb, 'حد شهري مستقبلي للجولات المجانية؛ صفر يعني غير مفعّل', true, '{"min":0,"max":1000}'::jsonb),
  ('party.free.rotating_categories_enabled', '0'::jsonb, 'تفعيل تدوير الأقسام المجانية مستقبلًا', true, '{"min":0,"max":1}'::jsonb),
  ('party.free.ad_supported_enabled', '0'::jsonb, 'تفعيل جولة مدعومة بإعلان مستقبلًا', true, '{"min":0,"max":1}'::jsonb)
on conflict (key) do update
set description_ar = excluded.description_ar,
    is_public = excluded.is_public,
    validation = excluded.validation;

-- The original importer remains intact for compatibility. The Admin uses this
-- version for Party-aware rows so open answers are not padded with fake
-- options and all reviewed metadata reaches the canonical questions table.
create or replace function public.commit_party_import_batch(
  p_batch_id uuid,
  p_publish boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_batch public.import_batches%rowtype;
  target_row public.import_rows%rowtype;
  question_id_value uuid;
  correct_option_id_value uuid;
  option_record record;
  tag_slug text;
  format_value text;
  option_count integer;
  expected_option_count integer;
  committed_count integer := 0;
  skipped_count integer := 0;
  mode_values public.match_mode[];
begin
  caller := public.require_active_user();
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Moderator role required';
  end if;
  select * into target_batch
  from public.import_batches
  where id = p_batch_id
  for update;
  if not found or target_batch.status not in ('ready', 'review') then
    raise exception using errcode = 'P0001', message = 'Import batch is not ready to commit';
  end if;
  update public.import_batches set status = 'committing' where id = target_batch.id;

  for target_row in
    select *
    from public.import_rows
    where batch_id = target_batch.id
    order by row_number
    for update
  loop
    if target_row.status <> 'valid' then
      skipped_count := skipped_count + 1;
      continue;
    end if;
    if nullif(target_row.normalized_data ->> 'category_id', '') is null then
      raise exception using
        errcode = '22023',
        message = format('Row %s has no category', target_row.row_number);
    end if;

    format_value := coalesce(
      nullif(target_row.normalized_data ->> 'question_format', ''),
      case
        when target_row.normalized_data ->> 'question_type' = 'image' then 'image'
        else 'multiple_choice'
      end
    );
    if format_value not in ('open_answer', 'multiple_choice', 'true_false', 'image') then
      raise exception using errcode = '22023', message = 'Unsupported imported question format';
    end if;
    select count(*) into option_count
    from jsonb_array_elements_text(
      coalesce(target_row.normalized_data -> 'options', '[]'::jsonb)
    ) as imported_options(option_text)
    where nullif(btrim(imported_options.option_text), '') is not null;
    expected_option_count := case
      when format_value = 'multiple_choice' then 4
      when format_value = 'true_false' then 2
      else option_count
    end;
    if option_count <> expected_option_count
       or (format_value in ('open_answer', 'image') and option_count not in (0, 4)) then
      raise exception using errcode = '22023', message = 'Imported option count does not match format';
    end if;

    select coalesce(
      array_agg(mode_text::public.match_mode),
      array['solo'::public.match_mode]
    ) into mode_values
    from jsonb_array_elements_text(
      coalesce(
        target_row.normalized_data -> 'suitable_modes',
        jsonb_build_array('solo')
      )
    ) as modes(mode_text);

    insert into public.questions(
      question_text, question_type, image_url, category_id, subcategory_id,
      difficulty, status, needs_review, suitable_modes, created_by, published_at,
      gameplay_type, question_format, correct_answer, alternative_answers,
      explanation, source_url, source_name, season, point_value,
      media_rights_status, offline_practice_eligible, competitive_eligible
    ) values (
      target_row.normalized_data ->> 'question_text',
      case when format_value = 'image'
        then 'image'::public.question_type
        else 'text'::public.question_type
      end,
      nullif(target_row.normalized_data ->> 'image_url', ''),
      (target_row.normalized_data ->> 'category_id')::uuid,
      nullif(target_row.normalized_data ->> 'subcategory_id', '')::uuid,
      coalesce(
        (target_row.normalized_data ->> 'difficulty')::public.question_difficulty,
        'medium'::public.question_difficulty
      ),
      case
        when p_publish then 'published'::public.question_status
        when target_row.normalized_data ->> 'question_status' = 'review'
          then 'review'::public.question_status
        else 'draft'::public.question_status
      end,
      not p_publish,
      mode_values,
      caller.id,
      case when p_publish then clock_timestamp() else null end,
      case when format_value = 'true_false' then 'true-false' else 'classic' end,
      format_value,
      nullif(target_row.normalized_data ->> 'correct_answer', ''),
      coalesce(
        array(
          select jsonb_array_elements_text(
            coalesce(target_row.normalized_data -> 'alternative_answers', '[]'::jsonb)
          )
        ),
        '{}'::text[]
      ),
      nullif(target_row.normalized_data ->> 'explanation', ''),
      nullif(target_row.normalized_data ->> 'source_url', ''),
      nullif(target_row.normalized_data ->> 'source_name', ''),
      nullif(target_row.normalized_data ->> 'season', ''),
      coalesce((target_row.normalized_data ->> 'point_value')::integer, 200),
      case target_row.normalized_data ->> 'media_rights_status'
        when 'original' then 'original'
        when 'generated' then 'generated'
        when 'licensed' then 'licensed'
        else 'none'
      end,
      false,
      false
    ) returning id into question_id_value;

    correct_option_id_value := null;
    for option_record in
      select option_text, row_number() over (order by ordinality)::smallint as position
      from jsonb_array_elements_text(target_row.normalized_data -> 'options')
        with ordinality options(option_text, ordinality)
      where nullif(btrim(option_text), '') is not null
    loop
      insert into public.question_options(question_id, option_text, position)
      values (question_id_value, btrim(option_record.option_text), option_record.position)
      returning id into correct_option_id_value;
      if option_record.position <>
          (target_row.normalized_data ->> 'correct_option_position')::smallint then
        correct_option_id_value := null;
      end if;
      if correct_option_id_value is not null then
        update public.questions
        set correct_option_id = correct_option_id_value
        where id = question_id_value;
      end if;
    end loop;

    for tag_slug in
      select jsonb_array_elements_text(
        coalesce(target_row.normalized_data -> 'tags', '[]'::jsonb)
      )
    loop
      insert into public.tags(slug, name_ar)
      values (tag_slug, tag_slug)
      on conflict (slug) do nothing;
      insert into public.question_tags(question_id, tag_id)
      select question_id_value, id from public.tags where slug = tag_slug
      on conflict do nothing;
    end loop;

    update public.import_rows
    set status = 'committed', committed_question_id = question_id_value
    where id = target_row.id;
    committed_count := committed_count + 1;
  end loop;

  if committed_count = 0 then
    raise exception using errcode = 'P0001', message = 'No approved valid rows to commit';
  end if;
  update public.import_batches
  set status = 'completed', committed_by = caller.id, committed_at = clock_timestamp()
  where id = target_batch.id;
  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, new_data)
  values (
    caller.id,
    'import.party_committed',
    'import_batch',
    target_batch.id::text,
    jsonb_build_object('committed_rows', committed_count, 'published', p_publish)
  );
  return jsonb_build_object(
    'batch_id', target_batch.id,
    'status', 'completed',
    'committed_rows', committed_count,
    'skipped_rows', skipped_count,
    'published', p_publish
  );
exception when others then
  update public.import_batches
  set status = 'failed',
      error_summary = jsonb_build_object('message', sqlerrm, 'sqlstate', sqlstate)
  where id = p_batch_id;
  return jsonb_build_object(
    'batch_id', p_batch_id,
    'status', 'failed',
    'error', sqlerrm,
    'sqlstate', sqlstate
  );
end;
$$;

revoke all on function public.commit_party_import_batch(uuid, boolean)
  from public, anon;
grant execute on function public.commit_party_import_batch(uuid, boolean)
  to authenticated;
