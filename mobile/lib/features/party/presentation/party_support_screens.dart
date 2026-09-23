import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/ahdash_image.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/illustrated_state.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../domain/party_game.dart';
import 'party_game_controller.dart';
import 'party_gameplay_visuals.dart';
import 'party_setup_flow.dart';
import 'party_v2_ui.dart';

final class HowToPlayScreen extends ConsumerWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width <= 370;
    return Scaffold(
      backgroundColor: AppColors.paper0,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 24,
              compact ? 14 : 16,
              compact ? 20 : 24,
              10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'قواعد اللعب وكيفية البدء',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 24 : 26,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'من اختيار الفئات حتى تتويج الفريق الفائز',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.ahdashColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: compact ? 12 : 14),
                const _HowToPlayFacts(),
                SizedBox(height: compact ? 10 : 12),
                Expanded(
                  child: ListView.separated(
                    key: const ValueKey('how-to-play-scroll'),
                    padding: const EdgeInsets.only(bottom: 6),
                    itemCount: _instructionSteps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _InstructionStep(data: _instructionSteps[index]),
                  ),
                ),
                const SizedBox(height: 10),
                PartyPrimaryButton(
                  label: 'فهمت، لنبدأ!',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    ref
                        .read(partyGameControllerProvider.notifier)
                        .beginNewGame();
                    context.go('/party/categories');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _instructionSteps = <_InstructionStepData>[
  _InstructionStepData(
    number: '١',
    title: 'اختر الفئات',
    body: 'اختاروا ٦ فئات كروية؛ في كل فئة ٦ أسئلة بقيم مختلفة.',
    icon: Icons.category_outlined,
    accent: Color(0xFF1E874B),
  ),
  _InstructionStepData(
    number: '٢',
    title: 'كوّن الفرق',
    body: 'سمّوا الفريقين، وزّعوا اللاعبين، ثم اختاروا ٣ مساعدات لكل فريق.',
    icon: Icons.groups_2_outlined,
    accent: Color(0xFFE43D74),
  ),
  _InstructionStepData(
    number: '٣',
    title: 'ابدأوا لوحة الأسئلة',
    body: 'بعد شاشة الجاهزية اختاروا السؤال وتناوبوا مع المؤقت وفرصة الخصم.',
    icon: Icons.grid_view_rounded,
    accent: Color(0xFF4B8DE8),
  ),
  _InstructionStepData(
    number: '٤',
    title: 'احسم الفوز',
    body: 'اكشفوا الجواب واعتمدوا النقاط؛ ثم شاهدوا النتيجة وأعيدوا اللعب.',
    icon: Icons.emoji_events_outlined,
    accent: AppColors.gold,
  ),
];

final class _InstructionStepData {
  const _InstructionStepData({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });

  final String number;
  final String title;
  final String body;
  final IconData icon;
  final Color accent;
}

final class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.data});

  final _InstructionStepData data;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '${data.number}، ${data.title}، ${data.body}',
    child: Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EFE3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: data.accent.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F191714),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: data.accent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.paper0, width: 2),
            ),
            child: Text(
              data.number,
              style: TextStyle(
                color: data.accent.computeLuminance() > 0.58
                    ? AppColors.ink
                    : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: data.accent, size: 19),
          ),
        ],
      ),
    ),
  );
}

final class _HowToPlayFacts extends StatelessWidget {
  const _HowToPlayFacts();

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F7E7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFB9CDA6)),
    ),
    child: const Row(
      children: [
        _HowToPlayFact(icon: Icons.groups_2_outlined, label: 'فريقان'),
        _HowToPlayFactDivider(),
        _HowToPlayFact(icon: Icons.category_outlined, label: '٦ فئات'),
        _HowToPlayFactDivider(),
        _HowToPlayFact(icon: Icons.grid_view_rounded, label: '٣٦ سؤالاً'),
      ],
    ),
  );
}

final class _HowToPlayFact extends StatelessWidget {
  const _HowToPlayFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.palm),
        const SizedBox(width: 5),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _HowToPlayFactDivider extends StatelessWidget {
  const _HowToPlayFactDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 24, color: const Color(0xFFB9CDA6));
}

final class PartyFaqPanel extends StatelessWidget {
  const PartyFaqPanel({super.key});

