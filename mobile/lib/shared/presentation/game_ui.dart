import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'brand_identity.dart';

enum GameSurfaceTone { base, raised, selected, gold, danger }

enum AhdashGlyph {
  home,
  play,
  teams,
  ranking,
  profile,
  classic,
  trueFalse,
  speed,
  ordering,
  club,
  eagle,
  premium,
}

final class AhdashGameWorld extends StatelessWidget {
  const AhdashGameWorld({required this.child, this.intensity = 1, super.key});

  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GameWorldPainter(
          background: colors.background,
          surface: colors.surface,
          line: colors.borderStrong,
          energy: colors.primary,
          sand: colors.sand,
          intensity: intensity,
        ),
        child: child,
      ),
    );
  }
}

final class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.child,
    this.tone = GameSurfaceTone.base,
    this.padding = const EdgeInsets.all(AppSpacing.sm),
    this.cut = 7,
    this.onTap,
    this.selected = false,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final GameSurfaceTone tone;
  final EdgeInsetsGeometry padding;
  final double cut;
  final VoidCallback? onTap;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final fill = switch (tone) {
      GameSurfaceTone.raised => colors.surfaceElevated,
      GameSurfaceTone.selected => colors.selected,
      GameSurfaceTone.gold => colors.gold.withValues(alpha: 0.1),
      GameSurfaceTone.danger => colors.error.withValues(alpha: 0.08),
      GameSurfaceTone.base => Colors.transparent,
    };
    final stroke = selected || tone == GameSurfaceTone.selected
        ? colors.primary
        : tone == GameSurfaceTone.gold
        ? colors.gold
        : tone == GameSurfaceTone.danger
        ? colors.error
        : colors.border;
    final content = CustomPaint(
      painter: _CutPanelPainter(
        fill: fill,
        stroke: stroke,
        accent: selected ? colors.primary : Colors.transparent,
        cut: cut,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: _Pressable(onTap: onTap!, child: content),
    );
  }
}

final class AhdashIcon extends StatelessWidget {
  const AhdashIcon(
    this.glyph, {
    this.size = 24,
    this.color,
    this.active = false,
    super.key,
  });

  final AhdashGlyph glyph;
  final double size;
  final Color? color;
  final bool active;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _GlyphPainter(
      glyph: glyph,
      color: color ?? context.ahdashColors.textMuted,
      active: active,
    ),
  );
}

final class GameHud extends StatelessWidget {
  const GameHud({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 2);
    return SizedBox(
      height: 42 + ((textScale - 1) * 18),
      child: GamePanel(
        cut: 10,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(children: children),
      ),
    );
  }
}

final class AccessibilityViewport extends StatelessWidget {
  const AccessibilityViewport({
    required this.child,
    this.minimumAccessibleHeight = 560,
    super.key,
  });

  final Widget child;
  final double minimumAccessibleHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context);
      if (media.textScaler.scale(1) <= 1.28 && media.viewInsets.bottom == 0) {
        return child;
      }
      return SingleChildScrollView(
        child: SizedBox(
          width: constraints.maxWidth,
          height: math.max(constraints.maxHeight, minimumAccessibleHeight),
          child: child,
        ),
      );
    },
  );
}

