import 'package:ahdash_11/core/l10n/app_localizations.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget testApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (_, body) =>
        RepaintBoundary(key: const ValueKey('test-app-boundary'), child: body!),
    theme: theme ?? AppTheme.dark,
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}