  static const entries = <(String, String)>[
    ('كيف ألعب؟', 'اختاروا 6 فئات، جهّزوا فريقين، ثم تناوبوا على 36 سؤالًا.'),
    ('كم فئة؟', 'ست فئات بالضبط، ثلاث يختارها كل فريق.'),
    ('كم سؤال؟', 'ستة أسئلة لكل فئة: سؤالان 100 وسؤالان 200 وسؤالان 300.'),
    (
      'كيف تعمل المساعدات؟',
      'كل فريق يختار ثلاثًا، وكل مساعدة مرة واحدة، ومساعدة واحدة فقط لكل سؤال.',
    ),
    ('جاوب جوابين', 'يسمح للفريق بقول إجابتين بدل إجابة واحدة.'),
    (
      'اتصال بصديق',
      'يفتح مؤقتًا داخليًا مستقلًا للاستعانة بصديق حاضر؛ لا يجري مكالمة ولا يطلب جهات الاتصال.',
    ),
    ('الحفرة', 'الإجابة الصحيحة تخصم قيمة السؤال من الخصم.'),
    ('استريح', 'يختار الفريق لاعبًا من الخصم ليكون خارج السؤال الحالي.'),
    ('الفخ', 'يحوّل السؤال للخصم؛ وإجابته الخاطئة تخصم منه.'),
    (
      'هل أقدر أكمل لعبة سابقة؟',
      'نعم. تُحفظ الجولة على الجهاز ويظهر زر «كمّل لعبتكم» في Home.',
    ),
    (
      'ما الفرق بين Free وPremium؟',
      'السياسة المجانية تُدار مركزيًا. Premium شهري أو سنوي ولا يمنح أفضلية داخل الإجابة.',
    ),
    (
      'كيف أبلغ عن سؤال؟',
      'من شاشة السؤال أو الجواب اضغط «بلّغ»، ثم اختر السبب وأرسل.',
    ),
  ];

