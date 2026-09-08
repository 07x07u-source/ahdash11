import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final class DevelopmentAuthRepository implements AuthRepository {
  const DevelopmentAuthRepository();

  static const _idKey = 'development_user_id';
  static const _nameKey = 'development_username';
  static const _guestKey = 'development_is_guest';

  @override
  Future<AuthUser> continueAsGuest() async {
    final preferences = await SharedPreferences.getInstance();
    final user = AuthUser(
      id: const Uuid().v4(),
      username: 'لاعب 11',
      isGuest: true,
    );
    await _persist(preferences, user);
    return user;
  }

  @override
  Future<void> deleteAccount() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_idKey);
    await preferences.remove(_nameKey);
    await preferences.remove(_guestKey);
  }

  @override
  Future<AuthUser?> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final id = preferences.getString(_idKey);
    if (id == null) return null;
    return AuthUser(
      id: id,
      username: preferences.getString(_nameKey) ?? 'لاعب 11',
      isGuest: preferences.getBool(_guestKey) ?? true,
    );
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final user = AuthUser(
      id: preferences.getString(_idKey) ?? const Uuid().v4(),
      username: email.split('@').first,
      isGuest: false,
      email: email,
    );
    await _persist(preferences, user);
    return user;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final user = AuthUser(
      id: preferences.getString(_idKey) ?? const Uuid().v4(),
      username: username,
      isGuest: false,
      email: email,
    );
    await _persist(preferences, user);
    return user;
  }

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) async {
    final preferences = await SharedPreferences.getInstance();
    final user = AuthUser(
      id: preferences.getString(_idKey) ?? const Uuid().v4(),
      username: provider == SocialProvider.google ? 'لاعب قوقل' : 'لاعب Apple',
      isGuest: false,
      email: provider == SocialProvider.google
          ? 'google-player@example.local'
          : 'apple-player@example.local',
    );
    await _persist(preferences, user);
    return SocialSignInAuthenticated(user);
  }

  @override
  Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_idKey);
    await preferences.remove(_nameKey);
    await preferences.remove(_guestKey);
  }

  Future<void> _persist(SharedPreferences preferences, AuthUser user) async {
    await preferences.setString(_idKey, user.id);
    await preferences.setString(_nameKey, user.username);
    await preferences.setBool(_guestKey, user.isGuest);
  }
}
