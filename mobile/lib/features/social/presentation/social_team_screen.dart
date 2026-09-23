import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> refresh() async {
      try {
        ref.invalidate(socialTeamDetailProvider(teamId));
        await ref.read(socialTeamDetailProvider(teamId).future);
      } catch (_) {
        // The provider renders the localized retry state below.
      }
    }

    final state = ref.watch(socialTeamDetailProvider(teamId));
    return AhdashV10Page(
      title: 'تفاصيل الفريق',
      subtitle: 'هويتكم، أعضاؤكم، ودعواتكم',
      onBack: () => context.canPop() ? context.pop() : context.go('/teams'),
      child: RefreshIndicator(
        onRefresh: refresh,
        child: state.when(
          loading: () => const _TeamLoading(),
          error: (_, _) => _TeamLoadError(onRetry: refresh),
          data: (team) => _TeamBody(team: team, onRefresh: refresh),
        ),
      ),
    );
  }
}

final class _TeamLoading extends StatelessWidget {
  const _TeamLoading();

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('team-detail-loading'),
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      Semantics(
        label: 'جارٍ تحميل تفاصيل الفريق',
        liveRegion: true,
        child: LoadingSkeleton(lines: 4, lineHeight: 82),
      ),
    ],
  );
}

final class _TeamLoadError extends StatelessWidget {
  const _TeamLoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('team-detail-error'),
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(
        height: 460,
        child: AppMessageState(
          icon: Icons.groups_3_outlined,
          title: 'تعذر فتح الفريق',
          message: 'تحقق من الاتصال، ثم حاول تحميل بيانات الفريق مجددًا.',
          actionLabel: 'إعادة المحاولة',
          onAction: onRetry,
        ),
      ),
    ],
  );
}

final class _TeamBody extends StatelessWidget {
  const _TeamBody({required this.team, required this.onRefresh});

  final SocialTeamDetail team;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final weeklyPoints = team.members.fold<int>(
      0,
      (total, member) => total + member.weeklyPoints,
    );
    return CustomScrollView(
      key: const ValueKey('team-detail-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _TeamIdentityHero(team: team, weeklyPoints: weeklyPoints),
        ),
        if (team.weeklyMvp case final member?) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _WeeklyMvpPanel(member: member)),
        ],
        if (team.canManage) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _TeamActions(team: team)),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 10),
            child: _RosterHeader(
              count: team.members.length,
              onRefresh: onRefresh,
            ),
          ),
        ),
        if (team.members.isEmpty)
          const SliverToBoxAdapter(child: _EmptyRoster())
        else
          SliverList.separated(
            itemCount: team.members.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (_, index) {
              final member = team.members[index];
              final details = <String>[
                if (member.level > 0) 'مستوى ${member.level}',
                if (member.weeklyPoints > 0)
                  '${member.weeklyPoints} نقطة هذا الأسبوع',
              ];
              return SocialPlayerRow(
                key: ValueKey('team-member-${member.userId}'),
                displayName: member.displayName,
                avatarUrl: member.avatarUrl,
                badge: _roleLabel(member.role),
                subtitle: details.isEmpty
                    ? 'عضو في الفريق'
                    : details.join('  •  '),
                highlighted: member.userId == team.currentUserId,
                trailing: member.rank > 0
                    ? _MemberRank(rank: member.rank)
                    : null,
              );
            },
          ),
        if (team.currentRole != 'owner') ...[
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(child: _LeaveTeamAction(team: team)),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

final class _TeamIdentityHero extends StatelessWidget {
  const _TeamIdentityHero({required this.team, required this.weeklyPoints});

  final SocialTeamDetail team;
  final int weeklyPoints;

  @override
  Widget build(BuildContext context) {
    final role = _roleLabel(team.currentRole);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final teamColor = ahdashHexColor(
      team.primaryColor,
      fallback: AppColors.palm,
    );
    final artwork = Image.asset(
      'assets/visuals/team_identity_huddle_v1.png',
      key: const ValueKey('team-identity-artwork'),
      width: largeText ? 112 : 96,
      height: largeText ? 112 : 96,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.medium,
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'فريقك الحالي',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _RolePill(label: role),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          team.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.paper0,
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (team.description?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 5),
          Text(
            team.description!.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD6DED7),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
    return Semantics(
      container: true,
      label:
          'فريق ${team.name}، ${team.members.length} أعضاء، دورك $role، $weeklyPoints نقطة هذا الأسبوع',
      child: Container(
        key: const ValueKey('team-identity-hero'),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0, .55, 1],
            colors: [Color(0xFF234A38), Color(0xFF183126), Color(0xFF111713)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF345746)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            PositionedDirectional(
              top: -72,
              end: -56,
              width: 224,
              height: 224,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      teamColor.withValues(alpha: .28),
                      teamColor.withValues(alpha: .08),
                      Colors.transparent,
                    ],
                    stops: const [0, .48, 1],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 0,
              start: 42,
              end: 42,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      teamColor.withValues(alpha: .62),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            const PositionedDirectional(
              top: 20,
              bottom: 20,
              start: 0,
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadiusDirectional.horizontal(
                    end: Radius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (largeText) ...[
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: artwork,
                    ),
                    const SizedBox(height: 8),
                    copy,
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: copy),
                        const SizedBox(width: 14),
                        artwork,
                      ],
                    ),
                  const SizedBox(height: 15),
                  Container(
                    height: 1,
                    color: AppColors.paper0.withValues(alpha: .13),
                  ),
                  const SizedBox(height: 12),
                  _TeamMetrics(
                    members: team.members.length,
                    weeklyPoints: weeklyPoints,
                    challenges: team.challenges.length,
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

final class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.paper0.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.paper0.withValues(alpha: .22)),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: const TextStyle(
        color: AppColors.paper0,
        fontSize: 9,
        height: 1,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

final class _TeamMetrics extends StatelessWidget {
  const _TeamMetrics({
    required this.members,
    required this.weeklyPoints,
    required this.challenges,
  });

  final int members;
  final int weeklyPoints;
  final int challenges;

  @override
  Widget build(BuildContext context) {
    final items = [
      _TeamMetric(value: '$members', label: 'الأعضاء'),
      _TeamMetric(value: '$weeklyPoints', label: 'نقاط الأسبوع'),
      _TeamMetric(value: '$challenges', label: 'التحديات'),
    ];
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    if (largeText) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items) SizedBox(width: width, child: item),
            ],
          );
        },
      );
    }
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: items[i]),
        ],
      ],
    );
  }
}

