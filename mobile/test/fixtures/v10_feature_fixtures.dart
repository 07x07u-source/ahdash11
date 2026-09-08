// Deterministic test-only fixtures. Production code must never import this file.
import 'dart:async';

import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/ranking/domain/leaderboard_entry.dart';

export '../helpers/party_phase4_fixture.dart';
export '../helpers/phase6_fixture.dart';

enum FixtureStateKind {
  loading,
  populated,
  empty,
  error,
  disabled,
  validation,
  guestRestricted,
  authenticated,
  compact,
  textScale13,
  keyboard,
}

final class FeatureFixtureCoverage {
  const FeatureFixtureCoverage({
    required this.feature,
    required this.screens,
    required this.actions,
    required this.states,
  });

  final String feature;
  final List<String> screens;
  final List<String> actions;
  final Set<FixtureStateKind> states;
}

final class DeterministicAsyncFixture<T> {
  const DeterministicAsyncFixture._();

  static Future<T> loading<T>() => Completer<T>().future;
  static Future<T> populated<T>(T value) => Future<T>.value(value);
  static Future<T> error<T>([String message = 'fixture unavailable']) =>
      Future<T>.error(StateError(message));
}

abstract final class V10FeatureFixtures {
  static final fixedNow = DateTime.utc(2026, 9, 7, 12);

  static const guest = AuthUser(
    id: 'fixture-guest',
    username: 'ضيف',
    isGuest: true,
  );
  static const account = AuthUser(
    id: 'fixture-account',
    username: 'fixture_player_11',
    isGuest: false,
    email: 'fixture@example.test',
  );

  static const emptyFriendsDashboard = <String, Object?>{
    'inbox': <Object?>[],
    'outbox': <Object?>[],
    'friends': <Object?>[],
  };

  static const populatedFriendsDashboard = <String, Object?>{
    'inbox': <Object?>[
      <String, Object?>{
        'request_id': 'fixture-request-in',
        'user_id': 'fixture-player-in',
        'display_name': 'لاعب طلب وارد',
        'username': 'fixture_incoming',
      },
    ],
    'outbox': <Object?>[
      <String, Object?>{
        'request_id': 'fixture-request-out',
        'user_id': 'fixture-player-out',
        'display_name': 'لاعب طلب مرسل',
        'username': 'fixture_outgoing',
      },
    ],
    'friends': <Object?>[
      <String, Object?>{
        'user_id': 'fixture-friend-a',
        'display_name': 'صديق الاختبار الأول',
        'username': 'fixture_friend_a',
      },
      <String, Object?>{
        'user_id': 'fixture-friend-b',
        'display_name': 'صديق الاختبار الثاني',
        'username': 'fixture_friend_b',
      },
    ],
  };

  static const friendSearchResults = <Map<String, Object?>>[
    <String, Object?>{
      'user_id': 'fixture-search-new',
      'display_name': 'لاعب جديد',
      'username': 'fixture_new',
      'relationship': 'none',
    },
    <String, Object?>{
      'user_id': 'fixture-search-pending',
      'display_name': 'طلب سابق',
      'username': 'fixture_pending',
      'relationship': 'pending_sent',
    },
    <String, Object?>{
      'user_id': 'fixture-search-friend',
      'display_name': 'صديق حالي',
      'username': 'fixture_existing',
      'relationship': 'friend',
    },
  ];

  static const selfSearchResult = <Map<String, Object?>>[
    <String, Object?>{
      'user_id': 'fixture-account',
      'display_name': 'الحساب نفسه',
      'username': 'fixture_player_11',
      'relationship': 'none',
    },
  ];

  static const blockedPlayers = <Map<String, Object?>>[
    <String, Object?>{
      'user_id': 'fixture-blocked-a',
      'display_name': 'حساب محظور للاختبار',
      'username': 'fixture_blocked',
    },
  ];

  static const ranking = <LeaderboardEntry>[
    LeaderboardEntry(
      rank: 1,
      userId: 'fixture-ranked-a',
      username: 'fixture_ranked_a',
      rating: 1120,
      tier: 'Gold',
    ),
    LeaderboardEntry(
      rank: 2,
      userId: 'fixture-ranked-b',
      username: 'fixture_ranked_b',
      rating: 1080,
      tier: 'Silver',
    ),
  ];
}

