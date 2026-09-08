import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/config/game_settings_repository.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/presentation/auth_screen.dart';
import 'package:ahdash_11/features/categories/domain/categories_repository.dart';
import 'package:ahdash_11/features/categories/presentation/categories_controller.dart';
import 'package:ahdash_11/features/categories/presentation/categories_screen.dart';
import 'package:ahdash_11/features/football/data/football_repository.dart';
import 'package:ahdash_11/features/football/domain/football_entities.dart';
import 'package:ahdash_11/features/football/presentation/football_preferences_screen.dart';
import 'package:ahdash_11/features/home/presentation/home_screen.dart';
import 'package:ahdash_11/features/match/domain/question_history_entry.dart';
import 'package:ahdash_11/features/match/domain/question_repository.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/match/presentation/question_repository_provider.dart';
import 'package:ahdash_11/features/match/presentation/question_screen.dart';
import 'package:ahdash_11/features/match/presentation/results_screen.dart';
import 'package:ahdash_11/features/match/presentation/solo_match_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/play/presentation/play_screen.dart';
import 'package:ahdash_11/features/premium/presentation/premium_screen.dart';
import 'package:ahdash_11/features/profile/domain/player_profile.dart';
import 'package:ahdash_11/features/profile/presentation/profile_controller.dart';
import 'package:ahdash_11/features/profile/presentation/profile_screen.dart';
import 'package:ahdash_11/features/settings/presentation/settings_screen.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/domain/social_entities.dart';
import 'package:ahdash_11/features/social/presentation/social_hub_screen.dart';
import 'package:ahdash_11/features/store/presentation/store_screen.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:ahdash_11/shared/domain/game_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

enum _VisualScreen {
  home,
  categories,
  play,
  question,
  results,
  teams,
  profile,
  settings,
  login,
  clubPicker,
  premium,
  store,
}

void main() {
  setUpAll(() async {
    await (FontLoader('ThmanyahSans')
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Regular.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Medium.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Bold.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Black.otf'),
          ))
        .load();
    await (FontLoader('ThmanyahSerifDisplay')..addFont(
          rootBundle.load(
            'assets/fonts/thmanyah/thmanyahserifdisplay-Black.otf',
          ),
        ))
        .load();
    await (FontLoader('ThmanyahSerifText')
          ..addFont(
            rootBundle.load(
              'assets/fonts/thmanyah/thmanyahseriftext-Regular.otf',
            ),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahseriftext-Bold.otf'),
          ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const sizes = <Size>[
    Size(390, 844),
    Size(800, 360),
    Size(844, 390),
    Size(915, 412),
    Size(1280, 720),
    Size(1366, 768),
  ];

  for (final size in sizes) {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      final tone = brightness.name;
      final dimensions = '${size.width.round()}x${size.height.round()}';
      for (final screen in _VisualScreen.values) {
        final name = _fileName(screen);
        final suffix = '${dimensions}_$tone';
        testWidgets('$name visual $suffix', (tester) async {
          _configureView(tester, size);
          final container = _visualContainer(screen);
          addTearDown(container.dispose);

          final visualKey = ValueKey('visual-$name');
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: testApp(
                MediaQuery(
                  data: MediaQueryData(size: size, disableAnimations: true),
                  child: RepaintBoundary(
                    key: visualKey,
                    child: _screenWidget(screen),
                  ),
                ),
                theme: brightness == Brightness.dark
                    ? AppTheme.dark
                    : AppTheme.light,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 120));
          await _precacheImages(tester, visualKey);
          await tester.pump();
          await expectLater(
            find.byKey(visualKey),
            matchesGoldenFile(
              '../../../docs/visual-validation/goldens/${name}_$suffix.png',
            ),
          );
        });
      }
    }
  }
}

ProviderContainer _visualContainer(_VisualScreen screen) => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(
      const AppConfig(
        environment: AppEnvironment.production,
        supabaseUrl: '',
        supabaseKey: '',
        firebaseEnabled: false,
        adMobEnabled: false,
        revenueCatAndroidKey: '',
        revenueCatIosKey: '',
      ),
    ),
    appServicesProvider.overrideWithValue(const AppServices.noop()),
    playerProfileProvider.overrideWith((ref) async => _profile),
    categoriesRepositoryProvider.overrideWithValue(_categories),
    socialHubProvider.overrideWith((ref) async => _socialHub),
    footballLeaguesProvider.overrideWith((ref) async => _leagues),
    questionRepositoryProvider.overrideWithValue(const _VisualQuestions()),
    gameSettingsProvider.overrideWith(
      (ref) async => const GameSettings(questionTimeSeconds: 60),
    ),
    soloMatchControllerProvider.overrideWithBuild(
      (ref, notifier) => _matchState(screen),
    ),
    partyGameControllerProvider.overrideWithBuild(
      (ref, notifier) => const PartyGameState(restored: true),
    ),
    tournamentControllerProvider.overrideWithBuild(
      (ref, notifier) => const TournamentState(restored: true),
    ),
  ],
);

