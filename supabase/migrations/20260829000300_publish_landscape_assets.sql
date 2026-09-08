-- Register the objects uploaded through the linked Supabase CLI and publish
-- their managed application slots. No binary data is stored in PostgreSQL.

with staff as (
  select id
  from public.profiles
  where role in ('moderator', 'admin', 'super_admin') and status = 'active'
  order by case role when 'super_admin' then 1 when 'admin' then 2 else 3 end, created_at
  limit 1
), media_values(
  slot_key, content_key, asset_group, storage_name, original_filename,
  mime_type, size_bytes, width, height, alt_text, rights_status
) as (
  values
    ('auth.login.hero', 'branding.login.artwork', 'branding', 'login-hero.webp', 'login_landscape_v2.webp', 'image/webp', 99362::bigint, 1920, 1080, 'بوابة تسجيل الدخول لأحدعش', 'generated'),
    ('auth.signup.hero', 'auth.signup.hero', 'onboarding', 'signup-hero.webp', 'login_landscape_v2.webp', 'image/webp', 99362::bigint, 1920, 1080, 'بوابة إنشاء حساب أحدعش', 'generated'),
    ('home.hero', 'home.hero.image', 'app-content', 'home-hero.webp', 'home_background.webp', 'image/webp', 34028::bigint, 768, 1152, 'ملعب العب الحين', 'generated'),
    ('play.classic', 'play.classic', 'app-content', 'play-classic.webp', 'classic_mode_art.webp', 'image/webp', 54492::bigint, 720, 720, 'نمط الكلاسيك', 'generated'),
    ('play.truefalse', 'play.truefalse', 'app-content', 'play-truefalse.webp', 'true_false_mode_art.webp', 'image/webp', 53604::bigint, 720, 720, 'نمط صح أو خطأ', 'generated'),
    ('play.speed', 'play.speed', 'app-content', 'play-speed.webp', 'speed_mode_art.webp', 'image/webp', 77034::bigint, 720, 720, 'نمط السرعة', 'generated'),
    ('play.ordering', 'play.ordering', 'app-content', 'play-ordering.webp', 'play_hub_background.webp', 'image/webp', 64078::bigint, 768, 1152, 'نمط رتبهم', 'generated'),
    ('play.clubguess', 'play.clubguess', 'app-content', 'play-clubguess.webp', 'team_patterns.webp', 'image/webp', 57200::bigint, 720, 720, 'نمط من النادي', 'generated'),
    ('play.eagleeye', 'play.eagleeye', 'app-content', 'play-eagleeye.png', 'eagle-eye-cover.png', 'image/png', 2011157::bigint, 1122, 1402, 'نمط عين الصقر', 'generated'),
    ('premium.hero', 'premium.hero.image', 'branding', 'premium-hero.webp', 'premium_landscape_v2.webp', 'image/webp', 111606::bigint, 1920, 1080, 'هوية أحدعش بريميوم', 'generated'),
    ('team.empty', 'team.empty', 'app-content', 'team-empty.webp', 'team_background.webp', 'image/webp', 85658::bigint, 768, 1152, 'حالة الفريق الفارغة', 'generated'),
    ('friends.empty', 'friends.empty', 'app-content', 'friends-empty.webp', 'player11_cosmetics.webp', 'image/webp', 35530::bigint, 720, 720, 'حالة ربعك الفارغة', 'generated'),
    ('challenge.empty', 'challenge.empty', 'app-content', 'challenge-empty.webp', 'speed_mode_art.webp', 'image/webp', 77034::bigint, 720, 720, 'حالة التحديات الفارغة', 'generated'),
    ('profile.background', 'profile.background', 'app-content', 'profile-background.webp', 'profile_background.webp', 'image/webp', 40084::bigint, 768, 1152, 'خلفية الملف الشخصي', 'generated')
)
insert into public.media_assets(
  id, bucket_id, storage_path, original_filename, mime_type, size_bytes,
  width, height, alt_text, asset_group, status, created_by, updated_by,
  slot_key, rights_status, version
)
select
  md5('ahdash11:media:' || media.slot_key)::uuid,
  'app-content',
  'app-content/landscape-2026-27/' || media.storage_name,
  media.original_filename, media.mime_type, media.size_bytes,
  media.width, media.height, media.alt_text, media.asset_group,
  'active', staff.id, staff.id, media.slot_key, media.rights_status, 1
from media_values media
cross join staff
on conflict (storage_path) do update set
  original_filename = excluded.original_filename,
  mime_type = excluded.mime_type,
  size_bytes = excluded.size_bytes,
  width = excluded.width,
  height = excluded.height,
  alt_text = excluded.alt_text,
  asset_group = excluded.asset_group,
  status = 'active',
  updated_by = excluded.updated_by,
  slot_key = excluded.slot_key,
  rights_status = excluded.rights_status;

with mappings(slot_key, content_key) as (
  values
    ('auth.login.hero', 'branding.login.artwork'),
    ('auth.signup.hero', 'auth.signup.hero'),
    ('home.hero', 'home.hero.image'),
    ('play.classic', 'play.classic'),
    ('play.truefalse', 'play.truefalse'),
    ('play.speed', 'play.speed'),
    ('play.ordering', 'play.ordering'),
    ('play.clubguess', 'play.clubguess'),
    ('play.eagleeye', 'play.eagleeye'),
    ('premium.hero', 'premium.hero.image'),
    ('team.empty', 'team.empty'),
    ('friends.empty', 'friends.empty'),
    ('challenge.empty', 'challenge.empty'),
    ('profile.background', 'profile.background')
), staff as (
  select id from public.profiles
  where role in ('moderator', 'admin', 'super_admin') and status = 'active'
  order by case role when 'super_admin' then 1 when 'admin' then 2 else 3 end, created_at
  limit 1
)
update public.app_content content
set draft_media_id = media.id,
    published_media_id = media.id,
    draft_updated_by = staff.id,
    published_by = staff.id,
    draft_updated_at = clock_timestamp(),
    published_at = clock_timestamp(),
    version = greatest(content.version + 1, media.version),
    is_active = true
from mappings mapping
join public.media_assets media
  on media.slot_key = mapping.slot_key and media.status = 'active'
cross join staff
where content.key = mapping.content_key;

create or replace function public.landscape_visual_asset_counts()
returns table(uploaded_count bigint, published_count bigint, slot_count bigint)
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select
    count(distinct media.id),
    count(distinct content.published_media_id),
    count(distinct media.slot_key)
  from public.media_assets media
  left join public.app_content content on content.published_media_id = media.id
  where media.storage_path like 'app-content/landscape-2026-27/%';
$$;

revoke all on function public.landscape_visual_asset_counts() from public;
grant execute on function public.landscape_visual_asset_counts() to anon, authenticated;
