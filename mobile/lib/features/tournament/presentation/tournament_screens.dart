import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ahdash_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/editorial_v7.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../party/domain/party_game.dart';
import '../../party/domain/party_tournament_context.dart';
import '../../party/presentation/party_game_controller.dart';
import '../data/tournament_registration_repository.dart';
import '../domain/tournament.dart';
import '../domain/tournament_engine.dart';
import 'tournament_controller.dart';
import 'tournament_flow.dart';

final class TournamentHubScreen extends ConsumerStatefulWidget {
  const TournamentHubScreen({super.key});

  @override
  ConsumerState<TournamentHubScreen> createState() =>
      _TournamentHubScreenState();
}

final class _TournamentHubScreenState
    extends ConsumerState<TournamentHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tournamentControllerProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentControllerProvider);
    final active = state.active;
    return _TournamentScaffold(
      title: 'بطولات أحدعش',
      showBack: false,
      child: context.v9Metrics.portrait && active != null && state.restored
          ? _V10TournamentHubBody(
              tournament: active,
              partyMatchId: state.partyMatchId,
              onHistory: () => _showHistory(state.history),
              onRules: () => context.push('/how-to-play'),
            )
          : Column(
              children: [
                if (!state.restored) const LinearProgressIndicator(),
                if (state.error != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.error!,
                          style: TextStyle(color: context.ahdashColors.error),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(tournamentControllerProvider.notifier)
                            .refresh(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: OutlinedButton.icon(
                    onPressed: () => _showHistory(state.history),
                    icon: const Icon(AhdashIcons.forward, size: 17),
                    label: const Text('البطولات السابقة'),
                  ),
                ),
                SizedBox(height: context.v9Metrics.compact ? 6 : 18),
                Expanded(
                  child: !state.restored
                      ? const Center(child: Text('جارٍ استعادة البطولة…'))
                      : active == null
                      ? _TournamentEmptyState(
                          onCreate: () => context.push('/tournaments/create'),
                          onJoin: () => context.push('/tournaments/join'),
                        )
                      : _ActiveTournamentCard(
                          tournament: active,
                          partyMatchId: state.partyMatchId,
                          onCreate: () => context.push('/tournaments/create'),
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _showHistory(List<Tournament> history) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: _TournamentHistoryPanel(history: history),
        ),
      );
}

final class _TournamentEmptyState extends StatelessWidget {
  const _TournamentEmptyState({required this.onCreate, required this.onJoin});

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const AhdashPictogramView(
        pictogram: AhdashPictogram.tournament,
        scale: AhdashPictogramScale.sectionIdentity,
        semanticLabel: 'بطولة',
      ),
      const SizedBox(height: 12),
      Text('بطولتك تبدأ هنا', style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 5),
      const Text('خروج مغلوب واضح، من تسجيل الفرق حتى رفع الكأس.'),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            AhdashV10PrimaryButton(label: 'أنشئ بطولة', onPressed: onCreate),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onJoin, child: const Text('انضم برمز')),
          ],
        ),
      ),
    ],
  );
}

final class _ActiveTournamentCard extends StatelessWidget {
  const _ActiveTournamentCard({
    required this.tournament,
    required this.partyMatchId,
    required this.onCreate,
  });
  final Tournament tournament;
  final String? partyMatchId;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final champion = tournament.hasConfirmedChampion
        ? tournament.team(tournament.championTeamId)
        : null;
    final completed = tournament.matches
        .where((match) => match.status == TournamentMatchStatus.completed)
        .length;
    final playableCount = tournament.matches
        .where((match) => match.status != TournamentMatchStatus.bye)
        .length;
    final progress = playableCount > 0
        ? completed / playableCount
        : tournament.teams.length / tournament.rules.capacity;
    final nextMatch = TournamentFlowResolver.currentMatch(tournament);
    final nextA = tournament.team(nextMatch?.teamAId)?.name;
    final nextB = tournament.team(nextMatch?.teamBId)?.name;
    final compact = context.v9Metrics.compact;
    final main = _TournamentHubSummary(
      tournament: tournament,
      partyMatchId: partyMatchId,
      completed: completed,
      progress: progress,
      champion: champion,
      onCreate: onCreate,
    );
    final upcoming = nextA != null && nextB != null
        ? _TournamentUpcomingMatch(
            match: nextMatch!,
            teamA: tournament.team(nextMatch.teamAId)!,
            teamB: tournament.team(nextMatch.teamBId)!,
          )
        : null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          main,
          if (upcoming != null) ...[
            SizedBox(height: compact ? 18 : 24),
            upcoming,
          ],
        ],
      ),
    );
  }
}

final class _TournamentHubSummary extends StatelessWidget {
  const _TournamentHubSummary({
    required this.tournament,
    required this.partyMatchId,
    required this.completed,
    required this.progress,
    required this.champion,
    required this.onCreate,
  });

  final Tournament tournament;
  final String? partyMatchId;
  final int completed;
  final double progress;
  final TournamentTeam? champion;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final compact = context.v9Metrics.compact;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AhdashPictogramView(
              pictogram: AhdashPictogram.tournament,
              color: context.ahdashColors.gold,
              scale: AhdashPictogramScale.compactFeature,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: compact ? 28 : 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    champion == null
                        ? 'تنافس مستمر حتى يحسم فريق طريق الكأس.'
                        : 'اكتمل المشوار وتُوّج ${champion!.name}.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.ahdashColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 14 : 28),
        Row(
          children: [
            Flexible(
              flex: 3,
              child: Text(
                tournament.matches.isNotEmpty
                    ? 'المباريات المكتملة: $completed من أصل ${tournament.matches.where((match) => match.status != TournamentMatchStatus.bye).length}'
                    : 'الفرق الجاهزة: ${tournament.teams.length} من أصل ${tournament.rules.capacity}',
                style: const TextStyle(fontWeight: FontWeight.w900),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: progress.clamp(0, 1),
                  backgroundColor: context.ahdashColors.border,
                  color: context.ahdashColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 16 : 30),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AhdashV10PrimaryButton(
              onPressed: () => context.push(
                TournamentFlowResolver.routeFor(
                  TournamentState(
                    active: tournament,
                    restored: true,
                    partyMatchId: partyMatchId,
                  ),
                ),
              ),
              label: tournament.status == TournamentStatus.completed
                  ? 'شاهد البطل'
                  : 'كمّل البطولة',
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onCreate,
              child: const Text('بطولة جديدة'),
            ),
          ],
        ),
      ],
    );
  }
}

final class _TournamentUpcomingMatch extends StatelessWidget {
  const _TournamentUpcomingMatch({
    required this.match,
    required this.teamA,
    required this.teamB,
  });

