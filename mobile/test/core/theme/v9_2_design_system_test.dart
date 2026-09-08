import 'package:ahdash_11/core/theme/app_colors.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/core/theme/app_typography.dart';
import 'package:ahdash_11/shared/presentation/measured_v9.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V9.2 light tokens match the approved handoff', () {
    expect(AppColors.paper0, const Color(0xFFFBF7EF));
    expect(AppColors.paper1, const Color(0xFFF4EBDD));
    expect(AppColors.paper2, const Color(0xFFEBDFC9));
    expect(AppColors.paper3, const Color(0xFFDDCEB5));
    expect(AppColors.ink, const Color(0xFF191714));
    expect(AppColors.hairline, const Color(0xFFD3C6B2));
    expect(AhdashColors.light.primary, const Color(0xFFB6FF3B));
    expect(AhdashColors.light.teamA, const Color(0xFFE84B8A));
    expect(AhdashColors.light.teamB, const Color(0xFF4B8DE8));
  });

  test('V9.2 spacing, radii, sizing, motion, and type stay bounded', () {
    expect(
      [
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.huge,
        AppSpacing.max,
      ],
      [4, 8, 12, 16, 20, 24, 32, 40, 48, 64],
    );
    expect([AppRadius.small, AppRadius.medium, AppRadius.large], [8, 12, 16]);
    expect(AhdashSizing.minimumTouchTarget, greaterThanOrEqualTo(44));
    expect(AppMotion.standard.inMilliseconds, inInclusiveRange(180, 240));
    expect(AppMotion.selection.inMilliseconds, inInclusiveRange(140, 180));
    expect(AppMotion.reveal.inMilliseconds, inInclusiveRange(250, 400));
    expect(AppMotion.celebration.inMilliseconds, inInclusiveRange(500, 900));
    expect(AhdashTypography.display.fontSize, inInclusiveRange(30, 40));
    expect(AhdashTypography.score.fontSize, inInclusiveRange(32, 48));
  });

  test('canonical V9.2 theme is light and carries the palette extension', () {
    final theme = AhdashTheme.light;
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppColors.paper0);
    expect(theme.extension<AhdashColors>(), AhdashColors.light);
    expect(theme.textTheme.bodyMedium?.fontFamily, AppTypography.bodyFamily);
  });

  test('responsive metrics switch composition instead of global scaling', () {
    final wide = AhdashV9Metrics.fromSize(const Size(1366, 768));
    final compact = AhdashV9Metrics.fromSize(const Size(844, 390));
    final portrait = AhdashV9Metrics.fromSize(const Size(390, 844));

    expect(wide.wide, isTrue);
    expect(wide.compact, isFalse);
    expect(compact.compact, isTrue);
    expect(compact.wide, isFalse);
    expect(portrait.portrait, isTrue);
    expect(portrait.compact, isTrue);
    expect(compact.primaryActionHeight, 48);
    expect(wide.primaryActionHeight, 52);
    expect(compact.gutter, lessThan(wide.gutter));
  });
}
