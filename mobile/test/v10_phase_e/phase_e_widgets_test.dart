import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/football/presentation/football_preferences_controller.dart';
import 'package:ahdash_11/features/football/presentation/football_preferences_screen.dart';
import 'package:ahdash_11/features/notifications/data/notifications_repository.dart';
import 'package:ahdash_11/features/notifications/presentation/notifications_screen.dart';
import 'package:ahdash_11/features/premium/presentation/premium_controller.dart';
import 'package:ahdash_11/features/premium/presentation/premium_screen.dart';
import 'package:ahdash_11/features/profile/presentation/profile_controller.dart';
import 'package:ahdash_11/features/profile/presentation/profile_screen.dart';
import 'package:ahdash_11/features/settings/presentation/settings_screen.dart';
import 'package:ahdash_11/features/support/presentation/report_problem_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/phase6_fixture.dart';
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
        'Phase E surfaces fit ${size.width}x${size.height} at $scale',
        (tester) async {
          _view(tester, size);
          for (final screen in _screens) {
            await tester.pumpWidget(_scope(size, scale, screen));
            await tester.pump(const Duration(milliseconds: 100));
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
    for (final target in const ['report', 'football']) {
      testWidgets('$target keyboard stays reachable at $size', (tester) async {
        _view(tester, size, keyboard: 300);
        final screen = target == 'report'
            ? const ReportProblemScreen(sourceScreen: '/settings')
            : const FootballPreferencesScreen();
        await tester.pumpWidget(_scope(size, 1.3, screen, inset: 300));
        await tester.pumpAndSettle();
        final field = find.byKey(
          ValueKey(
            '$target-${target == 'report' ? 'description-' : 'search-'}field',
          ),
        );
        expect(field, findsOneWidget);
        await tester.showKeyboard(field);
        await tester.enterText(field, 'بحث عربي طويل');
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

void _view(WidgetTester tester, Size size, {double keyboard = 0}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio()
      ..resetViewInsets();
  });
}

Widget _scope(Size size, double scale, Widget screen, {double inset = 0}) =>
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(phase6Config),
        appServicesProvider.overrideWithValue(const AppServices.noop()),
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => phase6User,
        ),
        appPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => const AppPreferences(),
        ),
        playerProfileProvider.overrideWith((ref) async => phase6Profile),
        notificationsProvider.overrideWith((ref) async => phase6Notifications),
        footballPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => phase6Football,
        ),
        premiumControllerProvider.overrideWithBuild(
          (ref, notifier) async => phase6Premium,
        ),
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
  ProfileScreen(),
  NotificationsScreen(),
  SettingsScreen(),
  ReportProblemScreen(sourceScreen: '/settings'),
  FootballPreferencesScreen(),
  PremiumScreen(),
];
