import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

/// Drift database using explicit SQL to keep schema ownership visible and avoid
/// generated files in the repository. Repositories expose strongly typed data.
final class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults()
    : super(
        driftDatabase(
          name: 'ahdash_11_cache',
          native: const DriftNativeOptions(shareAcrossIsolates: true),
        ),
      );

  @override
  int get schemaVersion => 2;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables =>
      const <TableInfo<Table, dynamic>>[];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities =>
      const <DatabaseSchemaEntity>[];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await customStatement('''
        CREATE TABLE cached_categories (
          id TEXT PRIMARY KEY NOT NULL,
          payload TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          cached_at INTEGER NOT NULL
        )
      ''');
      await customStatement('''
        CREATE TABLE cached_questions (
          id TEXT PRIMARY KEY NOT NULL,
          category_id TEXT NOT NULL,
          payload TEXT NOT NULL,
          cached_at INTEGER NOT NULL
        )
      ''');
      await customStatement('''
        CREATE INDEX cached_questions_category_idx
        ON cached_questions(category_id)
      ''');
      await customStatement('''
        CREATE TABLE question_history (
          question_id TEXT PRIMARY KEY NOT NULL,
          seen_count INTEGER NOT NULL DEFAULT 0,
          correct_count INTEGER NOT NULL DEFAULT 0,
          last_seen_at INTEGER NOT NULL
        )
      ''');
      await customStatement('''
        CREATE TABLE local_settings (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await customStatement('''
        CREATE TABLE pending_operations (
          id TEXT PRIMARY KEY NOT NULL,
          kind TEXT NOT NULL,
          payload TEXT NOT NULL,
          attempts INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');
      await _createVersionTwoTables();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await _createVersionTwoTables();
    },
  );

  Future<void> _createVersionTwoTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS question_usage_history (
        id TEXT PRIMARY KEY NOT NULL,
        question_id TEXT NOT NULL,
        account_id TEXT,
        game_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        used_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS question_usage_recent_idx
      ON question_usage_history(question_id, used_at DESC)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS question_usage_game_idx
      ON question_usage_history(game_id, used_at)
    ''');
  }

  Future<void> replaceCategories(List<Map<String, Object?>> rows) async {
    await transaction(() async {
      await customStatement('DELETE FROM cached_categories');
      final now = DateTime.now().millisecondsSinceEpoch;
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        await customStatement(
          '''
          INSERT INTO cached_categories(id, payload, sort_order, cached_at)
          VALUES (?, ?, ?, ?)
          ''',
          [row['id'], jsonEncode(row), index, now],
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> readCategories() async {
    final rows = await customSelect(
      'SELECT payload FROM cached_categories ORDER BY sort_order',
    ).get();
    return rows
        .map((row) => jsonDecode(row.read<String>('payload')))
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
  }

  Future<void> replaceQuestions(List<Map<String, Object?>> rows) async {
    await transaction(() async {
      await customStatement('DELETE FROM cached_questions');
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final row in rows) {
        await customStatement(
          '''
          INSERT INTO cached_questions(id, category_id, payload, cached_at)
          VALUES (?, ?, ?, ?)
          ''',
          [row['id'], row['category_id'], jsonEncode(row), now],
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> readQuestions() async {
    final rows = await customSelect(
      'SELECT payload FROM cached_questions ORDER BY id',
    ).get();
    return rows
        .map((row) => jsonDecode(row.read<String>('payload')))
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
  }

  Future<List<Map<String, Object?>>> readQuestionHistory() async {
    final rows = await customSelect('''
      SELECT question_id, seen_count, correct_count, last_seen_at
      FROM question_history
    ''').get();
    return rows.map((row) => row.data.cast<String, Object?>()).toList();
  }

  Future<void> recordQuestionSeen({
    required String questionId,
    required bool correct,
    required DateTime seenAt,
  }) {
    return customStatement(
      '''
      INSERT INTO question_history(
        question_id, seen_count, correct_count, last_seen_at
      ) VALUES (?, 1, ?, ?)
      ON CONFLICT(question_id) DO UPDATE SET
        seen_count = seen_count + 1,
        correct_count = correct_count + excluded.correct_count,
        last_seen_at = excluded.last_seen_at
      ''',
      [questionId, correct ? 1 : 0, seenAt.millisecondsSinceEpoch],
    );
  }

  Future<void> recordQuestionUsage({
    required String id,
    required String questionId,
    required String gameId,
    required String categoryId,
    String? accountId,
    required DateTime usedAt,
  }) => customStatement(
    '''
      INSERT OR IGNORE INTO question_usage_history(
        id, question_id, account_id, game_id, category_id, used_at
      ) VALUES (?, ?, ?, ?, ?, ?)
    ''',
    [
      id,
      questionId,
      accountId,
      gameId,
      categoryId,
      usedAt.millisecondsSinceEpoch,
    ],
  );

  Future<List<Map<String, Object?>>> readQuestionUsage({
    String? questionId,
    int limit = 1000,
  }) async {
    final rows = await customSelect(
      questionId == null
          ? '''
              SELECT id, question_id, account_id, game_id, category_id, used_at
              FROM question_usage_history
              ORDER BY used_at DESC
              LIMIT ?
            '''
          : '''
              SELECT id, question_id, account_id, game_id, category_id, used_at
              FROM question_usage_history
              WHERE question_id = ?
              ORDER BY used_at DESC
              LIMIT ?
            ''',
      variables: questionId == null
          ? [Variable<int>(limit)]
          : [Variable<String>(questionId), Variable<int>(limit)],
    ).get();
    return rows.map((row) => row.data.cast<String, Object?>()).toList();
  }

  Future<void> enqueuePendingOperation({
    required String id,
    required String kind,
    required Map<String, Object?> payload,
    DateTime? createdAt,
  }) => customStatement(
    '''
      INSERT OR REPLACE INTO pending_operations(
        id, kind, payload, attempts, created_at
      ) VALUES (?, ?, ?, 0, ?)
    ''',
    [
      id,
      kind,
      jsonEncode(payload),
      (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    ],
  );

  Future<List<Map<String, Object?>>> readPendingOperations({
    String? kind,
    int limit = 100,
  }) async {
    final rows = await customSelect(
      kind == null
          ? '''
              SELECT id, kind, payload, attempts, created_at
              FROM pending_operations
              ORDER BY created_at
              LIMIT ?
            '''
          : '''
              SELECT id, kind, payload, attempts, created_at
              FROM pending_operations
              WHERE kind = ?
              ORDER BY created_at
              LIMIT ?
            ''',
      variables: kind == null
          ? [Variable<int>(limit)]
          : [Variable<String>(kind), Variable<int>(limit)],
    ).get();
    return rows
        .map((row) {
          final data = row.data.cast<String, Object?>();
          return {
            ...data,
            'payload': switch (jsonDecode(data['payload']! as String)) {
              final Map<Object?, Object?> value => Map<String, Object?>.from(
                value,
              ),
              _ => const <String, Object?>{},
            },
          };
        })
        .toList(growable: false);
  }

  Future<void> markPendingOperationAttempt(String id) => customStatement(
    'UPDATE pending_operations SET attempts = attempts + 1 WHERE id = ?',
    [id],
  );

  Future<void> deletePendingOperation(String id) =>
      customStatement('DELETE FROM pending_operations WHERE id = ?', [id]);

  Future<void> putSetting(String key, String value) {
    return customStatement(
      '''
      INSERT INTO local_settings(key, value, updated_at) VALUES (?, ?, ?)
      ON CONFLICT(key) DO UPDATE SET
        value = excluded.value,
        updated_at = excluded.updated_at
      ''',
      [key, value, DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<String?> readSetting(String key) async {
    final row = await customSelect(
      'SELECT value FROM local_settings WHERE key = ?',
      variables: [Variable<String>(key)],
    ).getSingleOrNull();
    return row?.read<String>('value');
  }
}
