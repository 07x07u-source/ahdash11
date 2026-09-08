import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final class AppLocalizations {
  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('ar'), Locale('en')];
  static const delegate = _AppLocalizationsDelegate();

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _values = <String, Map<String, String>>{
    'ar': {
      'appName': 'أحدعش | 11',
      'home': 'الرئيسية',
      'play': 'اللعب',
      'social': 'الفِرق',
      'ranking': 'الترتيب',
      'store': 'المتجر',
      'profile': 'حسابي',
      'retry': 'إعادة المحاولة',
      'offline': 'أنت غير متصل بالإنترنت',
      'genericError': 'حدث خطأ غير متوقع',
    },
    'en': {
      'appName': 'Ahdash | 11',
      'home': 'Home',
      'play': 'Play',
      'social': 'Lounge',
      'ranking': 'Ranking',
      'store': 'Store',
      'profile': 'Profile',
      'retry': 'Retry',
      'offline': 'You are offline',
      'genericError': 'Something went wrong',
    },
  };

  String value(String key) {
    return _values[locale.languageCode]?[key] ?? _values['ar']![key] ?? key;
  }

  String get appName => value('appName');
  String get home => value('home');
  String get play => value('play');
  String get social => value('social');
  String get ranking => value('ranking');
  String get store => value('store');
  String get profile => value('profile');
  String get retry => value('retry');
  String get offline => value('offline');
  String get genericError => value('genericError');
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

final class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
