import 'dart:async';

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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/phase6_fixture.dart';
import '../helpers/test_app.dart';
import '../helpers/visual_test_variant.dart';

enum _Visual {
  profile,
  notifications,
  settings,
  report,
  reportKeyboard,
  football,
  footballKeyboard,
  premium,
  premiumLoading,
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
  });

  for (final size
      in variant == null
          ? const [Size(390, 844), Size(360, 800)]
          : [variant.size]) {
    for (final visual in _Visual.values) {
      final dimensions = '${size.width.round()}x${size.height.round()}';
      testWidgets('phase E ${visual.name} $dimensions', (tester) async {
        final keyboard =
            visual == _Visual.reportKeyboard ||
            visual == _Visual.footballKeyboard;
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1
          ..viewInsets = keyboard
              ? const FakeViewPadding(bottom: 266)
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
              appConfigProvider.overrideWithValue(phase6Config),
              appServicesProvider.overrideWithValue(const AppServices.noop()),
              authControllerProvider.overrideWithBuild(
                (ref, notifier) async => phase6User,
              ),
              appPreferencesProvider.overrideWithBuild(
                (ref, notifier) async => const AppPreferences(),
              ),
              playerProfileProvider.overrideWith((ref) async => phase6Profile),
              notificationsProvider.overrideWith(
                (ref) async => phase6Notifications,
              ),
              footballPreferencesProvider.overrideWithBuild(
                (ref, notifier) async => phase6Football,
              ),
              premiumControllerProvider.overrideWithBuild(
                (ref, notifier) => visual == _Visual.premiumLoading
                    ? Completer<PremiumView>().future
                    : Future.value(phase6Premium),
              ),
            ],
            child: testApp(
              MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(variant?.scale ?? 1),
                  viewInsets: keyboard
                      ? const EdgeInsets.only(bottom: 266)
                      : EdgeInsets.zero,
                  padding: keyboard
                      ? const EdgeInsets.only(top: 47)
                      : const EdgeInsets.only(top: 47, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                  disableAnimations: true,
                ),
                child: _screen(visual),
              ),
              theme: AppTheme.light,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        if (visual == _Visual.premiumLoading) {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        } else {
          await tester.pumpAndSettle();
        }
        if (keyboard) {
          final field = visual == _Visual.reportKeyboard
              ? find.byKey(const ValueKey('report-description-field'))
              : find.byKey(const ValueKey('football-search-field'));
          await tester.showKeyboard(field);
          if (visual == _Visual.reportKeyboard) {
            await tester.enterText(
              field,
              'لم يتم احتساب الفوز في التحدي الأخير..',
            );
          }
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(tester.takeException(), isNull);
        await verifyVisual(
          tester,
          find.byType(MaterialApp),
          'goldens/v10_phase_e/${visual.name}_$dimensions.png',
          variant,
        );
      });
    }
  }
}

Widget _screen(_Visual visual) => switch (visual) {
  _Visual.profile => const ProfileScreen(),
  _Visual.notifications => const NotificationsScreen(),
  _Visual.settings => const SettingsScreen(),
  _Visual.report || _Visual.reportKeyboard => const ReportProblemScreen(
    sourceScreen: '/settings',
  ),
  _Visual.football ||
  _Visual.footballKeyboard => const FootballPreferencesScreen(),
  _Visual.premium || _Visual.premiumLoading => const PremiumScreen(),
};
