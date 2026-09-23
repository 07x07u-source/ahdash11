import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/routing/app_router.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_repository.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/auth/presentation/auth_gate.dart';
import 'package:ahdash_11/features/auth/presentation/auth_screen.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/profile/presentation/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/party_phase4_fixture.dart';
import '../../helpers/phase6_fixture.dart';

void main() {
  testWidgets(
    'real router gates every private guest deep link before mounting private data',
    (tester) async {
      var profileReads = 0;
      final (container, router) = await pumpGuestRouter(
        tester,
        onProfile: () => profileReads++,
      );
      for (final path in [
        '/profile',
        '/blocked-players',
        '/teams',
        '/notifications',
        '/ranking',
        '/premium',
        '/football-preferences',
        '/report-problem',
        '/party/games',
        '/tournaments',
        '/tournaments/create',
        '/tournaments/join?code=ABC123',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(find.byType(AuthGateScreen), findsOneWidget, reason: path);
        expect(
          router.routeInformationProvider.value.uri.queryParameters['next'],
          path,
        );
        expect(tester.takeException(), isNull);
      }
      expect(profileReads, 0);
      expect(
        container.read(partyGameControllerProvider).session,
        same(phase4BoardSession),
      );
    },
  );

  testWidgets('legacy Friends and Online routes return guests safely to Home', (
    tester,
  ) async {
    final (_, router) = await pumpGuestRouter(tester);
    for (final path in [
      '/friends',
      '/friends?teamId=legacy-team',
      '/online',
      '/online/match/legacy-match',
      '/room/legacy-room',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/home',
        reason: path,
      );
      expect(find.byType(AuthGateScreen), findsNothing, reason: path);
      expect(tester.takeException(), isNull, reason: path);
    }
  });

  testWidgets(
    'guest signs in through gate and resumes intended destination without losing Party',
    (tester) async {
      final (container, router) = await pumpGuestRouter(tester);
      router.go('/profile');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('gate-sign-in')));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).at(0),
        'player@example.test',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Password123');
      final submit = find.byKey(const ValueKey('auth-primary-action'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      expect(container.read(authControllerProvider).value?.isGuest, isFalse);
      expect(
        container.read(partyGameControllerProvider).session,
        same(phase4BoardSession),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'create account gate preserves intent and opens account creation mode',
    (tester) async {
      final (_, router) = await pumpGuestRouter(tester);
      router.go('/tournaments');
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('gate-create-account')),
      );
      await tester.tap(find.byKey(const ValueKey('gate-create-account')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AuthScreen>(find.byType(AuthScreen)).initialMode,
        AuthMode.createAccount,
      );
      expect(
        router.routeInformationProvider.value.uri.queryParameters['next'],
        '/tournaments',
      );
    },
  );

  testWidgets('guest can use local settings and rules without upgrading', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final (container, router) = await pumpGuestRouter(tester);
    for (final path in ['/how-to-play', '/settings']) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, path);
      expect(find.byType(AuthGateScreen), findsNothing);
    }

    expect(find.byKey(const ValueKey('settings-scroll')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-device-preferences')),
      findsOneWidget,
    );
    for (final key in [
      'settings-quick-sound',
      'settings-quick-haptics',
      'settings-quick-motion',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }

    expect(container.read(appPreferencesProvider).value?.soundEffects, isTrue);
    await tester.tap(find.byKey(const ValueKey('settings-quick-sound')));
    await tester.pumpAndSettle();
    expect(container.read(appPreferencesProvider).value?.soundEffects, isFalse);
    expect(router.routeInformationProvider.value.uri.path, '/settings');
    expect(find.byType(AuthGateScreen), findsNothing);
    expect(find.byType(AuthScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AHDASH dock uses real routes, ignores duplicate taps and stays out of entry',
    (tester) async {
      final (_, router) = await pumpGuestRouter(tester);
      router.go('/home');
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('التنقل الرئيسي'), findsOneWidget);
      expect(find.byKey(const ValueKey('main-dock-home')), findsOneWidget);
      expect(find.byKey(const ValueKey('main-dock-play')), findsOneWidget);
      expect(find.byKey(const ValueKey('main-dock-tournaments')), findsNothing);
      expect(find.byKey(const ValueKey('main-dock-teams')), findsNothing);
      expect(find.byKey(const ValueKey('main-dock-profile')), findsOneWidget);
      expect(find.text('Online'), findsNothing);
      expect(find.text('أونلاين (قريبًا)'), findsNothing);
      expect(find.text('الأصدقاء'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('main-dock-play')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/play');
      await tester.tap(find.byKey(const ValueKey('main-dock-play')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/play');
      expect(router.canPop(), isFalse);

      await tester.tap(find.byKey(const ValueKey('main-dock-profile')));
      await tester.pumpAndSettle();
      expect(find.byType(AuthGateScreen), findsOneWidget);
      expect(find.bySemanticsLabel('التنقل الرئيسي'), findsNothing);

      router.go('/auth');
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.bySemanticsLabel('التنقل الرئيسي'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<(ProviderContainer, GoRouter)> pumpGuestRouter(
  WidgetTester tester, {
  VoidCallback? onProfile,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(phase6Config),
      appServicesProvider.overrideWithValue(const AppServices.noop()),
      authRepositoryProvider.overrideWithValue(_Auth()),
      appPreferencesProvider.overrideWithBuild(
        (ref, notifier) async => const AppPreferences(
          onboardingCompleted: true,
          reducedMotion: true,
        ),
      ),
      partyGameControllerProvider.overrideWithBuild(
        (ref, notifier) =>
            PartyGameState(restored: true, session: phase4BoardSession),
      ),
      playerProfileProvider.overrideWith((ref) async {
        onProfile?.call();
        return phase6Profile;
      }),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.future);
  final router = container.read(appRouterProvider);
  router.go('/settings');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, router);
}

final class _Auth implements AuthRepository {
  static const guest = AuthUser(
    id: 'anonymous',
    username: 'ضيف',
    isGuest: true,
  );
  static const account = AuthUser(
    id: 'real-account',
    username: 'محمد',
    isGuest: false,
  );
  @override
  Future<AuthUser?> restore() async => guest;
  @override
  Future<AuthUser> continueAsGuest() async => guest;
  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async => account;
  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) async => account;
  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) async =>
      const SocialSignInAuthenticated(account);
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
}
