import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const screen = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
  static const huge = 48.0;
  static const max = 64.0;
}

abstract final class AppRadius {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const hero = 16.0;
  static const pill = 999.0;
}

/// Size contract shared by Material component themes and responsive widgets.
abstract final class AhdashSizing {
  static const minimumTouchTarget = 44.0;
  static const touchTarget = 48.0;
  static const primaryActionCompact = 48.0;
  static const primaryActionWide = 52.0;
  static const secondaryActionCompact = 46.0;
  static const secondaryActionWide = 48.0;
  static const inputCompact = 48.0;
  static const inputWide = 52.0;
  static const utilityGlyphCompact = 20.0;
  static const utilityGlyphWide = 22.0;
}

abstract final class AppMotion {
  static const micro = Duration(milliseconds: 100);
  static const fast = micro;
  static const standard = Duration(milliseconds: 200);
  static const emphasized = Duration(milliseconds: 320);
  static const deliberate = emphasized;
  static const launch = Duration(milliseconds: 520);
  static const selection = Duration(milliseconds: 160);
  static const reveal = Duration(milliseconds: 320);
  static const score = Duration(milliseconds: 320);
  static const celebration = Duration(milliseconds: 700);
  static const imageFade = Duration(milliseconds: 180);
  static const loadingPulse = Duration(milliseconds: 850);
  static const feedbackHold = Duration(milliseconds: 1250);
  static const connectivityNotice = Duration(milliseconds: 1600);
  static const networkPoll = Duration(milliseconds: 700);
  static const staggerStep = Duration(milliseconds: 45);
  static const pressScale = 0.975;
  static const curve = Curves.easeOutCubic;
  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;
  static const springCurve = Curves.easeOutBack;
}

/// Public motion contract used by product surfaces and golden tests.
abstract final class AhdashMotionTokens {
  static const micro = AppMotion.micro;
  static const standard = AppMotion.standard;
  static const emphasized = AppMotion.emphasized;
  static const celebration = AppMotion.celebration;
  static const pressScale = AppMotion.pressScale;
  static const curve = AppMotion.curve;
}

abstract final class AppOpacity {
  static const subtle = 0.08;
  static const soft = 0.12;
  static const disabled = 0.45;
  static const navigationSolid = 0.96;
  static const navigationGlass = 0.72;
}

abstract final class AppBlur {
  static const navigation = 14.0;
}

abstract final class AppElevation {
  static const card = 1.0;
  static const raisedCard = 2.0;
  static const navigationBlur = 22.0;
  static const navigationOffset = 8.0;
}

abstract final class AppTheme {
  static ThemeData get dark =>
      _build(brightness: Brightness.dark, palette: AhdashColors.dark);

  static ThemeData get light =>
      _build(brightness: Brightness.light, palette: AhdashColors.light);

  static ThemeData _build({
    required Brightness brightness,
    required AhdashColors palette,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.primaryForeground,
      secondary: palette.gold,
      onSecondary: palette.primaryForeground,
      error: palette.error,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainerLowest: palette.background,
      surfaceContainerLow: palette.surfaceMuted,
      surfaceContainer: palette.surface,
      surfaceContainerHigh: palette.surfaceElevated,
      surfaceContainerHighest: palette.surfaceElevated,
      onSurfaceVariant: palette.textMuted,
      outline: palette.border,
      outlineVariant: palette.borderStrong,
      shadow: const Color(0x33000000),
      scrim: const Color(0x99000000),
      inverseSurface: palette.textPrimary,
      onInverseSurface: palette.background,
      inversePrimary: AppColors.primary,
    );
    const baseText = AppTypography.theme;
    final overlay = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: palette.background,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: palette.background,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      fontFamily: AppTypography.bodyFamily,
      fontFamilyFallback: const ['Noto Sans Arabic', 'sans-serif'],
      textTheme: baseText.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.compact,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        systemOverlayStyle: overlay,
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: palette.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: palette.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.primaryForeground,
          disabledBackgroundColor: palette.disabled.withValues(alpha: 0.32),
          disabledForegroundColor: palette.textMuted,
          minimumSize: const Size(0, AhdashSizing.primaryActionCompact),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: baseText.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AhdashSizing.secondaryActionCompact),
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: baseText.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size(
            AhdashSizing.minimumTouchTarget,
            AhdashSizing.minimumTouchTarget,
          ),
          textStyle: baseText.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: TextStyle(color: palette.textMuted),
        hintStyle: TextStyle(color: palette.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        constraints: const BoxConstraints(minHeight: AhdashSizing.inputCompact),
      ),
      iconTheme: IconThemeData(color: palette.textPrimary, size: 21),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AhdashSizing.minimumTouchTarget),
          iconSize: AhdashSizing.utilityGlyphWide,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: palette.borderStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(palette.primaryForeground),
      ),
      radioTheme: RadioThemeData(
        visualDensity: VisualDensity.compact,
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primary
              : palette.textMuted,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: palette.selected,
        disabledColor: palette.surfaceMuted,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: baseText.labelMedium?.copyWith(color: palette.textPrimary),
        secondaryLabelStyle: baseText.labelMedium?.copyWith(
          color: palette.textPrimary,
        ),
        checkmarkColor: palette.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      dividerColor: palette.border,
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.textPrimary,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle: baseText.labelMedium?.copyWith(color: palette.background),
        waitDuration: const Duration(milliseconds: 450),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.textPrimary,
        contentTextStyle: baseText.bodyMedium?.copyWith(
          color: palette.background,
        ),
        actionTextColor: palette.primary,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: palette.border),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primaryForeground
              : palette.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primary
              : palette.surfaceMuted,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 42)),
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? palette.selected
                : Colors.transparent,
          ),
          foregroundColor: WidgetStatePropertyAll(palette.textPrimary),
          side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          textStyle: WidgetStatePropertyAll(baseText.labelMedium),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.textPrimary,
        unselectedLabelColor: palette.textMuted,
        labelStyle: baseText.labelLarge,
        unselectedLabelStyle: baseText.labelMedium,
        indicatorColor: palette.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: palette.border,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.surfaceMuted,
        circularTrackColor: palette.surfaceMuted,
      ),
    );
  }
}

/// Canonical V9.2 theme entry point. The legacy dark theme remains available
/// through [AppTheme.dark] for old previews, but is not exposed by the app.
abstract final class AhdashTheme {
  static ThemeData get light => AppTheme.light;
}
