import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/app_error_reporter.dart';
import '../../../core/services/app_services.dart';
import '../../../core/storage/app_database.dart';
import '../data/local_app_content_repository.dart';
import '../data/supabase_app_content_repository.dart';
import '../domain/app_content.dart';
import '../domain/app_content_repository.dart';

final appContentRepositoryProvider = Provider<AppContentRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase) return const LocalAppContentRepository();
  return SupabaseAppContentRepository(
    Supabase.instance.client,
    ref.watch(appDatabaseProvider),
    config.supabaseUrl,
  );
});

final appContentProvider =
    AsyncNotifierProvider<AppContentController, AppContentBundle>(
      AppContentController.new,
    );

final class AppContentController extends AsyncNotifier<AppContentBundle> {
  @override
  Future<AppContentBundle> build() async {
    final repository = ref.watch(appContentRepositoryProvider);
    final cached = await repository.readCached();
    scheduleMicrotask(() {
      if (ref.mounted) unawaited(refresh(silent: true));
    });
    return cached ?? AppContentBundle.defaults;
  }

  Future<void> refresh({bool silent = false}) async {
    final previous = state.value ?? AppContentBundle.defaults;
    try {
      final content = await ref.read(appContentRepositoryProvider).refresh();
      if (!ref.mounted) return;
      state = AsyncData(content);
    } catch (error, stackTrace) {
      unawaited(
        ref
            .read(appServicesProvider)
            .errors
            .report(
              severity: AppErrorSeverity.warning,
              category: AppErrorCategory.content,
              feature: 'published_content_refresh',
              error: error,
              stackTrace: stackTrace,
              screen: '/home',
              context: const {'operation': 'get_published_app_content'},
            ),
      );
      if (ref.mounted) state = AsyncData(previous);
    }
  }
}
