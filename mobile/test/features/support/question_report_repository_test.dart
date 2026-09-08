import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/support/data/question_report_repository.dart';
import 'package:ahdash_11/features/support/domain/question_report.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'offline signed-in question report is queued with its account ownership',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = QuestionReportRepository(
        database: database,
        appVersion: '0.1.0+1',
        currentAccount: () =>
            const AuthUser(id: 'account', username: 'محمد', isGuest: false),
      );

      final status = await repository.submit(
        questionId: 'question-id',
        gameId: 'party-game-id',
        reason: QuestionReportReason.wrongCategory,
        comment: 'تحتاج إلى تصنيف مختلف',
        now: DateTime.utc(2026, 9, 2),
      );

      expect(status, QuestionReportSubmitStatus.queued);
      final queued = await database.readPendingOperations(
        kind: 'question_report',
      );
      expect(queued, hasLength(1));
      final payload = queued.single['payload']! as Map<String, Object?>;
      expect(payload['question_id'], 'question-id');
      expect(payload['game_id'], 'party-game-id');
      expect(payload['reason'], 'wrong_category');
      expect(payload['app_version'], '0.1.0+1');
      expect(payload['user_id'], 'account');
    },
  );

  test('guest reports cannot send or queue a protected mutation', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = QuestionReportRepository(
      database: database,
      appVersion: 'test',
      currentAccount: () =>
          const AuthUser(id: 'guest', username: 'ضيف', isGuest: true),
    );
    expect(
      await repository.submit(
        questionId: 'q',
        gameId: 'g',
        reason: QuestionReportReason.typo,
      ),
      QuestionReportSubmitStatus.authenticationRequired,
    );
    expect(
      await database.readPendingOperations(kind: 'question_report'),
      isEmpty,
    );
    expect(await repository.syncPending(), 0);
  });

  test('all report reasons map to an accepted backend enum', () {
    const accepted = {
      'wrong_answer',
      'unclear',
      'wrong_image',
      'duplicate',
      'other',
    };
    expect(
      QuestionReportReason.values.every(
        (reason) => accepted.contains(reason.backendReason),
      ),
      isTrue,
    );
  });
}
