final class FootballLeague {
  const FootballLeague({
    required this.id,
    required this.nameAr,
    required this.countryNameAr,
    required this.badgeText,
    required this.primaryColor,
    this.nameEn,
    this.logoUrl,
    this.visualStatus = 'fallback',
  });

  factory FootballLeague.fromJson(Map<String, Object?> json) => FootballLeague(
    id: '${json['id']}',
    nameAr: '${json['name_ar'] ?? 'دوري'}',
    countryNameAr: '${json['country_name_ar'] ?? ''}',
    badgeText: '${json['badge_text'] ?? '11'}',
    primaryColor: '${json['primary_color'] ?? '#B6FF3B'}',
    nameEn: json['name_en'] as String?,
    logoUrl: json['logo_url'] as String?,
    visualStatus: '${json['visual_status'] ?? 'fallback'}',
  );

  final String id;
  final String nameAr;
  final String countryNameAr;
  final String badgeText;
  final String primaryColor;
  final String? nameEn;
  final String? logoUrl;
  final String visualStatus;
  String? get safeLogoUrl =>
      ['licensed', 'custom'].contains(visualStatus) ? logoUrl : null;
}

final class FootballClub {
  const FootballClub({
    required this.id,
    required this.leagueId,
    required this.nameAr,
    required this.leagueNameAr,
    required this.badgeText,
    required this.primaryColor,
    this.nameEn,
    this.logoUrl,
    this.visualStatus = 'fallback',
  });

  factory FootballClub.fromJson(Map<String, Object?> json) => FootballClub(
    id: '${json['id']}',
    leagueId: '${json['league_id']}',
    nameAr: '${json['name_ar'] ?? 'نادي'}',
    leagueNameAr: '${json['league_name_ar'] ?? ''}',
    badgeText: '${json['badge_text'] ?? '11'}',
    primaryColor: '${json['primary_color'] ?? '#B6FF3B'}',
    nameEn: json['name_en'] as String?,
    logoUrl: json['logo_url'] as String?,
    visualStatus: '${json['visual_status'] ?? 'fallback'}',
  );

  final String id;
  final String leagueId;
  final String nameAr;
  final String leagueNameAr;
  final String badgeText;
  final String primaryColor;
  final String? nameEn;
  final String? logoUrl;
  final String visualStatus;
  String? get safeLogoUrl =>
      ['licensed', 'custom'].contains(visualStatus) ? logoUrl : null;
}

final class FootballPreferences {
  const FootballPreferences({
    this.leagueId,
    this.clubId,
    this.showPublicly = true,
  });

  factory FootballPreferences.fromJson(Map<String, Object?> json) =>
      FootballPreferences(
        leagueId: json['league_id'] as String?,
        clubId: json['club_id'] as String?,
        showPublicly: json['show_publicly'] as bool? ?? true,
      );

  final String? leagueId;
  final String? clubId;
  final bool showPublicly;
}
