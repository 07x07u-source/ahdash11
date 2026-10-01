import 'package:ahdash_11/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production defaults point to the public legal center', () {
    final config = AppConfig.fromEnvironment();

    expect(config.privacyPolicyUrl, defaultPrivacyPolicyUrl);
    expect(config.termsUrl, defaultTermsUrl);
    expect(config.privacyPolicyUri?.host, 'ahdash11.com');
    expect(config.termsUri?.host, 'ahdash11.com');
  });
}
