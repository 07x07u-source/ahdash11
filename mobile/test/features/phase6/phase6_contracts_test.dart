import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_error_reporter.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/services/notification_service.dart';
import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/football/data/football_repository.dart';
import 'package:ahdash_11/features/football/domain/football_entities.dart';
import 'package:ahdash_11/features/football/presentation/football_preferences_controller.dart';
import 'package:ahdash_11/features/notifications/data/notifications_repository.dart';
import 'package:ahdash_11/features/premium/presentation/premium_controller.dart';
import 'package:ahdash_11/features/profile/domain/player_profile.dart';
import 'package:ahdash_11/features/profile/presentation/profile_controller.dart';
import 'package:ahdash_11/features/support/presentation/problem_report_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase6_fixture.dart';

final accountProvider = NotifierProvider<TestAccount, AuthUser?>(
  TestAccount.new,
);

class TestAccount extends Notifier<AuthUser?> {
  @override
  AuthUser? build() => phase6User;
  void switchTo(AuthUser? user) => state = user;
}

ProviderContainer makeContainer({
  PurchaseService? purchases,
  AppErrorReporter? reports,
  PreferenceStorage? storage,
  FootballRepository? football,
  ProfileRepository? profile,
}) {
  const noop = AppServices.noop();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      appConfigProvider.overrideWithValue(phase6Config),
      authControllerProvider.overrideWithBuild(
        (ref, notifier) async => ref.watch(accountProvider),
      ),
      appServicesProvider.overrideWithValue(
        AppServices(
          analytics: noop.analytics,
          crashReporter: noop.crashReporter,
          notifications: noop.notifications,
          ads: noop.ads,
          purchases: purchases ?? noop.purchases,
          errors: reports ?? noop.errors,
        ),
      ),
      preferenceStorageProvider.overrideWithValue(
        storage ?? MemoryPreferences(),
      ),
      if (football != null)
        footballRepositoryProvider.overrideWithValue(football),
      if (profile != null) profileRepositoryProvider.overrideWithValue(profile),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('profile only marks returned numeric stats available', () {
    final value = PlayerProfile.fromJson({
      'id': 'a',
      'username': 'a',
      'wins': 0,
    });
    expect(value.availableStats, {'wins'});
    expect(value.wins, 0);
    expect(value.availableStats, isNot(contains('matches')));
  });
  test('profile visibility defaults private and hides club jersey color', () {
    final value = PlayerProfile.fromJson({
      'id': 'a',
      'avatar_jersey_color': '#123456',
      'favorite_club_data': {'id': 'b', 'primary_color': '#ABCDEF'},
    });
    expect(value.showFootballPreferences, isFalse);
    expect(value.safeJerseyColor, '#123456');
  });
  test('profile team color precedes visible club and custom', () {
    final value = PlayerProfile.fromJson({
      'id': 'a',
      'show_football_preferences': true,
      'avatar_jersey_color': '#123456',
      'social_team': {'primary_color': '#111111'},
      'favorite_club_data': {'primary_color': '#ABCDEF'},
    });
    expect(value.safeJerseyColor, '#111111');
  });
  test('profile offline fails without fabricated profile', () async {
    final c = makeContainer();
    await expectLater(
      c.read(playerProfileProvider.future),
      throwsA(isA<ProfileUnavailable>()),
    );
  });
  test('profile rejects response belonging to a different account', () async {
    final c = makeContainer(profile: FakeProfile());
    expect((await c.read(playerProfileProvider.future)).id, phase6User.id);
    c
        .read(accountProvider.notifier)
        .switchTo(
          const AuthUser(id: 'account-b', username: 'b', isGuest: false),
        );
    await expectLater(
      c.read(playerProfileProvider.future),
      throwsA(isA<ProfileUnavailable>()),
    );
  });
  test('signed out profile has no cached private result', () async {
    final c = makeContainer(profile: FakeProfile());
    await c.read(playerProfileProvider.future);
    c.read(accountProvider.notifier).switchTo(null);
    await expectLater(
      c.read(playerProfileProvider.future),
      throwsA(isA<ProfileUnavailable>()),
    );
  });
  for (final route in [
    'https://example.com/teams/join?code=ABCD',
    '//example.com/home',
    '/online',
    '/wallet/coins',
    '/profile?token=secret',
    '/teams/join?code=BAD!',
    '/profile#secret',
  ]) {
    test('notification rejects $route', () {
      expect(
        NotificationNavigation.resolve({'deep_link': route}),
        '/notifications',
      );
    });
  }
  test('notification join allowlist strips extra query parameters', () {
    expect(
      NotificationNavigation.resolve({
        'deep_link': '/tournaments/join?code=ABCD&token=secret',
      }),
      '/tournaments/join?code=ABCD',
    );
  });
  test('notification returned timestamps determine unread state', () {
    final row = {
      'id': '1',
      'type': 'system',
      'title_ar': 'عنوان',
      'body_ar': 'نص',
      'created_at': '2026-09-05T10:00:00Z',
    };
    expect(InboxNotification.fromJson(row).unread, isTrue);
    expect(
      InboxNotification.fromJson({
        ...row,
        'read_at': '2026-09-05T11:00:00Z',
      }).unread,
      isFalse,
    );
  });
  test('notifications without backend fail instead of samples', () async {
    await expectLater(
      makeContainer().read(notificationsProvider.future),
      throwsStateError,
    );
  });
  test('settings persistence preserves separate immediate writes', () async {
    final storage = MemoryPreferences();
    final c = makeContainer(storage: storage);
    await c.read(appPreferencesProvider.future);
    final n = c.read(appPreferencesProvider.notifier);
    await Future.wait([
      n.setSoundEffects(false),
      n.setHaptics(false),
      n.setReducedMotion(true),
    ]);
    final value = c.read(appPreferencesProvider).requireValue;
    expect(value.soundEffects, isFalse);
    expect(value.haptics, isFalse);
    expect(value.reducedMotion, isTrue);
    expect(storage.values.length, 3);
  });
  test('settings storage failure does not claim saved value', () async {
    final storage = MemoryPreferences()..failWrite = true;
    final c = makeContainer(storage: storage);
    await c.read(appPreferencesProvider.future);
    await expectLater(
      c.read(appPreferencesProvider.notifier).setSoundEffects(false),
      throwsStateError,
    );
    expect(c.read(appPreferencesProvider).requireValue.soundEffects, isTrue);
  });
  test('settings read failure yields usable safe defaults', () async {
    final c = makeContainer(storage: MemoryPreferences()..failRead = true);
    expect(
      (await c.read(appPreferencesProvider.future)).player11Variant,
      Player11Variant.male,
    );
  });
  test('report validation follows optional 1500-character server contract', () {
    expect(ProblemReportContract.validate('gameplay', ''), isNull);
    expect(ProblemReportContract.validate('unknown', ''), isNotNull);
    expect(ProblemReportContract.validate('other', 'a' * 1501), isNotNull);
    expect(
      ProblemReportContract.safeSource('/profile?token=secret'),
      '/settings',
    );
  });
  test(
    'report no-op does not report successful submission and retains draft',
    () async {
      final c = makeContainer();
      await c.read(authControllerProvider.future);
      final n = c.read(problemReportProvider.notifier)
        ..update(description: 'وصف خاص');
      expect(await n.submit('/settings'), isFalse);
      expect(c.read(problemReportProvider).description, 'وصف خاص');
      expect(c.read(problemReportProvider).sent, isFalse);
    },
  );
  test('report prevents double submit and only confirms returned id', () async {
    final reporter = FakeReports();
    final c = makeContainer(reports: reporter);
    await c.read(authControllerProvider.future);
    final n = c.read(problemReportProvider.notifier)
      ..update(description: 'وصف');
    final first = n.submit('/settings');
    expect(await n.submit('/settings'), isFalse);
    expect(reporter.calls, 1);
    reporter.result.complete('report-id');
    expect(await first, isTrue);
    expect(c.read(problemReportProvider).sent, isTrue);
  });
  test('report timeout preserves text and blocks ambiguous retry', () async {
    final reporter = FakeReports();
    final c = makeContainer(reports: reporter);
    await c.read(authControllerProvider.future);
    final n = c.read(problemReportProvider.notifier)
      ..update(description: 'وصف');
    final first = n.submit('/settings');
    reporter.result.completeError(TimeoutException('network'));
    expect(await first, isFalse);
    expect(c.read(problemReportProvider).uncertain, isTrue);
    expect(await n.submit('/settings'), isFalse);
    expect(reporter.calls, 1);
    expect(c.read(problemReportProvider).description, 'وصف');
  });
  test('report draft clears on account change', () async {
    final c = makeContainer();
    await c.read(authControllerProvider.future);
    c.read(problemReportProvider.notifier).update(description: 'خاص');
    c.read(accountProvider.notifier).switchTo(null);
    await c.read(authControllerProvider.future);
    expect(c.read(problemReportProvider).description, isEmpty);
  });
  for (final status in [
    'fallback',
    'pending',
    'unlicensed',
    'licensed',
    'custom',
  ]) {
    test('badge rights $status', () {
      final club = FootballClub.fromJson({
        'id': 'a',
        'league_id': 'l',
        'logo_url': 'https://example.com/badge.png',
        'visual_status': status,
      });
      expect(
        club.safeLogoUrl,
        ['licensed', 'custom'].contains(status) ? isNotNull : isNull,
      );
    });
  }
  test('football league change clears incompatible club and query', () async {
    final c = makeContainer(football: FakeFootball());
    await c.read(footballPreferencesProvider.future);
    c.read(footballPreferencesProvider.notifier).chooseLeague('league-b');
    final value = c.read(footballPreferencesProvider).requireValue;
    expect(value.clubId, isNull);
    expect(value.query, isEmpty);
    expect(value.leagueId, 'league-b');
    await Future<void>.delayed(Duration.zero);
  });
  test(
    'football search forwards league and query and hides results safely',
    () async {
      final repo = FakeFootball();
      final c = makeContainer(football: repo);
      await c.read(footballPreferencesProvider.future);
      await c.read(footballPreferencesProvider.notifier).search('United');
      expect(repo.lastQuery, 'United');
      expect(repo.lastLeague, 'league-a');
      expect(c.read(footballPreferencesProvider).requireValue.clubs, isEmpty);
    },
  );
  test('football visibility is persisted and save is guarded', () async {
    final repo = FakeFootball()..saveGate = Completer<void>();
    final c = makeContainer(football: repo);
    await c.read(footballPreferencesProvider.future);
    final n = c.read(footballPreferencesProvider.notifier)..visibility(false);
    final first = n.save();
    expect(await n.save(), isFalse);
    expect(repo.saves, 1);
    repo.saveGate!.complete();
    expect(await first, isTrue);
    expect(repo.publicValue, isFalse);
  });
  test('premium unavailable has no plans or local authority', () async {
    final value = await makeContainer().read(premiumControllerProvider.future);
    expect(value.available, isFalse);
    expect(value.plans, isEmpty);
    expect(value.status.hasAccess, isFalse);
  });
  test(
    'premium double purchase guarded, confirmation comes from service',
    () async {
      final store = FakePurchases()..gate = Completer<bool>();
      final c = makeContainer(purchases: store);
      await c.read(premiumControllerProvider.future);
      final n = c.read(premiumControllerProvider.notifier);
      final first = n.purchase();
      expect(await n.purchase(), isFalse);
      expect(store.buys, 1);
      expect(
        c.read(premiumControllerProvider).requireValue.status.hasAccess,
        isFalse,
      );
      store.active = true;
      store.gate!.complete(true);
      expect(await first, isTrue);
      expect(
        c.read(premiumControllerProvider).requireValue.status.hasAccess,
        isTrue,
      );
    },
  );
  test('premium purchase result alone cannot grant entitlement', () async {
    final store = FakePurchases()..result = true;
    final c = makeContainer(purchases: store);
    await c.read(premiumControllerProvider.future);
    expect(
      await c.read(premiumControllerProvider.notifier).purchase(),
      isFalse,
    );
    expect(
      c.read(premiumControllerProvider).requireValue.status.hasAccess,
      isFalse,
    );
  });
  test('premium cancellation clears busy without granting access', () async {
    final store = FakePurchases()..error = PlatformException(code: '1');
    final c = makeContainer(purchases: store);
    await c.read(premiumControllerProvider.future);
    expect(
      await c.read(premiumControllerProvider.notifier).purchase(),
      isFalse,
    );
    final value = c.read(premiumControllerProvider).requireValue;
    expect(value.busy, isFalse);
    expect(value.status.hasAccess, isFalse);
    expect(value.message, contains('أُلغيت'));
  });
  for (final active in [false, true]) {
    test('restore entitlement $active is reported truthfully', () async {
      final store = FakePurchases()..result = active;
      final c = makeContainer(purchases: store);
      await c.read(premiumControllerProvider.future);
      store.active = active;
      expect(
        await c.read(premiumControllerProvider.notifier).restore(),
        active,
      );
      expect(store.restores, 1);
      expect(
        c.read(premiumControllerProvider).requireValue.message,
        contains(active ? 'استعدنا' : 'لا يوجد'),
      );
    });
  }
  test('restore error does not claim success', () async {
    final store = FakePurchases()..error = Exception('offline');
    final c = makeContainer(purchases: store);
    await c.read(premiumControllerProvider.future);
    expect(await c.read(premiumControllerProvider.notifier).restore(), isFalse);
    expect(
      c.read(premiumControllerProvider).requireValue.message,
      contains('تعذر'),
    );
  });
  test(
    'premium account switch discards in-flight private purchase result',
    () async {
      final store = FakePurchases()..gate = Completer<bool>();
      final c = makeContainer(purchases: store);
      await c.read(premiumControllerProvider.future);
      final first = c.read(premiumControllerProvider.notifier).purchase();
      c.read(accountProvider.notifier).switchTo(null);
      await c.read(premiumControllerProvider.future);
      store.gate!.complete(true);
      expect(await first, isFalse);
      expect(c.read(premiumControllerProvider).requireValue.available, isFalse);
    },
  );
}

