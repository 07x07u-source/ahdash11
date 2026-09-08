import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/theme/ahdash_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_game_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/presentation/ahdash_image.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/connectivity_status_banner.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../game/application/game_clock.dart';
import '../../game/application/game_session_controller.dart';
import '../../game/presentation/ahdash_game.dart';
import '../data/online_match_gateway.dart';
import '../domain/quiz_question.dart';
import 'game_widgets.dart';

final class OnlineMatchScreen extends ConsumerStatefulWidget {
  const OnlineMatchScreen({
    required this.matchId,
    this.clock = const SystemGameClock(),
    super.key,
  });

  final String matchId;
  final GameClock clock;

  @override
  ConsumerState<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

final class _OnlineMatchScreenState extends ConsumerState<OnlineMatchScreen>
    with WidgetsBindingObserver {
  late final GameSessionController _controller;
  late GameSessionState _session;
  AhdashGame? _game;
  bool? _gameReducedMotion;
  Map<String, Object?>? _finishedFallback;
  String? _lastRevealId;
  var _checkingFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = GameSessionController(
      matchId: widget.matchId,
      gateway: SupabaseOnlineMatchGateway(Supabase.instance.client),
      clock: widget.clock,
    );
    _session = _controller.state;
    _controller.addListener(_onSessionChanged);
    unawaited(_controller.start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final adapter = FlameGameThemeAdapter.fromAppTheme(context.gameTheme);
    if (_game == null || _gameReducedMotion != reduceMotion) {
      _game?.dispose();
      _game = AhdashGame(theme: adapter, reduceMotion: reduceMotion);
      _gameReducedMotion = reduceMotion;
    } else {
      _game!.updateTheme(adapter);
    }
    _syncGameTimer(_session);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _game?.resumeEngine();
        if (_session.phase != GameSessionPhase.completed) {
          unawaited(_controller.recover());
        }
      case AppLifecycleState.inactive ||
          AppLifecycleState.paused ||
          AppLifecycleState.hidden:
        _game?.pauseEngine();
      case AppLifecycleState.detached:
        _game?.pauseEngine();
    }
  }

  void _onSessionChanged() {
    if (!mounted) return;
    final next = _controller.state;
    _syncGameTimer(next);
    final reveal = next.reveal;
    if (reveal != null && reveal.questionId != _lastRevealId) {
      _lastRevealId = reveal.questionId;
      final correct = next.selectedOptionId == reveal.correctOptionId;
      final game = _game;
      if (game != null) unawaited(game.showVerdict(correct: correct));
      unawaited(
        ref
            .read(feedbackServiceProvider)
            .play(correct ? FeedbackCue.correct : FeedbackCue.wrong),
      );
    }
    setState(() => _session = next);
    if (next.phase == GameSessionPhase.failed &&
        next.question == null &&
        !_checkingFinished) {
      unawaited(_loadFinishedState());
    }
  }

  void _syncGameTimer(GameSessionState state) {
    final question = state.question;
    if (question == null || question.durationMs <= 0) return;
    _game?.updateTimerFraction(
      state.remaining.inMilliseconds / question.durationMs,
    );
  }