  @override
  Widget build(BuildContext context) => PartyV2Canvas(
    motion: false,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded),
              const SizedBox(width: 8),
              Text(
                'الأسئلة الشائعة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) => ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                title: Text(
                  entries[index].$1,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      entries[index].$2,
                      style: TextStyle(
                        color: context.ahdashColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

final class PartyGamesScreen extends ConsumerStatefulWidget {
  const PartyGamesScreen({super.key});

  @override
  ConsumerState<PartyGamesScreen> createState() => _PartyGamesScreenState();
}

final class _PartyGamesScreenState extends ConsumerState<PartyGamesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(partyGameControllerProvider.notifier).restore(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partyState = ref.watch(partyGameControllerProvider);
    final session = partyState.session;
    final metrics = context.v9Metrics;
    if (metrics.portrait) {
      return SavedGamesPortraitPage(
        restored: partyState.restored,
        sessions: [
          ?session,
          ...partyState.history.where((item) => item.id != session?.id),
        ],
        onOpen: (game) =>
            context.go(PartySetupFlowResolver.routeForSession(game)),
        onStart: _startNewGame,
        onHome: () => context.go('/home'),
      );
    }
    return _SupportScaffold(
      title: 'ألعابي',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (partyState.history.isNotEmpty)
            TextButton.icon(
              onPressed: () => _showHistory(partyState.history),
              icon: const Icon(Icons.history_rounded),
              label: const Text('السجل'),
            ),
          TextButton(onPressed: _startNewGame, child: const Text('لعبة جديدة')),
        ],
      ),
      child: !partyState.restored
          ? const Center(child: CircularProgressIndicator())
          : session == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AhdashPictogramView(
                    pictogram: AhdashPictogram.emptyGames,
                    scale: AhdashPictogramScale.emptyState,
                    semanticLabel: 'لا توجد لعبة محفوظة',
                  ),
                  SizedBox(height: metrics.compact ? 6 : 12),
                  Text(
                    'ما عندكم لعبة محفوظة الآن',
                    style: TextStyle(
                      fontSize: metrics.sectionSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!metrics.compact) ...[
                    const SizedBox(height: 6),
                    Text(
                      'ابدأوا جولة جديدة، ونحفظ تقدّمكم تلقائيًا على هذا الجهاز.',
                      style: TextStyle(
                        color: context.ahdashColors.textSecondary,
                        fontSize: metrics.bodySize,
                      ),
                    ),
                  ],
                  SizedBox(height: metrics.compact ? 10 : 18),
                  SizedBox(
                    width: metrics.compact ? 200 : 250,
                    child: PartyPrimaryButton(
                      label: 'ابدأ لعبة',
                      onPressed: _startNewGame,
                    ),
                  ),
                ],
              ),
            )
          : metrics.portrait
          ? _SavedPartyPortrait(
              session: session,
              onResume: () =>
                  context.go(PartySetupFlowResolver.routeForSession(session)),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Row(
                  children: [
                    const AhdashPictogramView(
                      pictogram: AhdashPictogram.teamsStep,
                      scale: AhdashPictogramScale.sectionIdentity,
                    ),
                    SizedBox(width: metrics.compact ? 18 : 30),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            session.isComplete
                                ? 'اللعبة الأخيرة'
                                : 'اللعبة الحالية',
                            style: TextStyle(
                              color: context.ahdashColors.primary,
                              fontSize: metrics.metadataSize,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: metrics.compact ? 2 : 6),
                          Row(
                            children: [
                              PartyTeamDot(
                                color: Color(session.teams[0].colorValue),
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${session.teams[0].name} × ${session.teams[1].name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: metrics.teamNameSize,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PartyTeamDot(
                                color: Color(session.teams[1].colorValue),
                                size: 12,
                              ),
                            ],
                          ),
                          SizedBox(height: metrics.compact ? 8 : 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: metrics.compact ? 6 : 8,
                              value:
                                  session.questions
                                      .where((question) => question.used)
                                      .length /
                                  36,
                              backgroundColor:
                                  context.ahdashColors.surfaceMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${session.questions.where((question) => question.used).length} من 36 سؤالًا • ${session.isComplete ? 'مكتملة' : 'محفوظة على هذا الجهاز'}',
                            style: TextStyle(
                              color: session.isComplete
                                  ? context.ahdashColors.success
                                  : context.ahdashColors.textSecondary,
                              fontSize: metrics.metadataSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: metrics.compact ? 18 : 32),
                    Text(
                      '${session.scores[0]} — ${session.scores[1]}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: metrics.scoreSize,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: metrics.compact ? 18 : 32),
                    SizedBox(
                      width: metrics.compact ? 170 : 220,
                      child: PartyPrimaryButton(
                        label: session.isComplete
                            ? 'عرض النتيجة'
                            : 'كمّل لعبتك',
                        onPressed: () => context.go(
                          PartySetupFlowResolver.routeForSession(session),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _startNewGame() {
    ref.read(partyGameControllerProvider.notifier).beginNewGame();
    context.go('/party/categories');
  }

  Future<void> _showHistory(List<PartyGameSession> history) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.86,
          child: _GameHistorySheet(history: history),
        ),
      );
}

/// Stateless saved-session surface, split from persistence orchestration so
/// every deterministic UI state can be exercised without touching storage.
final class SavedGamesPortraitPage extends StatelessWidget {
  const SavedGamesPortraitPage({
    super.key,
    required this.restored,
    required this.sessions,
    required this.onOpen,
    required this.onStart,
    required this.onHome,
  });

  final bool restored;
  final List<PartyGameSession> sessions;
  final ValueChanged<PartyGameSession> onOpen;
  final VoidCallback onStart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width <= 370;
    return Scaffold(
      backgroundColor: AppColors.paper0,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 24,
              16,
              compact ? 20 : 24,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'الجلسات المحفوظة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 26 : 28,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ارجع للمجلس وكمل من آخر سؤال',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.ahdashColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: compact ? 16 : 18),
                if (restored && sessions.isNotEmpty) ...[
                  _SavedGamesToolbar(sessions: sessions, onStart: onStart),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: !restored
                      ? const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LoadingSkeleton(lines: 4),
                        )
                      : sessions.isEmpty
                      ? _SavedGamesEmptyState(onStart: onStart)
                      : Scrollbar(
                          child: ListView.separated(
                            key: const ValueKey('saved-games-list'),
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: sessions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) => _SavedGameCard(
                              game: sessions[index],
                              current:
                                  index == 0 && !sessions[index].isComplete,
                              onOpen: () => onOpen(sessions[index]),
                            ),
                          ),
                        ),
                ),
                TextButton.icon(
                  onPressed: onHome,
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('العودة للرئيسية'),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _SavedGamesToolbar extends StatelessWidget {
  const _SavedGamesToolbar({required this.sessions, required this.onStart});

  final List<PartyGameSession> sessions;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final active = sessions.where((game) => !game.isComplete).length;
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7E7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB9CDA6)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_added_outlined,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _savedSessionsLabel(sessions.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  active == 0
                      ? 'كل الجولات مكتملة'
                      : '${_savedArabicDigits(active)} جاهزة للاستئناف',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.ahdashColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onStart,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'لعبة جديدة',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SavedGamesEmptyState extends StatelessWidget {
  const _SavedGamesEmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => AhdashIllustratedState(
    asset: 'assets/visuals/saved_games_empty_cutout_v1.png',
    title: 'لا توجد جلسة محفوظة',
    message: 'ابدأ لعبة جماعية، ونحفظ تقدّم المجلس تلقائيًا على هذا الجهاز.',
    action: PartyPrimaryButton(
      label: 'ابدأ لعبة',
      icon: Icons.play_arrow_rounded,
      onPressed: onStart,
    ),
  );
}

final class _SavedGameCard extends StatelessWidget {
  const _SavedGameCard({
    required this.game,
    required this.current,
    required this.onOpen,
  });

  final PartyGameSession game;
  final bool current;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final compact = MediaQuery.sizeOf(context).width <= 370;
    final used = game.questions.where((question) => question.used).length;
    final total = game.questions.length;
    final remaining = (total - used).clamp(0, total);
    final progress = total == 0 ? 0.0 : used / total;
    final category = game.categories.firstOrNull;
    final categoryNames = game.categories.isEmpty
        ? 'مجلس كروي'
        : game.categories.take(2).map((item) => item.name).join('  •  ');
    final accent = category == null
        ? AppColors.palm
        : Color(category.colorValue);

    return Semantics(
      container: true,
      label: game.isComplete
          ? 'جلسة مكتملة، ${game.teams[0].name} ضد ${game.teams[1].name}'
          : 'جلسة محفوظة، ${game.teams[0].name} ضد ${game.teams[1].name}',
      child: Container(
        padding: EdgeInsets.all(compact ? 13 : 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF7EFE3),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD5C5AF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14191714),
              offset: Offset(0, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: compact ? 54 : 60,
                  child: AhdashImage(
                    imageUrl: category?.imageUrl,
                    fallbackWidget: _SavedGameCoverFallback(accent: accent),
                    aspectRatio: 1,
                    alignment: Alignment(
                      (category?.focalX ?? 0.5) * 2 - 1,
                      (category?.focalY ?? 0.5) * 2 - 1,
                    ),
                    borderRadius: 14,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            flex: 3,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: _SavedGameStatusBadge(
                                complete: game.isComplete,
                                current: current,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            flex: 2,
                            child: Text(
                              _savedGameDate(game),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        categoryNames,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _SavedTeamScore(
                    team: game.teams[0],
                    score: game.scores[0],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.paper0,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD5C5AF)),
                    ),
                    child: Text(
                      'ضد',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _SavedTeamScore(
                    team: game.teams[1],
                    score: game.scores[1],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  game.isComplete
                      ? 'اكتملت الجولة'
                      : '${_savedArabicDigits(remaining)} سؤالاً متبقياً',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_savedArabicDigits(used)}/${_savedArabicDigits(total)}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.paper0,
                color: game.isComplete ? colors.success : AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            PartyPrimaryButton(
              label: game.isComplete ? 'عرض النتيجة' : 'استمر في اللعب',
              icon: game.isComplete
                  ? Icons.leaderboard_outlined
                  : Icons.play_arrow_rounded,
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}

final class _SavedGameStatusBadge extends StatelessWidget {
  const _SavedGameStatusBadge({required this.complete, required this.current});

  final bool complete;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? context.ahdashColors.success
        : current
        ? AppColors.ink
        : AppColors.najdiClay;
    final label = complete
        ? 'مكتملة'
        : current
        ? 'اللعبة الحالية'
        : 'محفوظة';
    return Container(
      constraints: const BoxConstraints(maxWidth: 135),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: complete ? 0.11 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SavedTeamScore extends StatelessWidget {
  const _SavedTeamScore({required this.team, required this.score});

  final PartyTeam team;
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = Color(team.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PartyTeamDot(color: color, size: 7),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _savedArabicDigits(score),
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

final class _SavedGameCoverFallback extends StatelessWidget {
  const _SavedGameCoverFallback({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent.withValues(alpha: 0.92), AppColors.ink],
      ),
    ),
    child: PartyGameplayArtwork(
      scene: PartyGameplayArtworkScene.category,
      accent: AppColors.primary,
      onDark: true,
    ),
  );
}

const _savedArabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String _savedGameDate(PartyGameSession game) {
  final date = (game.completedAt ?? game.createdAt).toLocal();
  return '${_savedArabicDigits(date.day)} ${_savedArabicMonths[date.month - 1]}';
}

String _savedArabicDigits(int value) {
  const western = '0123456789';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((char) {
    final index = western.indexOf(char);
    return index < 0 ? char : arabic[index];
  }).join();
}

String _savedSessionsLabel(int count) => switch (count) {
  1 => 'جلسة محفوظة',
  2 => 'جلستان محفوظتان',
  _ => '${_savedArabicDigits(count)} جلسات محفوظة',
};

final class _GameHistorySheet extends StatelessWidget {
  const _GameHistorySheet({required this.history});

  final List<PartyGameSession> history;

  @override
  Widget build(BuildContext context) => Material(
    color: context.ahdashColors.surface,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded),
              const SizedBox(width: 8),
              Text(
                'سجل الألعاب',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'إغلاق',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final game = history[index];
                final winnerIndex = game.scores[0] == game.scores[1]
                    ? null
                    : game.scores[0] > game.scores[1]
                    ? 0
                    : 1;
                final date = game.completedAt ?? game.createdAt;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.ahdashColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.ahdashColors.border),
                  ),
                  child: ListTile(
                    leading: Icon(
                      winnerIndex == null
                          ? Icons.handshake_outlined
                          : Icons.emoji_events_outlined,
                      color: context.ahdashColors.gold,
                    ),
                    title: Text(
                      '${game.teams[0].name} × ${game.teams[1].name}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      '${date.year}/${date.month}/${date.day} • ${game.categories.map((category) => category.name).join('، ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${game.scores[0]} — ${game.scores[1]}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

final class _SavedPartyPortrait extends StatelessWidget {
  const _SavedPartyPortrait({required this.session, required this.onResume});

  final PartyGameSession session;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: AhdashPictogramView(
              pictogram: AhdashPictogram.teamsStep,
              scale: AhdashPictogramScale.sectionIdentity,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            session.isComplete ? 'اللعبة الأخيرة' : 'اللعبة الحالية',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.ahdashColors.primary,
              fontSize: context.v9Metrics.metadataSize,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              PartyTeamDot(color: Color(session.teams[0].colorValue), size: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${session.teams[0].name} × ${session.teams[1].name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.v9Metrics.teamNameSize,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PartyTeamDot(color: Color(session.teams[1].colorValue), size: 12),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value:
                  session.questions.where((question) => question.used).length /
                  36,
              backgroundColor: context.ahdashColors.surfaceMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${session.questions.where((question) => question.used).length} من 36 سؤالًا • ${session.isComplete ? 'مكتملة' : 'محفوظة على هذا الجهاز'}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: session.isComplete
                  ? context.ahdashColors.success
                  : context.ahdashColors.textSecondary,
              fontSize: context.v9Metrics.metadataSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${session.scores[0]} — ${session.scores[1]}',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: context.v9Metrics.scoreSize,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          PartyPrimaryButton(
            label: session.isComplete ? 'عرض النتيجة' : 'كمّل لعبتك',
            onPressed: onResume,
          ),
        ],
      ),
    ),
  );
}

final class _SupportScaffold extends StatelessWidget {
  const _SupportScaffold({
    required this.title,
    required this.child,
    required this.trailing,
  });

  final String title;
  final Widget child;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => AhdashV10Page(
    title: title,
    subtitle: 'دليل اللعب الحقيقي',
    onBack: () => context.go('/home'),
    actions: [trailing],
    child: child,
  );
}
