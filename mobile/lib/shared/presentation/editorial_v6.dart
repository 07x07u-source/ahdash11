import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import 'brand_identity.dart';

/// Shared composition primitives for the V6 editorial presentation layer.
/// They intentionally favour one continuous page, typographic hierarchy and
/// hairline separators over nested cards.
final class AhdashEditorialCanvas extends StatelessWidget {
  const AhdashEditorialCanvas({
    required this.child,
    this.accent,
    this.gold = false,
    super.key,
  });

  final Widget child;
  final Color? accent;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final signal = accent ?? (gold ? colors.gold : colors.primary);
    return ColoredBox(
      color: colors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PositionedDirectional(
            top: -160,
            end: -90,
            width: 440,
            height: 440,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    signal.withValues(alpha: 0.075),
                    signal.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: 0,
            start: 0,
            end: 0,
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: signal.withValues(alpha: 0.42)),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

final class EditorialPageFrame extends StatelessWidget {
  const EditorialPageFrame({
    required this.child,
    this.top = true,
    this.bottom = true,
    super.key,
  });

  final Widget child;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontal = size.width >= 1280
        ? 48.0
        : size.width >= 900
        ? 32.0
        : 20.0;
    final vertical = size.height <= 400 ? 10.0 : 18.0;
    return SafeArea(
      top: top,
      bottom: bottom,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: child,
      ),
    );
  }
}

final class EditorialScreenHeader extends StatelessWidget {
  const EditorialScreenHeader({
    required this.title,
    this.kicker,
    this.leading,
    this.actions = const [],
    this.showMark = true,
    this.gold = false,
    super.key,
  });

  final String title;
  final String? kicker;
  final Widget? leading;
  final List<Widget> actions;
  final bool showMark;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          if (kicker != null) ...[
            Container(
              width: 5,
              height: 22,
              color: gold ? colors.gold : colors.primary,
            ),
            const SizedBox(width: 9),
            Text(
              kicker!,
              style: AhdashTypography.metadata.copyWith(
                color: colors.textMuted,
              ),
            ),
            const SizedBox(width: 10),
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
          if (showMark) ...[
            const SizedBox(width: 12),
            const AhdashBrandLogo.mark(height: 30),
          ],
        ],
      ),
    );
  }
}

final class EditorialKickerV6 extends StatelessWidget {
  const EditorialKickerV6(this.text, {this.gold = false, super.key});

  final String text;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 3,
          color: gold ? colors.gold : colors.primary,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AhdashTypography.metadata.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

final class EditorialRule extends StatelessWidget {
  const EditorialRule({this.strong = false, this.vertical = false, super.key});

  final bool strong;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final color = strong
        ? context.ahdashColors.borderStrong
        : context.ahdashColors.border;
    return SizedBox(
      width: vertical ? 1 : double.infinity,
      height: vertical ? double.infinity : 1,
      child: ColoredBox(color: color),
    );
  }
}

final class EditorialPrimaryAction extends StatelessWidget {
  const EditorialPrimaryAction({
    required this.label,
    required this.onPressed,
    this.icon,
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
    final ink = colors.textPrimary;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(compact ? 132 : 176, compact ? 46 : 56),
        padding: EdgeInsetsDirectional.fromSTEB(
          compact ? 16 : 22,
          10,
          compact ? 12 : 16,
          10,
        ),
        backgroundColor: ink,
        foregroundColor: colors.background,
        disabledBackgroundColor: colors.disabled,
        shape: const RoundedRectangleBorder(),
        side: BorderSide(color: gold ? colors.gold : colors.primary, width: 2),
        textStyle: AhdashTypography.button,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (icon != null) ...[
            const SizedBox(width: 12),
            Icon(icon, size: 20),
          ],
        ],
      ),
    );
  }
}

final class EditorialStat extends StatelessWidget {
  const EditorialStat({
    required this.value,
    required this.label,
    this.gold = false,
    super.key,
  });

  final String value;
  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: AhdashTypography.score.copyWith(
            color: gold ? colors.gold : colors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AhdashTypography.metadata.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

enum EditorialChoiceState { idle, selected, correct, wrong, locked }

final class EditorialChoiceRow extends StatelessWidget {
  const EditorialChoiceRow({
    required this.index,
    required this.text,
    required this.state,
    this.onTap,
    super.key,
  });

  final int index;
  final String text;
  final EditorialChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final active = state == EditorialChoiceState.selected;
    final correct = state == EditorialChoiceState.correct;
    final wrong = state == EditorialChoiceState.wrong;
    final signal = correct
        ? colors.success
        : wrong
        ? colors.error
        : colors.primary;
    return Semantics(
      button: onTap != null,
      selected: active || correct,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.standard,
          decoration: BoxDecoration(
            color: (active || correct || wrong)
                ? signal.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: active || correct || wrong ? signal : colors.border,
                width: active || correct || wrong ? 2 : 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  textDirection: TextDirection.ltr,
                  style: AhdashTypography.metadata.copyWith(
                    color: active || correct || wrong
                        ? signal
                        : colors.textMuted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AhdashTypography.label.copyWith(
                    color: state == EditorialChoiceState.locked
                        ? colors.textMuted
                        : colors.textPrimary,
                  ),
                ),
              ),
              if (active || correct || wrong)
                Icon(
                  correct
                      ? Icons.check_rounded
                      : wrong
                      ? Icons.close_rounded
                      : Icons.arrow_back_rounded,
                  size: 20,
                  color: signal,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
