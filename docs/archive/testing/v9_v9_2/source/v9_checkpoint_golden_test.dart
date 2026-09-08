import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/ads_service.dart';
import 'package:ahdash_11/core/services/analytics_service.dart';
import 'package:ahdash_11/core/services/app_error_reporter.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/services/crash_reporter.dart';
import 'package:ahdash_11/core/services/notification_service.dart';
import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/auth/presentation/auth_screen.dart';
import 'package:ahdash_11/features/categories/domain/categories_repository.dart';
import 'package:ahdash_11/features/categories/presentation/categories_controller.dart';
import 'package:ahdash_11/features/content/domain/app_content.dart';
import 'package:ahdash_11/features/content/presentation/app_content_controller.dart';
import 'package:ahdash_11/features/football/data/football_repository.dart';
import 'package:ahdash_11/features/football/domain/football_entities.dart';
import 'package:ahdash_11/features/football/presentation/football_preferences_screen.dart';
import 'package:ahdash_11/features/home/presentation/home_screen.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/onboarding/presentation/launch_screen.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_catalog_provider.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_game_screens.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_screens.dart';
import 'package:ahdash_11/features/premium/presentation/premium_screen.dart';
import 'package:ahdash_11/features/profile/domain/player_profile.dart';
import 'package:ahdash_11/features/profile/presentation/profile_controller.dart';
import 'package:ahdash_11/features/profile/presentation/profile_screen.dart';
import 'package:ahdash_11/features/settings/presentation/settings_screen.dart';
import 'package:ahdash_11/features/tournament/domain/tournament.dart';
import 'package:ahdash_11/features/tournament/domain/tournament_engine.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_screens.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

enum _V9Screen {
  launch,
  signIn,
  createAccount,
  home,
  categories,
  teams,
  ready,
  board,
  question,
  result,
  tournamentHub,
  tournamentBracket,
  tournamentMatch,
  tournamentChampion,
  profile,
  settings,
  footballPreferences,
  premium,
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

  const sizes = [Size(844, 390), Size(1280, 720)];
  for (final size in sizes) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final screen in _V9Screen.values) {
        final dimensions = '${size.width.round()}x${size.height.round()}';
        final fileName = '${screen.name}_${dimensions}_${brightness.name}.png';
        testWidgets('V9 checkpoint $fileName', (tester) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(() {
            tester.view
              ..resetPhysicalSize()
              ..resetDevicePixelRatio();
          });

          final baseTournament = _tournamentFixture();
          final tournament = screen == _V9Screen.tournamentChampion
              ? _championFixture(baseTournament)
              : baseTournament;
          final container = _container(screen, tournament);
          addTearDown(container.dispose);
          final key = ValueKey(fileName);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: testApp(
                MediaQuery(
                  data: MediaQueryData(size: size, disableAnimations: true),
                  child: RepaintBoundary(
                    key: key,
                    child: _screen(screen, tournament),
                  ),
                ),
                theme: brightness == Brightness.light
                    ? AppTheme.light
                    : AppTheme.dark,
              ),
            ),
          );
          await tester.pump();
          if (screen == _V9Screen.createAccount) {
            await tester.tap(find.byKey(const ValueKey('auth-mode-toggle')));
            await tester.pump();
          }
          if (screen == _V9Screen.settings) {
            await tester.tap(find.text('الخصوصية'));
            await tester.pump();
          }
          await tester.pump(
            screen == _V9Screen.launch
                ? const Duration(milliseconds: 600)
                : const Duration(milliseconds: 200),
          );
          await _precacheImages(tester, key);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(key),
            matchesGoldenFile(
              '../../../docs/visual-validation/v9-checkpoint/$fileName',
            ),
          );
        });
      }
    }
  }

  const portraitSize = Size(390, 844);
  for (final screen in _V9Screen.values) {
    testWidgets('V9 portrait smoke ${screen.name}', (tester) async {
      tester.view
        ..physicalSize = portraitSize
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });

      final baseTournament = _tournamentFixture();
      final tournament = screen == _V9Screen.tournamentChampion
          ? _championFixture(baseTournament)
          : baseTournament;
      final container = _container(screen, tournament);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(
            MediaQuery(
              data: const MediaQueryData(
                size: portraitSize,
                disableAnimations: true,
              ),
              child: _screen(screen, tournament),
            ),
            theme: AppTheme.light,
          ),
        ),
      );
      await tester.pump();
      if (screen == _V9Screen.createAccount) {
        await tester.tap(find.byKey(const ValueKey('auth-mode-toggle')));
        await tester.pump();
      }
      if (screen == _V9Screen.settings) {
        await tester.tap(find.text('الخصوصية'));
        await tester.pump();
      }
      await tester.pump(
        screen == _V9Screen.launch
            ? const Duration(milliseconds: 600)
            : const Duration(milliseconds: 200),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

ProviderContainer _container(_V9Screen screen, Tournament tournament) {
  final launchAuth = Completer<AuthUser?>();
  return ProviderContainer(
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
      appServicesProvider.overrideWithValue(_goldenServices),
      appPreferencesProvider.overrideWithBuild(
        (ref, notifier) async => const AppPreferences(
          soundEffects: false,
          haptics: false,
          reducedMotion: true,
        ),
      ),
      authControllerProvider.overrideWithBuild(
        (ref, notifier) => screen == _V9Screen.launch
            ? launchAuth.future
            : const AuthUser(
                id: 'v9-player',
                username: 'لاعب_أحدعش',
                isGuest: false,
              ),
      ),
      appContentProvider.overrideWithBuild(
        (ref, notifier) => AppContentBundle.defaults,
      ),
      categoriesRepositoryProvider.overrideWithValue(
        _GoldenCategoriesRepository(_categories),
      ),
      playerProfileProvider.overrideWith((ref) async => _profile),
      footballRepositoryProvider.overrideWithValue(
        const FootballRepository(null),
      ),
      footballLeaguesProvider.overrideWith((ref) async => _footballLeagues),
      partyCatalogProvider.overrideWith((ref) async => _catalog),
      partyHelperCatalogProvider.overrideWith(
        (ref) async => defaultPartyHelperDefinitions,
      ),
      partyRuntimeSettingsProvider.overrideWith(
        (ref) async => const PartyRuntimeSettings(),
      ),
      partyGameControllerProvider.overrideWithBuild(
        (ref, notifier) => _partyState(screen),
      ),
      tournamentControllerProvider.overrideWith(
        () => _GoldenTournamentController(tournament),
      ),
    ],
  );
}

