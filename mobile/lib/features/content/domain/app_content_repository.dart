import 'app_content.dart';

abstract interface class AppContentRepository {
  Future<AppContentBundle?> readCached();

  Future<AppContentBundle> refresh();
}
