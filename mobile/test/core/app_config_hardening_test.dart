import 'package:ahdash_11/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppConfig config({
    String supabaseUrl = '',
    String supabaseKey = '',
    bool google = false,
    bool apple = false,
    String privacy = '',
    String terms = '',
  }) => AppConfig(
    environment: AppEnvironment.production,
    supabaseUrl: supabaseUrl,
    supabaseKey: supabaseKey,
    firebaseEnabled: false,
    adMobEnabled: false,
    revenueCatAndroidKey: '',
    revenueCatIosKey: '',
    googleAuthEnabled: google,
    appleAuthEnabled: apple,
    privacyPolicyUrl: privacy,
    termsUrl: terms,
  );

  test('Supabase requires a complete HTTPS configuration', () {
    expect(
      config(
        supabaseUrl: 'https://project.supabase.co',
        supabaseKey: 'public-key',
      ).hasSupabase,
      isTrue,
    );
    expect(
      config(supabaseUrl: 'not-a-url', supabaseKey: 'key').hasSupabase,
      isFalse,
    );
    expect(
      config(
        supabaseUrl: 'https://project.supabase.co',
        supabaseKey: 'REPLACE_ME',
      ).hasSupabase,
      isFalse,
    );
  });

  test('social providers cannot appear without a valid backend', () {
    final value = config(google: true, apple: true);
    expect(value.googleAuthAvailable, isFalse);
    expect(value.appleAuthAvailable, isFalse);
  });

  test('legal URI getters accept only complete HTTPS URLs', () {
    final value = config(
      privacy: 'https://ahdash.example/privacy',
      terms: 'javascript:alert(1)',
    );
    expect(value.privacyPolicyUri?.path, '/privacy');
    expect(value.termsUri, isNull);
  });
}
