enum MatchPhase {
  created,
  lobby,
  ready,
  countdown,
  question,
  answersLocked,
  result,
  nextQuestion,
  reconnecting,
  finished,
}

final class InvalidMatchTransition implements Exception {
  const InvalidMatchTransition(this.from, this.to);

  final MatchPhase from;
  final MatchPhase to;

  @override
  String toString() => 'Invalid match transition: ${from.name} -> ${to.name}';
}

final class MatchStateMachine {
  MatchStateMachine({MatchPhase initial = MatchPhase.created})
    : _phase = initial;

  static const _allowed = <MatchPhase, Set<MatchPhase>>{
    MatchPhase.created: {MatchPhase.lobby},
    MatchPhase.lobby: {MatchPhase.ready, MatchPhase.reconnecting},
    MatchPhase.ready: {MatchPhase.countdown, MatchPhase.reconnecting},
    MatchPhase.countdown: {MatchPhase.question, MatchPhase.reconnecting},
    MatchPhase.question: {MatchPhase.answersLocked, MatchPhase.reconnecting},
    MatchPhase.answersLocked: {MatchPhase.result, MatchPhase.reconnecting},
    MatchPhase.result: {
      MatchPhase.nextQuestion,
      MatchPhase.finished,
      MatchPhase.reconnecting,
    },
    MatchPhase.nextQuestion: {MatchPhase.question, MatchPhase.finished},
    MatchPhase.reconnecting: {
      MatchPhase.lobby,
      MatchPhase.ready,
      MatchPhase.countdown,
      MatchPhase.question,
      MatchPhase.answersLocked,
      MatchPhase.result,
      MatchPhase.nextQuestion,
      MatchPhase.finished,
    },
    MatchPhase.finished: {},
  };

  MatchPhase _phase;
  MatchPhase? _beforeReconnect;

  MatchPhase get phase => _phase;

  bool canTransitionTo(MatchPhase next) => _allowed[_phase]!.contains(next);

  void transitionTo(MatchPhase next) {
    if (!canTransitionTo(next)) throw InvalidMatchTransition(_phase, next);
    _phase = next;
  }

  void disconnected() {
    if (_phase == MatchPhase.finished || _phase == MatchPhase.reconnecting) {
      return;
    }
    _beforeReconnect = _phase;
    transitionTo(MatchPhase.reconnecting);
  }

  void reconnected({MatchPhase? authoritativePhase}) {
    if (_phase != MatchPhase.reconnecting) {
      throw InvalidMatchTransition(_phase, authoritativePhase ?? _phase);
    }
    final destination = authoritativePhase ?? _beforeReconnect;
    if (destination == null) throw StateError('No phase available to restore');
    transitionTo(destination);
    _beforeReconnect = null;
  }
}
