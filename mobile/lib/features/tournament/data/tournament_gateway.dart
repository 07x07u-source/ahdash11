import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/tournament.dart';

final tournamentGatewayProvider = Provider<TournamentGateway>(
  (ref) => const SupabaseTournamentGateway(),
);

abstract interface class TournamentGateway {
  Future<String?> tournamentIdForMatch(String matchId);
  Future<Tournament?> loadTournament(String tournamentId);
  Future<String?> createTournament(Tournament tournament);

  Future<void> saveBracket(Tournament tournament);

  Future<void> confirmResult({
    required String tournamentId,
    required TournamentMatch match,
  });
}

final class SupabaseTournamentGateway implements TournamentGateway {
  const SupabaseTournamentGateway();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<String?> tournamentIdForMatch(String matchId) async {
    final row = await _client
        .from('tournament_matches')
        .select('tournament_id')
        .eq('id', matchId)
        .maybeSingle()
        .timeout(const Duration(seconds: 8));
    return row?['tournament_id'] as String?;
  }

  @override
  Future<Tournament?> loadTournament(String tournamentId) async {
    final row = await _client
        .from('tournaments')
        .select(
          '*,teams:tournament_teams!tournament_teams_tournament_id_fkey(*,roster:tournament_players(*)),matches:tournament_matches!tournament_matches_tournament_id_fkey(*)',
        )
        .eq('id', tournamentId)
        .maybeSingle()
        .timeout(const Duration(seconds: 8));
    return row == null ? null : tournamentFromServer(row);
  }

  @override
  Future<String?> createTournament(Tournament tournament) async {
    await _client
        .rpc<Object?>(
          'create_tournament',
          params: {
            'p_client_id': tournament.id,
            'p_name': tournament.name,
            'p_rules': tournament.rules.toJson(),
          },
        )
        .timeout(const Duration(seconds: 8));
    final row = await _client
        .from('tournaments')
        .select('invite_code')
        .eq('id', tournament.id)
        .single()
        .timeout(const Duration(seconds: 8));
    return row['invite_code'] as String?;
  }

  @override
  Future<void> saveBracket(Tournament tournament) async {
    // Deliberately never fall back to save_tournament_bracket. The v1 RPC
    // deletes tournament_players and is revoked by the Phase 5 migration.
    await _client
        .rpc<Object?>(
          'save_tournament_bracket_v2',
          params: {
            'p_tournament_id': tournament.id,
            'p_teams': tournament.teams
                .where((team) => team.approved)
                .map((value) => value.toJson())
                .toList(growable: false),
            'p_matches': tournament.matches
                .map((value) => value.toJson())
                .toList(growable: false),
          },
        )
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> confirmResult({
    required String tournamentId,
    required TournamentMatch match,
  }) async {
    await _client
        .rpc<Object?>(
          'confirm_tournament_match_result_v2',
          params: {
            'p_tournament_id': tournamentId,
            'p_match_id': match.id,
            'p_score_a': match.scoreA,
            'p_score_b': match.scoreB,
            'p_winner_team_id': match.winnerId,
            'p_party_session_id': match.partySessionId,
          },
        )
        .timeout(const Duration(seconds: 8));
  }
}

/// Keeps database identity and roster metadata intact when hydrating the cache.
Tournament tournamentFromServer(Map<String, Object?> row) =>
    Tournament.fromJson({
      ...row,
      'rules': {
        for (final key in [
          'capacity',
          'players_per_team',
          'visibility',
          'seeding',
          'category_ids',
          'timer_seconds',
          'helpers_enabled',
          'tiebreaker_enabled',
        ])
          key: row[key],
      },
      'teams': (row['teams'] as List? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(
            (team) => {
              ...team,
              'approved': team['status'] == 'approved',
              'registration_status': team['status'],
              'players': (team['roster'] as List? ?? const [])
                  .whereType<Map<Object?, Object?>>()
                  .map((player) => player['display_name'])
                  .whereType<String>()
                  .toList(),
            },
          )
          .toList(),
      'matches': (row['matches'] as List? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(
            (match) => {
              ...match,
              'round': match['round_number'],
              'winner_id': match['winner_team_id'],
            },
          )
          .toList(),
    });
