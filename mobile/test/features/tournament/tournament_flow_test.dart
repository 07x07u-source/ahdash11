import 'package:ahdash_11/features/tournament/domain/tournament.dart';
import 'package:ahdash_11/features/tournament/domain/tournament_engine.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ready and incomplete completion never create redirect loops', () {
    final engine = _engine();
    final draft = _withTeams(
      engine,
      engine.create(
        name: 'كأس الحالة',
        organizerId: 'organizer',
        rules: const TournamentRules(capacity: 4),
      ),
    );
    final ready = TournamentState(
      active: draft.copyWith(status: TournamentStatus.ready),
      restored: true,
    );
    expect(TournamentFlowResolver.routeFor(ready), '/tournaments/draw');
    expect(
      TournamentFlowResolver.redirectFor(TournamentFlowStep.draw, ready),
      isNull,
    );
    final incomplete = TournamentState(
      active: engine
          .generateBracket(draft, randomSeed: 1)
          .copyWith(status: TournamentStatus.completed),
      restored: true,
    );
    expect(TournamentFlowResolver.routeFor(incomplete), '/tournaments/bracket');
    expect(
      TournamentFlowResolver.redirectFor(
        TournamentFlowStep.bracket,
        incomplete,
      ),
      isNull,
    );
    expect(
      TournamentFlowResolver.redirectFor(
        TournamentFlowStep.champion,
        incomplete,
      ),
      '/tournaments/bracket',
    );
  });
  test('canonical resolver follows actual tournament status', () {
    final engine = _engine();
    final empty = engine.create(
      name: 'كأس الاختبار',
      organizerId: 'organizer',
      rules: const TournamentRules(capacity: 4),
    );
    expect(
      TournamentFlowResolver.routeFor(
        TournamentState(active: empty, restored: true),
      ),
      '/tournaments/teams',
    );

    final ready = _withTeams(engine, empty);
    expect(
      TournamentFlowResolver.routeFor(
        TournamentState(active: ready, restored: true),
      ),
      '/tournaments/draw',
    );

    final live = engine.generateBracket(ready, randomSeed: 11);
    expect(
      TournamentFlowResolver.routeFor(
        TournamentState(active: live, restored: true),
      ),
      '/tournaments/bracket',
    );
    final playable = live.matches.firstWhere(
      (match) => match.status == TournamentMatchStatus.ready,
    );
    expect(
      TournamentFlowResolver.routeFor(
        TournamentState(
          active: live,
          restored: true,
          partyMatchId: playable.id,
        ),
      ),
      '/tournaments/match/${playable.id}',
    );
  });

  test('deep links reject stale or impossible tournament states', () {
    final engine = _engine();
    final draft = _withTeams(
      engine,
      engine.create(
        name: 'كأس الروابط',
        organizerId: 'organizer',
        rules: const TournamentRules(capacity: 4),
      ),
    );
    expect(
      TournamentFlowResolver.redirectFor(
        TournamentFlowStep.bracket,
        TournamentState(active: draft, restored: true),
      ),
      '/tournaments/draw',
    );

    final live = engine.generateBracket(draft, randomSeed: 9);
    expect(
      TournamentFlowResolver.redirectFor(
        TournamentFlowStep.match,
        TournamentState(active: live, restored: true),
        matchId: 'missing',
      ),
      '/tournaments/bracket',
    );
    final playable = live.matches.firstWhere(
      (match) => match.status == TournamentMatchStatus.ready,
    );
    expect(
      TournamentFlowResolver.redirectFor(
        TournamentFlowStep.match,
        TournamentState(active: live, restored: true),
        matchId: playable.id,
      ),
      isNull,
    );
  });

  test('completed tournament resolves to its real champion', () {
    final engine = _engine();
    var tournament = engine.generateBracket(
      _withTeams(
        engine,
        engine.create(
          name: 'كأس البطل',
          organizerId: 'organizer',
          rules: const TournamentRules(capacity: 4),
        ),
      ),
      randomSeed: 3,
    );
    while (tournament.status != TournamentStatus.completed) {
      final match = tournament.matches.firstWhere(
        (value) => value.status == TournamentMatchStatus.ready,
      );
      tournament = engine.confirmResult(
        tournament,
        matchId: match.id,
        scoreA: 2,
        scoreB: 1,
      );
    }
    expect(
      TournamentFlowResolver.routeFor(
        TournamentState(active: tournament, restored: true),
      ),
      '/tournaments/champion',
    );
  });
}

TournamentEngine _engine() {
  var next = 0;
  return TournamentEngine(idFactory: () => 'id-${next++}');
}

Tournament _withTeams(TournamentEngine engine, Tournament tournament) {
  var result = tournament;
  for (final name in ['الصقور', 'المدرج', 'التكتيك', 'الأساطير']) {
    result = engine.addTeam(result, name: name);
  }
  return result;
}
