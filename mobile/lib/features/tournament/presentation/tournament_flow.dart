import '../../party/presentation/party_game_controller.dart';
import '../../party/presentation/party_setup_flow.dart';
import '../domain/tournament.dart';
import 'tournament_controller.dart';

enum TournamentFlowStep { hub, create, teams, draw, bracket, match, champion }

abstract final class TournamentFlowResolver {
  static TournamentMatch? currentMatch(Tournament tournament) {
    final matches =
        tournament.matches
            .where(
              (match) =>
                  match.hasBothTeams &&
                  (match.status == TournamentMatchStatus.ready ||
                      match.status == TournamentMatchStatus.live),
            )
            .toList()
          ..sort(
            (a, b) => a.round == b.round
                ? a.position.compareTo(b.position)
                : a.round.compareTo(b.round),
          );
    return matches.firstOrNull;
  }

  static int currentRound(Tournament tournament) =>
      currentMatch(tournament)?.round ?? tournament.finalMatch?.round ?? 1;

  static bool hasPartyResult(
    Tournament tournament,
    TournamentMatch match,
    PartyGameState party,
  ) {
    final session = party.session;
    final context = session?.tournamentContext;
    return session != null &&
        session.isComplete &&
        session.scores[0] != session.scores[1] &&
        context?.tournamentId == tournament.id &&
        context?.matchId == match.id &&
        context?.teamAId == match.teamAId &&
        context?.teamBId == match.teamBId;
  }

  static String routeFor(
    TournamentState state, {
    String? requestedMatchId,
    PartyGameState? party,
  }) {
    final tournament = state.active;
    if (tournament == null || tournament.status == TournamentStatus.cancelled) {
      return '/tournaments';
    }
    if (tournament.status == TournamentStatus.completed) {
      return tournament.hasConfirmedChampion
          ? '/tournaments/champion'
          : tournament.matches.isEmpty
          ? '/tournaments'
          : '/tournaments/bracket';
    }
    if (tournament.status == TournamentStatus.live) {
      final matchId = requestedMatchId ?? state.partyMatchId;
      final match = _playableMatch(tournament, matchId);
      if (match != null &&
          party != null &&
          party.tournamentContext?.tournamentId == tournament.id &&
          party.tournamentContext?.matchId == match.id &&
          !hasPartyResult(tournament, match, party)) {
        return PartySetupFlowResolver.canonicalRoute(party);
      }
      return match == null
          ? '/tournaments/bracket'
          : '/tournaments/match/${match.id}';
    }
    if (!tournament.canDraw) {
      return '/tournaments/teams';
    }
    return '/tournaments/draw';
  }

  static String? redirectFor(
    TournamentFlowStep requested,
    TournamentState state, {
    String? matchId,
  }) {
    if (requested == TournamentFlowStep.hub ||
        requested == TournamentFlowStep.create) {
      return null;
    }
    final tournament = state.active;
    final canonical = routeFor(state, requestedMatchId: matchId);
    final allowed = switch (requested) {
      TournamentFlowStep.teams =>
        tournament != null && tournament.status != TournamentStatus.cancelled,
      TournamentFlowStep.draw => tournament != null && tournament.canDraw,
      TournamentFlowStep.bracket =>
        tournament != null &&
            (tournament.status == TournamentStatus.live ||
                tournament.status == TournamentStatus.completed) &&
            tournament.matches.isNotEmpty,
      TournamentFlowStep.match =>
        tournament != null &&
            tournament.matches.any((match) => match.id == matchId),
      TournamentFlowStep.champion =>
        tournament != null && tournament.hasConfirmedChampion,
      TournamentFlowStep.hub || TournamentFlowStep.create => true,
    };
    if (allowed) return null;
    return canonical;
  }

  static TournamentMatch? _playableMatch(
    Tournament tournament,
    String? matchId,
  ) {
    if (matchId == null) return null;
    return tournament.matches
        .where(
          (match) =>
              match.id == matchId &&
              match.hasBothTeams &&
              (match.status == TournamentMatchStatus.ready ||
                  match.status == TournamentMatchStatus.live),
        )
        .firstOrNull;
  }
}
