import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/app_error_reporter.dart';
import '../../../core/services/app_services.dart';
import '../../../core/storage/app_database.dart';
import '../../../shared/domain/category.dart';
import '../data/drift_categories_repository.dart';
import '../data/supabase_categories_repository.dart';
import '../domain/categories_repository.dart';
import '../domain/category_discovery.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final database = ref.watch(appDatabaseProvider);
  if (config.hasSupabase) {
    return SupabaseCategoriesRepository(
      Supabase.instance.client,
      database,
      allowDemoFallback: !config.isProduction,
    );
  }
  return DriftCategoriesRepository(database, seedDemo: !config.isProduction);
});

final categoriesProvider =
    AsyncNotifierProvider<CategoriesController, List<QuizCategory>>(
      CategoriesController.new,
    );

final categoryCollectionsProvider = FutureProvider<List<CategoryCollection>>((
  ref,
) async {
  if (!ref.read(appConfigProvider).hasSupabase) return const [];
  try {
    final response = await Supabase.instance.client
        .from('category_collections')
        .select(
          'id,label_ar,audience_codes,country_codes,region_codes,group_keys,sort_order',
        )
        .eq('is_active', true)
        .order('sort_order');
    return response
        .whereType<Map<String, Object?>>()
        .map(CategoryCollection.fromJson)
        .where((value) => value.id.isNotEmpty && value.labelAr.isNotEmpty)
        .toList(growable: false);
  } catch (_) {
    // The browser continues with category metadata before this additive table
    // is deployed to the remote project.
    return const [];
  }
});

final class CategoriesController extends AsyncNotifier<List<QuizCategory>> {
  @override
  Future<List<QuizCategory>> build() async {
    final repository = ref.watch(categoriesRepositoryProvider);
    final cached = await repository.loadCategories();
    scheduleMicrotask(() {
      if (ref.mounted) unawaited(refresh());
    });
    return cached;
  }

  Future<void> refresh() async {
    final previous = state.value ?? const <QuizCategory>[];
    try {
      final categories = await ref
          .read(categoriesRepositoryProvider)
          .loadCategories(forceRefresh: true);
      if (ref.mounted) state = AsyncData(categories);
    } catch (error, stackTrace) {
      unawaited(
        ref
            .read(appServicesProvider)
            .errors
            .report(
              severity: AppErrorSeverity.warning,
              category: AppErrorCategory.content,
              feature: 'categories_refresh',
              error: error,
              stackTrace: stackTrace,
              screen: '/categories',
            ),
      );
      if (!ref.mounted) return;
      state = previous.isEmpty
          ? AsyncError(error, stackTrace)
          : AsyncData(previous);
    }
  }
}
