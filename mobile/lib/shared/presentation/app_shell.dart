import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/feedback_service.dart';
import '../../core/theme/ahdash_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

final class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const destinations = <_DockDestination>[
    _DockDestination(
      '/home',
      'الرئيسية',
      AhdashIcons.home,
      AhdashIcons.homeSelected,
    ),
    _DockDestination(
      '/play',
      'اللعب',
      AhdashIcons.play,
      AhdashIcons.playSelected,
    ),
    _DockDestination(
      '/profile',
      'حسابي',
      AhdashIcons.profile,
      AhdashIcons.profileSelected,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final dockWidth = (viewportWidth - 40).clamp(272.0, 316.0).toDouble();
    final selected = destinations.indexWhere((item) => item.path == location);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ColoredBox(
          color: AppColors.paper0,
          child: Stack(
            children: [
              Positioned.fill(child: child),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 12 + safeBottom,
                child: Center(
                  child: SizedBox(
                    width: dockWidth,
                    child: Semantics(
                      container: true,
                      label: 'التنقل الرئيسي',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: AlignmentDirectional.topStart,
                                end: AlignmentDirectional.bottomEnd,
                                colors: [Color(0xD42F2C26), Color(0xCC191714)],
                              ),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: AppColors.paper3.withValues(alpha: .52),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3D191714),
                                  blurRadius: 24,
                                  offset: Offset(0, 11),
                                ),
                                BoxShadow(
                                  color: Color(0x22FFFFFF),
                                  blurRadius: 10,
                                  offset: Offset(0, -1),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              height: 64,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  children: [
                                    for (
                                      var index = 0;
                                      index < destinations.length;
                                      index++
                                    )
                                      Expanded(
                                        child: _DockItem(
                                          destination: destinations[index],
                                          selected: selected == index,
                                          reducedMotion: reducedMotion,
                                          onPressed: () {
                                            if (selected == index) return;
                                            ref
                                                .read(feedbackServiceProvider)
                                                .play(FeedbackCue.navigation);
                                            context.go(
                                              destinations[index].path,
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DockDestination {
  const _DockDestination(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

final class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.destination,
    required this.selected,
    required this.reducedMotion,
    required this.onPressed,
  });

  final _DockDestination destination;
  final bool selected;
  final bool reducedMotion;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: destination.label,
    excludeFromSemantics: true,
    waitDuration: const Duration(milliseconds: 500),
    child: Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('main-dock-${destination.path.substring(1)}'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            child: Center(
              child: AnimatedContainer(
                duration: reducedMotion ? Duration.zero : AppMotion.selection,
                curve: AppMotion.enterCurve,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(23),
                  border: selected
                      ? Border.all(color: const Color(0xFFDAFFA1))
                      : null,
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x2DB6FF3B),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: selected ? 22 : 21,
                      color: selected
                          ? AppColors.ink
                          : AppColors.paper1.withValues(alpha: .88),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: selected
                            ? AppColors.ink
                            : AppColors.paper1.withValues(alpha: .72),
                        fontSize: 9.5,
                        height: 1.05,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
