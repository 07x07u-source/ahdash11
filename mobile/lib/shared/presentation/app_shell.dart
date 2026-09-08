import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/services/feedback_service.dart';
import 'brand_scaffold.dart';
import 'game_ui.dart';

final class AppShell extends ConsumerWidget {
  const AppShell({
    required this.index,
    required this.child,
    this.appBar,
    super.key,
  });

  final int index;
  final Widget child;
  final PreferredSizeWidget? appBar;

  static const _paths = ['/home', '/play', '/teams', '/ranking', '/profile'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final destinations = [
      (AhdashGlyph.home, l10n.home),
      (AhdashGlyph.play, l10n.play),
      (AhdashGlyph.teams, l10n.social),
      (AhdashGlyph.ranking, l10n.ranking),
      (AhdashGlyph.profile, l10n.profile),
    ];
    return BrandScaffold(
      appBar: appBar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: child),
            NavigationBar(
              selectedIndex: index,
              height: 68,
              onDestinationSelected: (selected) {
                if (selected == index) return;
                ref.read(feedbackServiceProvider).play(FeedbackCue.navigation);
                context.go(_paths[selected]);
              },
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    icon: Icon(_materialIcon(item.$1)),
                    label: item.$2,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _materialIcon(AhdashGlyph glyph) => switch (glyph) {
  AhdashGlyph.home => Icons.home_rounded,
  AhdashGlyph.play => Icons.sports_esports_rounded,
  AhdashGlyph.teams => Icons.groups_rounded,
  AhdashGlyph.ranking => Icons.leaderboard_rounded,
  AhdashGlyph.profile => Icons.person_rounded,
  _ => Icons.circle_outlined,
};
