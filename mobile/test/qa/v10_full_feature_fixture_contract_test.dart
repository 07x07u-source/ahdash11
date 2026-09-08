import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../fixtures/v10_feature_fixtures.dart';

void main() {
  test('fixture registry inventories every active product area', () {
    expect(v10FeatureFixtureCoverage.map((entry) => entry.feature).toSet(), {
      'Auth',
      'Home',
      'Party',
      'Tournament',
      'Other Play',
      'Social',
      'Account',
    });
    expect(
      v10FeatureFixtureCoverage.expand((entry) => entry.screens).toSet(),
      containsAll({
        'Launch',
        'Onboarding',
        'Sign In',
        'Create Account',
        'Account Required Gate',
        'Play Hub',
        'Play Menu',
        'How To Play',
        'Categories',
        'Detail',
        'Teams',
        'Splitter',
        'Helpers',
        'Ready',
        'Board',
        'Text Question',
        'Image Question',
        'Reveal',
        'Result',
        'Saved Games',
        'Hub',
        'Create',
        'Join',
        'Registrations',
        'Draw',
        'Bracket',
        'Match',
        'Champion',
        'Game Setup',
        'Category Browser',
        'Solo Setup',
        'Solo Match',
        'Solo Result',
        'Team Challenge',
        'Social Hub',
        'Team Join',
        'Friends',
        'Search',
        'Blocked Players',
        'Team Detail',
        'Profile',
        'Ranking',
        'Notifications',
        'Settings',
        'Report',
        'Football Preferences',
        'Premium',
      }),
    );
  });

  test(
    'every major collection has loading, populated, empty and error states',
    () {
      for (final feature in const [
        'Party',
        'Tournament',
        'Social',
        'Account',
      ]) {
        final entry = v10FeatureFixtureCoverage.singleWhere(
          (value) => value.feature == feature,
        );
        expect(
          entry.states,
          containsAll({
            FixtureStateKind.loading,
            FixtureStateKind.populated,
            FixtureStateKind.empty,
            FixtureStateKind.error,
          }),
          reason: feature,
        );
      }
    },
  );

  test('fixture identities and clocks are stable and visibly test-only', () {
    expect(V10FeatureFixtures.fixedNow, DateTime.utc(2026, 9, 7, 12));
    expect(V10FeatureFixtures.guest.id, startsWith('fixture-'));
    expect(V10FeatureFixtures.account.id, startsWith('fixture-'));
    expect(
      V10FeatureFixtures.friendSearchResults
          .map((row) => '${row['user_id']}')
          .every((id) => id.startsWith('fixture-')),
      isTrue,
    );
  });

  test('production Dart cannot import QA fixtures or expose fixture hooks', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      if (source.contains('test/fixtures/') ||
          source.contains('v10_feature_fixtures') ||
          source.contains('fixtureDashboard')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('Online remains absent from the active fixture inventory', () {
    final names = v10FeatureFixtureCoverage
        .expand((entry) => entry.screens)
        .map((value) => value.toLowerCase());
    expect(names, isNot(contains('online')));
    expect(names, isNot(contains('private room')));
  });
}
