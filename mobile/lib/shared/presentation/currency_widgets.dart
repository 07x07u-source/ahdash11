import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/feedback_service.dart';
import '../../core/settings/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

abstract final class AhdashCoinAssets {
  static const mark = 'assets/images/currency/ahdash_coin_mark.svg';
  static const token = 'assets/images/currency/ahdash_coin_token.webp';
  static const stack = 'assets/images/currency/ahdash_coin_stack.webp';
  static const reward = 'assets/images/currency/ahdash_coin_reward.webp';
}

final class AhdashCoinIcon extends StatelessWidget {
  const AhdashCoinIcon({this.size = 24, this.semanticLabel, super.key});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AhdashCoinAssets.token,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
      filterQuality: FilterQuality.medium,
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: image)
        : Semantics(image: true, label: semanticLabel, child: image);
  }
}

final class AhdashCoinPrice extends StatelessWidget {
  const AhdashCoinPrice({
    required this.amount,
    this.compact = false,
    super.key,
  });

  final int amount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Semantics(
      label: '$amount كوين أحدعش',
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : AppSpacing.sm,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xD90B0F14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.gold.withValues(alpha: 0.58)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AhdashCoinIcon(size: compact ? 18 : 22),
            const SizedBox(width: 5),
            Text(
              '$amount',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class AhdashCoinBalance extends ConsumerStatefulWidget {
  const AhdashCoinBalance({
    required this.balance,
    this.onTap,
    this.compact = false,
    super.key,
  });

  final int balance;
  final VoidCallback? onTap;
  final bool compact;

  @override
  ConsumerState<AhdashCoinBalance> createState() => _AhdashCoinBalanceState();
}

final class _AhdashCoinBalanceState extends ConsumerState<AhdashCoinBalance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;
  late int _from;

  @override
  void initState() {
    super.initState();
    _from = widget.balance;
    _shine = AnimationController(vsync: this, duration: AppMotion.celebration);
  }

  @override
  void didUpdateWidget(covariant AhdashCoinBalance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.balance > oldWidget.balance) {
      _from = oldWidget.balance;
      final preferences =
          ref.read(appPreferencesProvider).value ?? const AppPreferences();
      if (!preferences.reducedMotion) {
        _shine.forward(from: 0);
      }
      unawaited(ref.read(feedbackServiceProvider).play(FeedbackCue.reward));
    } else {
      _from = widget.balance;
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences =
        ref.watch(appPreferencesProvider).value ?? const AppPreferences();
    final colors = context.ahdashColors;
    final duration = preferences.reducedMotion
        ? Duration.zero
        : AppMotion.celebration;
    final content = AnimatedBuilder(
      animation: _shine,
      builder: (context, child) {
        final scale = preferences.reducedMotion
            ? 1.0
            : 1 + (0.08 * (1 - (_shine.value * 2 - 1).abs()));
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? AppSpacing.xs : AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceElevated.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.gold.withValues(alpha: 0.48)),
          boxShadow: [
            BoxShadow(
              color: colors.gold.withValues(alpha: 0.12),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AhdashCoinIcon(size: widget.compact ? 24 : 30),
            const SizedBox(width: 6),
            TweenAnimationBuilder<double>(
              duration: duration,
              tween: Tween(
                begin: _from.toDouble(),
                end: widget.balance.toDouble(),
              ),
              builder: (context, value, _) => Text(
                value.round().toString(),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: widget.compact ? 13 : 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: widget.onTap != null,
      label: 'رصيدك ${widget.balance} كوين أحدعش',
      child: widget.onTap == null
          ? content
          : InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: content,
            ),
    );
  }
}

final class AhdashCoinReward extends StatelessWidget {
  const AhdashCoinReward({required this.amount, super.key});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'مكافأة $amount كوين أحدعش',
      child: SizedBox(
        width: 92,
        height: 92,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: Image.asset(
                AhdashCoinAssets.reward,
                fit: BoxFit.cover,
                cacheWidth: 184,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AhdashCoinPrice(amount: amount, compact: true),
            ),
          ],
        ),
      ),
    );
  }
}
