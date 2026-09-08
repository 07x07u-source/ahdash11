import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/presentation/brand_identity.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/auth_controller.dart';

final class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({
    this.minimumDisplayDuration = AppMotion.launch,
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
    if (widget.autoNavigate) {
      _destination = _resolveDestination();
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateWhenReady());
    }
  }

  Future<String> _resolveDestination() async {
    final minimumBrandMoment = Future<void>.delayed(
      widget.minimumDisplayDuration,
    );
    final preferencesFuture = _safePreferences();
    final userFuture = _safeUser();
    final preferences = await preferencesFuture;
    final user = await userFuture;
    await minimumBrandMoment;
    if (!preferences.onboardingCompleted) return '/onboarding';
    if (user == null) return '/auth';
    return '/home';
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
    final colors = context.ahdashColors;
    final preferences = ref.watch(appPreferencesProvider).value;
    final reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        (preferences?.reducedMotion ?? false);
    return BrandScaffold(
      showDevelopmentBadge: false,
      body: ColoredBox(
        color: colors.background,
        child: AhdashV10Frame(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = Semantics(
                label: 'أحدعش، لعبة التحدي الكروية',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border, width: 2),
                      ),
                      child: SizedBox.square(
                        dimension: 160,
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: AhdashBrandLogo.mark(width: 80, height: 80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'أحدعش',
                      style: AhdashTypography.display.copyWith(
                        color: colors.textPrimary,
                        fontSize: 44,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A H D A S H',
                      textDirection: TextDirection.ltr,
                      style: AhdashTypography.metadata.copyWith(
                        color: colors.textMuted,
                        fontSize: 11,
                        letterSpacing: 3,
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
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - value)),
                    child: Transform.scale(
                      scale: 0.96 + (value * 0.04),
                      child: child,
                    ),
                  ),
                ),
              );
              return Column(
                children: [
                  const Spacer(),
                  animatedContent,
                  const Spacer(),
                  Text(
                    'المجلس الرياضي الأول',
                    textAlign: TextAlign.center,
                    style: AhdashTypography.metadata.copyWith(
                      color: colors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
