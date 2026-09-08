import 'package:ahdash_11/core/services/app_error_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppErrorSanitizer', () {
    test('redacts credentials, bearer tokens, JWTs, and email addresses', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJwbGF5ZXIifQ.verylongsignaturevalue';
      final sanitized = AppErrorSanitizer.text(
        'Authorization: Bearer super-secret-token password=hunter2 '
        'email player@example.com jwt $jwt',
        700,
      );

      expect(sanitized, isNot(contains('super-secret-token')));
      expect(sanitized, isNot(contains('hunter2')));
      expect(sanitized, isNot(contains('player@example.com')));
      expect(sanitized, isNot(contains(jwt)));
      expect(sanitized, contains('[redacted]'));
      expect(sanitized, contains('[redacted-email]'));
      expect(sanitized, contains('[redacted-token]'));
    });

    test('enforces size limits and handles empty nullable values', () {
      expect(AppErrorSanitizer.text('123456789', 5), '12345');
      expect(AppErrorSanitizer.nullable('   ', 20), isNull);
      expect(AppErrorSanitizer.text('\u0001', 20), 'unknown');
    });
  });
}
