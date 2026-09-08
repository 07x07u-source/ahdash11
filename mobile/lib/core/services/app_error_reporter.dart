import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum AppErrorSeverity { info, warning, error, critical }

enum AppErrorCategory {
  startup,
  api,
  supabase,
  content,
  matchmaking,
  room,
  wallet,
  notification,
  image,
  purchase,
  auth,
  offlineSync,
  unexpectedState,
}

extension on AppErrorCategory {
  String get wireName => switch (this) {
    AppErrorCategory.offlineSync => 'offline_sync',
    AppErrorCategory.unexpectedState => 'unexpected_state',
    _ => name,
  };
}

abstract interface class AppErrorReporter {
  String get appVersion;
  String get buildNumber;

  Future<void> report({
    required AppErrorSeverity severity,
    required AppErrorCategory category,
    required String feature,
    required Object error,
    StackTrace? stackTrace,
    String? screen,
    Map<String, String?> context = const {},
  });

  Future<String?> submitProblem({
    required String category,
    required String? description,
    required String? screen,
  });
}

final class NoopAppErrorReporter implements AppErrorReporter {
  const NoopAppErrorReporter();

  @override
  String get appVersion => '0.1.0';
  @override
  String get buildNumber => '1';

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
  }) async => null;
}

final class SupabaseAppErrorReporter implements AppErrorReporter {
  SupabaseAppErrorReporter({
    required SupabaseClient client,
    required this.appVersion,
    required this.buildNumber,
    Connectivity? connectivity,
  }) : _client = client,
       _connectivity = connectivity ?? Connectivity(),
       _sessionId = const Uuid().v4();

  final SupabaseClient _client;
  final Connectivity _connectivity;
  final String _sessionId;

  @override
  final String appVersion;
  @override
  final String buildNumber;

  @override
  Future<void> report({
    required AppErrorSeverity severity,
    required AppErrorCategory category,
    required String feature,
    required Object error,
    StackTrace? stackTrace,
    String? screen,
    Map<String, String?> context = const {},
  }) async {
    if (_client.auth.currentUser == null) return;
    try {
      await _client
          .rpc<void>(
            'report_app_error',
            params: {
              'p_severity': severity.name,
              'p_category': category.wireName,
              'p_feature': AppErrorSanitizer.text(feature, 80),
              'p_message': AppErrorSanitizer.text('$error', 700),
              'p_stack': stackTrace == null
                  ? null
                  : AppErrorSanitizer.text('$stackTrace', 6000),
              'p_screen': AppErrorSanitizer.nullable(screen, 100),
              'p_app_version': AppErrorSanitizer.text(appVersion, 32),
              'p_build_number': AppErrorSanitizer.text(buildNumber, 20),
              'p_platform': _platform,
              'p_os_version': AppErrorSanitizer.nullable(
                Platform.operatingSystemVersion,
                120,
              ),
              'p_device_model': null,
              'p_network_state': await _networkState(),
              'p_session_id': _sessionId,
              'p_context': <String, String?>{
                'operation': AppErrorSanitizer.nullable(
                  context['operation'],
                  80,
                ),
                'state': AppErrorSanitizer.nullable(context['state'], 80),
                'code': AppErrorSanitizer.nullable(context['code'], 80),
              },
            },
          )
          .timeout(const Duration(seconds: 8));
    } on Object {
      // Telemetry must never cause another user-facing failure or retry loop.
    }
  }

  @override
  Future<String?> submitProblem({
    required String category,
    required String? description,
    required String? screen,
  }) async {
    if (_client.auth.currentUser == null) {
      throw StateError('يلزم تسجيل الدخول لإرسال البلاغ.');
    }
    final result = await _client
        .rpc<Object?>(
          'submit_user_problem_report',
          params: {
            'p_category': category,
            'p_description': AppErrorSanitizer.nullable(description, 1500),
            'p_screen': AppErrorSanitizer.nullable(screen, 100),
            'p_app_version': AppErrorSanitizer.text(appVersion, 32),
            'p_build_number': AppErrorSanitizer.text(buildNumber, 20),
            'p_platform': _platform,
          },
        )
        .timeout(const Duration(seconds: 12));
    return result?.toString();
  }

  String get _platform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  Future<String> _networkState() async {
    try {
      final values = await _connectivity.checkConnectivity();
      if (values.contains(ConnectivityResult.none)) return 'offline';
      if (values.contains(ConnectivityResult.wifi)) return 'wifi';
      if (values.contains(ConnectivityResult.mobile)) return 'mobile';
      if (values.contains(ConnectivityResult.ethernet)) return 'ethernet';
      if (values.contains(ConnectivityResult.vpn)) return 'vpn';
      if (values.isNotEmpty) return 'other';
    } on Object {
      // Unknown is safer than failing the original reporting path.
    }
    return 'unknown';
  }
}

abstract final class AppErrorSanitizer {
  static final _jwt = RegExp(
    r'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}',
  );
  static final _bearer = RegExp(
    r'Bearer\s+[A-Za-z0-9._~+/=-]{8,}',
    caseSensitive: false,
  );
  static final _credential = RegExp(
    r'(authorization|access_token|refresh_token|password|secret|private_key)\s*[:=]\s*[^,;\s]+',
    caseSensitive: false,
  );
  static final _email = RegExp(
    r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
  );

  static String text(String value, int maxLength) {
    var clean = value
        .replaceAll(_jwt, '[redacted-token]')
        .replaceAll(_bearer, 'Bearer [redacted]')
        .replaceAllMapped(
          _credential,
          (match) => '${match.group(1)}=[redacted]',
        )
        .replaceAll(_email, '[redacted-email]')
        .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), ' ')
        .trim();
    if (clean.length > maxLength) clean = clean.substring(0, maxLength);
    return clean.isEmpty ? 'unknown' : clean;
  }

  static String? nullable(String? value, int maxLength) {
    if (value == null || value.trim().isEmpty) return null;
    return text(value, maxLength);
  }
}
