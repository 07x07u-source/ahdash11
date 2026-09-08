-- Landscape/Premium/football 2026-27. Existing economy remains legacy; no destructive drops.

alter table public.media_assets
  add column if not exists slot_key text,
  add column if not exists rights_status text not null default 'original',
  add column if not exists version integer not null default 1;

alter table public.media_assets
  add constraint media_assets_slot_key_format check (slot_key is null or slot_key ~ '^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*){1,4}$'),
  add constraint media_assets_rights_status check (rights_status in ('original', 'generated', 'licensed')),
  add constraint media_assets_version_positive check (version > 0);

create index if not exists media_assets_slot_idx
  on public.media_assets(slot_key, status, version desc) where slot_key is not null;

create or replace function public.bump_media_asset_version()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if new.storage_path is distinct from old.storage_path
     or new.status is distinct from old.status
     or new.slot_key is distinct from old.slot_key
     or new.rights_status is distinct from old.rights_status then
    new.version := old.version + 1;
  end if;
  return new;
end;
$$;

create trigger media_assets_bump_version
before update of storage_path, status, slot_key, rights_status on public.media_assets
for each row execute function public.bump_media_asset_version();

insert into public.app_content(
  key, section, content_type, label_ar, usage_ar, default_text_ar,
  min_length, max_length, published_at
)
values
  ('auth.login.hero', 'auth', 'image', 'صورة تسجيل الدخول', 'الصورة الرئيسية في شاشة الدخول', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('auth.signup.hero', 'auth', 'image', 'صورة إنشاء الحساب', 'الصورة الرئيسية في إنشاء الحساب', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('home.hero', 'home', 'image', 'صورة اللعب الرئيسية', 'خلفية العب الحين', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('play.classic', 'play', 'image', 'الكلاسيك', 'صورة نمط الكلاسيك', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('play.truefalse', 'play', 'image', 'صح أو خطأ', 'صورة نمط صح أو خطأ', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('play.speed', 'play', 'image', 'السرعة', 'صورة نمط السرعة', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('play.ordering', 'play', 'image', 'رتبهم', 'صورة نمط الترتيب', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('play.clubguess', 'play', 'image', 'من النادي', 'صورة تخمين النادي', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('play.eagleeye', 'play', 'image', 'عين الصقر', 'صورة عين الصقر', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('premium.hero', 'premium', 'image', 'صورة بريميوم', 'الخلفية الرئيسية للاشتراك', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('team.empty', 'team', 'image', 'فريق فارغ', 'حالة عدم وجود فريق', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('friends.empty', 'social', 'image', 'ربعك فارغة', 'حالة عدم وجود أصدقاء', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('challenge.empty', 'challenge', 'image', 'تحديات فارغة', 'حالة عدم وجود تحديات', '', '0', '1', '2026-08-29T00:00:00+03:00'),
  ('profile.background', 'profile', 'image', 'خلفية الملف', 'خلفية بطاقة اللاعب', '', '0', '1', '2026-08-29T00:00:00+03:00')
on conflict (key) do update set
  label_ar = excluded.label_ar,
  usage_ar = excluded.usage_ar,
  is_active = true;

alter table public.football_leagues
  add column if not exists season text not null default '2026/27',
  add column if not exists source_url text,
  add column if not exists source_checked_at timestamptz,
  add column if not exists logo_rights_status text not null default 'fallback';

alter table public.football_clubs
  add column if not exists season text not null default '2026/27',
  add column if not exists source_url text,
  add column if not exists source_checked_at timestamptz,
  add column if not exists logo_rights_status text not null default 'fallback';

update public.football_leagues
set logo_rights_status = visual_status
where logo_rights_status is distinct from visual_status;
update public.football_clubs
set logo_rights_status = visual_status
where logo_rights_status is distinct from visual_status;

alter table public.football_leagues
  add constraint football_leagues_logo_rights_status check (logo_rights_status in ('fallback', 'custom', 'licensed')),
  add constraint football_leagues_rights_consistent check (logo_rights_status = visual_status);
alter table public.football_clubs
  add constraint football_clubs_logo_rights_status check (logo_rights_status in ('fallback', 'custom', 'licensed')),
  add constraint football_clubs_rights_consistent check (logo_rights_status = visual_status);

insert into public.football_countries(
  id, provider_name, provider_id, code, name_ar, name_en,
  is_featured, is_active, sort_order, last_synced_at
)
values
  ('00000000-0000-4000-8000-000000000001', 'official-2026-27', 'sa', 'SA', 'السعودية', 'Saudi Arabia', 'true', 'true', '1', '2026-08-29T00:00:00+03:00'),
  ('00000000-0000-4000-8000-000000000002', 'official-2026-27', 'gb', 'GB', 'إنجلترا', 'England', 'true', 'true', '2', '2026-08-29T00:00:00+03:00'),
  ('00000000-0000-4000-8000-000000000003', 'official-2026-27', 'es', 'ES', 'إسبانيا', 'Spain', 'true', 'true', '3', '2026-08-29T00:00:00+03:00'),
  ('00000000-0000-4000-8000-000000000004', 'official-2026-27', 'it', 'IT', 'إيطاليا', 'Italy', 'true', 'true', '4', '2026-08-29T00:00:00+03:00'),
  ('00000000-0000-4000-8000-000000000005', 'official-2026-27', 'de', 'DE', 'ألمانيا', 'Germany', 'true', 'true', '5', '2026-08-29T00:00:00+03:00'),
  ('00000000-0000-4000-8000-000000000006', 'official-2026-27', 'fr', 'FR', 'فرنسا', 'France', 'true', 'true', '6', '2026-08-29T00:00:00+03:00')
on conflict (code) do update set
  provider_name = excluded.provider_name,
  provider_id = excluded.provider_id,
  name_ar = excluded.name_ar,
  name_en = excluded.name_en,
  is_featured = true,
  is_active = true,
  sort_order = excluded.sort_order,
  last_synced_at = excluded.last_synced_at;

with league_values(provider_id, country_code, name_ar, name_en, short_name, primary_color, secondary_color, source_url, sort_order) as (
  values
  ('saudi-pro', 'SA', 'دوري روشن السعودي', 'Saudi Pro League', 'RSL', '#006C35', '#D9B45D', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures', '1'),
  ('premier-league', 'GB', 'الدوري الإنجليزي الممتاز', 'Premier League', 'PL', '#3D195B', '#00FF85', 'https://www.premierleague.com/en/managers', '2'),
  ('laliga', 'ES', 'الدوري الإسباني', 'LALIGA EA SPORTS', 'LALIGA', '#17202A', '#FF4B44', 'https://www.laliga.com/laliga-easports/clubes', '3'),
  ('serie-a', 'IT', 'الدوري الإيطالي', 'Serie A', 'SERIE A', '#0057B8', '#FFFFFF', 'https://www.legaseriea.it/team/index', '4'),
  ('bundesliga', 'DE', 'الدوري الألماني', 'Bundesliga', 'BUNDES', '#D20515', '#FFFFFF', 'https://www.bundesliga.com/en/bundesliga/table/', '5'),
  ('ligue-1', 'FR', 'الدوري الفرنسي', 'Ligue 1', 'L1', '#0A0A2A', '#D9FF00', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released', '6')
)
insert into public.football_leagues(
  id, country_id, provider_name, provider_id, name_ar, name_en, short_name,
  visual_status, logo_url, license_reference, primary_color, secondary_color,
  is_featured, is_active, sort_order, last_synced_at, season, source_url,
  source_checked_at, logo_rights_status
)
select
  md5('ahdash11:league:' || data.provider_id)::uuid,
  country.id,
  'official-2026-27', data.provider_id, data.name_ar, data.name_en,
  data.short_name, 'fallback', null, null, data.primary_color,
  data.secondary_color, true, true, data.sort_order::integer, '2026-08-29T00:00:00+03:00',
  '2026/27', data.source_url, '2026-08-29T00:00:00+03:00', 'fallback'
from league_values data
join public.football_countries country on country.code = data.country_code
on conflict (provider_name, provider_id) do update set
  country_id = excluded.country_id,
  name_ar = excluded.name_ar,
  name_en = excluded.name_en,
  short_name = excluded.short_name,
  primary_color = excluded.primary_color,
  secondary_color = excluded.secondary_color,
  is_featured = true,
  is_active = true,
  sort_order = excluded.sort_order,
  last_synced_at = excluded.last_synced_at,
  season = excluded.season,
  source_url = excluded.source_url,
  source_checked_at = excluded.source_checked_at,
  visual_status = 'fallback',
  logo_url = null,
  license_reference = null,
  logo_rights_status = 'fallback';

with club_values(league_provider_id, provider_id, name_ar, name_en, short_name, primary_color, secondary_color, sort_order, source_url) as (
  values
  ('saudi-pro', 'hilal', 'الهلال', 'Al Hilal', 'HIL', '#2454B8', '#FFFFFF', '1', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'nassr', 'النصر', 'Al Nassr', 'NAS', '#F4CF31', '#173B74', '2', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'ahli', 'الأهلي', 'Al Ahli', 'AHL', '#198B59', '#FFFFFF', '3', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'qadsiah', 'القادسية', 'Al Qadsiah', 'QAD', '#B51F32', '#F0C75E', '4', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'ittihad', 'الاتحاد', 'Al Ittihad', 'ITT', '#1E1E1E', '#F4CF31', '5', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'taawoun', 'التعاون', 'Al Taawoun', 'TAA', '#F4CF31', '#173B74', '6', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'ettifaq', 'الاتفاق', 'Al Ettifaq', 'ETT', '#B51F32', '#2E7D4F', '7', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'fateh', 'الفتح', 'Al Fateh', 'FAT', '#1D78B5', '#2E7D4F', '8', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'khaleej', 'الخليج', 'Al Khaleej', 'KHA', '#F1B52B', '#1F6A4D', '9', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'shabab', 'الشباب', 'Al Shabab', 'SHB', '#F5F5F5', '#1E1E1E', '10', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'neom', 'نيوم', 'NEOM SC', 'NEO', '#342E7A', '#5FD1C8', '11', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'hazem', 'الحزم', 'Al Hazem', 'HAZ', '#D7AE35', '#1E1E1E', '12', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'fayha', 'الفيحاء', 'Al Fayha', 'FAY', '#E36A2E', '#6B3C92', '13', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'kholood', 'الخلود', 'Al Kholood', 'KHO', '#1C5C9E', '#D4A83A', '14', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'riyadh', 'الرياض', 'Al Riyadh', 'RIY', '#B51F32', '#1E1E1E', '15', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'abha', 'أبها', 'Abha', 'ABH', '#2454B8', '#B51F32', '16', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'faisaly', 'الفيصلي', 'Al Faisaly', 'FAI', '#7B1F2B', '#F5F5F5', '17', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('saudi-pro', 'diriyah', 'الدرعية', 'Diriyah Club', 'DIR', '#7D5A34', '#D8B16B', '18', 'https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures'),
  ('premier-league', 'arsenal', 'أرسنال', 'Arsenal', 'ARS', '#B51F32', '#F5F5F5', '1', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'aston-villa', 'أستون فيلا', 'Aston Villa', 'AVL', '#6B2949', '#85B9D8', '2', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'bournemouth', 'بورنموث', 'Bournemouth', 'BOU', '#B51F32', '#1E1E1E', '3', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'brentford', 'برينتفورد', 'Brentford', 'BRE', '#B51F32', '#F5F5F5', '4', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'brighton', 'برايتون', 'Brighton', 'BHA', '#2454B8', '#F5F5F5', '5', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'chelsea', 'تشيلسي', 'Chelsea', 'CHE', '#2454B8', '#F5F5F5', '6', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'coventry', 'كوفنتري سيتي', 'Coventry City', 'COV', '#58A7D8', '#F5F5F5', '7', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'crystal-palace', 'كريستال بالاس', 'Crystal Palace', 'CRY', '#2454B8', '#B51F32', '8', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'everton', 'إيفرتون', 'Everton', 'EVE', '#2454B8', '#F5F5F5', '9', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'fulham', 'فولهام', 'Fulham', 'FUL', '#F5F5F5', '#1E1E1E', '10', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'hull', 'هال سيتي', 'Hull City', 'HUL', '#E5962D', '#1E1E1E', '11', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'ipswich', 'إيبسويتش تاون', 'Ipswich Town', 'IPS', '#2454B8', '#F5F5F5', '12', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'leeds', 'ليدز يونايتد', 'Leeds United', 'LEE', '#F5F5F5', '#2454B8', '13', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'liverpool', 'ليفربول', 'Liverpool', 'LIV', '#B51F32', '#F5F5F5', '14', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'man-city', 'مانشستر سيتي', 'Manchester City', 'MCI', '#85B9D8', '#F5F5F5', '15', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'man-utd', 'مانشستر يونايتد', 'Manchester United', 'MUN', '#B51F32', '#1E1E1E', '16', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'newcastle', 'نيوكاسل يونايتد', 'Newcastle United', 'NEW', '#1E1E1E', '#F5F5F5', '17', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'nottingham-forest', 'نوتنغهام فورست', 'Nottingham Forest', 'NFO', '#B51F32', '#F5F5F5', '18', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'sunderland', 'سندرلاند', 'Sunderland', 'SUN', '#B51F32', '#F5F5F5', '19', 'https://www.premierleague.com/en/managers'),
  ('premier-league', 'tottenham', 'توتنهام هوتسبير', 'Tottenham Hotspur', 'TOT', '#F5F5F5', '#1E3158', '20', 'https://www.premierleague.com/en/managers'),
  ('laliga', 'athletic', 'أتلتيك بلباو', 'Athletic Club', 'ATH', '#B51F32', '#F5F5F5', '1', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'atletico', 'أتلتيكو مدريد', 'Atletico de Madrid', 'ATM', '#B51F32', '#2454B8', '2', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'osasuna', 'أوساسونا', 'CA Osasuna', 'OSA', '#B51F32', '#1E3158', '3', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'celta', 'سيلتا فيغو', 'Celta', 'CEL', '#85B9D8', '#B51F32', '4', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'alaves', 'ديبورتيفو ألافيس', 'Deportivo Alaves', 'ALA', '#2454B8', '#F5F5F5', '5', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'elche', 'إلتشي', 'Elche CF', 'ELC', '#F5F5F5', '#2E7D4F', '6', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'barcelona', 'برشلونة', 'FC Barcelona', 'BAR', '#283A78', '#9F273E', '7', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'getafe', 'خيتافي', 'Getafe CF', 'GET', '#2454B8', '#F5F5F5', '8', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'levante', 'ليفانتي', 'Levante UD', 'LEV', '#B51F32', '#2454B8', '9', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'malaga', 'مالقة', 'Malaga CF', 'MGA', '#58A7D8', '#F5F5F5', '10', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'racing', 'راسينغ سانتاندير', 'Racing Club', 'RAC', '#2E7D4F', '#F5F5F5', '11', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'deportivo', 'ديبورتيفو لاكورونيا', 'RC Deportivo', 'DEP', '#2454B8', '#F5F5F5', '12', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'espanyol', 'إسبانيول', 'RCD Espanyol', 'ESP', '#2454B8', '#F5F5F5', '13', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'betis', 'ريال بيتيس', 'Real Betis', 'BET', '#2E7D4F', '#F5F5F5', '14', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'real-madrid', 'ريال مدريد', 'Real Madrid', 'RMA', '#F5F5F5', '#D5B35A', '15', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'real-sociedad', 'ريال سوسيداد', 'Real Sociedad', 'RSO', '#2454B8', '#F5F5F5', '16', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'sevilla', 'إشبيلية', 'Sevilla FC', 'SEV', '#F5F5F5', '#B51F32', '17', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'valencia', 'فالنسيا', 'Valencia CF', 'VAL', '#F5F5F5', '#1E1E1E', '18', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'villarreal', 'فياريال', 'Villarreal CF', 'VIL', '#E9D43B', '#2454B8', '19', 'https://www.laliga.com/laliga-easports/clubes'),
  ('laliga', 'rayo', 'رايو فايكانو', 'Rayo Vallecano', 'RAY', '#F5F5F5', '#B51F32', '20', 'https://www.laliga.com/laliga-easports/clubes'),
  ('serie-a', 'atalanta', 'أتالانتا', 'Atalanta', 'ATA', '#2454B8', '#1E1E1E', '1', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'bologna', 'بولونيا', 'Bologna', 'BOL', '#9F273E', '#1E3158', '2', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'cagliari', 'كالياري', 'Cagliari', 'CAG', '#9F273E', '#1E3158', '3', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'como', 'كومو', 'Como', 'COM', '#2454B8', '#F5F5F5', '4', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'fiorentina', 'فيورنتينا', 'Fiorentina', 'FIO', '#6B3C92', '#F5F5F5', '5', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'frosinone', 'فروزينوني', 'Frosinone', 'FRO', '#E9D43B', '#2454B8', '6', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'genoa', 'جنوى', 'Genoa', 'GEN', '#9F273E', '#1E3158', '7', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'inter', 'إنتر ميلان', 'Internazionale', 'INT', '#2454B8', '#1E1E1E', '8', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'juventus', 'يوفنتوس', 'Juventus', 'JUV', '#F5F5F5', '#1E1E1E', '9', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'lazio', 'لاتسيو', 'Lazio', 'LAZ', '#85B9D8', '#F5F5F5', '10', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'lecce', 'ليتشي', 'Lecce', 'LEC', '#E9D43B', '#B51F32', '11', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'milan', 'ميلان', 'Milan', 'MIL', '#B51F32', '#1E1E1E', '12', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'monza', 'مونزا', 'Monza', 'MON', '#B51F32', '#F5F5F5', '13', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'napoli', 'نابولي', 'Napoli', 'NAP', '#58A7D8', '#F5F5F5', '14', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'parma', 'بارما', 'Parma', 'PAR', '#E9D43B', '#2454B8', '15', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'roma', 'روما', 'Roma', 'ROM', '#7B1F2B', '#D8A43A', '16', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'sassuolo', 'ساسولو', 'Sassuolo', 'SAS', '#2E7D4F', '#1E1E1E', '17', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'torino', 'تورينو', 'Torino', 'TOR', '#7B1F2B', '#F5F5F5', '18', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'udinese', 'أودينيزي', 'Udinese', 'UDI', '#F5F5F5', '#1E1E1E', '19', 'https://www.legaseriea.it/team/index'),
  ('serie-a', 'venezia', 'فينيتسيا', 'Venezia', 'VEN', '#E5962D', '#1E1E1E', '20', 'https://www.legaseriea.it/team/index'),
  ('bundesliga', 'bayern', 'بايرن ميونخ', 'Bayern Munich', 'FCB', '#B51F32', '#F5F5F5', '1', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'augsburg', 'أوغسبورغ', 'Augsburg', 'FCA', '#B51F32', '#2E7D4F', '2', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'bremen', 'فيردر بريمن', 'Werder Bremen', 'SVW', '#2E7D4F', '#F5F5F5', '3', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'dortmund', 'بوروسيا دورتموند', 'Borussia Dortmund', 'BVB', '#E9D43B', '#1E1E1E', '4', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'elversberg', 'إلفرسبرغ', 'Elversberg', 'ELV', '#F5F5F5', '#1E1E1E', '5', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'frankfurt', 'آينتراخت فرانكفورت', 'Eintracht Frankfurt', 'SGE', '#B51F32', '#1E1E1E', '6', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'freiburg', 'فرايبورغ', 'Freiburg', 'SCF', '#B51F32', '#1E1E1E', '7', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'hamburg', 'هامبورغ', 'Hamburg', 'HSV', '#2454B8', '#F5F5F5', '8', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'hoffenheim', 'هوفنهايم', 'Hoffenheim', 'TSG', '#2454B8', '#F5F5F5', '9', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'cologne', 'كولن', 'Cologne', 'KOE', '#F5F5F5', '#B51F32', '10', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'leipzig', 'لايبزيغ', 'RB Leipzig', 'RBL', '#F5F5F5', '#B51F32', '11', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'leverkusen', 'باير ليفركوزن', 'Bayer Leverkusen', 'B04', '#B51F32', '#1E1E1E', '12', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'gladbach', 'بوروسيا مونشنغلادباخ', 'Borussia Monchengladbach', 'BMG', '#F5F5F5', '#1E1E1E', '13', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'mainz', 'ماينتس', 'Mainz', 'M05', '#B51F32', '#F5F5F5', '14', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'paderborn', 'بادربورن', 'Paderborn', 'SCP', '#2454B8', '#1E1E1E', '15', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'schalke', 'شالكه', 'Schalke', 'S04', '#2454B8', '#F5F5F5', '16', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'union-berlin', 'يونيون برلين', 'Union Berlin', 'FCU', '#B51F32', '#F5F5F5', '17', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('bundesliga', 'stuttgart', 'شتوتغارت', 'VfB Stuttgart', 'VFB', '#F5F5F5', '#B51F32', '18', 'https://www.bundesliga.com/en/bundesliga/table/'),
  ('ligue-1', 'angers', 'أنجيه', 'Angers SCO', 'SCO', '#1E1E1E', '#F5F5F5', '1', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'auxerre', 'أوكسير', 'AJ Auxerre', 'AJA', '#2454B8', '#F5F5F5', '2', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'brest', 'بريست', 'Stade Brestois 29', 'BRE', '#B51F32', '#F5F5F5', '3', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'le-havre', 'لوهافر', 'Havre AC', 'HAC', '#58A7D8', '#1E3158', '4', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'lens', 'لانس', 'RC Lens', 'RCL', '#B51F32', '#E9D43B', '5', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'lille', 'ليل', 'LOSC', 'LIL', '#B51F32', '#1E3158', '6', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'lorient', 'لوريان', 'FC Lorient', 'FCL', '#E5962D', '#1E1E1E', '7', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'lyon', 'ليون', 'Olympique Lyonnais', 'OL', '#F5F5F5', '#2454B8', '8', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'le-mans', 'لو مان', 'Le Mans FC', 'LM', '#B51F32', '#E9D43B', '9', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'marseille', 'مارسيليا', 'Olympique de Marseille', 'OM', '#58A7D8', '#F5F5F5', '10', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'monaco', 'موناكو', 'AS Monaco', 'ASM', '#B51F32', '#F5F5F5', '11', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'nice', 'نيس', 'OGC Nice', 'NIC', '#B51F32', '#1E1E1E', '12', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'paris-fc', 'باريس إف سي', 'Paris FC', 'PFC', '#2454B8', '#58A7D8', '13', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'psg', 'باريس سان جيرمان', 'Paris Saint-Germain', 'PSG', '#1E3158', '#B51F32', '14', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'rennes', 'رين', 'Stade Rennais FC', 'REN', '#B51F32', '#1E1E1E', '15', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'strasbourg', 'ستراسبورغ', 'RC Strasbourg Alsace', 'RCS', '#2454B8', '#F5F5F5', '16', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'toulouse', 'تولوز', 'Toulouse FC', 'TFC', '#6B3C92', '#F5F5F5', '17', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released'),
  ('ligue-1', 'troyes', 'تروا', 'ESTAC Troyes', 'EST', '#2454B8', '#F5F5F5', '18', 'https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released')
)
insert into public.football_clubs(
  id, league_id, provider_name, provider_id, name_ar, name_en, short_name,
  visual_status, logo_url, license_reference, primary_color, secondary_color,
  is_active, sort_order, last_synced_at, season, source_url,
  source_checked_at, logo_rights_status
)
select
  md5('ahdash11:club:' || data.league_provider_id || ':' || data.provider_id)::uuid,
  league.id, 'official-2026-27', data.league_provider_id || ':' || data.provider_id,
  data.name_ar, data.name_en, data.short_name, 'fallback', null, null,
  data.primary_color, data.secondary_color, true, data.sort_order::integer,
  '2026-08-29T00:00:00+03:00', '2026/27', data.source_url, '2026-08-29T00:00:00+03:00', 'fallback'
from club_values data
join public.football_leagues league
  on league.provider_name = 'official-2026-27'
 and league.provider_id = data.league_provider_id
on conflict (provider_name, provider_id) do update set
  league_id = excluded.league_id,
  name_ar = excluded.name_ar,
  name_en = excluded.name_en,
  short_name = excluded.short_name,
  primary_color = excluded.primary_color,
  secondary_color = excluded.secondary_color,
  is_active = true,
  sort_order = excluded.sort_order,
  last_synced_at = excluded.last_synced_at,
  season = excluded.season,
  source_url = excluded.source_url,
  source_checked_at = excluded.source_checked_at,
  visual_status = 'fallback',
  logo_url = null,
  license_reference = null,
  logo_rights_status = 'fallback';

update public.football_clubs club
set is_active = false
from public.football_leagues league
where club.league_id = league.id
  and league.provider_name = 'official-2026-27'
  and club.provider_name is distinct from 'official-2026-27';

comment on table public.wallets is
  'Legacy compatibility ledger. Coins are deprecated from the client experience as of the Landscape Premium release.';
comment on table public.wallet_transactions is
  'Legacy compatibility history. New player rewards use XP, achievements, levels and ranks.';
comment on table public.store_items is
  'Legacy cosmetic catalog retained for compatibility. The client entry point is now Premium/Customization.';

create or replace function public.football_catalog_2026_27_counts()
returns table(league_key text, league_name_ar text, club_count bigint)
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select league.provider_id, league.name_ar, count(club.id)
  from public.football_leagues league
  left join public.football_clubs club
    on club.league_id = league.id and club.is_active and club.season = '2026/27'
  where league.provider_name = 'official-2026-27'
    and league.is_active and league.season = '2026/27'
  group by league.provider_id, league.name_ar, league.sort_order
  order by league.sort_order;
$$;

revoke all on function public.football_catalog_2026_27_counts() from public;
grant execute on function public.football_catalog_2026_27_counts() to anon, authenticated;
