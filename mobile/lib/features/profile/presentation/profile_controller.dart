import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/player_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(appConfigProvider).hasSupabase ? Supabase.instance.client : null,
  );
});

/// No durable profile cache. Authentication changes invalidate this provider.
final playerProfileProvider = FutureProvider<PlayerProfile>((ref) async {
  final auth = await ref.watch(authControllerProvider.future);
  if (auth == null || auth.isGuest) throw const ProfileUnavailable();
  final profile = await ref.watch(profileRepositoryProvider).load();
  if (profile.id != auth.id) throw const ProfileUnavailable();
  return profile;
});

final class ProfileUnavailable implements Exception {
  const ProfileUnavailable();
}

class ProfileRepository {
  const ProfileRepository(this.client);
  final SupabaseClient? client;

  Future<PlayerProfile> load() async {
    final remote = client;
    if (remote == null) throw const ProfileUnavailable();
    final data = await remote.rpc<Object?>('get_my_profile_summary');
    if (data is! Map) throw const FormatException('Invalid profile payload');
    final merged = Map<String, Object?>.from(data);
    try {
      final stats = await remote.rpc<Object?>('get_my_tournament_stats');
      if (stats is Map) merged.addAll(Map<String, Object?>.from(stats));
    } on Object {
      // Unavailable additive stats are omitted, never represented as zero.
    }
    if (merged['correct_answers'] is num && merged['wrong_answers'] is num) {
      merged['questions_answered'] =
          (merged['correct_answers'] as num).toInt() +
          (merged['wrong_answers'] as num).toInt();
    }
    return PlayerProfile.fromJson(merged);
  }
}
