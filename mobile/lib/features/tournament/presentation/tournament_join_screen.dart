import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../social/data/social_repository.dart';
import '../../social/domain/social_entities.dart';
import '../data/tournament_registration_repository.dart';

final class TournamentJoinScreen extends ConsumerStatefulWidget {
  const TournamentJoinScreen({
    this.initialCode,
    this.initialPlayersPerTeam,
    super.key,
  });

  final String? initialCode;
  final int? initialPlayersPerTeam;

  @override
  ConsumerState<TournamentJoinScreen> createState() =>
      _TournamentJoinScreenState();
}

final class _TournamentJoinScreenState
    extends ConsumerState<TournamentJoinScreen> {
  late final TextEditingController _code;
  final _teamName = TextEditingController();
  final _players = TextEditingController();
  final _excludedMemberIds = <String>{};
  var _useSavedTeam = true;
  var _busy = false;
  String? _error;

  int get _rosterLimit => (widget.initialPlayersPerTeam ?? 8).clamp(1, 8);

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _teamName.dispose();
    _players.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hub = ref.watch(socialHubProvider);
    final savedTeam = hub.value?.team;
    final canUseSavedTeam =
        savedTeam != null &&
        (savedTeam.role == 'owner' || savedTeam.role == 'admin');
    final detail = savedTeam == null
        ? const AsyncValue<SocialTeamDetail?>.data(null)
        : ref.watch(socialTeamDetailProvider(savedTeam.id)).whenData((v) => v);
    final metrics = context.v9Metrics;

    return BrandScaffold(
      body: AhdashV9Frame(
        child: Column(
          children: [
            AhdashV9TopBar(
              title: 'الانضمام إلى بطولة',
              kicker: 'تسجيل فريق',
              gold: true,
              leading: AhdashV9IconButton(
                icon: Icons.arrow_forward_rounded,
                tooltip: 'رجوع',
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/tournaments'),
              ),
            ),
            SizedBox(height: metrics.sectionGap),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _JoinHeader(compact: metrics.compact),
                        SizedBox(height: metrics.sectionGap),
                        TextField(
                          key: const Key('tournament-join-code'),
                          controller: _code,
                          enabled: !_busy,
                          autofocus: widget.initialCode == null,
                          maxLength: 12,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp('[A-Za-z0-9]'),
                            ),
                          ],
                          textDirection: TextDirection.ltr,
                          decoration: const InputDecoration(
                            labelText: 'رمز البطولة',
                            hintText: 'مثال: A11CUP26',
                            prefixIcon: Icon(Icons.key_rounded),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'يمكن الوصول إلى هذه الصفحة من رابط الدعوة أو QR؛ الرمز يُملأ تلقائيًا عند فتح الرابط.',
                          style: TextStyle(
                            color: context.ahdashColors.textMuted,
                            fontSize: metrics.metadataSize,
                          ),
                        ),
                        SizedBox(height: metrics.sectionGap),
                        Text(
                          'اختر الفريق المشارك',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment<bool>(
                              value: true,
                              enabled: canUseSavedTeam,
                              icon: const Icon(Icons.shield_outlined),
                              label: Text(
                                savedTeam == null
                                    ? 'لا يوجد فريق محفوظ'
                                    : canUseSavedTeam
                                    ? 'فريقي: ${savedTeam.name}'
                                    : 'القائد فقط يسجّل الفريق',
                              ),
                            ),
                            const ButtonSegment<bool>(
                              value: false,
                              icon: Icon(Icons.add_rounded),
                              label: Text('فريق جديد للبطولة'),
                            ),
                          ],
                          selected: {
                            _useSavedTeam && canUseSavedTeam ? true : false,
                          },
                          onSelectionChanged: _busy
                              ? null
                              : (selection) => setState(
                                  () => _useSavedTeam = selection.first,
                                ),
                        ),
                        const SizedBox(height: 12),
                        if (_useSavedTeam && canUseSavedTeam)
                          _savedRoster(detail)
                        else
                          _newTeamFields(),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            key: const Key('tournament-join-error'),
                            style: TextStyle(
                              color: context.ahdashColors.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        SizedBox(height: metrics.sectionGap),
                        AhdashV9PrimaryAction(
                          label: _busy
                              ? 'جارٍ إرسال الطلب…'
                              : 'مراجعة وإرسال الطلب',
                          icon: Icons.how_to_reg_rounded,
                          gold: true,
                          minimumWidth: double.infinity,
                          onPressed: _busy
                              ? null
                              : () => _reviewAndSubmit(
                                  savedTeam: canUseSavedTeam ? savedTeam : null,
                                  detail: detail.value,
                                ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'يراجع منظّم البطولة الطلب. بعد القبول تظهر المشاركة ضمن فريقك وإشعارات البطولة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.ahdashColors.textMuted,
                            fontSize: metrics.metadataSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedRoster(AsyncValue<SocialTeamDetail?> detail) => detail.when(
    loading: () => const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (_, _) => const _JoinNotice(
      icon: Icons.cloud_off_rounded,
      text: 'تعذر تحميل تشكيلة الفريق. حدّث الصفحة أو استخدم فريقًا جديدًا.',
    ),
    data: (team) {
      if (team == null) return const SizedBox.shrink();
      final members = team.members.take(_rosterLimit).toList(growable: false);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تشكيلة البطولة • حتى $_rosterLimit لاعبين',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          for (final member in members)
            CheckboxListTile(
              value: !_excludedMemberIds.contains(member.userId),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: Text(member.displayName),
              subtitle: Text(
                member.role == 'owner' || member.role == 'admin'
                    ? 'قائد الفريق'
                    : 'عضو',
              ),
              onChanged: _busy
                  ? null
                  : (selected) => setState(() {
                      if (selected == false) {
                        _excludedMemberIds.add(member.userId);
                      } else {
                        _excludedMemberIds.remove(member.userId);
                      }
                    }),
            ),
          if (team.members.length > _rosterLimit)
            Text(
              'يعرض النظام أول $_rosterLimit لاعبين بحسب ترتيب الفريق. يمكنك إلغاء أي لاعب قبل الإرسال.',
              style: TextStyle(color: context.ahdashColors.textMuted),
            ),
        ],
      );
    },
  );

  Widget _newTeamFields() => Column(
    children: [
      TextField(
        key: const Key('tournament-new-team-name'),
        controller: _teamName,
        enabled: !_busy,
        maxLength: 40,
        decoration: const InputDecoration(
          labelText: 'اسم الفريق',
          prefixIcon: Icon(Icons.shield_outlined),
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        key: const Key('tournament-new-team-roster'),
        controller: _players,
        enabled: !_busy,
        minLines: 3,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: 'اللاعبون — اسم في كل سطر',
          helperText: 'أول اسم هو القائد • الحد الأعلى $_rosterLimit',
          alignLabelWithHint: true,
          prefixIcon: const Icon(Icons.groups_rounded),
        ),
      ),
    ],
  );

  Future<void> _reviewAndSubmit({
    required SocialTeamSummary? savedTeam,
    required SocialTeamDetail? detail,
  }) async {
    final code = _code.text.trim().toUpperCase();
    final usingSaved = _useSavedTeam && savedTeam != null;
    final teamName = usingSaved ? savedTeam.name : _teamName.text.trim();
    final roster = usingSaved
        ? (detail?.members ?? const <SocialTeamMember>[])
              .where((member) => !_excludedMemberIds.contains(member.userId))
              .take(_rosterLimit)
              .map(
                (member) => <String, Object?>{
                  'user_id': member.userId,
                  'display_name': member.displayName,
                  'is_captain':
                      member.role == 'owner' || member.role == 'admin',
                },
              )
              .toList(growable: false)
        : _players.text
              .split('\n')
              .map((name) => name.trim())
              .where((name) => name.isNotEmpty)
              .take(_rosterLimit)
              .toList(growable: false)
              .indexed
              .map(
                (entry) => <String, Object?>{
                  'user_id': null,
                  'display_name': entry.$2,
                  'is_captain': entry.$1 == 0,
                },
              )
              .toList(growable: false);

    if (code.length < 4) {
      setState(() => _error = 'أدخل رمز بطولة صالحًا.');
      return;
    }
    if (teamName.length < 2) {
      setState(() => _error = 'اسم الفريق يجب أن يكون حرفين على الأقل.');
      return;
    }
    if (roster.isEmpty) {
      setState(() => _error = 'اختر لاعبًا واحدًا على الأقل للتشكيلة.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مراجعة طلب البطولة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الفريق: $teamName'),
            Text('التشكيلة: ${roster.length} لاعبين'),
            const SizedBox(height: 8),
            const Text('سيصل الطلب إلى منظّم البطولة للموافقة.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('تعديل'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إرسال الطلب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(tournamentRegistrationRepositoryProvider)
          .register(inviteCode: code, teamName: teamName, roster: roster);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.hourglass_top_rounded),
          title: const Text('أُرسل طلب الانضمام'),
          content: Text(
            'فريق $teamName الآن قيد مراجعة منظّم البطولة. سنعرض النتيجة في الإشعارات.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('تم'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/tournaments');
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'تعذر إرسال الطلب. تحقق من الرمز، فتح التسجيل، وعدد لاعبي التشكيلة.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

final class _JoinHeader extends StatelessWidget {
  const _JoinHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AhdashPictogramView(
        pictogram: AhdashPictogram.tournament,
        scale: compact
            ? AhdashPictogramScale.compactFeature
            : AhdashPictogramScale.sectionIdentity,
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ادخل البطولة بفريقك',
              style: TextStyle(
                fontSize: context.v9Metrics.heroSize,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'رمز البطولة ← الفريق ← التشكيلة ← موافقة المنظّم',
              style: TextStyle(color: context.ahdashColors.textSecondary),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _JoinNotice extends StatelessWidget {
  const _JoinNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      children: [
        Icon(icon, color: context.ahdashColors.gold),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
