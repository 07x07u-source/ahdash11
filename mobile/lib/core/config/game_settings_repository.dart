import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/domain/game_settings.dart';
import 'app_config.dart';

final gameSettingsProvider = FutureProvider<GameSettings>((ref) async {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase) return const GameSettings();
  try {
    final response = await Supabase.instance.client
        .from('game_settings')
        .select('key,value')
        .inFilter('key', [
          'match.default_question_count',
          'match.question_duration_ms',
          'scoring.base_score',
          'scoring.max_speed_bonus',
          'questions.difficulty_min_sample',
        ]);
    final values = <String, Object?>{};
    for (final row in response.whereType<Map<String, Object?>>()) {
      final key = row['key']! as String;
      final value = row['value'];
      switch (key) {
        case 'match.default_question_count':
          values['default_question_count'] = value;
        case 'match.question_duration_ms':
          if (value is num) {
            values['question_time_seconds'] = (value / 1000).round();
          }
        case 'scoring.base_score':
          values['base_score'] = value;
        case 'scoring.max_speed_bonus':
          values['max_speed_bonus'] = value;
        case 'questions.difficulty_min_sample':
          values['difficulty_sample_size'] = value;
      }
    }
    return GameSettings.fromJson(values);
  } catch (_) {
    return const GameSettings();
  }
});
