import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final screens = File(
    'lib/features/tournament/presentation/tournament_screens.dart',
  ).readAsStringSync();
  final router = File('lib/core/routing/app_router.dart').readAsStringSync();

  test('semifinal and final remain bracket states, not product routes', () {
    expect(router, contains("path: '/tournaments/bracket'"));
    expect(router, isNot(contains('/tournaments/semifinal')));
    expect(router, isNot(contains('/tournaments/final')));
    expect(screens, contains("'نصف النهائي'"));
    expect(screens, contains("'النهائي'"));
  });

  test('Tournament screens reuse the V10 portrait foundation', () {
    expect(screens, contains('AhdashV10Frame'));
    expect(screens, contains('maxWidth: 430'));
    expect(screens, contains("ValueKey('tournament-keyboard-scroll')"));
    expect(screens, contains("ValueKey('tournament-name-field')"));
  });

  test('Create options come from TournamentRules domain constraints', () {
    expect(screens, contains('TournamentRules.supportedCapacities'));
    expect(screens, contains('TournamentRules.supportedPlayerCounts'));
    expect(screens, contains('TournamentEngine.tournamentNameError'));
  });

  test('Tournament UI contains no prohibited economy or fake ranking copy', () {
    for (final prohibited in <String>[
      'XP',
      'Coins',
      'Wallet',
      'MVP',
      'نسبة الفوز',
      'تصنيف الفريق',
    ]) {
      expect(screens, isNot(contains(prohibited)), reason: prohibited);
    }
  });
}
