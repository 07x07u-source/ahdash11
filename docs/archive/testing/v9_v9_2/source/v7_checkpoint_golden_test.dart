import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
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
import 'package:ahdash_11/features/notifications/presentation/notifications_screen.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_catalog_provider.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_game_screens.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_screens.dart';
import 'package:ahdash_11/features/party/presentation/party_support_screens.dart';
import 'package:ahdash_11/features/premium/presentation/premium_screen.dart';
import 'package:ahdash_11/features/profile/domain/player_profile.dart';
import 'package:ahdash_11/features/profile/presentation/profile_controller.dart';
import 'package:ahdash_11/features/profile/presentation/profile_screen.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_screen.dart';
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

enum _CheckpointScreen {
  login,
  home,
  categories,
  teams,
  helpers,
  ready,
  board,
  textQuestion,
  reveal,
  result,
  profile,
  settings,
  premium,
  howTo,
  notifications,
  ranking,
  tournamentHub,
  tournamentCreate,
  tournamentTeams,
  tournamentDraw,
  tournamentBracket,
  tournamentMatch,
  tournamentChampion,
}

enum _V8CheckpointScreen {
  signIn,
  createAccount,
  home,
  categories,
  board,
  question,
  profile,
  tournamentMatch,
  teams,
  helpers,
  ready,
  reveal,
  result,
  howTo,
  tournamentHub,
  tournamentCreate,
  tournamentTeams,
  tournamentDraw,
  tournamentBracket,
  tournamentChampion,
  settings,
  premium,
  notifications,
  footballPreferences,
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
  final tournament = _tournamentFixture();

