import 'dart:convert';

import 'package:flutter/foundation.dart';

abstract final class AppContentKeys {
  static const homeHeroTitle = 'home.hero.title';
  static const homeHeroSubtitle = 'home.hero.subtitle';
  static const homeHeroImage = 'home.hero.image';
  static const homeFeaturedTitle = 'home.featured.title';
  static const homeFeaturedDescription = 'home.featured.description';
  static const premiumHeroTitle = 'premium.hero.title';
  static const premiumHeroSubtitle = 'premium.hero.subtitle';
  static const premiumHeroImage = 'premium.hero.image';
  static const storeBannerTitle = 'store.banner.title';
  static const storeBannerSubtitle = 'store.banner.subtitle';
  static const maintenanceMessage = 'maintenance.message';
  static const announcementTitle = 'announcement.title';
  static const announcementDescription = 'announcement.description';
  static const announcementImage = 'announcement.image';
  static const brandingLogoPrimary = 'branding.logo.primary';
  static const brandingLogoLight = 'branding.logo.light';
  static const brandingLogoDark = 'branding.logo.dark';
  static const brandingLogoMark = 'branding.logo.mark';
  static const brandingLoginArtwork = 'branding.login.artwork';
  static const authLoginBackground = 'auth.login.background';
  static const brandingPlaceholderDefault = 'branding.placeholder.default';
  static const brandingCategoryFallback = 'branding.category.fallback';
  static const brandingStoreArtwork = 'branding.store.artwork';
  static const brandingPremiumArtwork = 'branding.premium.artwork';
  static const playClassicImage = 'play.classic';
  static const playTrueFalseImage = 'play.truefalse';
  static const playSpeedImage = 'play.speed';
  static const playOrderingImage = 'play.ordering';
  static const playClubGuessImage = 'play.clubguess';
  static const playEagleEyeImage = 'play.eagleeye';
  static const teamEmptyImage = 'team.empty';
  static const friendsEmptyImage = 'friends.empty';
  static const challengeEmptyImage = 'challenge.empty';
  static const profileBackgroundImage = 'profile.background';
  static const promotionHomeImage = 'promotions.home.image';
  static const promotionSeasonalImage = 'promotions.seasonal.image';
  static const appearanceAccentColor = 'appearance.accent.color';
  static const featureHomePromotion = 'feature.home.promotion';
  static const featureHomeSeasonal = 'feature.home.seasonal';
  static const featurePremiumPromotion = 'feature.premium.promotion';
  static const featureRewardedCta = 'feature.rewarded.cta';
  static const featureHomeFeatured = 'feature.home.featured';

  static const values = <String>{
    homeHeroTitle,
    homeHeroSubtitle,
    homeHeroImage,
    homeFeaturedTitle,
    homeFeaturedDescription,
    premiumHeroTitle,
    premiumHeroSubtitle,
    premiumHeroImage,
    storeBannerTitle,
    storeBannerSubtitle,
    maintenanceMessage,
    announcementTitle,
    announcementDescription,
    announcementImage,
    brandingLogoPrimary,
    brandingLogoLight,
    brandingLogoDark,
    brandingLogoMark,
    brandingLoginArtwork,
    authLoginBackground,
    brandingPlaceholderDefault,
    brandingCategoryFallback,
    brandingStoreArtwork,
    brandingPremiumArtwork,
    playClassicImage,
    playTrueFalseImage,
    playSpeedImage,
    playOrderingImage,
    playClubGuessImage,
    playEagleEyeImage,
    teamEmptyImage,
    friendsEmptyImage,
    challengeEmptyImage,
    profileBackgroundImage,
    promotionHomeImage,
    promotionSeasonalImage,
    appearanceAccentColor,
    featureHomePromotion,
    featureHomeSeasonal,
    featurePremiumPromotion,
    featureRewardedCta,
    featureHomeFeatured,
  };
}

@immutable
final class AppContentValue {
  const AppContentValue({
    this.textAr,
    this.imageUrl,
    this.imageAltText,
    this.version = 0,
  });

