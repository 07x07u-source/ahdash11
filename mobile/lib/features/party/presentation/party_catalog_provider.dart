import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/app_database.dart';
import '../../../shared/domain/category.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../game/domain/game_rules.dart';
import '../../match/data/drift_question_repository.dart';
import '../../match/domain/quiz_question.dart';
import '../../match/presentation/question_repository_provider.dart';
import '../../premium/presentation/premium_access_provider.dart';
import '../domain/party_game.dart';
import '../domain/party_game_engine.dart';

const _partyPackCacheKey = 'party_question_pack_cache_v1';

final partyEntitlementProvider = FutureProvider<bool>((ref) async {
  return (await ref.watch(premiumAccessProvider.future)).hasAccess;
});

final partyRuntimeSettingsProvider = FutureProvider<PartyRuntimeSettings>((
  ref,
) async {
  if (!ref.read(appConfigProvider).hasSupabase) {
    return const PartyRuntimeSettings();
  }
  try {
    final response = await Supabase.instance.client
        .from('game_settings')
        .select('key,value')
        .inFilter('key', const [
          'party.tiebreaker_enabled',
          'party.rule_config',
        ]);
    final values = <String, Object?>{
      for (final row in response.whereType<Map<String, Object?>>())
        if (row['key'] case final String key) key: row['value'],
    };
    final tieBreakerValue = values['party.tiebreaker_enabled'];
    final ruleValue = values['party.rule_config'];
    final ruleJson = switch (ruleValue) {
      final Map<Object?, Object?> value => Map<String, Object?>.from(value),
      final String value => switch (jsonDecode(value)) {
        final Map<Object?, Object?> decoded => Map<String, Object?>.from(
          decoded,
        ),
        _ => const <String, Object?>{},
      },
      _ => const <String, Object?>{},
    };
    return PartyRuntimeSettings(
      tieBreakerEnabled:
          tieBreakerValue == null ||
          tieBreakerValue == true ||
          tieBreakerValue == 1 ||
          tieBreakerValue == '1',
      rules: ruleJson.isEmpty
          ? GameRuleConfig.classicSession
          : GameRuleConfig.fromJson(ruleJson),
    );
  } catch (_) {
    return const PartyRuntimeSettings();
  }
});

final partyHelperCatalogProvider = FutureProvider<List<PartyHelperDefinition>>((
  ref,
) async {
  if (!ref.read(appConfigProvider).hasSupabase) {
    return defaultPartyHelperDefinitions;
  }
  try {
    final response = await Supabase.instance.client
        .from('party_help_tools')
        .select(
          'id,name_ar,description_ar,icon_key,timing,rule_config,sort_order',
        )
        .eq('is_active', true)
        .order('sort_order');
    final definitions = response
        .whereType<Map<String, Object?>>()
        .map(PartyHelperDefinition.fromJson)
        .toList(growable: false);
    return definitions.isEmpty ? defaultPartyHelperDefinitions : definitions;
  } catch (_) {
    return defaultPartyHelperDefinitions;
  }
});

Future<List<QuizQuestion>> fetchPartyQuestionPack({
  List<String> categoryIds = const [],
  int limit = 250,
}) async {
  final response = await Supabase.instance.client.rpc<Object?>(
    'get_party_question_pack',
    params: {
      'p_limit': limit,
      if (categoryIds.isNotEmpty) 'p_category_ids': categoryIds,
    },
  );
  if (response is! List) {
    throw const FormatException('Party pack must be a list');
  }
  return response
      .whereType<Map<String, Object?>>()
      .map(QuizQuestion.fromJson)
      .toList(growable: false);
}

final partyCatalogProvider = FutureProvider<PartyCatalog>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  final database = ref.read(appDatabaseProvider);
  List<QuizQuestion> questions;
  var source = PartyCatalogSource.remote;
  Map<String, PartyCategoryHealth> health = const {};

  if (ref.read(appConfigProvider).hasSupabase) {
    try {
      questions = await fetchPartyQuestionPack();
      await database.putSetting(
        _partyPackCacheKey,
        jsonEncode(questions.map((question) => question.toJson()).toList()),
      );
      health = await _fetchPartyCategoryHealth();
    } catch (_) {
      final fallback = await _loadCachedOrSafeFallback(ref);
      questions = fallback.questions;
      source = fallback.source;
    }
  } else {
    final fallback = await _loadCachedOrSafeFallback(ref);
    questions = fallback.questions;
    source = fallback.source;
  }

  return PartyCatalog(
    categories: categories,
    questions: questions,
    healthByCategoryId: health,
    source: source,
  );
});

