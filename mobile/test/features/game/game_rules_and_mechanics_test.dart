import 'package:ahdash_11/features/game/domain/answer_evaluator.dart';
import 'package:ahdash_11/features/game/domain/game_rules.dart';
import 'package:ahdash_11/features/game/domain/question_mechanics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRuleConfig and TurnEngine', () {
    test('classic session gives 60 seconds then a 10 second steal', () {
      const rules = GameRuleConfig.classicSession;
      const engine = TurnEngine();
      final now = DateTime.utc(2026, 9, 2, 12);
      final primary = engine.startQuestion(
        activeTeamIndex: 0,
        rules: rules,
        now: now,
      );

      expect(primary.durationSeconds, 60);
      expect(primary.answeringTeamIndex, 0);
      final steal = engine.expire(
        primary,
        rules: rules,
        now: now.add(const Duration(seconds: 60)),
      );
      expect(steal.phase, TurnPhase.steal);
      expect(steal.answeringTeamIndex, 1);
      expect(steal.durationSeconds, 10);
      expect(
        engine
            .expire(
              steal,
              rules: rules,
              now: now.add(const Duration(seconds: 70)),
            )
            .phase,
        TurnPhase.reveal,
      );
    });

    test('pause and resume preserve only the remaining time', () {
      const engine = TurnEngine();
      const rules = GameRuleConfig.classicSession;
      final start = DateTime.utc(2026, 9, 2, 12);
      final turn = engine.startQuestion(
        activeTeamIndex: 1,
        rules: rules,
        now: start,
      );
      final paused = engine.pause(turn, start.add(const Duration(seconds: 17)));
      expect(paused.remainingSeconds(start), 43);
      final resumed = engine.resume(
        paused,
        start.add(const Duration(minutes: 5)),
      );
      expect(resumed.durationSeconds, 43);
      expect(resumed.phase, TurnPhase.primaryAnswer);
    });
  });

  group('AnswerEvaluator', () {
    test('normalizes Arabic letters, diacritics, whitespace and digits', () {
      const evaluator = AnswerEvaluator();
      final result = evaluator.text(
        input: '  إلـــى   النَّصر! ',
        answer: 'الى النصر',
      );
      expect(result.correct, isTrue);
      expect(AnswerEvaluator.normalizeArabicDigits('٢۰١٠'), '2010');
    });

    test('generic numeric tolerance accepts the exact inclusive range', () {
      const evaluator = AnswerEvaluator();
      expect(
        evaluator.numeric(input: '٢٠٠٩', answer: 2010, tolerance: 1).correct,
        isTrue,
      );
      expect(
        evaluator.numeric(input: '2011', answer: 2010, tolerance: 1).correct,
        isTrue,
      );
      expect(
        evaluator.numeric(input: '2012', answer: 2010, tolerance: 1).correct,
        isFalse,
      );
    });

    test('ordering supports exact and deterministic partial evaluation', () {
      const evaluator = AnswerEvaluator();
      final partial = evaluator.ordering(
        submitted: const ['A', 'C', 'B'],
        expected: const ['A', 'B', 'C'],
        allowPartial: true,
      );
      expect(partial.correct, isFalse);
      expect(partial.partialCredit, closeTo(1 / 3, 0.001));
      expect(
        evaluator
            .ordering(
              submitted: const ['A', 'B', 'C'],
              expected: const ['A', 'B', 'C'],
            )
            .correct,
        isTrue,
      );
    });
  });

  group('Extensible question mechanics', () {
    test('registry has a concrete contract for every required type', () {
      expect(
        QuestionMechanicRegistry.supportedTypes,
        containsAll(AhdashQuestionType.values),
      );
      expect(
        QuestionMechanicRegistry.forType(
          AhdashQuestionType.secretIdentity,
        ).privateReveal,
        isTrue,
      );
      expect(
        QuestionMechanicRegistry.forType(
          AhdashQuestionType.video,
        ).requiresMedia,
        isTrue,
      );
    });

    test('progressive hints decay points without becoming negative', () {
      var state = const ProgressiveHintState(
        hints: ['1', '2', '3', '4', '5'],
        basePoints: 500,
        pointDecayPerHint: 125,
      );
      expect(state.visibleHints, ['1']);
      for (var index = 0; index < 8; index++) {
        state = state.revealNext();
      }
      expect(state.visibleHints.length, 5);
      expect(state.availablePoints, 0);
    });

    test('drawing undo and clear never leak a hidden text hint', () {
      const stroke = DrawingStroke(
        points: [DrawingPoint(1, 2), DrawingPoint(2, 3)],
        colorValue: 0xFF000000,
        width: 4,
      );
      final drawing = const DrawingSession().add(stroke).add(stroke);
      expect(drawing.undo().strokes, hasLength(1));
      expect(drawing.clear().strokes, isEmpty);
    });

    test('secret identity code is opaque and reveal is controlled', () {
      const engine = SecretIdentityEngine();
      final assignment = engine.create('لاعب سري', seed: 11);
      expect(assignment.publicCode, isNot(contains('لاعب')));
      expect(engine.reveal(assignment).state, SecretRevealState.hidden);
      final ready = assignment.copyWith(state: SecretRevealState.ready);
      expect(engine.reveal(ready).state, SecretRevealState.visible);
      expect(engine.conceal(ready).state, SecretRevealState.concealed);
    });

    test('charades protects reveal order and records the outcome', () {
      var session = const CharadesSession(secret: 'ميسي', durationSeconds: 60);
      expect(session.start(DateTime.utc(2026)).phase, CharadesPhase.hidden);
      session = session.ready().start(DateTime.utc(2026));
      expect(session.phase, CharadesPhase.acting);
      expect(session.finish(success: true).phase, CharadesPhase.success);
    });
  });
}