SoloMatchState _matchState(_VisualScreen screen) => switch (screen) {
  _VisualScreen.question => SoloMatchState(
    status: SoloMatchStatus.answering,
    questions: const [_VisualQuestions.question],
    questionStartedAt: DateTime.utc(2100),
    settings: const GameSettings(questionTimeSeconds: 60),
    playerScore: 740,
    opponentScore: 610,
  ),
  _VisualScreen.results => const SoloMatchState(
    status: SoloMatchStatus.finished,
    questions: [_VisualQuestions.question],
    currentIndex: 1,
    playerScore: 1480,
    opponentScore: 920,
    settings: GameSettings(questionTimeSeconds: 60),
    records: [
      SoloAnswerRecord(
        questionId: 'visual-question',
        selectedIndex: 0,
        correct: true,
        score: 1480,
        responseTime: Duration(milliseconds: 3200),
      ),
    ],
  ),
  _ => const SoloMatchState(),
};

Widget _screenWidget(_VisualScreen screen) => switch (screen) {
  _VisualScreen.home => const HomeScreen(),
  _VisualScreen.categories => const CategoriesScreen(),
  _VisualScreen.play => const PlayScreen(),
  _VisualScreen.question => const QuestionScreen(),
  _VisualScreen.results => const ResultsScreen(),
  _VisualScreen.teams => const SocialHubScreen(),
  _VisualScreen.profile => const ProfileScreen(),
  _VisualScreen.settings => const SettingsScreen(),
  _VisualScreen.login => const AuthScreen(),
  _VisualScreen.clubPicker => const FootballPreferencesScreen(),
  _VisualScreen.premium => const PremiumScreen(),
  _VisualScreen.store => const StoreScreen(),
};

String _fileName(_VisualScreen screen) => switch (screen) {
  _VisualScreen.clubPicker => 'club_picker',
  _ => screen.name,
};

void _configureView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _precacheImages(WidgetTester tester, Key key) async {
  final boundary = find.byKey(key);
  final imageProviders = tester
      .widgetList<Image>(
        find.descendant(of: boundary, matching: find.byType(Image)),
      )
      .map((image) => image.image)
      .toList(growable: false);
  if (imageProviders.isEmpty) return;
  final context = tester.element(boundary);
  await tester.runAsync(() async {
    await Future.wait(
      imageProviders.map((provider) => precacheImage(provider, context)),
    );
  });
}

const _profile = PlayerProfile(
  id: 'visual-player',
  username: 'لاعب_أحدعش',
  displayName: 'سلمان الحربي',
  level: 11,
  xp: 680,
  coins: 1480,
  rating: 1311,
  wins: 11,
  losses: 3,
  draws: 2,
  matches: 16,
  accuracy: 0.78,
  bestStreak: 7,
  currentStreak: 3,
  rank: 11,
  avatarJerseyColor: '#B6FF3B',
  isPremium: true,
  favoriteLeagueData: ProfileFootballChoice(
    id: 'spl',
    nameAr: 'الدوري السعودي',
    primaryColor: '#0C7A43',
    visualStatus: 'fallback',
    badgeText: 'SA',
  ),
  favoriteClubData: ProfileFootballChoice(
    id: 'riyadh-11',
    nameAr: 'نادي الرياض',
    primaryColor: '#FFC857',
    visualStatus: 'fallback',
    badgeText: '11',
  ),
  socialTeam: ProfileSocialTeam(
    id: 'team-11',
    name: 'صقور نجد',
    primaryColor: '#B6FF3B',
    badgeSeed: 'SN',
    role: 'owner',
  ),
  achievements: [
    ProfileAchievement(
      slug: 'first-win',
      nameAr: 'أول فوز',
      descriptionAr: 'حققت فوزك الأول',
      artworkKey: 'first_win',
    ),
    ProfileAchievement(
      slug: 'streak',
      nameAr: 'سلسلة حاسمة',
      descriptionAr: 'سبع إجابات متتالية',
      artworkKey: 'streak',
    ),
  ],
);

