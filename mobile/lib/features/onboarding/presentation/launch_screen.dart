import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_preferences.dart';
import '../../../core/startup/startup_trace.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/auth_controller.dart';

final class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({
    this.minimumDisplayDuration = Duration.zero,
    this.autoNavigate = true,
    super.key,
  });

  final Duration minimumDisplayDuration;
  final bool autoNavigate;

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

final class _LaunchScreenState extends ConsumerState<LaunchScreen> {
  Future<String>? _destination;
  var _navigated = false;

  @override
  void initState() {
    super.initState();
    StartupTrace.mark('launch_mounted');
    if (widget.autoNavigate) {
      _destination = _resolveDestination();
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateWhenReady());
    }
  }

  Future<String> _resolveDestination() async {
    StartupTrace.mark('destination_resolution_started');
    final minimumBrandMoment = Future<void>.delayed(
      widget.minimumDisplayDuration,
    );
    final preferencesFuture = _safePreferences();
    final userFuture = _safeUser();
    final preferences = await preferencesFuture;
    final user = await userFuture;
    await minimumBrandMoment;
    final destination = !preferences.onboardingCompleted
        ? '/onboarding'
        : user == null
        ? '/auth'
        : '/home';
    StartupTrace.mark('destination_resolved_${destination.substring(1)}');
    return destination;
  }

  Future<AppPreferences> _safePreferences() async {
    try {
      return await ref.read(appPreferencesProvider.future);
    } catch (_) {
      return const AppPreferences();
    }
  }

  Future<AuthUser?> _safeUser() async {
    try {
      return await ref.read(authControllerProvider.future);
    } catch (_) {
      return null;
    }
  }

  Future<void> _navigateWhenReady() async {
    final destination = await (_destination ??= _resolveDestination());
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(appPreferencesProvider).value;
    final reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        (preferences?.reducedMotion ?? false);
    return BrandScaffold(
      showDevelopmentBadge: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFCF6), AppColors.paper0, Color(0xFFF3E9D9)],
            stops: [0, .58, 1],
          ),
        ),
        child: CustomPaint(
          painter: const _LaunchBackdropPainter(),
          child: AhdashV10Frame(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final portrait = constraints.maxHeight >= constraints.maxWidth;
                final compact = constraints.maxHeight < 720;
                final content = Semantics(
                  label: 'أحدعش، مجلس التحدي الكروي',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LaunchHero(
                        portrait: portrait,
                        compact: compact,
                        reducedMotion: reducedMotion,
                      ),
                      SizedBox(height: portrait ? 14 : 6),
                      _LaunchReveal(
                        delay: const Duration(milliseconds: 180),
                        reducedMotion: reducedMotion,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/branding/logo-wordmark.png',
                              width: portrait ? 224 : 174,
                              height: portrait ? 62 : 46,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              excludeFromSemantics: true,
                            ),
                            if (portrait) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'مجلس اللعبة الكروية',
                                style: TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const _LaunchPillRow(),
                            ] else
                              Text(
                                'اسأل  ·  نافس  ·  احسمها',
                                style: AhdashTypography.metadata.copyWith(
                                  color: AppColors.inkMuted,
                                  fontSize: 9,
                                  letterSpacing: .4,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                final animatedContent = TweenAnimationBuilder<double>(
                  duration: reducedMotion ? Duration.zero : AppMotion.launch,
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: 1),
                  child: content,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: .965 + (.035 * value),
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - value)),
                        child: child,
                      ),
                    ),
                  ),
                );
                return Column(
                  children: [
                    _LaunchReveal(
                      delay: const Duration(milliseconds: 50),
                      reducedMotion: reducedMotion,
                      child: _LaunchEditionBadge(compact: compact),
                    ),
                    const Spacer(flex: 2),
                    animatedContent,
                    const Spacer(flex: 3),
                    _LaunchReveal(
                      delay: const Duration(milliseconds: 420),
                      reducedMotion: reducedMotion,
                      child: _LaunchLoadingIndicator(
                        reducedMotion: reducedMotion,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _LaunchEditionBadge extends StatelessWidget {
  const _LaunchEditionBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F191714),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(width: 7),
            Text(
              'AHDASH 11  /  READY',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: AppColors.paper0,
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _LaunchPillRow extends StatelessWidget {
  const _LaunchPillRow();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _LaunchPill(label: 'اسأل'),
      SizedBox(width: 7),
      _LaunchPill(label: 'نافس', highlighted: true),
      SizedBox(width: 7),
      _LaunchPill(label: 'احسمها'),
    ],
  );
}

final class _LaunchPill extends StatelessWidget {
  const _LaunchPill({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: highlighted ? AppColors.primary : AppColors.paper1,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(
        color: highlighted ? AppColors.ink : AppColors.hairline,
      ),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
    ),
  );
}

final class _LaunchReveal extends StatefulWidget {
  const _LaunchReveal({
    required this.child,
    required this.delay,
    required this.reducedMotion,
  });

  final Widget child;
  final Duration delay;
  final bool reducedMotion;

  @override
  State<_LaunchReveal> createState() => _LaunchRevealState();
}

final class _LaunchRevealState extends State<_LaunchReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _LaunchReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion ||
        oldWidget.delay != widget.delay) {
      _syncMotion();
    }
  }

  void _syncMotion() {
    _timer?.cancel();
    if (widget.reducedMotion) {
      _controller
        ..stop()
        ..value = 1;
      return;
    }
    _controller
      ..stop()
      ..value = 0;
    _timer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final value = Curves.easeOutCubic.transform(_controller.value);
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Transform.scale(scale: .97 + (.03 * value), child: child),
        ),
      );
    },
  );
}

