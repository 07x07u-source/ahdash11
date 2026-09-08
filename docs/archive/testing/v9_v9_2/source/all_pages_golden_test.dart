import 'dart:async';
import 'dart:convert';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/config/game_settings_repository.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/categories/domain/categories_repository.dart';
import 'package:ahdash_11/features/categories/presentation/categories_controller.dart';
import 'package:ahdash_11/features/game/domain/game_mode.dart';
import 'package:ahdash_11/features/game/presentation/game_setup_screen.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/match/presentation/solo_match_controller.dart';
import 'package:ahdash_11/features/match/presentation/solo_setup_screen.dart';
import 'package:ahdash_11/features/notifications/presentation/notifications_screen.dart';
import 'package:ahdash_11/features/onboarding/presentation/launch_screen.dart';
import 'package:ahdash_11/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_support_screens.dart';
import 'package:ahdash_11/features/profile/domain/player_profile.dart';
import 'package:ahdash_11/features/profile/presentation/profile_controller.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_screen.dart';
import 'package:ahdash_11/features/settings/presentation/settings_screen.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/domain/social_entities.dart';
import 'package:ahdash_11/features/social/presentation/blocked_players_screen.dart';
import 'package:ahdash_11/features/social/presentation/friends_screen.dart';
import 'package:ahdash_11/features/social/presentation/social_join_team_screen.dart';
import 'package:ahdash_11/features/social/presentation/social_team_screen.dart';
import 'package:ahdash_11/features/social/presentation/team_challenge_screen.dart';
import 'package:ahdash_11/features/support/presentation/report_problem_screen.dart';
import 'package:ahdash_11/features/tournament/domain/tournament.dart';
import 'package:ahdash_11/features/tournament/domain/tournament_engine.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_join_screen.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_registrations_screen.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_screens.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:ahdash_11/shared/domain/game_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../helpers/test_app.dart';

enum _GalleryPage {
  launch,
  onboarding,
  gameSetup,
  soloSetup,
  ranking,
  friends,
  blockedPlayers,
  socialJoinTeam,
  socialTeam,
  teamChallenge,
  notifications,
  reportProblem,
  partyGames,
  tournamentJoin,
  tournamentRegistrations,
  tournamentMatch,
  settings,
}

