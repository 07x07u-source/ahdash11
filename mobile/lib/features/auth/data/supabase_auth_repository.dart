import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'google_auth_diagnostics.dart';
import 'native_google_auth_client.dart';
import 'supabase_user_mapper.dart';

final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._client, {
    NativeGoogleAuthClient? googleAuthClient,
  }) : _googleAuthClient = googleAuthClient ?? GoogleSignInAuthClient();

  final SupabaseClient _client;
  final NativeGoogleAuthClient _googleAuthClient;

  @override
  Future<AuthUser> continueAsGuest() async {
    final response = await _client.auth.signInAnonymously();
    return mapSupabaseUser(response.user!);
  }

  @override
  Future<void> deleteAccount() async {
    final wasGoogle = _isGoogleUser(_client.auth.currentUser);
    await _client.functions.invoke('delete-account', body: const {});
    await _client.auth.signOut();
    if (wasGoogle) await _safeGoogleSignOut();
  }

  @override
  Future<AuthUser?> restore() async {
    GoogleAuthDiagnostics.stage('session_restore.started');
    final user = _client.auth.currentUser;
    if (user == null) {
      GoogleAuthDiagnostics.stage('session_restore.empty');
      return null;
    }
    GoogleAuthDiagnostics.stage('session_restore.success');
    return mapSupabaseUser(user);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return mapSupabaseUser(response.user!);
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final current = _client.auth.currentUser;
    if (current?.isAnonymous ?? false) {
      final response = await _client.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          data: {'username': username},
        ),
      );
      return mapSupabaseUser(response.user!);
    }
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    return mapSupabaseUser(response.user!);
  }

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) async {
    if (provider == SocialProvider.apple) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.ahdash.eleven://login-callback',
      );
      return const SocialSignInRedirectStarted();
    }

    final credentials = await _googleAuthClient.authenticate();
    try {
      GoogleAuthDiagnostics.stage('supabase_exchange.started');
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: credentials.idToken,
        accessToken: credentials.accessToken,
      );
      final user = response.user;
      if (user == null) {
        GoogleAuthDiagnostics.stage('supabase_session.missing');
        throw const SocialSignInException(SocialSignInFailureCode.provider);
      }
      GoogleAuthDiagnostics.stage('supabase_session.success');
      GoogleAuthDiagnostics.stage('profile_mapping.success');
      return SocialSignInAuthenticated(mapSupabaseUser(user));
    } on SocialSignInException {
      rethrow;
    } on AuthException catch (error) {
      GoogleAuthDiagnostics.stage(
        'supabase_exchange.failure',
        code: error.statusCode,
      );
      throw const SocialSignInException(SocialSignInFailureCode.provider);
    }
  }

  @override
  Future<void> signOut() async {
    final wasGoogle = _isGoogleUser(_client.auth.currentUser);
    await _client.auth.signOut();
    if (wasGoogle) await _safeGoogleSignOut();
  }

  bool _isGoogleUser(User? user) {
    if (user == null) return false;
    final provider = user.appMetadata['provider'];
    final providers = user.appMetadata['providers'];
    return provider == 'google' ||
        (providers is List && providers.contains('google'));
  }

  Future<void> _safeGoogleSignOut() async {
    try {
      await _googleAuthClient.signOut();
    } catch (_) {
      // Supabase is authoritative for the application session. A local Google
      // cleanup failure must not keep the player signed into Ahdash.
    }
  }
}
