import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/app_database.dart';
import '../domain/app_content.dart';
import '../domain/app_content_repository.dart';

final class SupabaseAppContentRepository implements AppContentRepository {
  SupabaseAppContentRepository(this._client, this._database, this._supabaseUrl);

  static const _cacheKey = 'app_content.v1';

  final SupabaseClient _client;
  final AppDatabase _database;
  final String _supabaseUrl;

  @override
  Future<AppContentBundle?> readCached() async {
    return AppContentBundle.tryDecode(await _database.readSetting(_cacheKey));
  }

  @override
  Future<AppContentBundle> refresh() async {
    final response = await _client.rpc<Object?>('get_published_app_content');
    final rows = response is List
        ? response.whereType<Map<Object?, Object?>>().map(
            (row) => Map<String, Object?>.from(row),
          )
        : const Iterable<Map<String, Object?>>.empty();
    final bundle = AppContentBundle.fromRpcRows(
      rows,
      supabaseUrl: _supabaseUrl,
    );
    await _database.putSetting(_cacheKey, bundle.encode());
    return bundle;
  }
}
