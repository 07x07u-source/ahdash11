import 'question_history_entry.dart';
import 'quiz_question.dart';

abstract interface class QuestionRepository {
  Future<List<QuizQuestion>> loadSoloPool();
  Future<List<QuestionHistoryEntry>> loadHistory();
  Future<void> recordAnswer({
    required String questionId,
    required int selectedIndex,
    required bool correct,
  });
}
