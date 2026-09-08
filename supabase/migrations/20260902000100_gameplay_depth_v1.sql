-- Ahdash gameplay-depth contract.
-- Additive only: existing questions, categories, reports and purchases remain intact.

alter table public.categories
  add column if not exists tags text[] not null default '{}',
  add column if not exists country_codes text[] not null default '{}',
  add column if not exists region_codes text[] not null default '{}',
  add column if not exists audience_codes text[] not null default array['general']::text[],
  add column if not exists popularity_score integer not null default 0,
  add column if not exists is_recommended boolean not null default false,
  add column if not exists gameplay_instructions_ar text,
  add column if not exists mechanic_type text not null default 'text',
  add column if not exists added_at timestamptz not null default now();

update public.categories
set tags = keywords
where cardinality(tags) = 0
  and cardinality(keywords) > 0;

alter table public.categories
  drop constraint if exists categories_popularity_score_check,
  add constraint categories_popularity_score_check check (popularity_score >= 0),
  drop constraint if exists categories_audience_codes_check,
  add constraint categories_audience_codes_check check (cardinality(audience_codes) between 1 and 16),
  drop constraint if exists categories_gameplay_instructions_length,
  add constraint categories_gameplay_instructions_length check (
    gameplay_instructions_ar is null
    or char_length(gameplay_instructions_ar) between 1 and 1200
  ),
  drop constraint if exists categories_mechanic_type_check,
  add constraint categories_mechanic_type_check check (
    mechanic_type in (
      'text', 'multiple_choice', 'true_false', 'image', 'image_crop',
      'image_blur', 'audio', 'video', 'ordering', 'progressive_hints',
      'drawing', 'charades', 'secret_identity', 'numeric', 'year', 'mixed'
    )
  ),
  drop constraint if exists categories_question_formats_check,
  add constraint categories_question_formats_check check (
    cardinality(question_formats) between 1 and 24
    and question_formats <@ array[
      'open_answer', 'multiple_choice', 'true_false', 'image', 'image_crop',
      'image_blur', 'zoom_image', 'focus_memory', 'audio', 'reversed_audio',
      'video', 'career_path', 'player_number', 'first_name', 'player_crop',
      'silhouette', 'club_league', 'kit', 'ordering', 'multi_clue',
      'progressive_hints', 'hidden_player', 'drawing', 'charades',
      'secret_identity', 'numeric', 'year'
    ]::text[]
  );

create index if not exists categories_discovery_idx
  on public.categories(
    editorial_status,
    is_active,
    is_recommended desc,
    popularity_score desc,
    added_at desc
  )
  where parent_id is null;
create index if not exists categories_tags_gin_idx
  on public.categories using gin(tags);
create index if not exists categories_audience_codes_gin_idx
  on public.categories using gin(audience_codes);
create index if not exists categories_country_codes_gin_idx
  on public.categories using gin(country_codes);
create index if not exists categories_region_codes_gin_idx
  on public.categories using gin(region_codes);

grant select (
  tags,
  country_codes,
  region_codes,
  audience_codes,
  popularity_score,
  is_recommended,
  gameplay_instructions_ar,
  mechanic_type,
  added_at
) on public.categories to anon, authenticated;

