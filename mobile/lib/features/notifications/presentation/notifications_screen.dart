import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/app_services.dart';
import '../../../core/theme/app_colors.dart';
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
        IconButton.outlined(
          key: const ValueKey('notifications-refresh'),
          icon: const Icon(Icons.refresh_rounded, size: 21),
          tooltip: 'تحديث الإشعارات',
          style: IconButton.styleFrom(
            minimumSize: const Size.square(44),
            foregroundColor: AppColors.ink,
            backgroundColor: AppColors.paper0,
            side: const BorderSide(color: AppColors.hairline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          onPressed: () => ref.invalidate(notificationsProvider),
        ),
      ],
      child: _Inbox(key: ValueKey(account)),
    );
  }
}

enum _InboxFilter { all, unread, matches, teams, system }

final class _Inbox extends ConsumerStatefulWidget {
  const _Inbox({super.key});

  @override
  ConsumerState<_Inbox> createState() => _InboxState();
}

final class _InboxState extends ConsumerState<_Inbox> {
  _InboxFilter _filter = _InboxFilter.all;
  final _busy = <String>{};
  bool _markingAll = false;

  @override
  Widget build(BuildContext context) => ref
      .watch(notificationsProvider)
      .when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: false,
        loading: () => const _NotificationsLoading(),
        error: (_, _) => _NotificationsError(onRetry: _refresh),
        data: _buildInbox,
      );

  Widget _buildInbox(List<InboxNotification> items) {
    final activeItems = items
        .where(
          (item) => const {'friend', 'social'}.contains(item.type) == false,
        )
        .toList(growable: false);
    final unreadCount = activeItems.where((item) => item.unread).length;
    final visible = activeItems.where(_matchesFilter).toList(growable: false);
    final recent = visible.where((item) => item.unread).toList(growable: false);
    final previous = visible
        .where((item) => !item.unread)
        .toList(growable: false);

    return RefreshIndicator(
      key: const ValueKey('notifications-pull-refresh'),
      color: AppColors.ink,
      backgroundColor: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        key: const ValueKey('notifications-scroll'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _NotificationSummary(
            unreadCount: unreadCount,
            totalCount: items.length,
            busy: _markingAll,
            onMarkAllRead: unreadCount == 0 ? null : _markAllRead,
          ),
          const SizedBox(height: 14),
          _NotificationFilters(
            selected: _filter,
            unreadCount: unreadCount,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: 18),
          if (visible.isEmpty)
            _NotificationsEmpty(filtered: activeItems.isNotEmpty)
          else ...[
            if (recent.isNotEmpty)
              _NotificationGroup(
                key: const ValueKey('notifications-recent-group'),
                title: 'وصل حديثًا',
                caption:
                    '${recent.length} ${_notificationCountLabel(recent.length)}',
                items: recent,
                busy: _busy,
                onOpen: _open,
              ),
            if (recent.isNotEmpty && previous.isNotEmpty)
              const SizedBox(height: 20),
            if (previous.isNotEmpty)
              _NotificationGroup(
                key: const ValueKey('notifications-previous-group'),
                title: 'السجل السابق',
                caption: 'آخر التحديثات المقروءة',
                items: previous,
                busy: _busy,
                onOpen: _open,
              ),
          ],
        ],
      ),
    );
  }

  bool _matchesFilter(InboxNotification item) => switch (_filter) {
    _InboxFilter.all => true,
    _InboxFilter.unread => item.unread,
    _InboxFilter.matches => const {
      'match',
      'challenge',
      'tournament',
    }.contains(item.type),
    _InboxFilter.teams => item.type == 'team',
    _InboxFilter.system => const {'system', 'announcement'}.contains(item.type),
  };

  Future<void> _refresh() async {
    ref.invalidate(notificationsProvider);
    try {
      await ref.read(notificationsProvider.future);
    } on Object {
      // The provider renders the localized retry surface.
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    final account = ref.read(authControllerProvider).value?.id;
    if (account == null) return;
    setState(() => _markingAll = true);
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead(account);
      if (!mounted || ref.read(authControllerProvider).value?.id != account) {
        return;
      }
      ref.invalidate(notificationsProvider);
      await ref
          .read(appServicesProvider)
          .analytics
          .log('notifications_marked_all_read');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعليم جميع الإشعارات كمقروءة.')),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديث الإشعارات. أعد المحاولة.')),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _open(InboxNotification item) async {
    if (!_busy.add(item.id)) return;
    setState(() {});
    final account = ref.read(authControllerProvider).value?.id;
    try {
      if (account == null) throw StateError('Unavailable');
      if (item.unread) {
        await ref
            .read(notificationsRepositoryProvider)
            .markRead(account, item.id);
      }
      if (!mounted || ref.read(authControllerProvider).value?.id != account) {
        return;
      }
      if (item.unread) ref.invalidate(notificationsProvider);
      await ref.read(appServicesProvider).analytics.log('notification_opened', {
        'type': item.type,
      });
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

final class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({
    required this.unreadCount,
    required this.totalCount,
    required this.busy,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final int totalCount;
  final bool busy;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primary.withValues(alpha: .34)),
          ),
          child: const Text(
            'مركزك اليوم',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'كل الجديد، في مكان واحد',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          totalCount == 0
              ? 'ستظهر هنا دعواتك وتحديثات اللعبة.'
              : 'دعوات وتحديات وتحديثات مرتبة حسب أهميتها.',
          style: TextStyle(
            color: AppColors.white.withValues(alpha: .7),
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
    final counter = Container(
      key: const ValueKey('notifications-unread-count'),
      width: largeText ? double.infinity : 74,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: unreadCount == 0
            ? Colors.white.withValues(alpha: .08)
            : AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unreadCount == 0
              ? Colors.white.withValues(alpha: .12)
              : AppColors.primary,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$unreadCount',
            style: TextStyle(
              color: unreadCount == 0 ? AppColors.white : AppColors.ink,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'غير مقروء',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: unreadCount == 0
                  ? AppColors.white.withValues(alpha: .68)
                  : AppColors.ink,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return Container(
      key: const ValueKey('notifications-summary'),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF244A39), Color(0xFF172A21), Color(0xFF111713)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF315E49)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142219).withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            start: -45,
            top: -55,
            child: Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: .055),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (largeText) ...[
                copy,
                const SizedBox(height: 12),
                counter,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 14),
                    counter,
                  ],
                ),
              if (onMarkAllRead != null || busy) ...[
                const SizedBox(height: 7),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    key: const ValueKey('notifications-mark-all-read'),
                    onPressed: busy ? null : onMarkAllRead,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor: AppColors.white.withValues(
                        alpha: .45,
                      ),
                      minimumSize: const Size(44, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.done_all_rounded, size: 18),
                    label: Text(
                      busy ? 'جارٍ التحديث' : 'تعليم الكل كمقروء',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

final class _NotificationFilters extends StatelessWidget {
  const _NotificationFilters({
    required this.selected,
    required this.unreadCount,
    required this.onSelected,
  });

  final _InboxFilter selected;
  final int unreadCount;
  final ValueChanged<_InboxFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = [
      const (_InboxFilter.all, 'الكل', Icons.inbox_rounded),
      (
        _InboxFilter.unread,
        unreadCount == 0 ? 'غير المقروء' : 'غير المقروء $unreadCount',
        Icons.mark_email_unread_rounded,
      ),
      const (_InboxFilter.matches, 'اللعب', Icons.sports_soccer_rounded),
      const (_InboxFilter.teams, 'الفِرق', Icons.group_outlined),
      const (_InboxFilter.system, 'النظام', Icons.auto_awesome_rounded),
    ];
    return Semantics(
      container: true,
      label: 'تصفية الإشعارات',
      child: SingleChildScrollView(
        key: const ValueKey('notifications-filters'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var index = 0; index < options.length; index++) ...[
              _NotificationFilterChip(
                filter: options[index].$1,
                label: options[index].$2,
                icon: options[index].$3,
                selected: selected == options[index].$1,
                onPressed: () => onSelected(options[index].$1),
              ),
              if (index != options.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

final class _NotificationFilterChip extends StatelessWidget {
  const _NotificationFilterChip({
    required this.filter,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final _InboxFilter filter;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('notifications-filter-${filter.name}'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.paper1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.primary : AppColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.title,
    required this.caption,
    required this.items,
    required this.busy,
    required this.onOpen,
    super.key,
  });

  final String title;
  final String caption;
  final List<InboxNotification> items;
  final Set<String> busy;
  final ValueChanged<InboxNotification> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            caption,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      for (var index = 0; index < items.length; index++) ...[
        _NotificationCard(
          item: items[index],
          busy: busy.contains(items[index].id),
          onTap: () => onOpen(items[index]),
        ),
        if (index != items.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
}

final class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.busy,
    required this.onTap,
  });

  final InboxNotification item;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(item.type);
    return Semantics(
      container: true,
      button: true,
      label:
          '${item.unread ? 'إشعار غير مقروء' : 'إشعار مقروء'}، ${item.title}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('notification-${item.id}'),
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsetsDirectional.fromSTEB(0, 13, 13, 13),
            decoration: BoxDecoration(
              color: item.unread
                  ? Color.alphaBlend(
                      visual.accent.withValues(alpha: .055),
                      Colors.white,
                    )
                  : AppColors.paper1,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: item.unread
                    ? visual.accent.withValues(alpha: .56)
                    : AppColors.hairline,
              ),
              boxShadow: item.unread
                  ? [
                      BoxShadow(
                        color: visual.accent.withValues(alpha: .08),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 58,
                  decoration: BoxDecoration(
                    color: item.unread ? visual.accent : Colors.transparent,
                    borderRadius: const BorderRadiusDirectional.horizontal(
                      end: Radius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        visual.accent.withValues(
                          alpha: item.unread ? .22 : .11,
                        ),
                        visual.accent.withValues(
                          alpha: item.unread ? .08 : .04,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: visual.accent.withValues(alpha: .18),
                    ),
                  ),
                  child: Icon(visual.icon, color: visual.accent, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 15,
                                height: 1.25,
                                fontWeight: item.unread
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (item.unread) ...[
                            const SizedBox(width: 7),
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: visual.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 3,
                        children: [
                          Text(
                            visual.label,
                            style: TextStyle(
                              color: visual.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppColors.hairline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            _relativeTime(item.createdAt),
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                if (busy)
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: visual.accent,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.inkMuted,
                    size: 21,
                    textDirection: TextDirection.ltr,
                  ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('notifications-empty'),
    padding: const EdgeInsets.fromLTRB(14, 28, 14, 10),
    child: Column(
      children: [
        const _NotificationStateArtwork(icon: Icons.notifications_none_rounded),
        const SizedBox(height: 18),
        Text(
          filtered ? 'لا يوجد شيء في هذا القسم' : 'صندوقك هادئ الآن',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          filtered
              ? 'جرّب اختيار «الكل» لمشاهدة بقية إشعاراتك.'
              : 'عند وصول دعوة أو تحدٍ جديد ستجده هنا مرتبًا وواضحًا.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

final class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('notifications-error'),
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(14, 72, 14, 24),
    children: [
      const _NotificationStateArtwork(
        icon: Icons.signal_wifi_connected_no_internet_4_rounded,
        error: true,
      ),
      const SizedBox(height: 18),
      const Text(
        'تعذر الوصول إلى إشعاراتك',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'تحقق من الاتصال ثم حاول مرة أخرى. إشعاراتك محفوظة ولن تضيع.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.inkMuted, fontSize: 14, height: 1.55),
      ),
      const SizedBox(height: 20),
      Center(
        child: FilledButton.icon(
          key: const ValueKey('notifications-retry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 19),
          label: const Text('إعادة المحاولة'),
        ),
      ),
    ],
  );
}

final class _NotificationStateArtwork extends StatelessWidget {
  const _NotificationStateArtwork({required this.icon, this.error = false});

  final IconData icon;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final accent = error ? AppColors.danger : AppColors.primary;
    return SizedBox(
      width: 148,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PositionedDirectional(
            end: 5,
            top: 18,
            child: Transform.rotate(
              angle: -.09,
              child: Container(
                width: 86,
                height: 66,
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.hairline),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 4,
            bottom: 8,
            child: Transform.rotate(
              angle: .08,
              child: Container(
                width: 88,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.paper1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.hairline),
                ),
              ),
            ),
          ),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: .18),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Icon(icon, color: accent, size: 34),
          ),
          PositionedDirectional(
            end: 30,
            top: 12,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paper0, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('notifications-loading'),
    physics: const NeverScrollableScrollPhysics(),
    children: [
      _SkeletonBlock(
        height: 152,
        radius: 24,
        color: AppColors.ink.withValues(alpha: .12),
      ),
      const SizedBox(height: 14),
      const Row(
        children: [
          Expanded(child: _SkeletonBlock(height: 42, radius: 14)),
          SizedBox(width: 8),
          Expanded(child: _SkeletonBlock(height: 42, radius: 14)),
          SizedBox(width: 8),
          Expanded(child: _SkeletonBlock(height: 42, radius: 14)),
        ],
      ),
      const SizedBox(height: 22),
      const _SkeletonBlock(height: 16, widthFactor: .34, radius: 8),
      const SizedBox(height: 12),
      const _SkeletonBlock(height: 112, radius: 20),
      const SizedBox(height: 10),
      const _SkeletonBlock(height: 112, radius: 20),
      const SizedBox(height: 10),
      const _SkeletonBlock(height: 112, radius: 20),
    ],
  );
}

final class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    required this.radius,
    this.widthFactor = 1,
    this.color,
  });

  final double height;
  final double radius;
  final double widthFactor;
  final Color? color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color ?? AppColors.paper2,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.hairline.withValues(alpha: .45)),
        ),
      ),
    ),
  );
}

final class _NotificationVisual {
  const _NotificationVisual(this.label, this.icon, this.accent);

  final String label;
  final IconData icon;
  final Color accent;
}

_NotificationVisual _visualFor(String type) => switch (type) {
  'match' => const _NotificationVisual(
    'مباراة',
    Icons.sports_soccer_rounded,
    AppColors.teamBlue,
  ),
  'challenge' => const _NotificationVisual(
    'تحدٍ',
    Icons.bolt_rounded,
    AppColors.teamPink,
  ),
  'tournament' => const _NotificationVisual(
    'بطولة',
    Icons.emoji_events_rounded,
    Color(0xFFB77916),
  ),
  'team' => const _NotificationVisual(
    'الفريق',
    Icons.groups_rounded,
    AppColors.palm,
  ),
  'announcement' => const _NotificationVisual(
    'إعلان',
    Icons.campaign_rounded,
    AppColors.palm,
  ),
  _ => const _NotificationVisual(
    'النظام',
    Icons.auto_awesome_rounded,
    AppColors.palm,
  ),
};

String _notificationCountLabel(int count) {
  if (count == 1) return 'جديد';
  if (count == 2) return 'جديدان';
  if (count >= 3 && count <= 10) return 'جديدة';
  return 'جديد';
}

String _relativeTime(DateTime value) {
  final now = DateTime.now().toUtc();
  final delta = now.difference(value.toUtc());
  if (delta.isNegative || delta.inMinutes < 1) return 'الآن';
  if (delta.inMinutes < 60) {
    if (delta.inMinutes == 1) return 'قبل دقيقة';
    if (delta.inMinutes == 2) return 'قبل دقيقتين';
    return 'قبل ${delta.inMinutes} دقيقة';
  }
  if (delta.inHours < 24) {
    if (delta.inHours == 1) return 'قبل ساعة';
    if (delta.inHours == 2) return 'قبل ساعتين';
    return 'قبل ${delta.inHours} ساعات';
  }
  if (delta.inDays < 7) {
    if (delta.inDays == 1) return 'أمس';
    if (delta.inDays == 2) return 'قبل يومين';
    return 'قبل ${delta.inDays} أيام';
  }
  return '${value.day}/${value.month}/${value.year}';
}
