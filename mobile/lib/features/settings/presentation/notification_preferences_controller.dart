import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../auth/presentation/auth_controller.dart';

Map<String, bool> mergeNotificationPreferences(Map<String, Object?> row) => {
  for (final key in NotificationPreferencesController.defaults.keys)
    key: row[key] as bool? ?? NotificationPreferencesController.defaults[key]!,
};

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>(
      (ref) => NotificationPreferencesRepository(
        ref.watch(appConfigProvider).hasSupabase
            ? Supabase.instance.client
            : null,
      ),
    );

class NotificationPreferencesRepository {
  const NotificationPreferencesRepository(this.client);
  final SupabaseClient? client;
  Future<Map<String, bool>> load(String account) async {
    if (client == null) throw StateError('Unavailable');
    final row = await client!
        .from('notification_preferences')
        .select(NotificationPreferencesController.defaults.keys.join(','))
        .eq('user_id', account)
        .single();
    return mergeNotificationPreferences(row);
  }

  Future<void> save(String account, String key, bool value) async {
    if (client == null || client!.auth.currentUser?.id != account) {
      throw StateError('Unavailable');
    }
    await client!
        .from('notification_preferences')
        .update({key: value})
        .eq('user_id', account)
        .select('user_id')
        .single();
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferencesController, Map<String, bool>>(
      NotificationPreferencesController.new,
    );

final class NotificationPreferencesController
    extends AsyncNotifier<Map<String, bool>> {
  static const defaults = <String, bool>{
    'friend_requests': true,
    'match_invites': true,
    'challenges': true,
    'rewards': true,
    'season_events': true,
    'announcements': true,
    'teams': true,
    'promotions': false,
  };
  bool _saving = false;
  int _epoch = 0;
  @override
  Future<Map<String, bool>> build() async {
    _epoch++;
    _saving = false;
    final user = await ref.watch(authControllerProvider.future);
    if (user == null || user.isGuest) throw StateError('Unavailable');
    return ref.watch(notificationPreferencesRepositoryProvider).load(user.id);
  }

  Future<void> setPreference(String key, bool value) async {
    if (!defaults.containsKey(key) || _saving) return;
    final previous = state.asData?.value;
    final user = ref.read(authControllerProvider).asData?.value;
    if (previous == null || user == null || user.isGuest) {
      throw StateError('Unavailable');
    }
    _saving = true;
    final epoch = _epoch;
    try {
      await ref
          .read(notificationPreferencesRepositoryProvider)
          .save(user.id, key, value);
      if (epoch == _epoch &&
          ref.read(authControllerProvider).asData?.value?.id == user.id) {
        state = AsyncData({...previous, key: value});
      }
    } finally {
      if (epoch == _epoch) _saving = false;
    }
  }
}
