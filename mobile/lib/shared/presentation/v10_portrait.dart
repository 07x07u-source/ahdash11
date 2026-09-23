import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Shared RTL header. Content sizes naturally; utility actions stay 44px+.
final class AhdashPageHeader extends StatelessWidget {
  const AhdashPageHeader({
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    super.key,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = MediaQuery.sizeOf(context).width < 390;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null) ...[
          IconButton.outlined(
            tooltip: 'رجوع',
            onPressed: onBack,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.ink,
              backgroundColor: AppColors.paper0,
              minimumSize: const Size.square(AhdashSizing.touchTarget),
              fixedSize: const Size.square(AhdashSizing.touchTarget),
              overlayColor: AppColors.brandLime.withValues(alpha: .16),
              side: const BorderSide(color: AppColors.hairline),
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 21),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 21 : 22,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: textScale > 1.2 ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: textScale > 1.2 ? 6 : 10),
          Padding(padding: const EdgeInsets.only(top: 1), child: trailing!),
        ],
      ],
    );
  }
}

/// Shared shell for the final V10 product surfaces. It intentionally keeps
/// the content column narrow while allowing every supported portrait width to
/// use its own gutter. Screens choose whether their body owns scrolling.
final class AhdashV10Page extends StatelessWidget {
  const AhdashV10Page({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    this.onBack,
    this.scrollable = false,
    this.keyboardSafe = false,
    this.maxWidth = 430,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool scrollable;
  final bool keyboardSafe;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final metrics = AhdashV10Metrics.of(context);
    Widget content = child;
    if (scrollable || keyboardSafe) {
      content = SingleChildScrollView(
        key: ValueKey(
          keyboardSafe ? 'v10-page-keyboard-scroll' : 'v10-page-scroll',
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        // Scaffold already consumes the keyboard inset. Do not count it twice.
        padding: EdgeInsets.only(bottom: metrics.gutter),
        child: child,
      );
    }
    final headerActions = actions.isEmpty
        ? null
        : Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            children: actions,
          );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.paper0,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.paper0, Color(0xFFF8F2E7), AppColors.paper0],
            stops: [0, .62, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.gutter,
                  metrics.gutter,
                  metrics.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AhdashPageHeader(
                      title: title,
                      subtitle: subtitle,
                      onBack: onBack,
                      trailing: headerActions,
                    ),
                    SizedBox(height: metrics.sectionGap),
                    Expanded(child: content),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class AhdashV10Panel extends StatelessWidget {
  const AhdashV10Panel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.semanticLabel,
    this.selected = false,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.selectedBorderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool selected;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final Color? selectedBorderColor;

  @override
  Widget build(BuildContext context) {
    final panel = Ink(
      decoration: BoxDecoration(
        color: selected
            ? (selectedBackgroundColor ?? AppColors.paper2)
            : (backgroundColor ?? AppColors.paper1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? (selectedBorderColor ?? AppColors.ink)
              : AppColors.hairline,
          width: selected ? 1.35 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C191714),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: padding, child: child),
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: Material(color: Colors.transparent, child: panel),
    );
  }
}

/// V10 portrait sizing contract. It deliberately scales spacing, not the
/// product model, across the supported 360–430 logical-pixel widths.
@immutable
final class AhdashV10Metrics {
  const AhdashV10Metrics._(this.width, this.height);

  factory AhdashV10Metrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AhdashV10Metrics._(size.width, size.height);
  }

  final double width;
  final double height;

  double get gutter => width >= 390 ? 24 : 20;
  double get sectionGap => height < 820 ? 14 : 20;
  double get heroSize => width < 390 ? 31 : 34;
}

final class AhdashV10Frame extends StatelessWidget {
  const AhdashV10Frame({
    required this.child,
    this.padding,
    this.maxWidth = 430,
    this.safeTop = true,
    this.safeBottom = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final bool safeTop;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final metrics = AhdashV10Metrics.of(context);
    return SafeArea(
      top: safeTop,
      bottom: safeBottom,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding ?? EdgeInsets.all(metrics.gutter),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Keyboard-safe V10 surface. Focused fields remain reachable and the bottom
/// action scrolls above viewInsets on small portrait devices.
final class AhdashV10KeyboardScroll extends StatelessWidget {
  const AhdashV10KeyboardScroll({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metrics = AhdashV10Metrics.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          key: const ValueKey('v10-keyboard-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            metrics.gutter,
            metrics.gutter,
            metrics.gutter,
            metrics.gutter + inset,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - metrics.gutter * 2 - inset)
                  .clamp(0, double.infinity),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

final class AhdashV10PrimaryButton extends StatelessWidget {
  const AhdashV10PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final enabled = !loading && onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      liveRegion: loading,
      label: loading ? '$label، جارٍ التنفيذ' : label,
      onTap: enabled ? onPressed : null,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            minHeight: textScale > 1.2 ? 60 : 56,
          ),
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : AppMotion.selection,
              switchInCurve: AppMotion.enterCurve,
              switchOutCurve: AppMotion.exitCurve,
              child: loading
                  ? const SizedBox.square(
                      key: ValueKey('v10-primary-loading'),
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      key: const ValueKey('v10-primary-label'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: textScale > 1.2 ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(icon, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

final class AhdashV10ScreenTitle extends StatelessWidget {
  const AhdashV10ScreenTitle({
    required this.title,
    required this.subtitle,
    this.onDark = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final metrics = AhdashV10Metrics.of(context);
    final foreground = onDark ? AppColors.paper0 : AppColors.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AhdashTypography.headline.copyWith(
            color: foreground,
            fontSize: metrics.heroSize,
            height: 1.15,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AhdashTypography.body.copyWith(
            color: onDark
                ? AppColors.paper1.withValues(alpha: .78)
                : AppColors.inkSoft,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
