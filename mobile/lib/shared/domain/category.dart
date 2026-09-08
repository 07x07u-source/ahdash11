import 'package:flutter/material.dart';

final class QuizCategory {
  const QuizCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.accentColor,
    this.slug = '',
    this.imageUrl,
    this.focalX = 0.5,
    this.focalY = 0.5,
    this.subcategories = const [],
    this.groupKey = 'other',
    this.seasonLabel,
    this.questionFormats = const ['open_answer'],
    this.favoriteEligible = true,
    this.accessTier = 'free',
    this.featured = false,
    this.isNew = false,
    this.editorialStatus = 'published',
    this.freeRotation = false,
    this.tags = const [],
    this.countryCodes = const [],
    this.regionCodes = const [],
    this.audiences = const ['general'],
    this.popularityScore = 0,
    this.recommended = false,
    this.gameplayInstructions,
    this.mechanicType = 'text',
    this.addedAt,
  });

  factory QuizCategory.fromJson(Map<String, Object?> json) {
    final rawSubcategories = json['subcategories'];
    final rawColor = json['accent_color'];
    final colorValue = switch (rawColor) {
      final int value => value,
      final String value =>
        int.tryParse(value.replaceFirst('#', '0xFF')) ?? 0xFFB6FF3B,
      _ => 0xFFB6FF3B,
    };
    return QuizCategory(
      id: json['id']! as String,
      name: json['name']! as String,
      description: (json['description'] as String?) ?? '',
      iconName: (json['icon_name'] as String?) ?? 'sports_soccer',
      accentColor: Color(colorValue),
      slug: (json['slug'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      focalX: (json['cover_focal_x'] as num?)?.toDouble() ?? 0.5,
      focalY: (json['cover_focal_y'] as num?)?.toDouble() ?? 0.5,
      groupKey: (json['group_key'] as String?) ?? 'other',
      seasonLabel: json['season_label'] as String?,
      questionFormats:
          (json['question_formats'] as List?)?.whereType<String>().toList() ??
          const ['open_answer'],
      favoriteEligible: json['is_favorite_eligible'] as bool? ?? true,
      accessTier: (json['access_tier'] as String?) ?? 'free',
      featured: json['is_featured'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      editorialStatus: (json['editorial_status'] as String?) ?? 'published',
      freeRotation: json['is_free_rotation'] as bool? ?? false,
      tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
      countryCodes:
          (json['country_codes'] as List?)?.whereType<String>().toList() ??
          const [],
      regionCodes:
          (json['region_codes'] as List?)?.whereType<String>().toList() ??
          const [],
      audiences:
          (json['audience_codes'] as List?)?.whereType<String>().toList() ??
          const ['general'],
      popularityScore: (json['popularity_score'] as num?)?.toInt() ?? 0,
      recommended: json['is_recommended'] as bool? ?? false,
      gameplayInstructions: json['gameplay_instructions_ar'] as String?,
      mechanicType: (json['mechanic_type'] as String?) ?? 'text',
      addedAt: DateTime.tryParse('${json['added_at'] ?? ''}'),
      subcategories: rawSubcategories is List
          ? rawSubcategories
                .map(
                  (item) => switch (item) {
                    final String name => name,
                    final Map<String, Object?> map => map['name'] as String?,
                    _ => null,
                  },
                )
                .whereType<String>()
                .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String name;
  final String description;
  final String iconName;
  final Color accentColor;
  final String slug;
  final String? imageUrl;
  final double focalX;
  final double focalY;
  Alignment get focalAlignment =>
      Alignment((focalX.clamp(0, 1) * 2) - 1, (focalY.clamp(0, 1) * 2) - 1);
  final List<String> subcategories;
  final String groupKey;
  final String? seasonLabel;
  final List<String> questionFormats;
  final bool favoriteEligible;
  final String accessTier;
  final bool featured;
  final bool isNew;
  final String editorialStatus;
  final bool freeRotation;
  final List<String> tags;
  final List<String> countryCodes;
  final List<String> regionCodes;
  final List<String> audiences;
  final int popularityScore;
  final bool recommended;
  final String? gameplayInstructions;
  final String mechanicType;
  final DateTime? addedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon_name': iconName,
    'accent_color': accentColor.toARGB32(),
    'slug': slug,
    'image_url': imageUrl,
    'cover_focal_x': focalX,
    'cover_focal_y': focalY,
    'subcategories': subcategories,
    'group_key': groupKey,
    'season_label': seasonLabel,
    'question_formats': questionFormats,
    'is_favorite_eligible': favoriteEligible,
    'access_tier': accessTier,
    'is_featured': featured,
    'is_new': isNew,
    'editorial_status': editorialStatus,
    'is_free_rotation': freeRotation,
    'tags': tags,
    'country_codes': countryCodes,
    'region_codes': regionCodes,
    'audience_codes': audiences,
    'popularity_score': popularityScore,
    'is_recommended': recommended,
    'gameplay_instructions_ar': gameplayInstructions,
    'mechanic_type': mechanicType,
    'added_at': addedAt?.toUtc().toIso8601String(),
  };
}
