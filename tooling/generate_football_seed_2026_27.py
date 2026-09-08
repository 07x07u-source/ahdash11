from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "supabase/migrations/20260829000200_landscape_premium_football.sql"
DOC = ROOT / "docs/football-data-sources-2026-27.md"

CHECKED = "2026-08-29T00:00:00+03:00"

leagues = [
    ("saudi-pro", "SA", "دوري روشن السعودي", "Saudi Pro League", "RSL", "#006C35", "#D9B45D", "https://www.spl.com.sa/ar/news/spl-announces-roshn-saudi-league-2026-2027-fixtures"),
    ("premier-league", "GB", "الدوري الإنجليزي الممتاز", "Premier League", "PL", "#3D195B", "#00FF85", "https://www.premierleague.com/en/managers"),
    ("laliga", "ES", "الدوري الإسباني", "LALIGA EA SPORTS", "LALIGA", "#17202A", "#FF4B44", "https://www.laliga.com/laliga-easports/clubes"),
    ("serie-a", "IT", "الدوري الإيطالي", "Serie A", "SERIE A", "#0057B8", "#FFFFFF", "https://www.legaseriea.it/team/index"),
    ("bundesliga", "DE", "الدوري الألماني", "Bundesliga", "BUNDES", "#D20515", "#FFFFFF", "https://www.bundesliga.com/en/bundesliga/table/"),
    ("ligue-1", "FR", "الدوري الفرنسي", "Ligue 1", "L1", "#0A0A2A", "#D9FF00", "https://ligue1.com/en/articles/l1_article_5292-the-2026-27-ligue-1-mcdonald-s-calendar-is-released"),
]

