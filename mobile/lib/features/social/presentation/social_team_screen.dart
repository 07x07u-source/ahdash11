import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/social_identity.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../data/social_repository.dart';
import '../domain/social_entities.dart';
import 'social_visuals.dart';

final class SocialTeamScreen extends ConsumerWidget {
  const SocialTeamScreen({required this.teamId, super.key});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AhdashV10Page(
    title: 'تفاصيل الفريق',
    subtitle: 'بيانات العضوية الفعلية فقط',
    onBack: () => context.canPop() ? context.pop() : context.go('/teams'),
    actions: [
      IconButton(
        tooltip: 'تحديث',
        onPressed: () => ref.invalidate(socialTeamDetailProvider(teamId)),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    child: ref
        .watch(socialTeamDetailProvider(teamId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppMessageState(
            icon: Icons.groups_3_outlined,
            title: 'تعذر فتح الفريق',
            message: 'قد تكون العضوية أو خدمة الفريق غير متاحة.',
            actionLabel: 'إعادة المحاولة',
            onAction: () => ref.invalidate(socialTeamDetailProvider(teamId)),
          ),
          data: (team) => _TeamBody(team: team),
        ),
  );
}

final class _TeamBody extends StatelessWidget {
  const _TeamBody({required this.team});

  final SocialTeamDetail team;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SocialHero(
        title: team.name,
        subtitle: 'هوية الفريق وأعضاؤه وإجراءاته الفعلية.',
        scene: SocialArtworkScene.team,
      ),
      const SizedBox(height: 12),
      AhdashV10Panel(
        semanticLabel: 'الفريق ${team.name}، ${team.members.length} أعضاء',
        child: Row(
          children: [
            AhdashClubBadge(
              label: team.badgeSeed,
              colorHex: team.primaryColor,
              size: 64,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (team.description?.trim().isNotEmpty == true)
                    Text(
                      team.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text('${team.members.length} أعضاء'),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _TeamActions(team: team),
      const SizedBox(height: 16),
      const Text(
        'الأعضاء',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: team.members.isEmpty
            ? const Center(child: Text('لا توجد عضويات متاحة للعرض.'))
            : ListView.separated(
                key: const ValueKey('team-real-members'),
                itemCount: team.members.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final member = team.members[index];
                  return SocialPlayerRow(
                    displayName: member.displayName,
                    avatarUrl: member.avatarUrl,
                    badge: _roleLabel(member.role),
                  );
                },
              ),
      ),
    ],
  );
}

final class _TeamActions extends ConsumerStatefulWidget {
  const _TeamActions({required this.team});

  final SocialTeamDetail team;

  @override
  ConsumerState<_TeamActions> createState() => _TeamActionsState();
}

final class _TeamActionsState extends ConsumerState<_TeamActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (widget.team.canManage)
        OutlinedButton.icon(
          onPressed: _busy ? null : _rotateCode,
          icon: const Icon(Icons.vpn_key_outlined),
          label: const Text('رمز دعوة جديد'),
        ),
      OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () => context.push('/friends?teamId=${widget.team.id}'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('دعوة صديق'),
      ),
      if (widget.team.currentRole != 'owner')
        TextButton.icon(
          onPressed: _busy ? null : _leave,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('مغادرة الفريق'),
        ),
    ],
  );

  Future<void> _rotateCode() async {
    setState(() => _busy = true);
    try {
      final code = await ref
          .read(socialRepositoryProvider)
          .rotateInviteCode(widget.team.id);
      if (!mounted) return;
      final copied = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('رمز الدعوة'),
          content: SelectableText(code, textDirection: TextDirection.ltr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('إغلاق'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('نسخ'),
            ),
          ],
        ),
      );
      if (copied == true) {
        await Clipboard.setData(ClipboardData(text: code));
        if (mounted) showAhdashSnackbar(context, 'تم نسخ الرمز.');
      }
    } catch (_) {
      if (mounted) showAhdashSnackbar(context, 'تعذر إنشاء رمز دعوة جديد.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(socialRepositoryProvider)
          .removeTeamMember(widget.team.id, widget.team.currentUserId);
      ref.invalidate(socialHubProvider);
      if (mounted) context.go('/teams');
    } catch (_) {
      if (mounted) showAhdashSnackbar(context, 'تعذر مغادرة الفريق.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

String _roleLabel(String role) => switch (role) {
  'owner' => 'المالك',
  'admin' => 'قائد',
  _ => 'عضو',
};
