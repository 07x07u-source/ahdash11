import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/app_database.dart';
import '../../../shared/domain/category.dart';
import '../domain/categories_repository.dart';
import 'drift_categories_repository.dart';

final class SupabaseCategoriesRepository implements CategoriesRepository {
  SupabaseCategoriesRepository(
    this._client,
    this._database, {
    this.allowDemoFallback = true,
  });

  final SupabaseClient _client;
  final AppDatabase _database;
  final bool allowDemoFallback;

  @override
  Future<List<QuizCategory>> loadCategories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cache = await _database.readCategories();
      if (cache.isNotEmpty) {
        final categories = cache
            .map(QuizCategory.fromJson)
            .where(
              (category) => allowDemoFallback || !category.id.endsWith('-demo'),
            )
            .toList(growable: false);
        if (categories.isNotEmpty || !allowDemoFallback) return categories;
      }
    }
    try {
      final source = await _loadRemoteRows();
      const accents = [
        0xFFB6FF3B,
        0xFFFFC857,
        0xFF77B8FF,
        0xFFC89BFF,
        0xFFFF7A90,
        0xFF55D6BE,
      ];
      final children = <String, List<String>>{};
      for (final row in source.where((row) => row['parent_id'] != null)) {
        children
            .putIfAbsent('${row['parent_id']}', () => <String>[])
            .add('${row['name_ar']}');
      }
      var categoryIndex = 0;
      final rows = source
          .where((row) => row['parent_id'] == null)
          .map((row) {
            final canonical = <String, Object?>{
              'id': row['id'],
              'slug': row['slug'],
              'name': row['name_ar'],
              'description': row['description_ar'],
              'icon_name': row['icon_key'],
              'image_url': row['image_url'],
              'cover_focal_x': row['cover_focal_x'] ?? 0.5,
              'cover_focal_y': row['cover_focal_y'] ?? 0.5,
              'accent_color': accents[categoryIndex % accents.length],
              'subcategories': children['${row['id']}'] ?? const <String>[],
              'group_key': row['group_key'] ?? 'other',
              'season_label': row['season_label'],
              'question_formats':
                  row['question_formats'] ?? const ['open_answer'],
              'is_favorite_eligible': row['is_favorite_eligible'] ?? true,
              'access_tier': row['access_tier'] ?? 'free',
              'is_featured': row['is_featured'] ?? false,
              'is_new': row['is_new'] ?? false,
              'editorial_status': row['editorial_status'] ?? 'published',
              'is_free_rotation': row['is_free_rotation'] ?? false,
              'tags': row['tags'] ?? const <String>[],
              'country_codes': row['country_codes'] ?? const <String>[],
              'region_codes': row['region_codes'] ?? const <String>[],
              'audience_codes': row['audience_codes'] ?? const ['general'],
              'popularity_score': row['popularity_score'] ?? 0,
              'is_recommended': row['is_recommended'] ?? false,
              'gameplay_instructions_ar': row['gameplay_instructions_ar'],
              'mechanic_type': row['mechanic_type'] ?? 'text',
              'added_at': row['added_at'],
            };
            categoryIndex += 1;
            return canonical;
          })
          .toList(growable: false);
      if (rows.isEmpty) {
        return await (allowDemoFallback
            ? DriftCategoriesRepository(_database).loadCategories()
            : Future.value(const <QuizCategory>[]));
      }
      await _database.replaceCategories(rows);
      return rows.map(QuizCategory.fromJson).toList(growable: false);
    } catch (_) {
      final cache = await _database.readCategories();
      if (cache.isNotEmpty) {
        final categories = cache
            .map(QuizCategory.fromJson)
            .where(
              (category) => allowDemoFallback || !category.id.endsWith('-demo'),
            )
            .toList(growable: false);
        if (categories.isNotEmpty || !allowDemoFallback) return categories;
      }
      if (!allowDemoFallback) rethrow;
      return DriftCategoriesRepository(_database).loadCategories();
    }
  }

  Future<List<Map<String, Object?>>> _loadRemoteRows() async {
    try {
      final response = await _client
          .from('categories')
          .select(
            'id,parent_id,slug,name_ar,description_ar,icon_key,image_url,cover_focal_x,cover_focal_y,sort_order,'
            'group_key,season_label,question_formats,is_favorite_eligible,'
            'access_tier,is_featured,is_new,editorial_status,is_free_rotation,'
            'tags,country_codes,region_codes,audience_codes,popularity_score,'
            'is_recommended,gameplay_instructions_ar,mechanic_type,added_at',
          )
          .eq('is_active', true)
          .eq('editorial_status', 'published')
          .order('is_featured', ascending: false)
          .order('sort_order');
      return response.whereType<Map<String, Object?>>().toList(growable: false);
    } on PostgrestException catch (error) {
      // The release remains compatible during the window before the owner
      // manually applies the Party V2 migration to the remote project.
      if (error.code != '42703') rethrow;
      return _loadPartyV2OrLegacyRows();
    }
  }

  Future<List<Map<String, Object?>>> _loadPartyV2OrLegacyRows() async {
    try {
      final response = await _client
          .from('categories')
          .select(
            'id,parent_id,slug,name_ar,description_ar,icon_key,image_url,cover_focal_x,cover_focal_y,sort_order,'
            'group_key,season_label,question_formats,is_favorite_eligible,'
            'access_tier,is_featured,is_new,editorial_status,is_free_rotation',
          )
          .eq('is_active', true)
          .eq('editorial_status', 'published')
          .order('is_featured', ascending: false)
          .order('sort_order');
      return response.whereType<Map<String, Object?>>().toList(growable: false);
    } on PostgrestException catch (error) {
      if (error.code != '42703') rethrow;
      final response = await _client
          .from('categories')
          .select(
            'id,parent_id,slug,name_ar,description_ar,icon_key,image_url,sort_order',
          )
          .eq('is_active', true)
          .order('sort_order');
      return response.whereType<Map<String, Object?>>().toList(growable: false);
    }
  }
}
