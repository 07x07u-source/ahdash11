import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'client-safe online payload preserves option ids without an answer key',
    () {
      final question = PublicQuestion.fromJson({
        'match_question_id': 'mq-1',
        'match_id': 'm-1',
        'question_text': 'سؤال شبكي آمن؟',
        'category_id': 'cat-1',
        'closes_at': '2026-08-27T18:00:00Z',
        'options': [
          {'id': 'o-1', 'text': 'أ'},
          {'id': 'o-2', 'text': 'ب'},
          {'id': 'o-3', 'text': 'ج'},
          {'id': 'o-4', 'text': 'د'},
        ],
      });

      expect(question.id, 'mq-1');
      expect(question.options, ['أ', 'ب', 'ج', 'د']);
      expect(question.optionIds, ['o-1', 'o-2', 'o-3', 'o-4']);
      expect(question.difficulty, QuestionDifficulty.medium);
    },
  );
}
