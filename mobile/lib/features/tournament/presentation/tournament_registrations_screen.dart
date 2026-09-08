import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/tournament_registration_repository.dart';
import 'tournament_controller.dart';

final class TournamentRegistrationsScreen extends ConsumerWidget {
  const TournamentRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentControllerProvider).active;
    ref.watch(authControllerProvider);
    if (tournament == null ||
        !tournament.canEdit ||
        !ref.read(tournamentControllerProvider.notifier).canManage) {
      return BrandScaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/tournaments'),
            child: const Text('العودة إلى البطولات'),
          ),
        ),
      );
    }
    final requests = ref.watch(
      pendingTournamentRegistrationsProvider(tournament.id),
    );
    final metrics = context.v9Metrics;
    return BrandScaffold(
      body: AhdashV9Frame(
        child: Column(
          children: [
            AhdashV9TopBar(
              title: 'طلبات الانضمام',
              kicker: tournament.name,
              gold: true,
              leading: AhdashV9IconButton(
                icon: Icons.arrow_forward_rounded,
                tooltip: 'رجوع',
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/tournaments/teams'),
              ),
              actions: [
                AhdashV9IconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'تحديث',
                  onPressed: () => ref.invalidate(
                    pendingTournamentRegistrationsProvider(tournament.id),
                  ),
                ),
              ],
            ),
            SizedBox(height: metrics.sectionGap),
            Expanded(
              child: requests.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _RegistrationMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'تعذر تحميل الطلبات',
                  message: 'تأكد من الاتصال وأن حسابك هو منظّم هذه البطولة.',
                  action: () => ref.invalidate(
                    pendingTournamentRegistrationsProvider(tournament.id),
                  ),
                ),
                data: (items) => items.isEmpty
                    ? const _RegistrationMessage(
                        icon: Icons.inbox_outlined,
                        title: 'لا توجد طلبات معلّقة',
                        message:
                            'شارك رمز البطولة. الطلبات الجديدة ستظهر هنا للموافقة أو الرفض.',
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _RegistrationCard(request: items[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _RegistrationCard extends ConsumerStatefulWidget {
  const _RegistrationCard({required this.request});

  final TournamentRegistrationRequest request;

  @override
  ConsumerState<_RegistrationCard> createState() => _RegistrationCardState();
}

final class _RegistrationCardState extends ConsumerState<_RegistrationCard> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final compact =
        context.v9Metrics.portrait || MediaQuery.sizeOf(context).width < 620;
    final team = Row(
      children: [
        CircleAvatar(
          backgroundColor: context.ahdashColors.selected,
          child: const Icon(Icons.shield_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.teamName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                request.playerNames.isEmpty
                    ? 'لم تُرسل أسماء التشكيلة'
                    : request.playerNames.join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.ahdashColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (compact) const Spacer(),
        TextButton(
          onPressed: _busy ? null : () => _review(false),
          child: const Text('رفض'),
        ),
        const SizedBox(width: 6),
        FilledButton.icon(
          onPressed: _busy ? null : () => _review(true),
          icon: _busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: const Text('قبول'),
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.ahdashColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.ahdashColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [team, const SizedBox(height: 10), actions],
              )
            : Row(
                children: [
                  Expanded(child: team),
                  const SizedBox(width: 12),
                  actions,
                ],
              ),
      ),
    );
  }

  Future<void> _review(bool approve) async {
    final tournament = ref.read(tournamentControllerProvider).active;
    if (_busy ||
        tournament == null ||
        !tournament.canEdit ||
        !ref.read(tournamentControllerProvider.notifier).canManage) {
      return;
    }
    if (approve && tournament.teams.length >= tournament.rules.capacity) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اكتملت سعة البطولة.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(tournamentRegistrationRepositoryProvider)
          .review(registrationId: widget.request.id, approve: approve);
      // Hydrate the server-created ID and roster; never manufacture a second
      // local team from the accepted registration's display name.
      await ref.read(tournamentControllerProvider.notifier).refresh();
      ref.invalidate(pendingTournamentRegistrationsProvider(tournament.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'قُبل الفريق وأضيف للبطولة.' : 'رُفض الطلب.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تحديث الطلب. تحقق من صلاحيات المنظّم.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

final class _RegistrationMessage extends StatelessWidget {
  const _RegistrationMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: context.ahdashColors.gold),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    ),
  );
}