clubs = {
    "saudi-pro": [
        ("hilal", "الهلال", "Al Hilal", "HIL", "#2454B8", "#FFFFFF"),
        ("nassr", "النصر", "Al Nassr", "NAS", "#F4CF31", "#173B74"),
        ("ahli", "الأهلي", "Al Ahli", "AHL", "#198B59", "#FFFFFF"),
        ("qadsiah", "القادسية", "Al Qadsiah", "QAD", "#B51F32", "#F0C75E"),
        ("ittihad", "الاتحاد", "Al Ittihad", "ITT", "#1E1E1E", "#F4CF31"),
        ("taawoun", "التعاون", "Al Taawoun", "TAA", "#F4CF31", "#173B74"),
        ("ettifaq", "الاتفاق", "Al Ettifaq", "ETT", "#B51F32", "#2E7D4F"),
        ("fateh", "الفتح", "Al Fateh", "FAT", "#1D78B5", "#2E7D4F"),
        ("khaleej", "الخليج", "Al Khaleej", "KHA", "#F1B52B", "#1F6A4D"),
        ("shabab", "الشباب", "Al Shabab", "SHB", "#F5F5F5", "#1E1E1E"),
        ("neom", "نيوم", "NEOM SC", "NEO", "#342E7A", "#5FD1C8"),
        ("hazem", "الحزم", "Al Hazem", "HAZ", "#D7AE35", "#1E1E1E"),
        ("fayha", "الفيحاء", "Al Fayha", "FAY", "#E36A2E", "#6B3C92"),
        ("kholood", "الخلود", "Al Kholood", "KHO", "#1C5C9E", "#D4A83A"),
        ("riyadh", "الرياض", "Al Riyadh", "RIY", "#B51F32", "#1E1E1E"),
        ("abha", "أبها", "Abha", "ABH", "#2454B8", "#B51F32"),
        ("faisaly", "الفيصلي", "Al Faisaly", "FAI", "#7B1F2B", "#F5F5F5"),
        ("diriyah", "الدرعية", "Diriyah Club", "DIR", "#7D5A34", "#D8B16B"),
    ],
    "premier-league": [
        ("arsenal", "أرسنال", "Arsenal", "ARS", "#B51F32", "#F5F5F5"),
        ("aston-villa", "أستون فيلا", "Aston Villa", "AVL", "#6B2949", "#85B9D8"),
        ("bournemouth", "بورنموث", "Bournemouth", "BOU", "#B51F32", "#1E1E1E"),
        ("brentford", "برينتفورد", "Brentford", "BRE", "#B51F32", "#F5F5F5"),
        ("brighton", "برايتون", "Brighton", "BHA", "#2454B8", "#F5F5F5"),
        ("chelsea", "تشيلسي", "Chelsea", "CHE", "#2454B8", "#F5F5F5"),
        ("coventry", "كوفنتري سيتي", "Coventry City", "COV", "#58A7D8", "#F5F5F5"),
        ("crystal-palace", "كريستال بالاس", "Crystal Palace", "CRY", "#2454B8", "#B51F32"),
        ("everton", "إيفرتون", "Everton", "EVE", "#2454B8", "#F5F5F5"),
        ("fulham", "فولهام", "Fulham", "FUL", "#F5F5F5", "#1E1E1E"),
        ("hull", "هال سيتي", "Hull City", "HUL", "#E5962D", "#1E1E1E"),
        ("ipswich", "إيبسويتش تاون", "Ipswich Town", "IPS", "#2454B8", "#F5F5F5"),
        ("leeds", "ليدز يونايتد", "Leeds United", "LEE", "#F5F5F5", "#2454B8"),
        ("liverpool", "ليفربول", "Liverpool", "LIV", "#B51F32", "#F5F5F5"),
        ("man-city", "مانشستر سيتي", "Manchester City", "MCI", "#85B9D8", "#F5F5F5"),
        ("man-utd", "مانشستر يونايتد", "Manchester United", "MUN", "#B51F32", "#1E1E1E"),
        ("newcastle", "نيوكاسل يونايتد", "Newcastle United", "NEW", "#1E1E1E", "#F5F5F5"),
        ("nottingham-forest", "نوتنغهام فورست", "Nottingham Forest", "NFO", "#B51F32", "#F5F5F5"),
        ("sunderland", "سندرلاند", "Sunderland", "SUN", "#B51F32", "#F5F5F5"),
        ("tottenham", "توتنهام هوتسبير", "Tottenham Hotspur", "TOT", "#F5F5F5", "#1E3158"),
    ],
    "laliga": [
        ("athletic", "أتلتيك بلباو", "Athletic Club", "ATH", "#B51F32", "#F5F5F5"),
        ("atletico", "أتلتيكو مدريد", "Atletico de Madrid", "ATM", "#B51F32", "#2454B8"),
        ("osasuna", "أوساسونا", "CA Osasuna", "OSA", "#B51F32", "#1E3158"),
        ("celta", "سيلتا فيغو", "Celta", "CEL", "#85B9D8", "#B51F32"),
        ("alaves", "ديبورتيفو ألافيس", "Deportivo Alaves", "ALA", "#2454B8", "#F5F5F5"),
        ("elche", "إلتشي", "Elche CF", "ELC", "#F5F5F5", "#2E7D4F"),
        ("barcelona", "برشلونة", "FC Barcelona", "BAR", "#283A78", "#9F273E"),
        ("getafe", "خيتافي", "Getafe CF", "GET", "#2454B8", "#F5F5F5"),
        ("levante", "ليفانتي", "Levante UD", "LEV", "#B51F32", "#2454B8"),
        ("malaga", "مالقة", "Malaga CF", "MGA", "#58A7D8", "#F5F5F5"),
        ("racing", "راسينغ سانتاندير", "Racing Club", "RAC", "#2E7D4F", "#F5F5F5"),
        ("deportivo", "ديبورتيفو لاكورونيا", "RC Deportivo", "DEP", "#2454B8", "#F5F5F5"),
        ("espanyol", "إسبانيول", "RCD Espanyol", "ESP", "#2454B8", "#F5F5F5"),
        ("betis", "ريال بيتيس", "Real Betis", "BET", "#2E7D4F", "#F5F5F5"),
        ("real-madrid", "ريال مدريد", "Real Madrid", "RMA", "#F5F5F5", "#D5B35A"),
        ("real-sociedad", "ريال سوسيداد", "Real Sociedad", "RSO", "#2454B8", "#F5F5F5"),
        ("sevilla", "إشبيلية", "Sevilla FC", "SEV", "#F5F5F5", "#B51F32"),
        ("valencia", "فالنسيا", "Valencia CF", "VAL", "#F5F5F5", "#1E1E1E"),
        ("villarreal", "فياريال", "Villarreal CF", "VIL", "#E9D43B", "#2454B8"),
        ("rayo", "رايو فايكانو", "Rayo Vallecano", "RAY", "#F5F5F5", "#B51F32"),
    ],
    "serie-a": [
        ("atalanta", "أتالانتا", "Atalanta", "ATA", "#2454B8", "#1E1E1E"),
        ("bologna", "بولونيا", "Bologna", "BOL", "#9F273E", "#1E3158"),
        ("cagliari", "كالياري", "Cagliari", "CAG", "#9F273E", "#1E3158"),
        ("como", "كومو", "Como", "COM", "#2454B8", "#F5F5F5"),
        ("fiorentina", "فيورنتينا", "Fiorentina", "FIO", "#6B3C92", "#F5F5F5"),
        ("frosinone", "فروزينوني", "Frosinone", "FRO", "#E9D43B", "#2454B8"),
        ("genoa", "جنوى", "Genoa", "GEN", "#9F273E", "#1E3158"),
        ("inter", "إنتر ميلان", "Internazionale", "INT", "#2454B8", "#1E1E1E"),
        ("juventus", "يوفنتوس", "Juventus", "JUV", "#F5F5F5", "#1E1E1E"),
        ("lazio", "لاتسيو", "Lazio", "LAZ", "#85B9D8", "#F5F5F5"),
        ("lecce", "ليتشي", "Lecce", "LEC", "#E9D43B", "#B51F32"),
        ("milan", "ميلان", "Milan", "MIL", "#B51F32", "#1E1E1E"),
        ("monza", "مونزا", "Monza", "MON", "#B51F32", "#F5F5F5"),
        ("napoli", "نابولي", "Napoli", "NAP", "#58A7D8", "#F5F5F5"),
        ("parma", "بارما", "Parma", "PAR", "#E9D43B", "#2454B8"),
        ("roma", "روما", "Roma", "ROM", "#7B1F2B", "#D8A43A"),
        ("sassuolo", "ساسولو", "Sassuolo", "SAS", "#2E7D4F", "#1E1E1E"),
        ("torino", "تورينو", "Torino", "TOR", "#7B1F2B", "#F5F5F5"),
        ("udinese", "أودينيزي", "Udinese", "UDI", "#F5F5F5", "#1E1E1E"),
        ("venezia", "فينيتسيا", "Venezia", "VEN", "#E5962D", "#1E1E1E"),
    ],
    "bundesliga": [
        ("bayern", "بايرن ميونخ", "Bayern Munich", "FCB", "#B51F32", "#F5F5F5"),
        ("augsburg", "أوغسبورغ", "Augsburg", "FCA", "#B51F32", "#2E7D4F"),
        ("bremen", "فيردر بريمن", "Werder Bremen", "SVW", "#2E7D4F", "#F5F5F5"),
        ("dortmund", "بوروسيا دورتموند", "Borussia Dortmund", "BVB", "#E9D43B", "#1E1E1E"),
        ("elversberg", "إلفرسبرغ", "Elversberg", "ELV", "#F5F5F5", "#1E1E1E"),
        ("frankfurt", "آينتراخت فرانكفورت", "Eintracht Frankfurt", "SGE", "#B51F32", "#1E1E1E"),
        ("freiburg", "فرايبورغ", "Freiburg", "SCF", "#B51F32", "#1E1E1E"),
        ("hamburg", "هامبورغ", "Hamburg", "HSV", "#2454B8", "#F5F5F5"),
        ("hoffenheim", "هوفنهايم", "Hoffenheim", "TSG", "#2454B8", "#F5F5F5"),
        ("cologne", "كولن", "Cologne", "KOE", "#F5F5F5", "#B51F32"),
        ("leipzig", "لايبزيغ", "RB Leipzig", "RBL", "#F5F5F5", "#B51F32"),
        ("leverkusen", "باير ليفركوزن", "Bayer Leverkusen", "B04", "#B51F32", "#1E1E1E"),
        ("gladbach", "بوروسيا مونشنغلادباخ", "Borussia Monchengladbach", "BMG", "#F5F5F5", "#1E1E1E"),
        ("mainz", "ماينتس", "Mainz", "M05", "#B51F32", "#F5F5F5"),
        ("paderborn", "بادربورن", "Paderborn", "SCP", "#2454B8", "#1E1E1E"),
        ("schalke", "شالكه", "Schalke", "S04", "#2454B8", "#F5F5F5"),
        ("union-berlin", "يونيون برلين", "Union Berlin", "FCU", "#B51F32", "#F5F5F5"),
        ("stuttgart", "شتوتغارت", "VfB Stuttgart", "VFB", "#F5F5F5", "#B51F32"),
    ],
    "ligue-1": [
        ("angers", "أنجيه", "Angers SCO", "SCO", "#1E1E1E", "#F5F5F5"),
        ("auxerre", "أوكسير", "AJ Auxerre", "AJA", "#2454B8", "#F5F5F5"),
        ("brest", "بريست", "Stade Brestois 29", "BRE", "#B51F32", "#F5F5F5"),
        ("le-havre", "لوهافر", "Havre AC", "HAC", "#58A7D8", "#1E3158"),
        ("lens", "لانس", "RC Lens", "RCL", "#B51F32", "#E9D43B"),
        ("lille", "ليل", "LOSC", "LIL", "#B51F32", "#1E3158"),
        ("lorient", "لوريان", "FC Lorient", "FCL", "#E5962D", "#1E1E1E"),
        ("lyon", "ليون", "Olympique Lyonnais", "OL", "#F5F5F5", "#2454B8"),
        ("le-mans", "لو مان", "Le Mans FC", "LM", "#B51F32", "#E9D43B"),
        ("marseille", "مارسيليا", "Olympique de Marseille", "OM", "#58A7D8", "#F5F5F5"),
        ("monaco", "موناكو", "AS Monaco", "ASM", "#B51F32", "#F5F5F5"),
        ("nice", "نيس", "OGC Nice", "NIC", "#B51F32", "#1E1E1E"),
        ("paris-fc", "باريس إف سي", "Paris FC", "PFC", "#2454B8", "#58A7D8"),
        ("psg", "باريس سان جيرمان", "Paris Saint-Germain", "PSG", "#1E3158", "#B51F32"),
        ("rennes", "رين", "Stade Rennais FC", "REN", "#B51F32", "#1E1E1E"),
        ("strasbourg", "ستراسبورغ", "RC Strasbourg Alsace", "RCS", "#2454B8", "#F5F5F5"),
        ("toulouse", "تولوز", "Toulouse FC", "TFC", "#6B3C92", "#F5F5F5"),
        ("troyes", "تروا", "ESTAC Troyes", "EST", "#2454B8", "#F5F5F5"),
    ],
}


