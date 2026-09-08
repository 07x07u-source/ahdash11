import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/content/domain/app_content.dart';
import 'package:ahdash_11/features/content/presentation/app_content_controller.dart';
import 'package:ahdash_11/features/home/presentation/home_screen.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Home renders real actions without Coin or Wallet affordances', (
    tester,
  ) async {
    _setSize(tester, const Size(844, 390));
    final router = await _pumpHome(
      tester,
      const PartyGameState(restored: true),
    );
    addTearDown(router.dispose);

    expect(find.text('ابدأ لعبة'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('أنشئ بطولة'), 160);
    expect(find.text('أنشئ بطولة'), findsOneWidget);
    expect(find.textContaining('كمل'), findsNothing);
    expect(find.textContaining('عملة'), findsNothing);
    expect(find.textContaining('محفظة'), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.text('طرق اللعب'), findsOneWidget);
    expect(find.textContaining('عن بعد'), findsNothing);
    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shows resume only for a real resumable Party session', (
    tester,
  ) async {
    _setSize(tester, const Size(844, 390));
    final router = await _pumpHome(
      tester,
      PartyGameState(session: _session, restored: true),
    );
    addTearDown(router.dispose);

    expect(find.text('كمل لعبتك'), findsOneWidget);
    await tester.tap(find.text('كمل لعبتك'));
    await tester.pumpAndSettle();
    expect(find.text('BOARD'), findsOneWidget);
  });

  testWidgets('Home primary action enters the canonical category route', (
    tester,
  ) async {
    _setSize(tester, const Size(844, 390));
    final router = await _pumpHome(
      tester,
      const PartyGameState(restored: true),
    );
    addTearDown(router.dispose);

    await tester.tap(find.widgetWithText(FilledButton, 'ابدأ لعبة'));
    await tester.pumpAndSettle();
    expect(find.text('CATEGORIES'), findsOneWidget);

    router.go('/home');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('أنشئ بطولة'), 160);
    await tester.pumpAndSettle();
    await tester.tap(find.text('أنشئ بطولة'));
    await tester.pumpAndSettle();
    expect(find.text('CREATE_TOURNAMENT'), findsOneWidget);
  });

  testWidgets('Home compact RTL composition has no overflow', (tester) async {
    _setSize(tester, const Size(800, 360));
    final router = await _pumpHome(
      tester,
      const PartyGameState(restored: true),
    );
    addTearDown(router.dispose);

    expect(find.text('لعبة جماعية'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Directionality &&
            widget.textDirection == TextDirection.rtl,
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<GoRouter> _pumpHome(
  WidgetTester tester,
  PartyGameState partyState,
) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/party/categories',
        builder: (_, _) => const Scaffold(body: Text('CATEGORIES')),
      ),
      GoRoute(
        path: '/party/board',
        builder: (_, _) => const Scaffold(body: Text('BOARD')),
      ),
      GoRoute(
        path: '/tournaments/create',
        builder: (_, _) => const Scaffold(body: Text('CREATE_TOURNAMENT')),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const Scaffold(body: Text('SETTINGS')),
      ),
      GoRoute(
        path: '/how-to-play',
        builder: (_, _) => const Scaffold(body: Text('HOW_TO')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => const AuthUser(
            id: 'home-account',
            username: 'لاعب',
            isGuest: false,
          ),
        ),
        appPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => const AppPreferences(reducedMotion: true),
        ),
        appContentProvider.overrideWithBuild(
          (ref, notifier) async => AppContentBundle.defaults,
        ),
        partyGameControllerProvider.overrideWithBuild(
          (ref, notifier) => partyState,
        ),
        tournamentControllerProvider.overrideWithBuild(
          (ref, notifier) => const TournamentState(restored: true),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void _setSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

final _session = PartyGameSession(
  id: 'resume-party',
  teams: const [
    PartyTeam(name: 'الصقور', colorValue: 0xFFE84B8A),
    PartyTeam(name: 'المدرج', colorValue: 0xFF4B8DE8),
  ],
  categories: const [
    PartyCategorySnapshot(
      id: 'league',
      name: 'الدوري السعودي',
      colorValue: 0xFFB6FF3B,
      ownerTeamIndex: 0,
      questions: [
        PartyQuestionSnapshot(
          id: 'question',
          categoryId: 'league',
          text: 'سؤال حقيقي محفوظ',
          answer: 'إجابة',
          difficulty: QuestionDifficulty.easy,
          pointValue: 100,
          format: PartyQuestionFormat.multipleChoice,
        ),
      ],
    ),
  ],
  timerSeconds: 30,
  createdAt: DateTime(2026, 9, 4),
);
