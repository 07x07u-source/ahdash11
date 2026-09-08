import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ads_service.dart';
import 'analytics_service.dart';
import 'app_error_reporter.dart';
import 'crash_reporter.dart';
import 'notification_service.dart';
import 'purchase_service.dart';

final appServicesProvider = Provider<AppServices>(
  (ref) => const AppServices.noop(),
);

final class AppServices {
  const AppServices({
    required this.analytics,
    required this.crashReporter,
    required this.notifications,
    required this.ads,
    required this.purchases,
    required this.errors,
  });

  const AppServices.noop()
    : analytics = const NoopAnalyticsService(),
      crashReporter = const NoopCrashReporter(),
      notifications = const NoopNotificationService(),
      ads = const NoopAdsService(),
      purchases = const NoopPurchaseService(),
      errors = const NoopAppErrorReporter();

  final AnalyticsService analytics;
  final CrashReporter crashReporter;
  final NotificationService notifications;
  final AdsService ads;
  final PurchaseService purchases;
  final AppErrorReporter errors;
}
