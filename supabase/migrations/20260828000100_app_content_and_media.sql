-- Production-managed application copy and image assets.
-- Existing gameplay tables and rules remain unchanged; this migration only adds
-- optional content references with backward-compatible null/default behavior.

create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null default 'app-content' check (bucket_id = 'app-content'),
  storage_path text not null unique,
  original_filename text not null,
  mime_type text not null check (mime_type in ('image/jpeg', 'image/png', 'image/webp')),
  size_bytes bigint not null check (size_bytes between 1 and 8388608),
  width integer not null check (width between 64 and 6000),
  height integer not null check (height between 64 and 6000),
  alt_text text not null default '' check (char_length(alt_text) <= 160),
  asset_group text not null default 'app-content' check (
    asset_group in ('app-content', 'categories', 'store', 'achievements', 'promotions', 'onboarding')
  ),
  status text not null default 'active' check (status in ('active', 'archived')),
  created_by uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  updated_by uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint media_assets_path_format check (
    storage_path ~ '^(app-content|categories|store|achievements|promotions|onboarding)/[a-zA-Z0-9][a-zA-Z0-9/_-]*\.(jpg|jpeg|png|webp)$'
    and storage_path !~ '(^|/)\.\.(/|$)'
  ),
  constraint media_assets_filename_length check (char_length(original_filename) between 1 and 180)
);

create index media_assets_browse_idx
  on public.media_assets(status, asset_group, updated_at desc);
create index media_assets_created_by_idx
  on public.media_assets(created_by, created_at desc);

create table public.app_content (
  key text primary key,
  section text not null,
  content_type text not null check (content_type in ('text', 'image', 'text_image')),
  label_ar text not null,
  usage_ar text not null,
  default_text_ar text,
  draft_text_ar text,
  published_text_ar text,
  draft_media_id uuid references public.media_assets(id) on delete restrict,
  published_media_id uuid references public.media_assets(id) on delete restrict,
  min_length integer not null default 0 check (min_length between 0 and 500),
  max_length integer not null default 160 check (max_length between 1 and 1000),
  is_active boolean not null default true,
  version integer not null default 0 check (version >= 0),
  draft_updated_by uuid references public.profiles(id) on delete set null,
  published_by uuid references public.profiles(id) on delete set null,
  draft_updated_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint app_content_key_format check (key ~ '^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*){1,4}$'),
  constraint app_content_section_format check (section ~ '^[a-z][a-z0-9_-]{1,39}$'),
  constraint app_content_length_range check (min_length <= max_length),
  constraint app_content_default_length check (
    default_text_ar is null or char_length(default_text_ar) between min_length and max_length
  ),
  constraint app_content_draft_length check (
    draft_text_ar is null or char_length(draft_text_ar) between min_length and max_length
  ),
  constraint app_content_published_length check (
    published_text_ar is null or char_length(published_text_ar) between min_length and max_length
  ),
  constraint app_content_text_default check (
    content_type = 'image' or default_text_ar is not null
  )
);

create index app_content_section_idx on public.app_content(section, key);
create index app_content_published_media_idx
  on public.app_content(published_media_id) where published_media_id is not null;
create index app_content_draft_media_idx
  on public.app_content(draft_media_id) where draft_media_id is not null;

alter table public.categories
  add column cover_media_id uuid references public.media_assets(id) on delete restrict;
alter table public.store_items
  add column image_media_id uuid references public.media_assets(id) on delete restrict;

create index categories_cover_media_idx
  on public.categories(cover_media_id) where cover_media_id is not null;
create index store_items_image_media_idx
  on public.store_items(image_media_id) where image_media_id is not null;

create trigger media_assets_set_updated_at before update on public.media_assets
for each row execute function public.set_updated_at();
create trigger app_content_set_updated_at before update on public.app_content
for each row execute function public.set_updated_at();

