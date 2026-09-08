import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/editorial_v6.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../match/presentation/game_widgets.dart';
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
        subtitle: 'تحدٍ محفوظ ومحسوب من الخادم',
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
    if (_loading) return const LoadingSkeleton(lines: 7);
    if (_error case final message?) {
      return AppMessageState(
        icon: Icons.sports_score_outlined,
        title: 'تعذر بدء التحدي',
        message: message,
        actionLabel: 'رجوع',
        onAction: () => context.pop(),
      );
    }
    if (_result case final value?) return _ResultView(result: value);
    final question = _question;
    if (question == null) return const LoadingSkeleton(lines: 7);
    final options = socialRows(question['options']);
    final count = (question['question_count'] as num?)?.round() ?? 1;
    final sequence = (question['sequence'] as num?)?.round() ?? 1;
    final totalMs = (question['duration_ms'] as num?)?.round() ?? 15000;
    final progress = totalMs <= 0
        ? 0.0
        : (_remaining.inMilliseconds / totalMs).clamp(0.0, 1.0);
    return AccessibilityViewport(
      key: ValueKey('question-$sequence'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = context.v9Metrics;
          final shortLandscape = constraints.maxHeight <= 330;
          final answersLocked =
              _submitting ||
              _feedback != null ||
              _submissionTracker.pending != null;
          final questionPanel = GamePanel(
            tone: GameSurfaceTone.raised,
            padding: EdgeInsets.symmetric(
              horizontal: shortLandscape
                  ? 20
                  : metrics.compact
                  ? 28
                  : 56,
              vertical: metrics.compact ? 10 : 20,
            ),
            child: Center(
              child: Text(
                '${question['question_text'] ?? ''}',
                textAlign: TextAlign.center,
                maxLines: metrics.compact ? 4 : 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: metrics.compact ? 28 : 32,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
          final answerStage = Column(
            children: [
              Expanded(
                child: _ChallengeAnswerBoard(
                  options: options,
                  selectedOptionId: _selectedOptionId,
                  feedback: _feedback,
                  disabled: answersLocked,
                  onTap: _submit,
                ),
              ),
              if (_submissionError case final message?)
                SizedBox(
                  height: metrics.secondaryActionHeight,
                  child: GamePanel(
                    tone: GameSurfaceTone.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.sync_problem_rounded, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _submitting || _submissionTracker.pending == null
                              ? null
                              : () => _sendPending(_submissionTracker.pending!),
                          child: const Text('إعادة'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );

          return Column(
            children: [
              SizedBox(
                height: metrics.touchTarget,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${question['challenge_title'] ?? 'تحدي الفريق'} • $sequence/$count',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    SizedBox(
                      width: metrics.compact ? 120 : 180,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        color: progress < 0.28
                            ? context.ahdashColors.error
                            : context.ahdashColors.primary,
                      ),
                    ),
                    SizedBox(width: metrics.compact ? 8 : 16),
                    Text(
                      '${(_remaining.inMilliseconds / 1000).clamp(0, 99).toStringAsFixed(1)} ث',
                      textDirection: TextDirection.ltr,
                    ),
                    SizedBox(width: metrics.compact ? 8 : 16),
                    Text(
                      '${question['score'] ?? 0} نقطة',
                      style: TextStyle(
                        color: context.ahdashColors.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: metrics.compact ? 6 : 10),
              Expanded(
                child: shortLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: questionPanel),
                          const SizedBox(width: 6),
                          Expanded(flex: 7, child: answerStage),
                        ],
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: metrics.compact ? 104 : 180,
                            child: questionPanel,
                          ),
                          SizedBox(height: metrics.compact ? 6 : 10),
                          Expanded(child: answerStage),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
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
        if (constraints.maxHeight >= 260 || options.length > 4) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 4.1,
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
    final state = isCorrect
        ? AnswerVisualState.correct
        : isWrongSelection
        ? AnswerVisualState.wrong
        : selected
        ? AnswerVisualState.selected
        : disabled
        ? AnswerVisualState.locked
        : AnswerVisualState.neutral;
    return AnswerOptionCard(
      index: position - 1,
      text: '${option['text'] ?? ''}',
      state: state,
      onTap: disabled ? null : onTap,
    );
  }
}

final class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final Map<String, Object?> result;

  @override
  Widget build(BuildContext context) {
    final rows = socialRows(result['leaderboard']);
    return AccessibilityViewport(
      key: const ValueKey('challenge-result'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AhdashPictogramView(
                    pictogram: AhdashPictogram.win,
                    scale: AhdashPictogramScale.result,
                    tone: AhdashPictogramTone.achievement,
                  ),
                  SizedBox(height: context.v9Metrics.compact ? 6 : 12),
                  Text(
                    'ثبتنا نتيجتك',
                    style: TextStyle(
                      fontSize: context.v9Metrics.heroSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result['score'] ?? 0}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: context.ahdashColors.gold,
                      fontSize: context.v9Metrics.scoreSize,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الترتيب #${result['rank'] ?? 0} • '
                    '${result['correct_answers'] ?? 0} إجابات صحيحة',
                    style: TextStyle(
                      color: context.ahdashColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: AhdashV9PrimaryAction(
                      label: 'العودة للفريق',
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: EditorialRule(vertical: true),
          ),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CompactSectionTitle(
                    eyebrow: 'ترتيب الفريق',
                    title: 'أفضل النتائج',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: GamePagedList<Map<String, Object?>>(
                      items: rows,
                      pageSize: 4,
                      aspectRatio: 5.2,
                      itemBuilder: (_, row, index) => Material(
                        color: Colors.transparent,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: context.ahdashColors.border,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: Text(
                              '${row['rank'] ?? index + 1}'.padLeft(2, '0'),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                color: context.ahdashColors.gold,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            title: Text('${row['display_name'] ?? 'لاعب 11'}'),
                            trailing: Text(
                              '${row['score'] ?? 0}',
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