final class CompactSectionTitle extends StatelessWidget {
  const CompactSectionTitle({
    required this.title,
    this.eyebrow,
    this.trailing,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 3, height: 28, color: context.ahdashColors.primary),
      const SizedBox(width: 3),
      Container(width: 1, height: 28, color: context.ahdashColors.textPrimary),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null)
              Text(
                eyebrow!,
                style: TextStyle(
                  color: context.ahdashColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

final class ElevenLoader extends StatefulWidget {
  const ElevenLoader({this.size = 32, super.key});

  final double size;

  @override
  State<ElevenLoader> createState() => _ElevenLoaderState();
}

/// A fixed-height, swipeable collection for game screens that must not grow
/// vertically. It keeps every item reachable through explicit pages.
final class GamePagedList<T> extends StatefulWidget {
  const GamePagedList({
    required this.items,
    required this.itemBuilder,
    this.pageSize = 4,
    this.columns = 1,
    this.aspectRatio = 3,
    this.empty,
    super.key,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final int columns;
  final double aspectRatio;
  final Widget? empty;

  @override
  State<GamePagedList<T>> createState() => _GamePagedListState<T>();
}

final class _GamePagedListState<T> extends State<GamePagedList<T>> {
  final _controller = PageController();
  var _page = 0;

  int get _pageCount =>
      math.max(1, (widget.items.length / widget.pageSize).ceil());

  @override
  void didUpdateWidget(covariant GamePagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= _pageCount) {
      _page = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return widget.empty ?? const SizedBox.shrink();
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: _pageCount,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, page) {
              final start = page * widget.pageSize;
              final end = math.min(
                start + widget.pageSize,
                widget.items.length,
              );
              final slice = widget.items.sublist(start, end);
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: slice.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.columns,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: widget.aspectRatio,
                ),
                itemBuilder: (context, index) =>
                    widget.itemBuilder(context, slice[index], start + index),
              );
            },
          ),
        ),
        if (_pageCount > 1)
          SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'السابق',
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  onPressed: _page == 0
                      ? null
                      : () => _controller.previousPage(
                          duration: AppMotion.fast,
                          curve: Curves.easeOut,
                        ),
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                ),
                Text(
                  '${_page + 1} / $_pageCount',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  tooltip: 'التالي',
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  onPressed: _page == _pageCount - 1
                      ? null
                      : () => _controller.nextPage(
                          duration: AppMotion.fast,
                          curve: Curves.easeOut,
                        ),
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

final class _ElevenLoaderState extends State<ElevenLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.loadingPulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return AhdashBrandLogo.mark(height: widget.size);
    }
    return FadeTransition(
      opacity: Tween(begin: 0.42, end: 1.0).animate(_controller),
      child: AhdashBrandLogo.mark(height: widget.size),
    );
  }
}

final class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

final class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScale : 1,
        duration: AppMotion.micro,
        child: widget.child,
      ),
    ),
  );
}

final class _GameWorldPainter extends CustomPainter {
  const _GameWorldPainter({
    required this.background,
    required this.surface,
    required this.line,
    required this.energy,
    required this.sand,
    required this.intensity,
  });

