import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/content/domain/app_content.dart';
import '../../features/content/presentation/app_content_controller.dart';

enum AhdashLogoVariant { lockup, mark }

/// Canonical logo renderer. Branding Center is authoritative when it has a
/// published asset; the original brand-package PNG is the offline fallback.
final class AhdashBrandLogo extends ConsumerWidget {
  const AhdashBrandLogo({
    this.variant = AhdashLogoVariant.lockup,
    this.width,
    this.height = 48,
    this.onDarkSurface,
    this.semanticLabel = 'أحدعش | 11',
    super.key,
  });

  const AhdashBrandLogo.mark({
    this.width,
    this.height = 44,
    this.onDarkSurface,
    this.semanticLabel = 'شعار أحدعش',
    super.key,
  }) : variant = AhdashLogoVariant.mark;

  final AhdashLogoVariant variant;
  final double? width;
  final double height;
  final bool? onDarkSurface;
  final String semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content =
        ref.watch(appContentProvider).value ?? AppContentBundle.defaults;
    final dark =
        onDarkSurface ?? Theme.of(context).brightness == Brightness.dark;
    final key = variant == AhdashLogoVariant.mark
        ? AppContentKeys.brandingLogoMark
        : dark
        ? AppContentKeys.brandingLogoDark
        : AppContentKeys.brandingLogoPrimary;
    final preferredRemote = content.imageUrl(key);
    final remote =
        preferredRemote ??
        (variant == AhdashLogoVariant.lockup
            ? content.imageUrl(AppContentKeys.brandingLogoPrimary)
            : null);
    final fallback = variant == AhdashLogoVariant.mark
        ? 'assets/branding/logo-symbol.png'
        : 'assets/branding/logo-horizontal.png';
    final image = remote == null
        ? Image.asset(
            fallback,
            fit: BoxFit.contain,
            semanticLabel: semanticLabel,
            cacheHeight: (height * MediaQuery.devicePixelRatioOf(context))
                .ceil(),
          )
        : CachedNetworkImage(
            imageUrl: remote,
            fit: BoxFit.contain,
            fadeInDuration: AppMotion.imageFade,
            errorWidget: (_, _, _) => Image.asset(
              fallback,
              fit: BoxFit.contain,
              semanticLabel: semanticLabel,
            ),
          );
    final logo = SizedBox(width: width, height: height, child: image);
    final hasDarkLockup =
        dark && variant == AhdashLogoVariant.lockup && preferredRemote != null;
    if (!dark || hasDarkLockup) {
      return logo;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AhdashColors.light.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: logo,
      ),
    );
  }
}

final class EditorialKicker extends StatelessWidget {
  const EditorialKicker(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 3, height: 13, color: context.ahdashColors.primary),
      const SizedBox(width: 3),
      Container(width: 1, height: 13, color: context.ahdashColors.textPrimary),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color: context.ahdashColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
