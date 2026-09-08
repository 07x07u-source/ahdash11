import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import 'brand_identity.dart';

/// V9's screen-scale contract. It keeps controls readable at short landscape
/// heights and removes tertiary content before shrinking the primary task.
@immutable
final class AhdashV9Metrics {
  const AhdashV9Metrics._({
    required this.gutter,
    required this.verticalInset,
    required this.compact,
    required this.wide,
    required this.portrait,
  });

  factory AhdashV9Metrics.fromSize(Size size) {
    final portrait = size.height > size.width;
    final compact = size.width < 916 || size.height <= 412;
    final wide = size.width >= 1200 && size.height > 412;
    final gutter = portrait
        ? 16.0
        : switch (size.width) {
            >= 1366 => 40.0,
            >= 1200 => 32.0,
            >= 916 => 28.0,
            >= 844 => 24.0,
            _ => 20.0,
          };
    return AhdashV9Metrics._(
      gutter: gutter,
      verticalInset: portrait
          ? 12
          : compact
          ? 8
          : wide
          ? 16
          : 12,
      compact: compact,
      wide: wide,
      portrait: portrait,
    );
  }

  final double gutter;
  final double verticalInset;
  final bool compact;
  final bool wide;
  final bool portrait;

  double get primaryActionHeight => compact ? 48 : 52;
  double get secondaryActionHeight => compact ? 46 : 48;
  double get inputHeight => compact ? 48 : 52;
  double get touchTarget => 48;
  double get utilityGlyph => compact ? 20 : 22;
  double get displaySize => compact
      ? 30
      : wide
      ? 40
      : 36;
  double get screenTitleSize => compact
      ? 24
      : wide
      ? 30
      : 28;
  double get heroSize => compact
      ? 28
      : wide
      ? 36
      : 32;
  double get teamNameSize => compact
      ? 24
      : wide
      ? 32
      : 28;
  double get scoreSize => compact
      ? 34
      : wide
      ? 44
      : 40;
  double get sectionSize => compact
      ? 18
      : wide
      ? 22
      : 20;
  double get bodySize => compact
      ? 15
      : wide
      ? 17
      : 16;
  double get metadataSize => compact
      ? 12
      : wide
      ? 14
      : 13;
  double get majorGap => compact
      ? 16
      : wide
      ? 32
      : 24;
  double get sectionGap => compact
      ? 12
      : wide
      ? 24
      : 16;
}

extension AhdashV9MetricsContext on BuildContext {
  AhdashV9Metrics get v9Metrics =>
      AhdashV9Metrics.fromSize(MediaQuery.sizeOf(this));
}

