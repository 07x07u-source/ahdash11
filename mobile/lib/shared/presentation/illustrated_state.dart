import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Quiet, card-free state layout. Text grows naturally and the entire message
/// remains scrollable on short viewports or with accessibility text scaling.
final class AhdashIllustratedState extends StatelessWidget {
  const AhdashIllustratedState({
    required this.asset,
    required this.title,
    required this.message,
    this.note,
    this.action,
    super.key,
  });

  final String asset;
  final String title;
  final String message;
  final String? note;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.hasBoundedHeight
              ? (constraints.maxHeight - 40).clamp(0, double.infinity)
              : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              asset,
              key: ValueKey(asset),
              width: 204,
              height: 136,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
            const SizedBox(height: 22),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 14,
                  height: 1.65,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.palm,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      note!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.palm,
                        fontSize: 11.5,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: SizedBox(width: double.infinity, child: action),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
