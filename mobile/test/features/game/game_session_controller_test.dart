import 'dart:async';

import 'package:ahdash_11/features/game/application/game_clock.dart';
import 'package:ahdash_11/features/game/application/game_session_controller.dart';
import 'package:ahdash_11/features/match/data/online_match_gateway.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameSessionController', () {
    test(
      'first answer locks synchronously and prevents double submission',
      () async {
        final now = DateTime.utc(2026, 8, 28, 12);
        final clock = _FakeClock(now);
        final gateway = _FakeGateway(_question(now));
        final submitCompleter = Completer<OnlineAnswerReceipt>();
        gateway.submitCompleter = submitCompleter;
        final controller = GameSessionController(
          matchId: 'match-1',
          gateway: gateway,
          clock: clock,
          idempotencyKeyFactory: () => 'attempt-a',
        );
        addTearDown(controller.dispose);

        await controller.start();
        expect(controller.state.phase, GameSessionPhase.acceptingInput);

        final first = controller.submitAnswer(0);
        final second = controller.submitAnswer(1);

        expect(gateway.submitCalls, 1);
        expect(controller.state.selectedOptionId, 'option-1');
        expect(
          controller.state.phase,
          anyOf(
            GameSessionPhase.lockingInput,
            GameSessionPhase.submittingAnswer,
          ),
        );

        submitCompleter.complete(
          OnlineAnswerReceipt(
            accepted: true,
            duplicate: false,
            serverReceivedAt: now,
            reveal: const AnswerReveal(
              questionId: 'question-1',
              correctOptionId: 'option-1',
              answers: [],
            ),
          ),
        );
        await Future.wait([first, second]);

        expect(controller.state.reveal?.correctOptionId, 'option-1');
        expect(gateway.idempotencyKeys.single, contains('attempt-a'));
        expect(gateway.clientSequences.single, 1);
      },
    );

    test('safe retry reuses the same idempotency key and sequence', () async {
      final now = DateTime.utc(2026, 8, 28, 12);
      final clock = _FakeClock(now);
      final gateway = _FakeGateway(_question(now))..throwFirstSubmit = true;
      final controller = GameSessionController(
        matchId: 'match-1',
        gateway: gateway,
        clock: clock,
        idempotencyKeyFactory: () => 'stable-attempt',
      );
      addTearDown(controller.dispose);
      await controller.start();

      await controller.submitAnswer(2);
      expect(controller.state.canRetrySubmission, isTrue);
      await controller.retryPendingSubmission();

      expect(gateway.submitCalls, 2);
      expect(gateway.idempotencyKeys.toSet().length, 1);
      expect(gateway.clientSequences, [1, 1]);
      expect(controller.state.reveal, isNotNull);
    });

    test('server clock offset drives deadline and timeout reveal', () async {
      final clientNow = DateTime.utc(2026, 8, 28, 12);
      final serverNow = clientNow.add(const Duration(minutes: 5));
      final clock = _FakeClock(clientNow);
      final gateway = _FakeGateway(
        _question(
          clientNow,
          serverNow: serverNow,
          deadline: serverNow.add(const Duration(seconds: 10)),
        ),
      );
      final controller = GameSessionController(
        matchId: 'match-1',
        gateway: gateway,
        clock: clock,
      );
      addTearDown(controller.dispose);

      await controller.start();
      expect(controller.state.remaining, const Duration(seconds: 10));

      clock.advance(const Duration(seconds: 11));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.remaining, Duration.zero);
      expect(controller.state.reveal, isNotNull);
      expect(gateway.revealCalls, 1);
    });

    test('accepts the safe two-option True/False server contract', () async {
      final now = DateTime.utc(2026, 8, 28, 12);
      final gateway = _FakeGateway(
        _question(now, gameType: 'true-false', optionCount: 2),
      );
      final controller = GameSessionController(
        matchId: 'match-true-false',
        gateway: gateway,
        clock: _FakeClock(now),
      );
      addTearDown(controller.dispose);

      await controller.start();

      expect(controller.state.phase, GameSessionPhase.acceptingInput);
      expect(controller.state.question?.options, ['أ', 'ب']);
    });
  });
}

PublicQuestion _question(
  DateTime clientNow, {
  DateTime? serverNow,
  DateTime? deadline,
  String gameType = 'classic',
  int optionCount = 4,
}) {
  const allOptions = ['أ', 'ب', 'ج', 'د'];
  const allOptionIds = ['option-1', 'option-2', 'option-3', 'option-4'];
  return PublicQuestion(
    id: 'question-1',
    text: 'من فاز؟',
    options: allOptions.take(optionCount).toList(growable: false),
    optionIds: allOptionIds.take(optionCount).toList(growable: false),
    categoryId: 'category-1',
    difficulty: QuestionDifficulty.medium,
    serverNow: serverNow ?? clientNow,
    serverDeadline: deadline ?? clientNow.add(const Duration(seconds: 15)),
    gameType: gameType,
  );
}

final class _FakeClock implements GameClock {
  _FakeClock(this._now);

  DateTime _now;
  final _ticks = StreamController<DateTime>.broadcast();

  void advance(Duration duration) {
    _now = _now.add(duration);
    _ticks.add(_now);
  }

  @override
  DateTime nowUtc() => _now;

  @override
  Stream<DateTime> ticks(Duration interval) => _ticks.stream;

  @override
  Future<void> wait(Duration duration) async {}
}

final class _FakeGateway implements OnlineMatchGateway {
  _FakeGateway(this.question);

  final PublicQuestion question;
  Completer<OnlineAnswerReceipt>? submitCompleter;
  bool throwFirstSubmit = false;
  int submitCalls = 0;
  int revealCalls = 0;
  final idempotencyKeys = <String>[];
  final clientSequences = <int>[];

  @override
  Future<PublicQuestion> fetchCurrentQuestion(String matchId) async => question;

  @override
  Future<OnlineAnswerReceipt> submitAnswer({
    required String matchQuestionId,
    required String matchOptionId,
    required String idempotencyKey,
    required int clientSequence,
  }) async {
    submitCalls++;
    idempotencyKeys.add(idempotencyKey);
    clientSequences.add(clientSequence);
    if (throwFirstSubmit && submitCalls == 1) throw Exception('network');
    final pending = submitCompleter;
    if (pending != null) return pending.future;
    return OnlineAnswerReceipt(
      accepted: true,
      duplicate: submitCalls > 1,
      serverReceivedAt: DateTime.utc(2026, 8, 28, 12),
      reveal: AnswerReveal(
        questionId: matchQuestionId,
        correctOptionId: matchOptionId,
        answers: const [],
      ),
    );
  }

  @override
  Future<AnswerReveal?> reveal(String matchQuestionId) async {
    revealCalls++;
    return AnswerReveal(
      questionId: matchQuestionId,
      correctOptionId: 'option-4',
      answers: const [],
    );
  }

  @override
  Future<Map<String, Object?>> advance(String matchId) async => {
    'state': 'advanced',
  };
}
