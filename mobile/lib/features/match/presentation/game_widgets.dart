import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

enum AnswerVisualState { neutral, selected, correct, wrong, locked }

final class GameTimerBar extends StatelessWidget {
  const GameTimerBar({
    required this.progress,
    required this.seconds,
    required this.questionNumber,
    required this.questionCount,
    super.key,
  });

  final double progress;
  final int seconds;
  final int questionNumber;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final urgent = seconds <= 5;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final timerColor = urgent ? colors.error : colors.primary;
    return Semantics(
      label:
          'السؤال $questionNumber من $questionCount، الوقت المتبقي $seconds ثانية',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '$questionNumber / $questionCount',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 5,
                    color: timerColor,
                    backgroundColor: colors.surfaceMuted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedScale(
                scale: !reduceMotion && seconds <= 3 ? 1.08 : 1,
                duration: reduceMotion ? Duration.zero : AppMotion.micro,
                curve: AppMotion.springCurve,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 27,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: timerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: timerColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    '$seconds',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: timerColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class AnswerOptionCard extends StatefulWidget {
  const AnswerOptionCard({
    required this.index,
    required this.text,
    required this.state,
    required this.onTap,
    super.key,
  });

  final int index;
  final String text;
  final AnswerVisualState state;
  final VoidCallback? onTap;

  @override
  State<AnswerOptionCard> createState() => _AnswerOptionCardState();
}

final class _AnswerOptionCardState extends State<AnswerOptionCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final (accent, background, icon, statusLabel) = switch (widget.state) {
      AnswerVisualState.correct => (
        colors.success,
        colors.success.withValues(alpha: 0.11),
        Icons.check_circle_rounded,
        'إجابة صحيحة',
      ),
      AnswerVisualState.wrong => (
        colors.error,
        colors.error.withValues(alpha: 0.1),
        Icons.cancel_rounded,
        'إجابة غير صحيحة',
      ),
      AnswerVisualState.selected => (
        colors.primary,
        colors.selected,
        Icons.lock_clock_rounded,
        'تم اختيارها',
      ),
      AnswerVisualState.locked => (
        colors.borderStrong,
        colors.surfaceMuted,
        Icons.lock_outline_rounded,
        'مقفلة',
      ),
      AnswerVisualState.neutral => (colors.border, colors.surface, null, null),
    };
    final emphasized = widget.state == AnswerVisualState.correct;
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      selected: widget.state == AnswerVisualState.selected,
      label:
          'الخيار ${widget.index + 1}: ${widget.text}${statusLabel == null ? '' : '، $statusLabel'}',
      child: AnimatedScale(
        key: ValueKey('answer-${widget.index}-${widget.state.name}'),
        scale: reduceMotion
            ? 1
            : (_pressed
                  ? AppMotion.pressScale
                  : emphasized
                  ? 1.012
                  : 1),
        duration: reduceMotion ? Duration.zero : AppMotion.micro,
        curve: _pressed ? AppMotion.exitCurve : AppMotion.springCurve,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppMotion.standard,
          curve: AppMotion.curve,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(
                  color: accent,
                  width: widget.state == AnswerVisualState.neutral ? 2 : 4,
                ),
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: widget.onTap == null
                  ? null
                  : (_) => setState(() => _pressed = true),
              onTapCancel: widget.onTap == null
                  ? null
                  : () => setState(() => _pressed = false),
              onTapUp: widget.onTap == null
                  ? null
                  : (_) => setState(() => _pressed = false),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: reduceMotion
                          ? Duration.zero
                          : AppMotion.standard,
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.13),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${widget.index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(icon, color: accent, size: 21),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class GameFeedbackPanel extends StatelessWidget {
  const GameFeedbackPanel({
    required this.correct,
    required this.basePoints,
    required this.speedBonus,
    super.key,
  });

  final bool correct;
  final int basePoints;
  final int speedBonus;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final accent = correct ? colors.success : colors.error;
    return Container(
      key: ValueKey(correct ? 'feedback-correct' : 'feedback-wrong'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'إجابة صحيحة' : 'الإجابة غير صحيحة',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
                if (correct)
                  Text(
                    '+$basePoints إجابة${speedBonus > 0 ? '  •  +$speedBonus سرعة' : ''}',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (correct)
            Text(
              '+${basePoints + speedBonus}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: accent,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}
