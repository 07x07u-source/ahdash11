import 'package:ahdash_11/features/game/domain/game_mode.dart';
import 'package:ahdash_11/features/match/domain/question_engine.dart';
import 'package:ahdash_11/features/match/domain/question_history_entry.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';

QuizQuestion question(String id, String category, {String? player}) {
  return QuizQuestion(
    id: id,
    text: id,
    options: const ['1', '2', '3', '4'],
    correctOptionIndex: 0,
    categoryId: category,
    difficulty: QuestionDifficulty.medium,
    player: player,
  );
}

void main() {
  const engine = QuestionEngine();

  test('distributes questions as evenly as possible across categories', () {
    final pool = [
      for (var i = 0; i < 8; i++) question('a$i', 'a'),
      for (var i = 0; i < 8; i++) question('b$i', 'b'),
      for (var i = 0; i < 8; i++) question('c$i', 'c'),
    ];
    final selected = engine.select(
      pool: pool,
      request: const QuestionSelectionRequest(
        categoryIds: {'a', 'b', 'c'},
        difficulty: QuestionDifficulty.medium,
        count: 15,
      ),
      history: const [],
    );

    final counts = <String, int>{};
    for (final item in selected) {
      counts.update(item.categoryId, (value) => value + 1, ifAbsent: () => 1);
    }
    expect(counts.values.toSet(), {5});
    expect(selected.map((item) => item.id).toSet().length, 15);
  });

  test('prefers unseen over recently seen questions', () {
    final now = DateTime(2026, 8, 27);
    final selected = engine.select(
      pool: [question('seen', 'a'), question('unseen', 'a')],
      request: const QuestionSelectionRequest(
        categoryIds: {'a'},
        difficulty: QuestionDifficulty.medium,
        count: 1,
      ),
      history: [
        QuestionHistoryEntry(
          questionId: 'seen',
          seenCount: 1,
          correctCount: 1,
          lastSeenAt: now,
        ),
      ],
      now: now,
    );

    expect(selected.single.id, 'unseen');
  });

  test('keeps True/False content separate while Speed reuses Classic', () {
    final trueFalse = QuizQuestion(
      id: 'tf',
      text: 'عبارة اختبارية واضحة.',
      options: const ['صح', 'خطأ'],
      correctOptionIndex: 0,
      categoryId: 'a',
      difficulty: QuestionDifficulty.medium,
      gameType: GameType.trueFalse,
    );
    final pool = [question('classic', 'a'), trueFalse];

    final trueFalseSelection = engine.select(
      pool: pool,
      request: const QuestionSelectionRequest(
        categoryIds: {'a'},
        difficulty: QuestionDifficulty.medium,
        count: 2,
        gameType: GameType.trueFalse,
      ),
      history: const [],
    );
    final speedSelection = engine.select(
      pool: pool,
      request: const QuestionSelectionRequest(
        categoryIds: {'a'},
        difficulty: QuestionDifficulty.medium,
        count: 2,
        gameType: GameType.speed,
      ),
      history: const [],
    );

    expect(trueFalseSelection.map((value) => value.id), ['tf']);
    expect(speedSelection.map((value) => value.id), ['classic']);
  });
}
