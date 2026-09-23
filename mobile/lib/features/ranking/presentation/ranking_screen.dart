import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/illustrated_state.dart';
import '../../../shared/presentation/social_identity.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/leaderboard_entry.dart';
import 'ranking_controller.dart';

final class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authControllerProvider).value?.id;
    Future<void> refresh() async {
      ref.invalidate(leaderboardProvider);
      await ref.read(leaderboardProvider.future);
    }

    return AhdashV10Page(
      title: 'الترتيب',
      subtitle: 'تابع الصدارة وموقعك بين لاعبي أحدعش',
      actions: [
        IconButton.outlined(
          tooltip: 'تحديث الترتيب',
          onPressed: refresh,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.ink,
            backgroundColor: AppColors.paper1,
            minimumSize: const Size(44, 44),
            side: const BorderSide(color: AppColors.hairline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
      child: ref
          .watch(leaderboardProvider)
          .when(
            loading: () => const _RankingLoadingView(),
            error: (_, _) => _RankingErrorView(onRetry: refresh),
            data: (entries) => entries.isEmpty
                ? const _RankingEmptyView()
                : _RankingContent(
                    entries: [...entries]
                      ..sort((a, b) => a.rank.compareTo(b.rank)),
                    currentUserId: currentUserId,
                    onRefresh: refresh,
                  ),
          ),
    );
  }
}

final class _RankingContent extends StatelessWidget {
  const _RankingContent({
    required this.entries,
    required this.currentUserId,
    required this.onRefresh,
  });

  final List<LeaderboardEntry> entries;
  final String? currentUserId;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? currentEntry;
    for (final entry in entries) {
      if (entry.userId == currentUserId) {
        currentEntry = entry;
        break;
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.ink,
      backgroundColor: AppColors.brandLime,
      child: CustomScrollView(
        key: const ValueKey('ranking-real-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _LeaderboardArena(entries: entries)),
          if (currentEntry != null) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _CurrentRankCard(entry: currentEntry)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: _RankingSectionHeader(resultCount: entries.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 9)),
          SliverList.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == entries.length - 1 ? 12 : 7,
              ),
              child: _RankingRow(
                entry: entries[index],
                current: entries[index].userId == currentUserId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _LeaderboardArena extends StatelessWidget {
  const _LeaderboardArena({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final leaders = entries.take(3).toList(growable: false);
    final display = leaders.length == 3
        ? [leaders[1], leaders[0], leaders[2]]
        : leaders.reversed.toList(growable: false);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return Container(
      key: const ValueKey('ranking-podium'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.paper3.withValues(alpha: .2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .09),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .22,
              child: Image.asset(
                'assets/visuals/party_victory_arena_v1.png',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/visuals/ranking_laurel_cutout_v1.png',
                      width: 52,
                      height: 48,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'منصة المتصدرين',
                            style: TextStyle(
                              color: AppColors.paper0,
                              fontSize: 17,
                              height: 1.3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'أفضل نقاط التصنيف',
                            style: TextStyle(
                              color: AppColors.paper3,
                              fontSize: 10.5,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!largeText) ...[
                      const SizedBox(width: 6),
                      const _VerifiedRankingBadge(),
                    ],
                  ],
                ),
                if (largeText) ...[
                  const SizedBox(height: 10),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _VerifiedRankingBadge(),
                  ),
                ],
                const SizedBox(height: 18),
                if (largeText)
                  Column(
                    children: [
                      for (var index = 0; index < leaders.length; index++) ...[
                        if (index > 0) const SizedBox(height: 10),
                        _PodiumCard(entry: leaders[index]),
                      ],
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var index = 0; index < display.length; index++) ...[
                        if (index > 0) const SizedBox(width: 7),
                        Expanded(child: _PodiumCard(entry: display[index])),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _VerifiedRankingBadge extends StatelessWidget {
  const _VerifiedRankingBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.paper0.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: AppColors.paper0.withValues(alpha: .14)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_rounded, color: AppColors.brandLime, size: 14),
        SizedBox(width: 4),
        Text(
          'موثّق',
          style: TextStyle(
            color: AppColors.paper0,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

final class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final first = entry.rank == 1;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final accent = _rankColor(entry.rank);
    final foreground = first ? AppColors.ink : AppColors.paper0;
    return Semantics(
      label:
          'المركز ${entry.rank}، ${entry.username}، ${entry.rating} نقطة تصنيف',
      child: Container(
        height: scale > 1.5
            ? null
            : (first ? 190 : 174) + ((scale - 1).clamp(0, 2) * 104),
        padding: const EdgeInsets.fromLTRB(7, 10, 7, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: first
                ? [const Color(0xFFD6FF91), AppColors.brandLime]
                : [const Color(0xFF30312A), const Color(0xFF242720)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: first ? AppColors.brandLime : accent.withValues(alpha: .48),
          ),
        ),
        child: scale > 1.5
            ? Padding(
                padding: const EdgeInsets.all(5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RankingAvatar(entry: entry, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${entry.rank}',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.username,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 15,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${entry.rating} نقطة',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 15,
                              height: 1.3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: first
                          ? AppColors.ink
                          : accent.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '#${entry.rank}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: first ? AppColors.brandLime : accent,
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _RankingAvatar(entry: entry, size: first ? 52 : 44),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        entry.username,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 11.5,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${entry.rating}',
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'نقطة',
                    style: TextStyle(
                      color: first ? AppColors.ink : AppColors.paper3,
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

final class _CurrentRankCard extends StatelessWidget {
  const _CurrentRankCard({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('ranking-current-player'),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.brandLime.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.palm.withValues(alpha: .55)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: Text(
            '#${entry.rank}',
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: AppColors.brandLime,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هذا مركزك',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              Text(
                'استمر في اللعب وارفع تصنيفك',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${entry.rating}',
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

final class _RankingSectionHeader extends StatelessWidget {
  const _RankingSectionHeader({required this.resultCount});

  final int resultCount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.brandLime,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
      const SizedBox(width: 9),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الترتيب الكامل',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            Text(
              'اسحب للأسفل لتحديث النتائج',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.paper1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Text(
          '$resultCount نتيجة',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

final class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry, required this.current});

  final LeaderboardEntry entry;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final podium = entry.rank <= 3;
    final accent = _rankColor(entry.rank);
    return Semantics(
      container: true,
      selected: current,
      label:
          'المركز ${entry.rank}، ${entry.username}، ${_tierLabel(entry.tier)}، ${entry.rating} نقطة تصنيف',
      child: Container(
        key: ValueKey('ranking-row-${entry.userId}'),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 12, 9),
        decoration: BoxDecoration(
          color: current
              ? AppColors.brandLime.withValues(alpha: .14)
              : AppColors.paper1,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: current
                ? AppColors.palm.withValues(alpha: .62)
                : podium
                ? accent.withValues(alpha: .48)
                : AppColors.hairline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 42,
              decoration: BoxDecoration(
                color: podium
                    ? accent.withValues(alpha: entry.rank == 1 ? 1 : .18)
                    : AppColors.paper2,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '${entry.rank}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: entry.rank == 1 ? AppColors.ink : accent,
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            _RankingAvatar(entry: entry, size: 38),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current ? '${entry.username} · أنت' : entry.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _tierLabel(entry.tier),
                      style: TextStyle(
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.rating}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'نقطة تصنيف',
                  style: TextStyle(
                    fontSize: 8,
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _RankingAvatar extends StatelessWidget {
  const _RankingAvatar({required this.entry, required this.size});

  final LeaderboardEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasRemoteAvatar = entry.avatarUrl?.trim().isNotEmpty ?? false;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AhdashPlayer11Avatar(imageUrl: entry.avatarUrl, size: size),
        if (!hasRemoteAvatar)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: size * .42,
              height: size * .42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: .9),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandLime, width: 1.2),
              ),
              child: Text(
                entry.username.trim().isEmpty ? '١١' : entry.username.trim()[0],
                style: TextStyle(
                  color: AppColors.paper0,
                  fontSize: size * .22,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _RankingLoadingView extends StatelessWidget {
  const _RankingLoadingView();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.brandLime,
            strokeWidth: 3,
          ),
        ),
      ),
      const SizedBox(height: 18),
      const _RankingSkeletonRow(),
      const SizedBox(height: 8),
      const _RankingSkeletonRow(),
      const SizedBox(height: 8),
      const _RankingSkeletonRow(),
    ],
  );
}

final class _RankingSkeletonRow extends StatelessWidget {
  const _RankingSkeletonRow();

  @override
  Widget build(BuildContext context) => Container(
    height: 62,
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.hairline),
    ),
  );
}

final class _RankingEmptyView extends StatelessWidget {
  const _RankingEmptyView();

  @override
  Widget build(BuildContext context) => const AhdashIllustratedState(
    asset: 'assets/visuals/ranking_empty_cutout_v1.png',
    title: 'الصدارة تنتظر أول نتيجة',
    message: 'بعد أول مباراة موثقة سيظهر ترتيب اللاعبين ونقاط التصنيف هنا.',
    note: 'لا توجد مراكز أو نتائج تجريبية',
  );
}

final class _RankingErrorView extends StatelessWidget {
  const _RankingErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Spacer(flex: 2),
      Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
            color: AppColors.brandLime,
            size: 44,
          ),
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'تعذر تحديث الترتيب',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      const Text(
        'لم تصل النتائج الموثقة من الخادم. تحقق من الاتصال وحاول مجددًا.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.inkMuted,
          fontSize: 14,
          height: 1.6,
          fontWeight: FontWeight.w600,
        ),
      ),
      const Spacer(flex: 3),
      AhdashV10PrimaryButton(
        key: const ValueKey('ranking-retry'),
        label: 'إعادة المحاولة',
        icon: Icons.refresh_rounded,
        onPressed: onRetry,
      ),
      const SizedBox(height: 12),
    ],
  );
}

Color _rankColor(int rank) => switch (rank) {
  1 => AppColors.brandLime,
  2 => AppColors.teamBlue,
  3 => AppColors.gold,
  _ => AppColors.inkMuted,
};

String _tierLabel(String tier) => switch (tier.toLowerCase()) {
  'bronze' => 'برونزي',
  'silver' => 'فضي',
  'gold' => 'ذهبي',
  'platinum' => 'بلاتيني',
  'diamond' => 'ماسي',
  _ => tier,
};