void main() {
  final tournament = _TournamentFixture();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://preview.supabase.co',
      publishableKey: 'preview-public-key',
      httpClient: MockClient(_previewResponse),
      debug: false,
    );
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

  const sizes = [
    Size(800, 360),
    Size(844, 390),
    Size(915, 412),
    Size(1280, 720),
    Size(1366, 768),
  ];
  for (final size in sizes) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final page in _GalleryPage.values) {
        final dimensions = '${size.width.round()}x${size.height.round()}';
        testWidgets('gallery ${page.name} $dimensions ${brightness.name}', (
          tester,
        ) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(() {
            tester.view
              ..resetPhysicalSize()
              ..resetDevicePixelRatio();
          });

          final database = AppDatabase(NativeDatabase.memory());
          final container = _container(page, tournament.tournament, database);
          addTearDown(() async {
            container.dispose();
            await database.close();
          });
          final key = ValueKey('gallery-${page.name}');
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: testApp(
                MediaQuery(
                  data: MediaQueryData(size: size, disableAnimations: true),
                  child: RepaintBoundary(
                    key: key,
                    child: _screen(page, tournament.matchId),
                  ),
                ),
                theme: brightness == Brightness.light
                    ? AppTheme.light
                    : AppTheme.dark,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 220));
          await _precacheImages(tester, key);
          await tester.pump();
          await expectLater(
            find.byKey(key),
            matchesGoldenFile(
              '../../../docs/screenshots/mobile/pages/'
              '${page.name}_${size.width.toInt()}x${size.height.toInt()}_'
              '${brightness.name}.png',
            ),
          );
          if (page == _GalleryPage.launch) {
            await tester.pump(const Duration(milliseconds: 600));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  const portraitSize = Size(390, 844);
  for (final page in _GalleryPage.values) {
    testWidgets('gallery portrait smoke ${page.name}', (tester) async {
      tester.view
        ..physicalSize = portraitSize
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });

      final database = AppDatabase(NativeDatabase.memory());
      final container = _container(page, tournament.tournament, database);
      addTearDown(() async {
        container.dispose();
        await database.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(
            MediaQuery(
              data: const MediaQueryData(
                size: portraitSize,
                disableAnimations: true,
              ),
              child: _screen(page, tournament.matchId),
            ),
            theme: AppTheme.light,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(tester.takeException(), isNull);
      if (page == _GalleryPage.launch) {
        await tester.pump(const Duration(milliseconds: 600));
      }
    });
  }
}

ProviderContainer _container(
  _GalleryPage page,
  Tournament tournament,
  AppDatabase database,
) {
  final online = switch (page) {
    _GalleryPage.teamChallenge => true,
    _ => false,
  };
  return ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig(
          environment: AppEnvironment.production,
          supabaseUrl: online ? 'https://preview.supabase.co' : '',
          supabaseKey: online ? 'preview-public-key' : '',
          firebaseEnabled: false,
          adMobEnabled: false,
          revenueCatAndroidKey: '',
          revenueCatIosKey: '',
        ),
      ),
      appServicesProvider.overrideWithValue(const AppServices.noop()),
      appDatabaseProvider.overrideWithValue(database),
      authControllerProvider.overrideWithBuild(
        (ref, notifier) => page == _GalleryPage.launch
            ? Completer<AuthUser?>().future
            : const AuthUser(
                id: 'preview-user',
                username: 'لاعب_أحدعش',
                isGuest: false,
              ),
      ),
      playerProfileProvider.overrideWith((ref) async => _profile),
      categoriesRepositoryProvider.overrideWithValue(
        const _GalleryCategoriesRepository(_categories),
      ),
      gameSettingsProvider.overrideWith(
        (ref) async => const GameSettings(questionTimeSeconds: 60),
      ),
      soloMatchControllerProvider.overrideWithBuild(
        (ref, notifier) => const SoloMatchState(),
      ),
      partyGameControllerProvider.overrideWithBuild(
        (ref, notifier) =>
            PartyGameState(session: _partySession, restored: true),
      ),
      tournamentControllerProvider.overrideWith(
        () => _GalleryTournamentController(tournament),
      ),
      socialHubProvider.overrideWith((ref) async => _socialHub),
      socialTeamDetailProvider.overrideWith((ref, teamId) async => _socialTeam),
      blockedPlayersProvider.overrideWith((ref) async => _blockedPlayers),
    ],
  );
}

Widget _screen(_GalleryPage page, String tournamentMatchId) => switch (page) {
  _GalleryPage.launch => const LaunchScreen(),
  _GalleryPage.onboarding => const OnboardingScreen(),
  _GalleryPage.gameSetup => const GameSetupScreen(gameType: GameType.classic),
  _GalleryPage.soloSetup => const SoloSetupScreen(),
  _GalleryPage.ranking => const RankingScreen(),
  _GalleryPage.friends => const FriendsScreen(),
  _GalleryPage.blockedPlayers => const BlockedPlayersScreen(),
  _GalleryPage.socialJoinTeam => const SocialJoinTeamScreen(
    initialCode: 'A11TEAM',
  ),
  _GalleryPage.socialTeam => const SocialTeamScreen(teamId: 'team-11'),
  _GalleryPage.teamChallenge => const TeamChallengeScreen(
    challengeId: 'challenge-11',
    enableCountdown: false,
  ),
  _GalleryPage.notifications => const NotificationsScreen(),
  _GalleryPage.reportProblem => const ReportProblemScreen(
    sourceScreen: '/settings',
  ),
  _GalleryPage.partyGames => const PartyGamesScreen(),
  _GalleryPage.tournamentJoin => const TournamentJoinScreen(
    initialCode: 'A11CUP26',
    initialPlayersPerTeam: 2,
  ),
  _GalleryPage.tournamentRegistrations => const TournamentRegistrationsScreen(),
  _GalleryPage.tournamentMatch => TournamentMatchScreen(
    matchId: tournamentMatchId,
  ),
  _GalleryPage.settings => const SettingsScreen(),
};

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

