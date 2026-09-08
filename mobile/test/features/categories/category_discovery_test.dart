import 'package:ahdash_11/features/categories/domain/category_discovery.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = CategoryDiscoveryEngine();
  final categories = [
    const QuizCategory(
      id: 'saudi-family',
      name: 'أَبطال السعودية',
      description: 'نجوم المنتخب',
      iconName: 'ball',
      accentColor: Colors.green,
      tags: ['لاعبون', 'Saudi'],
      countryCodes: ['SA'],
      audiences: ['family'],
      popularityScore: 90,
      recommended: true,
    ),
    const QuizCategory(
      id: 'world-kids',
      name: 'كأس العالم',
      description: 'مناسبات عالمية',
      iconName: 'cup',
      accentColor: Colors.blue,
      tags: ['FIFA'],
      regionCodes: ['GLOBAL'],
      audiences: ['kids'],
      popularityScore: 70,
    ),
    const QuizCategory(
      id: 'audio',
      name: 'صوت المعلق',
      description: 'تعرف على التعليق',
      iconName: 'audio',
      accentColor: Colors.amber,
      questionFormats: ['audio'],
      mechanicType: 'audio',
    ),
  ];

  test('Arabic search normalizes hamza, diacritics and searches tags', () {
    final result = engine.discover(
      categories: categories,
      query: const CategoryDiscoveryQuery(search: 'ابطال'),
    );
    expect(result.map((item) => item.id), ['saudi-family']);

    final latin = engine.discover(
      categories: categories,
      query: const CategoryDiscoveryQuery(search: 'fifa'),
    );
    expect(latin.single.id, 'world-kids');
  });

  test('audience collections are supplied as data and not UI branches', () {
    const collection = CategoryCollection(
      id: 'kids',
      labelAr: 'الأطفال',
      audienceCodes: {'kids'},
    );
    final result = engine.discover(
      categories: categories,
      query: const CategoryDiscoveryQuery(collection: collection),
    );
    expect(result.single.id, 'world-kids');
  });

  test(
    'random selection excludes disliked, favors favorites and has no duplicates',
    () {
      final result = engine.pickRandom(
        categories: categories,
        count: 2,
        excludedIds: const {'audio'},
        preferredIds: const {'world-kids'},
        recentlyPlayedIds: const {'saudi-family'},
        seed: 11,
      );
      expect(result.first.id, 'world-kids');
      expect(result.map((item) => item.id).toSet(), hasLength(2));
      expect(result.map((item) => item.id), isNot(contains('audio')));
    },
  );

  test('media and special filters use backend metadata', () {
    final result = engine.discover(
      categories: categories,
      query: const CategoryDiscoveryQuery(mediaOnly: true, specialOnly: true),
    );
    expect(result.single.id, 'audio');
  });
}
