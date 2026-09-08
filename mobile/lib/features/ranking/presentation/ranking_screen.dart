import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/social_identity.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../social/presentation/social_visuals.dart';
import '../domain/leaderboard_entry.dart';
import 'ranking_controller.dart';

final class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authControllerProvider).value?.id;
    return AhdashV10Page(
      title: 'الترتيب',
      subtitle: 'نتائج موثقة من الخادم فقط',
      actions: [
        IconButton(
          tooltip: 'تحديث',
          onPressed: () => ref.invalidate(leaderboardProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: ref
          .watch(leaderboardProvider)
          .when(
            loading: () => const LoadingSkeleton(lines: 5),
            error: (_, _) => AppMessageState(
              icon: Icons.leaderboard_outlined,
              title: 'الترتيب غير متاح الآن',
              message: 'تعذر جلب النتائج الموثقة. حاول مرة أخرى لاحقًا.',
              actionLabel: 'إعادة المحاولة',
              onAction: () => ref.invalidate(leaderboardProvider),
            ),
            data: (entries) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SocialHero(
                  title: 'جدول\nالمنافسة',
                  subtitle: 'ترتيب مبني على النتائج الموثقة فقط.',
                  scene: SocialArtworkScene.ranking,
                ),
                const SizedBox(height: 14),
                if (entries.isEmpty)
                  const Expanded(
                    child: SocialEmptyState(
                      title: 'لا توجد نتائج منشورة',
                      message: 'عندما تتوفر نتائج حقيقية من الخادم ستظهر هنا.',
                      scene: SocialArtworkScene.ranking,
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        const _RankingLegend(),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            key: const ValueKey('ranking-real-list'),
                            itemCount: entries.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 7),
                            itemBuilder: (_, index) => _RankingRow(
                              entry: entries[index],
                              current: entries[index].userId == currentUserId,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}

final class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry, required this.current});

  final LeaderboardEntry entry;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final podium = entry.rank <= 3;
    return AhdashV10Panel(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 12, 9),
      selected: current,
      selectedBackgroundColor: AppColors.paper1,
      selectedBorderColor: AppColors.ink,
      semanticLabel: 'المركز ${entry.rank}، ${entry.username}، ${entry.rating}',
      child: Row(
        children: [
          Container(
            width: 42,
            height: 48,
            decoration: BoxDecoration(
              color: podium
                  ? entry.rank == 1
                        ? AppColors.primary
                        : entry.rank == 2
                        ? AppColors.gold
                        : AppColors.paper3
                  : AppColors.paper1,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: podium ? AppColors.ink : AppColors.hairline,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.rank}',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 19,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AhdashPlayer11Avatar(imageUrl: entry.avatarUrl, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current ? '${entry.username} · أنت' : entry.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.tier,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.rating}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'نقطة',
                style: TextStyle(fontSize: 9, color: AppColors.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _RankingLegend extends StatelessWidget {
  const _RankingLegend();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            'المركز',
            style: TextStyle(fontSize: 9, color: AppColors.inkMuted),
          ),
        ),
        Expanded(
          child: Text(
            'اللاعب',
            style: TextStyle(fontSize: 9, color: AppColors.inkMuted),
          ),
        ),
        Text(
          'الرصيد',
          style: TextStyle(fontSize: 9, color: AppColors.inkMuted),
        ),
      ],
    ),
  );
}
