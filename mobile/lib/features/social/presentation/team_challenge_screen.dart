import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../../shared/presentation/illustrated_state.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../data/social_repository.dart';
import '../domain/challenge_submission.dart';
import '../domain/social_entities.dart';

final class TeamChallengeScreen extends ConsumerStatefulWidget {
  const TeamChallengeScreen({
    required this.challengeId,
    this.enableCountdown = true,
    super.key,
  });

  final String challengeId;
  final bool enableCountdown;

  @override
  ConsumerState<TeamChallengeScreen> createState() =>
      _TeamChallengeScreenState();
}

final class _TeamChallengeScreenState extends ConsumerState<TeamChallengeScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  String? _attemptId;
  Map<String, Object?>? _question;
  Map<String, Object?>? _feedback;
  Map<String, Object?>? _result;
  String? _selectedOptionId;
  Duration _remaining = Duration.zero;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _submissionError;
  final _submissionTracker = ChallengeSubmissionTracker();
  Duration _serverOffset = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final pending = _submissionTracker.pending;
    if (pending != null) {
      unawaited(_sendPending(pending));
    } else if (_question != null && _feedback == null && _result == null) {
      unawaited(_loadQuestion());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _result != null || _error != null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _question != null) {
          showAhdashSnackbar(context, 'أكمل السؤال الحالي قبل الخروج.');
        }
      },
      child: AhdashV10Page(
        title: 'تحدي الفريق',
        subtitle: 'جولة سريعة تجمع تركيزك مع فريقك',
        onBack: _question == null ? () => context.pop() : null,
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.standard,
          child: _body(context),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const _ChallengeLoadingView();
    if (_error case final message?) {
      return _ChallengeErrorView(message: message, onBack: context.pop);
    }
    if (_result case final value?) return _ResultView(result: value);
    final question = _question;
    if (question == null) return const _ChallengeLoadingView();
    final options = socialRows(question['options']);
    final count = (question['question_count'] as num?)?.round() ?? 1;
    final sequence = (question['sequence'] as num?)?.round() ?? 1;
    final totalMs = (question['duration_ms'] as num?)?.round() ?? 15000;
    final progress = totalMs <= 0
        ? 0.0
        : (_remaining.inMilliseconds / totalMs).clamp(0.0, 1.0);
    final answersLocked =
        _submitting || _feedback != null || _submissionTracker.pending != null;
    return _ChallengeQuestionView(
      key: ValueKey('question-$sequence'),
      title: '${question['challenge_title'] ?? 'تحدي الفريق'}',
      question: '${question['question_text'] ?? ''}',
      sequence: sequence,
      count: count,
      score: (question['score'] as num?)?.round() ?? 0,
      seconds: (_remaining.inMilliseconds / 1000).clamp(0, 99),
      progress: progress,
      options: options,
      selectedOptionId: _selectedOptionId,
      feedback: _feedback,
      answersLocked: answersLocked,
      submissionError: _submissionError,
      canRetry: !_submitting && _submissionTracker.pending != null,
      onRetry: () {
        final pending = _submissionTracker.pending;
        if (pending != null) unawaited(_sendPending(pending));
      },
      onAnswer: _submit,
    );
  }

  Future<void> _start() async {
    try {
      final started = await ref
          .read(socialRepositoryProvider)
          .startChallenge(widget.challengeId);
      _attemptId = '${started['attempt_id']}';
      await _loadQuestion();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'التحدي غير نشط، أو استُخدمت كل المحاولات، أو الاتصال غير متاح.';
        });
      }
    }
  }

  Future<void> _loadQuestion() async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    _timer?.cancel();
    final question = await ref
        .read(socialRepositoryProvider)
        .getChallengeQuestion(attemptId);
    final closesAt = DateTime.tryParse('${question['closes_at']}')?.toUtc();
    final serverNow = DateTime.tryParse('${question['server_now']}')?.toUtc();
    final clientNow = DateTime.now().toUtc();
    _serverOffset = serverNow?.difference(clientNow) ?? Duration.zero;
    final remaining = closesAt?.difference(clientNow.add(_serverOffset));
    if (!mounted) return;
    setState(() {
      _question = question;
      _feedback = null;
      _selectedOptionId = null;
      _submissionTracker.resetAuthoritativeState();
      _submissionError = null;
      _loading = false;
      _remaining = remaining == null
          ? Duration(
              milliseconds: (question['duration_ms'] as num?)?.round() ?? 15000,
            )
          : remaining.isNegative
          ? Duration.zero
          : remaining;
    });
    if (widget.enableCountdown) _startTimer(closesAt);
  }

  void _startTimer(DateTime? closesAt) {
    _timer?.cancel();
    final deadline =
        closesAt ?? DateTime.now().toUtc().add(_serverOffset).add(_remaining);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final remaining = deadline.difference(
        DateTime.now().toUtc().add(_serverOffset),
      );
      if (!mounted) return;
      setState(
        () => _remaining = remaining.isNegative ? Duration.zero : remaining,
      );
      if (remaining <= Duration.zero) {
        _timer?.cancel();
        if (!_submitting && _feedback == null) unawaited(_submit(null));
      }
    });
  }

  Future<void> _submit(String? optionId) async {
    final attemptId = _attemptId;
    if (attemptId == null ||
        _submitting ||
        _feedback != null ||
        _submissionTracker.pending != null) {
      return;
    }
    final pending = _submissionTracker.begin(
      attemptId: attemptId,
      questionId: '${_question?['question_id'] ?? ''}',
      optionId: optionId,
    );
    await _sendPending(pending);
  }

  Future<void> _sendPending(ChallengeSubmission pending) async {
    final attemptId = _attemptId;
    if (attemptId == null || _submitting || _feedback != null) return;
    _timer?.cancel();
    setState(() {
      _submitting = true;
      _selectedOptionId = pending.optionId;
      _submissionError = null;
    });
    try {
      final feedback = await ref
          .read(socialRepositoryProvider)
          .submitChallengeAnswer(
            attemptId: attemptId,
            optionId: pending.optionId,
            idempotencyKey: pending.idempotencyKey,
            clientSequence: pending.clientSequence,
          );
      if (!mounted) return;
      if (feedback['expired'] == true) {
        setState(() {
          _submitting = false;
          _question = null;
          _submissionTracker.complete(pending);
          _error = 'انتهت مدة التحدي قبل تثبيت الإجابة.';
        });
        return;
      }
      setState(() {
        _feedback = feedback;
        _submitting = false;
        _submissionTracker.complete(pending);
        _submissionError = null;
      });
      await Future<void>.delayed(
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 850),
      );
      if (feedback['completed'] == true) {
        final result = await ref
            .read(socialRepositoryProvider)
            .getChallengeResult(attemptId);
        if (mounted) setState(() => _result = result);
      } else {
        await _loadQuestion();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submissionError =
              'لم يصل تأكيد الخادم. أعد نفس المحاولة؛ لا يمكن تبديل الإجابة.';
        });
      }
    }
  }
}

