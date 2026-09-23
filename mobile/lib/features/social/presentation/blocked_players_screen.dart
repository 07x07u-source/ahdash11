import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/social_identity.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../data/social_repository.dart';

final blockedPlayersProvider = FutureProvider<List<Map<String, Object?>>>((
  ref,
) {
  final repository = ref.watch(socialRepositoryProvider);
  if (!repository.isAvailable) return const [];
  return repository.loadBlockedPlayers();
});

final class BlockedPlayersScreen extends ConsumerWidget {
  const BlockedPlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(socialRepositoryProvider).isAvailable;
    final state = ref.watch(blockedPlayersProvider);
    return AhdashV10Page(
      title: 'اللاعبون المحظورون',
      subtitle: 'قائمتك تحت سيطرتك',
      onBack: () => context.canPop() ? context.pop() : context.go('/settings'),
      child: RefreshIndicator(
        onRefresh: () async {
          if (!available) return;
          try {
            ref.invalidate(blockedPlayersProvider);
            await ref.read(blockedPlayersProvider.future);
          } catch (_) {
            // The provider renders the safe retry state below.
          }
        },
        child: CustomScrollView(
          key: const ValueKey('blocked-players-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _PrivacyHero()),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            if (!available)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _BlockedMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'القائمة غير متاحة الآن',
                  message: 'تحتاج هذه القائمة إلى اتصال الخدمة بحسابك.',
                ),
              )
            else
              ...state.when<List<Widget>>(
                loading: () => [
                  SliverToBoxAdapter(
                    child: Semantics(
                      label: 'جارٍ تحميل قائمة الحظر',
                      liveRegion: true,
                      child: const LoadingSkeleton(lines: 3, lineHeight: 84),
                    ),
                  ),
                ],
                error: (_, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _BlockedMessage(
                      icon: Icons.wifi_off_rounded,
                      title: 'تعذر تحميل قائمة الحظر',
                      message: 'تحقق من الاتصال وحاول مجددًا.',
                      action: OutlinedButton.icon(
                        onPressed: () => ref.invalidate(blockedPlayersProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ),
                  ),
                ],
                data: (rows) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'قائمة الحظر',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper1,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Semantics(
                              label: '${rows.length} حساب في قائمة الحظر',
                              child: Text(
                                '${rows.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'تحديث قائمة الحظر',
                            onPressed: () =>
                                ref.invalidate(blockedPlayersProvider),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(44, 44),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 21),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (rows.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _BlockedMessage(
                        icon: Icons.shield_outlined,
                        artwork: 'assets/visuals/blocked_empty_calm_v1.png',
                        title: 'قائمة الحظر فارغة',
                        message:
                            'لا يوجد لاعب محظور في حسابك.\nستظهر الحسابات التي تحظرها هنا.',
                      ),
                    )
                  else ...[
                    SliverList.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _BlockedPlayerRow(
                        key: ValueKey(
                          'blocked-player-${rows[index]['user_id']}',
                        ),
                        row: rows[index],
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(4, 16, 4, 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.inkMuted,
                            ),
                            SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'تتحدث القائمة بعد نجاح فك الحظر.',
                                style: TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

final class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('blocked-privacy-hero'),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF244536), Color(0xFF17251E)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.paper3.withValues(alpha: .2)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
        final artwork = Image.asset(
          'assets/visuals/blocked_privacy_hero_v1.png',
          key: const ValueKey('blocked-privacy-artwork'),
          width: largeText ? 78 : 108,
          height: largeText ? 78 : 116,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          filterQuality: FilterQuality.medium,
        );
        const eyebrow = Text(
          'إدارة الخصوصية',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        );
        const copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مساحتك،\nعلى راحتك',
              style: TextStyle(
                color: AppColors.paper0,
                fontSize: 22,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'راجع قائمتك وفك الحظر متى ما رغبت.',
              style: TextStyle(
                color: Color(0xFFD2DFD3),
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ],
        );
        if (largeText) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: eyebrow),
                  artwork,
                ],
              ),
              const SizedBox(height: 10),
              copy,
            ],
          );
        }
        return Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [eyebrow, SizedBox(height: 7), copy],
              ),
            ),
            const SizedBox(width: 12),
            artwork,
          ],
        );
      },
    ),
  );
}

final class _BlockedMessage extends StatelessWidget {
  const _BlockedMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.artwork,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final String? artwork;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (artwork != null)
          Image.asset(
            artwork!,
            key: const ValueKey('blocked-empty-artwork'),
            width: 160,
            height: 160,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            filterQuality: FilterQuality.medium,
          )
        else
          ExcludeSemantics(child: Icon(icon, size: 58, color: AppColors.palm)),
        SizedBox(height: artwork == null ? 18 : 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            height: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 12,
            height: 1.7,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    ),
  );
}

final class _BlockedPlayerRow extends ConsumerStatefulWidget {
  const _BlockedPlayerRow({required this.row, super.key});
  final Map<String, Object?> row;
  @override
  ConsumerState<_BlockedPlayerRow> createState() => _BlockedPlayerRowState();
}

final class _BlockedPlayerRowState extends ConsumerState<_BlockedPlayerRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final userId = '${row['user_id']}';
    final name = '${row['display_name'] ?? row['username'] ?? 'حساب محظور'}';
    final username = '${row['username'] ?? ''}'.replaceFirst(RegExp(r'^@'), '');
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.block_rounded, size: 13, color: AppColors.inkMuted),
        const SizedBox(width: 5),
        Text(
          _busy ? 'جارٍ فك الحظر…' : 'محظور',
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    final action = OutlinedButton.icon(
      key: ValueKey('unblock-$userId'),
      onPressed: _busy ? null : () => _unblock(userId),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.palm,
        backgroundColor: const Color(0xFFF0F5EB),
        minimumSize: const Size(108, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        side: const BorderSide(color: Color(0xFFA6BDAA)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(
        _busy ? Icons.hourglass_top_rounded : Icons.lock_open_rounded,
        size: 16,
      ),
      label: Text(
        _busy ? 'جارٍ…' : 'فك الحظر',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper0,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: AhdashPlayer11Avatar(
                    imageUrl: row['avatar_url'] as String?,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.hairline),
            const SizedBox(height: 10),
            if (largeText) ...[
              Semantics(liveRegion: true, child: status),
              const SizedBox(height: 10),
              action,
            ] else
              Row(
                children: [
                  Expanded(child: Semantics(liveRegion: true, child: status)),
                  const SizedBox(width: 8),
                  action,
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _unblock(String userId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(socialRepositoryProvider).unblockPlayer(userId);
      ref.invalidate(blockedPlayersProvider);
    } catch (_) {
      if (mounted) showAhdashSnackbar(context, 'تعذر فك الحظر.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
