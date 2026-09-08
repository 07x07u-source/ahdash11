import 'package:ahdash_11/features/content/domain/app_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'safe feature flags and accent color reject malformed remote values',
    () {
      final content = AppContentBundle.fromRpcRows([
        {
          'content_key': AppContentKeys.featureHomePromotion,
          'value_ar': 'true',
        },
        {
          'content_key': AppContentKeys.featureHomeSeasonal,
          'value_ar': 'definitely',
        },
        {
          'content_key': AppContentKeys.appearanceAccentColor,
          'value_ar': '#2F6FBA',
        },
      ], supabaseUrl: 'https://example.supabase.co');

      expect(
        content.flag(AppContentKeys.featureHomePromotion, fallback: false),
        isTrue,
      );
      expect(
        content.flag(AppContentKeys.featureHomeSeasonal, fallback: true),
        isTrue,
      );
      expect(content.accentHex(), '#2F6FBA');

      final malformed = AppContentBundle.fromRpcRows([
        {
          'content_key': AppContentKeys.appearanceAccentColor,
          'value_ar': 'url(javascript:alert(1))',
        },
      ], supabaseUrl: 'https://example.supabase.co');
      expect(malformed.accentHex(fallback: '#74B512'), '#74B512');
    },
  );

  test('parses typed remote copy and versioned public media URLs', () {
    final content = AppContentBundle.fromRpcRows([
      {
        'content_key': AppContentKeys.homeHeroTitle,
        'value_ar': '  عنوان من لوحة التحكم  ',
        'content_version': 4,
      },
      {
        'content_key': AppContentKeys.homeHeroImage,
        'media_storage_path': 'app-content/2026/08/hero.webp',
        'media_updated_at': '2026-08-28T08:00:00Z',
        'media_alt_text': 'ملعب ليلي',
        'content_version': 2,
      },
    ], supabaseUrl: 'https://example.supabase.co');

    expect(
      content.text(AppContentKeys.homeHeroTitle, 'fallback'),
      'عنوان من لوحة التحكم',
    );
    expect(
      content.imageUrl(AppContentKeys.homeHeroImage),
      contains(
        '/storage/v1/object/public/app-content/app-content/2026/08/hero.webp?v=',
      ),
    );
  });

  test('keeps local defaults for missing or malformed remote content', () {
    final content = AppContentBundle.fromRpcRows([
      {
        'content_key': 'unknown.unsafe.key',
        'value_ar': 'لا يجب قبوله',
        'media_storage_path': '../attack.svg',
      },
    ], supabaseUrl: 'https://example.supabase.co');

    expect(
      content.text(AppContentKeys.homeFeaturedTitle, 'fallback'),
      'تحدي اليوم',
    );
    expect(content.values.containsKey('unknown.unsafe.key'), isFalse);
  });

  test('cached content round-trips while defaults fill missing keys', () {
    final source = AppContentBundle.fromRpcRows([
      {
        'content_key': AppContentKeys.premiumHeroTitle,
        'value_ar': 'Premium جديد',
        'content_version': 3,
      },
    ], supabaseUrl: 'https://example.supabase.co');
    final cached = AppContentBundle.tryDecode(source.encode());

    expect(cached, isNotNull);
    expect(
      cached!.text(AppContentKeys.premiumHeroTitle, 'fallback'),
      'Premium جديد',
    );
    expect(
      cached.text(AppContentKeys.homeHeroTitle, 'fallback'),
      'مستعد تثبت إنك تعرف الكورة؟',
    );
  });
}
