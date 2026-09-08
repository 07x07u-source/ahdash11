import 'package:ahdash_11/core/services/legal_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LegalLinkService', () {
    test('opens a valid Terms URL in the external launcher', () async {
      Uri? opened;
      final service = LegalLinkService(
        launcher: (uri) async {
          opened = uri;
          return true;
        },
      );

      expect(
        await service.open('https://ahdash.example/terms'),
        LegalLinkOpenResult.opened,
      );
      expect(opened, Uri.parse('https://ahdash.example/terms'));
    });

    test('accepts a valid Privacy URL', () {
      final service = LegalLinkService();
      expect(service.isAvailable('https://ahdash.example/privacy'), isTrue);
    });

    test('reports missing configuration without launching', () async {
      var launches = 0;
      final service = LegalLinkService(
        launcher: (_) async {
          launches++;
          return true;
        },
      );

      expect(await service.open(''), LegalLinkOpenResult.missing);
      expect(launches, 0);
    });

    test('rejects non-HTTPS and malformed URLs', () async {
      final service = LegalLinkService();
      expect(
        await service.open('http://example.com'),
        LegalLinkOpenResult.invalid,
      );
      expect(await service.open('not a url'), LegalLinkOpenResult.invalid);
    });

    test('maps launcher rejection and exception to safe failure', () async {
      final rejected = LegalLinkService(launcher: (_) async => false);
      final failed = LegalLinkService(
        launcher: (_) async => throw StateError('platform failure'),
      );

      expect(
        await rejected.open('https://ahdash.example/terms'),
        LegalLinkOpenResult.launchFailed,
      );
      expect(
        await failed.open('https://ahdash.example/privacy'),
        LegalLinkOpenResult.launchFailed,
      );
    });
  });
}
