import 'package:flutter/material.dart';

import '../../../shared/presentation/visual_art.dart';
import '../domain/game_mode.dart';

final class AhdashGameTile extends StatelessWidget {
  const AhdashGameTile({
    required this.type,
    required this.onTap,
    this.compact = false,
    this.imageUrl,
    super.key,
  });

  final GameType type;
  final VoidCallback? onTap;
  final bool compact;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final enabled = type.isEnabled && onTap != null;
    return AhdashImageTile(
      asset: artworkFor(type),
      imageUrl: imageUrl,
      title: type.titleAr,
      subtitle: enabled ? type.descriptionAr : _comingSoonReason,
      badge: enabled ? _badge : 'قريبًا',
      onTap: enabled ? onTap : null,
      enabled: enabled,
      height: compact ? 160 : 238,
      imageAlignment: type == GameType.speed
          ? Alignment.centerLeft
          : Alignment.center,
    );
  }

  static String artworkFor(GameType type) => switch (type) {
    GameType.classic => 'assets/images/modes/classic_mode_art.webp',
    GameType.trueFalse => 'assets/images/modes/true_false_mode_art.webp',
    GameType.speed => 'assets/images/modes/speed_mode_art.webp',
    GameType.ordering => 'assets/images/backgrounds/play_hub_background.webp',
    GameType.clubGuess => 'assets/images/store/team_patterns.webp',
    GameType.eagleEye => 'assets/visuals/eagle-eye-cover.png',
  };

  String get _badge => switch (type) {
    GameType.classic => 'شائع',
    GameType.trueFalse => 'خاطف',
    GameType.speed => '7 ثوانٍ',
    _ => 'جديد',
  };

  String get _comingSoonReason => switch (type) {
    GameType.ordering => 'قيد تجهيز محرر الأسئلة',
    GameType.clubGuess => 'قيد تجهيز بيانات الأندية',
    GameType.eagleEye => 'قيد تجهيز أصول مرخّصة',
    _ => type.descriptionAr,
  };
}
