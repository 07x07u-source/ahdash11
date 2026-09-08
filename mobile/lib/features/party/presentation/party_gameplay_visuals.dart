import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum PartyGameplayArtworkScene { category, ready, imageFallback, result }

/// Rights-safe procedural football artwork used by the local Party flow.
///
/// The artwork is deliberately geometric: pitch markings, ball trajectories,
/// stadium light cones, and AHDASH's 11 motif. It has no club, league, player,
/// or third-party marks.
final class PartyGameplayArtwork extends StatelessWidget {
  const PartyGameplayArtwork({
    required this.scene,
    this.accent = AppColors.primary,
    this.onDark = false,
    this.progress = 1,
    this.child,
    super.key,
  });

  final PartyGameplayArtworkScene scene;
  final Color accent;
  final bool onDark;
  final double progress;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PartyGameplayArtworkPainter(
      scene: scene,
      accent: accent,
      onDark: onDark,
      progress: progress.clamp(0, 1),
    ),
    child: child ?? const SizedBox.expand(),
  );
}

final class _PartyGameplayArtworkPainter extends CustomPainter {
  const _PartyGameplayArtworkPainter({
    required this.scene,
    required this.accent,
    required this.onDark,
    required this.progress,
  });

  final PartyGameplayArtworkScene scene;
  final Color accent;
  final bool onDark;
  final double progress;

  Color get line => (onDark ? AppColors.paper0 : AppColors.ink).withValues(
    alpha: onDark ? 0.24 : 0.13,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final reveal = Curves.easeOutCubic.transform(progress);
    _paintEditorialNumber(canvas, size, reveal);
    switch (scene) {
      case PartyGameplayArtworkScene.category:
        _paintPitch(canvas, size, reveal);
        _paintFlight(canvas, size, reveal, rising: true);
      case PartyGameplayArtworkScene.ready:
        _paintFloodlights(canvas, size, reveal);
        _paintPitch(canvas, size, reveal);
        _paintTeamMarkers(canvas, size, reveal);
      case PartyGameplayArtworkScene.imageFallback:
        _paintFloodlights(canvas, size, reveal);
        _paintFlight(canvas, size, reveal, rising: false);
        _paintFrameCorners(canvas, size, reveal);
      case PartyGameplayArtworkScene.result:
        _paintFloodlights(canvas, size, reveal);
        _paintTrophy(canvas, size, reveal);
        _paintFlight(canvas, size, reveal, rising: true);
    }
  }

