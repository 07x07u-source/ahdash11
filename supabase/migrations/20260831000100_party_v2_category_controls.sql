-- Party Game V2 category merchandising and question-report reasons.
-- This migration intentionally extends the current schema; it does not replace
-- or reapply 20260830000100_party_game_content.sql.

alter type public.report_reason add value if not exists 'outdated';
alter type public.report_reason add value if not exists 'broken_media';

alter table public.categories
  add column if not exists group_key text not null default 'other',
  add column if not exists season_label text,
  add column if not exists question_formats text[] not null default array['open_answer']::text[],
  add column if not exists is_favorite_eligible boolean not null default true,
  add column if not exists access_tier text not null default 'free',
  add column if not exists is_featured boolean not null default false,
  add column if not exists is_new boolean not null default false,
  add column if not exists editorial_status public.question_status not null default 'published',
  add column if not exists is_free_rotation boolean not null default false;

alter table public.categories
  drop constraint if exists categories_group_key_check,
  add constraint categories_group_key_check check (
    group_key in (
      'saudi', 'leagues', 'clubs', 'competitions', 'national_teams',
      'players', 'history', 'images', 'audio_video', 'tactics', 'other'
    )
  ),
  drop constraint if exists categories_season_label_length,
  add constraint categories_season_label_length check (
    season_label is null or char_length(season_label) between 1 and 40
  ),
  drop constraint if exists categories_question_formats_check,
  add constraint categories_question_formats_check check (
    cardinality(question_formats) between 1 and 16
    and question_formats <@ array[
      'open_answer', 'multiple_choice', 'true_false', 'image', 'zoom_image',
      'focus_memory', 'audio', 'reversed_audio', 'video', 'career_path',
      'player_number', 'first_name', 'player_crop', 'silhouette',
      'club_league', 'kit', 'ordering', 'multi_clue', 'hidden_player',
      'drawing'
    ]::text[]
  ),
  drop constraint if exists categories_access_tier_check,
  add constraint categories_access_tier_check check (
    access_tier in ('free', 'premium')
  );

create index if not exists categories_party_browser_idx
  on public.categories(editorial_status, is_active, is_featured desc, is_new desc, sort_order)
  where parent_id is null;

create index if not exists categories_party_group_idx
  on public.categories(group_key, sort_order)
  where parent_id is null and is_active and editorial_status = 'published';

comment on column public.categories.group_key is
  'Football-first Party browser group; never inferred as a country catalogue.';
comment on column public.categories.question_formats is
  'Editorially allowed formats. A format may remain architecture-only until a client renderer is released.';
comment on column public.categories.access_tier is
  'Content visibility tier only. It must never alter scoring or competitive advantage.';
comment on column public.categories.is_free_rotation is
  'Admin-controlled free rotation marker, interpreted only when remote free rotation is enabled.';

grant select (
  group_key,
  season_label,
  question_formats,
  is_favorite_eligible,
  access_tier,
  is_featured,
  is_new,
  editorial_status,
  is_free_rotation
) on public.categories to anon, authenticated;
