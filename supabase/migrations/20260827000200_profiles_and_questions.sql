-- Identity, dynamic taxonomy, question bank, and per-player question history.
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username extensions.citext not null unique,
  display_name text not null,
  avatar_url text,
  role public.app_role not null default 'user',
  status public.profile_status not null default 'active',
  is_guest boolean not null default false,
  level integer not null default 1 check (level >= 1),
  xp bigint not null default 0 check (xp >= 0),
  rating integer not null default 1000 check (rating >= 0),
  favorite_club text,
  locale text not null default 'ar' check (locale ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  timezone text not null default 'Asia/Riyadh',
  last_seen_at timestamptz,
  banned_until timestamptz,
  ban_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_length check (char_length(username::text) between 3 and 24),
  constraint profiles_display_name_length check (char_length(display_name) between 1 and 50),
  constraint profiles_ban_consistency check (
    (status not in ('banned', 'suspended')) or ban_reason is not null
  )
);

create index profiles_role_idx on public.profiles(role);
create index profiles_status_idx on public.profiles(status);
create index profiles_rating_idx on public.profiles(rating desc);
create index profiles_username_trgm_idx on public.profiles using gin ((username::text) extensions.gin_trgm_ops);

create table public.player_stats (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  matches_played integer not null default 0 check (matches_played >= 0),
  wins integer not null default 0 check (wins >= 0),
  losses integer not null default 0 check (losses >= 0),
  draws integer not null default 0 check (draws >= 0),
  correct_answers integer not null default 0 check (correct_answers >= 0),
  wrong_answers integer not null default 0 check (wrong_answers >= 0),
  total_answer_time_ms bigint not null default 0 check (total_answer_time_ms >= 0),
  best_streak integer not null default 0 check (best_streak >= 0),
  current_streak integer not null default 0 check (current_streak >= 0),
  highest_rating integer not null default 1000 check (highest_rating >= 0),
  updated_at timestamptz not null default now(),
  constraint player_stats_match_totals check (wins + losses + draws <= matches_played)
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories(id) on delete cascade,
  slug extensions.citext not null unique,
  name_ar text not null,
  name_en text,
  description_ar text,
  icon_key text,
  image_url text,
  keywords text[] not null default '{}',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint categories_no_self_parent check (parent_id is null or parent_id <> id),
  constraint categories_slug_format check (slug::text ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  constraint categories_name_ar_length check (char_length(name_ar) between 1 and 80)
);

create index categories_parent_sort_idx on public.categories(parent_id, sort_order) where is_active;

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  question_text text not null,
  question_type public.question_type not null default 'text',
  image_url text,
  category_id uuid not null references public.categories(id) on delete restrict,
  subcategory_id uuid references public.categories(id) on delete restrict,
  difficulty public.question_difficulty not null default 'medium',
  correct_option_id uuid,
  normalized_text text not null default '',
  content_hash text not null default '',
  season text,
  club text,
  player text,
  competition text,
  country text,
  status public.question_status not null default 'draft',
  needs_review boolean not null default true,
  suitable_modes public.match_mode[] not null default array['solo'::public.match_mode, 'quick_1v1'::public.match_mode, 'friend_1v1'::public.match_mode, 'team_2v2'::public.match_mode],
  times_played bigint not null default 0 check (times_played >= 0),
  correct_answers bigint not null default 0 check (correct_answers >= 0),
  wrong_answers bigint not null default 0 check (wrong_answers >= 0),
  average_answer_time_ms numeric(12,2) check (average_answer_time_ms is null or average_answer_time_ms >= 0),
  difficulty_sample_size integer not null default 0 check (difficulty_sample_size >= 0),
  created_by uuid references public.profiles(id) on delete set null,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint questions_text_length check (char_length(question_text) between 5 and 1000),
  constraint questions_image_requirement check (question_type <> 'image' or image_url is not null),
  constraint questions_answer_totals check (correct_answers + wrong_answers <= times_played),
  constraint questions_publish_timestamp check (status <> 'published' or published_at is not null),
  constraint questions_distinct_category check (subcategory_id is null or subcategory_id <> category_id)
);

create unique index questions_active_content_hash_uidx
  on public.questions(content_hash)
  where status <> 'archived';
create index questions_browse_idx on public.questions(status, category_id, subcategory_id, difficulty);
create index questions_modes_idx on public.questions using gin(suitable_modes);
create index questions_normalized_trgm_idx on public.questions using gin (normalized_text extensions.gin_trgm_ops);
create index questions_created_by_idx on public.questions(created_by, created_at desc);

create table public.question_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  option_text text not null,
  position smallint not null check (position between 1 and 4),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint question_options_text_length check (char_length(option_text) between 1 and 300),
  unique (question_id, position),
  unique (question_id, option_text),
  unique (id, question_id)
);

alter table public.questions
  add constraint questions_correct_option_fk
  foreign key (correct_option_id) references public.question_options(id)
  deferrable initially deferred;

create index question_options_question_idx on public.question_options(question_id, position);

create table public.tags (
  id uuid primary key default gen_random_uuid(),
  slug extensions.citext not null unique,
  name_ar text not null,
  name_en text,
  created_at timestamptz not null default now(),
  constraint tags_slug_format check (slug::text ~ '^[a-z0-9][a-z0-9_-]{1,63}$')
);

