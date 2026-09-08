import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Development-only stage logging for the native Google → Supabase flow.
///
/// Events deliberately contain no user data, client identifiers, or tokens.
final class GoogleAuthDiagnostics {
  const GoogleAuthDiagnostics._();

  static void stage(String stage, {String? code}) {
    if (!kDebugMode) return;
    final suffix = code == null || code.isEmpty ? '' : ' code=$code';
    debugPrint('GoogleAuthStage.$stage$suffix');
  }

  static String safeGoogleCode(GoogleSignInException error) {
    final text = '${error.description ?? ''} ${error.details ?? ''}';
    final nativeStatus = RegExp(
      r'(?<!\d)(10|12500|12501)(?!\d)',
    ).firstMatch(text)?.group(1);
    return nativeStatus == null
        ? error.code.name
        : '${error.code.name}:$nativeStatus';
  }

  static String safePlatformCode(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('12501') || normalized.contains('cancel')) {
      return 'canceled';
    }
    if (normalized.contains('12500') ||
        RegExp(r'(?<!\d)10(?!\d)').hasMatch(normalized) ||
        normalized.contains('developer_error')) {
      return 'configuration';
    }
    if (normalized.contains('network')) return 'network';
    return 'provider';
  }
}
