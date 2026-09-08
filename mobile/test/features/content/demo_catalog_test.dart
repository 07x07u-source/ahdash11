import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/features/categories/data/drift_categories_repository.dart';
import 'package:ahdash_11/features/match/data/drift_question_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled demo catalog is complete enough for a classic game', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final categories = await DriftCategoriesRepository(
      database,
    ).loadCategories();
    final questions = await DriftQuestionRepository(database).loadSoloPool();

    expect(categories, hasLength(6));
    expect(questions.length, greaterThanOrEqualTo(36));
    expect(questions.map((question) => question.id).toSet(), hasLength(42));

    for (final category in categories) {
      expect(category.slug, isNotEmpty);
      expect(category.imageUrl, startsWith('assets/'));
      expect(category.tags, isNotEmpty);
      expect(category.audiences, isNotEmpty);
      expect(category.questionFormats, isNotEmpty);
      expect(category.popularityScore, greaterThan(0));
      expect(
        questions.where((question) => question.categoryId == category.id),
        hasLength(greaterThanOrEqualTo(6)),
        reason: 'Each selectable demo category must fill its six board cells.',
      );
    }
  });

  test('bundled demo data is persisted for offline reuse', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await DriftCategoriesRepository(database).loadCategories();
    await DriftQuestionRepository(database).loadSoloPool();

    expect(await database.readCategories(), hasLength(6));
    expect(await database.readQuestions(), hasLength(42));
  });

  test(
    'production-safe category repository never seeds demo content',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final categories = await DriftCategoriesRepository(
        database,
        seedDemo: false,
      ).loadCategories();

      expect(categories, isEmpty);
      expect(await database.readCategories(), isEmpty);
    },
  );
}
