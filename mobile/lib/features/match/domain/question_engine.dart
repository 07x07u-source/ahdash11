import 'dart:math';

import '../../game/domain/game_mode.dart';
import 'question_history_entry.dart';
import 'quiz_question.dart';

final class QuestionSelectionRequest {
  const QuestionSelectionRequest({
    required this.categoryIds,
    required this.difficulty,
    required this.count,
    this.seed = 11,
    this.gameType = GameType.classic,
  });

  final Set<String> categoryIds;
  final QuestionDifficulty difficulty;
  final int count;
  final int seed;
  final GameType gameType;
}

final class QuestionEngine {
  const QuestionEngine();

  List<QuizQuestion> select({
    required List<QuizQuestion> pool,
    required QuestionSelectionRequest request,
    required List<QuestionHistoryEntry> history,
    DateTime? now,
  }) {
    if (request.count <= 0 || request.categoryIds.isEmpty) return const [];
    final contentType = request.gameType == GameType.speed
        ? GameType.classic
        : request.gameType;
    final selectedPool = pool
        .where(
          (question) =>
              request.categoryIds.contains(question.categoryId) &&
              question.gameType == contentType,
        )
        .toList(growable: false);
    if (selectedPool.isEmpty) return const [];

    final timestamp = now ?? DateTime.now();
    final historyByQuestion = {
      for (final entry in history) entry.questionId: entry,
    };
    final random = Random(request.seed);
    final categoryOrder = request.categoryIds.toList()..shuffle(random);
    final grouped = <String, List<QuizQuestion>>{};
    for (final categoryId in categoryOrder) {
      final questions =
          selectedPool
              .where((question) => question.categoryId == categoryId)
              .toList()
            ..shuffle(random)
            ..sort(
              (left, right) =>
                  _priority(
                    right,
                    historyByQuestion[right.id],
                    request.difficulty,
                    timestamp,
                  ).compareTo(
                    _priority(
                      left,
                      historyByQuestion[left.id],
                      request.difficulty,
                      timestamp,
                    ),
                  ),
            );
      grouped[categoryId] = questions;
    }

    final result = <QuizQuestion>[];
    final used = <String>{};
    final recentEntities = <String>[];
    final baseQuota = request.count ~/ categoryOrder.length;
    final remainder = request.count % categoryOrder.length;
    for (var index = 0; index < categoryOrder.length; index++) {
      final categoryId = categoryOrder[index];
      final quota = baseQuota + (index < remainder ? 1 : 0);
      _takeDiverse(
        source: grouped[categoryId] ?? const [],
        amount: quota,
        destination: result,
        used: used,
        recentEntities: recentEntities,
      );
    }

    if (result.length < request.count) {
      final remaining =
          selectedPool.where((question) => !used.contains(question.id)).toList()
            ..sort(
              (left, right) =>
                  _priority(
                    right,
                    historyByQuestion[right.id],
                    request.difficulty,
                    timestamp,
                  ).compareTo(
                    _priority(
                      left,
                      historyByQuestion[left.id],
                      request.difficulty,
                      timestamp,
                    ),
                  ),
            );
      _takeDiverse(
        source: remaining,
        amount: request.count - result.length,
        destination: result,
        used: used,
        recentEntities: recentEntities,
      );
    }
    return result.take(request.count).toList(growable: false);
  }

  int _priority(
    QuizQuestion question,
    QuestionHistoryEntry? history,
    QuestionDifficulty desired,
    DateTime now,
  ) {
    final difficultyDistance = (question.difficulty.index - desired.index)
        .abs();
    if (history == null) return 100000 - (difficultyDistance * 1000);
    final daysSinceSeen = now
        .difference(history.lastSeenAt)
        .inDays
        .clamp(0, 365);
    return 20000 +
        (daysSinceSeen * 100) -
        (history.seenCount * 250) -
        (difficultyDistance * 1000);
  }

  void _takeDiverse({
    required List<QuizQuestion> source,
    required int amount,
    required List<QuizQuestion> destination,
    required Set<String> used,
    required List<String> recentEntities,
  }) {
    for (var pick = 0; pick < amount; pick++) {
      final available = source
          .where((question) => !used.contains(question.id))
          .toList();
      if (available.isEmpty) return;
      final diverse = available.where((question) {
        final entity = question.player ?? question.club;
        return entity == null || !recentEntities.contains(entity);
      });
      final chosen = diverse.isNotEmpty ? diverse.first : available.first;
      destination.add(chosen);
      used.add(chosen.id);
      final entity = chosen.player ?? chosen.club;
      if (entity != null) {
        recentEntities.add(entity);
        if (recentEntities.length > 2) recentEntities.removeAt(0);
      }
    }
  }
}
