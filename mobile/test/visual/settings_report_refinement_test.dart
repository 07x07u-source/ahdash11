import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/ads_service.dart';
import 'package:ahdash_11/core/services/analytics_service.dart';
import 'package:ahdash_11/core/services/app_error_reporter.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/services/crash_reporter.dart';
import 'package:ahdash_11/core/services/notification_service.dart';
import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/premium/presentation/premium_controller.dart';
import 'package:ahdash_11/features/settings/presentation/notification_preferences_controller.dart';
import 'package:ahdash_11/features/settings/presentation/settings_screen.dart';
import 'package:ahdash_11/features/support/presentation/report_problem_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/phase6_fixture.dart';
import '../helpers/test_app.dart';
import '../helpers/visual_test_variant.dart';

enum _SettingsState { standard, premium, guest }

enum _ReportState { initial, keyboard, success, error, uncertain }

void main() {
  setUpAll(() async {
    final fonts = FontLoader('ThmanyahSans');
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      fonts.addFont(
        rootBundle.load('assets/fonts/thmanyah/thmanyahsans-$weight.otf'),
      );
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final size in const [Size(390, 844), Size(360, 800)]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      for (final state in _SettingsState.values) {
        final variant = VisualTestVariant(size, scale);
        testWidgets('settings ${state.name} ${variant.label}', (tester) async {
          _setView(tester, size);
          final user = state == _SettingsState.guest
              ? const AuthUser(id: 'guest', username: 'ضيف', isGuest: true)
              : phase6User;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appConfigProvider.overrideWithValue(phase6Config),
                appServicesProvider.overrideWithValue(const AppServices.noop()),
                authControllerProvider.overrideWithBuild(
                  (ref, notifier) async => user,
                ),
                appPreferencesProvider.overrideWithBuild(
                  (ref, notifier) async => const AppPreferences(
                    soundEffects: true,
                    haptics: true,
                    reducedMotion: false,
                  ),
                ),
                premiumControllerProvider.overrideWithBuild(
                  (ref, notifier) async => state == _SettingsState.premium
                      ? const PremiumView(
                          status: PremiumStatus(
                            state: PremiumAccessState.active,
                          ),
                        )
                      : const PremiumView(),
                ),
              ],
              child: testApp(
                _media(size, scale, const SettingsScreen()),
                theme: AppTheme.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await _settleRasterAssets(tester);
          expect(
            find.byKey(const ValueKey('settings-identity-card')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('settings-device-preferences')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('settings-identity-art')),
            findsOneWidget,
          );
          await verifyVisual(
            tester,
            find.byType(MaterialApp),
            'goldens/settings_report_review/settings_${state.name}_${size.width.round()}x${size.height.round()}.png',
            variant,
          );
        });
      }
    }
  }

  for (final size in const [Size(390, 844), Size(360, 800)]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      for (final state in const [
        _ReportState.initial,
        _ReportState.success,
        _ReportState.error,
        _ReportState.uncertain,
      ]) {
        final variant = VisualTestVariant(size, scale);
        testWidgets('report ${state.name} ${variant.label}', (tester) async {
          _setView(tester, size);
          await _pumpReport(tester, size, scale, state);
          if (state != _ReportState.initial) {
            await tester.tap(find.widgetWithText(FilledButton, 'إرسال البلاغ'));
            await tester.pumpAndSettle();
          }
          expect(
            find.byKey(const ValueKey('report-success-artwork')),
            state == _ReportState.success ? findsOneWidget : findsNothing,
          );
          await verifyVisual(
            tester,
            find.byType(MaterialApp),
            'goldens/settings_report_review/report_${state.name}_${size.width.round()}x${size.height.round()}.png',
            variant,
          );
        });
      }
    }

    const scale = 1.3;
    final variant = VisualTestVariant(size, scale);
    testWidgets('report keyboard ${variant.label}', (tester) async {
      _setView(tester, size, keyboard: 300);
      await _pumpReport(
        tester,
        size,
        scale,
        _ReportState.keyboard,
        keyboard: 300,
      );
      final field = find.byKey(const ValueKey('report-description-field'));
      await tester.showKeyboard(field);
      await tester.enterText(field, 'لم يتم احتساب نقاط السؤال الأخير.');
      await tester.pump(const Duration(milliseconds: 300));
      expect(field, findsOneWidget);
      await verifyVisual(
        tester,
        find.byType(MaterialApp),
        'goldens/settings_report_review/report_keyboard_${size.width.round()}x${size.height.round()}.png',
        variant,
      );
    });
  }

  for (final surface in const [
    'bottom',
    'local_sheet',
    'notifications_sheet',
  ]) {
    const size = Size(390, 844);
    const scale = 1.0;
    const variant = VisualTestVariant(size, scale);
    testWidgets('settings $surface detail', (tester) async {
      _setView(tester, size);
      await _pumpSettingsDetail(tester, size, scale);
      if (surface == 'bottom') {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('settings-sign-out')),
          260,
          scrollable: find.byType(Scrollable).first,
        );
      } else if (surface == 'local_sheet') {
        await tester.tap(find.text('عرض التفاصيل'));
      } else {
        final notifications = find.text('تفضيلات الإشعارات').first;
        await tester.ensureVisible(notifications);
        await tester.tap(notifications);
      }
      await tester.pumpAndSettle();
      await verifyVisual(
        tester,
        find.byType(MaterialApp),
        'goldens/settings_report_review/settings_${surface}_390x844.png',
        variant,
      );
    });
  }
}

