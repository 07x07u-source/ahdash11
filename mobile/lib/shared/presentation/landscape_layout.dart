import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum LandscapeSize { compact, standard, wide }

@immutable
final class LandscapeMetrics {
  const LandscapeMetrics({
    required this.size,
    required this.width,
    required this.height,
    required this.textScale,
  });

  factory LandscapeMetrics.of(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final size = height <= 390 || width < 850
        ? LandscapeSize.compact
        : width >= 1180 || width / height >= 2.2
        ? LandscapeSize.wide
        : LandscapeSize.standard;
    return LandscapeMetrics(
      size: size,
      width: width,
      height: height,
      textScale: media.textScaler.scale(1).clamp(1, 1.4),
    );
  }

  final LandscapeSize size;
  final double width;
  final double height;
  final double textScale;

  bool get compact => size == LandscapeSize.compact;
  bool get wide => size == LandscapeSize.wide;
  bool get large => wide;
  bool get accessibilityFallback => textScale > 1.28;
  double get gutter => compact
      ? AppSpacing.xs
      : wide
      ? AppSpacing.md
      : AppSpacing.sm;
  double get railWidth => compact
      ? 56
      : wide
      ? 64
      : 60;
  double get panelGap => compact ? AppSpacing.xxs : AppSpacing.sm;
  int gridColumns({int compact = 3, int standard = 4, int large = 6}) =>
      switch (size) {
        LandscapeSize.compact => compact,
        LandscapeSize.standard => standard,
        LandscapeSize.wide => large,
      };
}

final class LandscapePane extends StatelessWidget {
  const LandscapePane({
    required this.child,
    this.flex = 1,
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    super.key,
  });

  final Widget child;
  final int flex;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: child,
    ),
  );
}

final class LandscapeScrollPane extends StatelessWidget {
  const LandscapeScrollPane({required this.child, this.controller, super.key});

  final Widget child;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: controller,
    padding: EdgeInsets.all(LandscapeMetrics.of(context).gutter),
    child: child,
  );
}
