import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/features/categories/presentation/categories_controller.dart';
import 'package:ahdash_11/features/match/presentation/solo_setup_screen.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  const sizes = [
    Size(360, 800),
    Size(390, 844),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ];
  const scales = [1.0, 1.2, 1.3];

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets(
        'Phase D surfaces fit ${size.width}x${size.height} at $scale',
        (tester) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(() {
            tester.view
              ..resetPhysicalSize()
              ..resetDevicePixelRatio();
          });
          for (final screen in _screens) {
            await tester.pumpWidget(_scope(size, scale, screen));
            await tester.pump(const Duration(milliseconds: 120));
            expect(
              tester.takeException(),
              isNull,
              reason: screen.runtimeType.toString(),
            );
          }
        },
      );
    }
  }

  for (final size in const [Size(360, 800), Size(390, 844)]) {
    testWidgets('Friends search stays reachable with keyboard at $size', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1
        ..viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio()
          ..resetViewInsets();
      });
      await tester.pumpWidget(
        _scope(size, 1.3, const FriendsScreen(), inset: 300),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('friends-search-field'));
      expect(field, findsOneWidget);
      await tester.tap(field);
      await tester.enterText(field, 'لاعب');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _scope(Size size, double scale, Widget screen, {double inset = 0}) =>
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(_config),
        appServicesProvider.overrideWithValue(const AppServices.noop()),
        partyGameControllerProvider.overrideWithBuild(
          (ref, notifier) => const PartyGameState(restored: true),
        ),
        categoriesProvider.overrideWithBuild((ref, notifier) async => const []),
        leaderboardProvider.overrideWith((ref) async => const []),
        blockedPlayersProvider.overrideWith((ref) async => const []),
        socialTeamDetailProvider.overrideWith((ref, id) async => _team),
      ],
      child: testApp(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: inset),
            disableAnimations: true,
          ),
          child: screen,
        ),
      ),
    );

const _screens = <Widget>[
  HowToPlayScreen(),
  PartyGamesScreen(),
  PlayScreen(),
  SoloSetupScreen(),
  TeamChallengeScreen(challengeId: 'unavailable', enableCountdown: false),
  RankingScreen(),
  FriendsScreen(),
  BlockedPlayersScreen(),
  SocialTeamScreen(teamId: 'team'),
];

const _config = AppConfig(
  environment: AppEnvironment.production,
  supabaseUrl: '',
  supabaseKey: '',
  firebaseEnabled: false,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
);

const _team = SocialTeamDetail(
  id: 'team',
  name: 'فريق عربي طويل',
  description: null,
  primaryColor: '#5F8F0F',
  badgeSeed: '11',
  currentRole: 'owner',
  currentUserId: 'owner',
  members: [],
  challenges: [],
  activity: [],
  weeklyMvp: null,
);