final class _ChallengeLoadingView extends StatelessWidget {
  const _ChallengeLoadingView();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.brandLime,
            strokeWidth: 3,
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Expanded(child: LoadingSkeleton(lines: 5)),
    ],
  );
}

final class _ChallengeErrorView extends StatelessWidget {
  const _ChallengeErrorView({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: AhdashIllustratedState(
          asset: 'assets/visuals/challenge_unavailable_cutout_v1.png',
          title: 'التحدي غير متاح الآن',
          message: message,
          note: 'لن تُسجّل عليك أي محاولة',
        ),
      ),
      const SizedBox(height: 12),
      AhdashV10PrimaryButton(
        key: const ValueKey('challenge-error-back'),
        label: 'العودة إلى الفريق',
        icon: Icons.arrow_back_rounded,
        onPressed: onBack,
      ),
      const SizedBox(height: 12),
    ],
  );
}

final class _ChallengeQuestionView extends StatelessWidget {
  const _ChallengeQuestionView({
    required this.title,
    required this.question,
    required this.sequence,
    required this.count,
    required this.score,
    required this.seconds,
    required this.progress,
    required this.options,
    required this.selectedOptionId,
    required this.feedback,
    required this.answersLocked,
    required this.submissionError,
    required this.canRetry,
    required this.onRetry,
    required this.onAnswer,
    super.key,
  });

