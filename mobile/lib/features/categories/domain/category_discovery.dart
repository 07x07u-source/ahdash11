import 'dart:math';

import '../../../shared/domain/category.dart';
import '../../game/domain/answer_evaluator.dart';

enum CategorySort { editorial, newest, popular, recommended, recentlyPlayed }

final class CategoryCollection {
  const CategoryCollection({
    required this.id,
    required this.labelAr,
    this.audienceCodes = const {},
    this.countryCodes = const {},
    this.regionCodes = const {},
    this.groupKeys = const {},
  });

  factory CategoryCollection.fromJson(Map<String, Object?> json) =>
      CategoryCollection(
        id: '${json['id'] ?? ''}',
        labelAr: '${json['label_ar'] ?? ''}',
        audienceCodes:
            (json['audience_codes'] as List?)?.whereType<String>().toSet() ??
            const {},
        countryCodes:
            (json['country_codes'] as List?)?.whereType<String>().toSet() ??
            const {},
        regionCodes:
            (json['region_codes'] as List?)?.whereType<String>().toSet() ??
            const {},
        groupKeys:
            (json['group_keys'] as List?)?.whereType<String>().toSet() ??
            const {},
      );

  final String id;
  final String labelAr;
  final Set<String> audienceCodes;
  final Set<String> countryCodes;
  final Set<String> regionCodes;
  final Set<String> groupKeys;

  bool matches(QuizCategory category) =>
      (audienceCodes.isEmpty ||
          audienceCodes.intersection(category.audiences.toSet()).isNotEmpty) &&
      (countryCodes.isEmpty ||
          countryCodes
              .intersection(category.countryCodes.toSet())
              .isNotEmpty) &&
      (regionCodes.isEmpty ||
          regionCodes.intersection(category.regionCodes.toSet()).isNotEmpty) &&
      (groupKeys.isEmpty || groupKeys.contains(category.groupKey));
}

final class CategoryDiscoveryQuery {
  const CategoryDiscoveryQuery({
    this.search = '',
    this.collection,
    this.favoritesOnly = false,
    this.mediaOnly = false,
    this.specialOnly = false,
    this.sort = CategorySort.editorial,
  });

  final String search;
  final CategoryCollection? collection;
  final bool favoritesOnly;
  final bool mediaOnly;
  final bool specialOnly;
  final CategorySort sort;
}

final class CategoryDiscoveryEngine {
  const CategoryDiscoveryEngine();

  List<QuizCategory> discover({
    required List<QuizCategory> categories,
    required CategoryDiscoveryQuery query,
    Set<String> favoriteIds = const {},
    Map<String, DateTime> recentlyPlayed = const {},
  }) {
    final needle = normalizeSearch(query.search);
    final rows = categories
        .where((category) {
          final haystack = normalizeSearch(
            [
              category.name,
              category.description,
              category.slug,
              ...category.tags,
              ...category.subcategories,
            ].join(' '),
          );
          if (needle.isNotEmpty && !haystack.contains(needle)) return false;
          if (query.collection?.matches(category) == false) return false;
          if (query.favoritesOnly && !favoriteIds.contains(category.id)) {
            return false;
          }
          if (query.mediaOnly &&
              !category.questionFormats.any(
                (value) => const {
                  'image',
                  'image_crop',
                  'image_blur',
                  'audio',
                  'video',
                }.contains(value),
              )) {
            return false;
          }
          if (query.specialOnly && category.mechanicType == 'text') {
            return false;
          }
          return true;
        })
        .toList(growable: true);

    switch (query.sort) {
      case CategorySort.editorial:
        break;
      case CategorySort.newest:
        rows.sort((left, right) {
          if (left.isNew != right.isNew) return left.isNew ? -1 : 1;
          return (right.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                left.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
              );
        });
      case CategorySort.popular:
        rows.sort(
          (left, right) =>
              right.popularityScore.compareTo(left.popularityScore),
        );
      case CategorySort.recommended:
        rows.sort((left, right) {
          if (left.recommended != right.recommended) {
            return left.recommended ? -1 : 1;
          }
          return right.popularityScore.compareTo(left.popularityScore);
        });
      case CategorySort.recentlyPlayed:
        rows.sort(
          (left, right) =>
              (recentlyPlayed[right.id] ??
                      DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(
                    recentlyPlayed[left.id] ??
                        DateTime.fromMillisecondsSinceEpoch(0),
                  ),
        );
    }
    return rows;
  }

  List<QuizCategory> pickRandom({
    required List<QuizCategory> categories,
    required int count,
    Set<String> excludedIds = const {},
    Set<String> preferredIds = const {},
    Set<String> recentlyPlayedIds = const {},
    int? seed,
  }) {
    if (count <= 0) return const [];
    final random = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final candidates =
        categories
            .where((category) => !excludedIds.contains(category.id))
            .toList(growable: true)
          ..shuffle(random);
    candidates.sort((left, right) {
      final leftRank = _randomRank(left.id, preferredIds, recentlyPlayedIds);
      final rightRank = _randomRank(right.id, preferredIds, recentlyPlayedIds);
      return leftRank.compareTo(rightRank);
    });
    return candidates.take(count).toList(growable: false);
  }

  int _randomRank(
    String id,
    Set<String> preferredIds,
    Set<String> recentlyPlayedIds,
  ) =>
      (preferredIds.contains(id) ? -100 : 0) +
      (recentlyPlayedIds.contains(id) ? 100 : 0);

  static String normalizeSearch(String value) =>
      AnswerEvaluator.normalizeArabic(value);
}