Future<Map<String, PartyCategoryHealth>> _fetchPartyCategoryHealth() async {
  final response = await Supabase.instance.client.rpc<Object?>(
    'get_party_category_health',
  );
  if (response is! List) return const {};
  return {
    for (final row in response.whereType<Map<String, Object?>>())
      if (row['category_id'] case final String id)
        id: PartyCategoryHealth.fromJson(row),
  };
}

Future<_PartyQuestionLoad> _loadCachedOrSafeFallback(Ref ref) async {
  final cached = await ref
      .read(appDatabaseProvider)
      .readSetting(_partyPackCacheKey);
  if (cached != null && cached.isNotEmpty) {
    try {
      final decoded = jsonDecode(cached);
      if (decoded is List) {
        final questions = decoded
            .whereType<Map<String, Object?>>()
            .map(QuizQuestion.fromJson)
            .where(
              (question) =>
                  !ref.read(appConfigProvider).isProduction ||
                  !question.categoryId.endsWith('-demo'),
            )
            .toList(growable: false);
        if (questions.isNotEmpty) {
          return _PartyQuestionLoad(questions, PartyCatalogSource.cache);
        }
      }
    } catch (_) {
      // Ignore an outdated or corrupt cache and use the bundled safe pool.
    }
  }

  if (ref.read(appConfigProvider).isProduction) {
    return const _PartyQuestionLoad([], PartyCatalogSource.empty);
  }

  List<QuizQuestion> fallback;
  try {
    fallback = await ref.read(questionRepositoryProvider).loadSoloPool();
  } catch (_) {
    fallback = await DriftQuestionRepository(
      ref.read(appDatabaseProvider),
    ).loadSoloPool();
  }
  return _PartyQuestionLoad(
    fallback
        .where((question) {
          final image = question.imageUrl?.trim();
          if (image == null || image.isEmpty) return true;
          return image.startsWith('assets/') || image.startsWith('file:');
        })
        .toList(growable: false),
    PartyCatalogSource.bundled,
  );
}

enum PartyCatalogSource { remote, cache, bundled, empty }

final class _PartyQuestionLoad {
  const _PartyQuestionLoad(this.questions, this.source);

  final List<QuizQuestion> questions;
  final PartyCatalogSource source;
}

final class PartyCatalog {
  const PartyCatalog({
    required this.categories,
    required this.questions,
    this.healthByCategoryId = const {},
    this.source = PartyCatalogSource.remote,
  });

  final List<QuizCategory> categories;
  final List<QuizQuestion> questions;
  final Map<String, PartyCategoryHealth> healthByCategoryId;
  final PartyCatalogSource source;

  List<QuizCategory> get readyCategories {
    const engine = PartyGameEngine();
    return categories
        .where((category) {
          final health = healthByCategoryId[category.id];
          return health?.isReady ??
              engine.isCategoryReady(category.id, questions);
        })
        .toList(growable: false);
  }

  List<QuizCategory> playableCategories({required bool premium}) =>
      readyCategories
          .where(
            (category) =>
                category.accessTier == 'free' ||
                category.freeRotation ||
                premium,
          )
          .toList(growable: false);

  int questionCount(String categoryId) =>
      healthByCategoryId[categoryId]?.total ??
      questions.where((question) => question.categoryId == categoryId).length;
}

final class PartyCategoryHealth {
  const PartyCategoryHealth({
    required this.easy,
    required this.medium,
    required this.hard,
  });

  factory PartyCategoryHealth.fromJson(Map<String, Object?> json) =>
      PartyCategoryHealth(
        easy: (json['easy_count'] as num?)?.toInt() ?? 0,
        medium: (json['medium_count'] as num?)?.toInt() ?? 0,
        hard: (json['hard_count'] as num?)?.toInt() ?? 0,
      );

  final int easy;
  final int medium;
  final int hard;

  int get total => easy + medium + hard;
  bool get isReady => easy >= 2 && medium >= 2 && hard >= 2;
}

final class PartyRuntimeSettings {
  const PartyRuntimeSettings({
    this.tieBreakerEnabled = true,
    this.rules = GameRuleConfig.classicSession,
  });
  final bool tieBreakerEnabled;
  final GameRuleConfig rules;
}
