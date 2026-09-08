import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/utility_v9.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/notifications_repository.dart';

final class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authControllerProvider).value?.id;
    return AhdashUtilityScaffold(
      title: 'الإشعارات',
      showBack: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all_rounded),
          tooltip: 'تحديث',
          onPressed: () => ref.invalidate(notificationsProvider),
        ),
      ],
      child: _Inbox(key: ValueKey(account)),
    );
  }
}

final class _Inbox extends ConsumerStatefulWidget {
  const _Inbox({super.key});
  @override
  ConsumerState<_Inbox> createState() => _InboxState();
}

final class _InboxState extends ConsumerState<_Inbox> {
  String _filter = 'all';
  final _busy = <String>{};
  @override
  Widget build(BuildContext context) => ref
      .watch(notificationsProvider)
      .when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading: () => const LoadingSkeleton(lines: 5),
        error: (_, _) => AppMessageState(
          title: 'تعذر تحميل الإشعارات',
          message: 'سجّل دخولك وتحقق من الاتصال.',
          actionLabel: 'أعد المحاولة',
          onAction: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) {
          final visible = items.where((item) {
            if (_filter == 'all') return true;
            if (_filter == 'matches') {
              return const [
                'match',
                'challenge',
                'tournament',
              ].contains(item.type);
            }
            return item.type == 'system' || item.type == 'announcement';
          }).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      selected: _filter == 'all',
                      onPressed: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'المباريات',
                      selected: _filter == 'matches',
                      onPressed: () => setState(() => _filter = 'matches'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'النظام',
                      selected: _filter == 'system',
                      onPressed: () => setState(() => _filter = 'system'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: visible.isEmpty
                    ? const Center(
                        child: AppMessageState(
                          title: 'ما عندك إشعارات جديدة',
                          message: 'تظهر هنا تحديثات حسابك ودعواتك.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final item = visible[index];
                          final accent = item.unread
                              ? const Color(0xFF1E874B)
                              : AppColors.hairline;
                          return Semantics(
                            label: item.unread
                                ? 'إشعار غير مقروء'
                                : 'إشعار مقروء',
                            child: Material(
                              color: item.unread
                                  ? const Color(0xFFF8FFFA)
                                  : AppColors.paper1,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: accent),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                enabled: !_busy.contains(item.id),
                                onTap: () => _open(item),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: item.unread
                                        ? const Color(0xFFE8F7EE)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _notificationIcon(item.type),
                                    color: item.unread
                                        ? const Color(0xFF1E874B)
                                        : AppColors.muted,
                                    size: 21,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: item.unread
                                        ? FontWeight.w900
                                        : FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.body,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      item.unread
                                          ? 'قبل ساعة واحدة'
                                          : '${item.createdAt.day}/${item.createdAt.month}',
                                      semanticsLabel:
                                          'تاريخ الإشعار ${item.createdAt.day} / ${item.createdAt.month}',
                                      style: TextStyle(
                                        color: item.unread
                                            ? const Color(0xFF1E874B)
                                            : AppColors.muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: _busy.contains(item.id)
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );

  IconData _notificationIcon(String type) => switch (type) {
    'match' || 'challenge' || 'tournament' => Icons.sports_martial_arts,
    'system' => Icons.extension_rounded,
    _ => Icons.person_add_alt_1_rounded,
  };
  Future<void> _open(InboxNotification item) async {
    if (!_busy.add(item.id)) return;
    setState(() {});
    final account = ref.read(authControllerProvider).value?.id;
    try {
      if (account == null) throw StateError('Unavailable');
      await ref
          .read(notificationsRepositoryProvider)
          .markRead(account, item.id);
      if (!mounted || ref.read(authControllerProvider).value?.id != account) {
        return;
      }
      ref.invalidate(notificationsProvider);
      await ref.read(appServicesProvider).analytics.log('notification_opened');
      if (mounted && item.route != '/notifications') {
        await context.push(item.route);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الإشعار. أعد المحاولة.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }
}

final class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        backgroundColor: selected ? const Color(0xFF1E874B) : AppColors.paper1,
        foregroundColor: selected ? Colors.white : AppColors.muted,
        side: BorderSide(
          color: selected ? const Color(0xFF1E874B) : AppColors.hairline,
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}
