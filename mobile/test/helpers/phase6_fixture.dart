// Deterministic test-only data. Never imported by production code.
import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/football/domain/football_entities.dart';
import 'package:ahdash_11/features/football/presentation/football_preferences_controller.dart';
import 'package:ahdash_11/features/notifications/data/notifications_repository.dart';
import 'package:ahdash_11/features/premium/presentation/premium_controller.dart';
import 'package:ahdash_11/features/profile/domain/player_profile.dart';

const phase6Config = AppConfig(
  environment: AppEnvironment.production,
  supabaseUrl: '',
  supabaseKey: '',
  firebaseEnabled: false,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
);
const phase6User = AuthUser(
  id: 'test-account-a',
  username: 'player_11',
  isGuest: false,
);
final phase6Profile = PlayerProfile.fromJson({
  'id': phase6User.id,
  'username': 'Salman_11',
  'display_name': 'سلمان الحربي',
  'is_premium': true,
  'show_football_preferences': true,
  'favorite_league_data': {
    'id': 'league-a',
    'name_ar': 'الدوري الممتاز · مدرسة الوسطى',
    'badge_text': 'SA',
    'primary_color': '#276149',
  },
  'favorite_club_data': {
    'id': 'club-a',
    'name_ar': 'نادي الرياض السعودي',
    'badge_text': '11',
    'primary_color': '#276149',
  },
});
final phase6Notifications = [
  InboxNotification(
    id: 'notification-a',
    type: 'system',
    title: 'تم إطلاق فئة الدوري الإسباني!',
    body: 'استعد للعب بأسئلة وتحديات حصرية لليغا الإسبانية الآن.',
    createdAt: DateTime.utc(2026, 9, 5, 12),
    data: const {'route': '/profile'},
  ),
  InboxNotification(
    id: 'notification-b',
    type: 'challenge',
    title: 'تحدي جديد من أبو فيصل',
    body: 'ابدأ أبو فيصل تحديًا للمجلس الرياضي اليوم.',
    createdAt: DateTime.utc(2026, 9, 4, 10),
    readAt: DateTime.utc(2026, 9, 4, 11),
  ),
  InboxNotification(
    id: 'notification-c',
    type: 'social',
    title: 'انضمام لاعب جديد',
    body: 'انضم فهد العتيبي لقائمة أصدقائك بنجاح.',
    createdAt: DateTime.utc(2026, 9, 3, 8),
    readAt: DateTime.utc(2026, 9, 3, 9),
  ),
];
const phase6Leagues = [
  FootballLeague(
    id: 'league-a',
    nameAr: 'دوري روشن',
    countryNameAr: 'السعودية',
    badgeText: 'SA',
    primaryColor: '#276149',
  ),
  FootballLeague(
    id: 'league-b',
    nameAr: 'الدوري الإنجليزي',
    countryNameAr: 'إنجلترا',
    badgeText: 'EN',
    primaryColor: '#59466E',
  ),
  FootballLeague(
    id: 'league-c',
    nameAr: 'أوروبا',
    countryNameAr: 'أوروبا',
    badgeText: 'EU',
    primaryColor: '#936546',
  ),
];
const phase6Clubs = [
  FootballClub(
    id: 'club-b',
    leagueId: 'league-a',
    nameAr: 'النصر',
    leagueNameAr: 'دوري روشن',
    badgeText: 'UT',
    primaryColor: '#485989',
  ),
  FootballClub(
    id: 'club-d',
    leagueId: 'league-a',
    nameAr: 'الهلال',
    leagueNameAr: 'دوري روشن',
    badgeText: 'HIL',
    primaryColor: '#2867E8',
  ),
  FootballClub(
    id: 'club-a',
    leagueId: 'league-a',
    nameAr: 'نادي الرياض',
    leagueNameAr: 'دوري روشن',
    badgeText: '11',
    primaryColor: '#276149',
  ),
  FootballClub(
    id: 'club-c',
    leagueId: 'league-a',
    nameAr: 'الاتحاد',
    leagueNameAr: 'دوري روشن',
    badgeText: 'AC',
    primaryColor: '#936546',
  ),
];
const phase6Football = FootballView(
  leagues: phase6Leagues,
  clubs: phase6Clubs,
  leagueId: 'league-a',
  clubId: 'club-a',
  canSave: true,
);
// Localized fake store values are fixtures only, not fallback prices.
const phase6Plans = [
  PremiumPlan(
    period: PremiumPlanPeriod.monthly,
    identifier: 'test-monthly',
    price: '١٢٫٩٩ ر.س.',
    priceValue: 12.99,
    currencyCode: 'SAR',
  ),
  PremiumPlan(
    period: PremiumPlanPeriod.yearly,
    identifier: 'test-yearly',
    price: '٩٩٫٩٩ ر.س.',
    priceValue: 99.99,
    currencyCode: 'SAR',
  ),
];
const phase6Premium = PremiumView(plans: phase6Plans, available: true);
