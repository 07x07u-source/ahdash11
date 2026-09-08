import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'components.dart';

final class AhdashPageBackground extends StatelessWidget {
  const AhdashPageBackground({
    required this.asset,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.scrimStrength = 0.68,
    this.fit = BoxFit.cover,
    this.imageUrl,
    super.key,
  });

  final String asset;
  final Widget child;
  final Alignment alignment;
  final double scrimStrength;
  final BoxFit fit;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.ahdashColors;
    final topAlpha = dark ? scrimStrength * 0.45 : scrimStrength * 0.26;
    final bottomAlpha = dark ? scrimStrength : scrimStrength * 0.72;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: imageUrl == null
              ? Image.asset(
                  asset,
                  fit: fit,
                  alignment: alignment,
                  cacheWidth: 1080,
                  filterQuality: FilterQuality.medium,
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: fit,
                  alignment: alignment,
                  memCacheWidth: 1080,
                  placeholder: (_, _) => Image.asset(asset, fit: fit),
                  errorWidget: (_, _, _) => Image.asset(asset, fit: fit),
                ),
        ),
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.35, 0.72, 1],
                colors: [
                  colors.background.withValues(alpha: topAlpha),
                  colors.background.withValues(alpha: scrimStrength * 0.52),
                  colors.background.withValues(alpha: bottomAlpha),
                  colors.background,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

final class AhdashHeroArtwork extends StatelessWidget {
  const AhdashHeroArtwork({
    required this.asset,
    required this.child,
    this.semanticLabel,
    this.aspectRatio = 1.35,
    this.alignment = Alignment.center,
    this.foreground,
    this.onTap,
    this.imageUrl,
    super.key,
  });

  final String asset;
  final Widget child;
  final String? semanticLabel;
  final double aspectRatio;
  final Alignment alignment;
  final Widget? foreground;
  final VoidCallback? onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final content = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: imageUrl == null
                  ? Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      alignment: alignment,
                      cacheWidth: 1080,
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      alignment: alignment,
                      memCacheWidth: 1080,
                      placeholder: (_, _) =>
                          Image.asset(asset, fit: BoxFit.cover),
                      errorWidget: (_, _, _) =>
                          Image.asset(asset, fit: BoxFit.cover),
                    ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x120B0F14), Color(0xE80B0F14)],
                  stops: [0.28, 1],
                ),
              ),
            ),
            if (foreground != null) ExcludeSemantics(child: foreground!),
            Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
          ],
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.hero),
          border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: onTap == null
            ? content
            : AhdashPressable(
                onTap: onTap!,
                borderRadius: BorderRadius.circular(AppRadius.hero),
                child: content,
              ),
      ),
    );
  }
}

final class AhdashImageTile extends StatelessWidget {
  const AhdashImageTile({
    required this.asset,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
    this.height = 218,
    this.imageAlignment = Alignment.center,
    this.enabled = true,
    this.imageUrl,
    super.key,
  });

  final String asset;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;
  final double height;
  final Alignment imageAlignment;
  final bool enabled;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    final active = enabled && onTap != null;
    final tile = SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: imageUrl == null
                  ? Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      alignment: imageAlignment,
                      cacheWidth: 720,
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      alignment: imageAlignment,
                      memCacheWidth: 720,
                      placeholder: (_, _) =>
                          Image.asset(asset, fit: BoxFit.cover),
                      errorWidget: (_, _, _) =>
                          Image.asset(asset, fit: BoxFit.cover),
                    ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 0.72, 1],
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.58),
                    AppColors.background.withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: AppSpacing.md,
              end: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badge case final value?) ...[
                    AhdashBadge(
                      label: value,
                      color: active ? colors.primary : colors.sand,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFD5DAE1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: active,
      enabled: active,
      label: '$title، $subtitle${active ? '' : '، قريبًا'}',
      child: Opacity(
        opacity: enabled ? 1 : 0.62,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: colors.borderStrong),
          ),
          child: active
              ? AhdashPressable(
                  onTap: onTap!,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  child: tile,
                )
              : tile,
        ),
      ),
    );
  }
}

final class AhdashImageEmptyState extends StatelessWidget {
  const AhdashImageEmptyState({
    required this.asset,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String asset;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title، $message',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.large),
              child: Image.asset(
                asset,
                width: 220,
                height: 180,
                fit: BoxFit.cover,
                cacheWidth: 440,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
