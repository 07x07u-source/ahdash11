import '../../../shared/domain/category.dart';

abstract interface class CategoriesRepository {
  Future<List<QuizCategory>> loadCategories({bool forceRefresh = false});
}
