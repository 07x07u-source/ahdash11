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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.gutter,
                16,
                metrics.gutter,
                12,
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
                    trailing: actions.isEmpty ? null : Wrap(children: actions),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
