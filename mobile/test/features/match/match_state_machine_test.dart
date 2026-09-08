import 'package:ahdash_11/features/match/domain/match_state_machine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts the canonical match lifecycle', () {
    final machine = MatchStateMachine();
    for (final phase in [
      MatchPhase.lobby,
      MatchPhase.ready,
      MatchPhase.countdown,
      MatchPhase.question,
      MatchPhase.answersLocked,
      MatchPhase.result,
      MatchPhase.nextQuestion,
      MatchPhase.question,
      MatchPhase.answersLocked,
      MatchPhase.result,
      MatchPhase.finished,
    ]) {
      machine.transitionTo(phase);
    }
    expect(machine.phase, MatchPhase.finished);
  });

  test('restores the authoritative phase after reconnect', () {
    final machine = MatchStateMachine(initial: MatchPhase.question)
      ..disconnected();
    expect(machine.phase, MatchPhase.reconnecting);

    machine.reconnected(authoritativePhase: MatchPhase.answersLocked);
    expect(machine.phase, MatchPhase.answersLocked);
  });

  test('rejects skipping phases', () {
    final machine = MatchStateMachine();
    expect(
      () => machine.transitionTo(MatchPhase.question),
      throwsA(isA<InvalidMatchTransition>()),
    );
  });
}
