import 'dart:async';

import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/football/presentation/football_preferences_controller.dart';
import 'package:ahdash_11/features/football/presentation/football_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase6_fixture.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('club and visibility choices update immediately', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        footballPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => phase6Football,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testApp(
          const FootballPreferencesScreen(),
          theme: AppTheme.light,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hilal = find.text('الهلال');
    await tester.ensureVisible(hilal);
    await tester.tap(hilal);
    await tester.pump();
    expect(
      container.read(footballPreferencesProvider).requireValue.clubId,
      'club-d',
    );

    final visibility = find.byType(Switch);
    await tester.ensureVisible(visibility);
    await tester.tap(visibility);
    await tester.pump();
    expect(
      container.read(footballPreferencesProvider).requireValue.showPublicly,
      isFalse,
    );
  });

  testWidgets('keyboard uses a compact status without hiding the search', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1
      ..viewInsets = const FakeViewPadding(bottom: 266);
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio()
        ..resetViewInsets();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          footballPreferencesProvider.overrideWithBuild(
            (ref, notifier) async => phase6Football,
          ),
        ],
        child: testApp(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              viewInsets: EdgeInsets.only(bottom: 266),
            ),
            child: const FootballPreferencesScreen(),
          ),
          theme: AppTheme.light,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('football-keyboard-status')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('football-hero')), findsNothing);
    expect(find.byKey(const ValueKey('football-search-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('football-save')), findsOneWidget);
  });

  testWidgets('start, search, loading, and failure states stay explicit', (
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

    Future<void> pump(FutureOr<FootballView> Function() build) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            footballPreferencesProvider.overrideWithBuild(
              (ref, notifier) => build(),
            ),
          ],
          child: testApp(
            const FootballPreferencesScreen(),
            theme: AppTheme.light,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
    }

    await pump(() => const FootballView(leagues: phase6Leagues, canSave: true));
    expect(
      find.byKey(const ValueKey('football-select-league-prompt')),
      findsOneWidget,
    );

    await pump(
      () => const FootballView(
        leagues: phase6Leagues,
        leagueId: 'league-a',
        query: 'غير موجود',
        canSave: true,
      ),
    );
    expect(find.byKey(const ValueKey('football-search-empty')), findsOneWidget);

    await pump(
      () => const FootballView(
        leagues: phase6Leagues,
        leagueId: 'league-a',
        searching: true,
        canSave: true,
      ),
    );
    expect(
      find.byKey(const ValueKey('football-clubs-loading')),
      findsOneWidget,
    );

    final pending = Completer<FootballView>();
    await pump(() => pending.future);
    expect(find.byKey(const ValueKey('football-loading')), findsOneWidget);

    await pump(() => Future<FootballView>.error(StateError('offline')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('football-error')), findsOneWidget);
  });
}
