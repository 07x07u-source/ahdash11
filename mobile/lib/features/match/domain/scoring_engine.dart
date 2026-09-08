import 'dart:math' as math;

final class ScoringRules {
  const ScoringRules({
    this.basePoints = 100,
    this.maxSpeedBonus = 50,
    this.timeLimit = const Duration(seconds: 15),
  });

  final int basePoints;
  final int maxSpeedBonus;
  final Duration timeLimit;
}

final class ScoreBreakdown {
  const ScoreBreakdown({required this.basePoints, required this.speedBonus});

  final int basePoints;
  final int speedBonus;

  int get total => basePoints + speedBonus;
}

abstract final class ScoringEngine {
  static ScoreBreakdown calculate({
    required bool correct,
    required Duration answerTime,
    required ScoringRules rules,
  }) {
    if (!correct) {
      return const ScoreBreakdown(basePoints: 0, speedBonus: 0);
    }
    final elapsed = math.max(0, answerTime.inMilliseconds);
    final limit = math.max(1, rules.timeLimit.inMilliseconds);
    final remainingRatio = (1 - (elapsed / limit)).clamp(0.0, 1.0);
    return ScoreBreakdown(
      basePoints: rules.basePoints,
      speedBonus: (rules.maxSpeedBonus * remainingRatio).round(),
    );
  }
}