create table if not exists public.category_collections (
  id text primary key,
  label_ar text not null,
  audience_codes text[] not null default '{}',
  country_codes text[] not null default '{}',
  region_codes text[] not null default '{}',
  group_keys text[] not null default '{}',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint category_collections_id_format check (id ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  constraint category_collections_label_length check (char_length(label_ar) between 1 and 80)
);

alter table public.category_collections enable row level security;
drop policy if exists category_collections_public_read on public.category_collections;
create policy category_collections_public_read
  on public.category_collections for select
  to anon, authenticated
  using (is_active or public.has_role('moderator'));
drop policy if exists category_collections_admin_manage on public.category_collections;
create policy category_collections_admin_manage
  on public.category_collections for all
  to authenticated
  using (public.has_role('admin'))
  with check (public.has_role('admin'));
grant select on public.category_collections to anon, authenticated;
grant insert, update, delete on public.category_collections to authenticated;

alter table public.questions
  add column if not exists audio_url text,
  add column if not exists video_url text,
  add column if not exists accepted_tolerance numeric,
  add column if not exists numeric_answer numeric,
  add column if not exists ordering_items text[] not null default '{}',
  add column if not exists correct_order text[] not null default '{}',
  add column if not exists hints text[] not null default '{}',
  add column if not exists point_decay_per_hint integer not null default 0,
  add column if not exists mechanic_config jsonb not null default '{}'::jsonb;

alter table public.questions
  drop constraint if exists questions_party_format_check,
  add constraint questions_party_format_check check (
    question_format in (
      'open_answer', 'multiple_choice', 'true_false', 'image', 'image_crop',
      'image_blur', 'audio', 'video', 'ordering', 'progressive_hints',
      'drawing', 'charades', 'secret_identity', 'numeric', 'year'
    )
  ),
  drop constraint if exists questions_audio_url_check,
  add constraint questions_audio_url_check check (audio_url is null or audio_url ~ '^https://'),
  drop constraint if exists questions_video_url_check,
  add constraint questions_video_url_check check (video_url is null or video_url ~ '^https://'),
  drop constraint if exists questions_accepted_tolerance_check,
  add constraint questions_accepted_tolerance_check check (
    accepted_tolerance is null or accepted_tolerance >= 0
  ),
  drop constraint if exists questions_point_decay_per_hint_check,
  add constraint questions_point_decay_per_hint_check check (
    point_decay_per_hint between 0 and 1000
  ),
  drop constraint if exists questions_mechanic_config_object_check,
  add constraint questions_mechanic_config_object_check check (
    jsonb_typeof(mechanic_config) = 'object'
  );

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
  from public.questions as q
  where q.id = target_question_id;

  if not found or target_question.status <> 'published' then
    return null;
  end if;

  select count(*) into option_count
  from public.question_options as question_option
  where question_option.question_id = target_question.id;

  select question_option.question_id into correct_question_id
  from public.question_options as question_option
  where question_option.id = target_question.correct_option_id;

  if target_question.question_format in ('multiple_choice', 'true_false') then
    expected_option_count := case
      when target_question.question_format = 'true_false' then 2
      else 4
    end;
    if target_question.question_format = 'true_false' then
      select count(*) into true_false_label_count
      from public.question_options as question_option
      where question_option.question_id = target_question.id
        and (
          (question_option.position = 1 and question_option.option_text = 'صح')
          or (question_option.position = 2 and question_option.option_text = 'خطأ')
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
  end if;

  if nullif(btrim(target_question.correct_answer), '') is null then
    raise exception using
      errcode = '23514',
      message = 'Published host-evaluated questions require a correct answer';
  end if;
  if option_count not in (0, 4) then
    raise exception using
      errcode = '23514',
      message = 'Host-evaluated questions require zero or four compatibility options';
  end if;
  if option_count = 4
     and (
       target_question.correct_option_id is null
       or correct_question_id is distinct from target_question.id
     ) then
    raise exception using
      errcode = '23514',
      message = 'Compatibility options require one owned correct option';
  end if;
  if target_question.question_format in ('image', 'image_crop', 'image_blur')
     and target_question.image_url is null then
    raise exception using errcode = '23514', message = 'Image formats require an image URL';
  end if;
  if target_question.question_format = 'audio'
     and target_question.audio_url is null then
    raise exception using errcode = '23514', message = 'Audio questions require an audio URL';
  end if;
  if target_question.question_format = 'video'
     and target_question.video_url is null then
    raise exception using errcode = '23514', message = 'Video questions require a video URL';
  end if;
  if target_question.question_format = 'ordering'
     and (
       cardinality(target_question.ordering_items) < 2
       or cardinality(target_question.correct_order) <> cardinality(target_question.ordering_items)
     ) then
    raise exception using
      errcode = '23514',
      message = 'Ordering questions require matching item and answer arrays';
  end if;
  if target_question.question_format = 'progressive_hints'
     and cardinality(target_question.hints) = 0 then
    raise exception using
      errcode = '23514',
      message = 'Progressive-hint questions require at least one hint';
  end if;
  return null;
end;
$$;

drop trigger if exists questions_publishable_after_question on public.questions;
create constraint trigger questions_publishable_after_question
after insert or update of
  status,
  correct_option_id,
  question_format,
  correct_answer,
  image_url,
  audio_url,
  video_url,
  ordering_items,
  correct_order,
  hints
on public.questions
deferrable initially deferred
for each row execute function public.assert_question_publishable();

alter table public.question_reports
  add column if not exists client_game_id text,
  add column if not exists app_version text;

alter table public.question_reports
  drop constraint if exists question_reports_client_game_id_length,
  add constraint question_reports_client_game_id_length check (
    client_game_id is null or char_length(client_game_id) between 1 and 160
  ),
  drop constraint if exists question_reports_app_version_length,
  add constraint question_reports_app_version_length check (
    app_version is null or char_length(app_version) between 1 and 80
  );

grant insert (client_game_id, app_version) on public.question_reports to authenticated;

update public.party_game_settings
set default_timer_seconds = 60,
    timer_options_seconds = array[15, 20, 30, 45, 60],
    risk_rule = '{"correct_multiplier":1,"wrong_multiplier":0,"opponent_penalty_multiplier":-1}'::jsonb,
    pass_rule = '{"correct_multiplier":1,"wrong_multiplier":-1}'::jsonb,
    updated_at = now()
where singleton;

insert into public.game_settings(key, value, description_ar, is_public, validation)
values (
  'party.rule_config',
  '{"primary_answer_seconds":60,"steal_seconds":10,"allow_steal":true,"turn_rotation":"alternate","incorrect_penalty":0,"steal_reward_multiplier":1,"steal_wrong_penalty_multiplier":0,"pit_opponent_penalty_multiplier":-1,"trap_correct_reward_multiplier":1,"trap_wrong_penalty_multiplier":-1,"call_friend_seconds":20,"score_values":[100,200,300]}'::jsonb,
  'قواعد جلسة أحدعش الجماعية القابلة للضبط من لوحة الإدارة',
  true,
  '{"type":"object"}'::jsonb
)
on conflict (key) do update
set value = excluded.value,
    description_ar = excluded.description_ar,
    is_public = excluded.is_public,
    validation = excluded.validation,
    updated_at = now();

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
    'audio_url', q.audio_url,
    'video_url', q.video_url,
    'category_id', q.category_id,
    'subcategory_id', q.subcategory_id,
    'difficulty', q.difficulty,
    'point_value', q.point_value,
    'options', coalesce((
      select jsonb_agg(question_option.option_text order by question_option.position)
      from public.question_options as question_option
      where question_option.question_id = q.id
    ), '[]'::jsonb),
    'correct_option_index', coalesce((
      select question_option.position - 1
      from public.question_options as question_option
      where question_option.id = q.correct_option_id
        and question_option.question_id = q.id
    ), 0),
    'correct_answer', q.correct_answer,
    'alternative_answers', to_jsonb(q.alternative_answers),
    'explanation', q.explanation,
    'accepted_tolerance', q.accepted_tolerance,
    'numeric_answer', q.numeric_answer,
    'ordering_items', to_jsonb(q.ordering_items),
    'correct_order', to_jsonb(q.correct_order),
    'hints', to_jsonb(q.hints),
    'point_decay_per_hint', q.point_decay_per_hint,
    'mechanic_config', q.mechanic_config,
    'tags', coalesce((
      select jsonb_agg(tag.slug order by tag.slug)
      from public.question_tags as question_tag
      join public.tags as tag on tag.id = question_tag.tag_id
      where question_tag.question_id = q.id
    ), '[]'::jsonb),
    'season', q.season,
    'club', q.club,
    'player', q.player,
    'competition', q.competition,
    'country', q.country
  )
  from public.questions as q
  left join public.question_history as history
    on history.question_id = q.id
    and history.user_id = caller.id
  where q.status = 'published'
    and q.needs_review = false
    and q.offline_practice_eligible
    and not q.competitive_eligible
    and q.gameplay_type in ('classic', 'true-false')
    and q.question_format in (
      'open_answer', 'multiple_choice', 'true_false', 'image', 'image_crop',
      'image_blur', 'audio', 'video', 'ordering', 'progressive_hints',
      'drawing', 'charades', 'secret_identity', 'numeric', 'year'
    )
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
  order by history.last_seen_at nulls first, q.times_played, q.id
  limit p_limit;
end;
$$;

revoke all on function public.get_party_question_pack(integer, uuid[]) from public, anon;
grant execute on function public.get_party_question_pack(integer, uuid[]) to authenticated;

alter table public.user_inventory
  drop constraint if exists user_inventory_acquired_via_check,
  add constraint user_inventory_acquired_via_check check (
    acquired_via in ('coins', 'purchase', 'reward', 'subscription', 'admin', 'gift')
  );

create table if not exists public.gift_codes (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null unique,
  store_item_id uuid not null references public.store_items(id) on delete restrict,
  max_redemptions integer not null default 1 check (max_redemptions between 1 and 10000),
  redemption_count integer not null default 0 check (redemption_count >= 0),
  expires_at timestamptz,
  is_active boolean not null default true,
  note text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint gift_codes_hash_shape check (code_hash ~ '^[0-9a-f]{64}$'),
  constraint gift_codes_redemption_limit check (redemption_count <= max_redemptions),
  constraint gift_codes_note_length check (note is null or char_length(note) <= 500)
);

create table if not exists public.gift_redemptions (
  gift_code_id uuid not null references public.gift_codes(id) on delete restrict,
  user_id uuid not null references public.profiles(id) on delete cascade,
  redeemed_at timestamptz not null default now(),
  primary key (gift_code_id, user_id)
);

create index if not exists gift_codes_redeemable_idx
  on public.gift_codes(is_active, expires_at)
  where redemption_count < max_redemptions;
create index if not exists gift_redemptions_user_idx
  on public.gift_redemptions(user_id, redeemed_at desc);

alter table public.gift_codes enable row level security;
alter table public.gift_redemptions enable row level security;
drop policy if exists gift_codes_admin_manage on public.gift_codes;
create policy gift_codes_admin_manage
  on public.gift_codes for all
  to authenticated
  using (public.has_role('admin'))
  with check (public.has_role('admin'));
drop policy if exists gift_redemptions_owner_read on public.gift_redemptions;
create policy gift_redemptions_owner_read
  on public.gift_redemptions for select
  to authenticated
  using (user_id = auth.uid() or public.has_role('moderator'));
grant select, insert, update, delete on public.gift_codes to authenticated;
grant select on public.gift_redemptions to authenticated;

create or replace function public.redeem_gift_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  code_hash_value text;
  target_code public.gift_codes%rowtype;
  target_item public.store_items%rowtype;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'redeem_gift_code', 12, interval '1 hour');
  if char_length(btrim(coalesce(p_code, ''))) not between 6 and 80 then
    raise exception using errcode = '22023', message = 'Gift code is invalid';
  end if;
  code_hash_value := encode(
    extensions.digest(
      convert_to(upper(btrim(p_code)), 'UTF8'),
      'sha256'
    ),
    'hex'
  );

  select gift_code.* into target_code
  from public.gift_codes as gift_code
  where gift_code.code_hash = code_hash_value
  for update;
  if not found
     or not target_code.is_active
     or target_code.redemption_count >= target_code.max_redemptions
     or (target_code.expires_at is not null and target_code.expires_at <= clock_timestamp()) then
    raise exception using errcode = 'P0002', message = 'Gift code is unavailable';
  end if;
  if exists (
    select 1
    from public.gift_redemptions as redemption
    where redemption.gift_code_id = target_code.id
      and redemption.user_id = caller.id
  ) then
    raise exception using errcode = '23505', message = 'Gift code was already redeemed';
  end if;

  select store_item.* into target_item
  from public.store_items as store_item
  where store_item.id = target_code.store_item_id
    and store_item.is_active;
  if not found then
    raise exception using errcode = 'P0002', message = 'Gift product is unavailable';
  end if;

  insert into public.gift_redemptions(gift_code_id, user_id)
  values (target_code.id, caller.id);
  update public.gift_codes
  set redemption_count = redemption_count + 1,
      updated_at = clock_timestamp()
  where id = target_code.id;
  insert into public.user_inventory(
    user_id,
    store_item_id,
    status,
    quantity,
    acquired_via
  ) values (
    caller.id,
    target_item.id,
    'active',
    1,
    'gift'
  )
  on conflict (user_id, store_item_id) do update
  set status = 'active',
      quantity = greatest(public.user_inventory.quantity, 1),
      acquired_via = 'gift',
      updated_at = clock_timestamp();

  return jsonb_build_object(
    'status', 'redeemed',
    'product_id', target_item.id,
    'product_name_ar', target_item.name_ar
  );
end;
$$;

revoke all on function public.redeem_gift_code(text) from public, anon;
grant execute on function public.redeem_gift_code(text) to authenticated;

comment on table public.category_collections is
  'Admin-managed discovery groupings. Clients render these rows as data and do not hardcode taxonomies.';
comment on column public.questions.mechanic_config is
  'Format-specific configuration that must not contain unpublished answer keys.';