final class _TeamMetric extends StatelessWidget {
  const _TeamMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.paper0.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.paper0.withValues(alpha: .13)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFD2DBD4),
            fontSize: 9,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

final class _WeeklyMvpPanel extends StatelessWidget {
  const _WeeklyMvpPanel({required this.member});

  final SocialTeamMember member;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('team-weekly-mvp'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1C8),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE6C06A)),
    ),
    child: Row(
      children: [
        AhdashPlayer11Avatar(imageUrl: member.avatarUrl, size: 48),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نجم الأسبوع',
                style: TextStyle(
                  color: AppColors.coffee,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                member.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.coffee,
            ),
            Text(
              '${member.weeklyPoints} نقطة',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    ),
  );
}

final class _RosterHeader extends StatelessWidget {
  const _RosterHeader({required this.count, required this.onRefresh});

  final int count;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تشكيلة الفريق',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 2),
            Text(
              'الأدوار والنشاط الأسبوعي',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.paper1,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Text(
          '$count',
          semanticsLabel: '$count أعضاء',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
      const SizedBox(width: 6),
      IconButton(
        key: const ValueKey('team-refresh-button'),
        tooltip: 'تحديث بيانات الفريق',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded, size: 20),
      ),
    ],
  );
}

final class _MemberRank extends StatelessWidget {
  const _MemberRank({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: rank == 1 ? AppColors.primary : AppColors.paper1,
      shape: BoxShape.circle,
      border: Border.all(color: rank == 1 ? AppColors.ink : AppColors.hairline),
    ),
    child: Text(
      '#$rank',
      textDirection: TextDirection.ltr,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );
}

final class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('team-empty-roster'),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.hairline),
    ),
    child: const Column(
      children: [
        Icon(Icons.group_add_outlined, size: 46, color: AppColors.palm),
        SizedBox(height: 12),
        Text(
          'الفريق ينتظر تشكيلته',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 5),
        Text(
          'استخدم الدعوة لإضافة أول عضو إلى الفريق.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.inkMuted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    ),
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
  Widget build(BuildContext context) {
    final rotate = OutlinedButton.icon(
      key: const ValueKey('team-rotate-code'),
      onPressed: _busy ? null : _rotateCode,
      icon: _busy
          ? const SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.key_rounded, size: 18),
      label: const Text('تجديد الرمز'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
    return Container(
      key: const ValueKey('team-invite-panel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.stadium_outlined, size: 22, color: AppColors.palm),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رمز الانضمام',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'أنشئ رمزًا جديدًا وشاركه مع لاعبي الفريق.',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          rotate,
        ],
      ),
    );
  }

  Future<void> _rotateCode() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final code = await ref
          .read(socialRepositoryProvider)
          .rotateInviteCode(widget.team.id);
      if (!mounted) return;
      final copied = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('رمز الدعوة الجديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'شارك هذا الرمز مع من تريد ضمّه إلى الفريق.',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Container(
                key: const ValueKey('team-invite-code-value'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paper1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: SelectableText(
                  code,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 20,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('إغلاق'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialog, true),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('نسخ الرمز'),
            ),
          ],
        ),
      );
      if (copied == true) {
        await Clipboard.setData(ClipboardData(text: code));
        if (mounted) showAhdashSnackbar(context, 'تم نسخ رمز الدعوة.');
      }
    } catch (_) {
      if (mounted) showAhdashSnackbar(context, 'تعذر إنشاء رمز دعوة جديد.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

final class _LeaveTeamAction extends ConsumerStatefulWidget {
  const _LeaveTeamAction({required this.team});

  final SocialTeamDetail team;

  @override
  ConsumerState<_LeaveTeamAction> createState() => _LeaveTeamActionState();
}

final class _LeaveTeamActionState extends ConsumerState<_LeaveTeamAction> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'مغادرة فريق ${widget.team.name}',
    button: true,
    child: TextButton.icon(
      key: const ValueKey('team-leave-button'),
      onPressed: _busy ? null : _confirmLeave,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: _busy
          ? const SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout_rounded, size: 18),
      label: Text(_busy ? 'جارٍ مغادرة الفريق…' : 'مغادرة الفريق'),
    ),
  );

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('مغادرة الفريق؟'),
        content: Text(
          'ستغادر فريق ${widget.team.name}. يمكنك الانضمام مجددًا بدعوة جديدة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('البقاء'),
          ),
          FilledButton(
            key: const ValueKey('team-confirm-leave'),
            onPressed: () => Navigator.pop(dialog, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
