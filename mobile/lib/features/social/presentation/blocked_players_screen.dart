import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../data/social_repository.dart';
import 'social_visuals.dart';

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
  Widget build(BuildContext context, WidgetRef ref) => AhdashV10Page(
    title: 'اللاعبون المحظورون',
    subtitle: 'قائمة حسابك الفعلية وإدارة فك الحظر',
    onBack: () => context.canPop() ? context.pop() : context.go('/settings'),
    child: ref
        .watch(blockedPlayersProvider)
        .when(
          loading: () => const LoadingSkeleton(lines: 4),
          error: (_, _) => AppMessageState(
            icon: Icons.block_rounded,
            title: 'تعذر تحميل قائمة الحظر',
            message: 'تحقق من الاتصال وحاول مجددًا.',
            actionLabel: 'إعادة المحاولة',
            onAction: () => ref.invalidate(blockedPlayersProvider),
          ),
          data: (rows) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SocialHero(
                title: 'خصوصيتك\nفي ملعبك',
                subtitle: 'تحكّم بالقائمة بهدوء، ويمكنك فك الحظر متى شئت.',
                scene: SocialArtworkScene.blocked,
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                const Expanded(
                  child: SocialEmptyState(
                    title: 'قائمة الحظر فارغة',
                    message: 'لا يوجد لاعب محظور في حسابك.',
                    scene: SocialArtworkScene.blocked,
                  ),
                )
              else ...[
                Text(
                  '${rows.length} في القائمة',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) =>
                        _BlockedPlayerRow(row: rows[index]),
                  ),
                ),
              ],
            ],
          ),
        ),
  );
}

final class _BlockedPlayerRow extends ConsumerStatefulWidget {
  const _BlockedPlayerRow({required this.row});

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
    return SocialPlayerRow(
      displayName: name,
      username: '${row['username'] ?? ''}',
      avatarUrl: row['avatar_url'] as String?,
      badge: 'محظور',
      trailing: TextButton(
        onPressed: _busy ? null : () => _unblock(userId),
        child: Text(_busy ? 'جارٍ…' : 'فك الحظر'),
      ),
    );
  }

  Future<void> _unblock(String userId) async {
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
