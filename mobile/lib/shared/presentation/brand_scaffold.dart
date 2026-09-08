import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

final class BrandScaffold extends ConsumerWidget {
  const BrandScaffold({
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.showDevelopmentBadge = true,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool showDevelopmentBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final colors = context.ahdashColors;
    return Scaffold(
      appBar: appBar,
      extendBody: extendBody,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: Opacity(
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.035
                  : 0.018,
              child: Image.asset(
                'assets/branding/brand-pattern.png',
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          body,
          if (showDevelopmentBadge &&
              kDebugMode &&
              config.environment == AppEnvironment.development &&
              !config.hasSupabase)
            PositionedDirectional(
              top: AppSpacing.xs,
              start: AppSpacing.xs,
              child: Semantics(
                label: 'وضع التطوير المحلي',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.gold,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Text(
                      'DEV',
                      style: TextStyle(
                        color: colors.primaryForeground,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.maxWidth = 760,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