  void _paintEditorialNumber(Canvas canvas, Size size, double reveal) {
    final painter = TextPainter(
      text: TextSpan(
        text: '11',
        style: TextStyle(
          color: (onDark ? AppColors.paper0 : AppColors.ink).withValues(
            alpha: 0.045 * reveal,
          ),
          fontFamily: 'ThmanyahSans',
          fontSize: size.shortestSide * 0.76,
          fontWeight: FontWeight.w900,
          height: 0.85,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(size.width - painter.width * 0.88, size.height - painter.height),
    );
  }

  void _paintPitch(Canvas canvas, Size size, double reveal) {
    final paint = Paint()
      ..color = line.withValues(alpha: line.a * reveal)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.shortestSide * 0.008);
    final rect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.14,
      size.width * 0.84 * reveal,
      size.height * 0.72,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide * 0.06)),
      paint,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top),
      Offset(rect.center.dx, rect.bottom),
      paint,
    );
    canvas.drawCircle(
      rect.center,
      math.min(rect.width, rect.height) * 0.13,
      paint,
    );
    canvas.drawCircle(
      rect.center,
      paint.strokeWidth * 1.4,
      Paint()..color = line,
    );
  }

  void _paintFlight(
    Canvas canvas,
    Size size,
    double reveal, {
    required bool rising,
  }) {
    final start = Offset(
      size.width * 0.13,
      size.height * (rising ? 0.76 : 0.3),
    );
    final end = Offset(
      size.width * (0.78 * reveal + 0.13 * (1 - reveal)),
      size.height * (rising ? 0.24 : 0.7),
    );
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * (rising ? 0.06 : 0.92),
        end.dx,
        end.dy,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: 0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, size.shortestSide * 0.012)
        ..strokeCap = StrokeCap.round,
    );
    _paintBall(canvas, end, size.shortestSide * 0.055);
  }

  void _paintBall(Canvas canvas, Offset center, double radius) {
    final fill = Paint()..color = onDark ? AppColors.paper0 : AppColors.ink;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(
      center,
      radius * 0.42,
      Paint()..color = accent.withValues(alpha: 0.9),
    );
    final seam = Paint()
      ..color = accent.withValues(alpha: 0.8)
      ..strokeWidth = math.max(1, radius * 0.13)
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      -0.6,
      1.2,
      false,
      seam,
    );
  }

  void _paintFloodlights(Canvas canvas, Size size, double reveal) {
    final cone = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.gold.withValues(alpha: 0.26 * reveal),
          AppColors.gold.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    final left = Path()
      ..moveTo(size.width * 0.06, 0)
      ..lineTo(size.width * 0.32, size.height)
      ..lineTo(size.width * 0.52, size.height)
      ..lineTo(size.width * 0.18, 0)
      ..close();
    final right = Path()
      ..moveTo(size.width * 0.82, 0)
      ..lineTo(size.width * 0.48, size.height)
      ..lineTo(size.width * 0.68, size.height)
      ..lineTo(size.width * 0.94, 0)
      ..close();
    canvas.drawPath(left, cone);
    canvas.drawPath(right, cone);
  }

  void _paintTeamMarkers(Canvas canvas, Size size, double reveal) {
    final y = size.height * 0.55;
    final radius = size.shortestSide * 0.055;
    canvas.drawCircle(
      Offset(size.width * 0.26, y),
      radius,
      Paint()..color = accent.withValues(alpha: 0.88 * reveal),
    );
    canvas.drawCircle(
      Offset(size.width * 0.74, y),
      radius,
      Paint()..color = AppColors.gold.withValues(alpha: 0.88 * reveal),
    );
  }

  void _paintFrameCorners(Canvas canvas, Size size, double reveal) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.72 * reveal)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.shortestSide * 0.014)
      ..strokeCap = StrokeCap.square;
    final inset = size.shortestSide * 0.09;
    final arm = size.shortestSide * 0.15;
    for (final sx in [1.0, -1.0]) {
      for (final sy in [1.0, -1.0]) {
        final x = sx > 0 ? inset : size.width - inset;
        final y = sy > 0 ? inset : size.height - inset;
        canvas.drawLine(Offset(x, y), Offset(x + sx * arm, y), paint);
        canvas.drawLine(Offset(x, y), Offset(x, y + sy * arm), paint);
      }
    }
  }

  void _paintTrophy(Canvas canvas, Size size, double reveal) {
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final w = size.shortestSide * 0.28 * reveal;
    final h = size.shortestSide * 0.28;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    final cup = Path()
      ..moveTo(center.dx - w * 0.45, center.dy - h * 0.48)
      ..lineTo(center.dx + w * 0.45, center.dy - h * 0.48)
      ..quadraticBezierTo(
        center.dx + w * 0.35,
        center.dy + h * 0.18,
        center.dx,
        center.dy + h * 0.2,
      )
      ..quadraticBezierTo(
        center.dx - w * 0.35,
        center.dy + h * 0.18,
        center.dx - w * 0.45,
        center.dy - h * 0.48,
      )
      ..close();
    canvas.drawPath(cup, gold);
    canvas.drawLine(
      Offset(center.dx, center.dy + h * 0.18),
      Offset(center.dx, center.dy + h * 0.48),
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = math.max(4, w * 0.12)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + h * 0.58),
          width: w * 0.72,
          height: h * 0.13,
        ),
        const Radius.circular(4),
      ),
      gold,
    );
    final handle = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, w * 0.06);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx - w * 0.48, center.dy - h * 0.22),
        width: w * 0.52,
        height: h * 0.45,
      ),
      math.pi / 2,
      math.pi,
      false,
      handle,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx + w * 0.48, center.dy - h * 0.22),
        width: w * 0.52,
        height: h * 0.45,
      ),
      -math.pi / 2,
      math.pi,
      false,
      handle,
    );
  }

  @override
  bool shouldRepaint(_PartyGameplayArtworkPainter oldDelegate) =>
      oldDelegate.scene != scene ||
      oldDelegate.accent != accent ||
      oldDelegate.onDark != onDark ||
      oldDelegate.progress != progress;
}
