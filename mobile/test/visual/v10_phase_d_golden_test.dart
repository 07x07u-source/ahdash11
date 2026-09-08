import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/categories/presentation/categories_controller.dart';
import 'package:ahdash_11/features/match/presentation/solo_setup_screen.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_support_screens.dart';
import 'package:ahdash_11/features/play/presentation/play_screen.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_controller.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_screen.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/domain/social_entities.dart';
import 'package:ahdash_11/features/social/presentation/blocked_players_screen.dart';
import 'package:ahdash_11/features/social/presentation/friends_screen.dart';
import 'package:ahdash_11/features/social/presentation/social_team_screen.dart';
import 'package:ahdash_11/features/social/presentation/team_challenge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fake_social_repository.dart';
import '../helpers/party_phase4_fixture.dart';
import '../helpers/test_app.dart';
import '../helpers/visual_test_variant.dart';

enum _PhaseDVisual {
  howTo,
  savedGames,
  matchSetup,
  solo,
  teamChallenge,
  ranking,
  friends,
  friendsKeyboard,
  blocked,
  teamDetail,
}

void main() => registerVisualTests();

void registerVisualTests({VisualTestVariant? variant}) {
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
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
  });

  final sizes = variant == null
      ? const [Size(390, 844), Size(360, 800)]
      : [variant.size];
  for (final size in sizes) {
    for (final visual in _PhaseDVisual.values) {
      final dimensions = '${size.width.round()}x${size.height.round()}';
      testWidgets('phase D ${visual.name} $dimensions', (tester) async {
        final keyboard = visual == _PhaseDVisual.friendsKeyboard;
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1
          ..viewInsets = keyboard
              ? const FakeViewPadding(bottom: 300)
              : FakeViewPadding.zero;
        addTearDown(() {
          tester.view
            ..resetPhysicalSize()
            ..resetDevicePixelRatio()
            ..resetViewInsets();
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(_config),
              appServicesProvider.overrideWithValue(const AppServices.noop()),
              partyGameControllerProvider.overrideWithBuild(
                (ref, notifier) => PartyGameState(
                  restored: true,
                  session: phase4BoardSession,
                  history: [
                    PartyGameSession.fromJson({
                      ...phase4CompletedSession().toJson(),
                      'id': 'phase4-history-fixture',
                    }).copyWith(
                      teams: [
                        phase4Teams[0].copyWith(name: 'عميد جدة'),
                        phase4Teams[1].copyWith(name: 'فارس نجد'),
                      ],
                      scores: const [300, 300],
                    ),
                  ],
                ),
              ),
              categoriesProvider.overrideWithBuild(
                (ref, notifier) async => const [],
              ),
              leaderboardProvider.overrideWith((ref) async => const []),
              socialRepositoryProvider.overrideWithValue(
                FakeSocialRepository(dashboard: _friendsDashboard),
              ),
              blockedPlayersProvider.overrideWith(
                (ref) async => _blockedPlayers,
              ),
              socialTeamDetailProvider.overrideWith(
                (ref, teamId) async => _team,
              ),
            ],
            child: testApp(
              MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(variant?.scale ?? 1),
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                  viewInsets: keyboard
                      ? const EdgeInsets.only(bottom: 300)
                      : EdgeInsets.zero,
                  disableAnimations: true,
                ),
                child: _screen(visual),
              ),
              theme: AppTheme.light,
            ),
          ),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        if (keyboard) {
          await tester.tap(find.byType(TextField).first);
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await verifyVisual(
          tester,
          find.byType(MaterialApp),
          'goldens/v10_phase_d/${visual.name}_$dimensions.png',
          variant,
        );
      });
    }
  }
}

Widget _screen(_PhaseDVisual visual) => switch (visual) {
  _PhaseDVisual.howTo => const HowToPlayScreen(),
  _PhaseDVisual.savedGames => const PartyGamesScreen(),
  _PhaseDVisual.matchSetup => const PlayScreen(),
  _PhaseDVisual.solo => const SoloSetupScreen(),
  _PhaseDVisual.teamChallenge => const TeamChallengeScreen(
    challengeId: 'challenge-fixture',
    enableCountdown: false,
  ),
  _PhaseDVisual.ranking => const RankingScreen(),
  _PhaseDVisual.friends ||
  _PhaseDVisual.friendsKeyboard => const FriendsScreen(),
  _PhaseDVisual.blocked => const BlockedPlayersScreen(),
  _PhaseDVisual.teamDetail => const SocialTeamScreen(teamId: 'team-fixture'),
};

const _config = AppConfig(
  environment: AppEnvironment.production,
  supabaseUrl: '',
  supabaseKey: '',
  firebaseEnabled: false,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
);

const _blockedPlayers = [
  {
    'user_id': 'blocked-fixture',
    'display_name': 'لاعب محظور',
    'username': 'blocked_fixture',
    'avatar_url': null,
  },
];

const _friendsDashboard = <String, Object?>{
  'inbox': <Object?>[],
  'outbox': <Object?>[],
  'friends': <Object?>[
    <String, Object?>{
      'user_id': 'friend-1',
      'display_name': 'خالد العتيبي',
      'username': 'khalid',
      'avatar_url': null,
    },
    <String, Object?>{
      'user_id': 'friend-2',
      'display_name': 'سعد بن محمد',
      'username': 'saad',
      'avatar_url': null,
    },
    <String, Object?>{
      'user_id': 'friend-3',
      'display_name': 'فهد الحربي',
      'username': 'fahad',
      'avatar_url': null,
    },
  ],
};

const _team = SocialTeamDetail(
  id: 'team-fixture',
  name: 'صقور الجزيرة',
  description: 'مجلس خاص لأعضاء الفريق.',
  primaryColor: '#5F8F0F',
  badgeSeed: '11',
  currentRole: 'owner',
  currentUserId: 'owner-fixture',
  members: [
    SocialTeamMember(
      userId: 'owner-fixture',
      displayName: 'سلمان الحربي',
      role: 'owner',
      level: 0,
      weeklyPoints: 0,
      rank: 0,
    ),
    SocialTeamMember(
      userId: 'member-fixture',
      displayName: 'فيصل الزهراني',
      role: 'member',
      level: 0,
      weeklyPoints: 0,
      rank: 0,
    ),
    SocialTeamMember(
      userId: 'member-fixture-2',
      displayName: 'خالد منصور',
      role: 'member',
      level: 0,
      weeklyPoints: 0,
      rank: 0,
    ),
    SocialTeamMember(
      userId: 'member-fixture-3',
      displayName: 'أحمد العتيبي',
      role: 'member',
      level: 0,
      weeklyPoints: 0,
      rank: 0,
    ),
  ],
  challenges: [],
  activity: [],
  weeklyMvp: null,
);
