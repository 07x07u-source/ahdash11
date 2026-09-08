// ignore_for_file: sort_constructors_first

/// Immutable source identity. Display names are never used to attach a result.
final class PartyTournamentContext {
  const PartyTournamentContext({
    required this.tournamentId,
    required this.matchId,
    required this.teamAId,
    required this.teamBId,
    this.tiebreakerEnabled = true,
    this.fixedCategoryIds = const [],
  });

  final String tournamentId;
  final String matchId;
  final String teamAId;
  final String teamBId;
  final bool tiebreakerEnabled;
  final List<String> fixedCategoryIds;

  bool sameMatch(PartyTournamentContext? other) =>
      other != null &&
      tournamentId == other.tournamentId &&
      matchId == other.matchId &&
      teamAId == other.teamAId &&
      teamBId == other.teamBId;

  Map<String, Object?> toJson() => {
    'tournament_id': tournamentId,
    'match_id': matchId,
    'team_a_id': teamAId,
    'team_b_id': teamBId,
    'tiebreaker_enabled': tiebreakerEnabled,
    'fixed_category_ids': fixedCategoryIds,
  };

  factory PartyTournamentContext.fromJson(Map<String, Object?> json) =>
      PartyTournamentContext(
        tournamentId: json['tournament_id'] as String,
        matchId: json['match_id'] as String,
        teamAId: json['team_a_id'] as String,
        teamBId: json['team_b_id'] as String,
        tiebreakerEnabled: json['tiebreaker_enabled'] as bool? ?? true,
        fixedCategoryIds: (json['fixed_category_ids'] as List? ?? const [])
            .whereType<String>()
            .toList(),
      );
}