insert into public.app_content(
  key, section, content_type, label_ar, usage_ar, default_text_ar,
  draft_text_ar, published_text_ar, min_length, max_length, published_at
)
values
  ('home.hero.title', 'home', 'text', 'عنوان الواجهة الرئيسية', 'العنوان الكبير داخل صورة البداية', 'مستعد تثبت إنك تعرف الكورة؟', 'مستعد تثبت إنك تعرف الكورة؟', 'مستعد تثبت إنك تعرف الكورة؟', 3, 70, now()),
  ('home.hero.subtitle', 'home', 'text', 'وصف الواجهة الرئيسية', 'الشارة المختصرة أعلى عنوان البداية', '15 سؤال • دقايق قليلة', '15 سؤال • دقايق قليلة', '15 سؤال • دقايق قليلة', 3, 80, now()),
  ('home.hero.image', 'home', 'image', 'صورة الواجهة الرئيسية', 'الخلفية البصرية لبطاقة بدء التحدي', null, null, null, 0, 1, now()),
  ('home.featured.title', 'home', 'text', 'عنوان التحدي المميز', 'عنوان بطاقة التحدي اليومية', 'تحدي اليوم', 'تحدي اليوم', 'تحدي اليوم', 3, 50, now()),
  ('home.featured.description', 'home', 'text', 'وصف التحدي المميز', 'الوصف أسفل عنوان التحدي اليومية', '5 أسئلة ومكافأة تنتظرك', '5 أسئلة ومكافأة تنتظرك', '5 أسئلة ومكافأة تنتظرك', 3, 120, now()),
  ('premium.hero.title', 'premium', 'text', 'عنوان Premium', 'عنوان بطاقة الاشتراك في المتجر', '11 Premium', '11 Premium', '11 Premium', 3, 50, now()),
  ('premium.hero.subtitle', 'premium', 'text', 'وصف Premium', 'وصف مزايا الاشتراك في المتجر', 'بدون إعلانات • مزايا تجميلية • إحصائيات أوسع', 'بدون إعلانات • مزايا تجميلية • إحصائيات أوسع', 'بدون إعلانات • مزايا تجميلية • إحصائيات أوسع', 3, 160, now()),
  ('premium.hero.image', 'premium', 'image', 'صورة Premium', 'خلفية بطاقة الاشتراك في المتجر', null, null, null, 0, 1, now()),
  ('store.banner.title', 'store', 'text', 'عنوان بنر المتجر', 'عنوان الحملة الترويجية في المتجر', 'ميّز حسابك', 'ميّز حسابك', 'ميّز حسابك', 3, 60, now()),
  ('store.banner.subtitle', 'store', 'text', 'وصف بنر المتجر', 'النص المختصر للحملة الترويجية', 'عناصر تجميلية بدون أفضلية تنافسية', 'عناصر تجميلية بدون أفضلية تنافسية', 'عناصر تجميلية بدون أفضلية تنافسية', 3, 140, now()),
  ('maintenance.message', 'system', 'text', 'رسالة الصيانة', 'رسالة عامة تظهر فقط عند تفعيل وضع الصيانة', 'نرجع لك قريب، نجهّز الملعب.', 'نرجع لك قريب، نجهّز الملعب.', 'نرجع لك قريب، نجهّز الملعب.', 3, 180, now()),
  ('announcement.title', 'announcements', 'text', 'عنوان الإعلان', 'عنوان الإعلان الموسمي أو العام', 'الجديد في أحدعش', 'الجديد في أحدعش', 'الجديد في أحدعش', 3, 70, now()),
  ('announcement.description', 'announcements', 'text', 'وصف الإعلان', 'النص المختصر للإعلان الموسمي أو العام', 'تابع التحديات والمواسم الجديدة.', 'تابع التحديات والمواسم الجديدة.', 'تابع التحديات والمواسم الجديدة.', 3, 220, now()),
  ('announcement.image', 'announcements', 'image', 'صورة الإعلان', 'الصورة المصاحبة للإعلان العام', null, null, null, 0, 1, now())
on conflict (key) do nothing;

alter table public.media_assets enable row level security;
alter table public.app_content enable row level security;

create policy media_assets_staff_read on public.media_assets
for select to authenticated using (public.has_role('moderator'));
create policy media_assets_staff_insert on public.media_assets
for insert to authenticated with check (
  public.has_role('moderator')
  and created_by = auth.uid()
  and updated_by = auth.uid()
);
create policy media_assets_staff_update on public.media_assets
for update to authenticated using (public.has_role('moderator')) with check (
  public.has_role('moderator') and updated_by = auth.uid()
);

create policy app_content_staff_read on public.app_content
for select to authenticated using (public.has_role('moderator'));

revoke all on public.media_assets, public.app_content from anon, authenticated;
grant select, insert, update, delete on public.media_assets to authenticated;
grant select on public.app_content to authenticated;
grant select (cover_media_id) on public.categories to anon, authenticated;
grant select (image_media_id) on public.store_items to anon, authenticated;

