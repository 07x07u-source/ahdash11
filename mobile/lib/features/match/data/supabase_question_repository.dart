import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/app_database.dart';
import '../domain/question_history_entry.dart';
import '../domain/question_repository.dart';
import '../domain/quiz_question.dart';
import 'drift_question_repository.dart';

final class SupabaseQuestionRepository implements QuestionRepository {
  SupabaseQuestionRepository(this._client, this._database);

  final SupabaseClient _client;
  final AppDatabase _database;

  @override
  Future<List<QuestionHistoryEntry>> loadHistory() async {
    final localRows = await _database.readQuestionHistory();
    return localRows
        .map(
          (row) => QuestionHistoryEntry(
            questionId: row['question_id']! as String,
            seenCount: row['seen_count']! as int,
            correctCount: row['correct_count']! as int,
            lastSeenAt: DateTime.fromMillisecondsSinceEpoch(
              row['last_seen_at']! as int,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<QuizQuestion>> loadSoloPool() async {
    try {
      final response = await _client.rpc<Object?>(
        'get_solo_question_pack',
        params: {'p_limit': 100},
      );
      if (response is! List) {
        throw const FormatException('Question pack response must be a list');
      }
      final rows = response.whereType<Map<String, Object?>>().toList(
        growable: false,
      );
      final questions = rows.map(QuizQuestion.fromJson).toList(growable: false);
      await _database.replaceQuestions(rows);
      if (questions.isEmpty) {
        // An empty server pack is intentional when no answer-key content has
        // been curated exclusively for unranked offline Practice. Never reuse
        // an older competitive cache; fall back to the bundled demo pool.
        return await DriftQuestionRepository(_database).loadSoloPool();
      }
      return questions;
    } catch (_) {
      final cached = await _database.readQuestions();
      if (cached.isNotEmpty) {
        return cached.map(QuizQuestion.fromJson).toList(growable: false);
      }
      return DriftQuestionRepository(_database).loadSoloPool();
    }
  }

  @override
  Future<void> recordAnswer({
    required String questionId,
    required int selectedIndex,
    required bool correct,
  }) async {
    await _database.recordQuestionSeen(
      questionId: questionId,
      correct: correct,
      seenAt: DateTime.now(),
    );
    try {
      await _client.rpc<Object?>(
        'record_solo_answer',
        params: {
          'p_question_id': questionId,
          'p_selected_position': selectedIndex + 1,
        },
      );
    } catch (_) {
      // Local history remains authoritative for offline question selection and
      // will be reconciled by the pending-operation sync layer.
    }
  }
}