class FakeProfile extends ProfileRepository {
  FakeProfile() : super(null);
  @override
  Future<PlayerProfile> load() async => phase6Profile;
}

class MemoryPreferences extends PreferenceStorage {
  final values = <String, Object>{};
  bool failRead = false, failWrite = false;
  @override
  Future<Object?> read(String key) async {
    if (failRead) throw StateError('read');
    return values[key];
  }

  @override
  Future<void> write(String key, Object value) async {
    if (failWrite) throw StateError('write');
    values[key] = value;
  }
}

class FakeFootball extends FootballRepository {
  FakeFootball() : super(null);
  String? lastQuery, lastLeague;
  bool? publicValue;
  int saves = 0;
  Completer<void>? saveGate;
  @override
  bool get isAvailable => true;
  @override
  Future<List<FootballLeague>> listLeagues() async => phase6Leagues;
  @override
  Future<FootballPreferences> loadPreferences() async =>
      const FootballPreferences(leagueId: 'league-a', clubId: 'club-a');
  @override
  Future<List<FootballClub>> searchClubs({
    String? query,
    String? leagueId,
  }) async {
    lastQuery = query;
    lastLeague = leagueId;
    return query == null || query.isEmpty
        ? phase6Clubs.where((c) => c.leagueId == leagueId).toList()
        : [];
  }

