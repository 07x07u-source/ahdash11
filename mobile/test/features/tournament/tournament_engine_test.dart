import 'package:ahdash_11/features/tournament/domain/tournament.dart';
import 'package:ahdash_11/features/tournament/domain/tournament_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int id;
  late TournamentEngine engine;

  setUp(() {
    id = 0;
    engine = TournamentEngine(idFactory: () => 'id-${id++}');
  });

  Tournament draft({int capacity = 8, int teams = 5}) {
    var result = engine.create(
      name: 'كأس أحدعش',
      organizerId: 'organizer',
      rules: TournamentRules(capacity: capacity),
      now: DateTime.utc(2026, 8, 31),
    );
    for (var index = 0; index < teams; index++) {
      result = engine.addTeam(
        result,
        name: 'الفريق ${index + 1}',
        players: ['اللاعب ${index + 1}'],
      );
    }
    return result;
  }

  test('sparse capacity 64 has one real final and empty bye branches', () {
    final result = engine.generateBracket(
      draft(capacity: 64, teams: 2),
      randomSeed: 11,
    );
    expect(result.matches, hasLength(63));
    expect(
      result.matches.where((m) => m.status == TournamentMatchStatus.ready),
      hasLength(1),
    );
    expect(result.finalMatch!.hasBothTeams, isTrue);
    expect(result.status, TournamentStatus.live);
  });

  test(
    'score winner mismatch cannot advance and exact confirmation is idempotent',
    () {
      final result = engine.generateBracket(
        draft(capacity: 4, teams: 4),
        randomSeed: 11,
      );
      final match = result.matches.first;
      expect(
        () => engine.confirmResult(
          result,
          matchId: match.id,
          scoreA: 2,
          scoreB: 1,
          winnerId: match.teamBId,
        ),
        throwsA(isA<TournamentRuleException>()),
      );
      final confirmed = engine.confirmResult(
        result,
        matchId: match.id,
        scoreA: 2,
        scoreB: 1,
      );
      expect(
        identical(
          engine.confirmResult(
            confirmed,
            matchId: match.id,
            scoreA: 2,
            scoreB: 1,
          ),
          confirmed,
        ),
        isTrue,
      );
      expect(
        () => engine.generateBracket(confirmed),
        throwsA(isA<TournamentRuleException>()),
      );
    },
  );

  test('draw preserves non-eligible identities and roster metadata', () {
    var result = draft(capacity: 4, teams: 3);
    final original = result.teams.first;
    final team = TournamentTeam(
      id: original.id,
      name: original.name,
      players: original.players,
      ownerUserId: 'owner',
      roster: const [
        {'id': 'player-id', 'is_captain': true, 'user_id': 'member-id'},
      ],
    );
    result = result.copyWith(
      teams: [team, result.teams[1], result.teams[2].copyWith(approved: false)],
    );
    final drawn = engine.generateBracket(result, randomSeed: 11);
    expect(drawn.teams, hasLength(3));
    expect(drawn.team(team.id)!.roster, team.roster);
    expect(drawn.team(team.id)!.ownerUserId, 'owner');
    final participants = drawn.matches
        .where((m) => m.round == 1)
        .expand((m) => [m.teamAId, m.teamBId])
        .whereType<String>()
        .toList();
    expect(participants.toSet().length, 2);
    expect(participants, hasLength(2));
  });

  test('creates the complete match graph for every supported capacity', () {
    for (final capacity in [4, 8, 16, 32, 64]) {
      final tournament = engine.generateBracket(
        draft(capacity: capacity, teams: capacity),
        randomSeed: 11,
      );
      expect(tournament.matches, hasLength(capacity - 1));
      expect(
        tournament.matches.where((match) => match.round == 1),
        hasLength(capacity ~/ 2),
      );
      expect(tournament.matches.last.nextMatchId, isNull);
      expect(
        tournament.matches
            .where((match) => match.round == 1)
            .every((match) => match.status == TournamentMatchStatus.ready),
        isTrue,
      );
    }
  });

  test('distributes and advances byes without user confirmation', () {
    final tournament = engine.generateBracket(
      draft(capacity: 8, teams: 5),
      randomSeed: 11,
    );
    expect(
      tournament.matches.where(
        (match) => match.status == TournamentMatchStatus.bye,
      ),
      hasLength(3),
    );
    expect(
      tournament.matches.where(
        (match) => match.round == 2 && match.hasBothTeams,
      ),
      isNotEmpty,
    );
    expect(tournament.status, TournamentStatus.live);
  });

  test('requires a tiebreak winner for equal scores', () {
    final tournament = engine.generateBracket(
      draft(capacity: 4, teams: 4),
      randomSeed: 11,
    );
    final match = tournament.matches.first;
    expect(
      () => engine.confirmResult(
        tournament,
        matchId: match.id,
        scoreA: 300,
        scoreB: 300,
      ),
      throwsA(isA<TournamentRuleException>()),
    );
    final resolved = engine.confirmResult(
      tournament,
      matchId: match.id,
      scoreA: 300,
      scoreB: 300,
      winnerId: match.teamAId,
    );
    expect(resolved.matches.first.winnerId, match.teamAId);
  });

  test('advances winners and completes with a champion', () {
    var tournament = engine.generateBracket(
      draft(capacity: 4, teams: 4),
      randomSeed: 11,
    );
    for (final semifinal
        in tournament.matches.where((match) => match.round == 1).toList()) {
      tournament = engine.confirmResult(
        tournament,
        matchId: semifinal.id,
        scoreA: 400,
        scoreB: 200,
      );
    }
    final finalMatch = tournament.matches.singleWhere(
      (match) => match.round == 2,
    );
    expect(finalMatch.status, TournamentMatchStatus.ready);
    tournament = engine.confirmResult(
      tournament,
      matchId: finalMatch.id,
      scoreA: 500,
      scoreB: 300,
    );
    expect(tournament.status, TournamentStatus.completed);
    expect(tournament.championTeamId, finalMatch.teamAId);
  });

  test(
    'allows safe undo but blocks it after the dependent match completes',
    () {
      var tournament = engine.generateBracket(
        draft(capacity: 4, teams: 4),
        randomSeed: 11,
      );
      final semifinals = tournament.matches
          .where((match) => match.round == 1)
          .toList();
      tournament = engine.confirmResult(
        tournament,
        matchId: semifinals.first.id,
        scoreA: 1,
        scoreB: 0,
      );
      final restored = engine.undoResult(tournament, semifinals.first.id);
      expect(restored.matches.first.status, TournamentMatchStatus.ready);
      expect(restored.matches.last.teamAId, isNull);

      tournament = engine.generateBracket(
        draft(capacity: 4, teams: 4),
        randomSeed: 11,
      );
      final lockedSemifinals = tournament.matches
          .where((match) => match.round == 1)
          .toList();
      for (final semifinal in lockedSemifinals) {
        tournament = engine.confirmResult(
          tournament,
          matchId: semifinal.id,
          scoreA: 1,
          scoreB: 0,
        );
      }
      final finalMatch = tournament.matches.last;
      tournament = engine.confirmResult(
        tournament,
        matchId: finalMatch.id,
        scoreA: 1,
        scoreB: 0,
      );
      expect(
        () => engine.undoResult(tournament, lockedSemifinals.first.id),
        throwsA(isA<TournamentRuleException>()),
      );
    },
  );

  test('round-trips the full resumable snapshot', () {
    final tournament = engine.generateBracket(
      draft(capacity: 8, teams: 6),
      randomSeed: 11,
    );
    final restored = Tournament.decode(tournament.encode());
    expect(restored.id, tournament.id);
    expect(restored.rules.capacity, 8);
    expect(
      restored.teams.map((team) => team.name),
      tournament.teams.map((team) => team.name),
    );
    expect(
      restored.matches.map((match) => match.toJson()),
      tournament.matches.map((match) => match.toJson()),
    );
  });

  test('rejects duplicate names and duplicate players', () {
    final tournament = draft(capacity: 4, teams: 1);
    expect(
      () => engine.addTeam(tournament, name: tournament.teams.first.name),
      throwsA(isA<TournamentRuleException>()),
    );
    expect(
      () => engine.addTeam(
        tournament,
        name: 'فريق جديد',
        players: tournament.teams.first.players,
      ),
      throwsA(isA<TournamentRuleException>()),
    );
  });
}