  final TournamentMatch match;
  final TournamentTeam teamA;
  final TournamentTeam teamB;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.ahdashColors.surfaceMuted,
      border: Border.all(color: context.ahdashColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: EdgeInsets.all(context.v9Metrics.compact ? 14 : 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'المباراة القادمة',
            style: TextStyle(
              color: context.ahdashColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _UpcomingTeam(team: teamA)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: context.ahdashColors.borderStrong,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(child: _UpcomingTeam(team: teamB)),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: context.ahdashColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'الجولة ${match.round}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  match.status == TournamentMatchStatus.live
                      ? 'جارية'
                      : 'جاهزة',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

final class _UpcomingTeam extends StatelessWidget {
  const _UpcomingTeam({required this.team});
  final TournamentTeam team;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        team.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
      ),
      Text(
        team.players.isEmpty ? 'جاهز' : team.players.first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.ahdashColors.textMuted, fontSize: 11),
      ),
    ],
  );
}

final class _TournamentHistoryPanel extends StatelessWidget {
  const _TournamentHistoryPanel({required this.history});

  final List<Tournament> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 44),
            SizedBox(height: 8),
            Text('البطولات المكتملة ستظهر هنا.'),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tournament = history[index];
        final champion = tournament.team(tournament.championTeamId);
        return ListTile(
          leading: Icon(
            Icons.emoji_events_rounded,
            color: context.ahdashColors.gold,
          ),
          title: Text(tournament.name),
          subtitle: Text(
            'البطل: ${champion?.name ?? 'غير محدد'} • ${tournament.teams.length} فريق',
          ),
        );
      },
    );
  }
}

final class TournamentCreateScreen extends ConsumerStatefulWidget {
  const TournamentCreateScreen({super.key});
  @override
  ConsumerState<TournamentCreateScreen> createState() =>
      _TournamentCreateScreenState();
}

