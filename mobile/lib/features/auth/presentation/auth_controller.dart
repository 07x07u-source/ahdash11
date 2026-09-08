import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/config/app_config.dart';
import '../../../core/services/app_error_reporter.dart';
import '../../../core/services/app_services.dart';
import '../data/development_auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/guest_capability_policy.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.hasSupabase) {
    return SupabaseAuthRepository(Supabase.instance.client);
  }
  return const DevelopmentAuthRepository();
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

final class AuthController extends AsyncNotifier<AuthUser?> {
  var _authActionInProgress = false;

  @override
  Future<AuthUser?> build() async {
    final user = await ref.watch(authRepositoryProvider).restore();
    if (user != null) await _identify(user);
    return user;
  }

  Future<void> continueAsGuest() async {
    if (_authActionInProgress) return;
    _authActionInProgress = true;
    try {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        final user = await ref.read(authRepositoryProvider).continueAsGuest();
        await _identify(user);
        await ref.read(appServicesProvider).analytics.log('login', {
          'method': 'guest',
        });
        return user;
      });
    } finally {
      _authActionInProgress = false;
    }
  }

  Future<void> signIn(String email, String password) async {
    if (_authActionInProgress) return;
    _authActionInProgress = true;
    try {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        final user = await ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password);
        await _identify(user);
        await ref.read(appServicesProvider).analytics.log('login', {
          'method': 'email',
        });
        return user;
      });
    } finally {
      _authActionInProgress = false;
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    if (_authActionInProgress) return;
    _authActionInProgress = true;
    try {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        final user = await ref
            .read(authRepositoryProvider)
            .signUp(email: email, password: password, username: username);
        await _identify(user);
        await ref.read(appServicesProvider).analytics.log('signup');
        return user;
      });
    } finally {
      _authActionInProgress = false;
    }
  }

  Future<bool> signInWithSocial(SocialProvider provider) async {
    if (_authActionInProgress) return false;
    _authActionInProgress = true;
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .signInWithSocial(provider);
      if (result is SocialSignInRedirectStarted) {
        state = AsyncData(previous);
        return false;
      }
      final user = (result as SocialSignInAuthenticated).user;
      await _identify(user);
      await ref.read(appServicesProvider).analytics.log('login', {
        'method': provider.name,
      });
      state = AsyncData(user);
      return true;
    } on SocialSignInException catch (error, stack) {
      if (error.code == SocialSignInFailureCode.canceled) {
        state = AsyncData(previous);
        return false;
      }
      unawaited(
        ref
            .read(appServicesProvider)
            .errors
            .report(
              severity: AppErrorSeverity.warning,
              category: AppErrorCategory.auth,
              feature: '${provider.name}_sign_in',
              error: error,
              stackTrace: stack,
              screen: '/auth',
            ),
      );
      state = AsyncError(error, stack);
      return false;
    } catch (error, stack) {
      unawaited(
        ref
            .read(appServicesProvider)
            .errors
            .report(
              severity: AppErrorSeverity.error,
              category: AppErrorCategory.auth,
              feature: '${provider.name}_sign_in',
              error: error,
              stackTrace: stack,
              screen: '/auth',
            ),
      );
      state = AsyncError(error, stack);
      return false;
    } finally {
      _authActionInProgress = false;
    }
  }

  Future<void> signOut() async {
    final services = ref.read(appServicesProvider);
    try {
      await services.notifications.signOut();
    } catch (_) {
      // Provider cleanup must not trap the user in an authenticated session.
    }
    try {
      if (services.purchases.enabled) await services.purchases.signOut();
    } catch (_) {
      // RevenueCat will reconcile identity at the next successful login.
    }
    try {
      await services.crashReporter.clearIdentity();
    } catch (_) {
      // Crash reporting must never block a valid sign-out.
    }
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  Future<void> deleteAccount() async {
    final services = ref.read(appServicesProvider);
    try {
      await services.notifications.signOut();
    } catch (_) {
      // The server-side deletion flow deactivates all remaining tokens.
    }
    try {
      await services.crashReporter.clearIdentity();
    } catch (_) {
      // Crash reporting must never block account deletion.
    }
    try {
      if (services.purchases.enabled) await services.purchases.signOut();
    } catch (_) {
      // Account deletion remains authoritative in Supabase.
    }
    await ref.read(authRepositoryProvider).deleteAccount();
    state = const AsyncData(null);
  }

  Future<void> _identify(AuthUser user) async {
    final services = ref.read(appServicesProvider);
    try {
      await services.crashReporter.identify(user.id);
    } catch (_) {
      // Authentication remains successful if telemetry is unavailable.
    }
    final policy = GuestCapabilityPolicy(user);
    if (!policy.hasAccount) return;
    try {
      await services.notifications.identify(user.id);
    } catch (_) {
      // A push-token outage must not block a valid authentication session.
    }
    try {
      await services.purchases.identify(user.id);
    } catch (_) {
      // Entitlements will be refreshed when the store is opened.
    }
  }
}
