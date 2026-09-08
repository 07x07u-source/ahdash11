final class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.username,
    required this.level,
    required this.xp,
    required this.coins,
    required this.rating,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.matches,
    required this.accuracy,
    required this.bestStreak,
    required this.currentStreak,
    required this.rank,
    this.displayName,
    this.favoriteClub,
    this.favoriteLeagueData,
    this.favoriteClubData,
    this.socialTeam,
    this.achievements = const [],
    this.avatarUrl,
    this.avatarJerseyColor,
    this.isPremium = false,
    this.tournamentsPlayed = 0,
    this.tournamentsWon = 0,
    this.questionsAnswered = 0,
    this.favoriteCategoryNames = const [],
    this.showFootballPreferences = true,
    this.availableStats = const {
      'matches',
      'wins',
      'tournaments_played',
      'tournaments_won',
      'questions_answered',
    },
  });

  factory PlayerProfile.fromJson(Map<String, Object?> json) => PlayerProfile(
    showFootballPreferences: json['show_football_preferences'] == true,
    availableStats: {
      for (final key in [
        'matches',
        'wins',
        'tournaments_played',
        'tournaments_won',
        'questions_answered',
      ])
        if (json[key] is num) key,
    },
    id: json['id']! as String,
    username: (json['username'] as String?) ?? 'لاعب 11',
    displayName: json['display_name'] as String?,
    level: (json['level'] as num?)?.round() ?? 1,
    xp: (json['xp'] as num?)?.round() ?? 0,
    coins: (json['coins'] as num?)?.round() ?? 0,
    rating: (json['rating'] as num?)?.round() ?? 1000,
    wins: (json['wins'] as num?)?.round() ?? 0,
    losses: (json['losses'] as num?)?.round() ?? 0,
    draws: (json['draws'] as num?)?.round() ?? 0,
    matches: (json['matches'] as num?)?.round() ?? 0,
    accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
    bestStreak: (json['best_streak'] as num?)?.round() ?? 0,
    currentStreak: (json['current_streak'] as num?)?.round() ?? 0,
    rank: (json['rank'] as num?)?.round() ?? 0,
    favoriteClub: json['favorite_club'] as String?,
    favoriteLeagueData: ProfileFootballChoice.fromValue(
      json['favorite_league_data'],
    ),
    favoriteClubData: ProfileFootballChoice.fromValue(
      json['favorite_club_data'],
    ),
    socialTeam: ProfileSocialTeam.fromValue(json['social_team']),
    achievements: (json['achievements'] as List? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(
          (item) =>
              ProfileAchievement.fromJson(Map<String, Object?>.from(item)),
        )
        .toList(growable: false),
    avatarUrl: json['avatar_url'] as String?,
    avatarJerseyColor: json['avatar_jersey_color'] as String?,
    isPremium: (json['is_premium'] as bool?) ?? false,
    tournamentsPlayed: (json['tournaments_played'] as num?)?.round() ?? 0,
    tournamentsWon: (json['tournaments_won'] as num?)?.round() ?? 0,
    questionsAnswered: (json['questions_answered'] as num?)?.round() ?? 0,
    favoriteCategoryNames:
        (json['favorite_category_names'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false),
  );

  final String id;
  final String username;
  final int level;
  final int xp;
  final int coins;
  final int rating;
  final int wins;
  final int losses;
  final int draws;
  final int matches;
  final double accuracy;
  final int bestStreak;
  final int currentStreak;
  final int rank;
  final String? displayName;
  final String? favoriteClub;
  final ProfileFootballChoice? favoriteLeagueData;
  final ProfileFootballChoice? favoriteClubData;
  final ProfileSocialTeam? socialTeam;
  final List<ProfileAchievement> achievements;
  final String? avatarUrl;
  final String? avatarJerseyColor;
  final bool isPremium;
  final int tournamentsPlayed;
  final int tournamentsWon;
  final int questionsAnswered;
  final List<String> favoriteCategoryNames;
  final bool showFootballPreferences;
  final Set<String> availableStats;

  String? get safeJerseyColor =>
      socialTeam?.primaryColor ??
      (showFootballPreferences ? favoriteClubData?.primaryColor : null) ??
      avatarJerseyColor;

  String get publicName =>
      displayName?.trim().isNotEmpty == true ? displayName! : username;
}

final class ProfileFootballChoice {
  const ProfileFootballChoice({
    required this.id,
    required this.nameAr,
    required this.primaryColor,
    required this.visualStatus,
    this.badgeText,
    this.logoUrl,
  });

  static ProfileFootballChoice? fromValue(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    final json = Map<String, Object?>.from(value);
    return ProfileFootballChoice(
      id: '${json['id']}',
      nameAr: '${json['name_ar'] ?? 'اختيار كروي'}',
      primaryColor: '${json['primary_color'] ?? '#B6FF3B'}',
      visualStatus: '${json['visual_status'] ?? 'fallback'}',
      badgeText: json['badge_text'] as String?,
      logoUrl: json['logo_url'] as String?,
    );
  }

  final String id;
  final String nameAr;
  final String primaryColor;
  final String visualStatus;
  final String? badgeText;
  final String? logoUrl;
}

final class ProfileSocialTeam {
  const ProfileSocialTeam({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.badgeSeed,
    required this.role,
  });

  static ProfileSocialTeam? fromValue(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    final json = Map<String, Object?>.from(value);
    return ProfileSocialTeam(
      id: '${json['id']}',
      name: '${json['name'] ?? 'فريقي'}',
      primaryColor: '${json['primary_color'] ?? '#B6FF3B'}',
      badgeSeed: '${json['badge_seed'] ?? '11'}',
      role: '${json['role'] ?? 'member'}',
    );
  }

  final String id;
  final String name;
  final String primaryColor;
  final String badgeSeed;
  final String role;
}

final class ProfileAchievement {
  const ProfileAchievement({
    required this.slug,
    required this.nameAr,
    required this.descriptionAr,
    required this.artworkKey,
  });

  factory ProfileAchievement.fromJson(Map<String, Object?> json) =>
      ProfileAchievement(
        slug: '${json['slug']}',
        nameAr: '${json['name_ar'] ?? 'إنجاز'}',
        descriptionAr: '${json['description_ar'] ?? ''}',
        artworkKey: '${json['artwork_key'] ?? 'first_win'}',
      );

  final String slug;
  final String nameAr;
  final String descriptionAr;
  final String artworkKey;
}
