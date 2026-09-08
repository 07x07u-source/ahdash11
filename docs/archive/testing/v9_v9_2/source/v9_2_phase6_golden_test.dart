import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/services/purchase_service.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/phase6_fixture.dart';
import '../helpers/test_app.dart';

enum Phase6Screen {
  profile,
  notifications,
  settings,
  report,
  football,
  premium,
  profileUnavailable,
  notificationsEmpty,
  footballEmpty,
  premiumActive,
  premiumUnavailable,
}

void main() {
  setUpAll(() async {
    final font = FontLoader('ThmanyahSans');
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      font.addFont(
        rootBundle.load('assets/fonts/thmanyah/thmanyahsans-$weight.otf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
  });
  for (final size in const [
    Size(800, 360),
    Size(844, 390),
    Size(915, 412),
    Size(1280, 720),
    Size(1366, 768),
  ]) {
    for (final screen in Phase6Screen.values) {
      if (screen.index >= 6 && size != const Size(844, 390)) continue;
      final dimensions = '${size.width.round()}x${size.height.round()}';
      testWidgets('Phase 6 ${screen.name} $dimensions', (tester) async {
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
            appConfigProvider.overrideWithValue(phase6Config),
            appServicesProvider.overrideWithValue(AppServices.noop()),
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
              if (screen == Phase6Screen.profileUnavailable) {
                throw StateError('Unavailable');
              }
              return phase6Profile;
            }),
            notificationsProvider.overrideWith(
              (ref) async => screen == Phase6Screen.notificationsEmpty
                  ? []
                  : phase6Notifications,
            ),
            footballPreferencesProvider.overrideWithBuild(
              (ref, notifier) async => screen == Phase6Screen.footballEmpty
                  ? const FootballView(
                      leagues: phase6Leagues,
                      leagueId: 'league-a',
                      query: 'لا توجد نتيجة',
                      canSave: true,
                    )
                  : phase6Football,
            ),
            premiumControllerProvider.overrideWithBuild(
              (ref, notifier) async => switch (screen) {
                Phase6Screen.premiumActive => const PremiumView(
                  available: true,
                  status: PremiumStatus(state: PremiumAccessState.active),
                ),
                Phase6Screen.premiumUnavailable => const PremiumView(
                  message: 'الاشتراك غير متاح في هذه البيئة.',
                ),
                _ => phase6Premium,
              },
            ),
          ],
        );
        addTearDown(container.dispose);
        const key = ValueKey('phase6-boundary');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: testApp(
              MediaQuery(
                data: MediaQueryData(size: size, disableAnimations: true),
                child: RepaintBoundary(
                  key: key,
                  child: switch (screen) {
                    Phase6Screen.profile ||
                    Phase6Screen.profileUnavailable => const ProfileScreen(),
                    Phase6Screen.notifications ||
                    Phase6Screen.notificationsEmpty =>
                      const NotificationsScreen(),
                    Phase6Screen.settings => const SettingsScreen(),
                    Phase6Screen.report => const ReportProblemScreen(
                      sourceScreen: '/settings',
                    ),
                    Phase6Screen.football || Phase6Screen.footballEmpty =>
                      const FootballPreferencesScreen(),
                    _ => const PremiumScreen(),
                  },
                ),
              ),
              theme: AppTheme.light,
            ),
          ),
        );
        await tester.pump();
        final boundary = find.byKey(key);
        final images = tester
            .widgetList<Image>(
              find.descendant(of: boundary, matching: find.byType(Image)),
            )
            .map((e) => e.image)
            .toList();
        final context = tester.element(boundary);
        await tester.runAsync(() async {
          await Future.wait(
            images.map((image) => precacheImage(image, context)),
          );
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          boundary,
          matchesGoldenFile(
            '../../../docs/visual-validation/v9_2_phase6/${screen.name}_$dimensions.png',
          ),
        );
      });
    }
  }
}
