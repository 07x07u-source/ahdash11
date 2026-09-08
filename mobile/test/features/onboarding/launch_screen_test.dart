import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/onboarding/presentation/launch_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final scenario
      in <
        ({
          String name,
          bool onboardingCompleted,
          AuthUser? user,
          String destination,
        })
      >[
        (
          name: 'first launch opens onboarding',
          onboardingCompleted: false,
          user: null,
          destination: 'ONBOARDING',
        ),
        (
          name: 'returning signed-out player opens auth',
          onboardingCompleted: true,
          user: null,
          destination: 'AUTH',
        ),
        (
          name: 'authenticated player opens home',
          onboardingCompleted: true,
          user: const AuthUser(id: 'player', username: 'لاعب', isGuest: false),
          destination: 'HOME',
        ),
        (
          name: 'restored guest opens home',
          onboardingCompleted: true,
          user: const AuthUser(id: 'guest', username: 'ضيف', isGuest: true),
          destination: 'HOME',
        ),
      ]) {
    testWidgets(scenario.name, (tester) async {
      final router = GoRouter(
        initialLocation: '/launch',
        routes: [
          GoRoute(
            path: '/launch',
            builder: (_, _) =>
                const LaunchScreen(minimumDisplayDuration: Duration.zero),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const Scaffold(body: Text('ONBOARDING')),
          ),
          GoRoute(
            path: '/auth',
            builder: (_, _) => const Scaffold(body: Text('AUTH')),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithBuild(
              (ref, notifier) async => AppPreferences(
                onboardingCompleted: scenario.onboardingCompleted,
                reducedMotion: true,
              ),
            ),
            authControllerProvider.overrideWithBuild(
              (ref, notifier) async => scenario.user,
            ),
          ],
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: const Locale('ar'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(scenario.destination), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
