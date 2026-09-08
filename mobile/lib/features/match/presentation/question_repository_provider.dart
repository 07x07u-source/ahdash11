import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/app_database.dart';
import '../data/drift_question_repository.dart';
import '../data/supabase_question_repository.dart';
import '../domain/question_repository.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final database = ref.watch(appDatabaseProvider);
  if (config.hasSupabase) {
    return SupabaseQuestionRepository(Supabase.instance.client, database);
  }
  return DriftQuestionRepository(database);
});