  final String title;
  final String question;
  final int sequence;
  final int count;
  final int score;
  final double seconds;
  final double progress;
  final List<Map<String, Object?>> options;
  final String? selectedOptionId;
  final Map<String, Object?>? feedback;
  final bool answersLocked;
  final String? submissionError;
  final bool canRetry;
  final VoidCallback onRetry;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) => AccessibilityViewport(
    minimumAccessibleHeight: MediaQuery.textScalerOf(context).scale(1) > 1.2
        ? 700
        : 590,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 625;
        final accessibleText = MediaQuery.textScalerOf(context).scale(1) >= 1.2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: compact
                  ? (accessibleText ? 128 : 112)
                  : (accessibleText ? 140 : 124),
              child: _ChallengeRoundCard(
                title: title,
                sequence: sequence,
                count: count,
                score: score,
                seconds: seconds,
                progress: progress,
              ),
            ),
            SizedBox(height: compact ? 10 : 12),
            SizedBox(
              height: accessibleText
                  ? 170
                  : compact
                  ? 118
                  : 142,
              child: _ChallengeQuestionCard(question: question),
            ),
            SizedBox(height: compact ? 10 : 12),
            Expanded(
              child: _ChallengeAnswerBoard(
                options: options,
                selectedOptionId: selectedOptionId,
                feedback: feedback,
                disabled: answersLocked,
                onTap: onAnswer,
              ),
            ),
            if (submissionError case final message?) ...[
              const SizedBox(height: 8),
              _ChallengeRetryBar(
                message: message,
                enabled: canRetry,
                onRetry: onRetry,
              ),
            ] else ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 26,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      answersLocked
                          ? Icons.lock_clock_rounded
                          : Icons.touch_app_outlined,
                      size: 15,
                      color: AppColors.inkMuted,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        answersLocked
                            ? 'جاري تثبيت إجابتك…'
                            : 'اختر إجابة واحدة قبل انتهاء الوقت',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        );
      },
    ),
  );
}

final class _ChallengeRoundCard extends StatelessWidget {
  const _ChallengeRoundCard({
    required this.title,
    required this.sequence,
    required this.count,
    required this.score,
    required this.seconds,
    required this.progress,
  });