Widget _screen(_V9Screen screen, Tournament tournament) => switch (screen) {
  _V9Screen.launch => const LaunchScreen(),
  _V9Screen.signIn || _V9Screen.createAccount => const AuthScreen(),
  _V9Screen.home => const HomeScreen(),
  _V9Screen.categories => const PartyCategorySelectionScreen(),
  _V9Screen.teams => const PartyTeamSetupScreen(),
  _V9Screen.ready => const PartyReadyScreen(),
  _V9Screen.board => const PartyBoardScreen(),
  _V9Screen.question => const PartyQuestionScreen(),
  _V9Screen.result => const PartyResultScreen(),
  _V9Screen.tournamentHub => const TournamentHubScreen(),
  _V9Screen.tournamentBracket => const TournamentBracketScreen(),
  _V9Screen.tournamentMatch => TournamentMatchScreen(
    matchId: tournament.matches
        .where((match) => match.status == TournamentMatchStatus.ready)
        .last
        .id,
  ),
  _V9Screen.tournamentChampion => const TournamentChampionScreen(),
  _V9Screen.profile => const ProfileScreen(),
  _V9Screen.settings => const SettingsScreen(),
  _V9Screen.footballPreferences => const FootballPreferencesScreen(),
  _V9Screen.premium => const PremiumScreen(),
};

PartyGameState _partyState(_V9Screen screen) {
  final session = screen == _V9Screen.question
      ? _session.copyWith(activeQuestionId: 'q-0-0')
      : _session;
  final setupComplete = screen == _V9Screen.teams || screen == _V9Screen.ready;
  return PartyGameState(
    selectedCategoryIds: _categories
        .take(setupComplete ? 6 : 3)
        .map((category) => category.id)
        .toList(),
    teams: _teams,
    favoriteCategoryIds: const {'c0', 'c2'},
    session: session,
    restored: true,
  );
}

