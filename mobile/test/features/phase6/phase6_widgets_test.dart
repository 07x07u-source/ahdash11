import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
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

import '../../helpers/phase6_fixture.dart';
import '../../helpers/test_app.dart';

Future<void> pumpPhase6(
  WidgetTester tester,
  Widget screen, {
  double scale = 1,
  double keyboard = 0,
  bool unavailable = false,
}) async {
  tester.view
    ..physicalSize = const Size(800, 360)
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      appConfigProvider.overrideWithValue(phase6Config),
      appServicesProvider.overrideWithValue(const AppServices.noop()),
      authControllerProvider.overrideWithBuild(
        (ref, notifier) async => phase6User,
      ),
      appPreferencesProvider.overrideWithBuild(
        (ref, notifier) async => const AppPreferences(
          soundEffects: false,
          haptics: false,
          reducedMotion: true,
        ),
      ),
      playerProfileProvider.overrideWith((ref) async {
        if (unavailable) throw StateError('private failure');
        return phase6Profile;
      }),
      notificationsProvider.overrideWith(
        (ref) async => unavailable ? [] : phase6Notifications,
      ),
      footballPreferencesProvider.overrideWithBuild(
        (ref, notifier) async =>
            unavailable ? const FootballView() : phase6Football,
      ),
      premiumControllerProvider.overrideWithBuild(
        (ref, notifier) async =>
            unavailable ? const PremiumView() : phase6Premium,
      ),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: testApp(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(800, 360),
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
            disableAnimations: true,
          ),
          child: screen,
        ),
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final screens = <String, Widget>{
    'profile': const ProfileScreen(),
    'notifications': const NotificationsScreen(),
    'settings': const SettingsScreen(),
    'report': const ReportProblemScreen(sourceScreen: '/settings'),
    'football': const FootballPreferencesScreen(),
    'premium': const PremiumScreen(),
  };
  for (final entry in screens.entries) {
    for (final scale in [1.0, 1.4]) {
      testWidgets('${entry.key} compact RTL reduced motion scale $scale', (
        tester,
      ) async {
        await pumpPhase6(tester, entry.value, scale: scale);
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byWidget(entry.value))),
          TextDirection.rtl,
        );
        expect(find.textContaining('Coins'), findsNothing);
        expect(find.text('XP'), findsNothing);
        expect(find.text('الوضع الداكن'), findsNothing);
      });
    }
  }
  testWidgets('profile unavailable never shows fixture or raw exception', (
    tester,
  ) async {
    await pumpPhase6(tester, const ProfileScreen(), unavailable: true);
    expect(find.text('الملف غير متاح الآن'), findsOneWidget);
    expect(find.text(phase6Profile.publicName), findsNothing);
    expect(find.textContaining('private failure'), findsNothing);
  });
  testWidgets('notifications empty has truthful empty state', (tester) async {
    await pumpPhase6(tester, const NotificationsScreen(), unavailable: true);
    expect(find.text(phase6Notifications.first.title), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('premium renders exact localized service prices and full CTA', (
    tester,
  ) async {
    await pumpPhase6(tester, const PremiumScreen());
    for (final plan in phase6Plans) {
      expect(find.text(plan.price), findsOneWidget);
    }
    final button = find.widgetWithText(FilledButton, 'اشترك الآن');
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(360));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
  });
  testWidgets(
    'premium unavailable has no fabricated price or subscribe action',
    (tester) async {
      await pumpPhase6(tester, const PremiumScreen(), unavailable: true);
      expect(find.text('اشترك الآن'), findsNothing);
      for (final plan in phase6Plans) {
        expect(find.text(plan.price), findsNothing);
      }
    },
  );
  testWidgets('report keyboard keeps input and submit reachable by scrolling', (
    tester,
  ) async {
    await pumpPhase6(
      tester,
      const ReportProblemScreen(sourceScreen: '/settings'),
      keyboard: 170,
    );
    await tester.enterText(find.byType(TextField), 'وصف عربي mixed English');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'إرسال البلاغ'),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('وصف عربي mixed English'), findsOneWidget);
  });
}
