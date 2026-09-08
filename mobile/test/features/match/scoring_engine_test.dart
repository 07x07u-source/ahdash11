import 'package:ahdash_11/features/match/domain/scoring_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rules = ScoringRules();

  test('correct immediate answer earns base and full speed bonus', () {
    final score = ScoringEngine.calculate(
      correct: true,
      answerTime: Duration.zero,
      rules: rules,
    );

    expect(score.basePoints, 100);
    expect(score.speedBonus, 50);
    expect(score.total, 150);
  });

  test('speed bonus decreases linearly and never becomes negative', () {
    final halfway = ScoringEngine.calculate(
      correct: true,
      answerTime: const Duration(milliseconds: 7500),
      rules: rules,
    );
    final late = ScoringEngine.calculate(
      correct: true,
      answerTime: const Duration(seconds: 99),
      rules: rules,
    );

    expect(halfway.speedBonus, 25);
    expect(late.speedBonus, 0);
  });

  test('wrong answer always earns zero', () {
    final score = ScoringEngine.calculate(
      correct: false,
      answerTime: const Duration(milliseconds: 1),
      rules: rules,
    );

    expect(score.total, 0);
  });
}
