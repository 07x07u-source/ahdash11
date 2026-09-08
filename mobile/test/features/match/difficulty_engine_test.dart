import 'package:ahdash_11/features/match/domain/difficulty_engine.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not reassess before the minimum sample size', () {
    final result = DifficultyEngine.reassess(
      current: QuestionDifficulty.medium,
      timesPlayed: 49,
      correctAnswers: 49,
    );

    expect(result, QuestionDifficulty.medium);
  });

  test('moves very easy questions down one level', () {
    final result = DifficultyEngine.reassess(
      current: QuestionDifficulty.hard,
      timesPlayed: 100,
      correctAnswers: 92,
    );

    expect(result, QuestionDifficulty.medium);
  });

  test('moves questions below 25 percent up one level', () {
    final result = DifficultyEngine.reassess(
      current: QuestionDifficulty.medium,
      timesPlayed: 100,
      correctAnswers: 24,
    );

    expect(result, QuestionDifficulty.hard);
  });
}