  for (final size in sizes) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final screen in _CheckpointScreen.values) {
        final dimensions = '${size.width.round()}x${size.height.round()}';
        final fileName = '${screen.name}_${dimensions}_${brightness.name}.png';
        testWidgets('V7 checkpoint $fileName', (tester) async {
          final offlinePreview =
              screen == _CheckpointScreen.notifications ||
              screen == _CheckpointScreen.ranking;
          final screenTournament =
              screen == _CheckpointScreen.tournamentChampion
              ? tournament.copyWith(
                  status: TournamentStatus.completed,
                  championTeamId: tournament.teams.first.id,
                )
              : tournament;
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(() {
            tester.view
              ..resetPhysicalSize()
              ..resetDevicePixelRatio();
          });

          final container = ProviderContainer(
            overrides: [
              appConfigProvider.overrideWithValue(
                AppConfig(
                  environment: AppEnvironment.production,
                  supabaseUrl: offlinePreview
                      ? ''
                      : 'https://preview.supabase.co',
                  supabaseKey: offlinePreview ? '' : 'preview-public-key',
                  firebaseEnabled: false,
                  adMobEnabled: false,
                  revenueCatAndroidKey: '',
                  revenueCatIosKey: '',
                ),
              ),
              appServicesProvider.overrideWithValue(const AppServices.noop()),
              appPreferencesProvider.overrideWithBuild(
                (ref, notifier) async => const AppPreferences(
                  soundEffects: false,
                  haptics: false,
                  reducedMotion: true,
                ),
              ),
              authControllerProvider.overrideWithBuild(
                (ref, notifier) => const AuthUser(
                  id: 'v7-player',
                  username: 'لاعب_أحدعش',
                  isGuest: false,
                ),
              ),
              appContentProvider.overrideWithBuild(
                (ref, notifier) => AppContentBundle.defaults,
              ),
              categoriesRepositoryProvider.overrideWithValue(
                _CheckpointCategoriesRepository(_categories),
              ),
              playerProfileProvider.overrideWith((ref) async => _profile),
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
                () => _CheckpointTournamentController(screenTournament),
              ),
            ],
          );
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
                    child: _screen(screen, screenTournament),
                  ),
                ),
                theme: brightness == Brightness.light
                    ? AppTheme.light
                    : AppTheme.dark,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 150));
          await _precacheImages(tester, key);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(key),
            matchesGoldenFile(
              '../../../docs/visual-validation/v7-checkpoint/$fileName',
            ),
          );
        });
      }
    }
  }

  _registerV8Tests(
    sizes,
    tournament,
    screens: const [
      _V8CheckpointScreen.signIn,
      _V8CheckpointScreen.createAccount,
      _V8CheckpointScreen.home,
      _V8CheckpointScreen.categories,
      _V8CheckpointScreen.board,
      _V8CheckpointScreen.question,
      _V8CheckpointScreen.profile,
      _V8CheckpointScreen.tournamentMatch,
    ],
    label: 'V8 checkpoint',
    directory: 'v8-checkpoint',
  );
  _registerV8Tests(
    sizes,
    tournament,
    screens: const [
      _V8CheckpointScreen.teams,
      _V8CheckpointScreen.helpers,
      _V8CheckpointScreen.ready,
      _V8CheckpointScreen.reveal,
      _V8CheckpointScreen.result,
      _V8CheckpointScreen.howTo,
    ],
    label: 'V8 phase two',
    directory: 'v8-phase-two',
  );
  _registerV8Tests(
    sizes,
    tournament,
    screens: const [
      _V8CheckpointScreen.tournamentHub,
      _V8CheckpointScreen.tournamentCreate,
      _V8CheckpointScreen.tournamentTeams,
      _V8CheckpointScreen.tournamentDraw,
      _V8CheckpointScreen.tournamentBracket,
      _V8CheckpointScreen.tournamentChampion,
      _V8CheckpointScreen.settings,
      _V8CheckpointScreen.premium,
      _V8CheckpointScreen.notifications,
    ],
    label: 'V8 phase three',
    directory: 'v8-phase-three',
  );
  _registerV8Tests(
    sizes,
    tournament,
    screens: const [_V8CheckpointScreen.footballPreferences],
    label: 'V8 phase four',
    directory: 'v8-phase-four',
  );
  _registerV8Tests(
    sizes,
    tournament,
    screens: const [
      _V8CheckpointScreen.result,
      _V8CheckpointScreen.helpers,
      _V8CheckpointScreen.tournamentHub,
      _V8CheckpointScreen.tournamentCreate,
      _V8CheckpointScreen.tournamentDraw,
      _V8CheckpointScreen.tournamentChampion,
      _V8CheckpointScreen.premium,
      _V8CheckpointScreen.notifications,
    ],
    label: 'V8.1 pictogram checkpoint',
    directory: 'v8-1-pictograms',
  );
  _registerV8Tests(
    sizes,
    tournament,
    screens: const [
      _V8CheckpointScreen.signIn,
      _V8CheckpointScreen.createAccount,
      _V8CheckpointScreen.home,
      _V8CheckpointScreen.helpers,
      _V8CheckpointScreen.ready,
      _V8CheckpointScreen.result,
      _V8CheckpointScreen.tournamentHub,
      _V8CheckpointScreen.tournamentDraw,
      _V8CheckpointScreen.tournamentMatch,
      _V8CheckpointScreen.tournamentChampion,
      _V8CheckpointScreen.profile,
      _V8CheckpointScreen.premium,
      _V8CheckpointScreen.notifications,
    ],
    label: 'V8.2 checkpoint',
    directory: 'v8-2-checkpoint',
  );
}

