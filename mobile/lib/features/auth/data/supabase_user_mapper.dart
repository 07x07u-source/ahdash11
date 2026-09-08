import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../domain/auth_user.dart';
import '../domain/guest_capability_policy.dart';

GuestCapabilityPolicy supabaseCapabilities(User? user) =>
    GuestCapabilityPolicy(user == null ? null : mapSupabaseUser(user));

AuthUser mapSupabaseUser(User user) {
  final metadata = user.userMetadata ?? const <String, dynamic>{};
  return AuthUser(
    id: user.id,
    username: _username(metadata, user.email),
    isGuest: user.isAnonymous,
    email: user.email,
    avatarUrl: _firstText(metadata, const ['avatar_url', 'picture']),
  );
}

String _username(Map<String, dynamic> metadata, String? email) {
  final value =
      _firstText(metadata, const [
        'username',
        'full_name',
        'name',
        'preferred_username',
      ]) ??
      email?.split('@').first ??
      'لاعب 11';
  final cleaned = value.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '').trim();
  if (cleaned.isEmpty) return 'لاعب 11';
  return cleaned.length <= 40 ? cleaned : cleaned.substring(0, 40);
}

String? _firstText(Map<String, dynamic> metadata, List<String> keys) {
  for (final key in keys) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
