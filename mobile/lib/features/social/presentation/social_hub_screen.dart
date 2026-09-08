import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/app_shell.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/brand_identity.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../../shared/presentation/landscape_layout.dart';
import '../../../shared/presentation/social_identity.dart';
import '../data/social_repository.dart';
import '../domain/social_entities.dart';

final class SocialHubScreen extends ConsumerWidget {
  const SocialHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(socialHubProvider);
    final metrics = LandscapeMetrics.of(context);
    final portrait =
        MediaQuery.sizeOf(context).height > MediaQuery.sizeOf(context).width;
    return AppShell(
      index: 2,
      child: AhdashGameWorld(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(metrics.gutter),
            child: hub.when(
              loading: () => const Center(child: ElevenLoader(size: 42)),
              error: (_, _) => AppMessageState(
                icon: Icons.groups_3_outlined,
                title: 'تعذر تحميل الفِرق',
                message: 'تحقق من اتصالك ثم حاول مجددًا.',
                actionLabel: 'إعادة المحاولة',
                onAction: () => ref.invalidate(socialHubProvider),
              ),
              data: (value) {
                final title = CompactSectionTitle(
                  eyebrow: 'مساحة لعب خاصة',
                  title: value.team?.name ?? 'الفِرق',
                  trailing: Row(
                    children: [
                      IconButton(
                        tooltip: 'تحديث',
                        onPressed: () => ref.invalidate(socialHubProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => context.push('/friends'),
                        icon: const Icon(Icons.people_alt_outlined),
                        label: const Text('ربعك'),
                      ),
                    ],
                  ),
                );
                if (portrait) {
                  return Column(
                    children: [
                      title,
                      SizedBox(height: metrics.panelGap),
                      Expanded(
                        child: ListView(
                          children: [
                            SizedBox(
                              height: 300,
                              child: _SocialHero(
                                team: value.team,
                                compact: false,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              height: 360,
                              child: value.team == null
                                  ? const _NoTeamActions()
                                  : _TeamCard(
                                      team: value.team!,
                                      compact: false,
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              height: 300,
                              child: _InvitesAndPrivacy(
                                invites: value.invites,
                                compact: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return AccessibilityViewport(
                  child: Column(
                    children: [
                      title,
                      SizedBox(height: metrics.panelGap),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _SocialHero(
                                team: value.team,
                                compact: metrics.compact,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 4,
                              child: value.team == null
                                  ? const _NoTeamActions()
                                  : _TeamCard(
                                      team: value.team!,
                                      compact: metrics.compact,
                                    ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 3,
                              child: _InvitesAndPrivacy(
                                invites: value.invites,
                                compact: metrics.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _SocialHero extends StatelessWidget {
  const _SocialHero({required this.team, required this.compact});

  final SocialTeamSummary? team;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      tone: GameSurfaceTone.raised,
      padding: EdgeInsets.all(compact ? 8 : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              AhdashBrandLogo.mark(height: compact ? 28 : 48),
              const Spacer(),
              const AhdashBadge(label: 'خاص • بدعوة'),
            ],
          ),
          const Spacer(),
          AhdashIcon(
            AhdashGlyph.teams,
            size: compact ? 38 : 68,
            color: context.ahdashColors.primary,
            active: true,
          ),
          SizedBox(height: compact ? 2 : AppSpacing.sm),
          Text(
            team == null ? 'جمّع ربعك\nوالعبوا سوا' : 'فريقك\n${team!.name}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: compact
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.headlineLarge,
          ),
          SizedBox(height: compact ? 2 : AppSpacing.xs),
          Text(
            'تحديات كروية، ترتيب مشترك، وحضور يمثلكم.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.ahdashColors.textMuted,
              fontSize: compact ? 10 : null,
            ),
          ),
          const Spacer(),
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'لا استكشاف عام ولا دردشة مفتوحة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.compact});

  final SocialTeamSummary team;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      tone: GameSurfaceTone.selected,
      onTap: () => context.push('/teams/${team.id}'),
      selected: true,
      padding: EdgeInsets.all(compact ? 8 : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AhdashClubBadge(
                label: team.badgeSeed,
                colorHex: team.primaryColor,
                size: compact ? 38 : 62,
              ),
              SizedBox(width: compact ? 6 : AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${_roleLabel(team.role)} • ${team.memberCount} أعضاء',
                    ),
                    if (team.activeChallenges > 0)
                      Text(
                        '${team.activeChallenges} تحديات متاحة',
                        style: TextStyle(
                          color: context.ahdashColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
            ],
          ),
          const Spacer(),
          _TeamMetric(value: '${team.memberCount}', label: 'الأعضاء'),
          SizedBox(height: compact ? 3 : AppSpacing.sm),
          _TeamMetric(value: '${team.activeChallenges}', label: 'تحديات متاحة'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/teams/${team.id}'),
              icon: const Icon(Icons.sports_esports_rounded),
              label: const Text('افتح مساحة الفريق'),
            ),
          ),
        ],
      ),
    );
  }
}

final class _TeamMetric extends StatelessWidget {
  const _TeamMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => GamePanel(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

final class _InvitesAndPrivacy extends StatelessWidget {
  const _InvitesAndPrivacy({required this.invites, required this.compact});
  final List<SocialTeamInvite> invites;
  final bool compact;

  @override
  Widget build(BuildContext context) => GamePanel(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompactSectionTitle(
          title: invites.isEmpty ? 'الخصوصية' : 'دعواتك',
          eyebrow: invites.isEmpty ? 'تحت تحكمك' : '${invites.length} بانتظارك',
        ),
        SizedBox(height: compact ? 2 : AppSpacing.sm),
        if (invites.isNotEmpty)
          Expanded(
            child: PageView.builder(
              itemCount: invites.length,
              itemBuilder: (context, index) =>
                  Center(child: _InviteCard(invite: invites[index])),
            ),
          )
        else
          const Expanded(
            child: Center(child: Icon(Icons.lock_outline_rounded, size: 46)),
          ),
        Text(
          invites.isEmpty
              ? 'الانضمام بدعوة أو رمز فقط. لا يوجد ظهور لحظي.'
              : 'مرّر أفقيًا لعرض بقية الدعوات.',
          maxLines: 2,
          style: TextStyle(color: context.ahdashColors.textMuted, fontSize: 11),
        ),
      ],
    ),
  );
}

final class _InviteCard extends ConsumerStatefulWidget {
  const _InviteCard({required this.invite});

  final SocialTeamInvite invite;

  @override
  ConsumerState<_InviteCard> createState() => _InviteCardState();
}

final class _InviteCardState extends ConsumerState<_InviteCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 280;
        final identity = Row(
          children: [
            AhdashClubBadge(
              label: widget.invite.badgeSeed,
              colorHex: widget.invite.primaryColor,
              size: narrow ? 30 : 44,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.invite.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'من ${widget.invite.invitedByName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        );
        final actions = Row(
          children: [
            IconButton(
              tooltip: 'رفض',
              visualDensity: VisualDensity.compact,
              onPressed: _busy ? null : () => _respond(false),
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _respond(true),
                child: const Text('انضم'),
              ),
            ),
          ],
        );
        return GamePanel(
          padding: EdgeInsets.all(narrow ? 6 : AppSpacing.sm),
          child: narrow
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [identity, const SizedBox(height: 5), actions],
                )
              : Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 5),
                    SizedBox(width: 112, child: actions),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(socialRepositoryProvider)
          .respondInvite(widget.invite.inviteId, accept: accept);
      ref.invalidate(socialHubProvider);
    } catch (_) {
      if (mounted) showAhdashSnackbar(context, 'تعذر تحديث الدعوة.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

final class _NoTeamActions extends ConsumerWidget {
  const _NoTeamActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GamePanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CompactSectionTitle(
            title: 'ابدأ فريقك',
            eyebrow: 'فريق واحد نشط لكل لاعب',
          ),
          const Spacer(),
          const Center(child: AhdashIcon(AhdashGlyph.club, size: 62)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _createTeam(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('أنشئ فريق'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/teams/join'),
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('الانضمام إلى فريق'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createTeam(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final description = TextEditingController();
    var primaryColor = '#B6FF3B';
    var bannerStyle = 'najdi_lines';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('فريق جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  maxLength: 40,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'اسم الفريق'),
                ),
                TextField(
                  controller: description,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'وصف اختياري'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'لون الفريق',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in const <(String, Color)>[
                      ('#B6FF3B', Color(0xFFB6FF3B)),
                      ('#48A9FF', Color(0xFF48A9FF)),
                      ('#FFCB45', Color(0xFFFFCB45)),
                      ('#FF6B6B', Color(0xFFFF6B6B)),
                      ('#B68CFF', Color(0xFFB68CFF)),
                    ])
                      ChoiceChip(
                        selected: primaryColor == entry.$1,
                        showCheckmark: primaryColor == entry.$1,
                        avatar: CircleAvatar(backgroundColor: entry.$2),
                        label: const Text(''),
                        onSelected: (_) =>
                            setDialogState(() => primaryColor = entry.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: bannerStyle,
                  decoration: const InputDecoration(labelText: 'هوية الفريق'),
                  items: const [
                    DropdownMenuItem(
                      value: 'najdi_lines',
                      child: Text('خطوط نجدية'),
                    ),
                    DropdownMenuItem(
                      value: 'desert_dusk',
                      child: Text('غروب الصحراء'),
                    ),
                    DropdownMenuItem(
                      value: 'stadium_night',
                      child: Text('ليلة الملعب'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => bannerStyle = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('تراجع'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || !context.mounted) return;
    try {
      final result = await ref
          .read(socialRepositoryProvider)
          .createTeam(
            name: name.text,
            description: description.text,
            primaryColor: primaryColor,
            bannerStyle: bannerStyle,
          );
      if (!context.mounted) return;
      final inviteCode = '${result['invite_code'] ?? ''}';
      final inviteLink = Uri(
        scheme: 'com.ahdash.eleven',
        host: 'app',
        path: '/teams/join',
        queryParameters: {'code': inviteCode},
      ).toString();
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تم إنشاء الفريق'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('هذا الرمز يظهر الآن فقط. شاركه مع ربعك بشكل خاص.'),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                inviteCode,
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteCode));
                showAhdashSnackbar(context, 'تم نسخ الرمز.');
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ الرمز'),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteLink));
                showAhdashSnackbar(context, 'تم نسخ رابط الدعوة.');
              },
              icon: const Icon(Icons.link_rounded),
              label: const Text('نسخ الرابط'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('تم'),
            ),
          ],
        ),
      );
      ref.invalidate(socialHubProvider);
    } catch (_) {
      if (context.mounted) {
        showAhdashSnackbar(
          context,
          'تعذر إنشاء الفريق. راجع الاسم وحاول مجددًا.',
        );
      }
    }
  }
}

String _roleLabel(String role) => switch (role) {
  'owner' || 'admin' => 'قائد',
  _ => 'عضو',
};
