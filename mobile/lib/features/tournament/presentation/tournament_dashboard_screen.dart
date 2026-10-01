import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../data/tournament_registration_repository.dart';
import '../domain/tournament.dart';
import 'tournament_controller.dart';
import 'tournament_flow.dart';

final class TournamentDashboardScreen extends ConsumerStatefulWidget {
  const TournamentDashboardScreen({super.key});

  @override
  ConsumerState<TournamentDashboardScreen> createState() =>
      _TournamentDashboardScreenState();
}

final class _TournamentDashboardScreenState
    extends ConsumerState<TournamentDashboardScreen> {
  final _availableSearchController = TextEditingController();
  String _availableQuery = '';
  _TournamentListFilter _mineFilter = _TournamentListFilter.all;

  @override
  void dispose() {
    _availableSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(tournamentControllerProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tournamentState = ref.watch(tournamentControllerProvider);
    final mine = ref.watch(myTournamentEntriesProvider);
    final available = ref.watch(availableTournamentsProvider);
    final mineEntries = mine.asData?.value ?? const <MyTournamentEntry>[];
    final availableEntries =
        available.asData?.value ?? const <AvailableTournament>[];
    final pendingCount = mineEntries.where((entry) => entry.isPending).length;
    final activeEntriesCount = mineEntries
        .where((entry) => !entry.isPending && !entry.isCompleted)
        .length;
    final completedCount = mineEntries
        .where((entry) => entry.isCompleted)
        .length;
    final filteredAvailable = _filterAvailable(availableEntries);
    return AhdashV10Page(
      title: 'البطولات',
      subtitle: 'أنشئ، انضم، وتابع طريقك إلى الكأس من مكان واحد',
      onBack: () => context.go('/home'),
      actions: [
        IconButton.outlined(
          tooltip: 'تحديث البطولات',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.ink,
        backgroundColor: AppColors.primary,
        child: ListView(
          key: const ValueKey('tournament-dashboard-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            bottom: AhdashSizing.floatingDockContentInset,
          ),
          children: [
            _TournamentCommandHero(
              active: tournamentState.active,
              joinedCount: mine.value?.length ?? tournamentState.history.length,
              onCreate: () => context.push('/tournaments/create'),
              onJoin: () => context.push('/tournaments/join'),
            ),
            const SizedBox(height: 12),
            _TournamentPulseRow(
              activeCount: activeEntriesCount > 0
                  ? activeEntriesCount
                  : (tournamentState.active == null ? 0 : 1),
              pendingCount: pendingCount,
              completedCount: completedCount,
            ),
            const SizedBox(height: 22),
            _SectionHeader(
              title: 'بطولاتك',
              subtitle: 'المشاركة الحالية وسجل طلباتك',
              icon: Icons.shield_rounded,
            ),
            const SizedBox(height: 10),
            _TournamentFilterBar(
              selected: _mineFilter,
              onChanged: (value) => setState(() => _mineFilter = value),
            ),
            const SizedBox(height: 8),
            if (!tournamentState.restored)
              const _DashboardLoadingCard(label: 'نستعيد آخر بطولة…')
            else if (tournamentState.active != null && _mineFilter.showsActive)
              _ActiveTournamentDashboardCard(
                tournament: tournamentState.active!,
                onOpen: () => context.push(
                  TournamentFlowResolver.routeFor(tournamentState),
                ),
                onCopyInvite: tournamentState.active!.inviteCode == null
                    ? null
                    : () =>
                          _copyInviteCode(tournamentState.active!.inviteCode!),
              ),
            if (tournamentState.error != null) ...[
              const SizedBox(height: 8),
              _InlineNotice(
                icon: Icons.cloud_off_rounded,
                text: tournamentState.error!,
              ),
            ],
            mine.when(
              loading: () => tournamentState.active == null
                  ? const _DashboardLoadingCard(label: 'نحمّل مشاركاتك…')
                  : const SizedBox.shrink(),
              error: (_, _) => tournamentState.active == null
                  ? const _InlineNotice(
                      icon: Icons.sync_problem_rounded,
                      text: 'تعذر تحميل مشاركاتك من الخادم الآن.',
                    )
                  : const SizedBox.shrink(),
              data: (entries) {
                final visible = _filterMine(entries)
                    .where((entry) => entry.id != tournamentState.active?.id)
                    .take(4)
                    .toList(growable: false);
                if (visible.isEmpty &&
                    (tournamentState.active == null ||
                        !_mineFilter.showsActive)) {
                  return _EmptyMyTournaments(filter: _mineFilter);
                }
                return Column(
                  children: [
                    for (final entry in visible) ...[
                      const SizedBox(height: 8),
                      _MyTournamentCard(
                        entry: entry,
                        onOpen: () => _openRemote(entry.id),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'بطولات مفتوحة',
              subtitle: 'اختر بطولة عامة أو استخدم رمز دعوة',
              icon: Icons.public_rounded,
            ),
            const SizedBox(height: 10),
            if (availableEntries.isNotEmpty) ...[
              _TournamentSearchField(
                controller: _availableSearchController,
                onChanged: (value) => setState(() => _availableQuery = value),
                onClear: () {
                  _availableSearchController.clear();
                  setState(() => _availableQuery = '');
                },
              ),
              const SizedBox(height: 10),
            ],
            available.when(
              loading: () =>
                  const _DashboardLoadingCard(label: 'نبحث عن بطولات متاحة…'),
              error: (_, _) => _AvailableFallback(
                onJoin: () => context.push('/tournaments/join'),
              ),
              data: (tournaments) => tournaments.isEmpty
                  ? _AvailableFallback(
                      onJoin: () => context.push('/tournaments/join'),
                    )
                  : filteredAvailable.isEmpty
                  ? _NoTournamentSearchResults(
                      query: _availableQuery,
                      onClear: () {
                        _availableSearchController.clear();
                        setState(() => _availableQuery = '');
                      },
                    )
                  : SizedBox(
                      height: 156,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredAvailable.length.clamp(0, 8).toInt(),
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final tournament = filteredAvailable[index];
                          return _AvailableTournamentCard(
                            tournament: tournament,
                            onJoin: () => context.push(
                              tournament.inviteCode == null
                                  ? '/tournaments/join'
                                  : '/tournaments/join?code=${Uri.encodeQueryComponent(tournament.inviteCode!)}&players=${tournament.playersPerTeam}',
                            ),
                            onCopyCode: tournament.inviteCode == null
                                ? null
                                : () => _copyInviteCode(tournament.inviteCode!),
                          );
                        },
                      ),
                    ),
            ),
            if (tournamentState.history.isNotEmpty) ...[
              const SizedBox(height: 22),
              const _SectionHeader(
                title: 'أرشيفك المحلي',
                subtitle: 'آخر البطولات المكتملة على هذا الجهاز',
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 10),
              for (final tournament in tournamentState.history.take(3)) ...[
                _HistoryTournamentCard(tournament: tournament),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 18),
            _TournamentDetailsStrip(
              onHowTo: () => context.push('/how-to-play'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(myTournamentEntriesProvider);
    ref.invalidate(availableTournamentsProvider);
    await ref.read(tournamentControllerProvider.notifier).refresh();
  }

  List<MyTournamentEntry> _filterMine(List<MyTournamentEntry> entries) {
    return switch (_mineFilter) {
      _TournamentListFilter.all => entries,
      _TournamentListFilter.active =>
        entries
            .where((entry) => !entry.isCompleted && !entry.isPending)
            .toList(growable: false),
      _TournamentListFilter.pending =>
        entries.where((entry) => entry.isPending).toList(growable: false),
      _TournamentListFilter.completed =>
        entries.where((entry) => entry.isCompleted).toList(growable: false),
    };
  }

  List<AvailableTournament> _filterAvailable(
    List<AvailableTournament> entries,
  ) {
    final query = _availableQuery.trim().toLowerCase();
    if (query.isEmpty) return entries;
    return entries
        .where(
          (entry) =>
              entry.name.toLowerCase().contains(query) ||
              (entry.inviteCode?.toLowerCase().contains(query) ?? false),
        )
        .toList(growable: false);
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('تم نسخ رمز البطولة: $code'),
          action: SnackBarAction(
            label: 'انضمام',
            onPressed: () => context.push(
              '/tournaments/join?code=${Uri.encodeQueryComponent(code)}',
            ),
          ),
        ),
      );
  }

  Future<void> _openRemote(String id) async {
    final loaded = await ref
        .read(tournamentControllerProvider.notifier)
        .refresh(tournamentId: id);
    if (!mounted) return;
    if (loaded) {
      context.go(
        TournamentFlowResolver.routeFor(ref.read(tournamentControllerProvider)),
      );
    }
  }
}

final class _TournamentCommandHero extends StatelessWidget {
  const _TournamentCommandHero({
    required this.active,
    required this.joinedCount,
    required this.onCreate,
    required this.onJoin,
  });

  final Tournament? active;
  final int joinedCount;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    return Container(
      key: const ValueKey('tournament-command-hero'),
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF25231F), AppColors.ink],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29191714),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.ink, width: 1.1),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.ink,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الكأس يبدأ بقرار',
                      style: TextStyle(
                        color: AppColors.paper0,
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اصنع بطولة لربعك أو ادخل المنافسة برمز واحد.',
                      style: TextStyle(
                        color: AppColors.paper3,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroMetric(value: active == null ? '—' : '1', label: 'نشطة'),
              const SizedBox(width: 8),
              _HeroMetric(value: '$joinedCount', label: 'مشاركة'),
              const SizedBox(width: 8),
              const _HeroMetric(value: 'KO', label: 'خروج مغلوب'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('tournament-dashboard-create'),
                  onPressed: onCreate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.ink, width: 1.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('إنشاء بطولة'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('tournament-dashboard-join'),
                  onPressed: onJoin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.paper0,
                    backgroundColor: Colors.white.withValues(alpha: .06),
                    side: BorderSide(
                      color: AppColors.paper3.withValues(alpha: .72),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: const Text('انضم برمز'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.paper3, fontSize: 9),
          ),
        ],
      ),
    ),
  );
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .52),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .8)),
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _ActiveTournamentDashboardCard extends StatelessWidget {
  const _ActiveTournamentDashboardCard({
    required this.tournament,
    required this.onOpen,
    this.onCopyInvite,
  });
  final Tournament tournament;
  final VoidCallback onOpen;
  final VoidCallback? onCopyInvite;

  @override
  Widget build(BuildContext context) {
    final filled = tournament.teams.length;
    final capacity = tournament.rules.capacity;
    final progress = capacity == 0
        ? 0.0
        : (filled / capacity).clamp(0, 1).toDouble();
    return AhdashV10Panel(
      onTap: onOpen,
      semanticLabel: 'فتح بطولة ${tournament.name}',
      backgroundColor: AppColors.paper1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.palm),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tournament.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(label: _tournamentStatusLabel(tournament.status)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.paper2,
              color: AppColors.palm,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$filled من $capacity فرق',
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (onCopyInvite != null)
                IconButton(
                  tooltip: 'نسخ رمز الدعوة',
                  onPressed: onCopyInvite,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_rounded, size: 17),
                ),
              const Text(
                'متابعة البطولة',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_back_rounded, size: 17),
            ],
          ),
          if (tournament.inviteCode != null) ...[
            const SizedBox(height: 4),
            Text(
              'رمز الدعوة: ${tournament.inviteCode}',
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _MyTournamentCard extends StatelessWidget {
  const _MyTournamentCard({required this.entry, required this.onOpen});
  final MyTournamentEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => AhdashV10Panel(
    onTap: entry.isPending ? null : onOpen,
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: entry.isPending ? AppColors.paper2 : AppColors.ink,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            entry.isPending ? Icons.hourglass_top_rounded : Icons.flag_rounded,
            color: entry.isPending ? AppColors.ink : AppColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                entry.teamName?.isNotEmpty == true
                    ? '${entry.teamName} · ${entry.capacity} فرق${_createdDateSuffix(entry.createdAt)}'
                    : '${entry.capacity} فرق${_createdDateSuffix(entry.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        _StatusPill(
          label: entry.isPending
              ? 'بانتظار القبول'
              : entry.isRejected
              ? 'مرفوضة'
              : _serverStatusLabel(entry.tournamentStatus),
        ),
      ],
    ),
  );
}

final class _AvailableTournamentCard extends StatelessWidget {
  const _AvailableTournamentCard({
    required this.tournament,
    required this.onJoin,
    this.onCopyCode,
  });
  final AvailableTournament tournament;
  final VoidCallback onJoin;
  final VoidCallback? onCopyCode;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 218,
    child: AhdashV10Panel(
      onTap: onJoin,
      backgroundColor: AppColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.public_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              if (onCopyCode != null)
                IconButton(
                  tooltip: 'نسخ الرمز',
                  onPressed: onCopyCode,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                  color: AppColors.paper0,
                  icon: const Icon(Icons.copy_rounded, size: 15),
                ),
              const Spacer(),
              Text(
                '${tournament.capacity} فرق',
                style: const TextStyle(color: AppColors.paper3, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          Text(
            tournament.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.paper0,
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${tournament.playersPerTeam} لاعبين لكل فريق',
            style: const TextStyle(color: AppColors.paper3, fontSize: 10),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Text(
                'تسجيل الفريق',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

final class _HistoryTournamentCard extends StatelessWidget {
  const _HistoryTournamentCard({required this.tournament});
  final Tournament tournament;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Row(
      children: [
        const Icon(Icons.workspace_premium_rounded, color: AppColors.coffee),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            tournament.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          '${tournament.teams.length} فرق',
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 10),
        ),
      ],
    ),
  );
}

final class _AvailableFallback extends StatelessWidget {
  const _AvailableFallback({required this.onJoin});
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) => AhdashV10Panel(
    onTap: onJoin,
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.key_rounded, color: AppColors.ink),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'معك رمز دعوة؟',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              Text(
                'أدخله وسجّل فريقك مباشرة.',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_back_rounded, size: 19),
      ],
    ),
  );
}

final class _EmptyMyTournaments extends StatelessWidget {
  const _EmptyMyTournaments({required this.filter});

  final _TournamentListFilter filter;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Row(
      children: [
        const Icon(Icons.emoji_events_outlined, color: AppColors.inkMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            filter == _TournamentListFilter.all
                ? 'لا توجد مشاركة بعد. أنشئ بطولة أو انضم برمز.'
                : 'لا توجد بطولات ضمن هذا التصنيف حتى الآن.',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

enum _TournamentListFilter { all, active, pending, completed }

extension on _TournamentListFilter {
  bool get showsActive =>
      this == _TournamentListFilter.all || this == _TournamentListFilter.active;

  String get label => switch (this) {
    _TournamentListFilter.all => 'الكل',
    _TournamentListFilter.active => 'نشطة',
    _TournamentListFilter.pending => 'بانتظار القبول',
    _TournamentListFilter.completed => 'مكتملة',
  };
}

final class _TournamentFilterBar extends StatelessWidget {
  const _TournamentFilterBar({required this.selected, required this.onChanged});

  final _TournamentListFilter selected;
  final ValueChanged<_TournamentListFilter> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final filter in _TournamentListFilter.values) ...[
          ChoiceChip(
            label: Text(filter.label),
            selected: selected == filter,
            onSelected: (_) => onChanged(filter),
            avatar: Icon(switch (filter) {
              _TournamentListFilter.all => Icons.grid_view_rounded,
              _TournamentListFilter.active => Icons.bolt_rounded,
              _TournamentListFilter.pending => Icons.hourglass_top_rounded,
              _TournamentListFilter.completed => Icons.check_circle_rounded,
            }, size: 15),
          ),
          const SizedBox(width: 7),
        ],
      ],
    ),
  );
}

final class _TournamentSearchField extends StatelessWidget {
  const _TournamentSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey('tournament-search'),
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'ابحث باسم البطولة أو رمز الدعوة',
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'مسح البحث',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
    ),
  );
}

final class _NoTournamentSearchResults extends StatelessWidget {
  const _NoTournamentSearchResults({
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => AhdashV10Panel(
    child: Row(
      children: [
        const Icon(Icons.search_off_rounded, color: AppColors.inkMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'لا توجد بطولة تطابق “$query”.',
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
          ),
        ),
        TextButton(onPressed: onClear, child: const Text('مسح')),
      ],
    ),
  );
}

final class _TournamentPulseRow extends StatelessWidget {
  const _TournamentPulseRow({
    required this.activeCount,
    required this.pendingCount,
    required this.completedCount,
  });

  final int activeCount;
  final int pendingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _TournamentPulse(
        icon: Icons.bolt_rounded,
        value: '$activeCount',
        label: 'نشطة',
        color: AppColors.palm,
      ),
      const SizedBox(width: 8),
      _TournamentPulse(
        icon: Icons.hourglass_top_rounded,
        value: '$pendingCount',
        label: 'بانتظار',
        color: AppColors.coffee,
      ),
      const SizedBox(width: 8),
      _TournamentPulse(
        icon: Icons.verified_rounded,
        value: '$completedCount',
        label: 'منتهية',
        color: AppColors.ink,
      ),
    ],
  );
}

