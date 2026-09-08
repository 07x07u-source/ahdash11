import 'package:flutter/material.dart';

import '../../core/theme/ahdash_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'brand_identity.dart';

/// Continuous V7 canvas: warm paper/charcoal, a restrained signal wash and
/// the paired-stroke 11 motif. It deliberately avoids panel grids.
final class AhdashV7Canvas extends StatelessWidget {
  const AhdashV7Canvas({required this.child, this.gold = false, super.key});

  final Widget child;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final accent = gold ? colors.gold : colors.primary;
    return ColoredBox(
      color: colors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PositionedDirectional(
            top: -220,
            end: -150,
            width: 560,
            height: 560,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.075),
                      accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            start: 18,
            child: IgnorePointer(
              child: Row(
                children: [
                  ColoredBox(
                    color: colors.border.withValues(alpha: 0.28),
                    child: const SizedBox(width: 1),
                  ),
                  const SizedBox(width: 5),
                  ColoredBox(
                    color: accent.withValues(alpha: 0.2),
                    child: const SizedBox(width: 1),
                  ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

final class AhdashV7Frame extends StatelessWidget {
  const AhdashV7Frame({
    required this.child,
    this.safeTop = true,
    this.safeBottom = true,
    super.key,
  });

  final Widget child;
  final bool safeTop;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontal = switch (size.width) {
      >= 1366 => 40.0,
      >= 1180 => 32.0,
      >= 850 => 24.0,
      _ => 20.0,
    };
    final vertical = size.width < 850 || size.height <= 390
        ? 8.0
        : size.width >= 1180
        ? 16.0
        : 12.0;
    return SafeArea(
      top: safeTop,
      bottom: safeBottom,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1366),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontal,
              vertical: vertical,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

final class AhdashV7TopBar extends StatelessWidget {
  const AhdashV7TopBar({
    required this.title,
    this.kicker,
    this.leading,
    this.actions = const [],
    this.showLogo = true,
    this.gold = false,
    super.key,
  });

  final String title;
  final String? kicker;
  final Widget? leading;
  final List<Widget> actions;
  final bool showLogo;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final wide = MediaQuery.sizeOf(context).width >= 1180;
    return SizedBox(
      height: wide ? 52 : 48,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          if (kicker != null) ...[
            AhdashV7Kicker(kicker!, gold: gold),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AhdashTypography.sectionTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          ...actions,
          if (showLogo) ...[
            const SizedBox(width: 10),
            const AhdashBrandLogo.mark(height: 27),
          ],
        ],
      ),
    );
  }
}

final class AhdashV7Kicker extends StatelessWidget {
  const AhdashV7Kicker(this.text, {this.gold = false, super.key});

  final String text;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final accent = gold ? colors.gold : colors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 7,
          height: 20,
          child: Row(
            children: [
              Expanded(child: ColoredBox(color: accent)),
              const SizedBox(width: 3),
              Expanded(child: ColoredBox(color: colors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AhdashTypography.metadata.copyWith(
            color: colors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

final class AhdashV7PrimaryAction extends StatelessWidget {
  const AhdashV7PrimaryAction({
    required this.label,
    required this.onPressed,
    this.icon = AhdashIcons.forward,
    this.gold = false,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool gold;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return FilledButton.icon(
      onPressed: onPressed,
      iconAlignment: IconAlignment.end,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: Size(compact ? 144 : 190, compact ? 48 : 52),
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.background,
        disabledBackgroundColor: colors.disabled,
        side: BorderSide(color: gold ? colors.gold : colors.primary, width: 2),
      ),
    );
  }
}

final class AhdashV7IconButton extends StatelessWidget {
  const AhdashV7IconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      style: IconButton.styleFrom(
        foregroundColor: selected ? colors.textPrimary : colors.textMuted,
        backgroundColor: selected ? colors.selected : Colors.transparent,
      ),
      icon: Icon(icon, size: 21),
    );
  }
}

final class AhdashV7Hairline extends StatelessWidget {
  const AhdashV7Hairline({this.strong = false, super.key});

  final bool strong;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    width: double.infinity,
    child: ColoredBox(
      color: strong
          ? context.ahdashColors.borderStrong
          : context.ahdashColors.border,
    ),
  );
}