create or replace function public.media_asset_is_used(p_media_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select public.has_role('moderator') and (
    exists (
      select 1 from public.app_content
      where draft_media_id = p_media_id or published_media_id = p_media_id
    )
    or exists (select 1 from public.categories where cover_media_id = p_media_id)
    or exists (select 1 from public.store_items where image_media_id = p_media_id)
  );
$$;

create policy media_assets_staff_delete on public.media_assets
for delete to authenticated using (
  public.has_role('moderator') and not public.media_asset_is_used(id)
);

create or replace function public.get_published_app_content()
returns table (
  content_key text,
  section text,
  content_type text,
  value_ar text,
  media_storage_path text,
  media_alt_text text,
  media_updated_at timestamptz,
  content_version integer,
  published_at timestamptz
)
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select
    content.key,
    content.section,
    content.content_type,
    coalesce(content.published_text_ar, content.default_text_ar),
    media.storage_path,
    media.alt_text,
    media.updated_at,
    content.version,
    content.published_at
  from public.app_content as content
  left join public.media_assets as media
    on media.id = content.published_media_id and media.status = 'active'
  where content.is_active
  order by content.section, content.key;
$$;

create or replace function public.save_app_content_draft(
  p_key text,
  p_value_ar text,
  p_media_id uuid
)
returns public.app_content
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_content public.app_content%rowtype;
  updated_content public.app_content%rowtype;
  normalized_value text;
begin
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Content editor permission required';
  end if;

  select * into target_content
  from public.app_content
  where key = p_key
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Content key not found';
  end if;

  normalized_value := case when p_value_ar is null then null else btrim(p_value_ar) end;

  if target_content.content_type <> 'image' and normalized_value is null then
    raise exception using errcode = '23514', message = 'Text value is required';
  end if;

  if normalized_value is not null and char_length(normalized_value) not between target_content.min_length and target_content.max_length then
    raise exception using errcode = '22001', message = 'Content value length is outside the allowed range';
  end if;

  if p_media_id is not null and not exists (
    select 1 from public.media_assets where id = p_media_id and status = 'active'
  ) then
    raise exception using errcode = '23503', message = 'Media asset not found or archived';
  end if;

  if target_content.content_type = 'text' and p_media_id is not null then
    raise exception using errcode = '23514', message = 'This content key does not accept an image';
  end if;

  update public.app_content
  set draft_text_ar = normalized_value,
      draft_media_id = p_media_id,
      draft_updated_by = auth.uid(),
      draft_updated_at = now()
  where key = p_key
  returning * into updated_content;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
  values (
    auth.uid(), 'app_content.draft_saved', 'app_content', p_key,
    jsonb_build_object('text_ar', target_content.draft_text_ar, 'media_id', target_content.draft_media_id),
    jsonb_build_object('text_ar', updated_content.draft_text_ar, 'media_id', updated_content.draft_media_id)
  );

  return updated_content;
end;
$$;

create or replace function public.reset_app_content_draft(p_key text)
returns public.app_content
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_content public.app_content%rowtype;
  updated_content public.app_content%rowtype;
begin
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Content editor permission required';
  end if;

  select * into target_content
  from public.app_content
  where key = p_key
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Content key not found';
  end if;

  update public.app_content
  set draft_text_ar = default_text_ar,
      draft_media_id = null,
      draft_updated_by = auth.uid(),
      draft_updated_at = now()
  where key = p_key
  returning * into updated_content;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
  values (
    auth.uid(), 'app_content.draft_reset', 'app_content', p_key,
    jsonb_build_object('text_ar', target_content.draft_text_ar, 'media_id', target_content.draft_media_id),
    jsonb_build_object('text_ar', updated_content.draft_text_ar, 'media_id', updated_content.draft_media_id)
  );

  return updated_content;
end;
$$;

create or replace function public.publish_app_content(p_key text)
returns public.app_content
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_content public.app_content%rowtype;
  published_content public.app_content%rowtype;
begin
  if not public.has_role('admin') then
    raise exception using errcode = '42501', message = 'Content publisher permission required';
  end if;

  select * into target_content
  from public.app_content
  where key = p_key
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Content key not found';
  end if;

  if target_content.content_type <> 'image' and target_content.draft_text_ar is null then
    raise exception using errcode = '23514', message = 'A valid draft is required before publishing';
  end if;

  update public.app_content
  set published_text_ar = draft_text_ar,
      published_media_id = draft_media_id,
      published_by = auth.uid(),
      published_at = now(),
      version = version + 1
  where key = p_key
  returning * into published_content;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
  values (
    auth.uid(), 'app_content.published', 'app_content', p_key,
    jsonb_build_object(
      'text_ar', target_content.published_text_ar,
      'media_id', target_content.published_media_id,
      'version', target_content.version
    ),
    jsonb_build_object(
      'text_ar', published_content.published_text_ar,
      'media_id', published_content.published_media_id,
      'version', published_content.version
    )
  );

  return published_content;
end;
$$;

create or replace function public.update_category_content(
  p_category_id uuid,
  p_description_ar text,
  p_cover_media_id uuid,
  p_image_url text
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

  if p_cover_media_id is not null and not exists (
    select 1 from public.media_assets where id = p_cover_media_id and status = 'active'
  ) then
    raise exception using errcode = '23503', message = 'Media asset not found or archived';
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
      image_url = p_image_url
  where id = p_category_id
  returning * into updated_category;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
  values (
    auth.uid(), 'category.content_updated', 'category', p_category_id::text,
    jsonb_build_object('description_ar', previous_category.description_ar, 'cover_media_id', previous_category.cover_media_id, 'image_url', previous_category.image_url),
    jsonb_build_object('description_ar', updated_category.description_ar, 'cover_media_id', updated_category.cover_media_id, 'image_url', updated_category.image_url)
  );

  return updated_category;
end;
$$;

create or replace function public.update_store_item_media(
  p_store_item_id uuid,
  p_image_media_id uuid,
  p_image_url text
)
returns public.store_items
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  previous_item public.store_items%rowtype;
  updated_item public.store_items%rowtype;
begin
  if not public.has_role('admin') then
    raise exception using errcode = '42501', message = 'Administrator permission required';
  end if;

  if (p_image_media_id is null) <> (p_image_url is null) then
    raise exception using errcode = '23514', message = 'Media id and image URL must be provided together';
  end if;

  if p_image_media_id is not null and not exists (
    select 1 from public.media_assets where id = p_image_media_id and status = 'active'
  ) then
    raise exception using errcode = '23503', message = 'Media asset not found or archived';
  end if;

  if p_image_url is not null and (
    char_length(p_image_url) > 2048
    or p_image_url !~ '^https://[^[:space:]]+/storage/v1/object/public/app-content/'
  ) then
    raise exception using errcode = '22023', message = 'Invalid app-content image URL';
  end if;

  select * into previous_item
  from public.store_items
  where id = p_store_item_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Store item not found';
  end if;

  update public.store_items
  set image_media_id = p_image_media_id,
      image_url = p_image_url
  where id = p_store_item_id
  returning * into updated_item;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
  values (
    auth.uid(), 'store_item.media_updated', 'store_item', p_store_item_id::text,
    jsonb_build_object('image_media_id', previous_item.image_media_id, 'image_url', previous_item.image_url),
    jsonb_build_object('image_media_id', updated_item.image_media_id, 'image_url', updated_item.image_url)
  );

  return updated_item;
end;
$$;

create or replace function public.replace_media_asset(
  p_media_id uuid,
  p_storage_path text,
  p_original_filename text,
  p_mime_type text,
  p_size_bytes bigint,
  p_width integer,
  p_height integer,
  p_alt_text text,
  p_asset_group text,
  p_public_url text
)
returns public.media_assets
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  updated_media public.media_assets%rowtype;
begin
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Content editor permission required';
  end if;

  if exists (select 1 from public.store_items where image_media_id = p_media_id)
     and not public.has_role('admin') then
    raise exception using errcode = '42501', message = 'Administrator permission required for store artwork';
  end if;

  if char_length(p_public_url) > 2048
     or p_public_url !~ '^https://[^[:space:]]+/storage/v1/object/public/app-content/' then
    raise exception using errcode = '22023', message = 'Invalid app-content image URL';
  end if;

  update public.media_assets
  set storage_path = p_storage_path,
      original_filename = p_original_filename,
      mime_type = p_mime_type,
      size_bytes = p_size_bytes,
      width = p_width,
      height = p_height,
      alt_text = p_alt_text,
      asset_group = p_asset_group,
      status = 'active',
      updated_by = auth.uid()
  where id = p_media_id
  returning * into updated_media;

  if not found then
    raise exception using errcode = 'P0002', message = 'Media asset not found';
  end if;

  update public.categories
  set image_url = p_public_url
  where cover_media_id = p_media_id;

  update public.store_items
  set image_url = p_public_url
  where image_media_id = p_media_id;

  return updated_media;
end;
$$;

create or replace function public.audit_media_asset_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, new_data)
    values (auth.uid(), 'media_asset.created', 'media_asset', new.id::text, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
    values (auth.uid(), 'media_asset.updated', 'media_asset', new.id::text, to_jsonb(old), to_jsonb(new));
    return new;
  end if;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data)
  values (auth.uid(), 'media_asset.deleted', 'media_asset', old.id::text, to_jsonb(old));
  return old;
end;
$$;

create trigger media_assets_audit
after insert or update or delete on public.media_assets
for each row execute function public.audit_media_asset_change();

create view public.media_asset_usage
with (security_invoker = true)
as
select content.draft_media_id as media_id, 'app_content'::text as usage_type,
       content.key as usage_id, content.label_ar as usage_label, 'draft'::text as usage_state
from public.app_content as content where content.draft_media_id is not null
union all
select content.published_media_id, 'app_content', content.key, content.label_ar, 'published'
from public.app_content as content where content.published_media_id is not null
union all
select category.cover_media_id, 'category', category.id::text, category.name_ar, 'published'
from public.categories as category where category.cover_media_id is not null
union all
select item.image_media_id, 'store_item', item.id::text, item.name_ar, 'published'
from public.store_items as item where item.image_media_id is not null;

grant select on public.media_asset_usage to authenticated;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('app-content', 'app-content', true, 8388608, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy app_content_public_read on storage.objects
for select to anon, authenticated using (bucket_id = 'app-content');
create policy app_content_staff_insert on storage.objects
for insert to authenticated with check (
  bucket_id = 'app-content'
  and public.has_role('moderator')
  and (storage.foldername(name))[1] in ('app-content', 'categories', 'store', 'achievements', 'promotions', 'onboarding')
);
create policy app_content_staff_update on storage.objects
for update to authenticated using (
  bucket_id = 'app-content' and public.has_role('moderator')
) with check (
  bucket_id = 'app-content'
  and public.has_role('moderator')
  and (storage.foldername(name))[1] in ('app-content', 'categories', 'store', 'achievements', 'promotions', 'onboarding')
);
create policy app_content_staff_delete on storage.objects
for delete to authenticated using (
  bucket_id = 'app-content'
  and public.has_role('moderator')
  and not exists (
    select 1
    from public.media_assets as media
    where media.storage_path = name and public.media_asset_is_used(media.id)
  )
);

revoke all on function public.media_asset_is_used(uuid) from public;
revoke all on function public.get_published_app_content() from public;
revoke all on function public.save_app_content_draft(text, text, uuid) from public;
revoke all on function public.reset_app_content_draft(text) from public;
revoke all on function public.publish_app_content(text) from public;
revoke all on function public.update_category_content(uuid, text, uuid, text) from public;
revoke all on function public.update_store_item_media(uuid, uuid, text) from public;
revoke all on function public.replace_media_asset(uuid, text, text, text, bigint, integer, integer, text, text, text) from public;
revoke all on function public.audit_media_asset_change() from public, anon, authenticated;

grant execute on function public.media_asset_is_used(uuid) to authenticated;
grant execute on function public.get_published_app_content() to anon, authenticated;
grant execute on function public.save_app_content_draft(text, text, uuid) to authenticated;
grant execute on function public.reset_app_content_draft(text) to authenticated;
grant execute on function public.publish_app_content(text) to authenticated;
grant execute on function public.update_category_content(uuid, text, uuid, text) to authenticated;
grant execute on function public.update_store_item_media(uuid, uuid, text) to authenticated;
grant execute on function public.replace_media_asset(uuid, text, text, text, bigint, integer, integer, text, text, text) to authenticated;

comment on table public.media_assets is
  'Validated metadata for trusted administrative images stored in the public app-content bucket.';
comment on table public.app_content is
  'Stable, typed remote-copy keys with isolated draft and published states.';
comment on function public.get_published_app_content() is
  'Public read contract that exposes published copy and active media references only; drafts stay private.';
