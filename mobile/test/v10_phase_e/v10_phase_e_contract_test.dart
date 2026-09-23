import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test(
    'Profile UI binds identity, preferences, and stats to authenticated data',
    () {
      final screen = source(
        'lib/features/profile/presentation/profile_screen.dart',
      );
      final controller = source(
        'lib/features/profile/presentation/profile_controller.dart',
      );
      final model = source('lib/features/profile/domain/player_profile.dart');

      expect(screen, contains('ref.watch(playerProfileProvider)'));
      expect(controller, contains('authControllerProvider.future'));
      expect(controller, contains('auth == null || auth.isGuest'));
      expect(controller, contains('profile.id != auth.id'));
      expect(
        controller,
        contains("remote.rpc<Object?>('get_my_profile_summary')"),
      );
      expect(
        controller,
        contains("remote.rpc<Object?>('get_my_tournament_stats')"),
      );
      expect(controller, contains('PlayerProfile.fromJson(merged)'));
      expect(controller, isNot(contains('PlayerProfile.fromJson({')));

      for (final mapping in [
        "json['level']",
        "json['matches']",
        "json['wins']",
        "json['tournaments_won']",
        "json['questions_answered']",
        "json['favorite_league_data']",
        "json['favorite_club_data']",
        "json['show_football_preferences']",
        'if (json[key] is num) key',
      ]) {
        expect(model, contains(mapping));
      }

      for (final binding in [
        'profile.publicName',
        'profile.username',
        'profile.avatarUrl',
        'profile.level',
        'profile.matches',
        'profile.wins',
        'profile.tournamentsWon',
        'profile.questionsAnswered',
        'profile.favoriteLeagueData',
        'profile.favoriteClubData',
        'profile.showFootballPreferences',
      ]) {
        expect(screen, contains(binding));
      }

      for (final availableStat in [
        "profile.availableStats.contains('matches')",
        "profile.availableStats.contains('wins')",
        "profile.availableStats.contains('tournaments_won')",
        "profile.availableStats.contains('questions_answered')",
      ]) {
        expect(screen, contains(availableStat));
      }

      expect(
        screen,
        isNot(
          contains(
            RegExp(
              r'''_ProfileStat\([^)]*value:\s*['"]\d+(?:[.,]\d+)?['"]''',
              multiLine: true,
            ),
          ),
        ),
      );
      expect(
        screen,
        isNot(
          contains(
            RegExp(
              r'''['"](?:(?:المستوى|مستوى|الترتيب|ترتيب|التقييم|تقييم)\s*[:#-]?\s*\d+|\d+(?:[.,]\d+)?\s*(?:XP|نقطة|نقاط|مباراة|مباريات|فوز|انتصار|انتصارات|خسارة|خسائر|%|٪))['"]''',
            ),
          ),
        ),
      );
      expect(screen, contains('AhdashPlayer11Avatar'));
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