Future<void> _precacheImages(WidgetTester tester, Key key) async {
  final boundary = find.byKey(key);
  final providers = tester
      .widgetList<Image>(
        find.descendant(of: boundary, matching: find.byType(Image)),
      )
      .map((image) => image.image)
      .toList(growable: false);
  if (providers.isEmpty) return;
  final context = tester.element(boundary);
  await tester.runAsync(() async {
    await Future.wait(
      providers.map((provider) => precacheImage(provider, context)),
    );
  });
}

final class _GoldenCategoriesRepository implements CategoriesRepository {
  const _GoldenCategoriesRepository(this.categories);

  final List<QuizCategory> categories;

  @override
  Future<List<QuizCategory>> loadCategories({
    bool forceRefresh = false,
  }) async => categories;
}

final class _GoldenTournamentController extends TournamentController {
  _GoldenTournamentController(this.tournament);

  final Tournament tournament;

  @override
  TournamentState build() =>
      TournamentState(active: tournament, restored: true);

  @override
  Future<void> restore() async {}
}

Tournament _tournamentFixture() {
  var id = 0;
  final engine = TournamentEngine(idFactory: () => 'v9-${id++}');
  var draft = engine.create(
    name: 'بطولة أحدعش الليلية',
    organizerId: 'organizer',
    rules: const TournamentRules(capacity: 4, playersPerTeam: 2),
    now: DateTime.utc(2026, 9),
  );
  for (final team in const {
    'الصقور': ['سلمان', 'فيصل'],
    'المدرج': ['نواف', 'تركي'],
    'التكتيك': ['زياد', 'عبدالله'],
    'الأساطير': ['خالد', 'محمد'],
  }.entries) {
    draft = engine.addTeam(draft, name: team.key, players: team.value);
  }
  return engine.generateBracket(draft, randomSeed: 11);
}

Tournament _championFixture(Tournament tournament) {
  final finalRound = tournament.matches
      .map((match) => match.round)
      .reduce((a, b) => a > b ? a : b);
  final champion = tournament.teams.first;
  final runnerUp = tournament.teams[1];
  return tournament.copyWith(
    status: TournamentStatus.completed,
    championTeamId: champion.id,
    matches: tournament.matches
        .map(
          (match) => match.round == finalRound
              ? match.copyWith(
                  status: TournamentMatchStatus.completed,
                  teamAId: champion.id,
                  teamBId: runnerUp.id,
                  scoreA: 1200,
                  scoreB: 900,
                  winnerId: champion.id,
                  confirmedAt: DateTime.utc(2026, 9, 2),
                )
              : match,
        )
        .toList(growable: false),
  );
}

const _profile = PlayerProfile(
  id: 'v9-player',
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
  favoriteCategoryNames: ['دوري روشن', 'الأساطير', 'المنتخبات'],
);

const _footballLeagues = [
  FootballLeague(
    id: 'spl',
    nameAr: 'دوري روشن السعودي',
    countryNameAr: 'السعودية',
    badgeText: 'SA',
    primaryColor: '#0C7A43',
  ),
  FootballLeague(
    id: 'ucl',
    nameAr: 'دوري أبطال أوروبا',
    countryNameAr: 'أوروبا',
    badgeText: 'CL',
    primaryColor: '#203A8F',
  ),
  FootballLeague(
    id: 'pl',
    nameAr: 'الدوري الإنجليزي',
    countryNameAr: 'إنجلترا',
    badgeText: 'PL',
    primaryColor: '#3D195B',
  ),
  FootballLeague(
    id: 'laliga',
    nameAr: 'الدوري الإسباني',
    countryNameAr: 'إسبانيا',
    badgeText: 'LL',
    primaryColor: '#E21B2D',
  ),
  FootballLeague(
    id: 'serie-a',
    nameAr: 'الدوري الإيطالي',
    countryNameAr: 'إيطاليا',
    badgeText: 'SA',
    primaryColor: '#1455A0',
  ),
  FootballLeague(
    id: 'bundesliga',
    nameAr: 'الدوري الألماني',
    countryNameAr: 'ألمانيا',
    badgeText: 'BL',
    primaryColor: '#D20515',
  ),
];

final _catalog = PartyCatalog(
  categories: _categories,
  questions: const [],
  healthByCategoryId: {
    for (final category in _categories)
      category.id: const PartyCategoryHealth(easy: 2, medium: 2, hard: 2),
  },
);

