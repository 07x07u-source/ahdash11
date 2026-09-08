import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../domain/party_game.dart';
import 'party_game_controller.dart';
import 'party_setup_flow.dart';
import 'party_v2_ui.dart';

final class HowToPlayScreen extends ConsumerWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: AppColors.paper0,
    body: SafeArea(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    'قواعد اللعب وكيفية البدء',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  key: const ValueKey('how-to-play-scroll'),
                  children: const [
                    _InstructionStep(
                      number: '١',
                      title: 'اختر الفئات',
                      body: 'حدد ست فئات متاحة للجولة، ثلاث يختارها كل فريق.',
                      icon: Icons.category_outlined,
                    ),
                    _InstructionStep(
                      number: '٢',
                      title: 'كوّن الفرق',
                      body:
                          'سمّ الفريقين، وأضف اللاعبين اختياريًا، ثم اختر المساعدات.',
                      icon: Icons.groups_2_outlined,
                    ),
                    _InstructionStep(
                      number: '٣',
                      title: 'جاوب على الأسئلة',
                      body:
                          'اختاروا قيمة السؤال، ناقشوا الإجابة، ثم اكشفوا الجواب.',
                      icon: Icons.grid_view_rounded,
                    ),
                    _InstructionStep(
                      number: '٤',
                      title: 'احسم الفوز',
                      body:
                          'المضيف يمنح النقاط يدويًا، والفريق الأعلى نقاطًا يفوز.',
                      icon: Icons.emoji_events_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AhdashV10PrimaryButton(
                label: 'فهمت، لنبدأ!',
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  ref.read(partyGameControllerProvider.notifier).beginNewGame();
                  context.go('/party/categories');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String number;
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: AhdashV10Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      semanticLabel: '$number، $title، $body',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF1E7A42),
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
                  title,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 14,
                    height: 1.35,
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper0,
    body: SafeArea(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'الجلسات المحفوظة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              Text(
                'تابع لعبتك من حيث توقفت مع رفاقك',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.ahdashColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: !restored
                    ? const LoadingSkeleton(lines: 4)
                    : sessions.isEmpty
                    ? AppMessageState(
                        icon: Icons.sports_esports_outlined,
                        title: 'لا توجد جلسة محفوظة',
                        message:
                            'ابدأ لعبة جماعية، وسيُحفظ تقدّم المجلس تلقائيًا على هذا الجهاز.',
                        actionLabel: 'ابدأ لعبة',
                        onAction: onStart,
                      )
                    : ListView.separated(
                        itemCount: sessions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final game = sessions[index];
                          final category = game.categories.isEmpty
                              ? 'مجلس كروي'
                              : game.categories.first.name;
                          return Container(
                            constraints: const BoxConstraints(minHeight: 176),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4EBDD),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFD3C6B2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFD19B26),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        game.isComplete
                                            ? 'مكتملة'
                                            : 'محفوظة على هذا الجهاز',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          color: context.ahdashColors.textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      '${game.scores[0]}',
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        game.teams[0].name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const Text('ضد'),
                                    Expanded(
                                      child: Text(
                                        game.teams[1].name,
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${game.scores[1]}',
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                PartyPrimaryButton(
                                  label: game.isComplete
                                      ? 'عرض النتيجة'
                                      : 'استمر في اللعب',
                                  onPressed: () => onOpen(game),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              TextButton(
                onPressed: onHome,
                child: const Text('العودة للرئيسية'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

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
