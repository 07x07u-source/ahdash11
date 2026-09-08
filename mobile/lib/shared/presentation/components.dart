import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/feedback_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

final class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.ahdashColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

final class AhdashCard extends StatelessWidget {
  const AhdashCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.accent,
    this.elevated = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      side: BorderSide(color: accent?.withValues(alpha: 0.4) ?? colors.border),
    );
    final content = Padding(padding: padding, child: child);
    final material = Material(
      color: elevated ? colors.surfaceElevated : colors.surface,
      elevation: elevated && Theme.of(context).brightness == Brightness.light
          ? AppElevation.raisedCard
          : 0,
      shadowColor: const Color(0x16000000),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
    if (onTap == null) return material;
    return AhdashPressable(
      onTap: onTap!,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: material,
    );
  }
}

final class AhdashPressable extends ConsumerStatefulWidget {
  const AhdashPressable({
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.feedback = FeedbackCue.tap,
    super.key,
  });

  final VoidCallback onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final FeedbackCue feedback;

  @override
  ConsumerState<AhdashPressable> createState() => _AhdashPressableState();
}

final class _AhdashPressableState extends ConsumerState<AhdashPressable> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: reduceMotion || !_pressed ? 1 : AppMotion.pressScale,
      duration: reduceMotion ? Duration.zero : AppMotion.micro,
      curve: _pressed ? AppMotion.exitCurve : AppMotion.springCurve,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: () {
            unawaited(ref.read(feedbackServiceProvider).play(widget.feedback));
            widget.onTap();
          },
          child: widget.child,
        ),
      ),
    );
  }
}

final class AhdashEntrance extends StatefulWidget {
  const AhdashEntrance({required this.child, this.order = 0, super.key});

  final Widget child;
  final int order;

  @override
  State<AhdashEntrance> createState() => _AhdashEntranceState();
}

final class _AhdashEntranceState extends State<AhdashEntrance> {
  Timer? _timer;
  var _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visible || _timer != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _visible = true;
      return;
    }
    _timer = Timer(AppMotion.staggerStep * widget.order, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.emphasized;
    return AnimatedSlide(
      duration: duration,
      curve: AppMotion.enterCurve,
      offset: _visible ? Offset.zero : const Offset(0, 0.035),
      child: AnimatedOpacity(
        duration: duration,
        curve: AppMotion.enterCurve,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

final class AhdashButton extends StatelessWidget {
  const AhdashButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label),
            ],
          );
    return secondary
        ? OutlinedButton(onPressed: loading ? null : onPressed, child: child)
        : FilledButton(onPressed: loading ? null : onPressed, child: child);
  }
}

final class MetricPill extends StatelessWidget {
  const MetricPill({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final resolvedColor = color ?? colors.primary;
    return Semantics(
      label: '$label، $value',
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: resolvedColor),
            const SizedBox(width: 6),
            Text(
              value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

final class ModeCard extends StatelessWidget {
  const ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent,
    this.badge,
    this.compact = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? accent;
  final String? badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final resolvedAccent = accent ?? colors.primary;
    return AhdashCard(
      onTap: onTap,
      accent: resolvedAccent,
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: compact ? 44 : 52,
            height: compact ? 44 : 52,
            decoration: BoxDecoration(
              color: resolvedAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(icon, color: resolvedAccent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      AhdashBadge(label: badge!, color: resolvedAccent),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: colors.textMuted,
          ),
        ],
      ),
    );
  }
}

final class AhdashBadge extends StatelessWidget {
  const AhdashBadge({required this.label, this.color, super.key});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? context.ahdashColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: resolved,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

final class AhdashAvatar extends StatelessWidget {
  const AhdashAvatar({this.imageUrl, this.radius = 24, this.online, super.key});

  final String? imageUrl;
  final double radius;
  final bool? online;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Semantics(
      label: online == null
          ? 'صورة اللاعب'
          : online!
          ? 'اللاعب متصل'
          : 'اللاعب غير متصل',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: colors.surfaceMuted,
            foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
            child: Icon(Icons.person_rounded, color: colors.primary),
          ),
          if (online != null)
            PositionedDirectional(
              end: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: online! ? colors.success : colors.disabled,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class AhdashProgressBar extends StatelessWidget {
  const AhdashProgressBar({required this.value, this.color, super.key});

  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 7,
        color: color ?? colors.primary,
        backgroundColor: colors.surfaceMuted,
      ),
    );
  }
}

void showAhdashSnackbar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
}