def q(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def values(rows):
    return ",\n  ".join("(" + ", ".join(q(str(value)) for value in row) + ")" for row in rows)


country_rows = [
    ("SA", "السعودية", "Saudi Arabia", 1),
    ("GB", "إنجلترا", "England", 2),
    ("ES", "إسبانيا", "Spain", 3),
    ("IT", "إيطاليا", "Italy", 4),
    ("DE", "ألمانيا", "Germany", 5),
    ("FR", "فرنسا", "France", 6),
]

club_rows = []
for league_key, entries in clubs.items():
    source = next(league[7] for league in leagues if league[0] == league_key)
    for order, (slug, name_ar, name_en, short, primary, secondary) in enumerate(entries, 1):
        club_rows.append((league_key, slug, name_ar, name_en, short, primary, secondary, str(order), source))

assert len(leagues) == 6
assert len(club_rows) == 114

slots = [
    ("auth.login.hero", "auth", "صورة تسجيل الدخول", "الصورة الرئيسية في شاشة الدخول"),
    ("auth.signup.hero", "auth", "صورة إنشاء الحساب", "الصورة الرئيسية في إنشاء الحساب"),
    ("home.hero", "home", "صورة اللعب الرئيسية", "خلفية العب الحين"),
    ("play.classic", "play", "الكلاسيك", "صورة نمط الكلاسيك"),
    ("play.truefalse", "play", "صح أو خطأ", "صورة نمط صح أو خطأ"),
    ("play.speed", "play", "السرعة", "صورة نمط السرعة"),
    ("play.ordering", "play", "رتبهم", "صورة نمط الترتيب"),
    ("play.clubguess", "play", "من النادي", "صورة تخمين النادي"),
    ("play.eagleeye", "play", "عين الصقر", "صورة عين الصقر"),
    ("premium.hero", "premium", "صورة بريميوم", "الخلفية الرئيسية للاشتراك"),
    ("team.empty", "team", "فريق فارغ", "حالة عدم وجود فريق"),
    ("friends.empty", "social", "ربعك فارغة", "حالة عدم وجود أصدقاء"),
    ("challenge.empty", "challenge", "تحديات فارغة", "حالة عدم وجود تحديات"),
    ("profile.background", "profile", "خلفية الملف", "خلفية بطاقة اللاعب"),
]

sql = f"""-- Landscape/Premium/football 2026-27. Existing economy remains legacy; no destructive drops.

alter table public.media_assets
  add column if not exists slot_key text,
  add column if not exists rights_status text not null default 'original',
  add column if not exists version integer not null default 1;

alter table public.media_assets
  add constraint media_assets_slot_key_format check (slot_key is null or slot_key ~ '^[a-z][a-z0-9]*(\\.[a-z][a-z0-9]*){{1,4}}$'),
  add constraint media_assets_rights_status check (rights_status in ('original', 'generated', 'licensed')),
  add constraint media_assets_version_positive check (version > 0);

create index if not exists media_assets_slot_idx
  on public.media_assets(slot_key, status, version desc) where slot_key is not null;

insert into public.app_content(
  key, section, content_type, label_ar, usage_ar, default_text_ar,
  min_length, max_length, published_at
)
values
  {values((key, section, 'image', label, usage, '', '0', '1', CHECKED) for key, section, label, usage in slots)}
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
  {values((f"00000000-0000-4000-8000-{order:012d}", 'official-2026-27', code.lower(), code, ar, en, 'true', 'true', str(order), CHECKED) for code, ar, en, order in country_rows)}
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
  {values((*league[:7], league[7], str(order)) for order, league in enumerate(leagues, 1))}
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
  data.secondary_color, true, true, data.sort_order::integer, {q(CHECKED)},
  '2026/27', data.source_url, {q(CHECKED)}, 'fallback'
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
  {values(club_rows)}
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
  {q(CHECKED)}, '2026/27', data.source_url, {q(CHECKED)}, 'fallback'
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
"""

MIGRATION.write_text(sql, encoding="utf-8")

source_lines = []
for key, _, ar, en, _, _, _, url in leagues:
    names = [entry[2] for entry in clubs[key]]
    source_lines.append(
        f"## {ar} — {en}\n\n"
        f"- المصدر الرسمي: {url}\n"
        f"- الموسم: 2026/27\n"
        f"- عدد الأندية المتحقق: {len(names)}\n"
        f"- تاريخ التحقق: 2026-08-29 (Asia/Riyadh)\n"
        f"- الأندية: {', '.join(names)}\n"
        f"- الحقوق البصرية: أسماء وألوان آمنة وشارات إجرائية فقط؛ لا شعارات أو أطقم أو رعاة رسميين.\n"
    )

DOC.write_text(
    "# مصادر بيانات كرة القدم 2026/27\n\n"
    "تم التحقق من قوائم الموسم من صفحات الجهات المنظمة الرسمية. "
    "البيانات النصية فقط هي التي تُخزن؛ جميع الشعارات بحالة `fallback`.\n\n"
    + "\n".join(source_lines)
    + f"\n## الإجمالي\n\n6 دوريات و{len(club_rows)} ناديًا.\n",
    encoding="utf-8",
)

print(f"Generated {MIGRATION} with {len(club_rows)} clubs")
