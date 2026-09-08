import 'package:ahdash_11/core/services/ads_service.dart';
import 'package:ahdash_11/core/services/analytics_service.dart';
import 'package:ahdash_11/core/services/app_error_reporter.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/services/crash_reporter.dart';
import 'package:ahdash_11/core/services/notification_service.dart';
import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/support/presentation/report_problem_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase6_fixture.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('problem report submits safe context and shows success state', (
    tester,
  ) async {
    final reporter = _FakeReporter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(_services(reporter)),
          authControllerProvider.overrideWithBuild(
            (ref, notifier) async => phase6User,
          ),
        ],
        child: testApp(
          const ReportProblemScreen(sourceScreen: '/settings'),
          theme: AppTheme.light,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('وش المشكلة؟'), findsOneWidget);
    expect(find.text('وصف المشكلة — اختياري'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'تظهر الصورة فارغة عند الاتصال البطيء',
    );
    await tester.tap(find.text('إرسال البلاغ'));
    await tester.pumpAndSettle();

    expect(find.text('وصلنا بلاغك'), findsOneWidget);
    expect(reporter.lastScreen, '/settings');
    expect(reporter.lastCategory, 'gameplay');
    expect(reporter.lastDescription, contains('الصورة'));
  });
}

AppServices _services(AppErrorReporter reporter) => AppServices(
  analytics: const NoopAnalyticsService(),
  crashReporter: const NoopCrashReporter(),
  notifications: const NoopNotificationService(),
  ads: const NoopAdsService(),
  purchases: const NoopPurchaseService(),
  errors: reporter,
);

final class _FakeReporter implements AppErrorReporter {
  String? lastCategory;
  String? lastDescription;
  String? lastScreen;

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
    lastCategory = category;
    lastDescription = description;
    lastScreen = screen;
    return 'report-id';
  }
}
