import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';

final class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

final class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = <(IconData, String, String)>[
    (
      Icons.grid_on_rounded,
      'اختار الفئات',
      'حدد مجالات الأسئلة المفضلة للمجلس، وانطلق بالتحدي.',
    ),
    (
      Icons.shield_outlined,
      'كوّن الفرق',
      'قسّم اللاعبين إلى فريقين متنافسين، واختر اسم كل فريق.',
    ),
    (
      Icons.help_outline_rounded,
      'جاوب',
      'استعرض معلوماتك الكروية، واكسب التحديات التاريخية تحت ضغط الوقت.',
    ),
    (
      Icons.emoji_events_outlined,
      'احسم الفوز',
      'أول فريق يصل إلى النقاط المستهدفة يفوز بالمجلس.',
    ),
  ];

  final _stepKeys = List<GlobalKey>.generate(4, (_) => GlobalKey());
  var _step = 0;
  var _finishing = false;

  Future<void> _setStep(int value) async {
    final next = value.clamp(0, _steps.length - 1);
    if (next == _step) return;
    setState(() => _step = next);
    await WidgetsBinding.instance.endOfFrame;
    final targetContext = _stepKeys[next].currentContext;
    if (targetContext == null || !targetContext.mounted) return;
    final reducedMotion =
        MediaQuery.disableAnimationsOf(targetContext) ||
        (ref.read(appPreferencesProvider).value?.reducedMotion ?? false);
    await Scrollable.ensureVisible(
      targetContext,
      duration: reducedMotion ? Duration.zero : AppMotion.selection,
      curve: Curves.easeOutCubic,
      alignment: 0.5,
    );
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
    final colors = context.ahdashColors;
    final compact =
        MediaQuery.sizeOf(context).height >= MediaQuery.sizeOf(context).width;
    return BrandScaffold(
      showDevelopmentBadge: false,
      body: ColoredBox(
        color: colors.background,
        child: AhdashV10Frame(
          maxWidth:
              MediaQuery.sizeOf(context).width >
                  MediaQuery.sizeOf(context).height
              ? 1366
              : 430,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                _OnboardingHeader(compact: compact, onSkip: _finish),
                const SizedBox(height: 8),
                Flexible(
                  fit: compact ? FlexFit.loose : FlexFit.tight,
                  child: SizedBox(
                    height: compact
                        ? (MediaQuery.sizeOf(context).height < 820 ? 410 : 430)
                        : double.infinity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (!compact) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (
                                var index = 0;
                                index < _steps.length;
                                index++
                              ) ...[
                                Expanded(
                                  child: _StepCard(
                                    key: _stepKeys[index],
                                    step: _steps[index],
                                    index: index,
                                    selected: index == _step,
                                    compact: true,
                                    onTap: () => _setStep(index),
                                  ),
                                ),
                                if (index != _steps.length - 1)
                                  const SizedBox(width: 12),
                              ],
                            ],
                          );
                        }
                        return _PortraitStep(
                          key: _stepKeys[_step],
                          step: _steps[_step],
                        );
                      },
                    ),
                  ),
                ),
                _StepIndicator(step: _step, count: _steps.length),
                SizedBox(height: compact ? 26 : 10),
                _OnboardingActions(
                  compact: compact,
                  step: _step,
                  count: _steps.length,
                  finishing: _finishing,
                  onBack: () => _setStep(_step - 1),
                  onNext: () => _step == _steps.length - 1
                      ? _finish()
                      : _setStep(_step + 1),
                  onSkip: _finish,
                  onHowToPlay: () => context.push('/how-to-play'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.compact, required this.onSkip});

  final bool compact;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: compact ? 36 : 48,
    child: Row(
      children: [
        TextButton(
          onPressed: onSkip,
          child: Text(
            'تخطي',
            style: AhdashTypography.label.copyWith(
              color: context.ahdashColors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'أحدعش',
          style: AhdashTypography.label.copyWith(
            color: context.ahdashColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: context.ahdashColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    ),
  );
}

final class _PortraitStep extends StatelessWidget {
  const _PortraitStep({required this.step, super.key});

  final (IconData, String, String) step;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: 220,
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.ahdashColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.ahdashColors.border,
                width: 1.5,
              ),
            ),
            child: Icon(step.$1, size: 72, color: const Color(0xFF45A36C)),
          ),
        ),
        const SizedBox(height: 32),
        Text(step.$2, style: AhdashTypography.headline.copyWith(fontSize: 32)),
        const SizedBox(height: 12),
        Text(
          step.$3,
          style: AhdashTypography.body.copyWith(
            color: context.ahdashColors.textSecondary,
            fontSize: 16,
            height: 1.5,
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
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        'خطوة ${step + 1} من $count',
        style: AhdashTypography.metadata.copyWith(
          color: context.ahdashColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Spacer(),
      for (var index = 0; index < count; index++) ...[
        AnimatedContainer(
          duration: AppMotion.selection,
          width: index == step ? 16 : 6,
          height: 4,
          decoration: BoxDecoration(
            color: index == step
                ? context.ahdashColors.textPrimary
                : context.ahdashColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (index != count - 1) const SizedBox(width: 4),
      ],
    ],
  );
}

final class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.index,
    required this.selected,
    required this.compact,
    required this.onTap,
    super.key,
  });

  final (IconData, String, String) step;
  final int index;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Semantics(
      selected: selected,
      button: true,
      label: 'الخطوة ${index + 1}: ${step.$2}',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(
            color: selected ? colors.primary : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected ? colors.primary : colors.background,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        child: Text(
                          'الخطوة ${index + 1}',
                          style: AhdashTypography.metadata.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(step.$1, size: compact ? 24 : 32),
                  ],
                ),
                const Spacer(),
                Text(
                  step.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AhdashTypography.sectionTitle.copyWith(
                    fontSize: compact ? 16 : 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.$3,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: AhdashTypography.metadata.copyWith(
                    color: colors.textMuted,
                    fontSize: compact ? 11 : 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.compact,
    required this.step,
    required this.count,
    required this.finishing,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.onHowToPlay,
  });

  final bool compact;
  final int step;
  final int count;
  final bool finishing;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onHowToPlay;

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Container(
        padding: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.ahdashColors.border)),
        ),
        child: Row(
          children: [
            TextButton(
              onPressed: finishing ? null : onHowToPlay,
              child: const Text('كيف نلعب؟'),
            ),
            const Spacer(),
            SizedBox(
              width: 180,
              child: AhdashV9PrimaryAction(
                label: 'ابدأ الآن',
                onPressed: finishing ? null : onSkip,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.ahdashColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AhdashV9PrimaryAction(
            label: step == count - 1 ? 'ابدأ الآن' : 'التالي',
            onPressed: finishing ? null : onNext,
          ),
          if (step > 0)
            TextButton(
              onPressed: finishing ? null : onBack,
              child: const Text('السابق'),
            ),
        ],
      ),
    );
  }
}
