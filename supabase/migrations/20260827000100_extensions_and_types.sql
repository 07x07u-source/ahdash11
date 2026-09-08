-- Core extensions, enums, and generic helpers for أحدعش | 11.
create schema if not exists extensions;

create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_trgm with schema extensions;
create extension if not exists citext with schema extensions;

create type public.app_role as enum ('user', 'moderator', 'admin', 'super_admin');
create type public.profile_status as enum ('active', 'suspended', 'banned', 'deletion_pending');
create type public.question_type as enum ('text', 'image');
create type public.question_difficulty as enum ('easy', 'medium', 'hard', 'expert');
create type public.question_status as enum ('draft', 'review', 'published', 'archived');
create type public.match_mode as enum ('solo', 'quick_1v1', 'friend_1v1', 'team_2v2');
create type public.match_status as enum (
  'created', 'lobby', 'ready', 'countdown', 'question',
  'answers_locked', 'result', 'next_question', 'finished', 'cancelled'
);
create type public.match_player_status as enum ('invited', 'joined', 'ready', 'playing', 'disconnected', 'left', 'finished');
create type public.team_side as enum ('solo', 'a', 'b');
create type public.match_question_status as enum ('queued', 'accepting', 'locked', 'revealed');
create type public.room_status as enum ('open', 'locked', 'started', 'closed', 'expired');
create type public.room_member_status as enum ('joined', 'ready', 'disconnected', 'left', 'kicked');
create type public.friend_request_status as enum ('pending', 'accepted', 'declined', 'cancelled');
create type public.season_status as enum ('draft', 'active', 'completed', 'cancelled');
create type public.wallet_transaction_type as enum ('earn', 'spend', 'purchase', 'refund', 'reward', 'admin_adjustment');
create type public.store_item_type as enum ('hint', 'cosmetic', 'booster', 'coin_pack');
create type public.inventory_status as enum ('active', 'consumed', 'expired', 'revoked');
create type public.subscription_status as enum ('trialing', 'active', 'grace_period', 'paused', 'expired', 'cancelled', 'refunded');
create type public.notification_type as enum (
  'friend_request', 'match_invite', 'challenge', 'daily_challenge',
  'reward', 'season', 'announcement', 'system'
);
create type public.notification_status as enum ('queued', 'sent', 'delivered', 'failed', 'cancelled');
create type public.report_reason as enum ('wrong_answer', 'unclear', 'wrong_image', 'duplicate', 'other');
create type public.report_status as enum ('open', 'reviewing', 'resolved', 'dismissed');
create type public.import_source as enum ('csv', 'xlsx', 'manual');
create type public.import_batch_status as enum ('uploaded', 'validating', 'review', 'ready', 'committing', 'completed', 'failed', 'cancelled');
create type public.import_row_status as enum ('pending', 'valid', 'invalid', 'needs_review', 'duplicate', 'committed', 'skipped');
create type public.account_deletion_status as enum ('requested', 'processing', 'completed', 'failed', 'cancelled');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  new.updated_at = clock_timestamp();
  return new;
end;
$$;

create or replace function public.normalize_question_text(value text)
returns text
language sql
immutable
parallel safe
set search_path = pg_catalog
as $$
  select trim(regexp_replace(lower(coalesce(value, '')), '[^[:alnum:]]+', ' ', 'g'));
$$;

create or replace function public.jsonb_setting_number(value jsonb, fallback numeric)
returns numeric
language plpgsql
immutable
parallel safe
set search_path = pg_catalog
as $$
begin
  return coalesce((value #>> '{}')::numeric, fallback);
exception when others then
  return fallback;
end;
$$;

comment on function public.normalize_question_text(text) is
  'Conservative Arabic/Latin normalization used for exact duplicate hashes and similarity search.';
