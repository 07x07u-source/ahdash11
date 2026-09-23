import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'v10_portrait.dart';

/// Shared account/utility shell; no viewport may override the user's text scale.
final class AhdashUtilityScaffold extends StatelessWidget {
  const AhdashUtilityScaffold({
    required this.title,
    required this.child,
    this.actions = const [],
    this.fallback = '/home',
    this.showBack = true,
    this.headerHeight,
    super.key,
  });
  final String title, fallback;
  final Widget child;
  final List<Widget> actions;
  final bool showBack;
  final double? headerHeight;
  @override
  Widget build(BuildContext context) {
    final metrics = AhdashV10Metrics.of(context);
    return Scaffold(
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
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.gutter,
                  metrics.sectionGap,
                  metrics.gutter,
                  metrics.gutter,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AhdashPageHeader(
                      title: title,
                      onBack: showBack
                          ? () => context.canPop()
                                ? context.pop()
                                : context.go(fallback)
                          : null,
                      trailing: actions.isEmpty
                          ? null
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: actions,
                            ),
                    ),
                    SizedBox(height: metrics.sectionGap),
                    Expanded(child: child),
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