final class _LaunchHero extends StatefulWidget {
  const _LaunchHero({
    required this.portrait,
    required this.compact,
    required this.reducedMotion,
  });

  final bool portrait;
  final bool compact;
  final bool reducedMotion;

  @override
  State<_LaunchHero> createState() => _LaunchHeroState();
}

final class _LaunchHeroState extends State<_LaunchHero>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _orbitController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  Future<void> _startOrbitAfterEntrance() async {
    await _entranceController.forward(from: 0);
    if (!mounted || widget.reducedMotion) return;
    _orbitController.repeat();
  }

  @override
  void initState() {
    super.initState();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _LaunchHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion) _syncMotion();
  }

  void _syncMotion() {
    if (widget.reducedMotion) {
      _entranceController
        ..stop()
        ..value = 1;
      _orbitController
        ..stop()
        ..value = .18;
    } else if (!_entranceController.isAnimating &&
        !_orbitController.isAnimating) {
      _startOrbitAfterEntrance();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.portrait ? (widget.compact ? 210.0 : 246.0) : 148.0;
    final iconSize = size * .7;
    return SizedBox.square(
      dimension: size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _orbitController]),
        builder: (context, child) {
          final progress = _orbitController.value;
          final wave = math.sin(progress * math.pi * 2);
          final entrance = Curves.easeOutBack.transform(
            _entranceController.value,
          );
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: size * .96,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(
                          alpha: .18 + (.035 * wave.abs()),
                        ),
                        AppColors.gold.withValues(alpha: .055),
                        AppColors.paper0.withValues(alpha: 0),
                      ],
                      stops: const [0, .44, 1],
                    ),
                  ),
                ),
              ),
              SizedBox.square(
                dimension: size * .9,
                child: CustomPaint(
                  painter: _LaunchOrbitPainter(progress: progress),
                ),
              ),
              Transform.translate(
                offset: Offset(
                  0,
                  (widget.reducedMotion ? 0 : wave * 3) +
                      ((1 - _entranceController.value) * 18),
                ),
                child: Transform.scale(
                  scale:
                      entrance * (widget.reducedMotion ? 1 : 1 + (wave * .006)),
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(iconSize * .24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x35191714),
                          blurRadius: 30,
                          offset: Offset(0, 15),
                        ),
                        BoxShadow(
                          color: Color(0x1AB6FF3B),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(iconSize * .24),
                      child: child,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Opacity(
                  opacity: _entranceController.value,
                  child: CustomPaint(
                    size: Size.square(size),
                    painter: _LaunchLightSweepPainter(progress: progress),
                  ),
                ),
              ),
              PositionedDirectional(
                end: size * .055,
                bottom: size * .15,
                child: Container(
                  width: size * .2,
                  height: size * .2,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.paper0, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30191714),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    '11',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: size * .07,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: Image.asset(
          'assets/branding/app-icon.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

final class _LaunchBackdropPainter extends CustomPainter {
  const _LaunchBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.hairline.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final lime = Paint()
      ..color = AppColors.primary.withValues(alpha: .12)
      ..style = PaintingStyle.fill;
    final ink = Paint()
      ..color = AppColors.ink.withValues(alpha: .025)
      ..style = PaintingStyle.fill;

    canvas
      ..drawCircle(Offset(size.width * .08, size.height * .22), 124, line)
      ..drawCircle(Offset(size.width * .08, size.height * .22), 78, line)
      ..drawCircle(Offset(size.width * .93, size.height * .72), 142, line)
      ..drawCircle(Offset(size.width * .93, size.height * .72), 92, line)
      ..drawCircle(Offset(size.width * .93, size.height * .72), 34, lime);

    final slash = Path()
      ..moveTo(size.width * .72, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * .25, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(slash, ink);

    final accent = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .08, size.height * .12, 7, 70),
      const Radius.circular(99),
    );
    canvas.drawRRect(accent, lime);
  }

  @override
  bool shouldRepaint(covariant _LaunchBackdropPainter oldDelegate) => false;
}

final class _LaunchOrbitPainter extends CustomPainter {
  const _LaunchOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 7;
    final orbit = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = AppColors.hairline.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final limePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    final start = (progress * math.pi * 2) - (math.pi / 2);
    canvas
      ..drawCircle(center, radius, trackPaint)
      ..drawArc(orbit, start, math.pi * .34, false, limePaint);
    final dotAngle = start + (math.pi * .34);
    final dot = Offset(
      center.dx + (math.cos(dotAngle) * radius),
      center.dy + (math.sin(dotAngle) * radius),
    );
    canvas.drawCircle(dot, 2.7, Paint()..color = AppColors.gold);
  }

  @override
  bool shouldRepaint(covariant _LaunchOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

final class _LaunchLightSweepPainter extends CustomPainter {
  const _LaunchLightSweepPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 0) return;
    final rect = Offset.zero & size;
    final sweepWidth = size.shortestSide * .075;
    final paint = Paint()
      ..shader =
          const LinearGradient(
            colors: [Color(0x00B6FF3B), Color(0x65B6FF3B), Color(0x00B6FF3B)],
            stops: [0, .5, 1],
          ).createShader(
            Rect.fromLTWH(-sweepWidth, 0, sweepWidth * 2, size.height),
          );
    canvas
      ..save()
      ..clipRect(rect)
      ..translate(size.center(Offset.zero).dx, size.center(Offset.zero).dy)
      ..rotate((progress * math.pi * 2) - .7)
      ..drawRect(
        Rect.fromLTWH(
          -sweepWidth,
          -size.height,
          sweepWidth * 2,
          size.height * 2,
        ),
        paint,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _LaunchLightSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

final class _LaunchLoadingIndicator extends StatefulWidget {
  const _LaunchLoadingIndicator({required this.reducedMotion});

  final bool reducedMotion;

  @override
  State<_LaunchLoadingIndicator> createState() =>
      _LaunchLoadingIndicatorState();
}

final class _LaunchLoadingIndicatorState extends State<_LaunchLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  );

  @override
  void initState() {
    super.initState();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _LaunchLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion) _syncMotion();
  }

  void _syncMotion() {
    if (widget.reducedMotion) {
      _controller
        ..stop()
        ..value = .42;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'جاري تجهيز مجلسك الكروي',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26191714),
              blurRadius: 22,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: .28),
                    ),
                  ),
                  child: const Icon(
                    Icons.sports_soccer_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نضبط ملعبك…',
                        style: AhdashTypography.metadata.copyWith(
                          color: AppColors.paper0,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ثوانٍ وتبدأ أول صافرة',
                        style: TextStyle(
                          color: AppColors.paper3,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '11',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => SizedBox(
                width: double.infinity,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: ColoredBox(
                    color: AppColors.paper0.withValues(alpha: .11),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const segmentWidth = 64.0;
                        final left =
                            (constraints.maxWidth + segmentWidth) *
                                _controller.value -
                            segmentWidth;
                        return Stack(
                          children: [
                            Positioned(
                              left: left,
                              top: 0,
                              bottom: 0,
                              width: segmentWidth,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: const LinearGradient(
                                    colors: [AppColors.gold, AppColors.primary],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
