import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_game_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/ahdash_image.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/editorial_v6.dart';
import '../../game/domain/game_mode.dart';
import '../../game/presentation/ahdash_game.dart';
import 'solo_match_controller.dart';

final class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

final class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  Timer? _timer;
  Timer? _revealTimer;
  double _remainingSeconds = 15;
  var _lastQuestionIndex = -1;
  var _lastWarningSecond = -1;
  var _nextScheduled = false;
  AhdashGame? _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adapter = FlameGameThemeAdapter.fromAppTheme(context.gameTheme);
    _game ??= AhdashGame(
      theme: adapter,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    _game!.updateTheme(adapter);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(soloMatchControllerProvider, (previous, next) {
      if (next.status == SoloMatchStatus.answering &&
          next.currentIndex != _lastQuestionIndex) {
        _lastQuestionIndex = next.currentIndex;
        _nextScheduled = false;
        _revealTimer?.cancel();
        _startTimer(next);
        _prefetchNext(next);
      }
      if (next.status == SoloMatchStatus.revealed && !_nextScheduled) {
        _timer?.cancel();
        _nextScheduled = true;
        final correct = next.records.last.correct;
        unawaited(_game?.showVerdict(correct: correct));
        ref
            .read(feedbackServiceProvider)
            .play(correct ? FeedbackCue.correct : FeedbackCue.wrong);
        _revealTimer?.cancel();
        _revealTimer = Timer(AppMotion.feedbackHold, () async {
          if (!mounted) return;
          await ref.read(soloMatchControllerProvider.notifier).nextQuestion();
        });
      }
      if (next.status == SoloMatchStatus.finished) {
        _timer?.cancel();
        _revealTimer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/solo/result');
        });
      }
    });

    final match = ref.watch(soloMatchControllerProvider);
    if (match.status == SoloMatchStatus.answering &&
        match.currentIndex != _lastQuestionIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || match.currentIndex == _lastQuestionIndex) return;
        _lastQuestionIndex = match.currentIndex;
        _nextScheduled = false;
        _startTimer(match);
        _prefetchNext(match);
      });
    }
    return BrandScaffold(
      body: AhdashEditorialCanvas(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.16,
                  child: ClipRect(child: GameWidget<AhdashGame>(game: _game!)),
                ),
              ),
            ),
            Positioned.fill(child: _body(match)),
          ],
        ),
      ),
    );
  }

  Widget _body(SoloMatchState match) {
    if (match.status == SoloMatchStatus.loading ||
        match.status == SoloMatchStatus.idle) {
      return const EditorialPageFrame(
        child: Center(child: LoadingSkeleton(lines: 5)),
      );
    }
    if (match.status == SoloMatchStatus.error) {
      return AppMessageState(
        icon: Icons.error_outline_rounded,
        title: 'تعذر بدء المباراة',
        message: match.errorMessage ?? 'حاول مرة أخرى.',
        actionLabel: 'العودة للإعدادات',
        onAction: () => context.go('/solo'),
      );
    }
    final question = match.currentQuestion;
    if (question == null) return const SizedBox.shrink();
    final seconds = _remainingSeconds.ceil().clamp(
      0,
      match.settings.questionTimeSeconds,
    );
    final progress = (_remainingSeconds / match.settings.questionTimeSeconds)
        .clamp(0.0, 1.0);
    return EditorialPageFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactHeight = constraints.maxHeight < 430;
          final revealed = match.status == SoloMatchStatus.revealed;
          final prompt = _QuestionPrompt(
            text: question.text,
            imageUrl: question.imageUrl,
            compact: compactHeight,
            number: match.currentIndex + 1,
          );
          final answers = Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, answerConstraints) => _AnswerOptions(
                    options: question.options,
                    availableHeight: answerConstraints.maxHeight,
                    stateFor: (index) {
                      final selected = index == match.selectedIndex;
                      final correct = index == question.correctOptionIndex;
                      if (revealed && correct) {
                        return EditorialChoiceState.correct;
                      }
                      if (revealed && selected && !correct) {
                        return EditorialChoiceState.wrong;
                      }
                      if (selected) return EditorialChoiceState.selected;
                      if (revealed) return EditorialChoiceState.locked;
                      return EditorialChoiceState.idle;
                    },
                    onAnswer: revealed ? null : _answer,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.standard,
                child: revealed
                    ? Padding(
                        key: ValueKey('feedback-${match.currentIndex}'),
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: _EditorialFeedback(
                          correct: match.records.last.correct,
                          basePoints: match.lastScore?.basePoints ?? 0,
                          speedBonus: match.lastScore?.speedBonus ?? 0,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
          return Column(
            children: [
              EditorialScreenHeader(
                kicker: question.difficulty.arabicLabel,
                title: switch (match.gameType) {
                  GameType.speed => 'جولة السرعة',
                  GameType.trueFalse => 'صح أو خطأ',
                  _ => 'تحدي أحدعش',
                },
                leading: IconButton(
                  tooltip: 'إنهاء المباراة',
                  onPressed: _confirmExit,
                  icon: const Icon(Icons.close_rounded),
                ),
                actions: [_ScoreLine(score: match.playerScore)],
              ),
              _QuestionRoundMeta(
                progress: progress,
                seconds: seconds,
                questionNumber: match.currentIndex + 1,
                questionCount: match.questions.length,
              ),
              SizedBox(height: compactHeight ? 8 : 14),
              Expanded(
                child: constraints.maxWidth < 700
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 4, child: prompt),
                          const SizedBox(height: AppSpacing.sm),
                          const EditorialRule(),
                          const SizedBox(height: AppSpacing.sm),
                          Expanded(flex: 6, child: answers),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: question.text.length < 72 ? 7 : 6,
                            child: prompt,
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          const EditorialRule(vertical: true),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            flex: question.text.length < 72 ? 5 : 6,
                            child: answers,
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startTimer(SoloMatchState match) {
    _timer?.cancel();
    _remainingSeconds = match.settings.questionTimeSeconds.toDouble();
    _lastWarningSecond = -1;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final started = ref.read(soloMatchControllerProvider).questionStartedAt;
      if (started == null || !mounted) return;
      final elapsed = DateTime.now().difference(started).inMilliseconds / 1000;
      final next = match.settings.questionTimeSeconds - elapsed;
      final wholeSecond = next.ceil();
      if (wholeSecond <= 3 &&
          wholeSecond > 0 &&
          wholeSecond != _lastWarningSecond) {
        _lastWarningSecond = wholeSecond;
        ref.read(feedbackServiceProvider).play(FeedbackCue.countdown);
      }
      if (next <= 0) {
        _timer?.cancel();
        setState(() => _remainingSeconds = 0);
        ref.read(soloMatchControllerProvider.notifier).timeout();
      } else {
        _game?.updateTimerFraction(next / match.settings.questionTimeSeconds);
        setState(() => _remainingSeconds = next);
      }
    });
  }

  void _answer(int index) {
    _timer?.cancel();
    ref.read(feedbackServiceProvider).play(FeedbackCue.selection);
    ref.read(soloMatchControllerProvider.notifier).submitAnswer(index);
  }

  void _prefetchNext(SoloMatchState state) {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.questions.length) return;
    final url = state.questions[nextIndex].imageUrl;
    if (url != null) {
      unawaited(precacheImage(CachedNetworkImageProvider(url), context));
    }
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تبي تطلع من المباراة؟'),
        content: const Text('النتيجة الحالية ما راح تنحفظ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('أكمل اللعب'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
    if (shouldExit ?? false) {
      ref.read(soloMatchControllerProvider.notifier).reset();
      if (mounted) context.go('/home');
    }
  }
}

final class _QuestionPrompt extends StatelessWidget {
  const _QuestionPrompt({
    required this.text,
    required this.imageUrl,
    required this.compact,
    required this.number,
  });

  final String text;
  final String? imageUrl;
  final bool compact;
  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Stack(
      children: [
        PositionedDirectional(
          top: compact ? -16 : -24,
          start: 0,
          child: Text(
            '$number'.padLeft(2, '0'),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.055),
              fontSize: compact ? 100 : 146,
              height: 0.9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final prompt = Text(
                text,
                textAlign: TextAlign.start,
                style:
                    (compact
                            ? Theme.of(context).textTheme.titleLarge
                            : Theme.of(context).textTheme.headlineMedium)
                        ?.copyWith(
                          color: colors.textPrimary,
                          fontSize: compact ? 21 : 27,
                          height: 1.36,
                        ),
              );
              if (imageUrl == null) {
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SingleChildScrollView(child: prompt),
                );
              }
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AhdashImage(
                        imageUrl: imageUrl,
                        fallbackAsset: 'assets/visuals/eagle-eye-cover.png',
                        aspectRatio:
                            constraints.maxWidth /
                            (constraints.maxHeight * 0.58),
                        borderRadius: 0,
                        semanticLabel: 'صورة السؤال',
                      ),
                    ),
                    const SizedBox(height: 7),
                    Flexible(child: SingleChildScrollView(child: prompt)),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: AhdashImage(
                      imageUrl: imageUrl,
                      fallbackAsset: 'assets/visuals/eagle-eye-cover.png',
                      aspectRatio: constraints.maxWidth / constraints.maxHeight,
                      borderRadius: 0,
                      semanticLabel: 'صورة السؤال',
                    ),
                  ),
                  SizedBox(width: compact ? 12 : 20),
                  Expanded(
                    flex: 6,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SingleChildScrollView(child: prompt),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

final class _AnswerOptions extends StatelessWidget {
  const _AnswerOptions({
    required this.options,
    required this.availableHeight,
    required this.stateFor,
    required this.onAnswer,
  });

  final List<String> options;
  final double availableHeight;
  final EditorialChoiceState Function(int index) stateFor;
  final ValueChanged<int>? onAnswer;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    Widget option(int index) => EditorialChoiceRow(
      index: index,
      text: options[index],
      state: stateFor(index),
      onTap: onAnswer == null ? null : () => onAnswer!(index),
    );
    final scroll = availableHeight < 230 || textScale > 1.25;
    if (scroll) {
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox.shrink(),
        itemBuilder: (_, index) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: option(index),
        ),
      );
    }
    return Column(
      children: List.generate(
        options.length,
        (index) => Expanded(child: option(index)),
      ),
    );
  }
}

final class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text('النقاط', style: TextStyle(color: context.ahdashColors.textMuted)),
      const SizedBox(width: 8),
      Text(
        '$score',
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

final class _QuestionRoundMeta extends StatelessWidget {
  const _QuestionRoundMeta({
    required this.progress,
    required this.seconds,
    required this.questionNumber,
    required this.questionCount,
  });

  final double progress;
  final int seconds;
  final int questionNumber;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final urgent = seconds <= 3;
    final signal = urgent ? colors.dangerTimer : colors.primary;
    return Column(
      children: [
        Row(
          children: [
            Text(
              'السؤال',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
            const SizedBox(width: 5),
            Text(
              '$questionNumber / $questionCount',
              textDirection: TextDirection.ltr,
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
            const Spacer(),
            Text(
              '$seconds ث',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: urgent ? signal : colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRect(
          child: LinearProgressIndicator(
            minHeight: 3,
            value: progress,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation(signal),
          ),
        ),
      ],
    );
  }
}

final class _EditorialFeedback extends StatelessWidget {
  const _EditorialFeedback({
    required this.correct,
    required this.basePoints,
    required this.speedBonus,
  });

  final bool correct;
  final int basePoints;
  final int speedBonus;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final signal = correct ? colors.success : colors.error;
    return DecoratedBox(
      key: ValueKey(correct ? 'feedback-correct' : 'feedback-wrong'),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: signal, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Row(
          children: [
            Icon(
              correct ? Icons.check_circle_outline : Icons.cancel_rounded,
              color: signal,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              correct ? 'إجابة صحيحة' : 'الإجابة غير صحيحة',
              style: TextStyle(color: signal, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            Text(
              correct
                  ? 'أساس $basePoints • سرعة +$speedBonus'
                  : '+${basePoints + speedBonus} نقطة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