final class _TournamentPulse extends StatelessWidget {
  const _TournamentPulse({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .42),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .78)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12191714),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

final class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

final class _TournamentDetailsStrip extends StatelessWidget {
  const _TournamentDetailsStrip({required this.onHowTo});
  final VoidCallback onHowTo;

  @override
  Widget build(BuildContext context) => AhdashV10Panel(
    onTap: onHowTo,
    backgroundColor: AppColors.paper2,
    child: const Row(
      children: [
        Icon(Icons.rule_rounded, color: AppColors.palm),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'كل تفاصيل المنافسة',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              Text(
                'القرعة، النتائج، قبول الفرق وطريق البطل.',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_back_rounded, size: 18),
      ],
    ),
  );
}

final class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

String _tournamentStatusLabel(TournamentStatus status) => switch (status) {
  TournamentStatus.draft => 'تجهيز',
  TournamentStatus.registration => 'التسجيل مفتوح',
  TournamentStatus.ready => 'جاهزة',
  TournamentStatus.live => 'جارية',
  TournamentStatus.completed => 'مكتملة',
  TournamentStatus.cancelled => 'ملغاة',
};

String _serverStatusLabel(String status) => switch (status) {
  'draft' => 'تجهيز',
  'registration' => 'التسجيل مفتوح',
  'ready' => 'جاهزة',
  'live' => 'جارية',
  'completed' => 'مكتملة',
  'cancelled' => 'ملغاة',
  _ => 'مشاركة',
};

String _createdDateSuffix(DateTime? createdAt) {
  if (createdAt == null) return '';
  final date = createdAt.toLocal();
  return ' · ${date.day}/${date.month}/${date.year}';
}
