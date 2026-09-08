final class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.isGuest,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final bool isGuest;
  final String? email;
  final String? avatarUrl;
}