const v10FeatureFixtureCoverage = <FeatureFixtureCoverage>[
  FeatureFixtureCoverage(
    feature: 'Auth',
    screens: [
      'Launch',
      'Onboarding',
      'Sign In',
      'Create Account',
      'Guest',
      'Account Required Gate',
    ],
    actions: ['restore', 'sign in', 'create', 'Google', 'guest', 'logout'],
    states: {
      FixtureStateKind.loading,
      FixtureStateKind.populated,
      FixtureStateKind.error,
      FixtureStateKind.validation,
      FixtureStateKind.keyboard,
      FixtureStateKind.compact,
      FixtureStateKind.textScale13,
    },
  ),
  FeatureFixtureCoverage(
    feature: 'Home',
    screens: ['Play Hub', 'Play Menu', 'How To Play'],
    actions: ['start Party', 'resume', 'navigate', 'open account gate'],
    states: {
      FixtureStateKind.populated,
      FixtureStateKind.empty,
      FixtureStateKind.guestRestricted,
      FixtureStateKind.authenticated,
      FixtureStateKind.compact,
      FixtureStateKind.textScale13,
    },
  ),
  FeatureFixtureCoverage(
    feature: 'Party',
    screens: [
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
    ],
    actions: [
      'select/search',
      'validate teams',
      'split/skip',
      'select helper',
      'start',
      'choose question',
      'reveal',
      'score',
      'resume/restore',
      'undo',
    ],
    states: {
      FixtureStateKind.loading,
      FixtureStateKind.populated,
      FixtureStateKind.empty,
      FixtureStateKind.error,
      FixtureStateKind.disabled,
      FixtureStateKind.validation,
      FixtureStateKind.compact,
      FixtureStateKind.textScale13,
      FixtureStateKind.keyboard,
    },
  ),
  FeatureFixtureCoverage(
    feature: 'Tournament',
    screens: [
      'Hub',
      'Create',
      'Join',
      'Teams',
      'Registrations',
      'Draw',
      'Bracket',
      'Match',
      'Champion',
    ],
    actions: [
      'create',
      'join',
      'register',
      'add team',
      'draw',
      'confirm result',
      'restore',
    ],
    states: {
      FixtureStateKind.loading,
      FixtureStateKind.populated,
      FixtureStateKind.empty,
      FixtureStateKind.error,
      FixtureStateKind.disabled,
      FixtureStateKind.validation,
      FixtureStateKind.guestRestricted,
      FixtureStateKind.compact,
      FixtureStateKind.textScale13,
      FixtureStateKind.keyboard,
    },
  ),
  FeatureFixtureCoverage(
    feature: 'Other Play',
    screens: [
      'Game Setup',
      'Category Browser',
      'Solo Setup',
      'Solo Match',
      'Solo Result',
      'Team Challenge',
    ],
    actions: ['configure', 'start local Solo', 'submit challenge answer'],
    states: {
      FixtureStateKind.loading,
      FixtureStateKind.populated,
      FixtureStateKind.empty,
      FixtureStateKind.error,
      FixtureStateKind.disabled,
      FixtureStateKind.guestRestricted,
      FixtureStateKind.compact,
      FixtureStateKind.textScale13,
    },
  ),
  FeatureFixtureCoverage(
    feature: 'Social',
    screens: [
      'Social Hub',
      'Team Join',
      'Friends',
      'Search',
      'Blocked Players',
      'Team Detail',
    ],
    actions: ['search', 'add', 'accept/reject', 'remove', 'block', 'unblock'],
    states: {
      FixtureStateKind.loading,
      FixtureStateKind.populated,
      FixtureStateKind.empty,
      FixtureStateKind.error,
      FixtureStateKind.disabled,
      FixtureStateKind.guestRestricted,
      FixtureStateKind.compact,
      FixtureStateKind.textScale13,
      FixtureStateKind.keyboard,
    },
  ),
  FeatureFixtureCoverage(
    feature: 'Account',
    screens: [
      'Profile',
      'Ranking',
      'Notifications',
      'Settings',
      'Report',
      'Football Preferences',
      'Premium',
    ],
    actions: ['save', 'submit', 'purchase', 'restore', 'logout', 'delete'],
    states: {
      FixtureStateKind.loading,
      FixtureStateKind.populated,
      FixtureStateKind.empty,
      FixtureStateKind.error,
      FixtureStateKind.disabled,
      FixtureStateKind.validation,
      FixtureStateKind.guestRestricted,
      FixtureStateKind.authenticated,
      FixtureStateKind.compact,
      FixtureStateKind.textScale13,
      FixtureStateKind.keyboard,
    },
  ),
];
