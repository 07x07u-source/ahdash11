import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Small rights-safe editorial artwork for the Settings identity surface.
final class SettingsIdentityArtwork extends StatelessWidget {
  const SettingsIdentityArtwork({required this.premium, super.key});

  final bool premium;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SettingsIdentityPainter(premium: premium));
}

final class _SettingsIdentityPainter extends CustomPainter {
  const _SettingsIdentityPainter({required this.premium});

  final bool premium;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final line = Paint()
      ..color = AppColors.paper0.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final pitch = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(18),
    );
    canvas.drawRRect(pitch, line);
    canvas.drawLine(
      Offset(size.width * .5, 1),
      Offset(size.width * .5, size.height - 1),
      line,
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.shortestSide * .18,
      line,
    );

    final glow = Paint()
      ..color = (premium ? AppColors.gold : AppColors.primary).withValues(
        alpha: .2,
      );
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .28),
      size.shortestSide * .34,
      glow,
    );

    final card = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * .62, size.height * .53),
        width: size.width * .42,
        height: size.height * .58,
      ),
      const Radius.circular(14),
    );
    canvas.save();
    canvas.translate(card.center.dx, card.center.dy);
    canvas.rotate(-.08);
    final local = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: card.width,
        height: card.height,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      local,
      Paint()..color = premium ? AppColors.gold : AppColors.primary,
    );
    final text = TextPainter(
      text: const TextSpan(
        text: '١١',
        style: TextStyle(
          color: AppColors.ink,
          fontFamily: 'ThmanyahSans',
          fontSize: 23,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();

    final path = Path()
      ..moveTo(size.width * .08, size.height * .78)
      ..quadraticBezierTo(
        size.width * .3,
        size.height * .54,
        size.width * .46,
        size.height * .76,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.paper0.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(
      Offset(size.width * .1, size.height * .77),
      math.max(2.5, size.shortestSide * .035),
      Paint()..color = AppColors.paper0,
    );
  }

  @override
  bool shouldRepaint(covariant _SettingsIdentityPainter oldDelegate) =>
      oldDelegate.premium != premium;
}
