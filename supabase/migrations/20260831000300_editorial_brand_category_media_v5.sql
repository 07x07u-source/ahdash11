-- Ahdash V5 editorial identity: category-image readiness and provenance.
-- Legacy published categories are not mutated. Validation is enforced only
-- when a category enters publication or its publication media changes.

alter table public.categories
  add column if not exists cover_focal_x numeric(4, 3) not null default 0.5,
  add column if not exists cover_focal_y numeric(4, 3) not null default 0.5;

alter table public.categories
  drop constraint if exists categories_cover_focal_x_range,
  add constraint categories_cover_focal_x_range check (cover_focal_x between 0 and 1),
  drop constraint if exists categories_cover_focal_y_range,
  add constraint categories_cover_focal_y_range check (cover_focal_y between 0 and 1);

alter table public.media_assets
  add column if not exists source_text text,
  add column if not exists attribution text;

alter table public.media_assets
  drop constraint if exists media_assets_source_length,
  add constraint media_assets_source_length check (
    source_text is null or char_length(source_text) between 1 and 500
  ),
  drop constraint if exists media_assets_attribution_length,
  add constraint media_assets_attribution_length check (
    attribution is null or char_length(attribution) between 1 and 500
  );

alter table public.questions
  add column if not exists image_media_id uuid,
  add column if not exists image_caption text,
  add column if not exists image_focal_x numeric(4, 3) not null default 0.5,
  add column if not exists image_focal_y numeric(4, 3) not null default 0.5;

alter table public.questions
  drop constraint if exists questions_image_caption_length,
  add constraint questions_image_caption_length check (
    image_caption is null or char_length(image_caption) between 1 and 300
  ),
  drop constraint if exists questions_image_focal_x_range,
  add constraint questions_image_focal_x_range check (image_focal_x between 0 and 1),
  drop constraint if exists questions_image_focal_y_range,
  add constraint questions_image_focal_y_range check (image_focal_y between 0 and 1);

comment on column public.categories.cover_focal_x is
  'Horizontal focal point for editorial category crops, normalized from 0 to 1.';
comment on column public.categories.cover_focal_y is
  'Vertical focal point for editorial category crops, normalized from 0 to 1.';
comment on column public.media_assets.source_text is
  'Internal provenance URL or source note. Never rendered as game content.';
comment on column public.media_assets.attribution is
  'Rights attribution retained with the media asset when required.';
comment on column public.questions.image_caption is
  'Optional editorial caption for rights-cleared image questions.';

create or replace function public.validate_published_category_media_v5()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  should_validate boolean := false;
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

  if new.cover_media_id is null or new.image_url is null then
    raise exception using
      errcode = '23514',
      message = 'Published categories require a cover image';
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

drop trigger if exists categories_validate_published_media_v5 on public.categories;
create trigger categories_validate_published_media_v5
before insert or update of is_active, editorial_status, cover_media_id, image_url
on public.categories
for each row execute function public.validate_published_category_media_v5();

create or replace function public.prevent_published_category_media_archive_v5()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if old.status = 'active'
     and new.status = 'archived'
     and exists (
       select 1
       from public.categories as category
       where category.cover_media_id = old.id
         and category.is_active
         and category.editorial_status = 'published'
     ) then
    raise exception using
      errcode = '23514',
      message = 'Media is used by a published category';
  end if;
  return new;
end;
$$;

drop trigger if exists media_assets_prevent_category_archive_v5 on public.media_assets;
create trigger media_assets_prevent_category_archive_v5
before update of status on public.media_assets
for each row execute function public.prevent_published_category_media_archive_v5();

create or replace function public.validate_published_question_media_v5()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  should_validate boolean := false;
begin
  if tg_op = 'INSERT' then
    should_validate := new.status = 'published' and new.question_type = 'image';
  else
    should_validate := new.status = 'published'
      and new.question_type = 'image'
      and (
        old.status is distinct from new.status
        or old.question_type is distinct from new.question_type
        or old.image_url is distinct from new.image_url
        or old.media_rights_status is distinct from new.media_rights_status
      );
  end if;

  if should_validate and (
    new.image_url is null
    or new.media_rights_status not in ('original', 'generated', 'licensed')
  ) then
    raise exception using
      errcode = '23514',
      message = 'Published image questions require media and approved rights';
  end if;
  if should_validate and new.image_media_id is not null and not exists (
    select 1
    from public.media_assets as media
    where media.id = new.image_media_id
      and media.status = 'active'
      and media.mime_type in ('image/jpeg', 'image/png', 'image/webp')
      and media.rights_status in ('original', 'generated', 'licensed')
  ) then
    raise exception using
      errcode = '23514',
      message = 'Published question media asset is invalid or unavailable';
  end if;
  return new;
end;
$$;

drop trigger if exists questions_validate_published_media_v5 on public.questions;
create trigger questions_validate_published_media_v5
before insert or update of status, question_type, image_url, image_media_id, media_rights_status
on public.questions
for each row execute function public.validate_published_question_media_v5();