create table public.question_tags (
  question_id uuid not null references public.questions(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (question_id, tag_id)
);

create index question_tags_tag_idx on public.question_tags(tag_id, question_id);

create table public.question_history (
  user_id uuid not null references public.profiles(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  times_seen integer not null default 1 check (times_seen > 0),
  correct_count integer not null default 0 check (correct_count >= 0),
  wrong_count integer not null default 0 check (wrong_count >= 0),
  average_answer_time_ms numeric(12,2) check (average_answer_time_ms is null or average_answer_time_ms >= 0),
  last_was_correct boolean,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  primary key (user_id, question_id),
  constraint question_history_totals check (correct_count + wrong_count <= times_seen)
);

create index question_history_recent_idx on public.question_history(user_id, last_seen_at desc);
create index question_history_question_idx on public.question_history(question_id);

create table public.system_opponents (
  id uuid primary key default gen_random_uuid(),
  slug extensions.citext not null unique,
  name_ar text not null,
  difficulty_label text not null check (difficulty_label in ('easy', 'medium', 'hard', 'legend')),
  correct_probability numeric(5,4) not null check (correct_probability between 0 and 1),
  average_response_ms integer not null check (average_response_ms between 500 and 60000),
  response_jitter_ms integer not null default 1000 check (response_jitter_ms >= 0),
  avatar_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.prepare_question_record()
returns trigger
language plpgsql
set search_path = pg_catalog, public, extensions
as $$
begin
  new.normalized_text := public.normalize_question_text(new.question_text);
  new.content_hash := encode(extensions.digest(convert_to(new.normalized_text, 'UTF8'), 'sha256'), 'hex');
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;
  return new;
end;
$$;

create trigger questions_prepare_before_write
before insert or update of question_text, status, published_at on public.questions
for each row execute function public.prepare_question_record();

create or replace function public.validate_question_taxonomy()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  category_parent uuid;
  subcategory_parent uuid;
begin
  select parent_id into category_parent from public.categories where id = new.category_id;
  if category_parent is not null then
    raise exception using errcode = '23514', message = 'category_id must reference a top-level category';
  end if;
  if new.subcategory_id is not null then
    select parent_id into subcategory_parent from public.categories where id = new.subcategory_id;
    if subcategory_parent is distinct from new.category_id then
      raise exception using errcode = '23514', message = 'subcategory_id must be a child of category_id';
    end if;
  end if;
  return new;
end;
$$;

create trigger questions_validate_taxonomy
before insert or update of category_id, subcategory_id on public.questions
for each row execute function public.validate_question_taxonomy();

create or replace function public.assert_question_publishable()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  target_question public.questions%rowtype;
  target_question_id uuid;
  option_count integer;
  correct_question_id uuid;
begin
  if tg_table_name = 'questions' then
    target_question_id := coalesce(new.id, old.id);
  else
    target_question_id := coalesce(new.question_id, old.question_id);
  end if;

  select * into target_question
  from public.questions
  where id = target_question_id;

  if not found then
    return null;
  end if;

  if target_question.status <> 'published' then
    return null;
  end if;

  select count(*) into option_count
  from public.question_options
  where question_id = target_question.id;

  select question_id into correct_question_id
  from public.question_options
  where id = target_question.correct_option_id;

  if option_count <> 4 or target_question.correct_option_id is null or correct_question_id is distinct from target_question.id then
    raise exception using errcode = '23514', message = 'Published questions require exactly four options and a correct option owned by the question';
  end if;
  return null;
end;
$$;

create constraint trigger questions_publishable_after_question
after insert or update of status, correct_option_id on public.questions
deferrable initially deferred
for each row execute function public.assert_question_publishable();

create constraint trigger questions_publishable_after_option
after insert or update or delete on public.question_options
deferrable initially deferred
for each row execute function public.assert_question_publishable();

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger player_stats_set_updated_at before update on public.player_stats
for each row execute function public.set_updated_at();
create trigger categories_set_updated_at before update on public.categories
for each row execute function public.set_updated_at();
create trigger questions_set_updated_at before update on public.questions
for each row execute function public.set_updated_at();
create trigger question_options_set_updated_at before update on public.question_options
for each row execute function public.set_updated_at();
create trigger system_opponents_set_updated_at before update on public.system_opponents
for each row execute function public.set_updated_at();

create or replace function public.after_profile_created()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  insert into public.player_stats(user_id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

create trigger profiles_create_stats
after insert on public.profiles
for each row execute function public.after_profile_created();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  generated_username text := 'player_' || left(replace(new.id::text, '-', ''), 10);
  chosen_name text;
begin
  chosen_name := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
    generated_username
  );

  insert into public.profiles(id, username, display_name, is_guest)
  values (
    new.id,
    generated_username,
    left(chosen_name, 50),
    coalesce((new.raw_app_meta_data ->> 'provider') = 'anonymous', false)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

comment on column public.questions.correct_option_id is
  'Secret answer key. Direct client SELECT is revoked in the security migration.';
comment on table public.system_opponents is
  'Server-configured deterministic bot personalities; these are not fake auth users.';
