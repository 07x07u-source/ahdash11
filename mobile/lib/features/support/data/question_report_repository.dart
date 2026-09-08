import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/app_services.dart';
import '../../../core/storage/app_database.dart';
import '../../auth/data/supabase_user_mapper.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/guest_capability_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/question_report.dart';

final questionReportRepositoryProvider = Provider<QuestionReportRepository>((
  ref,
) {
  final configured = ref.watch(appConfigProvider).hasSupabase;
  return QuestionReportRepository(
    database: ref.watch(appDatabaseProvider),
    client: configured ? Supabase.instance.client : null,
    appVersion: ref.watch(appServicesProvider).errors.appVersion,
    currentAccount: () => ref.read(authControllerProvider).asData?.value,
  );
});

final class QuestionReportRepository {
  const QuestionReportRepository({
    required AppDatabase database,
    required String appVersion,
    SupabaseClient? client,
    AuthUser? Function()? currentAccount,
  }) : _database = database,
       _client = client,
       _currentAccount = currentAccount,
       _appVersion = appVersion;

  static const _kind = 'question_report';
  final AppDatabase _database;
  final SupabaseClient? _client;
  final String _appVersion;
  final AuthUser? Function()? _currentAccount;
  AuthUser? get _account => _currentAccount != null
      ? _currentAccount()
      : _client?.auth.currentUser == null
      ? null
      : mapSupabaseUser(_client!.auth.currentUser!);

  Future<QuestionReportSubmitStatus> submit({
    required String questionId,
    required String gameId,
    required QuestionReportReason reason,
    String? comment,
    DateTime? now,
  }) async {
    final account = _account;
    if (!GuestCapabilityPolicy(account).allows(AppCapability.reports)) {
      return QuestionReportSubmitStatus.authenticationRequired;
    }
    final draft = QuestionReportDraft(
      id: const Uuid().v4(),
      questionId: questionId,
      gameId: gameId,
      reason: reason,
      comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
      userId: account!.id,
      createdAt: (now ?? DateTime.now()).toUtc(),
      appVersion: _appVersion,
    );
    if (_client == null || _client.auth.currentUser == null) {
      await _queue(draft);
      return QuestionReportSubmitStatus.queued;
    }
    try {
      await _send(draft);
      return QuestionReportSubmitStatus.sent;
    } on PostgrestException catch (error) {
      if (error.code == '23505') return QuestionReportSubmitStatus.duplicate;
      await _queue(draft);
      return QuestionReportSubmitStatus.queued;
    } catch (_) {
      await _queue(draft);
      return QuestionReportSubmitStatus.queued;
    }
  }

  Future<int> syncPending() async {
    if (_client == null ||
        !supabaseCapabilities(_client.auth.currentUser).hasAccount) {
      return 0;
    }
    final rows = await _database.readPendingOperations(kind: _kind);
    var synced = 0;
    for (final row in rows) {
      final id = '${row['id']}';
      try {
        final payload = row['payload'];
        if (payload is! Map<String, Object?>) {
          await _database.deletePendingOperation(id);
          continue;
        }
        final draft = QuestionReportDraft.fromJson(payload);
        // Never attach an anonymous/other-account queued report to a new login.
        if (draft.userId != _client.auth.currentUser!.id) continue;
        await _send(draft);
        await _database.deletePendingOperation(id);
        synced++;
      } on PostgrestException catch (error) {
        if (error.code == '23505') {
          await _database.deletePendingOperation(id);
          synced++;
        } else {
          await _database.markPendingOperationAttempt(id);
        }
      } catch (_) {
        await _database.markPendingOperationAttempt(id);
      }
    }
    return synced;
  }

  Future<void> _queue(QuestionReportDraft draft) =>
      _database.enqueuePendingOperation(
        id: draft.id,
        kind: _kind,
        payload: draft.toJson(),
        createdAt: draft.createdAt,
      );

  Future<void> _send(QuestionReportDraft draft) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null ||
        user == null ||
        !supabaseCapabilities(user).hasAccount ||
        draft.userId != user.id) {
      throw StateError('Authentication needed');
    }
    final details = [
      if (draft.reason.backendReason != draft.reason.storageKey)
        '[${draft.reason.storageKey}]',
      if (draft.comment?.isNotEmpty == true) draft.comment!,
    ].join(' ');
    final row = <String, Object?>{
      'question_id': draft.questionId,
      'reporter_id': user.id,
      'reason': draft.reason.backendReason,
      'details': details.isEmpty ? null : details,
      'client_game_id': draft.gameId,
      'app_version': draft.appVersion,
    };
    try {
      await client.from('question_reports').insert(row);
    } on PostgrestException catch (error) {
      if (error.code != '42703' && error.code != 'PGRST204') rethrow;
      await client.from('question_reports').insert({
        'question_id': draft.questionId,
        'reporter_id': user.id,
        'reason': draft.reason.backendReason,
        'details': details.isEmpty
            ? '[game:${draft.gameId}] [app:${draft.appVersion}]'
            : '[game:${draft.gameId}] [app:${draft.appVersion}] $details',
      });
    }
  }
}