  Future<void> _loadFinishedState() async {
    _checkingFinished = true;
    try {
      final match = await Supabase.instance.client
          .from('matches')
          .select('status, winner_team')
          .eq('id', widget.matchId)
          .single();
      if (match['status'] != 'finished') return;
      final players = await Supabase.instance.client
          .from('match_players')
          .select(
            'display_name_snapshot, team, score, correct_answers, wrong_answers, '
            'xp_awarded, coins_awarded, rating_before, rating_after',
          )
          .eq('match_id', widget.matchId)
          .order('team');
      if (!mounted) return;
      setState(() {
        _finishedFallback = {
          'state': 'finished',
          'winner_team': match['winner_team'],
          'players': players,
        };
      });
    } catch (_) {
      // The controller keeps the actionable recovery state on screen.
    } finally {
      _checkingFinished = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_onSessionChanged)
      ..dispose();
    _game?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameType = _session.question?.gameType;
    final metrics = context.v9Metrics;
    return BrandScaffold(
      body: AhdashGameWorld(
        child: AhdashV9Frame(
          child: Column(
            children: [
              AhdashV9TopBar(
                title: 'مواجهة مباشرة',
                kicker: switch (gameType) {
                  'speed' => 'السرعة',
                  'true-false' => 'صح أو خطأ',
                  _ => 'كلاسيك',
                },
                leading: AhdashV9IconButton(
                  icon: AhdashIcons.close,
                  tooltip: 'إنهاء العرض والعودة',
                  onPressed: () => context.go('/play'),
                ),
              ),
              const ConnectivityStatusBanner(),
              SizedBox(height: metrics.compact ? 4 : 8),
              Expanded(
                child: AccessibilityViewport(child: _buildContent(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final finalResult = _session.finalResult ?? _finishedFallback;
    if (finalResult != null) return _OnlineResult(result: finalResult);

    final game = _game;
    if (game == null) return const LoadingSkeleton(lines: 5);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: GameWidget<AhdashGame>(
              game: game,
              addRepaintBoundary: true,
              loadingBuilder: (_) => const SizedBox.shrink(),
              errorBuilder: (_, _) => const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: _buildOverlay(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final colors = context.ahdashColors;
    final question = _session.question;
    if (_session.phase == GameSessionPhase.bootstrapping) {
      return const Center(child: LoadingSkeleton(lines: 4));
    }
    if (question == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceElevated.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 54, color: colors.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text(
                _session.error ?? 'حالة المباراة غير متاحة.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _controller.recover,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('استعادة المباراة'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 430;
        final shortLandscape = constraints.maxHeight <= 330;
        final action = _OnlineActionStrip(
          state: _session,
          onRecover: _controller.recover,
          onRetrySubmission: _controller.retryPendingSubmission,
          onNextQuestion: _controller.nextQuestion,
        );
        final showAction =
            _session.error != null ||
            _session.reveal != null ||
            _session.phase == GameSessionPhase.submittingAnswer ||
            _session.phase == GameSessionPhase.revealingVerdict;
        final answerStage = Column(
          children: [
            Expanded(
              child: _AnswerBoard(
                question: question,
                state: _session,
                onAnswer: _submit,
              ),
            ),
            if (showAction) ...[
              const SizedBox(height: AppSpacing.xs),
              SizedBox(height: compact ? 44 : 48, child: action),
            ],
          ],
        );
        return Column(
          children: [
            _GameHud(question: question, state: _session),
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
            Expanded(
              child: question.imageUrl == null && !shortLandscape
                  ? Column(
                      children: [
                        SizedBox(
                          height: compact
                              ? (constraints.maxHeight * 0.32).clamp(88, 116)
                              : (constraints.maxHeight * 0.38).clamp(150, 210),
                          child: GamePanel(
                            tone: GameSurfaceTone.raised,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 24 : 48,
                              vertical: compact ? 12 : 20,
                            ),
                            child: _OnlineQuestionPanel(
                              question: question,
                              compact: compact,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.xs : AppSpacing.sm,
                        ),
                        Expanded(child: answerStage),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: shortLandscape ? 5 : 6,
                          child: GamePanel(
                            tone: GameSurfaceTone.raised,
                            padding: EdgeInsets.all(
                              compact ? AppSpacing.sm : AppSpacing.md,
                            ),
                            child: _OnlineQuestionPanel(
                              question: question,
                              compact: compact,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: compact ? AppSpacing.xs : AppSpacing.sm,
                        ),
                        Expanded(
                          flex: shortLandscape ? 7 : 6,
                          child: answerStage,
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  void _submit(int index) {
    if (!_session.canAnswer) return;
    unawaited(ref.read(feedbackServiceProvider).play(FeedbackCue.selection));
    unawaited(_controller.submitAnswer(index));
  }
}

final class _OnlineQuestionPanel extends StatelessWidget {
  const _OnlineQuestionPanel({required this.question, required this.compact});

  final PublicQuestion question;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final metrics = context.v9Metrics;
    final length = question.text.characters.length;
    final questionSize = length > 100
        ? 24.0
        : length > 60
        ? 26.0
        : metrics.compact
        ? 28.0
        : 32.0;
    final text = Text(
      question.text,
      textAlign: TextAlign.center,
      maxLines: compact ? 5 : 7,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.question.copyWith(
        color: colors.textPrimary,
        fontSize: question.imageUrl == null
            ? questionSize
            : questionSize.clamp(22, 26),
        height: 1.25,
      ),
    );
    final imageUrl = question.imageUrl;
    if (imageUrl == null) return Center(child: text);
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Center(
            child: AhdashImage(
              imageUrl: imageUrl,
              fallbackAsset: 'assets/visuals/eagle-eye-cover.png',
              aspectRatio: 16 / 9,
              semanticLabel: 'وسيط السؤال',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 4, child: text),
      ],
    );
  }
}

final class _OnlineActionStrip extends StatelessWidget {
  const _OnlineActionStrip({
    required this.state,
    required this.onRecover,
    required this.onRetrySubmission,
    required this.onNextQuestion,
  });

  final GameSessionState state;
  final VoidCallback onRecover;
  final VoidCallback onRetrySubmission;
  final VoidCallback onNextQuestion;

  @override
  Widget build(BuildContext context) {
    if (state.error != null) {
      return _RecoveryBar(
        message: state.error!,
        retrySubmission: state.canRetrySubmission,
        onRetry: state.canRetrySubmission ? onRetrySubmission : onRecover,
      );
    }
    if (state.reveal != null) {
      return SizedBox.expand(
        child: FilledButton.icon(
          onPressed: state.phase == GameSessionPhase.transitioning
              ? null
              : onNextQuestion,
          icon: const Icon(Icons.arrow_back_rounded),
          label: Text(
            state.phase == GameSessionPhase.transitioning
                ? 'جارٍ المزامنة…'
                : 'السؤال التالي',
          ),
        ),
      );
    }
    if (state.phase == GameSessionPhase.submittingAnswer ||
        (state.phase == GameSessionPhase.revealingVerdict &&
            state.reveal == null)) {
      return const _ServerStatus(
        icon: Icons.lock_clock_rounded,
        label: 'تم تثبيت إجابتك • ننتظر حكم الخادم',
      );
    }
    return const SizedBox.shrink();
  }
}

final class _GameHud extends StatelessWidget {
  const _GameHud({required this.question, required this.state});

  final PublicQuestion question;
  final GameSessionState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final seconds = (state.remaining.inMilliseconds / 1000).ceil();
    final fraction = question.durationMs <= 0
        ? 0.0
        : (state.remaining.inMilliseconds / question.durationMs)
              .clamp(0.0, 1.0)
              .toDouble();
    final danger = seconds <= 5;
    final typeLabel = switch (question.gameType) {
      'speed' => 'السرعة',
      'true-false' => 'صح أو خطأ',
      _ => 'كلاسيك',
    };
    return Semantics(
      container: true,
      label: '$typeLabel، الجولة ${question.roundIndex}، متبقٍ $seconds ثانية',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(switch (question.gameType) {
                'speed' => Icons.bolt_rounded,
                'true-false' => Icons.rule_rounded,
                _ => Icons.grid_view_rounded,
              }, color: colors.primary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'جولة ${question.roundIndex}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 9,
                  color: danger ? colors.dangerTimer : colors.primary,
                  backgroundColor: colors.surfaceMuted,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (danger ? colors.dangerTimer : colors.primary)
                    .withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Text(
                '$seconds',
                textDirection: TextDirection.ltr,
                style: AppTypography.score.copyWith(
                  fontSize: 18,
                  color: danger ? colors.dangerTimer : colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AnswerBoard extends StatelessWidget {
  const _AnswerBoard({
    required this.question,
    required this.state,
    required this.onAnswer,
  });

  final PublicQuestion question;
  final GameSessionState state;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final shortAnswers = question.options.every(
          (value) => value.length <= 34,
        );
        final grid =
            question.options.length <= 4 &&
            constraints.maxHeight >= 160 &&
            textScale <= 1.25;

        Widget answer(int index) {
          final optionId = question.optionIds[index];
          final selected = state.selectedOptionId == optionId;
          final correct = state.reveal?.correctOptionId == optionId;
          final wrong = state.reveal != null && selected && !correct;
          final visualState = correct
              ? AnswerVisualState.correct
              : wrong
              ? AnswerVisualState.wrong
              : selected
              ? AnswerVisualState.selected
              : state.reveal != null || !state.canAnswer
              ? AnswerVisualState.locked
              : AnswerVisualState.neutral;
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: AnswerOptionCard(
              index: index,
              text: question.options[index],
              state: visualState,
              onTap: state.canAnswer ? () => onAnswer(index) : null,
            ),
          );
        }

        if (grid) {
          final columns = constraints.maxWidth >= 300 && shortAnswers ? 2 : 1;
          final rows = (question.options.length / columns).ceil();
          return Column(
            children: List.generate(rows, (row) {
              final cells = <Widget>[];
              for (var column = 0; column < columns; column++) {
                if (column > 0) {
                  cells.add(const SizedBox(width: AppSpacing.xs));
                }
                final index = row * columns + column;
                cells.add(
                  Expanded(
                    child: index < question.options.length
                        ? SizedBox.expand(child: answer(index))
                        : const SizedBox.shrink(),
                  ),
                );
              }
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: row == rows - 1 ? 0 : AppSpacing.xs,
                  ),
                  child: Row(children: cells),
                ),
              );
            }),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: question.options.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (_, index) => answer(index),
        );
      },
    );
  }
}

final class _ServerStatus extends StatelessWidget {
  const _ServerStatus({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 17,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

final class _RecoveryBar extends StatelessWidget {
  const _RecoveryBar({
    required this.message,
    required this.retrySubmission,
    required this.onRetry,
  });

  final String message;
  final bool retrySubmission;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.sync_problem_rounded, color: colors.warning),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(message)),
            TextButton(
              onPressed: onRetry,
              child: Text(retrySubmission ? 'إعادة آمنة' : 'استعادة'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _OnlineResult extends StatelessWidget {
  const _OnlineResult({required this.result});

  final Map<String, Object?> result;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final players = ((result['players'] as List?) ?? const [])
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
    final winner = result['winner_team'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 390;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: GamePanel(
                tone: GameSurfaceTone.gold,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: compact ? 40 : 58,
                      color: colors.gold,
                    ),
                    SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                    Text(
                      'انتهت المواجهة',
                      textAlign: TextAlign.center,
                      style:
                          (compact
                                  ? Theme.of(context).textTheme.headlineSmall
                                  : Theme.of(context).textTheme.headlineLarge)
                              ?.copyWith(color: colors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      winner == null
                          ? 'النتيجة النهائية معتمدة من الخادم'
                          : 'الفائز • الفريق ${winner.toString().toUpperCase()}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 7,
              child: GamePanel(
                tone: GameSurfaceTone.raised,
                child: Column(
                  children: [
                    CompactSectionTitle(
                      eyebrow: 'SERVER RESULT',
                      title: 'لوحة المواجهة',
                      trailing: Text(
                        '${players.length} لاعبين',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(
                      child: GamePagedList<Map<String, Object?>>(
                        items: players,
                        pageSize: compact ? 3 : 4,
                        aspectRatio: compact ? 11 : 9,
                        empty: Center(
                          child: Text(
                            'لا توجد تفاصيل لاعبين متاحة.',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                        itemBuilder: (_, player, _) =>
                            _OnlinePlayerResult(player: player),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                context.go('/play/setup/classic?format=1v1'),
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('العب مرة ثانية'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/play'),
                            child: const Text('ارجع للعب'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _OnlinePlayerResult extends StatelessWidget {
  const _OnlinePlayerResult({required this.player});

  final Map<String, Object?> player;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final name =
        player['display_name'] ?? player['display_name_snapshot'] ?? 'لاعب';
    return GamePanel(
      cut: 8,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.primary.withValues(alpha: 0.12),
            child: Text(
              '${player['team'] ?? '-'}'.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${player['correct_answers'] ?? 0} صحيحة • '
                  '+${player['xp_awarded'] ?? 0} XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${player['score'] ?? 0}',
            textDirection: TextDirection.ltr,
            style: AppTypography.score.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
