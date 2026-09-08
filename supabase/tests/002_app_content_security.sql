begin;

create extension if not exists pgtap with schema extensions;
select plan(26);

select has_table('public', 'media_assets', 'media asset metadata exists');
select has_table('public', 'app_content', 'managed application content exists');
select has_view('public', 'media_asset_usage', 'staff can inspect media usage');

select ok(
  (select relrowsecurity from pg_class where oid = 'public.media_assets'::regclass),
  'media assets have RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.app_content'::regclass),
  'application content has RLS enabled'
);

select has_column('public', 'categories', 'cover_media_id', 'categories can reference managed covers');
select has_column('public', 'store_items', 'image_media_id', 'store items can reference managed artwork');

select is(
  has_table_privilege('anon', 'public.app_content', 'SELECT'),
  false,
  'anonymous clients cannot read the table that contains drafts'
);
select is(
  has_table_privilege('anon', 'public.media_assets', 'SELECT'),
  false,
  'anonymous clients cannot enumerate media metadata'
);
select is(
  has_table_privilege('authenticated', 'public.app_content', 'INSERT'),
  false,
  'authenticated clients cannot insert arbitrary content keys'
);
select is(
  has_table_privilege('authenticated', 'public.app_content', 'SELECT'),
  true,
  'authenticated staff can reach the content table subject to RLS'
);

select is(
  has_function_privilege('anon', 'public.get_published_app_content()', 'EXECUTE'),
  true,
  'anonymous clients can read the safe published content contract'
);
select is(
  has_function_privilege('authenticated', 'public.get_published_app_content()', 'EXECUTE'),
  true,
  'signed-in clients can read the safe published content contract'
);
select is(
  has_function_privilege('authenticated', 'public.save_app_content_draft(text,text,uuid)', 'EXECUTE'),
  true,
  'authenticated staff can reach the draft RPC whose body enforces editor role'
);
select is(
  has_function_privilege('anon', 'public.save_app_content_draft(text,text,uuid)', 'EXECUTE'),
  false,
  'anonymous clients cannot save drafts'
);
select is(
  has_function_privilege('authenticated', 'public.publish_app_content(text)', 'EXECUTE'),
  true,
  'authenticated admins can reach the publish RPC whose body enforces admin role'
);
select is(
  has_function_privilege('anon', 'public.publish_app_content(text)', 'EXECUTE'),
  false,
  'anonymous clients cannot publish content'
);
select is(
  has_function_privilege('authenticated', 'public.audit_media_asset_change()', 'EXECUTE'),
  false,
  'clients cannot invoke the media audit trigger as an RPC'
);

select ok(
  exists (select 1 from storage.buckets where id = 'app-content'),
  'the app-content storage bucket exists'
);
select is(
  (select public from storage.buckets where id = 'app-content'),
  true,
  'published application images are publicly readable'
);
select is(
  (select file_size_limit from storage.buckets where id = 'app-content'),
  8388608::bigint,
  'the bucket rejects images larger than eight megabytes'
);
select is(
  (select allowed_mime_types from storage.buckets where id = 'app-content'),
  array['image/jpeg', 'image/png', 'image/webp']::text[],
  'the bucket accepts only the supported raster formats'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'app_content_staff_insert'
  ),
  'storage upload policy is installed'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'app_content_staff_delete'
  ),
  'storage delete policy checks role and usage'
);

select ok(
  exists (select 1 from public.app_content where key = 'home.hero.title'),
  'stable home content keys are seeded'
);
select is(
  (
    select value_ar from public.get_published_app_content()
    where content_key = 'home.hero.title'
  ),
  'مستعد تثبت إنك تعرف الكورة؟',
  'the public contract returns published/default copy without requiring admin setup'
);

select * from finish();
rollback;
