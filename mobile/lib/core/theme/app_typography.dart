import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const displayFamily = 'ThmanyahSans';
  static const bodyFamily = 'ThmanyahSans';
  // Compatibility aliases for legacy call sites. V9.2 intentionally uses one
  // licensed family across every active product role.
  static const editorialDisplayFamily = displayFamily;
  static const editorialTextFamily = bodyFamily;

  static const displayXl = TextStyle(
    fontFamily: displayFamily,
    fontSize: 36,
    height: 1.16,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const brand = TextStyle(
    fontFamily: displayFamily,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w900,
  );

  static const screenTitle = TextStyle(
    fontFamily: displayFamily,
    fontSize: 28,
    height: 1.14,
    fontWeight: FontWeight.w900,
  );

  static const headline = TextStyle(
    fontFamily: displayFamily,
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w900,
  );

  static const sectionTitle = TextStyle(
    fontFamily: displayFamily,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w800,
  );

  static const display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 32,
    height: 1.2,
    fontWeight: FontWeight.w900,
  );

  static const section = TextStyle(
    fontFamily: displayFamily,
    fontSize: 20,
    height: 1.35,
    fontWeight: FontWeight.w900,
  );

  static const compactSection = TextStyle(
    fontFamily: displayFamily,
    fontSize: 18,
    height: 1.34,
    fontWeight: FontWeight.w800,
  );

  static const question = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 26,
    height: 1.34,
    fontWeight: FontWeight.w700,
  );

  static const answer = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 17,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  static const body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    height: 1.48,
    fontWeight: FontWeight.w500,
  );

  static const caption = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  static const metadata = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const button = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const score = TextStyle(
    fontFamily: displayFamily,
    fontSize: 40,
    height: 1.25,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const champion = TextStyle(
    fontFamily: editorialDisplayFamily,
    fontSize: 40,
    height: 1.2,
    fontWeight: FontWeight.w900,
  );

  static const editorial = TextStyle(
    fontFamily: editorialTextFamily,
    fontSize: 16,
    height: 1.55,
    fontWeight: FontWeight.w500,
  );

  static const label = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );

  static const theme = TextTheme(
    displaySmall: displayXl,
    headlineLarge: display,
    headlineMedium: section,
    headlineSmall: compactSection,
    titleLarge: compactSection,
    titleMedium: answer,
    titleSmall: label,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: label,
    labelMedium: caption,
    labelSmall: caption,
  );
}

/// Canonical V9.2 typography contract. `AppTypography` remains available for
/// compatibility with older presentation layers while screen migrations are
/// completed incrementally.
abstract final class AhdashTypography {
  static const brand = AppTypography.brand;
  static const display = AppTypography.displayXl;
  static const screenTitle = AppTypography.screenTitle;
  static const headline = AppTypography.headline;
  static const hero = AppTypography.display;
  static const sectionTitle = AppTypography.sectionTitle;
  static const question = AppTypography.question;
  static const body = AppTypography.body;
  static const label = AppTypography.label;
  static const caption = AppTypography.caption;
  static const score = AppTypography.score;
  static const teamName = TextStyle(
    fontFamily: AppTypography.displayFamily,
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w900,
  );
  static const metadata = AppTypography.metadata;
  static const button = AppTypography.button;
}