  @override
  Future<void> savePreferences({
    String? leagueId,
    String? clubId,
    required bool showPublicly,
  }) async {
    saves++;
    publicValue = showPublicly;
    await saveGate?.future;
  }
}

class FakePurchases implements PurchaseService {
  bool active = false, result = false;
  int buys = 0, restores = 0;
  Object? error;
  Completer<bool>? gate;
  @override
  bool get enabled => true;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> identify(String userId) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<bool> isPremium() async => active;
  @override
  Future<List<PremiumPlan>> loadPlans() async => phase6Plans;
  @override
  Future<PremiumStatus> loadStatus() async => PremiumStatus(
    state: active ? PremiumAccessState.active : PremiumAccessState.inactive,
  );
  @override
  Future<bool> purchasePremium() => purchasePlan(PremiumPlanPeriod.monthly);
  @override
  Future<bool> purchasePlan(PremiumPlanPeriod period) async {
    buys++;
    if (error != null) throw error!;
    return gate == null ? result : await gate!.future;
  }

  @override
  Future<bool> restorePurchases() async {
    restores++;
    if (error != null) throw error!;
    return result;
  }
}

class FakeReports implements AppErrorReporter {
  int calls = 0;
  final result = Completer<String?>();
  @override
  String get appVersion => 'test';
  @override
  String get buildNumber => '1';
  @override
  Future<String?> submitProblem({
    required String category,
    required String? description,
    required String? screen,
  }) {
    calls++;
    return result.future;
  }

  @override
  Future<void> report({
    required AppErrorSeverity severity,
    required AppErrorCategory category,
    required String feature,
    required Object error,
    StackTrace? stackTrace,
    String? screen,
    Map<String, String?> context = const {},
  }) async {}
}
