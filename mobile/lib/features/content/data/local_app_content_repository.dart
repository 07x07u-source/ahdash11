import '../domain/app_content.dart';
import '../domain/app_content_repository.dart';

final class LocalAppContentRepository implements AppContentRepository {
  const LocalAppContentRepository();

  @override
  Future<AppContentBundle> refresh() async => AppContentBundle.defaults;

  @override
  Future<AppContentBundle?> readCached() async => AppContentBundle.defaults;
}
