import 'dart:async';

import 'package:ahdash_11/core/services/ads_service.dart';
import 'package:ahdash_11/core/services/analytics_service.dart';
import 'package:ahdash_11/core/services/app_error_reporter.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/services/crash_reporter.dart';
import 'package:ahdash_11/core/services/notification_service.dart';
import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/features/auth/data/supabase_user_mapper.dart';
import 'package:ahdash_11/features/auth/domain/auth_repository.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

void main() {
  test(
    'restored anonymous Guest is not identified to push or store services',
    () async {
      final notifications = _FakeNotifications();
      final purchases = _FakePurchases();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(
              restoreUser: const AuthUser(
                id: 'anonymous',
                username: 'ضيف',
                isGuest: true,
              ),
            ),
          ),
          appServicesProvider.overrideWithValue(
            AppServices(
              analytics: _FakeAnalytics(),
              crashReporter: const NoopCrashReporter(),
              notifications: notifications,
              ads: const NoopAdsService(),
              purchases: purchases,
              errors: const NoopAppErrorReporter(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        (await container.read(authControllerProvider.future))?.isGuest,
        isTrue,
      );
      expect(notifications.identifiedUserId, isNull);
      expect(purchases.identifiedUserId, isNull);
    },
  );
  test('maps Google metadata using stable fallbacks and avatar', () {
    const user = User(
      id: 'google-user',
      appMetadata: {'provider': 'google'},
      userMetadata: {
        'full_name': '  نورة القحطاني  ',
        'name': 'Fallback Name',
        'picture': 'https://images.example.test/noura.webp',
      },
      aud: 'authenticated',
      email: 'noura@example.test',
      createdAt: '2026-08-28T00:00:00Z',
    );

    final mapped = mapSupabaseUser(user);

    expect(mapped.id, 'google-user');
    expect(mapped.username, 'نورة القحطاني');
    expect(mapped.email, 'noura@example.test');
    expect(mapped.avatarUrl, 'https://images.example.test/noura.webp');
    expect(mapped.isGuest, isFalse);
  });

  test(
    'social login identifies integrations and records Google method',
    () async {
      const user = AuthUser(
        id: 'signed-in-user',
        username: 'لاعب قوقل',
        isGuest: false,
        email: 'player@example.test',
      );
      final repository = _FakeAuthRepository(
        result: const SocialSignInAuthenticated(user),
      );
      final analytics = _FakeAnalytics();
      final notifications = _FakeNotifications();
      final purchases = _FakePurchases();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          appServicesProvider.overrideWithValue(
            AppServices(
              analytics: analytics,
              crashReporter: const NoopCrashReporter(),
              notifications: notifications,
              ads: const NoopAdsService(),
              purchases: purchases,
              errors: const NoopAppErrorReporter(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      final authenticated = await container
          .read(authControllerProvider.notifier)
          .signInWithSocial(SocialProvider.google);

      expect(authenticated, isTrue);
      expect(container.read(authControllerProvider).value?.id, user.id);
      expect(notifications.identifiedUserId, user.id);
      expect(purchases.identifiedUserId, user.id);
      expect(analytics.events, hasLength(1));
      expect(analytics.events.single.name, 'login');
      expect(
        analytics.events.single.parameters,
        containsPair('method', 'google'),
      );
    },
  );

  test('Google cancellation returns quietly without an error state', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(
            error: const SocialSignInException(
              SocialSignInFailureCode.canceled,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    final authenticated = await container
        .read(authControllerProvider.notifier)
        .signInWithSocial(SocialProvider.google);

    expect(authenticated, isFalse);
    expect(container.read(authControllerProvider), isA<AsyncData<AuthUser?>>());
    expect(container.read(authControllerProvider).value, isNull);
  });

  test('Google auth failure is exposed as a typed error state', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(
            error: const SocialSignInException(
              SocialSignInFailureCode.configuration,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    await container
        .read(authControllerProvider.notifier)
        .signInWithSocial(SocialProvider.google);

    expect(
      container.read(authControllerProvider),
      isA<AsyncError<AuthUser?>>(),
    );
  });

  test(
    'a second Google press is ignored while authentication is active',
    () async {
      const user = AuthUser(
        id: 'google-user',
        username: 'لاعب',
        isGuest: false,
      );
      final completer = Completer<SocialSignInResult>();
      final repository = _BlockingAuthRepository(completer);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      final notifier = container.read(authControllerProvider.notifier);

      final first = notifier.signInWithSocial(SocialProvider.google);
      await Future<void>.delayed(Duration.zero);
      final duplicate = await notifier.signInWithSocial(SocialProvider.google);
      completer.complete(const SocialSignInAuthenticated(user));

      expect(duplicate, isFalse);
      expect(await first, isTrue);
      expect(repository.socialCalls, 1);
    },
  );

  test(
    'a second Apple press is ignored while authentication is active',
    () async {
      const user = AuthUser(id: 'apple-user', username: 'لاعب', isGuest: false);
      final completer = Completer<SocialSignInResult>();
      final repository = _BlockingAuthRepository(completer);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      final notifier = container.read(authControllerProvider.notifier);

      final first = notifier.signInWithSocial(SocialProvider.apple);
      await Future<void>.delayed(Duration.zero);
      final duplicate = await notifier.signInWithSocial(SocialProvider.apple);
      completer.complete(const SocialSignInAuthenticated(user));

      expect(duplicate, isFalse);
      expect(await first, isTrue);
      expect(repository.socialCalls, 1);
    },
  );

  test('a second email submit is ignored while sign-in is active', () async {
    const user = AuthUser(id: 'email-user', username: 'لاعب', isGuest: false);
    final completer = Completer<AuthUser>();
    final repository = _BlockingCredentialAuthRepository(completer);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);

    final first = notifier.signIn('player@example.test', 'valid-password');
    await Future<void>.delayed(Duration.zero);
    await notifier.signIn('player@example.test', 'valid-password');
    completer.complete(user);
    await first;

    expect(repository.signInCalls, 1);
    expect(container.read(authControllerProvider).value, user);
  });

  test('restores an existing auth session without a new login', () async {
    const user = AuthUser(id: 'restored', username: 'راجع', isGuest: false);
    final repository = _FakeAuthRepository(restoreUser: user);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect(await container.read(authControllerProvider.future), user);
  });

  test('logout clears the repository session', () async {
    const user = AuthUser(id: 'signed-in', username: 'لاعب', isGuest: false);
    final repository = _FakeAuthRepository(restoreUser: user);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    await container.read(authControllerProvider.notifier).signOut();

    expect(repository.signOutCalls, 1);
    expect(container.read(authControllerProvider).value, isNull);
  });
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.result, this.error, this.restoreUser});

  final SocialSignInResult? result;
  final Object? error;
  final AuthUser? restoreUser;
  int signOutCalls = 0;

  @override
  Future<AuthUser> continueAsGuest() => throw UnimplementedError();

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AuthUser?> restore() async => restoreUser;

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async => signOutCalls += 1;
}

final class _BlockingAuthRepository implements AuthRepository {
  _BlockingAuthRepository(this.completer);

  final Completer<SocialSignInResult> completer;
  int socialCalls = 0;

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) {
    socialCalls += 1;
    return completer.future;
  }

  @override
  Future<AuthUser?> restore() async => null;

  @override
  Future<AuthUser> continueAsGuest() => throw UnimplementedError();

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

final class _BlockingCredentialAuthRepository implements AuthRepository {
  _BlockingCredentialAuthRepository(this.completer);

  final Completer<AuthUser> completer;
  int signInCalls = 0;

  @override
  Future<AuthUser> signIn({required String email, required String password}) {
    signInCalls += 1;
    return completer.future;
  }

  @override
  Future<AuthUser?> restore() async => null;

  @override
  Future<AuthUser> continueAsGuest() => throw UnimplementedError();

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

final class _FakeAnalytics implements AnalyticsService {
  final events = <({String name, Map<String, Object>? parameters})>[];

  @override
  Future<void> log(String name, [Map<String, Object>? parameters]) async {
    events.add((name: name, parameters: parameters));
  }
}

final class _FakeNotifications implements NotificationService {
  String? identifiedUserId;

  @override
  Stream<AppNotificationEvent> get events => const Stream.empty();

  @override
  Future<String?> initialize() async => null;

  @override
  Future<AppNotificationEvent?> takeInitialEvent() async => null;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> identify(String userId) async => identifiedUserId = userId;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> dispose() async {}
}

final class _FakePurchases implements PurchaseService {
  String? identifiedUserId;

  @override
  bool get enabled => true;

  @override
  Future<void> identify(String userId) async => identifiedUserId = userId;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isPremium() async => false;

  @override
  Future<bool> purchasePremium() async => false;

  @override
  Future<List<PremiumPlan>> loadPlans() async => const [];

  @override
  Future<PremiumStatus> loadStatus() async =>
      const PremiumStatus(state: PremiumAccessState.inactive);

  @override
  Future<bool> purchasePlan(PremiumPlanPeriod period) async => false;

  @override
  Future<bool> restorePurchases() async => false;

  @override
  Future<void> signOut() async {}
}