final class _TournamentCreateScreenState
    extends ConsumerState<TournamentCreateScreen> {
  final _name = TextEditingController();
  var _step = 0;
  var _capacity = 8;
  var _players = 2;
  var _visibility = TournamentVisibility.private;
  var _seeding = TournamentSeeding.draw;
  var _loadingDraft = true;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = ref.read(tournamentControllerProvider.notifier);
      await controller.restore();
      final draft = await controller.readWizard();
      if (!mounted) return;
      if (draft != null) {
        _name.text = draft['name'] as String? ?? '';
        _step = (draft['step'] as int? ?? 0).clamp(0, 1);
        final rules = TournamentRules.fromJson(
          Map<String, Object?>.from(draft['rules'] as Map<Object?, Object?>),
        );
        _capacity = rules.capacity;
        _players = rules.playersPerTeam;
        _visibility = rules.visibility;
        _seeding = rules.seeding;
      }
      _name.addListener(_saveDraft);
      setState(() => _loadingDraft = false);
    });
  }

  void _saveDraft() {
    if (!mounted || _loadingDraft) return;
    unawaited(
      ref.read(tournamentControllerProvider.notifier).saveWizard({
        'name': _name.text,
        'step': _step,
        'rules': TournamentRules(
          capacity: _capacity,
          playersPerTeam: _players,
          visibility: _visibility,
          seeding: _seeding,
        ).toJson(),
      }),
    );
  }

  @override
  void dispose() {
    _name.removeListener(_saveDraft);
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentState = ref.watch(tournamentControllerProvider);
    final error = tournamentState.error;
    final compact = context.v9Metrics.compact;
    return _TournamentScaffold(
      title: 'أنشئ بطولة',
      keyboardSafe: true,
      child: context.v9Metrics.portrait && _step == 0
          ? _V10TournamentCreateBody(
              controller: _name,
              capacity: _capacity,
              error: _nameError,
              keyboardVisible: MediaQuery.viewInsetsOf(context).bottom > 0,
              enabled: !tournamentState.busy && !_loadingDraft,
              onCapacity: (value) {
                setState(() => _capacity = value);
                _saveDraft();
              },
              onNext: () {
                setState(
                  () => _nameError = TournamentEngine.tournamentNameError(
                    _name.text,
                  ),
                );
                if (_nameError == null) {
                  setState(() => _step = 1);
                  _saveDraft();
                }
              },
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        for (var index = 0; index < 2; index++) ...[
                          Expanded(
                            child: Container(
                              height: 4,
                              color: index <= _step
                                  ? context.ahdashColors.primary
                                  : context.ahdashColors.border,
                            ),
                          ),
                          if (index == 0) const SizedBox(width: 8),
                        ],
                        const SizedBox(width: 12),
                        Text(
                          '${_step + 1}/2',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 12 : 24),
                    Row(
                      children: [
                        AhdashPictogramView(
                          pictogram: AhdashPictogram.tournament,
                          scale: AhdashPictogramScale.sectionIdentity,
                        ),
                        SizedBox(width: compact ? 16 : 24),
                        Expanded(
                          child: Text(
                            _step == 0
                                ? 'سمِّ طريق الكأس'
                                : 'حدّد قواعد البطولة',
                            style: TextStyle(
                              fontSize: context.v9Metrics.heroSize,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 12 : 22),
                    if (_step == 0)
                      TextField(
                        key: const ValueKey('tournament-name-field'),
                        controller: _name,
                        autofocus: false,
                        decoration: InputDecoration(
                          labelText: 'اسم البطولة',
                          hintText: 'مثال: كأس الحي',
                          errorText: _nameError,
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _ChoiceField<int>(
                              label: 'السعة',
                              value: _capacity,
                              values: TournamentRules.supportedCapacities,
                              labelFor: (value) => '$value فريق',
                              onChanged: (value) {
                                setState(() => _capacity = value);
                                _saveDraft();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ChoiceField<int>(
                              label: 'لاعبو الفريق',
                              value: _players,
                              values: TournamentRules.supportedPlayerCounts,
                              labelFor: (value) => '$value',
                              onChanged: (value) {
                                setState(() => _players = value);
                                _saveDraft();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ChoiceField<TournamentVisibility>(
                              label: 'الدخول',
                              value: _visibility,
                              values: const [
                                TournamentVisibility.private,
                                TournamentVisibility.public,
                              ],
                              labelFor: (value) => switch (value) {
                                TournamentVisibility.private =>
                                  'خاصة • إضافة يدوية',
                                TournamentVisibility.invite => 'بدعوة',
                                TournamentVisibility.public =>
                                  'مفتوحة • رمز وطلبات',
                              },
                              onChanged: (value) {
                                setState(() => _visibility = value);
                                _saveDraft();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ChoiceField<TournamentSeeding>(
                              label: 'الترتيب',
                              value: _seeding,
                              values: TournamentSeeding.values,
                              labelFor: (value) =>
                                  value == TournamentSeeding.draw
                                  ? 'قرعة'
                                  : 'يدوي',
                              onChanged: (value) {
                                setState(() => _seeding = value);
                                _saveDraft();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error,
                        style: TextStyle(color: context.ahdashColors.error),
                      ),
                    ],
                    SizedBox(height: compact ? 14 : 24),
                    AhdashV9PrimaryAction(
                      key: const ValueKey('tournament-create-primary'),
                      onPressed: tournamentState.busy || _loadingDraft
                          ? null
                          : _step == 0
                          ? () {
                              setState(
                                () => _nameError =
                                    TournamentEngine.tournamentNameError(
                                      _name.text,
                                    ),
                              );
                              if (_nameError == null) {
                                setState(() => _step = 1);
                                _saveDraft();
                              }
                            }
                          : _create,
                      icon: null,
                      label: tournamentState.busy
                          ? 'جارٍ الحفظ…'
                          : _step == 0
                          ? 'التالي: القواعد'
                          : 'التالي: الفرق',
                    ),
                    if (_step > 0)
                      TextButton(
                        onPressed: tournamentState.busy
                            ? null
                            : () {
                                setState(() => _step = 0);
                                _saveDraft();
                              },
                        child: const Text('السابق: الاسم'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _create() async {
    final created = await ref
        .read(tournamentControllerProvider.notifier)
        .create(
          name: _name.text,
          rules: TournamentRules(
            capacity: _capacity,
            playersPerTeam: _players,
            visibility: _visibility,
            seeding: _seeding,
          ),
        );
    if (created != null && mounted) context.go('/tournaments/teams');
  }
}

final class _ChoiceField<T> extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: values
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(
              labelFor(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );
}

final class TournamentTeamsScreen extends ConsumerStatefulWidget {
  const TournamentTeamsScreen({super.key});
  @override
  ConsumerState<TournamentTeamsScreen> createState() =>
      _TournamentTeamsScreenState();
}

final class _TournamentTeamsScreenState
    extends ConsumerState<TournamentTeamsScreen> {
  final _teamName = TextEditingController();
  final _players = TextEditingController();
  @override
  void dispose() {
    _teamName.dispose();
    _players.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentControllerProvider);
    final tournament = state.active;
    if (tournament == null) return const TournamentHubScreen();
    final pendingCount = ref
        .watch(pendingTournamentRegistrationsProvider(tournament.id))
        .value
        ?.length;
    ref.watch(authControllerProvider);
    final canEdit =
        tournament.canEdit &&
        ref.read(tournamentControllerProvider.notifier).canManage;
    return _TournamentScaffold(
      title: 'الفرق المشاركة',
      child: context.v9Metrics.portrait
          ? _V10TournamentTeamsBody(
              tournament: tournament,
              enabled: canEdit && !state.busy,
              onAdd: () => _openAddTeamSheet(tournament),
              onDraw: tournament.canDraw && canEdit && !state.busy
                  ? () => context.go('/tournaments/draw')
                  : null,
            )
          : Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'الفرق ${tournament.teams.length}/${tournament.rules.capacity}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (canEdit) ...[
                      OutlinedButton.icon(
                        onPressed: state.busy
                            ? null
                            : () => _openAddTeamSheet(tournament),
                        icon: const Icon(AhdashIcons.add),
                        label: const Text('أضف فريقًا'),
                      ),
                      if (tournament.inviteCode != null) ...[
                        TextButton(
                          onPressed: () =>
                              _copyInviteCode(tournament.inviteCode!),
                          child: const Text('نسخ رمز الدعوة'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            await context.push('/tournaments/registrations');
                            if (mounted) {
                              await ref
                                  .read(tournamentControllerProvider.notifier)
                                  .refresh();
                            }
                          },
                          child: Text('الطلبات (${pendingCount ?? 0})'),
                        ),
                      ],
                    ],
                  ],
                ),
                if (canEdit)
                  Text(
                    'الإضافات اليدوية مسودة محلية حتى تثبيت القرعة.',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.ahdashColors.textMuted,
                    ),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: context.ahdashColors.error),
                    ),
                  ),
                SizedBox(height: context.v9Metrics.compact ? 8 : 16),
                Expanded(
                  child: tournament.teams.isEmpty
                      ? const Center(
                          child: Text('أضف فريقين على الأقل لتجهيز القرعة.'),
                        )
                      : _TeamGrid(teams: tournament.teams),
                ),
                SizedBox(height: context.v9Metrics.compact ? 8 : 14),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${tournament.teams.length} من ${tournament.rules.capacity} فرق مشاركة',
                    style: TextStyle(
                      color: context.ahdashColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AhdashV10PrimaryButton(
                  label: 'مراجعة القرعة',
                  icon: AhdashIcons.forward,
                  onPressed: tournament.canDraw && canEdit && !state.busy
                      ? () => context.go('/tournaments/draw')
                      : null,
                ),
              ],
            ),
    );
  }

  Future<void> _openAddTeamSheet(Tournament tournament) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.86,
        child: AhdashV7Canvas(
          gold: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'فريق جديد',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(AhdashIcons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _teamName,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'اسم الفريق',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _players,
                      decoration: InputDecoration(
                        labelText:
                            'اللاعبون — افصل بينهم بفاصلة (حتى ${tournament.rules.playersPerTeam})',
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () async {
                        await _add();
                        if (sheetContext.mounted && _teamName.text.isEmpty) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      icon: const Icon(AhdashIcons.add),
                      label: const Text('إضافة الفريق'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      final inviteLink = Uri(
        scheme: 'com.ahdash.eleven',
        host: 'app',
        path: '/tournaments/join',
        queryParameters: {'code': code},
      ).toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ رمز البطولة.'),
          action: SnackBarAction(
            label: 'نسخ الرابط',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteLink));
            },
          ),
        ),
      );
    }
  }

  Future<void> _add() async {
    final players = _players.text
        .split(RegExp(r'[,،]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (await ref
        .read(tournamentControllerProvider.notifier)
        .addTeam(_teamName.text, players: players)) {
      _teamName.clear();
      _players.clear();
    }
  }
}

final class _TeamGrid extends StatelessWidget {
  const _TeamGrid({required this.teams});
  final List<TournamentTeam> teams;
  @override
  Widget build(BuildContext context) => ListView.builder(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    physics: const ClampingScrollPhysics(),
    itemCount: teams.length,
    itemBuilder: (context, index) {
      final team = teams[index];
      return Semantics(
        label:
            '${team.name}، ${team.players.length} لاعب، ${team.approved ? 'جاهز' : 'قيد المراجعة'}',
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.ahdashColors.border),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: context.v9Metrics.compact ? 32 : 38,
                height: context.v9Metrics.compact ? 26 : 32,
                alignment: Alignment.center,
                color: context.ahdashColors.textPrimary,
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: context.ahdashColors.background,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  team.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: team.approved
                      ? context.ahdashColors.primary
                      : context.ahdashColors.gold,
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 104,
                child: Text(
                  '${team.players.length} لاعب • ${team.approved ? 'جاهز' : 'قيد المراجعة'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.ahdashColors.textMuted,
                    fontSize: context.v9Metrics.metadataSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

final class TournamentDrawScreen extends ConsumerWidget {
  const TournamentDrawScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tournamentControllerProvider);
    final tournament = state.active;
    if (tournament == null) return const TournamentHubScreen();
    ref.watch(authControllerProvider);
    final canDraw =
        tournament.canDraw &&
        ref.read(tournamentControllerProvider.notifier).canManage;
    final compact = context.v9Metrics.compact;
    final teams = tournament.teams.where((team) => team.approved).toList();
    Future<void> generate() async {
      final ok = await ref
          .read(tournamentControllerProvider.notifier)
          .generateBracket();
      if (ok && context.mounted) context.go('/tournaments/bracket');
    }

    final action = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AhdashPictogramView(
            pictogram: AhdashPictogram.draw,
            size: compact ? 72 : 100,
            semanticLabel: 'قرعة البطولة',
          ),
          const SizedBox(height: 12),
          Text(
            'ثبّت طريق البطولة',
            style: TextStyle(
              fontSize: compact ? 28 : 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tournament.rules.seeding == TournamentSeeding.draw
                ? 'قرعة الفرق المؤهلة مع التأهل التلقائي للمقاعد الخالية.'
                : 'ترتيب الفرق حسب البذور المسجلة.',
            style: TextStyle(color: context.ahdashColors.textMuted),
          ),
          SizedBox(height: compact ? 12 : 28),
          Divider(color: context.ahdashColors.border),
          const SizedBox(height: 8),
          AhdashV10PrimaryButton(
            onPressed: state.busy || !canDraw ? null : generate,
            label: state.busy ? 'جارٍ تثبيت القرعة…' : 'اعمل القرعة وابدأ',
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                state.error!,
                style: TextStyle(color: context.ahdashColors.error),
              ),
            ),
          if (!canDraw)
            const Text('القرعة غير متاحة في الحالة الحالية أو لهذا الحساب.'),
        ],
      ),
    );
    final roster = Container(
      padding: EdgeInsets.all(compact ? 16 : 28),
      decoration: BoxDecoration(
        color: context.ahdashColors.surface,
        border: Border.all(color: context.ahdashColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الفرق الجاهزة · ${teams.length}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: teams.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) => Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: compact ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: context.ahdashColors.background,
                  border: Border.all(color: context.ahdashColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        teams[index].name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'مؤهل',
                      style: TextStyle(
                        color: context.ahdashColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return _TournamentScaffold(
      title: 'قرعة البطولة',
      child: context.v9Metrics.portrait
          ? _V10TournamentDrawBody(
              tournament: tournament,
              teams: teams,
              enabled: !state.busy && canDraw,
              onGenerate: generate,
            )
          : Column(
              children: [
                Flexible(flex: 5, child: action),
                const SizedBox(height: 16),
                Expanded(flex: 4, child: roster),
              ],
            ),
    );
  }
}

final class TournamentBracketScreen extends ConsumerStatefulWidget {
  const TournamentBracketScreen({this.initialRound, super.key});
  final int? initialRound;
  @override
  ConsumerState<TournamentBracketScreen> createState() =>
      _TournamentBracketScreenState();
}

final class _TournamentBracketScreenState
    extends ConsumerState<TournamentBracketScreen> {
  late var _round = widget.initialRound;
  var _page = 0;
  @override
  Widget build(BuildContext context) {
    final tournamentState = ref.watch(tournamentControllerProvider);
    final tournament = tournamentState.active;
    if (tournament == null) return const TournamentHubScreen();
    _round ??= TournamentFlowResolver.currentRound(tournament);
    final maxRound = tournament.matches
        .map((value) => value.round)
        .fold(1, (a, b) => a > b ? a : b);
    final roundMatches =
        tournament.matches.where((value) => value.round == _round).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    final compact = context.v9Metrics.compact;
    const pageSize = 2;
    final pageCount = ((roundMatches.length + pageSize - 1) ~/ pageSize).clamp(
      1,
      99,
    );
    final visible = roundMatches.skip(_page * pageSize).take(pageSize).toList();
    _page = _page.clamp(0, pageCount - 1);
    final nextRoundLabel = _round! < maxRound
        ? _roundLabel(_round! + 1, maxRound)
        : null;
    final readyMatch = roundMatches
        .where((match) => match.status == TournamentMatchStatus.ready)
        .firstOrNull;
    return _TournamentScaffold(
      title: 'جدول المباريات',
      showMark: !compact,
      child: context.v9Metrics.portrait
          ? _V10TournamentBracketBody(
              tournament: tournament,
              maxRound: maxRound,
              round: _round!,
              matches: visible,
              readyMatch: readyMatch,
              onRound: (round) => setState(() {
                _round = round;
                _page = 0;
              }),
              onMatch: (match) =>
                  context.push('/tournaments/match/${match.id}'),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1088),
                child: Column(
                  children: [
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: maxRound,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final round = index + 1;
                          final selected = _round == round;
                          final label = _roundLabel(round, maxRound);
                          return Semantics(
                            selected: selected,
                            button: true,
                            label: 'عرض $label',
                            child: ChoiceChip(
                              label: Text(label),
                              selected: selected,
                              onSelected: (_) => setState(() {
                                _round = round;
                                _page = 0;
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: context.v9Metrics.compact ? 8 : 20),
                    Expanded(
                      child: _BracketStage(
                        tournament: tournament,
                        matches: visible,
                        nextRoundLabel: nextRoundLabel,
                      ),
                    ),
                    if (pageCount > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _page > 0
                                ? () => setState(() => _page--)
                                : null,
                            icon: const Icon(AhdashIcons.back),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text('${_page + 1} / $pageCount'),
                          ),
                          IconButton(
                            onPressed: _page + 1 < pageCount
                                ? () => setState(() => _page++)
                                : null,
                            icon: const Icon(AhdashIcons.forward),
                          ),
                        ],
                      ),
                    if (readyMatch != null) ...[
                      SizedBox(height: compact ? 4 : 10),
                      Divider(color: context.ahdashColors.border),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AhdashV10PrimaryButton(
                          onPressed: tournamentState.busy
                              ? null
                              : () => context.push(
                                  '/tournaments/match/${readyMatch.id}',
                                ),
                          icon: AhdashIcons.playSelected,
                          label: 'ابدأ ${_roundLabel(_round!, maxRound)}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  String _roundLabel(int round, int max) => round == max
      ? 'النهائي'
      : round == max - 1
      ? 'نصف النهائي'
      : 'الدور $round';
}

final class _BracketStage extends StatelessWidget {
  const _BracketStage({
    required this.tournament,
    required this.matches,
    required this.nextRoundLabel,
  });

  final Tournament tournament;
  final List<TournamentMatch> matches;
  final String? nextRoundLabel;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'لا توجد مباريات في هذا الدور.',
          style: TextStyle(color: context.ahdashColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: matches.length + (nextRoundLabel == null ? 0 : 1),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == matches.length) {
          return Semantics(
            label: 'الفائزون يتأهلون إلى $nextRoundLabel',
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.ahdashColors.gold.withValues(alpha: 0.08),
                border: Border.all(color: context.ahdashColors.gold),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'الفائزون يتأهلون إلى $nextRoundLabel',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          );
        }
        return _BracketMatchCard(tournament: tournament, match: matches[index]);
      },
    );
  }
}

final class _BracketMatchCard extends StatelessWidget {
  const _BracketMatchCard({required this.tournament, required this.match});
  final Tournament tournament;
  final TournamentMatch match;
  @override
  Widget build(BuildContext context) {
    final a = tournament.team(match.teamAId)?.name ?? 'بانتظار المتأهل';
    final b =
        tournament.team(match.teamBId)?.name ??
        (match.status == TournamentMatchStatus.bye ? 'BYE' : 'بانتظار المتأهل');
    final current =
        TournamentFlowResolver.currentMatch(tournament)?.id == match.id;
    final statusLabel = switch (match.status) {
      TournamentMatchStatus.pending => 'بانتظار اكتمال الطرفين',
      TournamentMatchStatus.ready => 'جاهزة للعب',
      TournamentMatchStatus.live => 'جارية',
      TournamentMatchStatus.completed => 'مكتملة',
      TournamentMatchStatus.bye => 'تأهل تلقائي',
      TournamentMatchStatus.cancelled => 'ملغاة',
    };
    final canOpen =
        match.status == TournamentMatchStatus.ready ||
        match.status == TournamentMatchStatus.live ||
        match.status == TournamentMatchStatus.completed;
    return Semantics(
      button: canOpen,
      label: 'مواجهة $a ضد $b، $statusLabel',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canOpen
              ? () => context.push('/tournaments/match/${match.id}')
              : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 94),
            decoration: BoxDecoration(
              color: current
                  ? context.ahdashColors.primary.withValues(alpha: 0.06)
                  : context.ahdashColors.surface.withValues(alpha: 0.58),
              border: Border.all(
                color: current
                    ? context.ahdashColors.primary
                    : context.ahdashColors.borderStrong,
                width: current ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BracketTeam(
                    name: a,
                    score: match.scoreA,
                    winner:
                        match.winnerId != null &&
                        match.winnerId == match.teamAId,
                  ),
                  Divider(height: 8, color: context.ahdashColors.border),
                  _BracketTeam(
                    name: b,
                    score: match.scoreB,
                    winner:
                        match.winnerId != null &&
                        match.winnerId == match.teamBId,
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: context.ahdashColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _BracketTeam extends StatelessWidget {
  const _BracketTeam({
    required this.name,
    required this.score,
    required this.winner,
  });
  final String name;
  final int? score;
  final bool winner;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: winner ? 3 : 1,
        height: 18,
        color: winner ? context.ahdashColors.gold : context.ahdashColors.border,
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: winner ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
      ),
      if (score != null)
        Text('$score', style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

final class TournamentMatchScreen extends ConsumerStatefulWidget {
  const TournamentMatchScreen({required this.matchId, super.key});
  final String matchId;
  @override
  ConsumerState<TournamentMatchScreen> createState() =>
      _TournamentMatchScreenState();
}

final class _TournamentMatchScreenState
    extends ConsumerState<TournamentMatchScreen> {
  var _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partyGameControllerProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentControllerProvider);
    final tournament = state.active;
    final match = tournament?.matches
        .where((value) => value.id == widget.matchId)
        .firstOrNull;
    if (tournament == null || match == null) return const TournamentHubScreen();
    final party = ref.watch(partyGameControllerProvider);
    ref.watch(authControllerProvider);
    final canManage = ref.read(tournamentControllerProvider.notifier).canManage;
    final teamA = tournament.team(match.teamAId);
    final teamB = tournament.team(match.teamBId);
    final awaitingResult =
        TournamentFlowResolver.hasPartyResult(tournament, match, party) &&
        match.status != TournamentMatchStatus.completed;
    final playable =
        tournament.status == TournamentStatus.live &&
        match.hasBothTeams &&
        (match.status == TournamentMatchStatus.ready ||
            match.status == TournamentMatchStatus.live);
    final linked =
        party.tournamentContext?.tournamentId == tournament.id &&
        party.tournamentContext?.matchId == match.id;
    final compact = context.v9Metrics.compact;
    final blocked = state.busy || _starting || !canManage || !playable;
    final scoreA = awaitingResult ? party.session!.scores[0] : match.scoreA;
    final scoreB = awaitingResult ? party.session!.scores[1] : match.scoreB;
    return _TournamentScaffold(
      title: awaitingResult ? 'اعتماد نتيجة المباراة' : 'المباراة الحالية',
      child: context.v9Metrics.portrait
          ? _V10TournamentMatchBody(
              match: match,
              teamA: teamA,
              teamB: teamB,
              awaitingResult: awaitingResult,
              playable: playable,
              blocked: blocked,
              linked: linked,
              onPrimary: awaitingResult
                  ? () => _confirmParty(party.session!)
                  : () => _startParty(tournament, match),
              onExternal: teamA != null && teamB != null
                  ? () => _manualResult(teamA, teamB)
                  : null,
            )
          : LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${tournament.name} · الجولة ${match.round} · المباراة ${match.position + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.ahdashColors.textMuted),
                      ),
                      SizedBox(height: compact ? 12 : 36),
                      _MatchTeamHero(team: teamA, score: scoreA),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'VS',
                          textDirection: TextDirection.ltr,
                          style: AppTypography.champion.copyWith(
                            fontSize: 24,
                            color: context.ahdashColors.textMuted,
                          ),
                        ),
                      ),
                      _MatchTeamHero(team: teamB, score: scoreB),
                      SizedBox(height: compact ? 12 : 28),
                      Text(
                        awaitingResult
                            ? 'راجع نتيجة Party قبل اعتماد التأهل'
                            : match.status == TournamentMatchStatus.completed
                            ? 'نتيجة معتمدة'
                            : playable
                            ? 'الفائز يتأهل بعد اعتماد المنظم للنتيجة'
                            : match.status == TournamentMatchStatus.bye
                            ? 'تأهل تلقائي دون مباراة'
                            : 'بانتظار اكتمال طرفي المباراة',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: compact ? 8 : 24),
                      Divider(color: context.ahdashColors.border),
                      SizedBox(height: compact ? 8 : 18),
                      if (playable)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AhdashV10PrimaryButton(
                              onPressed: blocked
                                  ? null
                                  : awaitingResult
                                  ? () => _confirmParty(party.session!)
                                  : () => _startParty(tournament, match),
                              icon: awaitingResult
                                  ? AhdashIcons.check
                                  : AhdashIcons.playSelected,
                              label: state.busy || _starting
                                  ? 'جارٍ التحقق…'
                                  : awaitingResult
                                  ? 'اعتماد النتيجة والتأهل'
                                  : linked
                                  ? 'استئناف المباراة'
                                  : 'ابدأ المباراة',
                            ),
                            if (!awaitingResult && !linked)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: OutlinedButton(
                                  onPressed: blocked
                                      ? null
                                      : () => _manualResult(teamA!, teamB!),
                                  child: const Text('تسجيل نتيجة خارجية'),
                                ),
                              ),
                          ],
                        )
                      else
                        OutlinedButton(
                          onPressed: () => context.go('/tournaments/bracket'),
                          child: const Text('العودة إلى الشجرة'),
                        ),
                      if (!canManage)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('عرض فقط · اعتماد النتائج متاح للمنظم.'),
                        ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.ahdashColors.error),
                          ),
                        ),
                      if (party.error != null && linked)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            party.error!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _startParty(Tournament tournament, TournamentMatch match) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final controller = ref.read(tournamentControllerProvider.notifier);
      if (!await controller.selectPartyMatch(match.id)) return;
      final a = tournament.team(match.teamAId)!;
      final b = tournament.team(match.teamBId)!;
      final started = await ref
          .read(partyGameControllerProvider.notifier)
          .beginTournamentGame(
            context: PartyTournamentContext(
              tournamentId: tournament.id,
              matchId: match.id,
              teamAId: a.id,
              teamBId: b.id,
              tiebreakerEnabled: tournament.rules.tiebreakerEnabled,
              fixedCategoryIds: tournament.rules.categoryIds,
            ),
            teams: [
              PartyTeam(
                name: a.name,
                players: a.players,
                colorValue: 0xFF2368A2,
              ),
              PartyTeam(
                name: b.name,
                players: b.players,
                colorValue: 0xFFB63863,
              ),
            ],
            timerSeconds: tournament.rules.timerSeconds,
            categoryIds: tournament.rules.categoryIds,
          );
      if (started && mounted) {
        context.go(
          TournamentFlowResolver.routeFor(
            ref.read(tournamentControllerProvider),
            requestedMatchId: match.id,
            party: ref.read(partyGameControllerProvider),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _confirmParty(PartyGameSession session) async {
    final controller = ref.read(tournamentControllerProvider.notifier);
    final ok = await controller.confirmResult(
      matchId: widget.matchId,
      scoreA: session.scores[0],
      scoreB: session.scores[1],
      partySessionId: session.id,
    );
    if (!ok || !mounted) return;
    await controller.clearPartyMatch();
    if (mounted) {
      context.go(
        TournamentFlowResolver.routeFor(ref.read(tournamentControllerProvider)),
      );
    }
  }

  Future<void> _manualResult(TournamentTeam a, TournamentTeam b) async {
    final scoreA = TextEditingController();
    final scoreB = TextEditingController();
    String? error;
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'نتيجة مباراة خارجية',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Text(
                  'فقط للمواجهة التي لُعبت خارج Party. لا يُعتمد التعادل.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: scoreA,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: a.name),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: scoreB,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: b.name),
                      ),
                    ),
                  ],
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(color: context.ahdashColors.error),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final valueA = int.tryParse(scoreA.text);
                          final valueB = int.tryParse(scoreB.text);
                          if (valueA == null ||
                              valueB == null ||
                              valueA < 0 ||
                              valueB < 0 ||
                              valueA == valueB) {
                            setSheetState(
                              () => error = 'أدخل نتيجتين صحيحتين دون تعادل.',
                            );
                            return;
                          }
                          setSheetState(() {
                            saving = true;
                            error = null;
                          });
                          final ok = await ref
                              .read(tournamentControllerProvider.notifier)
                              .confirmResult(
                                matchId: widget.matchId,
                                scoreA: valueA,
                                scoreB: valueB,
                              );
                          if (!sheetContext.mounted) return;
                          if (ok) {
                            Navigator.pop(sheetContext);
                            if (mounted) {
                              context.go(
                                TournamentFlowResolver.routeFor(
                                  ref.read(tournamentControllerProvider),
                                ),
                              );
                            }
                          } else {
                            setSheetState(() {
                              saving = false;
                              error = ref
                                  .read(tournamentControllerProvider)
                                  .error;
                            });
                          }
                        },
                  child: Text(saving ? 'جارٍ الاعتماد…' : 'اعتماد النتيجة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    scoreA.dispose();
    scoreB.dispose();
  }
}

final class _MatchTeamHero extends StatelessWidget {
  const _MatchTeamHero({required this.team, this.score});
  final TournamentTeam? team;
  final int? score;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 112),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.ahdashColors.surface,
      border: Border.all(color: context.ahdashColors.borderStrong),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          team?.name ?? 'بانتظار الفائز',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          team == null ? 'لم يُحسم الطرف بعد' : '${team!.players.length} لاعب',
          style: TextStyle(color: context.ahdashColors.textMuted),
        ),
        if (score != null)
          Text(
            '$score',
            textDirection: TextDirection.ltr,
            style: AppTypography.champion.copyWith(
              fontSize: context.v9Metrics.compact ? 32 : 48,
            ),
          ),
      ],
    ),
  );
}

final class TournamentChampionScreen extends ConsumerWidget {
  const TournamentChampionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentControllerProvider).active;
    final champion = tournament?.team(tournament.championTeamId);
    if (tournament == null ||
        champion == null ||
        !tournament.hasConfirmedChampion) {
      return const TournamentHubScreen();
    }
    final compact = context.v9Metrics.compact;
    final short = MediaQuery.sizeOf(context).height <= 370;
    return _TournamentScaffold(
      title: tournament.name,
      showHeader: false,
      child: context.v9Metrics.portrait
          ? _V10TournamentChampionBody(
              tournament: tournament,
              champion: champion,
              onDone: () => context.go('/home'),
              onHistory: () => context.go('/tournaments/bracket'),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!compact) ...[
                      Text(
                        'نهاية المشوار',
                        style: TextStyle(
                          color: context.ahdashColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    AhdashPictogramReveal(
                      child: AhdashPictogramView(
                        pictogram: AhdashPictogram.champion,
                        size: compact ? (short ? 56 : 64) : null,
                        scale: compact ? null : AhdashPictogramScale.champion,
                        tone: AhdashPictogramTone.achievement,
                        semanticLabel: 'بطل البطولة',
                      ),
                    ),
                    SizedBox(
                      height: short
                          ? 3
                          : compact
                          ? 6
                          : 12,
                    ),
                    const Text('بطل البطولة', style: AppTypography.editorial),
                    Text(
                      champion.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.champion.copyWith(
                        fontSize: compact ? 34 : 56,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tournament.name} • ${tournament.teams.length} فرق',
                      style: TextStyle(
                        color: context.ahdashColors.textSecondary,
                      ),
                    ),
                    Text(
                      'النهائي · ${tournament.finalMatch!.scoreA} — ${tournament.finalMatch!.scoreB}',
                      semanticsLabel:
                          'نتيجة النهائي ${tournament.finalMatch!.scoreA} مقابل ${tournament.finalMatch!.scoreB}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: compact ? 6 : 24),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: compact ? 236 : 280,
                          child: AhdashV10PrimaryButton(
                            label: 'تم',
                            onPressed: () => context.go('/home'),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: context.ahdashColors.textPrimary,
                          ),
                          onPressed: () => context.go('/tournaments/bracket'),
                          child: const Text('سجل البطولة'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

final class _V10TournamentHubBody extends StatelessWidget {
  const _V10TournamentHubBody({
    required this.tournament,
    required this.partyMatchId,
    required this.onHistory,
    required this.onRules,
  });
  final Tournament tournament;
  final String? partyMatchId;
  final VoidCallback onHistory, onRules;
  @override
  Widget build(BuildContext context) {
    final next = TournamentFlowResolver.currentMatch(tournament);
    final a = tournament.team(next?.teamAId),
        b = tournament.team(next?.teamBId);
    final route = TournamentFlowResolver.routeFor(
      TournamentState(
        active: tournament,
        restored: true,
        partyMatchId: partyMatchId,
      ),
    );
    return _TournamentBody(
      action: _V10TournamentCta(
        label: tournament.status == TournamentStatus.completed
            ? 'شاهد بطل البطولة'
            : 'استمر للبطولة الحالية',
        onPressed: () => context.push(route),
      ),
      children: [
        AhdashV10Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tournament.name,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                next == null
                    ? 'حالة البطولة: ${tournament.status == TournamentStatus.completed ? "مكتملة" : "قيد التجهيز"}'
                    : _tRoundLabel(next.round),
                style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
              ),
              const Divider(height: 32),
              Row(
                children: [
                  const Expanded(
                    child: _V10MetaPair(
                      label: 'نظام البطولة',
                      value: 'خروج المغلوب',
                    ),
                  ),
                  Expanded(
                    child: _V10MetaPair(
                      label: 'الفرق المسجلة',
                      value:
                          '${_tArabic(tournament.teams.length)} / ${_tArabic(tournament.rules.capacity)}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (next != null && a != null && b != null) ...[
          const SizedBox(height: 16),
          AhdashV10Panel(
            backgroundColor: AppColors.paper0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'المباراة القادمة',
                  style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 12),
                Text(
                  '${a.name}  ضد  ${b.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _V10OutlineAction(
          label: 'البطولات السابقة والأرشيف',
          onPressed: onHistory,
        ),
        const SizedBox(height: 12),
        _V10OutlineAction(label: 'لوائح البطولة والقواعد', onPressed: onRules),
      ],
    );
  }
}

final class _V10MetaPair extends StatelessWidget {
  const _V10MetaPair({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

final class _V10TournamentCreateBody extends StatelessWidget {
  const _V10TournamentCreateBody({
    required this.controller,
    required this.capacity,
    required this.error,
    required this.keyboardVisible,
    required this.enabled,
    required this.onCapacity,
    required this.onNext,
  });
  final TextEditingController controller;
  final int capacity;
  final String? error;
  final bool keyboardVisible, enabled;
  final ValueChanged<int> onCapacity;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        '١ من ٣ • تجهيز البطولة',
        style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
      ),
      const SizedBox(height: 24),
      TextField(
        key: const ValueKey('tournament-name-field'),
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: 'اسم البطولة',
          hintText: 'مثال: كأس الحي',
          errorText: error,
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'حجم البطولة',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final value in const [4, 8]) ...[
              Expanded(
                child: _V10CapacityChoice(
                  value: value,
                  selected: capacity == value,
                  onPressed: enabled ? () => onCapacity(value) : null,
                ),
              ),
              if (value == 4) const SizedBox(width: 16),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      _V10TournamentCta(
        key: const ValueKey('tournament-create-primary'),
        label: 'التالي',
        onPressed: enabled ? onNext : null,
      ),
    ],
  );
}

final class _V10CapacityChoice extends StatelessWidget {
  const _V10CapacityChoice({
    required this.value,
    required this.selected,
    required this.onPressed,
  });
  final int value;
  final bool selected;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF1E874B) : AppColors.hairline,
        width: selected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _tArabic(value),
          style: TextStyle(
            color: selected ? const Color(0xFF1E874B) : AppColors.inkMuted,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text('فرق رياضية', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

final class _V10TournamentTeamsBody extends StatelessWidget {
  const _V10TournamentTeamsBody({
    required this.tournament,
    required this.enabled,
    required this.onAdd,
    required this.onDraw,
  });
  final Tournament tournament;
  final bool enabled;
  final VoidCallback onAdd;
  final VoidCallback? onDraw;
  @override
  Widget build(BuildContext context) => _TournamentBody(
    action: _V10TournamentCta(label: 'ابدأ القرعة', onPressed: onDraw),
    children: [
      Text(
        '${tournament.teams.length} من ${tournament.rules.capacity} فرق',
        style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
      ),
      const SizedBox(height: 16),
      for (var i = 0; i < tournament.teams.length; i++) ...[
        _V10TournamentTeamRow(
          team: tournament.teams[i],
          color: _v10TeamColor(i),
        ),
        const SizedBox(height: 12),
      ],
      OutlinedButton.icon(
        onPressed: enabled ? onAdd : null,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة فريق'),
      ),
    ],
  );
}

final class _V10TournamentTeamRow extends StatelessWidget {
  const _V10TournamentTeamRow({required this.team, required this.color});
  final TournamentTeam team;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.hairline),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        _V10TeamDot(color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

final class _V10TournamentDrawBody extends StatelessWidget {
  const _V10TournamentDrawBody({
    required this.tournament,
    required this.teams,
    required this.enabled,
    required this.onGenerate,
  });
  final Tournament tournament;
  final List<TournamentTeam> teams;
  final bool enabled;
  final VoidCallback onGenerate;
  @override
  Widget build(BuildContext context) => _TournamentBody(
    action: _V10TournamentCta(
      label: 'اسحب القرعة',
      onPressed: enabled ? onGenerate : null,
    ),
    children: [
      AhdashV10Panel(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'القرعة جاهزة',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'تُحدد المواجهات عشوائيًا عند سحب القرعة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.inkMuted,
              ),
            ),
            if (!enabled)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'القرعة غير متاحة في الحالة الحالية أو لهذا الحساب.',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'الفرق المشاركة',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < teams.length; i++) ...[
        _V10TournamentTeamRow(team: teams[i], color: _v10TeamColor(i)),
        const SizedBox(height: 12),
      ],
    ],
  );
}

final class _V10TournamentBracketBody extends StatelessWidget {
  const _V10TournamentBracketBody({
    required this.tournament,
    required this.maxRound,
    required this.round,
    required this.matches,
    required this.readyMatch,
    required this.onRound,
    required this.onMatch,
  });
  final Tournament tournament;
  final int maxRound, round;
  final List<TournamentMatch> matches;
  final TournamentMatch? readyMatch;
  final ValueChanged<int> onRound;
  final ValueChanged<TournamentMatch> onMatch;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var r = 1; r <= maxRound; r++)
            _V10RoundTab(
              label: r == maxRound
                  ? 'النهائي'
                  : r == maxRound - 1
                  ? 'نصف النهائي'
                  : 'الدور ${_tArabic(r)}',
              selected: round == r,
              onPressed: () => onRound(r),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ListView.separated(
          itemCount: matches.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _V10BracketCard(
            tournament: tournament,
            match: matches[i],
            onPressed: () => onMatch(matches[i]),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _V10TournamentCta(
        label: 'الذهاب للمباراة القادمة',
        onPressed: readyMatch == null ? null : () => onMatch(readyMatch!),
      ),
    ],
  );
}

final class _V10RoundTab extends StatelessWidget {
  const _V10RoundTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: selected ? const Color(0xFF1E874B) : AppColors.inkMuted,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 3,
          color: selected ? const Color(0xFF1E874B) : Colors.transparent,
        ),
      ],
    ),
  );
}

final class _V10BracketCard extends StatelessWidget {
  const _V10BracketCard({
    required this.tournament,
    required this.match,
    required this.onPressed,
  });
  final Tournament tournament;
  final TournamentMatch match;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final a = tournament.team(match.teamAId)?.name ?? 'بانتظار المتأهل';
    final b = tournament.team(match.teamBId)?.name ?? 'بانتظار المتأهل';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: match.status == TournamentMatchStatus.pending ? null : onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _V10BracketTeam(name: a, score: match.scoreA),
              const Divider(height: 1),
              _V10BracketTeam(name: b, score: match.scoreB),
            ],
          ),
        ),
      ),
    );
  }
}

final class _V10BracketTeam extends StatelessWidget {
  const _V10BracketTeam({required this.name, required this.score});
  final String name;
  final int? score;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      Text(
        score == null ? '·' : _tArabic(score!),
        style: TextStyle(
          color: score != null && score! > 1
              ? const Color(0xFF1E874B)
              : AppColors.inkMuted,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

final class _V10TournamentMatchBody extends StatelessWidget {
  const _V10TournamentMatchBody({
    required this.match,
    required this.teamA,
    required this.teamB,
    required this.awaitingResult,
    required this.playable,
    required this.blocked,
    required this.linked,
    required this.onPrimary,
    required this.onExternal,
  });
  final TournamentMatch match;
  final TournamentTeam? teamA, teamB;
  final bool awaitingResult, playable, blocked, linked;
  final VoidCallback onPrimary;
  final VoidCallback? onExternal;
  @override
  Widget build(BuildContext context) => _TournamentBody(
    action: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _V10TournamentCta(
          label: awaitingResult
              ? 'اعتماد النتيجة والتأهل'
              : linked
              ? 'استئناف المباراة'
              : 'ابدأ المباراة',
          onPressed: blocked ? null : onPrimary,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: blocked ? null : onExternal,
          child: const Text('تسجيل نتيجة خارجية'),
        ),
      ],
    ),
    children: [
      Text(
        '${_tRoundLabel(match.round)} • مباراة ${_tArabic(match.position + 1)}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
      ),
      const SizedBox(height: 24),
      AhdashV10Panel(
        child: Column(
          children: [
            _V10MatchTeam(team: teamA, color: _v10TeamColor(0)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'VS',
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 24, color: AppColors.inkMuted),
              ),
            ),
            _V10MatchTeam(team: teamB, color: _v10TeamColor(1)),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text(
        playable
            ? 'الفائز يتأهل بعد اعتماد المنظم للنتيجة'
            : 'حالة المباراة محفوظة في البطولة',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    ],
  );
}

final class _V10MatchTeam extends StatelessWidget {
  const _V10MatchTeam({required this.team, required this.color});
  final TournamentTeam? team;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _V10TeamDot(color: color, size: 40),
      const SizedBox(height: 8),
      SizedBox(
        width: 280,
        child: Text(
          team?.name ?? 'بانتظار الفريق',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
}

final class _V10TournamentChampionBody extends StatelessWidget {
  const _V10TournamentChampionBody({
    required this.tournament,
    required this.champion,
    required this.onDone,
    required this.onHistory,
  });
  final Tournament tournament;
  final TournamentTeam champion;
  final VoidCallback onDone, onHistory;
  @override
  Widget build(BuildContext context) {
    final finalMatch = tournament.finalMatch!;
    final runnerUp = tournament.team(
      finalMatch.teamAId == champion.id
          ? finalMatch.teamBId
          : finalMatch.teamAId,
    );
    return _TournamentBody(
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AhdashV10PrimaryButton(
            label: 'عرض نتائج البطولة',
            onPressed: onHistory,
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onDone, child: const Text('تم')),
        ],
      ),
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.emoji_events_outlined, color: AppColors.ink, size: 80),
        const SizedBox(height: 24),
        Text(
          tournament.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 12),
        const Text(
          'بطل البطولة',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          champion.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            height: 1.3,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 24),
        AhdashV10Panel(
          child: Column(
            children: [
              _V10ChampionRow(label: 'البطل', value: champion.name),
              const Divider(height: 24),
              _V10ChampionRow(
                label: 'الوصيف',
                value: runnerUp?.name ?? '—',
                muted: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _V10ChampionRow extends StatelessWidget {
  const _V10ChampionRow({
    required this.label,
    required this.value,
    this.muted = false,
  });
  final String label;
  final String value;
  final bool muted;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            color: muted ? AppColors.inkMuted : AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: muted ? AppColors.inkMuted : const Color(0xFFFFB62E),
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

final class _V10OutlineAction extends StatelessWidget {
  const _V10OutlineAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        Transform.flip(
          flipX: true,
          child: const Icon(Icons.arrow_back_rounded, size: 18),
        ),
      ],
    ),
  );
}

final class _V10TournamentCta extends StatelessWidget {
  const _V10TournamentCta({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) =>
      AhdashV10PrimaryButton(label: label, onPressed: onPressed);
}

final class _V10TeamDot extends StatelessWidget {
  const _V10TeamDot({required this.color, this.size = 12});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

Color _v10TeamColor(int index) => const [
  Color(0xFFE5252A),
  Color(0xFF2867E8),
  Color(0xFF1EAD57),
  Color(0xFF078CC3),
  Color(0xFFDDA536),
  Color(0xFF8147E6),
  Color(0xFFE96422),
  Color(0xFF514BE8),
][index % 8];

String _tArabic(int value) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((digit) {
    final index = western.indexOf(digit);
    return index < 0 ? digit : eastern[index];
  }).join();
}

String _tRoundLabel(int round) => round == 1 ? 'الدور الأول' : 'الدور $round';

/// Shared body keeps the real action reachable while long content can scroll.
final class _TournamentBody extends StatelessWidget {
  const _TournamentBody({required this.children, required this.action});
  final List<Widget> children;
  final Widget action;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
      const SizedBox(height: 12),
      action,
    ],
  );
}

final class _TournamentScaffold extends StatelessWidget {
  const _TournamentScaffold({
    required this.title,
    required this.child,
    this.keyboardSafe = false,
    this.showBack = true,
    this.showMark = true,
    this.showHeader = true,
  });
  final String title;
  final Widget child;
  final bool keyboardSafe, showBack, showMark, showHeader;
  static const _keyboardScrollKey = ValueKey('tournament-keyboard-scroll');
  @override
  Widget build(BuildContext context) => BrandScaffold(
    showDevelopmentBadge: false,
    body: ColoredBox(
      color: AppColors.paper0,
      child: SafeArea(
        child: AhdashV10Frame(
          padding: EdgeInsets.fromLTRB(
            AhdashV10Metrics.of(context).gutter,
            16,
            AhdashV10Metrics.of(context).gutter,
            12,
          ),
          child: Column(
            children: [
              if (showHeader) ...[
                AhdashPageHeader(
                  title: title,
                  onBack: showBack
                      ? () => context.canPop()
                            ? context.pop()
                            : context.go('/home')
                      : null,
                  trailing: showMark
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.emoji_events_outlined, size: 24),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: keyboardSafe
                    ? SingleChildScrollView(
                        key: _keyboardScrollKey,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: child,
                      )
                    : child,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
