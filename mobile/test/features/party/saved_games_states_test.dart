import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_support_screens.dart';
import 'package:ahdash_11/shared/presentation/app_states.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/v10_feature_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('saved games empty state is deliberate at compact scale 1.3', (
    tester,
  ) async {
    await _pump(
      tester,
      const PartyGameState(restored: true),
      size: const Size(360, 800),
      scale: 1.3,
    );
    expect(find.text('لا توجد جلسة محفوظة'), findsOneWidget);
    expect(find.text('ابدأ لعبة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved games populated state renders real persisted sessions', (
    tester,
  ) async {
    await _pump(
      tester,
      PartyGameState(
        restored: true,
        session: phase4BoardSession,
        history: [
          PartyGameSession.fromJson({
            ...phase4CompletedSession().toJson(),
            'id': 'fixture-history-session',
          }),
        ],
      ),
    );
    expect(find.text('صقور الجزيرة'), findsNWidgets(2));
    expect(find.text('استمر في اللعب'), findsOneWidget);
    expect(find.text('عرض النتيجة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved games loading uses a stable progressive skeleton', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      testApp(
        SavedGamesPortraitPage(
          restored: false,
          sessions: const [],
          onOpen: (_) {},
          onStart: () {},
          onHome: () {},
        ),
        theme: AppTheme.light,
      ),
    );
    await tester.pump();
    expect(find.byType(LoadingSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  PartyGameState state, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(() async {
    await database.close();
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        partyGameControllerProvider.overrideWithBuild((ref, notifier) => state),
      ],
      child: testApp(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: const PartyGamesScreen(),
        ),
        theme: AppTheme.light,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
