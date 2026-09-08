import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final legalLinkServiceProvider = Provider<LegalLinkService>(
  (_) => LegalLinkService(),
);

enum LegalLinkOpenResult { opened, missing, invalid, launchFailed }

extension LegalLinkOpenResultCopy on LegalLinkOpenResult {
  String? get messageAr => switch (this) {
    LegalLinkOpenResult.opened => null,
    LegalLinkOpenResult.missing => 'الرابط غير مهيأ بعد.',
    LegalLinkOpenResult.invalid => 'إعداد الرابط غير صالح.',
    LegalLinkOpenResult.launchFailed =>
      'تعذر فتح الرابط في المتصفح. حاول مرة أخرى.',
  };
}

typedef ExternalUriLauncher = Future<bool> Function(Uri uri);

final class LegalLinkService {
  LegalLinkService({ExternalUriLauncher? launcher})
    : _launcher = launcher ?? _launchExternal;

  final ExternalUriLauncher _launcher;

  Uri? parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  bool isAvailable(String raw) => parse(raw) != null;

  Future<LegalLinkOpenResult> open(String raw) async {
    if (raw.trim().isEmpty) return LegalLinkOpenResult.missing;
    final uri = parse(raw);
    if (uri == null) return LegalLinkOpenResult.invalid;
    try {
      return await _launcher(uri)
          ? LegalLinkOpenResult.opened
          : LegalLinkOpenResult.launchFailed;
    } on Object {
      return LegalLinkOpenResult.launchFailed;
    }
  }
}

Future<bool> _launchExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
