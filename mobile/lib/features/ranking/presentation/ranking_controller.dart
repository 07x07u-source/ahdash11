import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../domain/leaderboard_entry.dart';

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final config = ref.watch(appConfigProvider);
  if (config.hasSupabase) {
    final client = Supabase.instance.client;
    final response = await client
        .from('leaderboard')
        .select('rank,user_id,username,rating,tier,avatar_url')
        .order('rank')
        .limit(100);
    final entries = response
        .whereType<Map<String, Object?>>()
        .map(LeaderboardEntry.fromJson)
        .toList();
    final userId = client.auth.currentUser?.id;
    if (userId != null && entries.every((entry) => entry.userId != userId)) {
      final current = await client
          .from('leaderboard')
          .select('rank,user_id,username,rating,tier,avatar_url')
          .eq('user_id', userId)
          .maybeSingle();
      if (current != null) entries.add(LeaderboardEntry.fromJson(current));
    }
    return entries;
  }
  // Missing backend means unavailable data, never illustrative production rows.
  return const [];
});
