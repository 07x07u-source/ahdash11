import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/v10_portrait.dart';

abstract final class PartyV2Motion {
  static const press = Duration(milliseconds: 110);
  static const page = Duration(milliseconds: 220);
  static const reveal = Duration(milliseconds: 240);
  static const score = Duration(milliseconds: 420);
  static const intro = Duration(milliseconds: 520);
  static const shuffle = Duration(milliseconds: 720);
}

final class PartyV2Canvas extends StatelessWidget {
  const PartyV2Canvas({required this.child, this.motion = true, super.key});

  final Widget child;
  final bool motion;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: const Color(0xFFFBF7EF), child: child);
}

final class PartyFlowScaffold extends StatelessWidget {
  const PartyFlowScaffold({
    required this.title,
    required this.step,
    required this.onBack,
    required this.child,
    required this.footer,
    this.subtitle,
    super.key,
  });
  final String title;
  final String? subtitle;
  final int step;
  final VoidCallback onBack;
  final Widget child, footer;
  @override
  Widget build(BuildContext context) {
    final metrics = AhdashV10Metrics.of(context);
    return BrandScaffold(
      showDevelopmentBadge: false,
      body: PartyV2Canvas(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.gutter,
                  16,
                  metrics.gutter,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AhdashPageHeader(
                      title: title,
                      subtitle: subtitle,
                      onBack: onBack,
                      trailing: PartyStepIndicator(current: step),
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: child),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: footer,
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
}

final class PartyStepIndicator extends StatelessWidget {
  const PartyStepIndicator({required this.current, super.key});

  final int current;

  static const labels = ['الفئات', 'الفرق', 'المساعدات', 'جاهزين'];

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Semantics(
      label: 'الخطوة $current من 4: ${labels[current - 1]}',
      child: SizedBox.square(
        dimension: 40,
        child: Center(
          child: Text(
            '$current/4',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: colors.success,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

final class PartyPrimaryButton extends ConsumerStatefulWidget {
  const PartyPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.width,
    this.feedback = true,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final double? width;
  final bool feedback;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  ConsumerState<PartyPrimaryButton> createState() => _PartyPrimaryButtonState();
}

final class _PartyPrimaryButtonState extends ConsumerState<PartyPrimaryButton> {
  bool _pressed = false;
  bool _focused = false;

  void _activate() {
    if (widget.onPressed == null || widget.busy) return;
    if (widget.feedback) {
      ref.read(feedbackServiceProvider).play(FeedbackCue.selection);
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final colors = context.ahdashColors;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: FocusableActionDetector(
          enabled: enabled,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTapUp: enabled
                ? (_) {
                    setState(() => _pressed = false);
                    _activate();
                  }
                : null,
            child: AnimatedScale(
              scale: _pressed ? 0.975 : 1,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : PartyV2Motion.press,
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : PartyV2Motion.press,
                width: widget.width,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: enabled
                      ? _pressed
                            ? Color.lerp(
                                widget.backgroundColor ?? colors.primary,
                                const Color(0xFF191714),
                                0.08,
                              )
                            : widget.backgroundColor ?? colors.primary
                      : colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: enabled ? const Color(0xFF191714) : colors.border,
                    width: _focused ? 2 : 1.35,
                  ),
                  boxShadow: enabled && !_pressed
                      ? const [
                          BoxShadow(
                            color: Color(0x24191714),
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.busy)
                        SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.disabled,
                          ),
                        )
                      else if (widget.icon != null)
                        Icon(
                          widget.icon!,
                          size: 19,
                          color: enabled
                              ? widget.foregroundColor ??
                                    colors.primaryForeground
                              : colors.disabled,
                        ),
                      if (widget.busy || widget.icon != null)
                        const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: enabled
                              ? widget.foregroundColor ??
                                    colors.primaryForeground
                              : colors.disabled,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class PartyEntrance extends StatelessWidget {
  const PartyEntrance({required this.child, this.offset = 0.035, super.key});

  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: PartyV2Motion.intro,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: FractionalTranslation(
          translation: Offset(0, offset * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

final class PartyTeamDot extends StatelessWidget {
  const PartyTeamDot({required this.color, this.size = 9, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

final class PartyDivider extends StatelessWidget {
  const PartyDivider({this.vertical = false, super.key});

  final bool vertical;

  @override
  Widget build(BuildContext context) => Container(
    width: vertical ? 1 : double.infinity,
    height: vertical ? double.infinity : 1,
    color: context.ahdashColors.border.withValues(alpha: 0.7),
  );
}
