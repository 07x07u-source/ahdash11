import 'package:ahdash_11/core/l10n/app_localizations.dart';
import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_game_screens.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/party_phase4_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Board renders six real categories and truthful cell states', (
    tester,
  ) async {
    await _pump(tester, session: phase4BoardSession, location: '/party/board');

    expect(find.byKey(const ValueKey('party-board-grid')), findsOneWidget);
    for (final category in phase4BoardSession.categories) {
      expect(find.text(category.name), findsOneWidget);
    }
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('دور صقور الجزيرة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Board accepts only one rapid question-open request', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      session: phase4BoardSession.copyWith(clearTimer: true),
      location: '/party/board',
    );
    final available = find.text('100').first;

    await tester.tap(available);
    await tester.tap(available, warnIfMissed: false);
    await tester.pumpAndSettle();

    final session = harness.container
        .read(partyGameControllerProvider)
        .session!;
    expect(session.activeQuestionId, isNotNull);
    expect(session.scoreEvents, isEmpty);
    expect(
      harness.router.routeInformationProvider.value.uri.path,
      '/party/question',
    );
  });

  testWidgets('Text Question never exposes the answer before reveal', (
    tester,
  ) async {
    final session = phase4QuestionSession();
    await _pump(tester, session: session, location: '/party/question');

    expect(find.text(session.activeQuestion!.text), findsOneWidget);
    expect(find.text(session.activeQuestion!.answer), findsNothing);
    expect(
      find.bySemanticsLabel(
        RegExp(RegExp.escape(session.activeQuestion!.answer)),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('party-reveal-answer')), findsOneWidget);
  });

  testWidgets('long mixed Arabic and English question fits compact text scale', (
    tester,
  ) async {
    final session = _replaceActiveQuestion(
      phase4QuestionSession(),
      phase4QuestionSession().activeQuestion!.copyWithText(
        'في نهائي AFC Champions League 2026، من اللاعب الذي سجل الهدف الحاسم بعد 120 دقيقة لصالح نادي الهلال السعودي؟',
      ),
    );
    await _pump(
      tester,
      session: session,
      location: '/party/question',
      size: const Size(360, 800),
      textScaler: const TextScaler.linear(1.35),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('AFC Champions League 2026'), findsOneWidget);
  });

  for (final ratio in const [0.72, 1.0, 1.78]) {
    testWidgets('Image Question supports aspect ratio $ratio', (tester) async {
      final question = PartyQuestionSnapshot(
        id: 'ratio-$ratio',
        categoryId: 'category',
        text: 'من اللاعب في الصورة؟',
        answer: 'إجابة لا تظهر',
        difficulty: QuestionDifficulty.medium,
        pointValue: 200,
        format: PartyQuestionFormat.image,
        imageUrl: 'assets/images/backgrounds/v9_2_home_stadium.png',
        mechanicConfig: {'aspect_ratio': ratio},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: PartyQuestionRenderer(question: question)),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) => widget is AspectRatio && widget.aspectRatio == ratio,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Image failure is safe, retryable, and leaks no answer semantics',
    (tester) async {
      const answer = 'اسم سري لا يظهر';
      const question = PartyQuestionSnapshot(
        id: 'broken-image',
        categoryId: 'category',
        text: 'من اللاعب؟',
        answer: answer,
        difficulty: QuestionDifficulty.easy,
        pointValue: 100,
        format: PartyQuestionFormat.image,
        imageUrl: 'assets/images/does-not-exist.png',
        mechanicConfig: {'aspect_ratio': 1.0},
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: PartyQuestionRenderer(question: question)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تعذر تحميل الصورة'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.text(answer), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(answer))),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Timer is isolated and recomputes safely after pause and resume',
    (tester) async {
      await _pump(
        tester,
        session: phase4QuestionSession(),
        location: '/party/question',
      );

      expect(find.text('24'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('24'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('gameplay helper shows available, active, and consumed states', (
    tester,
  ) async {
    final active = phase4QuestionSession().copyWith(
      armedHelper: PartyHelperId.twoChances,
      teams: [
        phase4Teams[0].copyWith(usedHelpers: const {PartyHelperId.twoChances}),
        phase4Teams[1],
      ],
    );
    await _pump(tester, session: active, location: '/party/question');

    expect(find.bySemanticsLabel('جاوب جوابين'), findsOneWidget);
    final semantics = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .firstWhere((widget) => widget.properties.label == 'جاوب جوابين');
    expect(semantics.properties.selected, isTrue);
    expect(semantics.properties.enabled, isFalse);
  });

  testWidgets('Reveal refuses unrevealed state and keeps the answer hidden', (
    tester,
  ) async {
    final session = phase4QuestionSession();
    await _pump(tester, session: session, location: '/party/reveal');
    await tester.pump();

    expect(find.text(session.activeQuestion!.answer), findsNothing);
  });

  testWidgets('Reveal selects then authoritatively awards Team A once', (
    tester,
  ) async {
    final initial = phase4RevealSession();
    final harness = await _pump(
      tester,
      session: initial,
      location: '/party/reveal',
    );

    await tester.tap(find.textContaining('صقور الجزيرة (+'));
    await tester.pump();
    expect(find.byKey(const ValueKey('party-submit-score')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('party-submit-score')));
    await tester.pumpAndSettle();

    final updated = harness.container
        .read(partyGameControllerProvider)
        .session!;
    expect(updated.scoreEvents, hasLength(1));
    expect(
      updated.scores[0],
      initial.scores[0] + initial.activeQuestion!.pointValue,
    );
    expect(
      harness.router.routeInformationProvider.value.uri.path,
      '/party/board',
    );
  });

  testWidgets(
    'No one creates the real no-score event without arbitrary award',
    (tester) async {
      final initial = phase4RevealSession();
      final harness = await _pump(
        tester,
        session: initial,
        location: '/party/reveal',
      );

      await tester.tap(find.text('لا أحد'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('party-submit-score')));
      await tester.pumpAndSettle();

      final updated = harness.container
          .read(partyGameControllerProvider)
          .session!;
      expect(updated.scoreEvents.single.teamDeltas, const [0, 0]);
      expect(updated.scores, initial.scores);
    },
  );

  testWidgets('Final Result renders the real winner and both scores', (
    tester,
  ) async {
    await _pump(
      tester,
      session: phase4CompletedSession(),
      location: '/party/result',
    );

    expect(find.text('الكأس لـ صقور الجزيرة'), findsOneWidget);
    expect(find.text('4700'), findsOneWidget);
    expect(find.text('4100'), findsOneWidget);
    expect(find.byKey(const ValueKey('party-play-again')), findsOneWidget);
  });

  testWidgets('Final Result renders a tie without declaring a winner', (
    tester,
  ) async {
    await _pump(
      tester,
      session: phase4CompletedSession(tied: true),
      location: '/party/result',
    );

    expect(find.text('تعادل'), findsOneWidget);
    expect(find.textContaining('الكأس لـ'), findsNothing);
  });

  testWidgets('Play Again creates a real draft and preserves teams', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      session: phase4CompletedSession(),
      location: '/party/result',
    );
    await tester.tap(find.byKey(const ValueKey('party-play-again')));
    await tester.pumpAndSettle();

    final state = harness.container.read(partyGameControllerProvider);
    expect(state.hasSetupDraft, isTrue);
    expect(
      state.teams.map((team) => team.name),
      phase4Teams.map((team) => team.name),
    );
    expect(state.teams.every((team) => team.usedHelpers.isEmpty), isTrue);
    expect(
      harness.router.routeInformationProvider.value.uri.path,
      '/party/categories',
    );
  });

  testWidgets('system Back preserves gameplay behind a safe exit dialog', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      session: phase4QuestionSession(),
      location: '/party/question',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('تطلعون من الجولة؟'), findsOneWidget);
    expect(
      harness.container
          .read(partyGameControllerProvider)
          .session!
          .activeQuestionId,
      isNotNull,
    );
  });

  for (final size in const [
    Size(360, 800),
    Size(390, 844),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ]) {
    testWidgets(
      'Phase 4 core screens fit RTL at ${size.width}×${size.height}',
      (tester) async {
        for (final entry in <(String, PartyGameSession)>[
          ('/party/board', phase4BoardSession),
          ('/party/question', phase4QuestionSession()),
          ('/party/question', phase4QuestionSession(image: true)),
          ('/party/reveal', phase4RevealSession()),
          ('/party/result', phase4CompletedSession()),
        ]) {
          await _pump(
            tester,
            session: entry.$2,
            location: entry.$1,
            size: size,
            withDatabase: false,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.$1} overflowed at $size',
          );
        }
      },
    );
  }

  for (final scale in const [1.2, 1.3]) {
    testWidgets('core gameplay preserves content at text scale $scale', (
      tester,
    ) async {
      for (final entry in <(String, PartyGameSession)>[
        ('/party/board', phase4BoardSession),
        ('/party/question', phase4QuestionSession()),
        ('/party/question', phase4QuestionSession(image: true)),
        ('/party/reveal', phase4RevealSession()),
        ('/party/result', phase4CompletedSession()),
      ]) {
        await _pump(
          tester,
          session: entry.$2,
          location: entry.$1,
          textScaler: TextScaler.linear(scale),
          withDatabase: false,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.$1} overflowed at text scale $scale',
        );
      }
    });
  }
}

final class _Harness {
  const _Harness(this.container, this.router);

  final ProviderContainer container;
  final GoRouter router;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required PartyGameSession session,
  required String location,
  Size size = const Size(390, 844),
  TextScaler textScaler = TextScaler.noScaling,
  bool withDatabase = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  final database = withDatabase ? AppDatabase(NativeDatabase.memory()) : null;
  final container = ProviderContainer(
    overrides: [
      if (database != null) appDatabaseProvider.overrideWithValue(database),
      partyGameControllerProvider.overrideWithBuild(
        (ref, notifier) => PartyGameState(session: session, restored: true),
      ),
    ],
  );
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/party/board',
        builder: (_, _) => const PartyBoardScreen(),
      ),
      GoRoute(
        path: '/party/question',
        builder: (_, _) => PartyQuestionScreen(fixedNow: phase4Clock),
      ),
      GoRoute(
        path: '/party/reveal',
        builder: (_, _) => const PartyRevealScreen(),
      ),
      GoRoute(
        path: '/party/result',
        builder: (_, _) => const PartyResultScreen(),
      ),
      GoRoute(
        path: '/party/categories',
        builder: (_, _) => const Scaffold(body: Text('اختيار الفئات')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('الرئيسية')),
      ),
    ],
  );
  addTearDown(() async {
    router.dispose();
    container.dispose();
    await database?.close();
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: textScaler,
          disableAnimations: true,
        ),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pump();
  return _Harness(container, router);
}

PartyGameSession _replaceActiveQuestion(
  PartyGameSession session,
  PartyQuestionSnapshot replacement,
) => session.copyWith(
  categories: session.categories
      .map(
        (category) => category.id != replacement.categoryId
            ? category
            : category.copyWith(
                questions: category.questions
                    .map(
                      (question) => question.id == replacement.id
                          ? replacement
                          : question,
                    )
                    .toList(),
              ),
      )
      .toList(),
);

extension on PartyQuestionSnapshot {
  PartyQuestionSnapshot copyWithText(String value) => PartyQuestionSnapshot(
    id: id,
    categoryId: categoryId,
    text: value,
    answer: answer,
    difficulty: difficulty,
    pointValue: pointValue,
    format: format,
    options: options,
    alternativeAnswers: alternativeAnswers,
    imageUrl: imageUrl,
    audioUrl: audioUrl,
    videoUrl: videoUrl,
    orderingItems: orderingItems,
    hints: hints,
    pointDecayPerHint: pointDecayPerHint,
    mechanicConfig: mechanicConfig,
    explanation: explanation,
    used: used,
  );
}
