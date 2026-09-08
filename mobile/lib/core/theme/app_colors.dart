import 'package:flutter/material.dart';

abstract final class AppColors {
  // V9.2 light product palette. Keep these names aligned with the Figma
  // handoff so product surfaces never need to repeat raw color literals.
  static const paper0 = Color(0xFFFBF7EF);
  static const paper1 = Color(0xFFF4EBDD);
  static const paper2 = Color(0xFFEBDFC9);
  static const paper3 = Color(0xFFDDCEB5);
  static const ink = Color(0xFF191714);
  static const inkSoft = Color(0xFF35312B);
  static const inkMuted = Color(0xFF756E63);
  static const hairline = Color(0xFFD3C6B2);
  static const teamPink = Color(0xFFE84B8A);
  static const teamBlue = Color(0xFF4B8DE8);

  static const background = Color(0xFF171613);
  static const surface = Color(0xFF211F1B);
  static const surfaceHigh = Color(0xFF292620);
  static const primary = Color(0xFFB6FF3B);
  static const brandLime = Color(0xFFB6FF3B);
  static const onPrimary = Color(0xFF171613);
  static const white = Color(0xFFF4EBDD);
  static const muted = Color(0xFFA79D90);
  static const danger = Color(0xFFFF4D57);
  static const gold = Color(0xFFFFC857);
  static const success = Color(0xFF78A91B);
  static const warning = Color(0xFFFFA94D);
  static const outline = Color(0xFF3B372F);
  static const sand = Color(0xFFD7C6AC);
  static const najdiClay = Color(0xFFB66B4D);
  static const palm = Color(0xFF1F654C);
  static const coffee = Color(0xFF6B4632);
}

@immutable
final class AhdashColors extends ThemeExtension<AhdashColors> {
  const AhdashColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.primaryForeground,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.gold,
    required this.selected,
    required this.disabled,
    required this.sand,
    required this.clay,
    required this.palm,
    required this.coffee,
    required this.dangerTimer,
    required this.teamA,
    required this.teamB,
    required this.focus,
  });

  static const dark = AhdashColors(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceHigh,
    surfaceMuted: Color(0xFF342F28),
    textPrimary: AppColors.white,
    textSecondary: Color(0xFFDED3C2),
    textMuted: Color(0xFFAAA091),
    border: Color(0xFF4B453C),
    borderStrong: Color(0xFF675F52),
    primary: AppColors.primary,
    primaryForeground: AppColors.onPrimary,
    success: Color(0xFF78A91B),
    error: AppColors.danger,
    warning: AppColors.warning,
    info: Color(0xFF7EA0B8),
    gold: AppColors.gold,
    selected: Color(0xFF303821),
    disabled: Color(0xFF71695E),
    sand: AppColors.sand,
    clay: AppColors.najdiClay,
    palm: AppColors.palm,
    coffee: AppColors.coffee,
    dangerTimer: Color(0xFFFF6B55),
    teamA: Color(0xFF58A6FF),
    teamB: Color(0xFFFF7A9E),
    focus: Color(0xFFF4EBDD),
  );

  static const light = AhdashColors(
    background: AppColors.paper0,
    surface: AppColors.paper1,
    surfaceElevated: AppColors.paper2,
    surfaceMuted: AppColors.paper3,
    textPrimary: AppColors.ink,
    textSecondary: AppColors.inkSoft,
    textMuted: Color(0xFF756E63),
    border: AppColors.hairline,
    borderStrong: Color(0xFFAA9A82),
    primary: Color(0xFFB6FF3B),
    primaryForeground: Color(0xFF191714),
    success: Color(0xFF527F0C),
    error: Color(0xFFC83443),
    warning: Color(0xFFAD6418),
    info: Color(0xFF356A86),
    gold: Color(0xFFFFC857),
    selected: Color(0xFFE9F5CF),
    disabled: Color(0xFFA89F93),
    sand: Color(0xFFD7C6AC),
    clay: Color(0xFF9D5B43),
    palm: Color(0xFF246B53),
    coffee: Color(0xFF6B4632),
    dangerTimer: Color(0xFFC83E31),
    teamA: AppColors.teamPink,
    teamB: AppColors.teamBlue,
    focus: Color(0xFF191714),
  );

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderStrong;
  final Color primary;
  final Color primaryForeground;
  final Color success;
  final Color error;
  final Color warning;
  final Color info;
  final Color gold;
  final Color selected;
  final Color disabled;
  final Color sand;
  final Color clay;
  final Color palm;
  final Color coffee;
  final Color dangerTimer;
  final Color teamA;
  final Color teamB;
  final Color focus;

  @override
  AhdashColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderStrong,
    Color? primary,
    Color? primaryForeground,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? gold,
    Color? selected,
    Color? disabled,
    Color? sand,
    Color? clay,
    Color? palm,
    Color? coffee,
    Color? dangerTimer,
    Color? teamA,
    Color? teamB,
    Color? focus,
  }) {
    return AhdashColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      gold: gold ?? this.gold,
      selected: selected ?? this.selected,
      disabled: disabled ?? this.disabled,
      sand: sand ?? this.sand,
      clay: clay ?? this.clay,
      palm: palm ?? this.palm,
      coffee: coffee ?? this.coffee,
      dangerTimer: dangerTimer ?? this.dangerTimer,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      focus: focus ?? this.focus,
    );
  }

  @override
  AhdashColors lerp(covariant AhdashColors? other, double t) {
    if (other == null) return this;
    return AhdashColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(
        primaryForeground,
        other.primaryForeground,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      clay: Color.lerp(clay, other.clay, t)!,
      palm: Color.lerp(palm, other.palm, t)!,
      coffee: Color.lerp(coffee, other.coffee, t)!,
      dangerTimer: Color.lerp(dangerTimer, other.dangerTimer, t)!,
      teamA: Color.lerp(teamA, other.teamA, t)!,
      teamB: Color.lerp(teamB, other.teamB, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
    );
  }
}

extension AhdashThemeContext on BuildContext {
  AhdashColors get ahdashColors =>
      Theme.of(this).extension<AhdashColors>() ?? AhdashColors.dark;
}