  final String title;
  final int sequence;
  final int count;
  final int score;
  final double seconds;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final urgent = progress < .28;
    final timerColor = urgent ? const Color(0xFFFF7A6A) : AppColors.brandLime;
    return Semantics(
      label:
          '$title، السؤال $sequence من $count، $score نقطة، ${seconds.ceil()} ثانية متبقية',
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .14),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -42,
              end: -28,
              child: Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandLime.withValues(alpha: .09),
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.brandLime,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups_2_rounded,
                        color: AppColors.ink,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.paper0,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'السؤال $sequence من $count',
                            style: TextStyle(
                              color: AppColors.paper0.withValues(alpha: .64),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper0.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.paper0.withValues(alpha: .14),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 16,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'نقطة',
                            style: TextStyle(
                              color: AppColors.paper0.withValues(alpha: .6),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: timerColor, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          color: timerColor,
                          backgroundColor: AppColors.paper0.withValues(
                            alpha: .12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${seconds.toStringAsFixed(1)} ث',
                        textAlign: TextAlign.end,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: timerColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _ChallengeQuestionCard extends StatelessWidget {
  const _ChallengeQuestionCard({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.teamPink,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'السؤال',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Center(
            child: Text(
              question,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                height: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _ChallengeRetryBar extends StatelessWidget {
  const _ChallengeRetryBar({
    required this.message,
    required this.enabled,
    required this.onRetry,
  });

  final String message;
  final bool enabled;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
    decoration: BoxDecoration(
      color: context.ahdashColors.error.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: context.ahdashColors.error.withValues(alpha: .3),
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.sync_problem_rounded,
          color: context.ahdashColors.error,
          size: 18,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: enabled ? onRetry : null,
          child: const Text('إعادة'),
        ),
      ],
    ),
  );
}

final class _ChallengeAnswerBoard extends StatelessWidget {
  const _ChallengeAnswerBoard({
    required this.options,
    required this.selectedOptionId,
    required this.feedback,
    required this.disabled,
    required this.onTap,
  });

  final List<Map<String, Object?>> options;
  final String? selectedOptionId;
  final Map<String, Object?>? feedback;
  final bool disabled;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    Widget optionAt(int index) {
      final option = options[index];
      return _AnswerOption(
        option: option,
        position: index + 1,
        selected: selectedOptionId == '${option['id']}',
        feedback: feedback,
        disabled: disabled,
        onTap: () => onTap('${option['id']}'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (options.length > 4) {
          return GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 72,
            ),
            itemBuilder: (_, index) => optionAt(index),
          );
        }

        final rows = (options.length / 2).ceil();
        return Column(
          children: List.generate(rows, (row) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(2, (column) {
                    final index = row * 2 + column;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: column == 0 ? 6 : 0,
                        ),
                        child: index < options.length
                            ? optionAt(index)
                            : const SizedBox.shrink(),
                      ),
                    );
                  }),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

final class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.option,
    required this.position,
    required this.selected,
    required this.feedback,
    required this.disabled,
    required this.onTap,
  });

  final Map<String, Object?> option;
  final int position;
  final bool selected;
  final Map<String, Object?>? feedback;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final id = '${option['id']}';
    final correctId = '${feedback?['correct_option_id'] ?? ''}';
    final isCorrect = feedback != null && id == correctId;
    final isWrongSelection = feedback != null && selected && !isCorrect;
    final colors = context.ahdashColors;
    final neutralAccent = const [
      AppColors.teamPink,
      AppColors.teamBlue,
      AppColors.gold,
      AppColors.palm,
    ][(position - 1) % 4];
    final accent = isCorrect
        ? colors.success
        : isWrongSelection
        ? colors.error
        : selected
        ? AppColors.ink
        : neutralAccent;
    final background = isCorrect
        ? colors.success.withValues(alpha: .1)
        : isWrongSelection
        ? colors.error.withValues(alpha: .08)
        : selected
        ? AppColors.brandLime
        : disabled
        ? AppColors.paper2.withValues(alpha: .62)
        : AppColors.paper0;
    final statusIcon = isCorrect
        ? Icons.check_circle_rounded
        : isWrongSelection
        ? Icons.cancel_rounded
        : selected
        ? Icons.lock_clock_rounded
        : null;
    final statusLabel = isCorrect
        ? 'إجابة صحيحة'
        : isWrongSelection
        ? 'إجابة غير صحيحة'
        : selected
        ? 'تم اختيارها'
        : disabled
        ? 'الخيار مقفل'
        : null;
    return Semantics(
      button: true,
      enabled: !disabled,
      selected: selected,
      label:
          'الخيار $position: ${option['text'] ?? ''}${statusLabel == null ? '' : '، $statusLabel'}',
      child: AnimatedContainer(
        key: ValueKey('challenge-answer-$position-$statusLabel'),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.standard,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent.withValues(alpha: selected ? 1 : .48),
            width: selected || isCorrect || isWrongSelection ? 1.6 : 1,
          ),
          boxShadow: selected || isCorrect
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: .12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.ink
                          : accent.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$position',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: selected ? AppColors.brandLime : accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${option['text'] ?? ''}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: disabled && !selected && !isCorrect
                            ? AppColors.inkMuted
                            : AppColors.ink,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (statusIcon != null) ...[
                    const SizedBox(width: 5),
                    Icon(statusIcon, color: accent, size: 19),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ChallengeResultHero extends StatelessWidget {
  const _ChallengeResultHero({required this.score, required this.rank});
  final int score;
  final int rank;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('challenge-result-hero'),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF2C3024), AppColors.ink],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.gold.withValues(alpha: .25)),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .09),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (MediaQuery.textScalerOf(context).scale(1) > 1.5)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Image.asset(
              'assets/visuals/challenge_result_trophy_v1.png',
              width: 82,
              height: 68,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اكتمل التحدي',
                    style: TextStyle(
                      color: AppColors.paper3,
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'نتيجة ترفع الرأس',
                    style: TextStyle(
                      color: AppColors.paper0,
                      fontSize: 22,
                      height: 1.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (MediaQuery.textScalerOf(context).scale(1) <= 1.5) ...[
              const SizedBox(width: 8),
              Image.asset(
                'assets/visuals/challenge_result_trophy_v1.png',
                width: 94,
                height: 88,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: AppColors.paper0.withValues(alpha: .12)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: AppColors.brandLime,
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text(
                        'نقطة',
                        style: TextStyle(
                          color: AppColors.paper3,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.paper0.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: .24),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ترتيبك',
                    style: TextStyle(
                      color: AppColors.paper3,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    rank > 0 ? '#$rank' : '—',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 22,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

final class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final Map<String, Object?> result;

  @override
  Widget build(BuildContext context) {
    final rows = socialRows(result['leaderboard']);
    final score = (result['score'] as num?)?.round() ?? 0;
    final rank = (result['rank'] as num?)?.round() ?? 0;
    final correct = (result['correct_answers'] as num?)?.round() ?? 0;
    final wrong = (result['wrong_answers'] as num?)?.round() ?? 0;
    final gap = (result['gap_to_next'] as num?)?.round();
    return CustomScrollView(
      key: const ValueKey('challenge-result'),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ChallengeResultHero(score: score, rank: rank),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ResultStat(
                      icon: Icons.check_circle_rounded,
                      label: 'إجابة صحيحة',
                      value: '$correct',
                      color: context.ahdashColors.success,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _ResultStat(
                      icon: Icons.cancel_rounded,
                      label: 'إجابة خاطئة',
                      value: '$wrong',
                      color: context.ahdashColors.error,
                    ),
                  ),
                  if (gap != null) ...[
                    const SizedBox(width: 9),
                    Expanded(
                      child: _ResultStat(
                        icon: Icons.trending_up_rounded,
                        label: 'للمركز التالي',
                        value: gap <= 0 ? '—' : '$gap',
                        color: AppColors.teamBlue,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.brandLime,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ترتيب الفريق',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'أفضل نتيجة لكل لاعب',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (rows.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'ستظهر نتائج الفريق هنا',
                  style: TextStyle(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 7),
            itemBuilder: (context, index) {
              final row = rows[index];
              final rowRank = (row['rank'] as num?)?.round() ?? index + 1;
              final current = rowRank == rank;
              return Container(
                constraints: const BoxConstraints(minHeight: 54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: current
                      ? AppColors.brandLime.withValues(alpha: .16)
                      : AppColors.paper1,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: current
                        ? AppColors.palm.withValues(alpha: .5)
                        : AppColors.hairline,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      padding: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rowRank <= 3
                            ? AppColors.gold.withValues(alpha: .22)
                            : AppColors.paper2,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$rowRank',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: rowRank <= 3
                              ? AppColors.coffee
                              : AppColors.inkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${row['display_name'] ?? 'لاعب 11'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: current
                              ? FontWeight.w900
                              : FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${row['score'] ?? 0}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'نقطة',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AhdashV10PrimaryButton(
                  key: const ValueKey('challenge-result-back'),
                  label: 'العودة إلى الفريق',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 74),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .28)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
