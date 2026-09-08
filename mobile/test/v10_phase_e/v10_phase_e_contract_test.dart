import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test(
    'Profile UI exposes identity and preferences without fake statistics',
    () {
      final value = source(
        'lib/features/profile/presentation/profile_screen.dart',
      );
      for (final token in [
        'profile.matches',
        'profile.wins',
        'profile.xp',
        'profile.level',
        'profile.rating',
      ]) {
        expect(value, isNot(contains(token)));
      }
      expect(value, contains('AhdashPlayer11Avatar'));
      expect(value, contains('favoriteLeagueData'));
    },
  );

  test('Premium UI has dynamic prices and no unsupported benefit claims', () {
    final value = source(
      'lib/features/premium/presentation/premium_screen.dart',
    );
    final purchases = source('lib/core/services/purchase_service.dart');
    expect(value, contains('plan.price'));
    expect(purchases, contains('price: product.priceString'));
    for (final token in [
      '19.99',
      '١٩.٩٩',
      '25%',
      '٢٥٪',
      'توفير',
      'إزالة الإعلانات',
      'مضاعفة النقاط',
    ]) {
      expect(value, isNot(contains(token)));
    }
  });

  test('Settings omit inactive economy, dark mode, and power saving', () {
    final value = source(
      'lib/features/settings/presentation/settings_screen.dart',
    );
    for (final token in [
      'Power Saving',
      'توفير الطاقة',
      'Dark Mode',
      'الوضع الداكن',
      'Coins',
      'Wallet',
    ]) {
      expect(value, isNot(contains(token)));
    }
  });

  test('Store is Premium and wallet safely redirects to store', () {
    final value = source('lib/core/routing/app_router.dart');
    expect(
      value,
      contains(
        "GoRoute(path: '/store', builder: (_, _) => const PremiumScreen())",
      ),
    );
    expect(
      value,
      contains("GoRoute(path: '/wallet', redirect: (_, _) => '/store')"),
    );
  });

  test('Report and football inputs use keyboard-safe portrait scrolling', () {
    final report = source(
      'lib/features/support/presentation/report_problem_screen.dart',
    );
    final football = source(
      'lib/features/football/presentation/football_preferences_screen.dart',
    );
    expect(report, contains('MediaQuery.viewInsetsOf(context).bottom'));
    expect(report, contains("ValueKey('report-keyboard-scroll')"));
    expect(football, contains('MediaQuery.viewInsetsOf(context).bottom'));
    expect(football, contains("ValueKey('football-keyboard-scroll')"));
  });
}