Future<http.Response> _previewResponse(http.Request request) async {
  final path = request.url.path;
  final headers = {'content-type': 'application/json; charset=utf-8'};
  final now = _galleryNow;
  Object body;
  if (path.endsWith('/match_question_payloads')) {
    body = {
      'match_question_id': 'preview-match-question',
      'question_text': 'من صاحب الرقم القياسي في تسجيل أهداف المنتخب السعودي؟',
      'options': [
        {'id': 'option-1', 'text': 'ماجد عبدالله'},
        {'id': 'option-2', 'text': 'سالم الدوسري'},
        {'id': 'option-3', 'text': 'سامي الجابر'},
        {'id': 'option-4', 'text': 'ياسر القحطاني'},
      ],
      'category_id': 'history',
      'difficulty': 'medium',
      'sequence_number': 4,
      'duration_ms': 15000,
      'game_type': 'classic',
      'server_now': now.toIso8601String(),
      'server_deadline': now.add(const Duration(seconds: 15)).toIso8601String(),
    };
  } else if (path.endsWith('/rooms')) {
    body = {
      'code': '110011',
      'host_user_id': 'preview-user',
      'match_id': 'preview-match',
      'mode': 'friend_1v1',
      'status': 'open',
      'max_members': 2,
    };
  } else if (path.endsWith('/room_members')) {
    body = [
      {
        'user_id': 'preview-user',
        'team': 1,
        'seat': 1,
        'status': 'ready',
        'last_seen_at': '2026-09-01T12:00:00Z',
      },
      {
        'user_id': 'friend-user',
        'team': 2,
        'seat': 1,
        'status': 'ready',
        'last_seen_at': '2026-09-01T12:00:00Z',
      },
    ];
  } else if (path.endsWith('/profiles')) {
    body = [
      {
        'id': 'preview-user',
        'username': 'لاعب_أحدعش',
        'display_name': 'سلمان الحربي',
        'avatar_url': null,
        'rating': 1311,
      },
      {
        'id': 'friend-user',
        'username': 'صقر_نجد',
        'display_name': 'نواف العتيبي',
        'avatar_url': null,
        'rating': 1270,
      },
    ];
  } else if (path.endsWith('/rpc/start_team_challenge_attempt')) {
    body = {'attempt_id': 'preview-attempt'};
  } else if (path.endsWith('/rpc/get_team_challenge_question')) {
    body = {
      'question_id': 'challenge-question',
      'challenge_title': 'تحدي ليلة الكورة',
      'question_count': 5,
      'sequence': 2,
      'duration_ms': 20000,
      'server_now': now.toIso8601String(),
      'closes_at': now.add(const Duration(seconds: 20)).toIso8601String(),
      'question_text': 'أي نادٍ حقق أكبر عدد من ألقاب دوري أبطال أوروبا؟',
      'options': [
        {'id': 'a', 'text': 'ريال مدريد'},
        {'id': 'b', 'text': 'ميلان'},
        {'id': 'c', 'text': 'ليفربول'},
        {'id': 'd', 'text': 'بايرن ميونخ'},
      ],
    };
  } else if (path.endsWith('/matches')) {
    body = {'status': 'active', 'winner_team': null};
  } else {
    body = <Object?>[];
  }
  return http.Response(
    jsonEncode(body),
    200,
    headers: headers,
    request: request,
  );
}

const _profile = PlayerProfile(
  id: 'preview-user',
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
  isPremium: true,
);

const _categories = [
  QuizCategory(
    id: 'history',
    name: 'تاريخ الكرة',
    description: 'لحظات صنعت اللعبة',
    iconName: 'history',
    accentColor: Color(0xFFD6A84B),
    imageUrl: 'assets/visuals/eagle-eye-cover.png',
  ),
  QuizCategory(
    id: 'saudi',
    name: 'دوري روشن السعودي للمحترفين',
    description: 'الموسم السعودي الجديد',
    iconName: 'trophy',
    accentColor: Color(0xFF5F8F0F),
    imageUrl: 'assets/visuals/eagle-eye-cover.png',
  ),
];

