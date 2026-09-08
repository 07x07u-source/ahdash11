import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_repository.dart';
import 'google_auth_diagnostics.dart';

final class NativeGoogleCredentials {
  const NativeGoogleCredentials({
    required this.idToken,
    required this.accessToken,
  });

  final String idToken;
  final String accessToken;
}

abstract interface class NativeGoogleAuthClient {
  Future<NativeGoogleCredentials> authenticate();
  Future<void> signOut();
}

/// Native Google authentication backed by google_sign_in 7.x.
///
/// Android reads the web OAuth client from google-services.json. iOS reads
/// GIDClientID from Info.plist. There are deliberately no client secrets or
/// broad Google API scopes in the application.
final class GoogleSignInAuthClient implements NativeGoogleAuthClient {
  GoogleSignInAuthClient({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static const _minimalScopes = <String>['email'];
  static const _authenticationTimeout = Duration(seconds: 90);

  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;
  var _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final pending = _initialization ??= _googleSignIn.initialize();
    try {
      await pending;
      _initialized = true;
    } finally {
      if (!_initialized) _initialization = null;
    }
  }

  @override
  Future<NativeGoogleCredentials> authenticate() async {
    try {
      GoogleAuthDiagnostics.stage('initialize.started');
      await _ensureInitialized().timeout(_authenticationTimeout);
      GoogleAuthDiagnostics.stage('initialize.success');
      if (!_googleSignIn.supportsAuthenticate()) {
        GoogleAuthDiagnostics.stage(
          'initialize.failure',
          code: 'authenticate_not_supported',
        );
        throw const SocialSignInException(
          SocialSignInFailureCode.configuration,
        );
      }

      GoogleAuthDiagnostics.stage('account_picker.started');
      final account = await _googleSignIn
          .authenticate(scopeHint: _minimalScopes)
          .timeout(_authenticationTimeout);
      GoogleAuthDiagnostics.stage('authentication.success');
      final idToken = account.authentication.idToken?.trim();
      if (idToken == null || idToken.isEmpty) {
        GoogleAuthDiagnostics.stage('id_token.missing');
        throw const SocialSignInException(SocialSignInFailureCode.missingToken);
      }
      GoogleAuthDiagnostics.stage('id_token.present');

      GoogleAuthDiagnostics.stage('authorization.started');
      final authorizationClient = account.authorizationClient;
      final authorization =
          await authorizationClient
              .authorizationForScopes(_minimalScopes)
              .timeout(_authenticationTimeout) ??
          await authorizationClient
              .authorizeScopes(_minimalScopes)
              .timeout(_authenticationTimeout);
      final accessToken = authorization.accessToken.trim();
      if (accessToken.isEmpty) {
        GoogleAuthDiagnostics.stage('access_token.missing');
        throw const SocialSignInException(SocialSignInFailureCode.missingToken);
      }
      GoogleAuthDiagnostics.stage('access_token.present');

      return NativeGoogleCredentials(
        idToken: idToken,
        accessToken: accessToken,
      );
    } on SocialSignInException {
      rethrow;
    } on TimeoutException {
      GoogleAuthDiagnostics.stage('timeout');
      throw const SocialSignInException(SocialSignInFailureCode.timeout);
    } on GoogleSignInException catch (error) {
      GoogleAuthDiagnostics.stage(
        'google.failure',
        code: GoogleAuthDiagnostics.safeGoogleCode(error),
      );
      throw SocialSignInException(_mapGoogleFailure(error.code));
    } on SocketException {
      GoogleAuthDiagnostics.stage('network.failure');
      throw const SocialSignInException(SocialSignInFailureCode.network);
    } on PlatformException catch (error) {
      final code = GoogleAuthDiagnostics.safePlatformCode(error.code);
      GoogleAuthDiagnostics.stage('platform.failure', code: code);
      throw SocialSignInException(switch (code) {
        'canceled' => SocialSignInFailureCode.canceled,
        'configuration' => SocialSignInFailureCode.configuration,
        'network' => SocialSignInFailureCode.network,
        _ => SocialSignInFailureCode.provider,
      });
    } catch (_) {
      GoogleAuthDiagnostics.stage('unknown.failure');
      throw const SocialSignInException(SocialSignInFailureCode.unknown);
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
    GoogleAuthDiagnostics.stage('local_sign_out.success');
  }

  SocialSignInFailureCode _mapGoogleFailure(GoogleSignInExceptionCode code) {
    return switch (code) {
      GoogleSignInExceptionCode.canceled ||
      GoogleSignInExceptionCode.interrupted => SocialSignInFailureCode.canceled,
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        SocialSignInFailureCode.configuration,
      GoogleSignInExceptionCode.uiUnavailable =>
        SocialSignInFailureCode.provider,
      _ => SocialSignInFailureCode.unknown,
    };
  }
}
