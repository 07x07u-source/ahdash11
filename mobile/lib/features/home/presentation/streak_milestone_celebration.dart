import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/presentation/brand_identity.dart';

final class StreakMilestoneCelebration extends StatelessWidget {
  const StreakMilestoneCelebration({
    required this.days,
    required this.emoji,
    required this.onContinue,
    super.key,
  });

  final int days;
  final String emoji;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final nextMilestone = _nextMilestone(days);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: ColoredBox(
          color: colors.background.withValues(alpha: 0.16),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.045,
                    child: Image.asset(
                      'assets/branding/brand-pattern.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      semanticLabel: 'نقشة هوية أحدعش',
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(child: _StreakMotionBackdrop()),
                ),
                const PositionedDirectional(
                  top: -90,
                  end: -72,
                  child: _AccentOrb(size: 240),
                ),
                const PositionedDirectional(
                  bottom: -70,
                  start: -52,
                  child: _AccentOrb(size: 170, muted: true),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: const Text(
                                  'إنجاز جديد',
                                  style: TextStyle(
                                    color: AppColors.paper0,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const AhdashBrandLogo(
                                width: 98,
                                height: 32,
                                semanticLabel: 'أحدعش | 11',
                              ),
                            ],
                          ),
                          const SizedBox(height: 45),
                          _MilestoneEmblem(emoji: emoji),
                          const SizedBox(height: 18),
                          _CountUpNumber(
                            days: days,
                            key: const ValueKey('streak-milestone-days'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يوم بدون انقطاع!',
                            textAlign: TextAlign.center,
                            style: AhdashTypography.headline.copyWith(
                              color: AppColors.ink,
                              fontSize: 25,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _milestoneMessage(days),
                            textAlign: TextAlign.center,
                            style: AhdashTypography.body.copyWith(
                              color: AppColors.inkMuted,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _MilestoneRail(current: days, next: nextMilestone),
                          const SizedBox(height: 20),
                          const SizedBox(
                            width: double.infinity,
                            child: Divider(color: AppColors.hairline),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.flag_rounded,
                                size: 20,
                                color: AppColors.ink,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'المحطة القادمة: $nextMilestone يوم',
                                  style: AhdashTypography.label.copyWith(
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ),
                              Text(
                                '$days/$nextMilestone',
                                textDirection: TextDirection.ltr,
                                style: AhdashTypography.metadata.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Semantics(
                            button: true,
                            label: 'أكمل اللعب',
                            child: SizedBox(
                              width: 124,
                              height: 38,
                              child: FilledButton(
                                key: const ValueKey(
                                  'streak-milestone-continue',
                                ),
                                onPressed: onContinue,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.ink,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  shape: const StadiumBorder(
                                    side: BorderSide(
                                      color: AppColors.ink,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: const Text('أكمل اللعب'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

final class _StreakMotionBackdrop extends StatefulWidget {
  const _StreakMotionBackdrop();

  @override
  State<_StreakMotionBackdrop> createState() => _StreakMotionBackdropState();
}

final class _StreakMotionBackdropState extends State<_StreakMotionBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  var _motionPrepared = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionPrepared) return;
    _motionPrepared = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0.55;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final runnerWidth = (width * 0.66).clamp(210.0, 300.0);
      final travel = width + runnerWidth;
      return Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _StreakPitchPainter()),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final eased = Curves.easeInOutCubic.transform(_controller.value);
              return PositionedDirectional(
                bottom: constraints.maxHeight * 0.055,
                start: -runnerWidth + (travel * eased),
                child: Opacity(
                  opacity: 0.13,
                  child: Image.asset(
                    'assets/visuals/streak_runner_cutout.png',
                    width: runnerWidth,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: 'لاعب يركض بالكرة',
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

final class _StreakPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final accent = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final baseline = size.height * 0.86;
    canvas.drawLine(
      Offset(size.width * 0.06, baseline),
      Offset(size.width * 0.94, baseline),
      accent,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        -size.width * 0.20,
        baseline - size.width * 0.46,
        size.width * 0.92,
        size.width * 0.92,
      ),
      -0.35,
      1.02,
      false,
      line,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.38,
        baseline - size.width * 0.35,
        size.width * 0.82,
        size.width * 0.82,
      ),
      2.2,
      0.7,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _StreakPitchPainter oldDelegate) => false;
}

final class _MilestoneRail extends StatelessWidget {
  const _MilestoneRail({required this.current, required this.next});

  final int current;
  final int next;

  @override
  Widget build(BuildContext context) {
    final previous = _previousMilestone(current);
    final progress = ((current - previous) / (next - previous)).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            _RailDot(active: true, label: '$current'),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _RailDot(label: '$next'),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(
              'رحلة الشعلة',
              style: AhdashTypography.metadata.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const Spacer(),
            Text(
              'المحطة التالية',
              style: AhdashTypography.metadata.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _RailDot extends StatelessWidget {
  const _RailDot({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.paper1,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: active
            ? const Icon(Icons.check_rounded, size: 12, color: AppColors.ink)
            : null,
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textDirection: TextDirection.ltr,
        style: AhdashTypography.metadata.copyWith(color: AppColors.inkSoft),
      ),
    ],
  );
}

final class _CountUpNumber extends StatefulWidget {
  const _CountUpNumber({required this.days, super.key});

  final int days;

  @override
  State<_CountUpNumber> createState() => _CountUpNumberState();
}

final class _CountUpNumberState extends State<_CountUpNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.celebration,
  );
  late Animation<int> _count;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _count = IntTween(begin: 0, end: widget.days).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _CountUpNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days == widget.days) return;
    _count = IntTween(begin: 0, end: widget.days).animate(_controller);
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'وصلت إلى ${widget.days} يومًا متتاليًا',
    child: AnimatedBuilder(
      animation: _count,
      builder: (context, _) => Text(
        '${_count.value}',
        textDirection: TextDirection.ltr,
        style: AhdashTypography.score.copyWith(
          color: AppColors.ink,
          fontSize: 74,
          height: 0.95,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

final class _MilestoneEmblem extends StatelessWidget {
  const _MilestoneEmblem({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.72, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.celebration,
    curve: AppMotion.springCurve,
    builder: (context, scale, child) =>
        Transform.scale(scale: scale, child: child),
    child: SizedBox.square(
      dimension: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.36),
                width: 1,
              ),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24B6FF3B),
                  blurRadius: 22,
                  spreadRadius: 5,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              semanticsLabel: 'رمز سلسلة الأيام',
              style: const TextStyle(fontSize: 52, height: 1),
            ),
          ),
          const Positioned(
            top: 3,
            right: 16,
            child: _Spark(size: 10, color: AppColors.gold),
          ),
          const Positioned(
            bottom: 10,
            left: 9,
            child: _Spark(size: 7, color: AppColors.primary),
          ),
        ],
      ),
    ),
  );
}

final class _AccentOrb extends StatelessWidget {
  const _AccentOrb({required this.size, this.muted = false});

  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: (muted ? AppColors.gold : AppColors.primary).withValues(
        alpha: muted ? 0.09 : 0.13,
      ),
    ),
  );
}

final class _Spark extends StatelessWidget {
  const _Spark({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: 0.78,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

String _milestoneMessage(int days) => switch (days) {
  10 => 'أول عشرة أيام متتالية! حافظ على الشعلة وخلك حاضر كل يوم.',
  50 => 'خمسون يومًا من الاستمرار. هذا مو حظ، هذه عادة بطل.',
  100 => 'مئة يوم كاملة! إنجاز نادر يثبت أنك من نخبة لاعبي أحدعش.',
  365 => 'سنة كاملة من الحضور اليومي. إنجاز أسطوري يستحق الاحتفال.',
  _ => 'وصلت لمحطة كبيرة جديدة. استمر، وسجلك القادم أقرب مما تتخيل.',
};

int _nextMilestone(int days) {
  if (days < 10) return 10;
  if (days < 50) return 50;
  if (days < 100) return 100;
  if (days < 365) {
    final nextHundred = ((days ~/ 100) + 1) * 100;
    return nextHundred > 365 ? 365 : nextHundred;
  }
  return ((days ~/ 100) + 1) * 100;
}

int _previousMilestone(int days) {
  if (days <= 10) return 0;
  if (days <= 50) return 10;
  if (days <= 100) return 50;
  if (days <= 365) return (days ~/ 100) * 100;
  return ((days ~/ 100) * 100).clamp(365, 9999);
}
