import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

final class AhdashImage extends StatelessWidget {
  const AhdashImage({
    required this.aspectRatio,
    this.imageUrl,
    this.fallbackAsset,
    this.fallbackWidget,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius = AppRadius.medium,
    this.semanticLabel,
    this.overlay,
    super.key,
  }) : assert(
         imageUrl != null || fallbackAsset != null || fallbackWidget != null,
       );

  final String? imageUrl;
  final String? fallbackAsset;
  final Widget? fallbackWidget;
  final double aspectRatio;
  final BoxFit fit;
  final Alignment alignment;
  final double borderRadius;
  final String? semanticLabel;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pixelRatio = MediaQuery.devicePixelRatioOf(context);
            final cacheWidth = (constraints.maxWidth * pixelRatio).round();
            final cacheHeight = (constraints.maxHeight * pixelRatio).round();
            final localImageUrl = imageUrl?.startsWith('assets/') == true;
            final fallback =
                fallbackWidget ??
                (fallbackAsset == null
                    ? _ImageError(color: colors.textMuted)
                    : Image.asset(
                        fallbackAsset!,
                        fit: fit,
                        alignment: alignment,
                        cacheWidth: cacheWidth,
                        cacheHeight: cacheHeight,
                        semanticLabel: semanticLabel,
                      ));
            final image = imageUrl == null
                ? fallback
                : localImageUrl
                ? Image.asset(
                    imageUrl!,
                    fit: fit,
                    alignment: alignment,
                    cacheWidth: cacheWidth,
                    cacheHeight: cacheHeight,
                    semanticLabel: semanticLabel,
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: fit,
                    alignment: alignment,
                    memCacheWidth: cacheWidth,
                    memCacheHeight: cacheHeight,
                    fadeInDuration: AppMotion.imageFade,
                    placeholder: (_, _) =>
                        _ImagePlaceholder(color: colors.surfaceMuted),
                    errorWidget: (_, _, _) => fallback,
                  );
            return Stack(fit: StackFit.expand, children: [image, ?overlay]);
          },
        ),
      ),
    );
  }
}

final class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: const Center(child: Icon(Icons.sports_soccer_rounded, size: 28)),
    );
  }
}

final class _ImageError extends StatelessWidget {
  const _ImageError({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.ahdashColors.surfaceMuted,
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: color),
      ),
    );
  }
}
