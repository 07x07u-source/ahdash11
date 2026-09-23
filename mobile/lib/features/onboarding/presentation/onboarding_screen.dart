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

final class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

final class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = <(IconData, String, String, String)>[
    (
      Icons.grid_on_rounded,
      'اختار الفئات',
      'حدد مجالات الأسئلة المفضلة لجلسة اللعب من بين الدوريات العالمية والمحلية.',
      'assets/images/onboarding/onboarding_categories_ahdash.png',
    ),
    (
      Icons.shield_outlined,
      'كوّن الفرق',
      'قسّم اللاعبين إلى فريقين، واختر اسم كل فريق قبل بداية اللعب.',
      'assets/images/onboarding/onboarding_teams_ahdash.png',
    ),
    (
      Icons.help_outline_rounded,
      'جاوب',
      'اختبر معلوماتك الكروية، وأجب عن السؤال قبل انتهاء الوقت.',
      'assets/images/onboarding/onboarding_answer_ahdash.png',
    ),
    (
      Icons.emoji_events_outlined,
      'احسم الفوز',
      'اجمع النقاط؛ أول فريق يصل إلى الهدف يفوز بالمجلس.',
      'assets/images/onboarding/onboarding_victory_ahdash.png',
    ),
  ];

  var _step = 0;
  var _finishing = false;

  void _setStep(int value) {
    final next = value.clamp(0, _steps.length - 1);
    if (next == _step) return;
    setState(() => _step = next);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await ref.read(appPreferencesProvider.notifier).completeOnboarding();
      if (mounted) context.go('/auth');
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ التقدم. حاول مرة أخرى.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final portrait = size.height >= size.width;
    return BrandScaffold(
      showDevelopmentBadge: false,
      body: ColoredBox(
        color: AppColors.paper0,
        child: AhdashV10Frame(
          maxWidth: portrait ? 430 : 1366,
          child: SizedBox.expand(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: portrait
                  ? _PortraitOnboarding(
                      step: _step,
                      count: _steps.length,
                      item: _steps[_step],
                      finishing: _finishing,
                      onSkip: _finish,
                      onBack: () => _setStep(_step - 1),
                      onNext: () => _step == _steps.length - 1
                          ? _finish()
                          : _setStep(_step + 1),
                    )
                  : _LandscapeOnboarding(
                      steps: _steps,
                      selectedStep: _step,
                      finishing: _finishing,
                      onStepSelected: _setStep,
                      onSkip: _finish,
                      onHowToPlay: () => context.push('/how-to-play'),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _PortraitOnboarding extends StatelessWidget {
  const _PortraitOnboarding({
    required this.step,
    required this.count,
    required this.item,
    required this.finishing,
    required this.onSkip,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int count;
  final (IconData, String, String, String) item;
  final bool finishing;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final copyHeight = textScale > 1.15 ? 200.0 : 152.0;
    return Column(
      children: [
        _OnboardingHeader(onSkip: onSkip),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: reducedMotion ? Duration.zero : AppMotion.selection,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: .97,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Center(
                    key: ValueKey('onboarding-art-$step'),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 260,
                        maxHeight: 245,
                      ),
                      child: _OnboardingArt(assetPath: item.$4),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: reducedMotion ? Duration.zero : AppMotion.selection,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: SizedBox(
                  key: ValueKey('onboarding-step-$step'),
                  height: copyHeight,
                  child: _OnboardingCopy(
                    step: step,
                    count: count,
                    title: item.$2,
                    description: item.$3,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              _StepIndicator(step: step, count: count),
              const SizedBox(height: 28),
              _PortraitActions(
                step: step,
                count: count,
                finishing: finishing,
                onBack: onBack,
                onNext: onNext,
              ),
              const SizedBox(height: 44),
            ],
          ),
        ),
      ],
    );
  }
}

final class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        const AhdashBrandLogo(width: 92, height: 30, onDarkSurface: false),
        const Spacer(),
        TextButton(
          key: const ValueKey('onboarding-skip-action'),
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.inkMuted,
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            textStyle: AhdashTypography.label.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: const Text('تخطي'),
        ),
      ],
    ),
  );
}

final class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy({
    required this.step,
    required this.count,
    required this.title,
    required this.description,
  });

  final int step;
  final int count;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '0${step + 1} / 0$count',
            textDirection: TextDirection.ltr,
            style: AhdashTypography.metadata.copyWith(
              color: AppColors.inkMuted,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AhdashTypography.headline.copyWith(
          color: AppColors.ink,
          fontSize: 26,
          height: 1.2,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        description,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AhdashTypography.body.copyWith(
          color: AppColors.inkSoft,
          fontSize: 13,
          height: 1.55,
          fontWeight: FontWeight.w400,
        ),
      ),
    ],
  );
}