  factory AppContentValue.fromJson(Map<String, Object?> json) {
    return AppContentValue(
      textAr: json['text_ar'] as String?,
      imageUrl: json['image_url'] as String?,
      imageAltText: json['image_alt_text'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }

  final String? textAr;
  final String? imageUrl;
  final String? imageAltText;
  final int version;

  Map<String, Object?> toJson() => {
    'text_ar': textAr,
    'image_url': imageUrl,
    'image_alt_text': imageAltText,
    'version': version,
  };
}

@immutable
final class AppContentBundle {
  const AppContentBundle(this.values, {this.refreshedAt});

  factory AppContentBundle.fromJson(Map<String, Object?> json) {
    final rawValues = json['values'];
    final values = <String, AppContentValue>{};
    if (rawValues is Map) {
      for (final entry in rawValues.entries) {
        if (entry.key is String &&
            AppContentKeys.values.contains(entry.key) &&
            entry.value is Map) {
          values[entry.key as String] = AppContentValue.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
        }
      }
    }
    return AppContentBundle({
      ...defaults.values,
      ...values,
    }, refreshedAt: DateTime.tryParse('${json['refreshed_at'] ?? ''}'));
  }

  factory AppContentBundle.fromRpcRows(
    Iterable<Map<String, Object?>> rows, {
    required String supabaseUrl,
    DateTime? refreshedAt,
  }) {
    final values = <String, AppContentValue>{...defaults.values};
    for (final row in rows) {
      final key = row['content_key'];
      if (key is! String || !AppContentKeys.values.contains(key)) continue;
      final rawText = row['value_ar'];
      final text =
          rawText is String &&
              rawText.trim().isNotEmpty &&
              rawText.trim().length <= 1000
          ? rawText.trim()
          : values[key]?.textAr;
      final path = row['media_storage_path'];
      final updatedAt = row['media_updated_at'];
      final version = switch (row['content_version']) {
        final num value => value.toInt(),
        final String value => int.tryParse(value) ?? 0,
        _ => 0,
      };
      final rawAltText = row['media_alt_text'];
      values[key] = AppContentValue(
        textAr: text,
        imageUrl: path is String && _isSafeStoragePath(path)
            ? _publicStorageUrl(
                supabaseUrl,
                path,
                cacheVersion: updatedAt?.toString() ?? '$version',
              )
            : null,
        imageAltText: rawAltText is String && rawAltText.length <= 160
            ? rawAltText
            : null,
        version: version,
      );
    }
    return AppContentBundle(
      values,
      refreshedAt: refreshedAt ?? DateTime.now().toUtc(),
    );
  }

  static const defaults = AppContentBundle({
    AppContentKeys.homeHeroTitle: AppContentValue(
      textAr: 'مستعد تثبت إنك تعرف الكورة؟',
    ),
    AppContentKeys.homeHeroSubtitle: AppContentValue(
      textAr: '15 سؤال • دقايق قليلة',
    ),
    AppContentKeys.homeFeaturedTitle: AppContentValue(textAr: 'تحدي اليوم'),
    AppContentKeys.homeFeaturedDescription: AppContentValue(
      textAr: '5 أسئلة ومكافأة تنتظرك',
    ),
    AppContentKeys.premiumHeroTitle: AppContentValue(textAr: '11 Premium'),
    AppContentKeys.premiumHeroSubtitle: AppContentValue(
      textAr: 'بدون إعلانات • مزايا تجميلية • إحصائيات أوسع',
    ),
    AppContentKeys.storeBannerTitle: AppContentValue(textAr: 'ميّز حسابك'),
    AppContentKeys.storeBannerSubtitle: AppContentValue(
      textAr: 'عناصر تجميلية بدون أفضلية تنافسية',
    ),
    AppContentKeys.maintenanceMessage: AppContentValue(
      textAr: 'نرجع لك قريب، نجهّز الملعب.',
    ),
    AppContentKeys.announcementTitle: AppContentValue(
      textAr: 'الجديد في أحدعش',
    ),
    AppContentKeys.announcementDescription: AppContentValue(
      textAr: 'تابع التحديات والمواسم الجديدة.',
    ),
    AppContentKeys.appearanceAccentColor: AppContentValue(textAr: '#78B814'),
    AppContentKeys.featureHomePromotion: AppContentValue(textAr: 'false'),
    AppContentKeys.featureHomeSeasonal: AppContentValue(textAr: 'false'),
    AppContentKeys.featurePremiumPromotion: AppContentValue(textAr: 'true'),
    AppContentKeys.featureRewardedCta: AppContentValue(textAr: 'false'),
    AppContentKeys.featureHomeFeatured: AppContentValue(textAr: 'true'),
  });

  final Map<String, AppContentValue> values;
  final DateTime? refreshedAt;

  String text(String key, String fallback) =>
      values[key]?.textAr?.trim().isNotEmpty == true
      ? values[key]!.textAr!.trim()
      : fallback;

  String? imageUrl(String key) => values[key]?.imageUrl;

  bool flag(String key, {required bool fallback}) {
    return switch (values[key]?.textAr?.trim().toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => fallback,
    };
  }

  String accentHex({String fallback = '#78B814'}) {
    final value = values[AppContentKeys.appearanceAccentColor]?.textAr?.trim();
    return value != null && RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)
        ? value.toUpperCase()
        : fallback;
  }

  Map<String, Object?> toJson() => {
    'values': values.map((key, value) => MapEntry(key, value.toJson())),
    'refreshed_at': refreshedAt?.toIso8601String(),
  };

  String encode() => jsonEncode(toJson());

  static AppContentBundle? tryDecode(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final json = jsonDecode(source);
      return json is Map
          ? AppContentBundle.fromJson(Map<String, Object?>.from(json))
          : null;
    } on Object {
      return null;
    }
  }

  static bool _isSafeStoragePath(String path) {
    return RegExp(
          r'^(app-content|categories|store|achievements|promotions|onboarding|branding|app-icons)/[A-Za-z0-9/_-]+\.(jpg|jpeg|png|webp)$',
        ).hasMatch(path) &&
        !path.split('/').contains('..');
  }

  static String _publicStorageUrl(
    String baseUrl,
    String path, {
    required String cacheVersion,
  }) {
    final base = Uri.parse(baseUrl);
    final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
    return base
        .replace(
          path:
              '${base.path.replaceAll(RegExp(r'/$'), '')}/storage/v1/object/public/app-content/$encodedPath',
          queryParameters: {'v': cacheVersion},
        )
        .toString();
  }
}
