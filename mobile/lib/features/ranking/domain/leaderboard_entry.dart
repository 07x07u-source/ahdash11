final class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.rating,
    required this.tier,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, Object?> json) =>
      LeaderboardEntry(
        rank: (json['rank']! as num).round(),
        userId: json['user_id']! as String,
        username: json['username']! as String,
        rating: (json['rating']! as num).round(),
        tier: (json['tier'] as String?) ?? 'Bronze',
        avatarUrl: json['avatar_url'] as String?,
      );

  final int rank;
  final String userId;
  final String username;
  final int rating;
  final String tier;
  final String? avatarUrl;
}
