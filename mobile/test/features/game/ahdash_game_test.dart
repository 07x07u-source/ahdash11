import 'package:ahdash_11/core/theme/app_game_theme.dart';
import 'package:ahdash_11/features/game/presentation/ahdash_game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWithGame<AhdashGame>(
    'correct verdict mounts and then removes a bounded visual burst',
    () => AhdashGame(
      theme: FlameGameThemeAdapter.fromAppTheme(_theme),
      reduceMotion: false,
    ),
    (game) async {
      final baseline = game.world.children.length;
      await game.showVerdict(correct: true);
      game.update(0);
      await game.ready();
      game.update(0);
      expect(game.world.children.length, greaterThan(baseline));

      game.update(0.5);
      game.update(0);
      expect(game.world.children.length, baseline);
    },
  );

  testWithGame<AhdashGame>(
    'reduced motion does not mount verdict particles',
    () => AhdashGame(
      theme: FlameGameThemeAdapter.fromAppTheme(_theme),
      reduceMotion: true,
    ),
    (game) async {
      final baseline = game.world.children.length;
      await game.showVerdict(correct: true);
      game.update(0);
      expect(game.world.children.length, baseline);
    },
  );
}

const _theme = AppGameTheme(
  stageTop: Color(0xFF131922),
  stageBottom: Color(0xFF0B0F14),
  energy: Color(0xFFB6FF3B),
  correct: Color(0xFF50E3A4),
  wrong: Color(0xFFFF4D57),
  dangerTimer: Color(0xFFFF6B55),
  teamA: Color(0xFF58A6FF),
  teamB: Color(0xFFFF7A9E),
  focus: Color(0xFFF7F9FB),
  celebrationDuration: Duration(milliseconds: 520),
  feedbackDuration: Duration(milliseconds: 300),
);
