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
      body: ColoredBox(
        color: AppColors.paper0,
        child: AhdashV10Frame(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final portrait = constraints.maxHeight >= constraints.maxWidth;
              final content = Semantics(
                label: 'أحدعش، مجلس التحدي الكروي',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LaunchHero(
                      portrait: portrait,
                      reducedMotion: reducedMotion,
                    ),
                    SizedBox(height: portrait ? 8 : 4),
                    Image.asset(
                      'assets/branding/logo-wordmark.png',
                      width: portrait ? 214 : 176,
                      height: portrait ? 64 : 50,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                    SizedBox(height: portrait ? 4 : 2),
                    Text(
                      'A H D A S H  |  1 1',
                      textDirection: TextDirection.ltr,
                      style: AhdashTypography.metadata.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 9,
                        letterSpacing: 2.8,
                        fontWeight: FontWeight.w800,
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
                    scale: .975 + (.025 * value),
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - value)),
                      child: child,
                    ),
                  ),
                ),
              );
              return Column(
                children: [
                  const Spacer(flex: 5),
                  animatedContent,
                  const Spacer(flex: 6),
                  _LaunchLoadingIndicator(reducedMotion: reducedMotion),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _LaunchHero extends StatefulWidget {
  const _LaunchHero({required this.portrait, required this.reducedMotion});

  final bool portrait;
  final bool reducedMotion;

  @override
  State<_LaunchHero> createState() => _LaunchHeroState();
}

final class _LaunchHeroState extends State<_LaunchHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

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
      _controller
        ..stop()
        ..value = .18;
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
  Widget build(BuildContext context) {
    final size = widget.portrait ? 292.0 : 164.0;
    return SizedBox.square(
      dimension: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          final wave = math.sin(progress * math.pi * 2);
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: size * .78,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(
                          alpha: .11 + (.025 * wave.abs()),
                        ),
                        AppColors.gold.withValues(alpha: .035),
                        AppColors.paper0.withValues(alpha: 0),
                      ],
                      stops: const [0, .5, 1],
                    ),
                  ),
                ),
              ),
              SizedBox.square(
                dimension: size * .82,
                child: CustomPaint(
                  painter: _LaunchOrbitPainter(progress: progress),
                ),
              ),
              Transform.translate(
                offset: Offset(0, widget.reducedMotion ? 0 : wave * 4),
                child: Transform.scale(
                  scale: widget.reducedMotion ? 1 : 1 + (wave * .008),
                  child: child,
                ),
              ),
            ],
          );
        },
        child: Image.asset(
          'assets/branding/logo-symbol.png',
          width: widget.portrait ? 220 : 126,
          height: widget.portrait ? 220 : 126,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'نجهّز مجلسك الكروي',
            style: AhdashTypography.metadata.copyWith(
              color: AppColors.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => SizedBox(
              width: 116,
              height: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: ColoredBox(
                  color: AppColors.paper3.withValues(alpha: .7),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const segmentWidth = 34.0;
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
  );
}