final class _OnboardingArt extends StatelessWidget {
  const _OnboardingArt({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 260,
    height: 245,
    child: Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Center(
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.hairline.withValues(alpha: .42),
              ),
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .09),
                  AppColors.gold.withValues(alpha: .025),
                  AppColors.paper0.withValues(alpha: 0),
                ],
                stops: const [0, .55, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
        ),
      ],
    ),
  );
}

final class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.count});

  final int step;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'خطوة ${step + 1} من $count',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++) ...[
          AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.selection,
            width: index == step ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: index == step ? AppColors.primary : AppColors.paper3,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          if (index != count - 1) const SizedBox(width: 6),
        ],
      ],
    ),
  );
}

final class _PortraitActions extends StatelessWidget {
  const _PortraitActions({
    required this.step,
    required this.count,
    required this.finishing,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int count;
  final bool finishing;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (step > 0) ...[
        SizedBox(
          width: 82,
          height: 52,
          child: OutlinedButton(
            onPressed: finishing ? null : onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.hairline),
              shape: const StadiumBorder(),
              padding: EdgeInsets.zero,
              textStyle: AhdashTypography.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('السابق'),
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: SizedBox(
          height: 52,
          child: FilledButton(
            key: const ValueKey('onboarding-primary-action'),
            onPressed: finishing ? null : onNext,
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.ink,
              disabledBackgroundColor: AppColors.paper2,
              disabledForegroundColor: AppColors.inkMuted,
              shape: const StadiumBorder(
                side: BorderSide(color: AppColors.ink, width: .8),
              ),
              textStyle: AhdashTypography.label.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: finishing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.ink,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(step == count - 1 ? 'ابدأ الآن' : 'التالي'),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    ],
  );
}

final class _LandscapeOnboarding extends StatelessWidget {
  const _LandscapeOnboarding({
    required this.steps,
    required this.selectedStep,
    required this.finishing,
    required this.onStepSelected,
    required this.onSkip,
    required this.onHowToPlay,
  });

  final List<(IconData, String, String, String)> steps;
  final int selectedStep;
  final bool finishing;
  final ValueChanged<int> onStepSelected;
  final VoidCallback onSkip;
  final VoidCallback onHowToPlay;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _OnboardingHeader(onSkip: onSkip),
      const SizedBox(height: 20),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              Expanded(
                child: _StepCard(
                  item: steps[index],
                  index: index,
                  selected: index == selectedStep,
                  onTap: () => onStepSelected(index),
                ),
              ),
              if (index != steps.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          TextButton(
            onPressed: finishing ? null : onHowToPlay,
            child: const Text('كيف نلعب؟'),
          ),
          const Spacer(),
          SizedBox(
            width: 190,
            height: 50,
            child: FilledButton(
              key: const ValueKey('onboarding-primary-action'),
              onPressed: finishing ? null : onSkip,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.ink,
                elevation: 0,
                shape: const StadiumBorder(
                  side: BorderSide(color: AppColors.ink, width: .8),
                ),
              ),
              child: const Text('ابدأ الآن'),
            ),
          ),
        ],
      ),
    ],
  );
}

final class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.item,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final (IconData, String, String, String) item;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: 'الخطوة ${index + 1}: ${item.$2}',
    child: Material(
      color: selected ? AppColors.paper1 : AppColors.paper0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? AppColors.ink : AppColors.hairline,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.paper1,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.$1, size: 23, color: AppColors.ink),
                ),
              ),
              const Spacer(),
              Text(
                item.$2,
                style: AhdashTypography.sectionTitle.copyWith(
                  color: AppColors.ink,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                item.$3,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AhdashTypography.body.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
