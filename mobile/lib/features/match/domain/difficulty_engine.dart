import 'quiz_question.dart';

abstract final class DifficultyEngine {
  static QuestionDifficulty reassess({
    required QuestionDifficulty current,
    required int timesPlayed,
    required int correctAnswers,
    int minimumSampleSize = 50,
  }) {
    if (timesPlayed < minimumSampleSize || timesPlayed <= 0) return current;
    final correctRate = correctAnswers / timesPlayed;
    if (correctRate >= 0.9) return _easier(current);
    if (correctRate < 0.25) return _harder(current);
    return current;
  }

  static QuestionDifficulty _easier(QuestionDifficulty value) =>
      switch (value) {
        QuestionDifficulty.easy => QuestionDifficulty.easy,
        QuestionDifficulty.medium => QuestionDifficulty.easy,
        QuestionDifficulty.hard => QuestionDifficulty.medium,
        QuestionDifficulty.expert => QuestionDifficulty.hard,
      };

  static QuestionDifficulty _harder(QuestionDifficulty value) =>
      switch (value) {
        QuestionDifficulty.easy => QuestionDifficulty.medium,
        QuestionDifficulty.medium => QuestionDifficulty.hard,
        QuestionDifficulty.hard => QuestionDifficulty.expert,
        QuestionDifficulty.expert => QuestionDifficulty.expert,
      };
}
