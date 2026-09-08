import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'ahdash_pictograms.dart';

final class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({this.lines = 4, this.lineHeight, super.key});

  final int lines;
  final double? lineHeight;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

final class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.loadingPulse,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final colors = context.ahdashColors;
    if (reduceMotion) {
      return _SkeletonLines(
        lines: widget.lines,
        lineHeight: widget.lineHeight,
        color: colors.surfaceMuted,
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Opacity(opacity: 0.35 + (_controller.value * 0.35), child: child),
      child: _SkeletonLines(
        lines: widget.lines,
        lineHeight: widget.lineHeight,
        color: colors.surfaceMuted,
      ),
    );
  }
}

final class AppMessageState extends StatelessWidget {
  const AppMessageState({
    this.icon,
    this.pictogram,
    this.pictogramTone = AhdashPictogramTone.standard,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(icon == null || pictogram == null);

  final IconData? icon;
  final AhdashPictogram? pictogram;
  final AhdashPictogramTone pictogramTone;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? (constraints.maxHeight - AppSpacing.xl * 2).clamp(
                    0,
                    double.infinity,
                  )
                : 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pictogram != null) ...[
                AhdashPictogramView(
                  pictogram: pictogram!,
                  scale: AhdashPictogramScale.emptyState,
                  tone: pictogramTone,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (icon != null) ...[
                Container(
                  width: 104,
                  height: 82,
                  decoration: BoxDecoration(
                    color: AppColors.paper1,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: colors.border),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ExcludeSemantics(child: AhdashStateArtwork()),
                      Center(
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.paper0,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.border),
                          ),
                          child: Icon(icon, size: 22, color: colors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (icon == null && pictogram == null) ...[
                const SizedBox(
                  width: 116,
                  height: 84,
                  child: ExcludeSemantics(child: AhdashStateArtwork()),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: MediaQuery.sizeOf(context).height <= 430 ? 20 : 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: MediaQuery.sizeOf(context).height <= 430 ? 14 : 16,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines({
    required this.lines,
    required this.lineHeight,
    required this.color,
  });

  final int lines;
  final double? lineHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heights = List<double>.generate(
          lines,
          (index) => lineHeight ?? (index.isEven ? 94 : 58),
        );
        final naturalHeight =
            heights.fold<double>(0, (sum, height) => sum + height) +
            (AppSpacing.sm * lines);
        final scale =
            constraints.hasBoundedHeight &&
                naturalHeight > constraints.maxHeight
            ? constraints.maxHeight / naturalHeight
            : 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(lines, (index) {
            final width = switch (index % 3) {
              1 => .82,
              2 => .66,
              _ => 1.0,
            };
            return Align(
              alignment: index.isEven
                  ? AlignmentDirectional.centerStart
                  : AlignmentDirectional.centerEnd,
              child: FractionallySizedBox(
                widthFactor: width,
                child: Container(
                  height: heights[index] * scale,
                  margin: EdgeInsets.only(bottom: AppSpacing.sm * scale),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      index.isEven ? AppRadius.large : AppRadius.medium,
                    ),
                    border: Border.all(
                      color: AppColors.hairline.withValues(alpha: .42),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Original, procedural match-card motif for empty and error surfaces.
final class AhdashStateArtwork extends StatelessWidget {
  const AhdashStateArtwork({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: const _AhdashStateArtworkPainter());
}

final class _AhdashStateArtworkPainter extends CustomPainter {
  const _AhdashStateArtworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final line = Paint()
      ..color = AppColors.ink.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(18),
      ),
      line,
    );
    canvas.drawLine(
      Offset(size.width * .5, 1),
      Offset(size.width * .5, size.height - 1),
      line,
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.shortestSide * .14,
      line,
    );
    final route = Path()
      ..moveTo(size.width * .08, size.height * .72)
      ..quadraticBezierTo(
        size.width * .34,
        size.height * .4,
        size.width * .68,
        size.height * .64,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.palm
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    final card = Rect.fromCenter(
      center: Offset(size.width * .75, size.height * .38),
      width: size.width * .25,
      height: size.height * .48,
    );
    canvas.save();
    canvas.translate(card.center.dx, card.center.dy);
    canvas.rotate(.09);
    final local = Rect.fromCenter(
      center: Offset.zero,
      width: card.width,
      height: card.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(local, const Radius.circular(8)),
      Paint()..color = AppColors.gold,
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(size.width * .68, size.height * .64),
      math.max(3, size.shortestSide * .045),
      Paint()..color = AppColors.ink,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
