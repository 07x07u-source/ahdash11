import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';

@immutable
final class AppGameTheme {
  const AppGameTheme({
    required this.stageTop,
    required this.stageBottom,
    required this.energy,
    required this.correct,
    required this.wrong,
    required this.dangerTimer,
    required this.teamA,
    required this.teamB,
    required this.focus,
    required this.celebrationDuration,
    required this.feedbackDuration,
  });

  factory AppGameTheme.fromPalette(AhdashColors palette) => AppGameTheme(
    stageTop: palette.surfaceElevated,
    stageBottom: palette.background,
    energy: palette.primary,
    correct: palette.success,
    wrong: palette.error,
    dangerTimer: palette.dangerTimer,
    teamA: palette.teamA,
    teamB: palette.teamB,
    focus: palette.focus,
    celebrationDuration: AppMotion.celebration,
    feedbackDuration: AppMotion.emphasized,
  );

  final Color stageTop;
  final Color stageBottom;
  final Color energy;
  final Color correct;
  final Color wrong;
  final Color dangerTimer;
  final Color teamA;
  final Color teamB;
  final Color focus;
  final Duration celebrationDuration;
  final Duration feedbackDuration;
}

extension AppGameThemeContext on BuildContext {
  AppGameTheme get gameTheme => AppGameTheme.fromPalette(
    Theme.of(this).extension<AhdashColors>() ?? AhdashColors.dark,
  );
}
