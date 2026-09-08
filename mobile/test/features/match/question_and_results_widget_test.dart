import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/config/game_settings_repository.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/game/domain/game_mode.dart';
import 'package:ahdash_11/features/match/domain/question_history_entry.dart';
import 'package:ahdash_11/features/match/domain/question_repository.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/match/domain/solo_opponent.dart';
import 'package:ahdash_11/features/match/presentation/question_repository_provider.dart';
import 'package:ahdash_11/features/match/presentation/question_screen.dart';
import 'package:ahdash_11/features/match/presentation/results_screen.dart';
import 'package:ahdash_11/features/match/presentation/solo_match_controller.dart';
import 'package:ahdash_11/shared/domain/game_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

final class _Questions implements QuestionRepository {
  static const question = QuizQuestion(
    id: 'q1',
    text: 'سؤال قابل للاختبار؟',
    options: ['نعم', 'لا', 'ربما', 'لاحقًا'],
    correctOptionIndex: 0,
    categoryId: 'cat',
    difficulty: QuestionDifficulty.easy,
  );

  @override
  Future<List<QuestionHistoryEntry>> loadHistory() async => const [];

  @override
  Future<List<QuizQuestion>> loadSoloPool() async => const [question];

  @override
  Future<void> recordAnswer({
    required String questionId,
    required int selectedIndex,
    required bool correct,
  }) async {}
}

final class _LongQuestions implements QuestionRepository {
  static const question = QuizQuestion(
    id: 'long-q',
    text:
        'في مباراة امتدت إلى وقت إضافي وحُسمت في الدقائق الأخيرة، من هو اللاعب الذي صنع الهدف الحاسم بعد سلسلة تمريرات طويلة؟',
    options: [
      'اللاعب صاحب الرقم أحد عشر الذي بدأ الهجمة من الجهة اليمنى',
      'حارس المرمى الذي تقدم للمشاركة في الركلة الأخيرة',
      'لاعب الوسط الذي دخل بديلًا في بداية الشوط الإضافي',
      'المدافع الذي استعاد الكرة ثم واصل الهجمة حتى منطقة الجزاء',
    ],
    correctOptionIndex: 0,
    categoryId: 'cat',
    difficulty: QuestionDifficulty.hard,
  );

  @override
  Future<List<QuestionHistoryEntry>> loadHistory() async => const [];

  @override
  Future<List<QuizQuestion>> loadSoloPool() async => const [question];

  @override
  Future<void> recordAnswer({
    required String questionId,
    required int selectedIndex,
    required bool correct,
  }) async {}
}

final class _TrueFalseQuestions implements QuestionRepository {
  static const question = QuizQuestion(
    id: 'true-false-q',
    text: 'الفريق الأعلى نقاطًا يتصدر جدول الدوري.',
    options: ['صح', 'خطأ'],
    correctOptionIndex: 0,
    categoryId: 'cat',
    difficulty: QuestionDifficulty.easy,
    gameType: GameType.trueFalse,
  );

  @override
  Future<List<QuestionHistoryEntry>> loadHistory() async => const [];

  @override
  Future<List<QuizQuestion>> loadSoloPool() async => const [question];

  @override
  Future<void> recordAnswer({
    required String questionId,
    required int selectedIndex,
    required bool correct,
  }) async {}
}

ProviderContainer container({
  QuestionRepository? repository,
  GameSettings settings = const GameSettings(),
}) => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(
      const AppConfig(
        environment: AppEnvironment.development,
        supabaseUrl: '',
        supabaseKey: '',
        firebaseEnabled: false,
        adMobEnabled: false,
        revenueCatAndroidKey: '',
        revenueCatIosKey: '',
      ),
    ),
    appServicesProvider.overrideWithValue(const AppServices.noop()),
    questionRepositoryProvider.overrideWithValue(repository ?? _Questions()),
    gameSettingsProvider.overrideWith((ref) async => settings),
  ],
);

const request = SoloMatchRequest(
  categoryIds: {'cat'},
  difficulty: QuestionDifficulty.easy,
  questionCount: 1,
  opponentLevel: SoloOpponentLevel.easy,
);

