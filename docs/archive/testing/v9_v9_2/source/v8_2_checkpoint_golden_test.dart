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
import 'package:ahdash_11/features/home/presentation/home_screen.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/notifications/presentation/notifications_screen.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_catalog_provider.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_game_screens.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_screens.dart';
import 'package:ahdash_11/features/premium/presentation/premium_screen.dart';
import 'package:ahdash_11/features/profile/domain/player_profile.dart';
import 'package:ahdash_11/features/profile/presentation/profile_controller.dart';
import 'package:ahdash_11/features/profile/presentation/profile_screen.dart';
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

enum _Screen {
  signIn,
  createAccount,
  home,
  helpers,
  ready,
  result,
  tournamentHub,
  tournamentDraw,
  tournamentMatch,
  tournamentChampion,
  profile,
  premium,
  notifications,
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
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const sizes = [Size(844, 390), Size(1280, 720)];
  for (final size in sizes) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final screen in _Screen.values) {
        final dimensions = '${size.width.round()}x${size.height.round()}';
        final fileName = '${screen.name}_${dimensions}_${brightness.name}.png';
        testWidgets('V8.2 checkpoint $fileName', (tester) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(() {
            tester.view
              ..resetPhysicalSize()
              ..resetDevicePixelRatio();
          });

          final baseTournament = _tournamentFixture();
          final tournament = screen == _Screen.tournamentChampion
              ? baseTournament.copyWith(
                  status: TournamentStatus.completed,
                  championTeamId: baseTournament.teams.first.id,
                )
              : baseTournament;
          final partyState = _partyState(screen);
          final offlinePreview = screen == _Screen.notifications;
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
                  id: 'v8-2-player',
                  username: 'لاعب_أحدعش',
                  isGuest: false,
                ),
              ),
              appContentProvider.overrideWithBuild(
                (ref, notifier) => AppContentBundle.defaults,
              ),
              categoriesRepositoryProvider.overrideWithValue(
                _CategoriesRepository(_categories),
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
                (ref, notifier) => partyState,
              ),
              tournamentControllerProvider.overrideWith(
                () => _TournamentController(tournament),
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
          if (screen == _Screen.createAccount) {
            await tester.tap(find.byKey(const ValueKey('auth-mode-toggle')));
            await tester.pumpAndSettle();
          }
          await tester.pump(const Duration(milliseconds: 150));
          await _precacheImages(tester, key);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(key),
            matchesGoldenFile(
              '../../../docs/visual-validation/v8-2-checkpoint/$fileName',
            ),
          );
        });
      }
    }
  }
}

Widget _screen(_Screen screen, Tournament tournament) => switch (screen) {
  _Screen.signIn || _Screen.createAccount => const AuthScreen(),
  _Screen.home => const HomeScreen(),
  _Screen.helpers => const PartyHelperSelectionScreen(),
  _Screen.ready => const PartyReadyScreen(),
  _Screen.result => const PartyResultScreen(),
  _Screen.tournamentHub => const TournamentHubScreen(),
  _Screen.tournamentDraw => const TournamentDrawScreen(),
  _Screen.tournamentMatch => TournamentMatchScreen(
    matchId: tournament.matches
        .where((match) => match.status == TournamentMatchStatus.ready)
        .last
        .id,
  ),
  _Screen.tournamentChampion => const TournamentChampionScreen(),
  _Screen.profile => const ProfileScreen(),
  _Screen.premium => const PremiumScreen(),
  _Screen.notifications => const NotificationsScreen(),
};

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

PartyGameState _partyState(_Screen screen) {
  final setup = screen == _Screen.helpers || screen == _Screen.ready;
  return PartyGameState(
    selectedCategoryIds: _categories
        .take(setup ? 6 : 3)
        .map((item) => item.id)
        .toList(),
    teams: _teams,
    favoriteCategoryIds: const {'c0', 'c2'},
    session: _session,
    restored: true,
  );
}

final class _CategoriesRepository implements CategoriesRepository {
  const _CategoriesRepository(this.values);
  final List<QuizCategory> values;

  @override
  Future<List<QuizCategory>> loadCategories({
    bool forceRefresh = false,
  }) async => values;
}

final class _TournamentController extends TournamentController {
  _TournamentController(this.fixture);
  final Tournament fixture;

  @override
  TournamentState build() => TournamentState(active: fixture, restored: true);

  @override
  Future<void> restore() async {}
}

Tournament _tournamentFixture() {
  var id = 0;
  final engine = TournamentEngine(idFactory: () => 'v8-2-${id++}');
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
  id: 'v8-2-player',
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
  id: 'v8-2-party',
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
          text: 'من سجل هدف الفوز في نهائي البطولة القارية؟',
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
