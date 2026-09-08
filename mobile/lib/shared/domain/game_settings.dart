final class GameSettings {
  const GameSettings({
    this.defaultQuestionCount = 15,
    this.baseScore = 100,
    this.maxSpeedBonus = 50,
    this.questionTimeSeconds = 15,
    this.difficultySampleSize = 50,
  });

  factory GameSettings.fromJson(Map<String, Object?> json) {
    int integer(String key, int fallback) {
      return switch (json[key]) {
        final int value => value,
        final num value => value.round(),
        _ => fallback,
      };
    }

    return GameSettings(
      defaultQuestionCount: integer('default_question_count', 15),
      baseScore: integer('base_score', 100),
      maxSpeedBonus: integer('max_speed_bonus', 50),
      questionTimeSeconds: integer('question_time_seconds', 15),
      difficultySampleSize: integer('difficulty_sample_size', 50),
    );
  }

  final int defaultQuestionCount;
  final int baseScore;
  final int maxSpeedBonus;
  final int questionTimeSeconds;
  final int difficultySampleSize;
}