void main() {
  const landscapeSizes = [Size(800, 360), Size(844, 390), Size(915, 412)];

  test(
    'Speed practice reuses Classic questions with a seven-second clock',
    () async {
      final scope = container();
      addTearDown(scope.dispose);
      await scope
          .read(soloMatchControllerProvider.notifier)
          .start(
            const SoloMatchRequest(
              categoryIds: {'cat'},
              difficulty: QuestionDifficulty.easy,
              questionCount: 1,
              opponentLevel: SoloOpponentLevel.easy,
              gameType: GameType.speed,
            ),
          );

      final state = scope.read(soloMatchControllerProvider);
      expect(state.status, SoloMatchStatus.answering);
      expect(state.gameType, GameType.speed);
      expect(state.settings.questionTimeSeconds, 7);
      expect(state.currentQuestion?.options, hasLength(4));
    },
  );

  test('True/False practice uses two options and a ten-second clock', () async {
    final scope = container(repository: _TrueFalseQuestions());
    addTearDown(scope.dispose);
    await scope
        .read(soloMatchControllerProvider.notifier)
        .start(
          const SoloMatchRequest(
            categoryIds: {'cat'},
            difficulty: QuestionDifficulty.easy,
            questionCount: 1,
            opponentLevel: SoloOpponentLevel.easy,
            gameType: GameType.trueFalse,
          ),
        );

    final state = scope.read(soloMatchControllerProvider);
    expect(state.status, SoloMatchStatus.answering);
    expect(state.settings.questionTimeSeconds, 10);
    expect(state.currentQuestion?.options, ['صح', 'خطأ']);
  });

  for (final size in landscapeSizes) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'question layout uses ${size.width}x${size.height} in ${brightness.name}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final scope = container();
          addTearDown(scope.dispose);
          await scope.read(soloMatchControllerProvider.notifier).start(request);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: scope,
              child: testApp(
                const QuestionScreen(),
                theme: brightness == Brightness.light
                    ? AppTheme.light
                    : AppTheme.dark,
              ),
            ),
          );
          await tester.pump();

          expect(find.text('سؤال قابل للاختبار؟'), findsOneWidget);
          expect(find.text('لاحقًا'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('question screen displays timer and four answer options', (
    tester,
  ) async {
    final scope = container();
    addTearDown(scope.dispose);
    await scope.read(soloMatchControllerProvider.notifier).start(request);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: testApp(const QuestionScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('سؤال قابل للاختبار؟'), findsOneWidget);
    expect(find.text('نعم'), findsOneWidget);
    expect(find.text('لاحقًا'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('selected and correct answer states show real score feedback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = container();
    addTearDown(scope.dispose);
    await scope.read(soloMatchControllerProvider.notifier).start(request);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: testApp(const QuestionScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('نعم'));
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.byKey(const ValueKey('feedback-correct')), findsOneWidget);
    expect(find.text('إجابة صحيحة'), findsOneWidget);
    expect(find.textContaining('سرعة'), findsOneWidget);
  });

  testWidgets('wrong answer is identified by text and icon, not color only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = container();
    addTearDown(scope.dispose);
    await scope.read(soloMatchControllerProvider.notifier).start(request);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: testApp(const QuestionScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('لا'));
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.byKey(const ValueKey('feedback-wrong')), findsOneWidget);
    expect(find.text('الإجابة غير صحيحة'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsWidgets);
  });

  testWidgets('question states remain usable with reduced motion', (
    tester,
  ) async {
    final scope = container();
    addTearDown(scope.dispose);
    await scope.read(soloMatchControllerProvider.notifier).start(request);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: testApp(const QuestionScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('نعم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long question and answers remain usable at large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = container(repository: _LongQuestions());
    addTearDown(scope.dispose);
    await scope.read(soloMatchControllerProvider.notifier).start(request);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: testApp(const QuestionScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(_LongQuestions.question.text), findsOneWidget);
    expect(find.byType(ListView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing an active question cancels gameplay timers', (
    tester,
  ) async {
    final scope = container();
    addTearDown(scope.dispose);
    await scope.read(soloMatchControllerProvider.notifier).start(request);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: testApp(const QuestionScreen()),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('timer finish submits a timeout without a client score', (
    tester,
  ) async {
    final scope = container(
      settings: const GameSettings(questionTimeSeconds: 1),
    );
    addTearDown(scope.dispose);
    await scope.read(soloMatchControllerProvider.notifier).start(request);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: testApp(const QuestionScreen()),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.pump(const Duration(milliseconds: 120));

    final state = scope.read(soloMatchControllerProvider);
    expect(state.status, SoloMatchStatus.revealed);
    expect(state.selectedIndex, isNull);
    expect(state.playerScore, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('results screen exposes complete match summary', (tester) async {
    final scope = container();
    addTearDown(scope.dispose);
    final controller = scope.read(soloMatchControllerProvider.notifier);
    await controller.start(request);
    controller.submitAnswer(0);
    await controller.nextQuestion();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: testApp(const ResultsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إجابات صحيحة'), findsOneWidget);
    expect(find.text('إعادة التحدي'), findsOneWidget);
    expect(find.byTooltip('مشاركة النتيجة'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
  });
}
