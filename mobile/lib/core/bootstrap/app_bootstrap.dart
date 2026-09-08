import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../services/ads_service.dart';
import '../services/analytics_service.dart';
import '../services/app_error_reporter.dart';
import '../services/app_services.dart';
import '../services/crash_reporter.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';

abstract final class AppBootstrap {
  static Future<AppServices> initialize(AppConfig config) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (config.hasSupabase) {
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabaseKey,
      ).timeout(const Duration(seconds: 15));
    }

    final AppErrorReporter errorReporter = config.hasSupabase
        ? SupabaseAppErrorReporter(
            client: Supabase.instance.client,
            appVersion: packageInfo.version,
            buildNumber: packageInfo.buildNumber,
          )
        : const NoopAppErrorReporter();

    AnalyticsService analytics = const NoopAnalyticsService();
    CrashReporter crashReporter = const NoopCrashReporter();
    NotificationService notifications = const NoopNotificationService();
    if (config.firebaseEnabled) {
      try {
        await Firebase.initializeApp().timeout(const Duration(seconds: 15));
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        analytics = FirebaseAnalyticsService(FirebaseAnalytics.instance);
        crashReporter = FirebaseCrashReporter(FirebaseCrashlytics.instance);
        notifications = FirebaseNotificationService(
          FirebaseMessaging.instance,
          config.hasSupabase ? Supabase.instance.client : null,
          appVersion: packageInfo.version,
        );
        unawaited(
          notifications.initialize().catchError((
            Object error,
            StackTrace stackTrace,
          ) {
            unawaited(
              errorReporter.report(
                severity: AppErrorSeverity.warning,
                category: AppErrorCategory.notification,
                feature: 'notification_initialization',
                error: error,
                stackTrace: stackTrace,
              ),
            );
            return null;
          }),
        );
      } catch (error, stackTrace) {
        unawaited(
          errorReporter.report(
            severity: AppErrorSeverity.error,
            category: AppErrorCategory.startup,
            feature: 'firebase_initialization',
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    final AdsService ads = config.adMobEnabled
        ? GoogleAdsService(
            rewardedAdUnitId: config.rewardedAdUnitId,
            interstitialAdUnitId: config.interstitialAdUnitId,
            interstitialEveryMatches: config.interstitialEveryMatches,
          )
        : const NoopAdsService();
    if (ads.enabled) {
      try {
        await ads.initialize();
      } catch (error, stackTrace) {
        unawaited(
          errorReporter.report(
            severity: AppErrorSeverity.warning,
            category: AppErrorCategory.startup,
            feature: 'ads_initialization',
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    PurchaseService purchases = config.revenueCatKey.isEmpty
        ? const NoopPurchaseService()
        : RevenueCatPurchaseService(
            config.revenueCatKey,
            config.revenueCatEntitlementId,
          );
    if (purchases.enabled) {
      try {
        await purchases.initialize();
      } catch (error, stackTrace) {
        unawaited(
          errorReporter.report(
            severity: AppErrorSeverity.warning,
            category: AppErrorCategory.startup,
            feature: 'purchases_initialization',
            error: error,
            stackTrace: stackTrace,
          ),
        );
        // Do not expose purchase actions backed by an SDK that never started.
        purchases = const NoopPurchaseService();
      }
    }

    return AppServices(
      analytics: analytics,
      crashReporter: crashReporter,
      notifications: notifications,
      ads: ads,
      purchases: purchases,
      errors: errorReporter,
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
}
