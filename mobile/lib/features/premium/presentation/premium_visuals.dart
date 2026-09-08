import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum PremiumArtworkScene {
  home,
  homeGathering,
  homeTactics,
  homeFloodlights,
  premium,
  categories,
  unlockedCategories,
  noAds,
}

/// Rights-safe, procedural football artwork shared by Home and Premium.
final class AhdashFootballArtwork extends StatelessWidget {
  const AhdashFootballArtwork({
    required this.scene,
    this.animateEntrance = false,
    this.progress,
    super.key,
  });

  final PremiumArtworkScene scene;
  final bool animateEntrance;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final fixedProgress = progress?.clamp(0.0, 1.0).toDouble();
    if (fixedProgress != null ||
        !animateEntrance ||
        MediaQuery.disableAnimationsOf(context)) {
      return CustomPaint(
        key: const ValueKey('ahdash-football-artwork'),
        painter: _FootballArtworkPainter(
          scene: scene,
          progress: fixedProgress ?? 1,
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      key: const ValueKey('ahdash-football-artwork-motion'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => CustomPaint(
        painter: _FootballArtworkPainter(scene: scene, progress: value),
      ),
    );
  }
}

final class PremiumCategoryBadge extends StatelessWidget {
  const PremiumCategoryBadge({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.gold,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 4 : 6,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: compact ? 11 : 14),
            SizedBox(width: compact ? 4 : 6),
            Text(
              'Premium',
              style: TextStyle(
                fontSize: compact ? 9 : 11,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class PremiumCategoryGateCard extends StatelessWidget {
  const PremiumCategoryGateCard({
    required this.onViewPremium,
    required this.onBack,
    this.categoryName,
    super.key,
  });

  final VoidCallback onViewPremium;
  final VoidCallback onBack;
  final String? categoryName;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 148,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF174D3D),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Stack(
              fit: StackFit.expand,
              children: [
                AhdashFootballArtwork(scene: PremiumArtworkScene.categories),
                PositionedDirectional(
                  top: 16,
                  start: 16,
                  child: PremiumCategoryBadge(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (categoryName case final name? when name.trim().isNotEmpty) ...[
            Text(
              name,
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
          ],
          const Text(
            'هذه الفئة ضمن Premium',
            style: TextStyle(
              fontSize: 25,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اشترك للوصول إلى الفئات الحصرية والاستمتاع باللعبة بدون إعلانات.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('premium-gate-open'),
            onPressed: onViewPremium,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('عرض Premium'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const ValueKey('premium-gate-back'),
            onPressed: onBack,
            child: const Text('العودة'),
          ),
        ],
      ),
    ),
  );
}

final class PremiumBenefitVisual extends StatelessWidget {
  const PremiumBenefitVisual({required this.scene, super.key});

  final PremiumArtworkScene scene;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 66,
    height: 54,
    child: CustomPaint(
      painter: _FootballArtworkPainter(scene: scene, progress: 1),
    ),
  );
}

final class _FootballArtworkPainter extends CustomPainter {
  const _FootballArtworkPainter({required this.scene, required this.progress});

  final PremiumArtworkScene scene;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    switch (scene) {
      case PremiumArtworkScene.home:
        _paintHome(canvas, size);
      case PremiumArtworkScene.homeGathering:
        _paintHomeGathering(canvas, size);
      case PremiumArtworkScene.homeTactics:
        _paintHomeTactics(canvas, size);
      case PremiumArtworkScene.homeFloodlights:
        _paintHomeFloodlights(canvas, size);
      case PremiumArtworkScene.premium:
        _paintPremium(canvas, size);
      case PremiumArtworkScene.categories:
        _paintCategories(canvas, size);
      case PremiumArtworkScene.unlockedCategories:
        _paintUnlockedCategories(canvas, size);
      case PremiumArtworkScene.noAds:
        _paintNoAds(canvas, size);
    }
  }

  void _paintHome(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final pitch = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.08,
        size.width * 0.92,
        size.height * 0.78,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(pitch, line);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.08),
      Offset(size.width * 0.5, size.height * 0.86),
      line,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.47),
      size.shortestSide * 0.13,
      line,
    );

    final shift = (1 - progress) * 10;
    _card(
      canvas,
      Rect.fromLTWH(
        size.width * 0.08 - shift,
        size.height * 0.19,
        size.width * 0.32,
        size.height * 0.48,
      ),
      AppColors.gold,
      -0.12,
      '؟',
    );
    _card(
      canvas,
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.12 + shift * 0.35,
        size.width * 0.34,
        size.height * 0.54,
      ),
      AppColors.primary,
      0.05,
      '١١',
    );
    _card(
      canvas,
      Rect.fromLTWH(
        size.width * 0.61 + shift,
        size.height * 0.24,
        size.width * 0.28,
        size.height * 0.42,
      ),
      AppColors.paper0,
      0.13,
      '⚽',
    );
    final path = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final motion = Path()
      ..moveTo(size.width * 0.1, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.43,
        size.height * (0.68 - progress * 0.03),
        size.width * 0.78,
        size.height * 0.8,
      );
    canvas.drawPath(motion, path);
    canvas.drawCircle(
      Offset(
        size.width * (0.1 + 0.68 * progress),
        size.height * (0.82 - 0.05 * math.sin(progress * math.pi)),
      ),
      4,
      Paint()..color = AppColors.ink,
    );
  }

  void _paintHomeGathering(Canvas canvas, Size size) {
    _paintPitch(canvas, size, AppColors.paper0.withValues(alpha: .24));
    final shift = (1 - progress) * 12;
    _card(
      canvas,
      Rect.fromLTWH(
        size.width * .08 - shift,
        size.height * .22,
        size.width * .31,
        size.height * .46,
      ),
      AppColors.gold,
      -.13,
      '؟',
    );
    _card(
      canvas,
      Rect.fromLTWH(
        size.width * .34,
        size.height * .12 + shift * .35,
        size.width * .34,
        size.height * .55,
      ),
      AppColors.primary,
      .05,
      '١١',
    );
    final team = Paint()..color = AppColors.paper0;
    for (final point in const [
      Offset(.77, .28),
      Offset(.87, .43),
      Offset(.75, .58),
    ]) {
      canvas.drawCircle(
        Offset(size.width * point.dx, size.height * point.dy),
        4,
        team,
      );
    }
    final motion = Path()
      ..moveTo(size.width * .1, size.height * .83)
      ..cubicTo(
        size.width * .34,
        size.height * .7,
        size.width * .58,
        size.height * .9,
        size.width * (.72 + .12 * progress),
        size.height * .73,
      );
    canvas.drawPath(
      motion,
      Paint()
        ..color = AppColors.paper0
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(size.width * .84, size.height * .73),
      5,
      Paint()..color = AppColors.paper0,
    );
    canvas.drawCircle(
      Offset(size.width * .84, size.height * .73),
      2,
      Paint()..color = AppColors.ink,
    );
  }

  void _paintHomeTactics(Canvas canvas, Size size) {
    _paintPitch(canvas, size, AppColors.ink.withValues(alpha: .14));
    final dot = Paint()..color = AppColors.ink;
    final lime = Paint()..color = AppColors.primary;
    for (final point in const [
      Offset(.16, .25),
      Offset(.33, .43),
      Offset(.18, .68),
      Offset(.63, .26),
      Offset(.78, .48),
      Offset(.63, .72),
    ]) {
      canvas.drawCircle(
        Offset(size.width * point.dx, size.height * point.dy),
        5,
        point.dx < .5 ? dot : lime,
      );
    }
    final route = Path()
      ..moveTo(size.width * .18, size.height * .68)
      ..quadraticBezierTo(
        size.width * .44,
        size.height * (.7 - .12 * progress),
        size.width * .62,
        size.height * .3,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _arrowHead(canvas, Offset(size.width * .62, size.height * .3), -.75);
    final text = TextPainter(
      text: const TextSpan(
        text: '١١',
        style: TextStyle(
          color: AppColors.ink,
          fontFamily: 'ThmanyahSans',
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    text.paint(
      canvas,
      Offset(size.width * .5 - text.width / 2, size.height * .43),
    );
  }

  void _paintHomeFloodlights(Canvas canvas, Size size) {
    final beam = Paint()..color = AppColors.gold.withValues(alpha: .13);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * .36, 0)
        ..lineTo(size.width * .62, size.height)
        ..lineTo(size.width * .18, size.height)
        ..close(),
      beam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .7, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width * .82, size.height)
        ..lineTo(size.width * .48, size.height)
        ..close(),
      Paint()..color = AppColors.primary.withValues(alpha: .14),
    );
    final crowd = Paint()..color = AppColors.ink.withValues(alpha: .22);
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(
        Offset(size.width * (.08 + i * .105), size.height * .8),
        3.5,
        crowd,
      );
    }
    _card(
      canvas,
      Rect.fromLTWH(
        size.width * (.3 + .02 * progress),
        size.height * .19,
        size.width * .38,
        size.height * .52,
      ),
      AppColors.primary,
      -.03,
      '١١',
    );
    _ball(canvas, Offset(size.width * .77, size.height * .65), 6);
  }

  void _paintPremium(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(
        Offset(size.width * i / 6, 0),
        Offset(size.width * i / 6, size.height),
        grid,
      );
    }
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        grid,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.18),
      size.shortestSide * 0.32,
      Paint()..color = AppColors.gold.withValues(alpha: 0.15),
    );
    final shift = (1 - progress) * 12;
    _card(
      canvas,
      Rect.fromLTWH(
        size.width * 0.55 + shift,
        size.height * 0.22,
        size.width * 0.28,
        size.height * 0.54,
      ),
      AppColors.gold,
      0.12,
      '؟',
    );
    _card(
      canvas,
      Rect.fromLTWH(
        size.width * 0.27,
        size.height * 0.15 + shift,
        size.width * 0.3,
        size.height * 0.58,
      ),
      AppColors.primary,
      -0.06,
      '١١',
    );
    final lockCenter = Offset(size.width * 0.2, size.height * 0.52);
    final lock = Paint()
      ..color = AppColors.paper0
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawArc(
      Rect.fromCircle(center: lockCenter.translate(0, -8), radius: 10),
      math.pi,
      math.pi,
      false,
      lock,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: lockCenter.translate(0, 5),
          width: 28,
          height: 24,
        ),
        const Radius.circular(6),
      ),
      lock,
    );
  }

  void _paintUnlockedCategories(Canvas canvas, Size size) {
    _paintCategories(canvas, size);
    final center = Offset(size.width * .23, size.height * .52);
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(7, -9), radius: 9),
      math.pi * .86,
      math.pi * .92,
      false,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawCircle(
      Offset(size.width * .84, size.height * .24),
      7,
      Paint()..color = AppColors.primary,
    );
  }

  void _paintCategories(Canvas canvas, Size size) {
    final paper = Paint()..color = AppColors.paper1;
    final gold = Paint()..color = AppColors.gold;
    final green = Paint()..color = AppColors.primary;
    canvas.save();
    canvas.translate(size.width * 0.63, size.height * 0.5);
    canvas.rotate(0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.31,
          height: size.height * 0.58,
        ),
        const Radius.circular(12),
      ),
      gold,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(size.width * 0.42, size.height * 0.48);
    canvas.rotate(-0.06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.33,
          height: size.height * 0.62,
        ),
        const Radius.circular(12),
      ),
      paper,
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(size.width * 0.23, size.height * 0.5),
      size.shortestSide * 0.13,
      green,
    );
    final lock = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = Offset(size.width * 0.23, size.height * 0.52);
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(0, -6), radius: 8),
      math.pi,
      math.pi,
      false,
      lock,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 5), width: 22, height: 19),
        const Radius.circular(5),
      ),
      lock,
    );
    final trail = Paint()
      ..color = AppColors.paper0.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.13,
        size.width * 0.9,
        size.height * 0.72,
      ),
      0.2,
      2.5,
      false,
      trail,
    );
  }

  void _paintNoAds(Canvas canvas, Size size) {
    final rail = Paint()
      ..color = AppColors.palm
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final flow = Path()
      ..moveTo(size.width * .1, size.height * .58)
      ..cubicTo(
        size.width * .28,
        size.height * .25,
        size.width * .58,
        size.height * .82,
        size.width * .9,
        size.height * .4,
      );
    canvas.drawPath(flow, rail);
    final centers = [
      Offset(size.width * .16, size.height * .5),
      Offset(size.width * .46, size.height * .52),
      Offset(size.width * .78, size.height * .47),
    ];
    for (var i = 0; i < centers.length; i++) {
      final rect = Rect.fromCenter(
        center: centers[i],
        width: size.width * .23,
        height: size.height * .55,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = i == 1
              ? AppColors.primary.withValues(alpha: .88)
              : AppColors.paper0,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = AppColors.ink.withValues(alpha: .35)
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        rect.center,
        3.2,
        Paint()..color = i == 1 ? AppColors.ink : AppColors.gold,
      );
    }
    _arrowHead(canvas, Offset(size.width * .91, size.height * .4), -.45);
  }

  void _paintPitch(Canvas canvas, Size size, Color color) {
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final pitch = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .035,
        size.height * .07,
        size.width * .93,
        size.height * .79,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(pitch, line);
    canvas.drawLine(
      Offset(size.width * .5, size.height * .07),
      Offset(size.width * .5, size.height * .86),
      line,
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .465),
      size.shortestSide * .13,
      line,
    );
  }

  void _ball(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = AppColors.ink);
    canvas.drawCircle(center, radius * .42, Paint()..color = AppColors.paper0);
  }

  void _arrowHead(Canvas canvas, Offset tip, double angle) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(-8, -4)
      ..lineTo(-6, 4)
      ..close();
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);
    canvas.drawPath(path, Paint()..color = AppColors.gold);
    canvas.restore();
  }

  void _card(
    Canvas canvas,
    Rect rect,
    Color color,
    double angle,
    String label,
  ) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(angle);
    final local = Rect.fromCenter(
      center: Offset.zero,
      width: rect.width,
      height: rect.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(local, const Radius.circular(12)),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(local, const Radius.circular(12)),
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: AppColors.ink,
          fontSize: math.min(rect.width, rect.height) * 0.36,
          fontWeight: FontWeight.w900,
          fontFamily: 'ThmanyahSans',
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: rect.width);
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FootballArtworkPainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.progress != progress;
}
