import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/social_identity.dart';

enum SocialArtworkScene { friends, search, blocked, team, ranking }

/// Procedural, rights-safe artwork built specifically for AHDASH social
/// surfaces. Match-card geometry keeps hero and empty states truthful.
final class SocialArtwork extends StatelessWidget {
  const SocialArtwork({required this.scene, this.dark = true, super.key});

  final SocialArtworkScene scene;
  final bool dark;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SocialArtworkPainter(scene: scene, dark: dark),
    child: const SizedBox.expand(),
  );
}

final class SocialHero extends StatelessWidget {
  const SocialHero({
    required this.title,
    required this.subtitle,
    required this.scene,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final SocialArtworkScene scene;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final panel = Container(
      height: compact
          ? (textScale >= 1.2 ? 168 : 138)
          : (textScale >= 1.2 ? 218 : 184),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ink, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const PositionedDirectional(
            top: 0,
            bottom: 0,
            start: 0,
            width: 5,
            child: ColoredBox(color: AppColors.primary),
          ),
          PositionedDirectional(
            top: 13,
            bottom: 13,
            end: 10,
            width: compact ? 128 : 150,
            child: ExcludeSemantics(child: SocialArtwork(scene: scene)),
          ),
          PositionedDirectional(
            top: 16,
            bottom: 14,
            start: 18,
            end: compact ? 132 : 154,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AHDASH / SOCIAL 11',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    height: 1,
                    letterSpacing: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.paper0,
                    fontSize: compact ? 20 : 24,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.paper3,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                if (actionLabel != null && onAction != null)
                  SizedBox(
                    height: 36,
                    child: FilledButton.icon(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: const BorderSide(color: AppColors.paper0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const PositionedDirectional(
            top: 12,
            start: 15,
            child: SizedBox(width: 18, child: Divider(color: AppColors.gold)),
          ),
        ],
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return panel;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, (1 - value) * 8),
        child: Opacity(opacity: value, child: child),
      ),
      child: panel,
    );
  }
}

final class SocialEmptyState extends StatelessWidget {
  const SocialEmptyState({
    required this.title,
    required this.message,
    required this.scene,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final SocialArtworkScene scene;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.paper1,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    height: 96,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: SocialArtwork(scene: scene),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 54,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: AppColors.ink),
                  ),
                  alignment: Alignment.center,
                  child: const RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'SOCIAL 11',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    side: const BorderSide(color: AppColors.ink),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

final class SocialPlayerRow extends StatelessWidget {
  const SocialPlayerRow({
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.subtitle,
    this.badge,
    this.trailing,
    this.highlighted = false,
    this.onTap,
    super.key,
  });

  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String? subtitle;
  final String? badge;
  final Widget? trailing;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: onTap != null,
    label: [
      displayName,
      if (subtitle != null) subtitle,
      if (badge != null) badge,
    ].join('، '),
    child: Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: highlighted ? AppColors.paper1 : AppColors.paper0,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: highlighted ? AppColors.ink : AppColors.hairline,
            width: highlighted ? 1.2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: highlighted ? AppColors.primary : AppColors.paper3,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(99),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      10,
                      10,
                      12,
                      10,
                    ),
                    child: Row(
                      children: [
                        AhdashPlayer11Avatar(imageUrl: avatarUrl, size: 44),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.2,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  if (badge != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: highlighted
                                            ? AppColors.primary
                                            : AppColors.paper2,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        badge!,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          height: 1,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (username?.isNotEmpty == true ||
                                  subtitle?.isNotEmpty == true) ...[
                                const SizedBox(height: 3),
                                Text(
                                  subtitle?.isNotEmpty == true
                                      ? subtitle!
                                      : '@$username',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final class _SocialArtworkPainter extends CustomPainter {
  const _SocialArtworkPainter({required this.scene, required this.dark});

  final SocialArtworkScene scene;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paper = dark ? AppColors.paper0 : AppColors.ink;
    final quiet = dark ? AppColors.paper3 : AppColors.inkMuted;
    final fieldLine = Paint()
      ..color = quiet.withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final field = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      const Radius.circular(16),
    );
    canvas.drawRRect(field, fieldLine);
    canvas.drawLine(
      Offset(size.width * .5, 4),
      Offset(size.width * .5, size.height - 4),
      fieldLine,
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      math.min(size.width, size.height) * .13,
      fieldLine,
    );

    void route(List<Offset> points, {Color? color, bool broken = false}) {
      if (points.length < 2) return;
      final paint = Paint()
        ..color = color ?? paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round;
      if (!broken) {
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      } else {
        for (var i = 0; i < points.length - 1; i++) {
          final a = points[i];
          final b = points[i + 1];
          canvas.drawLine(a, Offset.lerp(a, b, .36)!, paint);
          canvas.drawLine(Offset.lerp(a, b, .64)!, b, paint);
        }
      }
      final end = points.last;
      canvas.drawCircle(end, 3.5, Paint()..color = color ?? paper);
    }

    void card(Offset center, Color color, String label, {double angle = 0}) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 36, height: 48),
        const Radius.circular(10),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = paper.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: 'ThmanyahSans',
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      canvas.restore();
    }

    switch (scene) {
      case SocialArtworkScene.friends:
        route([
          Offset(size.width * .12, size.height * .78),
          Offset(size.width * .4, size.height * .55),
          Offset(size.width * .73, size.height * .72),
        ], color: AppColors.gold);
        card(
          Offset(size.width * .38, size.height * .48),
          AppColors.primary,
          '١١',
          angle: -.08,
        );
        card(
          Offset(size.width * .7, size.height * .43),
          AppColors.gold,
          '١١',
          angle: .08,
        );
        canvas.drawCircle(
          Offset(size.width * .2, size.height * .24),
          5,
          Paint()..color = paper,
        );
      case SocialArtworkScene.search:
        route([
          Offset(size.width * .1, size.height * .72),
          Offset(size.width * .42, size.height * .48),
        ], color: AppColors.primary);
        card(
          Offset(size.width * .42, size.height * .49),
          AppColors.primary,
          '١١',
          angle: -.05,
        );
        canvas.drawCircle(
          Offset(size.width * .72, size.height * .42),
          21,
          Paint()
            ..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawLine(
          Offset(size.width * .82, size.height * .57),
          Offset(size.width * .91, size.height * .7),
          Paint()
            ..color = AppColors.gold
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      case SocialArtworkScene.blocked:
        route(
          [
            Offset(size.width * .1, size.height * .7),
            Offset(size.width * .43, size.height * .48),
            Offset(size.width * .82, size.height * .28),
          ],
          color: quiet,
          broken: true,
        );
        card(
          Offset(size.width * .48, size.height * .52),
          AppColors.paper3,
          '١١',
        );
        canvas.drawCircle(
          Offset(size.width * .48, size.height * .52),
          34,
          Paint()
            ..color = AppColors.danger
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        canvas.drawLine(
          Offset(size.width * .3, size.height * .75),
          Offset(size.width * .67, size.height * .28),
          Paint()
            ..color = AppColors.danger
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      case SocialArtworkScene.team:
        final formation = <Offset>[
          Offset(.22, .5),
          Offset(.45, .25),
          Offset(.45, .74),
          Offset(.7, .38),
          Offset(.78, .7),
        ];
        route(
          formation
              .map((p) => Offset(size.width * p.dx, size.height * p.dy))
              .toList(),
          color: AppColors.gold,
        );
        for (var i = 0; i < formation.length; i++) {
          canvas.drawCircle(
            Offset(size.width * formation[i].dx, size.height * formation[i].dy),
            i == 0 ? 8 : 6,
            Paint()..color = i == 0 ? AppColors.gold : AppColors.primary,
          );
        }
        card(
          Offset(size.width * .25, size.height * .5),
          AppColors.gold,
          '١١',
          angle: -.08,
        );
      case SocialArtworkScene.ranking:
        final heights = <double>[.33, .58, .43];
        for (var i = 0; i < 3; i++) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * (.13 + i * .25),
              size.height * (1 - heights[i]) - 10,
              size.width * .19,
              size.height * heights[i],
            ),
            const Radius.circular(8),
          );
          canvas.drawRRect(
            rect,
            Paint()
              ..color = i == 1
                  ? AppColors.primary
                  : i == 0
                  ? AppColors.gold
                  : AppColors.paper3,
          );
          final label = TextPainter(
            text: TextSpan(
              text:
                  '${i == 1
                      ? 1
                      : i == 0
                      ? 2
                      : 3}',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(
            canvas,
            Offset(rect.center.dx - label.width / 2, rect.top + 6),
          );
        }
        route([
          Offset(size.width * .1, size.height * .22),
          Offset(size.width * .46, size.height * .12),
          Offset(size.width * .86, size.height * .25),
        ], color: AppColors.gold);
    }
  }

  @override
  bool shouldRepaint(covariant _SocialArtworkPainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.dark != dark;
}
