import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { development, staging, production }

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseKey,
    required this.firebaseEnabled,
    required this.adMobEnabled,
    required this.revenueCatAndroidKey,
    required this.revenueCatIosKey,
    this.revenueCatEntitlementId = 'premium',
    this.privacyPolicyUrl = '',
    this.termsUrl = '',
    this.adMobRewardedAndroidId = '',
    this.adMobRewardedIosId = '',
    this.adMobInterstitialAndroidId = '',
    this.adMobInterstitialIosId = '',
    this.interstitialEveryMatches = 3,
    this.googleAuthEnabled = false,
    this.appleAuthEnabled = false,
    this.premiumVouchersEnabled = false,
    this.premiumVouchersPolicyApproved = false,
  });

  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    return AppConfig(
      environment: AppEnvironment.values.firstWhere(
        (value) => value.name == environmentName,
        orElse: () => AppEnvironment.development,
      ),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      firebaseEnabled: const bool.fromEnvironment('FIREBASE_ENABLED'),
      adMobEnabled: const bool.fromEnvironment('ADMOB_ENABLED'),
      revenueCatAndroidKey: const String.fromEnvironment(
        'REVENUECAT_ANDROID_API_KEY',
      ),
      revenueCatIosKey: const String.fromEnvironment('REVENUECAT_IOS_API_KEY'),
      revenueCatEntitlementId: const String.fromEnvironment(
        'REVENUECAT_ENTITLEMENT_ID',
        defaultValue: 'premium',
      ),
      privacyPolicyUrl: const String.fromEnvironment('PRIVACY_POLICY_URL'),
      termsUrl: const String.fromEnvironment('TERMS_URL'),
      adMobRewardedAndroidId: const String.fromEnvironment(
        'ADMOB_REWARDED_ANDROID_ID',
      ),
      adMobRewardedIosId: const String.fromEnvironment('ADMOB_REWARDED_IOS_ID'),
      adMobInterstitialAndroidId: const String.fromEnvironment(
        'ADMOB_INTERSTITIAL_ANDROID_ID',
      ),
      adMobInterstitialIosId: const String.fromEnvironment(
        'ADMOB_INTERSTITIAL_IOS_ID',
      ),
      interstitialEveryMatches: const int.fromEnvironment(
        'ADMOB_INTERSTITIAL_EVERY_MATCHES',
        defaultValue: 3,
      ),
      googleAuthEnabled: const bool.fromEnvironment('GOOGLE_AUTH_ENABLED'),
      appleAuthEnabled: const bool.fromEnvironment('APPLE_AUTH_ENABLED'),
      premiumVouchersEnabled: const bool.fromEnvironment(
        'PREMIUM_VOUCHERS_ENABLED',
      ),
      premiumVouchersPolicyApproved: const bool.fromEnvironment(
        'PREMIUM_VOUCHERS_POLICY_APPROVED',
      ),
    );
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseKey;
  final bool firebaseEnabled;
  final bool adMobEnabled;
  final String revenueCatAndroidKey;
  final String revenueCatIosKey;
  final String revenueCatEntitlementId;
  final String privacyPolicyUrl;
  final String termsUrl;
  final String adMobRewardedAndroidId;
  final String adMobRewardedIosId;
  final String adMobInterstitialAndroidId;
  final String adMobInterstitialIosId;
  final int interstitialEveryMatches;
  final bool googleAuthEnabled;
  final bool appleAuthEnabled;
  final bool premiumVouchersEnabled;
  final bool premiumVouchersPolicyApproved;

  /// A partially configured or malformed backend must never reach SDK startup.
  bool get hasSupabase =>
      _httpsUri(supabaseUrl) != null && _usableValue(supabaseKey);

  Uri? get privacyPolicyUri => _httpsUri(privacyPolicyUrl);

  Uri? get termsUri => _httpsUri(termsUrl);

  bool get googleAuthAvailable => googleAuthEnabled && hasSupabase;

  bool get appleAuthAvailable => appleAuthEnabled && hasSupabase;

  /// Custom voucher redemption is intentionally a two-key feature gate.
  /// Production remains closed until store-policy approval is explicit.
  bool get premiumVouchersAvailable =>
      hasSupabase &&
      premiumVouchersEnabled &&
      (!isProduction || premiumVouchersPolicyApproved);

  bool get isProduction => environment == AppEnvironment.production;

  String get revenueCatKey {
    if (kIsWeb) return '';
    if (Platform.isAndroid && _usableValue(revenueCatAndroidKey)) {
      return revenueCatAndroidKey.trim();
    }
    if (Platform.isIOS && _usableValue(revenueCatIosKey)) {
      return revenueCatIosKey.trim();
    }
    return '';
  }

  static Uri? _httpsUri(String raw) {
    final value = raw.trim();
    if (!_usableValue(value)) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  static bool _usableValue(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;
    final normalized = value.toLowerCase();
    return !normalized.contains('replace_me') &&
        !normalized.contains('your_') &&
        !normalized.contains('placeholder') &&
        normalized != 'todo';
  }

  String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return adMobRewardedAndroidId.isNotEmpty
          ? adMobRewardedAndroidId
          : (isProduction ? '' : 'ca-app-pub-3940256099942544/5224354917');
    }
    if (Platform.isIOS) {
      return adMobRewardedIosId.isNotEmpty
          ? adMobRewardedIosId
          : (isProduction ? '' : 'ca-app-pub-3940256099942544/1712485313');
    }
    return '';
  }

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return adMobInterstitialAndroidId.isNotEmpty
          ? adMobInterstitialAndroidId
          : (isProduction ? '' : 'ca-app-pub-3940256099942544/1033173712');
    }
    if (Platform.isIOS) {
      return adMobInterstitialIosId.isNotEmpty
          ? adMobInterstitialIosId
          : (isProduction ? '' : 'ca-app-pub-3940256099942544/4411468910');
    }
    return '';
  }
}
