import 'package:firebase_crashlytics/firebase_crashlytics.dart';

abstract interface class CrashReporter {
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  });

  Future<void> identify(String userId);
  Future<void> clearIdentity();
}

final class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {}

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> clearIdentity() async {}
}

final class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) {
    return _crashlytics.recordError(error, stackTrace, fatal: fatal);
  }

  @override
  Future<void> identify(String userId) =>
      _crashlytics.setUserIdentifier(userId);

  @override
  Future<void> clearIdentity() => _crashlytics.setUserIdentifier('');
}