  final Color background;
  final Color surface;
  final Color line;
  final Color energy;
  final Color sand;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = background);
    final pitch = Paint()
      ..color = line.withValues(alpha: 0.32 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final inset = math.max(14.0, size.shortestSide * 0.055);
    final field = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawRect(field, pitch);
    canvas.drawLine(
      Offset(size.width * 0.5, field.top),
      Offset(size.width * 0.5, field.bottom),
      pitch,
    );
    for (var i = 0; i < 2; i++) {
      final x = size.width * (0.48 + i * 0.035);
      canvas.drawLine(
        Offset(x, field.top),
        Offset(x, field.bottom),
        Paint()
          ..color = (i == 0 ? line : sand).withValues(alpha: 0.18 * intensity)
          ..strokeWidth = 1,
      );
    }
    final motif = Paint()
      ..color = energy.withValues(alpha: 0.055 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final unit = math.min(44.0, size.shortestSide * 0.1);
    for (final origin in [
      Offset(size.width * 0.08, size.height * 0.2),
      Offset(size.width * 0.86, size.height * 0.72),
    ]) {
      canvas.drawLine(origin, origin + Offset(0, unit), motif);
      canvas.drawLine(
        origin + Offset(unit * 0.35, 0),
        origin + Offset(unit * 0.35, unit),
        motif,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GameWorldPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.line != line ||
      oldDelegate.intensity != intensity;
}

final class _CutPanelPainter extends CustomPainter {
  const _CutPanelPainter({
    required this.fill,
    required this.stroke,
    required this.accent,
    required this.cut,
  });
  final Color fill;
  final Color stroke;
  final Color accent;
  final double cut;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cut)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (accent.a > 0) {
      canvas.drawLine(
        Offset(size.width - cut - 28, size.height),
        Offset(size.width - cut, size.height),
        Paint()
          ..color = accent
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CutPanelPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.stroke != stroke ||
      oldDelegate.accent != accent ||
      oldDelegate.cut != cut;
}

final class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({
    required this.glyph,
    required this.color,
    required this.active,
  });
  final AhdashGlyph glyph;
  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 2.2 : 1.7
      ..strokeJoin = StrokeJoin.miter;
    final w = size.width;
    final h = size.height;
    switch (glyph) {
      case AhdashGlyph.home:
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.16, h * 0.48)
            ..lineTo(w * 0.5, h * 0.18)
            ..lineTo(w * 0.84, h * 0.48)
            ..lineTo(w * 0.76, h * 0.48)
            ..lineTo(w * 0.76, h * 0.82)
            ..lineTo(w * 0.24, h * 0.82)
            ..lineTo(w * 0.24, h * 0.48)
            ..close(),
          p,
        );
      case AhdashGlyph.play:
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.32, h * 0.2)
            ..lineTo(w * 0.78, h * 0.5)
            ..lineTo(w * 0.32, h * 0.8)
            ..close(),
          p,
        );
      case AhdashGlyph.teams:
        canvas.drawCircle(Offset(w * 0.38, h * 0.36), w * 0.14, p);
        canvas.drawCircle(Offset(w * 0.66, h * 0.4), w * 0.11, p);
        canvas.drawArc(
          Rect.fromLTWH(w * 0.14, h * 0.45, w * 0.5, h * 0.38),
          math.pi,
          math.pi,
          false,
          p,
        );
      case AhdashGlyph.ranking:
        canvas.drawLine(
          Offset(w * 0.2, h * 0.82),
          Offset(w * 0.2, h * 0.58),
          p,
        );
        canvas.drawLine(
          Offset(w * 0.5, h * 0.82),
          Offset(w * 0.5, h * 0.28),
          p,
        );
        canvas.drawLine(
          Offset(w * 0.8, h * 0.82),
          Offset(w * 0.8, h * 0.44),
          p,
        );
      case AhdashGlyph.profile:
        canvas.drawCircle(Offset(w * 0.5, h * 0.34), w * 0.17, p);
        canvas.drawArc(
          Rect.fromLTWH(w * 0.2, h * 0.48, w * 0.6, h * 0.36),
          math.pi,
          math.pi,
          false,
          p,
        );
      case AhdashGlyph.trueFalse:
        canvas.drawLine(
          Offset(w * 0.18, h * 0.5),
          Offset(w * 0.38, h * 0.7),
          p,
        );
        canvas.drawLine(
          Offset(w * 0.38, h * 0.7),
          Offset(w * 0.72, h * 0.28),
          p,
        );
      case AhdashGlyph.speed:
        canvas.drawArc(
          Rect.fromLTWH(w * 0.16, h * 0.2, w * 0.68, h * 0.68),
          math.pi,
          math.pi,
          false,
          p,
        );
        canvas.drawLine(
          Offset(w * 0.5, h * 0.54),
          Offset(w * 0.72, h * 0.34),
          p,
        );
      case AhdashGlyph.ordering:
        for (var i = 0; i < 3; i++) {
          final y = h * (0.28 + i * 0.23);
          canvas.drawLine(Offset(w * 0.24, y), Offset(w * 0.78, y), p);
        }
      case AhdashGlyph.club:
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.5, h * 0.12)
            ..lineTo(w * 0.82, h * 0.3)
            ..lineTo(w * 0.72, h * 0.76)
            ..lineTo(w * 0.5, h * 0.9)
            ..lineTo(w * 0.28, h * 0.76)
            ..lineTo(w * 0.18, h * 0.3)
            ..close(),
          p,
        );
      case AhdashGlyph.eagle:
        canvas.drawArc(
          Rect.fromLTWH(w * 0.12, h * 0.28, w * 0.76, h * 0.44),
          math.pi,
          math.pi,
          false,
          p,
        );
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.1, p);
      case AhdashGlyph.premium:
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.16, h * 0.34)
            ..lineTo(w * 0.34, h * 0.54)
            ..lineTo(w * 0.5, h * 0.22)
            ..lineTo(w * 0.66, h * 0.54)
            ..lineTo(w * 0.84, h * 0.34)
            ..lineTo(w * 0.74, h * 0.8)
            ..lineTo(w * 0.26, h * 0.8)
            ..close(),
          p,
        );
      case AhdashGlyph.classic:
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.3, p);
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.5, h * 0.32)
            ..lineTo(w * 0.65, h * 0.44)
            ..lineTo(w * 0.59, h * 0.62)
            ..lineTo(w * 0.41, h * 0.62)
            ..lineTo(w * 0.35, h * 0.44)
            ..close(),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.active != active;
}