create or replace function public.attach_question_media_v5(
  p_question_id uuid,
  p_media_id uuid,
  p_caption text,
  p_focal_x numeric,
  p_focal_y numeric
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_question public.questions%rowtype;
begin
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Content editor permission required';
  end if;
  if p_focal_x not between 0 and 1 or p_focal_y not between 0 and 1 then
    raise exception using errcode = '22023', message = 'Question focal point must be between 0 and 1';
  end if;
  if not exists (
    select 1
    from public.media_assets as media
    where media.id = p_media_id
      and media.status = 'active'
      and media.mime_type in ('image/jpeg', 'image/png', 'image/webp')
      and media.rights_status in ('original', 'generated', 'licensed')
  ) then
    raise exception using errcode = '23514', message = 'Question media is invalid or lacks approved rights';
  end if;

  select * into target_question
  from public.questions
  where id = p_question_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Question not found';
  end if;
  if target_question.status <> 'draft' then
    raise exception using errcode = '23514', message = 'Only draft question media can be changed here';
  end if;

  update public.questions
  set image_media_id = p_media_id,
      image_caption = nullif(btrim(coalesce(p_caption, '')), ''),
      image_focal_x = p_focal_x,
      image_focal_y = p_focal_y
  where id = p_question_id;
end;
$$;

create or replace view public.category_media_audit
with (security_invoker = true)
as
select
  category.id as category_id,
  category.name_ar,
  category.slug,
  category.is_active,
  category.editorial_status,
  category.cover_media_id,
  category.image_url,
  category.cover_focal_x,
  category.cover_focal_y,
  media.status as media_status,
  media.rights_status,
  media.source_text,
  media.attribution,
  case
    when not category.is_active or category.editorial_status <> 'published' then 'not_published'
    when category.cover_media_id is null or category.image_url is null then 'needs_media'
    when media.id is null then 'missing_asset'
    when media.status <> 'active' then 'archived_asset'
    when media.mime_type not in ('image/jpeg', 'image/png', 'image/webp') then 'invalid_media'
    when media.rights_status not in ('original', 'generated', 'licensed') then 'rights_issue'
    else 'ready'
  end as media_health
from public.categories as category
left join public.media_assets as media on media.id = category.cover_media_id;

create or replace function public.update_category_media_v5(
  p_category_id uuid,
  p_description_ar text,
  p_cover_media_id uuid,
  p_image_url text,
  p_focal_x numeric,
  p_focal_y numeric
)
returns public.categories
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  previous_category public.categories%rowtype;
  updated_category public.categories%rowtype;
  normalized_description text;
begin
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Content editor permission required';
  end if;

  if (p_cover_media_id is null) <> (p_image_url is null) then
    raise exception using errcode = '23514', message = 'Media id and image URL must be provided together';
  end if;
  if p_focal_x not between 0 and 1 or p_focal_y not between 0 and 1 then
    raise exception using errcode = '22023', message = 'Category focal point must be between 0 and 1';
  end if;

  if p_cover_media_id is not null and not exists (
    select 1
    from public.media_assets as media
    where media.id = p_cover_media_id
      and media.status = 'active'
      and media.mime_type in ('image/jpeg', 'image/png', 'image/webp')
      and media.rights_status in ('original', 'generated', 'licensed')
      and media.asset_group in ('categories', 'app-content')
  ) then
    raise exception using errcode = '23514', message = 'Category media is invalid or lacks approved rights';
  end if;

  if p_image_url is not null and (
    char_length(p_image_url) > 2048
    or p_image_url !~ '^https://[^[:space:]]+/storage/v1/object/public/app-content/'
  ) then
    raise exception using errcode = '22023', message = 'Invalid app-content image URL';
  end if;

  normalized_description := nullif(btrim(coalesce(p_description_ar, '')), '');
  if normalized_description is not null and char_length(normalized_description) > 500 then
    raise exception using errcode = '22001', message = 'Category description is too long';
  end if;

  select * into previous_category
  from public.categories
  where id = p_category_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Category not found';
  end if;

  update public.categories
  set description_ar = normalized_description,
      cover_media_id = p_cover_media_id,
      image_url = p_image_url,
      cover_focal_x = p_focal_x,
      cover_focal_y = p_focal_y
  where id = p_category_id
  returning * into updated_category;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
  values (
    auth.uid(), 'category.media_v5_updated', 'category', p_category_id::text,
    jsonb_build_object(
      'description_ar', previous_category.description_ar,
      'cover_media_id', previous_category.cover_media_id,
      'image_url', previous_category.image_url,
      'focal_x', previous_category.cover_focal_x,
      'focal_y', previous_category.cover_focal_y
    ),
    jsonb_build_object(
      'description_ar', updated_category.description_ar,
      'cover_media_id', updated_category.cover_media_id,
      'image_url', updated_category.image_url,
      'focal_x', updated_category.cover_focal_x,
      'focal_y', updated_category.cover_focal_y
    )
  );

  return updated_category;
end;
$$;

revoke all on function public.update_category_media_v5(uuid, text, uuid, text, numeric, numeric) from public;
grant execute on function public.update_category_media_v5(uuid, text, uuid, text, numeric, numeric) to authenticated;
revoke all on function public.attach_question_media_v5(uuid, uuid, text, numeric, numeric) from public;
grant execute on function public.attach_question_media_v5(uuid, uuid, text, numeric, numeric) to authenticated;
grant select on public.category_media_audit to authenticated;
grant select (cover_focal_x, cover_focal_y) on public.categories to anon, authenticated;

