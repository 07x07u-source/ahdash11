import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../domain/football_entities.dart';

final footballRepositoryProvider = Provider<FootballRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return FootballRepository(
    config.hasSupabase ? Supabase.instance.client : null,
  );
});

final footballLeaguesProvider = FutureProvider<List<FootballLeague>>((ref) {
  return ref.watch(footballRepositoryProvider).listLeagues();
});

class FootballRepository {
  const FootballRepository(this._client);

  final SupabaseClient? _client;

  bool get isAvailable => _client != null;

  Future<FootballPreferences> loadPreferences() async {
    final client = _client;
    if (client == null) return const FootballPreferences();
    final data = await client.rpc<Object?>('get_my_football_preferences');
    return FootballPreferences.fromJson(
      Map<String, Object?>.from(data! as Map<Object?, Object?>),
    );
  }

  Future<List<FootballLeague>> listLeagues() async {
    final client = _client;
    if (client == null) return const [];
    final data = await client.rpc<Object?>('list_football_leagues');
    return _rows(data).map(FootballLeague.fromJson).toList(growable: false);
  }

  Future<List<FootballClub>> searchClubs({
    String? query,
    String? leagueId,
  }) async {
    final client = _client;
    if (client == null) return const [];
    final data = await client.rpc<Object?>(
      'search_football_clubs',
      params: {
        'p_query': query?.trim(),
        'p_league_id': leagueId,
        'p_limit': 30,
        'p_offset': 0,
      },
    );
    return _rows(data).map(FootballClub.fromJson).toList(growable: false);
  }

  Future<void> savePreferences({
    String? leagueId,
    String? clubId,
    required bool showPublicly,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured');
    }
    await client.rpc<Object?>(
      'set_football_preferences',
      params: {
        'p_league_id': leagueId,
        'p_club_id': clubId,
        'p_show_publicly': showPublicly,
      },
    );
  }

  static List<Map<String, Object?>> _rows(Object? value) =>
      (value as List? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(Map<String, Object?>.from)
          .toList(growable: false);
}
