import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('How to Play documents the real Party contract and helpers', () {
    final source = File(
      'lib/features/party/presentation/party_support_screens.dart',
    ).readAsStringSync();
    for (final value in [
      'اختاروا 6 فئات',
      'جهّزوا فريقين',
      '36 سؤالًا',
      'جاوب جوابين',
      'اتصال بصديق',
      'الحفرة',
      'استريح',
      'الفخ',
      'لا يجري مكالمة',
    ]) {
      expect(source, contains(value));
    }
    expect(source, isNot(contains('Contacts')));
  });

  test('Ranking has no production demo leaderboard fallback', () {
    final source = File(
      'lib/features/ranking/presentation/ranking_controller.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('demo-1')));
    expect(source, isNot(contains('صقر الملاعب')));
    expect(source, contains('return const [];'));
  });

  test('Online remains deferred and wallet remains redirected', () {
    final source = File('lib/core/routing/app_router.dart').readAsStringSync();
    expect(source, contains("path: '/online', redirect: (_, _) => '/home'"));
    expect(source, contains("path: '/online/match/:matchId'"));
    expect(source, contains("path: '/room/:roomId'"));
    expect(source, contains("path: '/wallet', redirect: (_, _) => '/store'"));
  });

  test('active Team Detail omits fake levels, points, and match stats', () {
    final source = File(
      'lib/features/social/presentation/social_team_screen.dart',
    ).readAsStringSync();
    for (final token in [
      'weeklyPoints',
      'member.level',
      'win %',
      'مستوى',
      'نتائج حديثة',
    ]) {
      expect(source, isNot(contains(token)));
    }
    expect(source, contains('team.members.length'));
  });
}
