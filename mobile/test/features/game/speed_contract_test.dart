import 'package:ahdash_11/features/game/domain/game_mode.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Speed and two-option True/False are enabled', () {
    expect(GameType.speed.isEnabled, isTrue);
    expect(GameType.trueFalse.isEnabled, isTrue);
  });

  test('safe server payload carries Speed metadata without an answer key', () {
    final question = PublicQuestion.fromJson({
      'match_question_id': 'question-1',
      'question_text': 'من فاز؟',
      'category_id': 'category-1',
      'duration_ms': 7000,
      'game_type': 'speed',
      'server_now': '2026-08-28T12:00:00Z',
      'closes_at': '2026-08-28T12:00:07Z',
      'options': const [
        {'id': 'a', 'text': 'أ'},
        {'id': 'b', 'text': 'ب'},
        {'id': 'c', 'text': 'ج'},
        {'id': 'd', 'text': 'د'},
      ],
    });

    expect(question.gameType, 'speed');
    expect(question.durationMs, 7000);
    expect(question.options, hasLength(4));
    expect(
      question.serverDeadline?.difference(question.serverNow!),
      const Duration(seconds: 7),
    );
  });
}
