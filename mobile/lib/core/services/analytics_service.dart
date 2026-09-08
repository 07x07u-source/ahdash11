import 'package:firebase_analytics/firebase_analytics.dart';

abstract interface class AnalyticsService {
  Future<void> log(String name, [Map<String, Object>? parameters]);
}

final class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> log(String name, [Map<String, Object>? parameters]) async {}
}

final class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> log(String name, [Map<String, Object>? parameters]) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }
}