void _registerV8Tests(
  List<Size> sizes,
  Tournament tournament, {
  required List<_V8CheckpointScreen> screens,
  required String label,
  required String directory,
}) {
  for (final size in sizes) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final screen in screens) {
        final dimensions = '${size.width.round()}x${size.height.round()}';
        final fileName = '${screen.name}_${dimensions}_${brightness.name}.png';
        testWidgets('$label $fileName', (tester) async {
          final screenTournament =
              screen == _V8CheckpointScreen.tournamentChampion
              ? tournament.copyWith(
                  status: TournamentStatus.completed,
                  championTeamId: tournament.teams.first.id,
                )
              : tournament;
          final offlinePreview = screen == _V8CheckpointScreen.notifications;
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(() {
            tester.view
              ..resetPhysicalSize()
              ..resetDevicePixelRatio();
          });

          final partyFixture = switch (screen) {
            _V8CheckpointScreen.question => _partyState(
              _CheckpointScreen.textQuestion,
            ),
            _V8CheckpointScreen.categories => _partyState(
              _CheckpointScreen.categories,
            ),
            _V8CheckpointScreen.teams => _partyState(_CheckpointScreen.teams),
            _V8CheckpointScreen.helpers => _partyState(
              _CheckpointScreen.helpers,
            ),
            _V8CheckpointScreen.ready => _partyState(_CheckpointScreen.ready),
            _V8CheckpointScreen.reveal => _partyState(_CheckpointScreen.reveal),
            _V8CheckpointScreen.result => _partyState(_CheckpointScreen.result),
            _ => _partyState(_CheckpointScreen.board),
          };
          final container = ProviderContainer(
            overrides: [
              appConfigProvider.overrideWithValue(
                AppConfig(
                  environment: AppEnvironment.production,
                  supabaseUrl: offlinePreview
                      ? ''
                      : 'https://preview.supabase.co',
                  supabaseKey: offlinePreview ? '' : 'preview-public-key',
                  firebaseEnabled: false,
                  adMobEnabled: false,
                  revenueCatAndroidKey: '',
                  revenueCatIosKey: '',
                ),
              ),
              appServicesProvider.overrideWithValue(const AppServices.noop()),
              appPreferencesProvider.overrideWithBuild(
                (ref, notifier) async => const AppPreferences(
                  soundEffects: false,
                  haptics: false,
                  reducedMotion: true,
                ),
              ),
              authControllerProvider.overrideWithBuild(
                (ref, notifier) => const AuthUser(
                  id: 'v8-player',
                  username: 'لاعب_أحدعش',
                  isGuest: false,
                ),
              ),
              appContentProvider.overrideWithBuild(
                (ref, notifier) => AppContentBundle.defaults,
              ),
              categoriesRepositoryProvider.overrideWithValue(
                _CheckpointCategoriesRepository(_categories),
              ),
              playerProfileProvider.overrideWith((ref) async => _profile),
              partyCatalogProvider.overrideWith((ref) async => _catalog),
              partyHelperCatalogProvider.overrideWith(
                (ref) async => defaultPartyHelperDefinitions,
              ),
              partyRuntimeSettingsProvider.overrideWith(
                (ref) async => const PartyRuntimeSettings(),
              ),
              footballRepositoryProvider.overrideWithValue(
                const FootballRepository(null),
              ),
              footballLeaguesProvider.overrideWith(
                (ref) async => _footballLeagues,
              ),
              partyGameControllerProvider.overrideWithBuild(
                (ref, notifier) => partyFixture,
              ),
              tournamentControllerProvider.overrideWith(
                () => _CheckpointTournamentController(screenTournament),
              ),
            ],
          );
          addTearDown(container.dispose);

          final key = ValueKey('v8-$fileName');
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: testApp(
                MediaQuery(
                  data: MediaQueryData(size: size, disableAnimations: true),
                  child: RepaintBoundary(
                    key: key,
                    child: _v8Screen(screen, screenTournament),
                  ),
                ),
                theme: brightness == Brightness.light
                    ? AppTheme.light
                    : AppTheme.dark,
              ),
            ),
          );
          await tester.pump();
          if (screen == _V8CheckpointScreen.createAccount) {
            await tester.tap(find.byKey(const ValueKey('auth-mode-toggle')));
            await tester.pump();
          }
          await tester.pump(const Duration(milliseconds: 150));
          await _precacheImages(tester, key);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(key),
            matchesGoldenFile(
              '../../../docs/visual-validation/$directory/$fileName',
            ),
          );
        });
      }
    }
  }
}

Widget _v8Screen(
  _V8CheckpointScreen screen,
  Tournament tournament,
) => switch (screen) {
  _V8CheckpointScreen.signIn ||
  _V8CheckpointScreen.createAccount => const AuthScreen(),
  _V8CheckpointScreen.home => const HomeScreen(),
  _V8CheckpointScreen.categories => const PartyCategorySelectionScreen(),
  _V8CheckpointScreen.board => const PartyBoardScreen(),
  _V8CheckpointScreen.question => const PartyQuestionScreen(),
  _V8CheckpointScreen.profile => const ProfileScreen(),
  _V8CheckpointScreen.tournamentMatch => TournamentMatchScreen(
    matchId: tournament.matches
        .where((match) => match.status == TournamentMatchStatus.ready)
        .last
        .id,
  ),
  _V8CheckpointScreen.teams => const PartyTeamSetupScreen(),
  _V8CheckpointScreen.helpers => const PartyHelperSelectionScreen(),
  _V8CheckpointScreen.ready => const PartyReadyScreen(),
  _V8CheckpointScreen.reveal => const PartyRevealScreen(),
  _V8CheckpointScreen.result => const PartyResultScreen(),
  _V8CheckpointScreen.howTo => const HowToPlayScreen(),
  _V8CheckpointScreen.tournamentHub => const TournamentHubScreen(),
  _V8CheckpointScreen.tournamentCreate => const TournamentCreateScreen(),
  _V8CheckpointScreen.tournamentTeams => const TournamentTeamsScreen(),
  _V8CheckpointScreen.tournamentDraw => const TournamentDrawScreen(),
  _V8CheckpointScreen.tournamentBracket => const TournamentBracketScreen(),
  _V8CheckpointScreen.tournamentChampion => const TournamentChampionScreen(),
  _V8CheckpointScreen.settings => const SettingsScreen(),
  _V8CheckpointScreen.premium => const PremiumScreen(),
  _V8CheckpointScreen.notifications => const NotificationsScreen(),
  _V8CheckpointScreen.footballPreferences => const FootballPreferencesScreen(),
};