final _categories = List.generate(
  6,
  (index) => QuizCategory(
    id: 'c$index',
    name: const [
      'دوري روشن السعودي',
      'دوري الأبطال',
      'المنتخبات',
      'سوق الانتقالات',
      'الأساطير',
      'عين الصقر',
    ][index],
    description: 'ستة أسئلة جاهزة ومتوازنة',
    iconName: 'sports_soccer',
    imageUrl: index.isEven
        ? 'assets/visuals/eagle-eye-cover.png'
        : 'assets/visuals/home-hero.png',
    accentColor: Color(
      const [
        0xFF78B814,
        0xFFB77A00,
        0xFF2368A2,
        0xFFB63863,
        0xFF7446A8,
        0xFF14805D,
      ][index],
    ),
  ),
);

const _teams = [
  PartyTeam(
    name: 'صقور الجزيرة',
    colorValue: 0xFF2368A2,
    players: ['سلمان', 'فيصل'],
    selectedHelpers: {
      PartyHelperId.risk,
      PartyHelperId.twoChances,
      PartyHelperId.callFriend,
    },
  ),
  PartyTeam(
    name: 'ذئاب المدرج',
    colorValue: 0xFFB63863,
    players: ['نواف', 'تركي'],
    selectedHelpers: {
      PartyHelperId.pass,
      PartyHelperId.bench,
      PartyHelperId.callFriend,
    },
  ),
];

final _session = PartyGameSession(
  id: 'v9-party',
  teams: _teams,
  categories: List.generate(
    6,
    (categoryIndex) => PartyCategorySnapshot(
      id: 'c$categoryIndex',
      name: _categories[categoryIndex].name,
      colorValue: _categories[categoryIndex].accentColor.toARGB32(),
      ownerTeamIndex: categoryIndex < 3 ? 0 : 1,
      imageUrl: _categories[categoryIndex].imageUrl,
      questions: List.generate(
        6,
        (questionIndex) => PartyQuestionSnapshot(
          id: 'q-$categoryIndex-$questionIndex',
          categoryId: 'c$categoryIndex',
          text:
              'من سجل هدف الفوز في نهائي البطولة القارية بعد مباراة امتدت إلى الأشواط الإضافية؟',
          answer: 'اللاعب أحدعش',
          options: const [
            'اللاعب أحدعش',
            'سالم الدوسري',
            'ياسر القحطاني',
            'سامي الجابر',
          ],
          difficulty: questionIndex < 2
              ? QuestionDifficulty.easy
              : questionIndex < 4
              ? QuestionDifficulty.medium
              : QuestionDifficulty.hard,
          pointValue: questionIndex < 2
              ? 100
              : questionIndex < 4
              ? 200
              : 300,
          format: PartyQuestionFormat.multipleChoice,
        ),
      ),
    ),
  ),
  timerSeconds: 30,
  createdAt: DateTime(2026, 9),
  scores: const [1200, 900],
);

const _goldenServices = AppServices(
  analytics: NoopAnalyticsService(),
  crashReporter: NoopCrashReporter(),
  notifications: NoopNotificationService(),
  ads: NoopAdsService(),
  purchases: _GoldenPurchases(),
  errors: NoopAppErrorReporter(),
);

final class _GoldenPurchases implements PurchaseService {
  const _GoldenPurchases();

  @override
  bool get enabled => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isPremium() async => false;

  @override
  Future<bool> purchasePremium() async => false;

  @override
  Future<List<PremiumPlan>> loadPlans() async => const [
    PremiumPlan(
      period: PremiumPlanPeriod.monthly,
      identifier: 'monthly',
      price: '19.99 ر.س',
      priceValue: 19.99,
      currencyCode: 'SAR',
    ),
    PremiumPlan(
      period: PremiumPlanPeriod.yearly,
      identifier: 'yearly',
      price: '149.99 ر.س',
      priceValue: 149.99,
      currencyCode: 'SAR',
      monthlyEquivalent: '12.49 ر.س',
    ),
  ];

  @override
  Future<PremiumStatus> loadStatus() async =>
      const PremiumStatus(state: PremiumAccessState.inactive);

  @override
  Future<bool> purchasePlan(PremiumPlanPeriod period) async => false;

  @override
  Future<bool> restorePurchases() async => false;

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> signOut() async {}
}
