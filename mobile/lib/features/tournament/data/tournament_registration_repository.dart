import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

final tournamentRegistrationRepositoryProvider =
    Provider<TournamentRegistrationRepository>((ref) {
      final configured = ref.watch(appConfigProvider).hasSupabase;
      return TournamentRegistrationRepository(
        configured ? Supabase.instance.client : null,
      );
    });

final availableTournamentsProvider = FutureProvider<List<AvailableTournament>>((
  ref,
) {
  return ref.watch(tournamentRegistrationRepositoryProvider).available();
});

final pendingTournamentRegistrationsProvider =
    FutureProvider.family<List<TournamentRegistrationRequest>, String>((
      ref,
      tournamentId,
    ) {
      return ref
          .watch(tournamentRegistrationRepositoryProvider)
          .pendingRegistrations(tournamentId);
    });

final class AvailableTournament {
  const AvailableTournament({
    required this.id,
    required this.name,
    required this.capacity,
    required this.playersPerTeam,
    required this.inviteCode,
    required this.createdAt,
  });

  factory AvailableTournament.fromJson(Map<String, Object?> json) =>
      AvailableTournament(
        id: '${json['id']}',
        name: '${json['name'] ?? 'بطولة أحدعش'}',
        capacity: (json['capacity'] as num?)?.toInt() ?? 8,
        playersPerTeam: (json['players_per_team'] as num?)?.toInt() ?? 1,
        inviteCode: json['invite_code'] as String?,
        createdAt: DateTime.tryParse('${json['created_at']}'),
      );

  final String id;
  final String name;
  final int capacity;
  final int playersPerTeam;
  final String? inviteCode;
  final DateTime? createdAt;
}

final class TournamentRegistrationRequest {
  const TournamentRegistrationRequest({
    required this.id,
    required this.teamName,
    required this.roster,
    required this.createdAt,
  });

  factory TournamentRegistrationRequest.fromJson(Map<String, Object?> json) =>
      TournamentRegistrationRequest(
        id: '${json['id']}',
        teamName: '${json['team_name'] ?? 'فريق'}',
        roster: (json['roster'] as List? ?? const [])
            .whereType<Map<Object?, Object?>>()
            .map(Map<String, Object?>.from)
            .toList(growable: false),
        createdAt: DateTime.tryParse('${json['created_at']}'),
      );

  final String id;
  final String teamName;
  final List<Map<String, Object?>> roster;
  final DateTime? createdAt;

  List<String> get playerNames => roster
      .map((player) => '${player['display_name'] ?? ''}'.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
}

final class TournamentRegistrationRepository {
  const TournamentRegistrationRepository(this._client);

  final SupabaseClient? _client;

  bool get isAvailable => _client != null;

  SupabaseClient get _requiredClient =>
      _client ?? (throw StateError('Supabase is not configured'));

  Future<List<AvailableTournament>> available() async {
    if (_client == null || _client.auth.currentUser == null) return const [];
    final rows = await _requiredClient
        .from('tournaments')
        .select('id,name,capacity,players_per_team,invite_code,created_at')
        .eq('visibility', 'public')
        .eq('status', 'registration')
        .order('created_at', ascending: false)
        .limit(30);
    return rows
        .map((row) => AvailableTournament.fromJson(row))
        .toList(growable: false);
  }

  Future<String> register({
    required String inviteCode,
    required String teamName,
    required List<Map<String, Object?>> roster,
  }) async {
    final result = await _requiredClient.rpc<Object?>(
      'register_tournament_team',
      params: {
        'p_invite_code': inviteCode.trim().toUpperCase(),
        'p_team_name': teamName.trim(),
        'p_roster': roster,
      },
    );
    return '$result';
  }

  Future<List<TournamentRegistrationRequest>> pendingRegistrations(
    String tournamentId,
  ) async {
    if (_client == null || _client.auth.currentUser == null) return const [];
    final rows = await _requiredClient
        .from('tournament_registrations')
        .select('id,team_name,roster,created_at')
        .eq('tournament_id', tournamentId)
        .eq('status', 'pending')
        .order('created_at');
    return rows
        .map((row) => TournamentRegistrationRequest.fromJson(row))
        .toList(growable: false);
  }

  Future<String?> review({
    required String registrationId,
    required bool approve,
  }) async {
    final result = await _requiredClient.rpc<Object?>(
      'review_tournament_registration',
      params: {'p_registration_id': registrationId, 'p_approve': approve},
    );
    return result?.toString();
  }
}