final class AhdashV9Frame extends StatelessWidget {
  const AhdashV9Frame({
    required this.child,
    this.maxWidth = 1366,
    this.safeTop = true,
    this.safeBottom = true,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final bool safeTop;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final metrics = context.v9Metrics;
    return SafeArea(
      top: safeTop,
      bottom: safeBottom,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.gutter,
              vertical: metrics.verticalInset,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

final class AhdashV9IconButton extends StatelessWidget {
  const AhdashV9IconButton({
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
    final metrics = context.v9Metrics;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: BoxConstraints.tightFor(
        width: metrics.touchTarget,
        height: metrics.touchTarget,
      ),
      style: IconButton.styleFrom(
        foregroundColor: selected ? colors.textPrimary : colors.textSecondary,
        backgroundColor: selected ? colors.selected : Colors.transparent,
      ),
      icon: Icon(icon, size: metrics.utilityGlyph),
    );
  }
}

final class AhdashV9TopBar extends StatelessWidget {
  const AhdashV9TopBar({
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
    final metrics = context.v9Metrics;
    final accent = gold ? colors.gold : colors.primary;
    return SizedBox(
      height: metrics.touchTarget,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          if (kicker != null && !metrics.compact) ...[
            Container(width: 4, height: 24, color: accent),
            const SizedBox(width: 8),
            Text(
              kicker!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AhdashTypography.metadata.copyWith(
                color: colors.textMuted,
                fontSize: metrics.metadataSize,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AhdashTypography.sectionTitle.copyWith(
                color: colors.textPrimary,
                fontSize: metrics.sectionSize,
              ),
            ),
          ),
          const Spacer(),
          ...actions,
          if (showLogo) ...[
            const SizedBox(width: 12),
            AhdashBrandLogo.mark(height: metrics.compact ? 28 : 32),
          ],
        ],
      ),
    );
  }
}

final class AhdashV9PrimaryAction extends StatelessWidget {
  const AhdashV9PrimaryAction({
    required this.label,
    required this.onPressed,
    this.minimumWidth = 0,
    this.icon,
    this.gold = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final double minimumWidth;
  final IconData? icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final metrics = context.v9Metrics;
    final style = FilledButton.styleFrom(
      minimumSize: Size(minimumWidth, metrics.primaryActionHeight),
      backgroundColor: gold ? colors.gold : colors.primary,
      foregroundColor: colors.primaryForeground,
      textStyle: AhdashTypography.button.copyWith(
        fontSize: metrics.compact ? 15 : 17,
      ),
    );
    if (icon == null) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      iconAlignment: IconAlignment.end,
      icon: Icon(icon, size: metrics.utilityGlyph),
      label: Text(label),
    );
  }
}

/// Secondary action with the same measured height as the Figma handoff.
final class AhdashV9SecondaryAction extends StatelessWidget {
  const AhdashV9SecondaryAction({
    required this.label,
    required this.onPressed,
    this.minimumWidth = 0,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final double minimumWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final metrics = context.v9Metrics;
    final style = OutlinedButton.styleFrom(
      minimumSize: Size(minimumWidth, metrics.secondaryActionHeight),
      textStyle: AhdashTypography.button.copyWith(
        fontSize: metrics.compact ? 15 : 17,
      ),
    );
    if (icon == null) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      iconAlignment: IconAlignment.end,
      icon: Icon(icon, size: metrics.utilityGlyph),
      label: Text(label),
    );
  }
}

enum AhdashV9SurfaceTone { base, raised, muted }

/// Low-elevation paper surface used by cards, sheets, and grouped controls.
final class AhdashV9Surface extends StatelessWidget {
  const AhdashV9Surface({
    required this.child,
    this.tone = AhdashV9SurfaceTone.base,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    super.key,
  });

  final Widget child;
  final AhdashV9SurfaceTone tone;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final background = switch (tone) {
      AhdashV9SurfaceTone.base => colors.surface,
      AhdashV9SurfaceTone.raised => colors.surfaceElevated,
      AhdashV9SurfaceTone.muted => colors.surfaceMuted,
    };
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// V9.2 text input wrapper. Validation and controllers remain screen-owned.
final class AhdashV9Input extends StatelessWidget {
  const AhdashV9Input({
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    obscureText: obscureText,
    enabled: enabled,
    onChanged: onChanged,
    onFieldSubmitted: onSubmitted,
    validator: validator,
    style: AhdashTypography.body,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    ),
  );
}

/// A compact selectable option used for categories, filters, and helpers.
final class AhdashV9ChoiceChip extends StatelessWidget {
  const AhdashV9ChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    avatar: icon,
    selected: selected,
    onSelected: onSelected,
    labelStyle: AhdashTypography.label,
    showCheckmark: false,
  );
}

/// Standalone tab treatment for screens that do not use a Material [TabBar].
final class AhdashV9Tab extends StatelessWidget {
  const AhdashV9Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AhdashSizing.minimumTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? colors.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Text(
              label,
              style: AhdashTypography.label.copyWith(
                color: selected ? colors.textPrimary : colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AhdashV9TeamSide { a, b }

/// Canonical team color/name marker. Team A is pink; Team B is blue.
final class AhdashV9TeamIdentity extends StatelessWidget {
  const AhdashV9TeamIdentity({
    required this.name,
    required this.side,
    this.compact = false,
    super.key,
  });

  final String name;
  final AhdashV9TeamSide side;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final teamColor = side == AhdashV9TeamSide.a ? colors.teamA : colors.teamB;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 8 : 10,
          height: compact ? 24 : 32,
          decoration: BoxDecoration(
            color: teamColor,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AhdashTypography.teamName.copyWith(
              fontSize: compact ? 24 : context.v9Metrics.teamNameSize,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tabular score pair with stable BiDi behavior for Arabic layouts.
final class AhdashV9ScoreDisplay extends StatelessWidget {
  const AhdashV9ScoreDisplay({
    required this.teamAScore,
    required this.teamBScore,
    this.separator = '—',
    super.key,
  });

  final int teamAScore;
  final int teamBScore;
  final String separator;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'النتيجة $teamAScore مقابل $teamBScore',
    child: ExcludeSemantics(
      child: Text(
        '$teamAScore $separator $teamBScore',
        textDirection: TextDirection.ltr,
        style: AhdashTypography.score.copyWith(
          fontSize: context.v9Metrics.scoreSize,
        ),
      ),
    ),
  );
}

/// A reusable tournament row; routing and bracket state stay feature-owned.
final class AhdashV9TournamentMatchup extends StatelessWidget {
  const AhdashV9TournamentMatchup({
    required this.homeName,
    required this.awayName,
    this.homeScore,
    this.awayScore,
    this.onTap,
    super.key,
  });

  final String homeName;
  final String awayName;
  final int? homeScore;
  final int? awayScore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AhdashV9Surface(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    child: Row(
      children: [
        Expanded(
          child: AhdashV9TeamIdentity(
            name: homeName,
            side: AhdashV9TeamSide.a,
            compact: true,
          ),
        ),
        if (homeScore != null && awayScore != null)
          AhdashV9ScoreDisplay(teamAScore: homeScore!, teamBScore: awayScore!)
        else
          Text('ضد', style: AhdashTypography.metadata),
        Expanded(
          child: AhdashV9TeamIdentity(
            name: awayName,
            side: AhdashV9TeamSide.b,
            compact: true,
          ),
        ),
      ],
    ),
  );
}
