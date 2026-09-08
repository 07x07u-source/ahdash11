import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_preferences.dart';
import '../../core/theme/app_colors.dart';

Color ahdashHexColor(String? value, {Color fallback = AppColors.primary}) {
  final clean = value?.replaceFirst('#', '');
  if (clean == null || !RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(clean)) {
    return fallback;
  }
  return Color(int.parse('FF$clean', radix: 16));
}

final class AhdashClubBadge extends StatelessWidget {
  const AhdashClubBadge({
    required this.label,
    this.colorHex,
    this.logoUrl,
    this.size = 46,
    super.key,
  });

  final String label;
  final String? colorHex;
  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = ahdashHexColor(colorHex);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [color, color.withValues(alpha: 0.58)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label.characters.take(3).toString().toUpperCase(),
        maxLines: 1,
        style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
              ? Colors.white
              : const Color(0xFF101500),
          fontSize: size * 0.26,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    if (logoUrl == null || logoUrl!.isEmpty) return fallback;
    return Semantics(
      image: true,
      label: 'شعار مرخّص أو مخصص',
      child: CachedNetworkImage(
        imageUrl: logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: (_, _, _) => fallback,
        placeholder: (_, _) => fallback,
      ),
    );
  }
}

final class AhdashPlayer11Avatar extends ConsumerWidget {
  const AhdashPlayer11Avatar({
    this.imageUrl,
    this.jerseyColorHex,
    this.size = 76,
    this.heroTag,
    this.variant,
    super.key,
  });

  final String? imageUrl;
  final String? jerseyColorHex;
  final double size;
  final Object? heroTag;
  final Player11Variant? variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jersey = ahdashHexColor(jerseyColorHex);
    final selectedVariant =
        variant ??
        ref.watch(appPreferencesProvider).value?.player11Variant ??
        Player11Variant.male;
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.ahdashColors.surfaceElevated,
            jersey.withValues(alpha: 0.42),
          ],
        ),
        border: Border.all(color: jersey, width: math.max(2, size * 0.035)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Image.asset(
              selectedVariant.assetPath,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.78),
              filterQuality: FilterQuality.medium,
              cacheWidth: math.min(
                512,
                math.max(
                  96,
                  (size * MediaQuery.devicePixelRatioOf(context) * 2).ceil(),
                ),
              ),
              errorBuilder: (_, _, _) => Icon(
                Icons.sports_soccer_rounded,
                size: size * 0.52,
                color: jersey,
              ),
            )
          : CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) =>
                  Icon(Icons.person_rounded, size: size * 0.56),
            ),
    );
    avatar = Semantics(
      image: true,
      label: 'هوية ${selectedVariant.labelAr}',
      child: avatar,
    );
    return heroTag == null ? avatar : Hero(tag: heroTag!, child: avatar);
  }
}

final class AhdashPlayerCard extends StatelessWidget {
  const AhdashPlayerCard({
    required this.displayName,
    this.avatarUrl,
    this.jerseyColorHex,
    this.username,
    this.level,
    this.clubPreference,
    this.teamStatus,
    this.subtitle,
    this.rank,
    this.scoreLabel,
    this.trailing,
    this.onTap,
    this.carded = true,
    this.highlighted = false,
    super.key,
  });

  final String displayName;
  final String? avatarUrl;
  final String? jerseyColorHex;
  final String? username;
  final int? level;
  final String? clubPreference;
  final String? teamStatus;
  final String? subtitle;
  final int? rank;
  final String? scoreLabel;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool carded;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final fallbackDetails = <String>[
      if (username != null && username!.isNotEmpty) '@$username',
      if (level != null) 'مستوى $level',
      if (clubPreference != null && clubPreference!.isNotEmpty) clubPreference!,
      if (teamStatus != null && teamStatus!.isNotEmpty) teamStatus!,
    ];
    final detailText = subtitle ?? fallbackDetails.join(' • ');
    final leadingWidth = rank == null ? 48.0 : 76.0;

    final tile = ListTile(
      onTap: onTap,
      minVerticalPadding: 10,
      leading: SizedBox(
        width: leadingWidth,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rank case final value?) ...[
              SizedBox(
                width: 26,
                child: Text(
                  '#$value',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 4),
            ],
            AhdashPlayer11Avatar(
              imageUrl: avatarUrl,
              jerseyColorHex: jerseyColorHex,
              size: 44,
            ),
          ],
        ),
      ),
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: detailText.isEmpty
          ? null
          : Text(detailText, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing:
          trailing ??
          (scoreLabel == null
              ? null
              : Text(
                  scoreLabel!,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                )),
    );
    final surface = !carded
        ? tile
        : Card(
            color: highlighted ? context.ahdashColors.selected : null,
            clipBehavior: Clip.antiAlias,
            child: tile,
          );
    return Semantics(
      container: true,
      label: [
        displayName,
        if (detailText.isNotEmpty) detailText,
        if (rank != null) 'الترتيب $rank',
        if (scoreLabel != null) 'النقاط $scoreLabel',
      ].join('، '),
      child: surface,
    );
  }
}

final class SaudiPatternBackdrop extends StatelessWidget {
  const SaudiPatternBackdrop({required this.child, this.color, super.key});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SaudiPatternPainter(color ?? context.ahdashColors.primary),
      child: child,
    );
  }
}

final class _SaudiPatternPainter extends CustomPainter {
  const _SaudiPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.085)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const step = 26.0;
    for (double x = -step; x < size.width + step; x += step) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + step / 2, step / 2)
        ..lineTo(x, step)
        ..lineTo(x - step / 2, step / 2)
        ..close();
      for (double y = 0; y < size.height + step; y += step) {
        canvas.save();
        canvas.translate(0, y);
        canvas.drawPath(path, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SaudiPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
