import 'dart:io';
import 'dart:ui' as ui;

import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/guest_capability_policy.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/auth/presentation/auth_gate.dart';
import 'package:ahdash_11/features/notifications/data/notifications_repository.dart';
import 'package:ahdash_11/features/notifications/presentation/notifications_screen.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_support_screens.dart';
import 'package:ahdash_11/features/premium/presentation/premium_controller.dart';
import 'package:ahdash_11/features/premium/presentation/premium_screen.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_controller.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_screen.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/presentation/blocked_players_screen.dart';
import 'package:ahdash_11/features/social/presentation/friends_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fake_social_repository.dart';
import '../fixtures/v10_feature_fixtures.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final ahdashFont = FontLoader('ThmanyahSans');
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      ahdashFont.addFont(
        rootBundle.load('assets/fonts/thmanyah/thmanyahsans-$weight.otf'),
      );
    }
    await ahdashFont.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
  });

  for (final scenario
      in <({String name, String destination, AppCapability capability})>[
        (
          name: 'guest/guest_friends_auth_gate_390x844.png',
          destination: '/friends',
          capability: AppCapability.friends,
        ),
        (
          name: 'guest/guest_blocked_players_auth_gate_390x844.png',
          destination: '/blocked-players',
          capability: AppCapability.friends,
        ),
        (
          name: 'guest/guest_team_challenge_auth_gate_390x844.png',
          destination: '/teams',
          capability: AppCapability.teamChallenge,
        ),
        (
          name: 'guest/guest_profile_auth_gate_390x844.png',
          destination: '/profile',
          capability: AppCapability.profile,
        ),
      ]) {
    testWidgets('capture ${scenario.name}', (tester) async {
      final container = ProviderContainer(retry: (_, _) => null);
      addTearDown(container.dispose);
      await _pump(
        tester,
        container,
        AuthGateScreen(
          destination: scenario.destination,
          requiredCapability: scenario.capability,
        ),
      );
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('إنشاء حساب'), findsOneWidget);
      expect(find.text('العودة'), findsOneWidget);
      await _capture(tester, scenario.name);
    });
  }

  for (final scenario in <({String name, Map<String, Object?> dashboard})>[
    (
      name: 'friends/friends_empty_390x844.png',
      dashboard: V10FeatureFixtures.emptyFriendsDashboard,
    ),
    (
      name: 'friends/friends_populated_fixture_390x844.png',
      dashboard: V10FeatureFixtures.populatedFriendsDashboard,
    ),
  ]) {
    testWidgets('capture ${scenario.name}', (tester) async {
      final repository = FakeSocialRepository(dashboard: scenario.dashboard);
      final container = _socialContainer(repository);
      addTearDown(container.dispose);
      await _pump(tester, container, const FriendsScreen());
      await _capture(tester, scenario.name);
    });
  }

  testWidgets('capture deterministic friend search results', (tester) async {
    final repository = FakeSocialRepository(
      searchResults: V10FeatureFixtures.friendSearchResults,
    );
    final container = _socialContainer(repository);
    addTearDown(container.dispose);
    await _pump(tester, container, const FriendsScreen());
    await tester.enterText(
      find.byKey(const ValueKey('friends-search-field')),
      'لاعب',
    );
    await tester.tap(find.byTooltip('بحث'));
    await tester.pumpAndSettle();
    await _capture(
      tester,
      'friends/friends_search_results_fixture_390x844.png',
    );
  });

  testWidgets('capture friend search no-results fixture', (tester) async {
    final repository = FakeSocialRepository();
    final container = _socialContainer(repository);
    addTearDown(container.dispose);
    await _pump(tester, container, const FriendsScreen());
    await tester.enterText(
      find.byKey(const ValueKey('friends-search-field')),
      'غائب',
    );
    await tester.tap(find.byTooltip('بحث'));
    await tester.pumpAndSettle();
    await _capture(tester, 'friends/friends_search_no_results_390x844.png');
  });

  testWidgets('capture friends loading fixture', (tester) async {
    final repository = FakeSocialRepository();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        socialRepositoryProvider.overrideWithValue(repository),
        friendsDashboardProvider.overrideWith(
          (ref) => DeterministicAsyncFixture.loading(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await _pump(tester, container, const FriendsScreen(), settle: false);
    await _capture(tester, 'loading/friends_loading_390x844.png');
  });

  testWidgets('capture friends error fixture', (tester) async {
    final repository = FakeSocialRepository()
      ..dashboardError = StateError('fixture dashboard failure');
    final container = _socialContainer(repository);
    addTearDown(container.dispose);
    await _pump(tester, container, const FriendsScreen());
    await _capture(tester, 'errors/friends_error_390x844.png');
  });

  for (final populated in [false, true]) {
    testWidgets('capture blocked players populated=$populated', (tester) async {
      final repository = FakeSocialRepository(
        blockedPlayers: populated
            ? V10FeatureFixtures.blockedPlayers
            : const [],
      );
      final container = _socialContainer(repository);
      addTearDown(container.dispose);
      await _pump(tester, container, const BlockedPlayersScreen());
      await _capture(
        tester,
        populated
            ? 'blocked/blocked_players_fixture_390x844.png'
            : 'blocked/blocked_players_empty_390x844.png',
      );
    });
  }

  testWidgets('capture blocked players error fixture', (tester) async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        socialRepositoryProvider.overrideWithValue(FakeSocialRepository()),
        blockedPlayersProvider.overrideWith(
          (ref) => DeterministicAsyncFixture.error(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await _pump(tester, container, const BlockedPlayersScreen());
    await _capture(tester, 'errors/blocked_players_error_390x844.png');
  });

  for (final populated in [false, true]) {
    testWidgets('capture saved games populated=$populated', (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final state = populated
          ? PartyGameState(
              restored: true,
              session: phase4BoardSession,
              history: [
                PartyGameSession.fromJson({
                  ...phase4CompletedSession().toJson(),
                  'id': 'fixture-history-session',
                }),
              ],
            )
          : const PartyGameState(restored: true);
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          partyGameControllerProvider.overrideWithBuild(
            (ref, notifier) => state,
          ),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, container, const PartyGamesScreen());
      await _capture(
        tester,
        populated
            ? 'party/saved_games_multiple_fixture_390x844.png'
            : 'empty_states/saved_games_empty_390x844.png',
      );
    });
  }

  testWidgets('capture ranking loading and error fixtures', (tester) async {
    var container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        leaderboardProvider.overrideWith(
          (ref) => DeterministicAsyncFixture.loading(),
        ),
      ],
    );
    await _pump(tester, container, const RankingScreen(), settle: false);
    await _capture(tester, 'loading/ranking_loading_390x844.png');
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();

    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        leaderboardProvider.overrideWith(
          (ref) => DeterministicAsyncFixture.error(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await _pump(tester, container, const RankingScreen());
    await _capture(tester, 'errors/ranking_error_390x844.png');
  });

  for (final populated in [false, true]) {
    testWidgets('capture ranking populated=$populated', (tester) async {
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          leaderboardProvider.overrideWith(
            (ref) async => populated ? V10FeatureFixtures.ranking : const [],
          ),
          appPreferencesProvider.overrideWithBuild(
            (ref, notifier) async => const AppPreferences(reducedMotion: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, container, const RankingScreen());
      await _capture(
        tester,
        populated
            ? 'ranking/ranking_populated_fixture_390x844.png'
            : 'empty_states/ranking_empty_390x844.png',
      );
    });
  }

  testWidgets('capture notifications loading and error fixtures', (
    tester,
  ) async {
    var container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        notificationsProvider.overrideWith(
          (ref) => DeterministicAsyncFixture.loading(),
        ),
      ],
    );
    await _pump(tester, container, const NotificationsScreen(), settle: false);
    await _capture(tester, 'loading/notifications_loading_390x844.png');
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();

    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        notificationsProvider.overrideWith(
          (ref) => DeterministicAsyncFixture.error(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await _pump(tester, container, const NotificationsScreen());
    await _capture(tester, 'errors/notifications_error_390x844.png');
  });

  for (final populated in [false, true]) {
    testWidgets('capture notifications populated=$populated', (tester) async {
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          notificationsProvider.overrideWith(
            (ref) async => populated ? phase6Notifications : const [],
          ),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, container, const NotificationsScreen());
      await _capture(
        tester,
        populated
            ? 'notifications/notifications_populated_fixture_390x844.png'
            : 'empty_states/notifications_empty_390x844.png',
      );
    });
  }

  for (final scenario in <({String name, Future<PremiumView> value})>[
    (
      name: 'premium/premium_loading_390x844.png',
      value: DeterministicAsyncFixture.loading<PremiumView>(),
    ),
    (
      name: 'premium/premium_packages_fixture_390x844.png',
      value: Future<PremiumView>.value(phase6Premium),
    ),
    (
      name: 'premium/premium_packages_unavailable_390x844.png',
      value: Future<PremiumView>.value(const PremiumView()),
    ),
  ]) {
    testWidgets('capture ${scenario.name}', (tester) async {
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          appServicesProvider.overrideWithValue(const AppServices.noop()),
          premiumControllerProvider.overrideWithBuild(
            (ref, notifier) => scenario.value,
          ),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, container, const PremiumScreen(), settle: false);
      await _capture(tester, scenario.name);
    });
  }
}

ProviderContainer _socialContainer(FakeSocialRepository repository) =>
    ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        socialRepositoryProvider.overrideWithValue(repository),
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => V10FeatureFixtures.account,
        ),
        appPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => const AppPreferences(reducedMotion: true),
        ),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen, {
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: testApp(
        const MediaQuery(
          data: MediaQueryData(size: Size(390, 844), disableAnimations: true),
          child: SizedBox.shrink(),
        ),
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: testApp(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: screen,
        ),
        theme: AppTheme.light,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String relativePath) async {
  const output = String.fromEnvironment('FULL_FEATURE_QA_DIR');
  if (output.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('test-app-boundary')),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$output/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