Future<void> _pumpSettingsDetail(
  WidgetTester tester,
  Size size,
  double scale,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(phase6Config),
        appServicesProvider.overrideWithValue(const AppServices.noop()),
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => phase6User,
        ),
        appPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => const AppPreferences(
            soundEffects: true,
            haptics: true,
            reducedMotion: false,
          ),
        ),
        premiumControllerProvider.overrideWithBuild(
          (ref, notifier) async => const PremiumView(),
        ),
        notificationPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => NotificationPreferencesController.defaults,
        ),
      ],
      child: testApp(
        _media(size, scale, const SettingsScreen()),
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _settleRasterAssets(tester);
}

Future<void> _pumpReport(
  WidgetTester tester,
  Size size,
  double scale,
  _ReportState state, {
  double keyboard = 0,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(phase6Config),
        appServicesProvider.overrideWithValue(
          _reportServices(_VisualReporter(state)),
        ),
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => phase6User,
        ),
      ],
      child: testApp(
        _media(
          size,
          scale,
          const ReportProblemScreen(sourceScreen: '/settings'),
          keyboard: keyboard,
        ),
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _settleRasterAssets(tester);
  expect(find.byKey(const ValueKey('report-support-art')), findsOneWidget);
}

Future<void> _settleRasterAssets(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 180)),
  );
  await tester.pumpAndSettle();
}

Widget _media(Size size, double scale, Widget child, {double keyboard = 0}) =>
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(scale),
        viewInsets: EdgeInsets.only(bottom: keyboard),
        disableAnimations: true,
        padding: const EdgeInsets.only(top: 47, bottom: 34),
        viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
      ),
      child: child,
    );

void _setView(WidgetTester tester, Size size, {double keyboard = 0}) {
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

AppServices _reportServices(AppErrorReporter reporter) => AppServices(
  analytics: const NoopAnalyticsService(),
  crashReporter: const NoopCrashReporter(),
  notifications: const NoopNotificationService(),
  ads: const NoopAdsService(),
  purchases: const NoopPurchaseService(),
  errors: reporter,
);

final class _VisualReporter implements AppErrorReporter {
  const _VisualReporter(this.state);

  final _ReportState state;

  @override
  String get appVersion => '0.2.0';

  @override
  String get buildNumber => '42';

  @override
  Future<void> report({
    required AppErrorSeverity severity,
    required AppErrorCategory category,
    required String feature,
    required Object error,
    StackTrace? stackTrace,
    String? screen,
    Map<String, String?> context = const {},
  }) async {}

  @override
  Future<String?> submitProblem({
    required String category,
    required String? description,
    required String? screen,
  }) async {
    if (state == _ReportState.uncertain) {
      throw TimeoutException('visual timeout');
    }
    if (state == _ReportState.error) return null;
    return 'report-visual-id';
  }
}
