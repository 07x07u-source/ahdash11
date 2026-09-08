import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/presentation/auth_controller.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(
    ref.watch(appConfigProvider).hasSupabase ? Supabase.instance.client : null,
  ),
);

final notificationsProvider = FutureProvider<List<InboxNotification>>((
  ref,
) async {
  final user = await ref.watch(authControllerProvider.future);
  if (user == null || user.isGuest) throw StateError('Unavailable');
  return ref.watch(notificationsRepositoryProvider).load(user.id);
});

final class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.data = const {},
  });
  factory InboxNotification.fromJson(Map<String, Object?> row) =>
      InboxNotification(
        id: row['id'] as String,
        type: row['type'] as String,
        title: row['title_ar'] as String? ?? '',
        body: row['body_ar'] as String? ?? '',
        createdAt: DateTime.parse(row['created_at'] as String),
        readAt: DateTime.tryParse(row['read_at'] as String? ?? ''),
        data: Map<String, dynamic>.from(row['data'] as Map? ?? const {}),
      );
  final String id, type, title, body;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic> data;
  bool get unread => readAt == null;
  String get route => NotificationNavigation.resolve(data);
}

class NotificationsRepository {
  const NotificationsRepository(this.client);
  final SupabaseClient? client;
  Future<List<InboxNotification>> load(String userId) async {
    if (client == null) throw StateError('Unavailable');
    final rows = await client!
        .from('notifications')
        .select('id,type,title_ar,body_ar,data,read_at,created_at')
        .eq('target_user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(InboxNotification.fromJson).toList(growable: false);
  }

  Future<void> markRead(String userId, String id) async {
    if (client == null || client!.auth.currentUser?.id != userId) {
      throw StateError('Unavailable');
    }
    await client!
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('target_user_id', userId)
        .eq('id', id)
        .select('id')
        .single();
  }
}
