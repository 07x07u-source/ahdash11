import 'package:ahdash_11/features/profile/domain/player_profile.dart';
import 'package:ahdash_11/features/store/domain/store_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store item parses the deployed Supabase column contract', () {
    final item = StoreItem.fromJson({
      'id': '00000000-0000-4000-8000-000000000011',
      'name_ar': 'إطار أخضر',
      'description_ar': 'عنصر تجميلي',
      'type': 'cosmetic',
      'price_coins': 900,
      'metadata': {'icon_name': 'shield', 'premium_only': true},
    });

    expect(item.name, 'إطار أخضر');
    expect(item.type, StoreItemType.cosmetic);
    expect(item.iconName, 'shield');
    expect(item.isPremiumOnly, isTrue);
  });

  test('profile parses the composed server summary contract', () {
    final profile = PlayerProfile.fromJson({
      'id': '00000000-0000-4000-8000-000000000022',
      'username': 'player11',
      'level': 7,
      'xp': 640,
      'coins': 250,
      'rating': 1337,
      'wins': 8,
      'losses': 3,
      'draws': 1,
      'matches': 12,
      'accuracy': 0.72,
      'best_streak': 9,
      'current_streak': 2,
      'rank': 41,
      'is_premium': true,
    });

    expect(profile.coins, 250);
    expect(profile.matches, 12);
    expect(profile.accuracy, 0.72);
    expect(profile.isPremium, isTrue);
  });
}