final class _GalleryCategoriesRepository implements CategoriesRepository {
  const _GalleryCategoriesRepository(this.values);
  final List<QuizCategory> values;

  @override
  Future<List<QuizCategory>> loadCategories({
    bool forceRefresh = false,
  }) async => values;
}

final _galleryNow = DateTime.utc(2026, 9, 1, 12);

final _partySession = PartyGameSession(
  id: 'gallery-party',
  teams: const [
    PartyTeam(name: 'صقور الجزيرة', colorValue: 0xFF2368A2),
    PartyTeam(name: 'ذئاب المدرج', colorValue: 0xFFB63863),
  ],
  categories: const [
    PartyCategorySnapshot(
      id: 'history',
      name: 'تاريخ الكرة',
      colorValue: 0xFF5F8F0F,
      ownerTeamIndex: 0,
      questions: [
        PartyQuestionSnapshot(
          id: 'gallery-question',
          categoryId: 'history',
          text: 'من سجل هدف النهائي؟',
          answer: 'اللاعب أحدعش',
          difficulty: QuestionDifficulty.easy,
          pointValue: 100,
          format: PartyQuestionFormat.openAnswer,
        ),
      ],
    ),
  ],
  timerSeconds: 30,
  createdAt: DateTime(2026, 9),
  scores: const [700, 500],
);

const _socialHub = SocialHub(
  team: SocialTeamSummary(
    id: 'team-11',
    name: 'صقور نجد',
    primaryColor: '#5F8F0F',
    badgeSeed: 'SN',
    role: 'owner',
    memberCount: 5,
    activeChallenges: 2,
  ),
  invites: [],
);

final _socialTeam = SocialTeamDetail(
  id: 'team-11',
  name: 'صقور نجد',
  description: 'فريق يجمع عشاق الكرة السعودية وليالي التحدي.',
  primaryColor: '#5F8F0F',
  badgeSeed: 'SN',
  currentRole: 'owner',
  currentUserId: 'preview-user',
  members: const [
    SocialTeamMember(
      userId: 'preview-user',
      displayName: 'سلمان الحربي',
      role: 'owner',
      level: 11,
      weeklyPoints: 1480,
      rank: 1,
    ),
    SocialTeamMember(
      userId: 'friend-user',
      displayName: 'نواف العتيبي',
      role: 'member',
      level: 8,
      weeklyPoints: 970,
      rank: 2,
    ),
  ],
  challenges: [
    SocialTeamChallenge(
      id: 'challenge-11',
      title: 'تحدي ليلة الكورة',
      questionCount: 5,
      status: 'active',
      isOfficial: true,
      attemptsUsed: 0,
      endsAt: DateTime(2100),
    ),
  ],
  activity: const [],
  weeklyMvp: const SocialTeamMember(
    userId: 'preview-user',
    displayName: 'سلمان الحربي',
    role: 'owner',
    level: 11,
    weeklyPoints: 1480,
    rank: 1,
  ),
);

const _blockedPlayers = [
  {
    'user_id': 'blocked-user',
    'display_name': 'لاعب محظور',
    'username': 'blocked_11',
    'avatar_url': null,
  },
];

final class _TournamentFixture {
  _TournamentFixture() {
    var sequence = 0;
    final engine = TournamentEngine(
      idFactory: () => 'gallery-tournament-${sequence++}',
    );
    var value = engine.create(
      name: 'كأس ليلة الكورة',
      organizerId: 'preview-user',
      rules: const TournamentRules(capacity: 4),
      now: DateTime.utc(2026, 9),
    );
    for (final name in ['الصقور', 'المدرج', 'التكتيك', 'الأساطير']) {
      value = engine.addTeam(value, name: name);
    }
    tournament = engine.generateBracket(value, randomSeed: 11);
    matchId = tournament.matches.first.id;
  }

  late final Tournament tournament;
  late final String matchId;
}

final class _GalleryTournamentController extends TournamentController {
  _GalleryTournamentController(this.fixture);
  final Tournament fixture;

  @override
  TournamentState build() => TournamentState(active: fixture, restored: true);

  @override
  Future<void> restore() async {}
}
