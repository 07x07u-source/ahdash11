import 'auth_user.dart';

enum SocialProvider { google, apple }

enum SocialSignInFailureCode {
  canceled,
  network,
  configuration,
  missingToken,
  provider,
  timeout,
  unknown,
}

final class SocialSignInException implements Exception {
  const SocialSignInException(this.code);

  final SocialSignInFailureCode code;
}

sealed class SocialSignInResult {
  const SocialSignInResult();
}

final class SocialSignInAuthenticated extends SocialSignInResult {
  const SocialSignInAuthenticated(this.user);

  final AuthUser user;
}

/// Kept for Apple until the native Apple flow is introduced.
final class SocialSignInRedirectStarted extends SocialSignInResult {
  const SocialSignInRedirectStarted();
}

abstract interface class AuthRepository {
  Future<AuthUser?> restore();
  Future<AuthUser> continueAsGuest();
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  });
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider);
  Future<void> signOut();
  Future<void> deleteAccount();
}
