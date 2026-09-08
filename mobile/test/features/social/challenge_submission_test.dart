import 'package:ahdash_11/features/social/domain/challenge_submission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retry keeps the exact challenge idempotency receipt request', () {
    final tracker = ChallengeSubmissionTracker(keyFactory: () => 'fixed-key');
    final first = tracker.begin(
      attemptId: 'attempt-1',
      questionId: 'question-1',
      optionId: 'option-a',
    );
    final retry = tracker.begin(
      attemptId: 'attempt-1',
      questionId: 'question-1',
      optionId: 'option-b',
    );

    expect(retry, same(first));
    expect(retry.optionId, 'option-a');
    expect(retry.clientSequence, 1);
    expect(retry.idempotencyKey, contains('fixed-key'));
  });

  test('the next confirmed question receives the next client sequence', () {
    final tracker = ChallengeSubmissionTracker(keyFactory: () => 'key');
    final first = tracker.begin(
      attemptId: 'attempt-1',
      questionId: 'question-1',
      optionId: null,
    );
    tracker.complete(first);
    final second = tracker.begin(
      attemptId: 'attempt-1',
      questionId: 'question-2',
      optionId: 'option-b',
    );

    expect(second.clientSequence, 2);
    expect(second.idempotencyKey, isNot(first.idempotencyKey));
  });
}