Widget _screen(_CheckpointScreen screen, Tournament tournament) =>
    switch (screen) {
      _CheckpointScreen.login => const AuthScreen(),
      _CheckpointScreen.home => const HomeScreen(),
      _CheckpointScreen.categories => const PartyCategorySelectionScreen(),
      _CheckpointScreen.teams => const PartyTeamSetupScreen(),
      _CheckpointScreen.helpers => const PartyHelperSelectionScreen(),
      _CheckpointScreen.ready => const PartyReadyScreen(),
      _CheckpointScreen.board => const PartyBoardScreen(),
      _CheckpointScreen.textQuestion => const PartyQuestionScreen(),
      _CheckpointScreen.reveal => const PartyRevealScreen(),
      _CheckpointScreen.result => const PartyResultScreen(),
      _CheckpointScreen.profile => const ProfileScreen(),
      _CheckpointScreen.settings => const SettingsScreen(),
      _CheckpointScreen.premium => const PremiumScreen(),
      _CheckpointScreen.howTo => const HowToPlayScreen(),
      _CheckpointScreen.notifications => const NotificationsScreen(),
      _CheckpointScreen.ranking => const RankingScreen(),
      _CheckpointScreen.tournamentHub => const TournamentHubScreen(),
      _CheckpointScreen.tournamentCreate => const TournamentCreateScreen(),
      _CheckpointScreen.tournamentTeams => const TournamentTeamsScreen(),
      _CheckpointScreen.tournamentDraw => const TournamentDrawScreen(),
      _CheckpointScreen.tournamentBracket => const TournamentBracketScreen(),
      _CheckpointScreen.tournamentMatch => TournamentMatchScreen(
        matchId: tournament.matches
            .where((match) => match.status == TournamentMatchStatus.ready)
            .last
            .id,
      ),
      _CheckpointScreen.tournamentChampion => const TournamentChampionScreen(),
    };

PartyGameState _partyState(_CheckpointScreen screen) {
  final session =
      screen == _CheckpointScreen.textQuestion ||
          screen == _CheckpointScreen.reveal
      ? _session.copyWith(activeQuestionId: 'q-0-0')
      : _session;
  final setupComplete = switch (screen) {
    _CheckpointScreen.teams ||
    _CheckpointScreen.helpers ||
    _CheckpointScreen.ready => true,
    _ => false,
  };
  return PartyGameState(
    selectedCategoryIds: _categories
        .take(setupComplete ? 6 : 3)
        .map((item) => item.id)
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

final class _CheckpointCategoriesRepository implements CategoriesRepository {
  const _CheckpointCategoriesRepository(this.values);

  final List<QuizCategory> values;

  @override
  Future<List<QuizCategory>> loadCategories({
    bool forceRefresh = false,
  }) async => values;
}

final class _CheckpointTournamentController extends TournamentController {
  _CheckpointTournamentController(this.fixture);

  final Tournament fixture;

  @override
  TournamentState build() => TournamentState(active: fixture, restored: true);

  @override
  Future<void> restore() async {}
}

Tournament _tournamentFixture() {
  var id = 0;
  final engine = TournamentEngine(idFactory: () => 'v7-${id++}');
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

const _profile = PlayerProfile(
  id: 'v7-player',
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
    groupKey: index == 0 ? 'saudi' : 'leagues',
    seasonLabel: index == 0 ? '2026/27' : null,
    featured: index == 1,
    isNew: index == 5,
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
  id: 'v7-party',
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
  scores: const [700, 500],
);
