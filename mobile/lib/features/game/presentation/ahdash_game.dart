import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Alignment, LinearGradient;

import '../../../core/theme/app_game_theme.dart';

final class FlameGameThemeAdapter {
  FlameGameThemeAdapter.fromAppTheme(AppGameTheme theme)
    : stageTop = theme.stageTop,
      stageBottom = theme.stageBottom,
      energy = theme.energy,
      correct = theme.correct,
      wrong = theme.wrong,
      dangerTimer = theme.dangerTimer;

  final Color stageTop;
  final Color stageBottom;
  final Color energy;
  final Color correct;
  final Color wrong;
  final Color dangerTimer;
}

final class AhdashGame extends FlameGame {
  AhdashGame({required FlameGameThemeAdapter theme, required this.reduceMotion})
    : _theme = theme;

  FlameGameThemeAdapter _theme;
  final bool reduceMotion;
  double _elapsed = 0;
  double _timerFraction = 1;

  void updateTheme(FlameGameThemeAdapter value) => _theme = value;

  void updateTimerFraction(double value) {
    _timerFraction = value.clamp(0, 1);
  }

  Future<void> showVerdict({required bool correct}) async {
    if (reduceMotion) return;
    await world.add(
      _AhdashBurst(
        color: correct ? _theme.correct : _theme.wrong,
        positive: correct,
      ),
    );
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += reduceMotion ? 0 : dt;
  }

  @override
  void render(Canvas canvas) {
    final bounds = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_theme.stageTop, _theme.stageBottom],
        ).createShader(bounds),
    );

    final linePaint = Paint()
      ..color = _theme.energy.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.x / 2, size.y * 0.44);
    canvas.drawCircle(center, math.min(size.x, size.y) * 0.18, linePaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.x, center.dy), linePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.08,
          size.y * 0.1,
          size.x * 0.84,
          size.y * 0.68,
        ),
        const Radius.circular(28),
      ),
      linePaint,
    );

    final danger = _timerFraction <= 0.33;
    final glowColor = danger ? _theme.dangerTimer : _theme.energy;
    final pulse = reduceMotion ? 0.5 : (math.sin(_elapsed * 2.4) + 1) / 2;
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.12),
      36 + (pulse * 5),
      Paint()
        ..color = glowColor.withValues(alpha: 0.04 + (pulse * 0.035))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    super.render(canvas);
  }
}

final class _AhdashBurst extends Component with HasGameReference<AhdashGame> {
  _AhdashBurst({required this.color, required this.positive});

  final Color color;
  final bool positive;
  final List<_BurstMark> _marks = [];
  double _age = 0;
  static const _lifespan = 0.42;

  @override
  Future<void> onLoad() async {
    final random = math.Random(positive ? 11 : 22);
    final origin = Offset(game.size.x / 2, game.size.y * 0.46);
    for (var index = 0; index < (positive ? 14 : 7); index++) {
      final angle = ((math.pi * 2) / (positive ? 14 : 7)) * index;
      final speed = 72 + random.nextDouble() * 54;
      _marks.add(
        _BurstMark(
          origin: origin,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          rotation: angle,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= _lifespan) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_age / _lifespan).clamp(0.0, 1.0).toDouble();
    final paint = Paint()
      ..color = color.withValues(alpha: 1 - progress)
      ..style = PaintingStyle.fill;
    for (final mark in _marks) {
      final position = mark.origin + (mark.velocity * _age);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(mark.rotation + progress);
      final path = Path()
        ..moveTo(0, -5)
        ..lineTo(4, 0)
        ..lineTo(0, 5)
        ..lineTo(-4, 0)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }
}

final class _BurstMark {
  const _BurstMark({
    required this.origin,
    required this.velocity,
    required this.rotation,
  });

  final Offset origin;
  final Offset velocity;
  final double rotation;
}
