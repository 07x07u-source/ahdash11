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

  test('Friends and Online legacy routes are inactive Home tombstones', () {
    final source = File('lib/core/routing/app_router.dart').readAsStringSync();
    expect(source, contains("path: '/friends', redirect: (_, _) => '/home'"));
    expect(source, isNot(contains('FriendsScreen')));
    expect(source, contains("path: '/online', redirect: (_, _) => '/home'"));
    expect(
      source,
      contains("path: '/online/match/:matchId', redirect: (_, _) => '/home'"),
    );
    expect(
      source,
      contains("path: '/room/:roomId', redirect: (_, _) => '/home'"),
    );
    expect(source, contains("path: '/wallet', redirect: (_, _) => '/store'"));
  });

  test(
    'approved mobile navigation exposes Party without Friends or Online',
    () {
      final activeNavigation = [
        'lib/shared/presentation/app_shell.dart',
        'lib/features/home/presentation/home_screen.dart',
        'lib/features/play/presentation/play_screen.dart',
        'lib/features/profile/presentation/profile_screen.dart',
        'lib/features/social/presentation/social_hub_screen.dart',
        'lib/features/social/presentation/social_team_screen.dart',
        'lib/core/services/notification_service.dart',
      ].map((path) => File(path).readAsStringSync()).join('\n');

      for (final removedEntry in [
        "'/friends'",
        "'/online'",
        'أونلاين (قريبًا)',
        'matchmaking',
        '1v1',
        '2v2',
      ]) {
        expect(activeNavigation, isNot(contains(removedEntry)));
      }
      expect(activeNavigation, contains("'/party/categories'"));
      expect(activeNavigation, contains("'/play'"));
    },
  );

  test('active Team Detail binds stats to repository-backed team data', () {
    final screenSource = File(
      'lib/features/social/presentation/social_team_screen.dart',
    ).readAsStringSync();
    final repositorySource = File(
      'lib/features/social/data/social_repository.dart',
    ).readAsStringSync();
    final entitySource = File(
      'lib/features/social/domain/social_entities.dart',
    ).readAsStringSync();

    expect(repositorySource, contains("'get_social_team_detail'"));
    expect(repositorySource, contains("params: {'p_team_id': teamId}"));
    expect(repositorySource, contains('SocialTeamDetail.fromJson'));
    expect(entitySource, contains("json['level']"));
    expect(entitySource, contains("json['weekly_points']"));

    for (final binding in [
      'team.members.fold<int>',
      'member.level',
      'member.weeklyPoints',
      'team.members.length',
      'team.challenges.length',
    ]) {
      expect(screenSource, contains(binding));
    }

    expect(
      screenSource,
      isNot(contains(RegExp(r'''_TeamMetric\(\s*value:\s*['"]\d+['"]'''))),
    );
    expect(
      screenSource,
      isNot(
        contains(
          RegExp(
            r'''['"](?:مستوى\s+\d+|\d+\s+(?:نقطة|نقاط|مباراة|مباريات|فوز|خسارة))''',
          ),
        ),
      ),
    );
    expect(screenSource, isNot(contains('win %')));
    expect(screenSource, isNot(contains('نتائج حديثة')));
  });
}