const _socialHub = SocialHub(
  team: SocialTeamSummary(
    id: 'team-11',
    name: 'صقور نجد',
    primaryColor: '#B6FF3B',
    badgeSeed: 'SN',
    role: 'owner',
    memberCount: 11,
    activeChallenges: 2,
  ),
  invites: [
    SocialTeamInvite(
      inviteId: 'invite-1',
      teamId: 'team-22',
      teamName: 'فرسان الرياض',
      primaryColor: '#FFC857',
      badgeSeed: 'FR',
      invitedByName: 'نورة',
    ),
  ],
);

const _leagues = [
  FootballLeague(
    id: 'spl',
    nameAr: 'الدوري السعودي',
    countryNameAr: 'السعودية',
    badgeText: 'SA',
    primaryColor: '#0C7A43',
  ),
  FootballLeague(
    id: 'epl',
    nameAr: 'الدوري الإنجليزي',
    countryNameAr: 'إنجلترا',
    badgeText: 'EN',
    primaryColor: '#5C2D91',
  ),
  FootballLeague(
    id: 'laliga',
    nameAr: 'الدوري الإسباني',
    countryNameAr: 'إسبانيا',
    badgeText: 'ES',
    primaryColor: '#E24B3B',
  ),
  FootballLeague(
    id: 'seriea',
    nameAr: 'الدوري الإيطالي',
    countryNameAr: 'إيطاليا',
    badgeText: 'IT',
    primaryColor: '#5797E6',
  ),
  FootballLeague(
    id: 'bundesliga',
    nameAr: 'الدوري الألماني',
    countryNameAr: 'ألمانيا',
    badgeText: 'DE',
    primaryColor: '#D14343',
  ),
  FootballLeague(
    id: 'ucl',
    nameAr: 'دوري أبطال أوروبا',
    countryNameAr: 'أوروبا',
    badgeText: 'CL',
    primaryColor: '#3156A3',
  ),
];

const _categories = _VisualCategoriesRepository([
  QuizCategory(
    id: 'history',
    name: 'تاريخ الكرة',
    description: 'لحظات صنعت اللعبة',
    iconName: 'history',
    accentColor: Color(0xFFD6A84B),
    imageUrl: 'assets/visuals/eagle-eye-cover.png',
  ),
  QuizCategory(
    id: 'saudi-season',
    name: 'دوري روشن السعودي للمحترفين 2026/27',
    description: 'الموسم السعودي الجديد',
    iconName: 'trophy',
    accentColor: Color(0xFF5F8F0F),
    imageUrl: 'assets/visuals/eagle-eye-cover.png',
    seasonLabel: '2026/27',
    featured: true,
  ),
  QuizCategory(
    id: 'transfers',
    name: 'سوق الانتقالات',
    description: 'صفقات غيّرت تاريخ الأندية',
    iconName: 'repeat',
    accentColor: Color(0xFF9A6500),
    imageUrl: 'assets/visuals/eagle-eye-cover.png',
  ),
  QuizCategory(
    id: 'national',
    name: 'المنتخبات',
    description: 'محطات دولية لا تُنسى',
    iconName: 'flag',
    accentColor: Color(0xFF38332C),
    imageUrl: 'assets/visuals/eagle-eye-cover.png',
  ),
]);

final class _VisualCategoriesRepository implements CategoriesRepository {
  const _VisualCategoriesRepository(this.values);
  final List<QuizCategory> values;

  @override
  Future<List<QuizCategory>> loadCategories({
    bool forceRefresh = false,
  }) async => values;
}

final class _VisualQuestions implements QuestionRepository {
  const _VisualQuestions();

  static const question = QuizQuestion(
    id: 'visual-question',
    text: 'من صاحب الرقم القياسي في تسجيل أهداف المنتخب السعودي؟',
    options: ['ماجد عبدالله', 'سالم الدوسري', 'ياسر القحطاني', 'سامي الجابر'],
    correctOptionIndex: 0,
    categoryId: 'history',
    difficulty: QuestionDifficulty.medium,
  );

  @override
  Future<List<QuestionHistoryEntry>> loadHistory() async => const [];

  @override
  Future<List<QuizQuestion>> loadSoloPool() async => const [question];

  @override
  Future<void> recordAnswer({
    required String questionId,
    required int selectedIndex,
    required bool correct,
  }) async {}
}
