import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/tournament/domain/tournament.dart';
import 'package:ahdash_11/features/tournament/domain/tournament_engine.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  final fixtures = _fixtures();
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(393, 852),
    const Size(412, 915),
    const Size(430, 932),
  ]) {
    for (final scale in [1.0, 1.2, 1.3]) {
      testWidgets(
        'Phase C portrait RTL states fit $size at text scale $scale',
        (tester) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(() {
            tester.view
              ..resetPhysicalSize()
              ..resetDevicePixelRatio();
          });
          final screens = <(Tournament, Widget)>[
            (fixtures[1], const TournamentHubScreen()),
            (fixtures[0], const TournamentCreateScreen()),
            (fixtures[0], const TournamentTeamsScreen()),
            (fixtures[0], const TournamentDrawScreen()),
            (fixtures[1], const TournamentBracketScreen()),
            (
              fixtures[1],
              TournamentMatchScreen(matchId: fixtures[1].matches.last.id),
            ),
            (fixtures[2], const TournamentChampionScreen()),
          ];
          for (final (fixture, screen) in screens) {
            await tester.pumpWidget(
              ProviderScope(
                key: UniqueKey(),
                overrides: [
                  appConfigProvider.overrideWithValue(
                    const AppConfig(
                      environment: AppEnvironment.production,
                      supabaseUrl: '',
                      supabaseKey: '',
                      firebaseEnabled: false,
                      adMobEnabled: false,
                      revenueCatAndroidKey: '',
                      revenueCatIosKey: '',
                    ),
                  ),
                  tournamentControllerProvider.overrideWith(
                    () => _FixtureController(fixture),
                  ),
                  partyGameControllerProvider.overrideWithBuild(
                    (ref, notifier) => const PartyGameState(restored: true),
                  ),
                ],
                child: testApp(
                  MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true,
                    ),
                    child: screen,
                  ),
                  theme: AppTheme.light,
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
            final exception = tester.takeException();
            expect(
              exception,
              isNull,
              reason: '${screen.runtimeType} $size/$scale',
            );
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets('non-organizer sees no add team action', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentControllerProvider.overrideWith(
            () => _FixtureController(fixtures.first, canEdit: false),
          ),
        ],
        child: testApp(const TournamentTeamsScreen(), theme: AppTheme.light),
      ),
    );
    await tester.pump();
    expect(find.text('أضف فريقًا'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(360, 800), Size(390, 844)]) {
    testWidgets('Create Tournament stays reachable with keyboard at $size', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1
        ..viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio()
          ..resetViewInsets();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentControllerProvider.overrideWith(
              () => _FixtureController(fixtures.first),
            ),
          ],
          child: testApp(const TournamentCreateScreen(), theme: AppTheme.light),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('tournament-name-field'));
      final primary = find.byKey(const ValueKey('tournament-create-primary'));
      await tester.tap(field);
      await tester.enterText(field, 'أ');
      await tester.ensureVisible(primary);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      expect(tester.getRect(field).bottom, lessThan(size.height - 300));
      expect(tester.getRect(primary).bottom, lessThan(size.height - 300));
      await tester.tap(primary);
      await tester.pumpAndSettle();
      expect(find.text('اسم البطولة يجب أن يكون بين 3 و60 حرفًا.'), findsOne);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Tournament rules fit compact portrait after valid name', (
    tester,
  ) async {
    const size = Size(390, 844);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentControllerProvider.overrideWith(
            () => _FixtureController(fixtures.first),
          ),
        ],
        child: testApp(
          MediaQuery(
            data: const MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(1.3),
            ),
            child: const TournamentCreateScreen(),
          ),
          theme: AppTheme.light,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('tournament-name-field'));
    await tester.enterText(field, 'كأس الأبطال');
    await tester.tap(find.byKey(const ValueKey('tournament-create-primary')));
    await tester.pumpAndSettle();

    expect(find.text('حدّد قواعد البطولة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocked draw remains truthful and cannot report success', (
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
      ProviderScope(
        overrides: [
          tournamentControllerProvider.overrideWith(
            () => _FixtureController(fixtures.first, canEdit: false),
          ),
        ],
        child: testApp(const TournamentDrawScreen(), theme: AppTheme.light),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('القرعة غير متاحة في الحالة الحالية أو لهذا الحساب.'),
      findsOne,
    );
    expect(find.textContaining('تم إنشاء البطولة'), findsNothing);
    expect(find.textContaining('تم الحفظ'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final class _FixtureController extends TournamentController {
  _FixtureController(this.fixture, {this.canEdit = true});
  final Tournament fixture;
  final bool canEdit;
  @override
  TournamentState build() => TournamentState(active: fixture, restored: true);
  @override
  bool get canManage => canEdit;
  @override
  Future<void> restore() async {}
  @override
  Future<Map<String, Object?>?> readWizard() async => null;
  @override
  Future<void> saveWizard(Map<String, Object?> draft) async {}
}

List<Tournament> _fixtures() {
  var id = 0;
  final engine = TournamentEngine(idFactory: () => 'test-${id++}');
  var draft = engine.create(
    name: 'بطولة أبطال الحي 2026',
    organizerId: 'host',
    rules: const TournamentRules(capacity: 4, playersPerTeam: 2),
  );
  for (final name in [
    'نجوم الرياض United',
    'الصقور',
    'أبطال المدرج',
    'فريق المدينة',
  ]) {
    draft = engine.addTeam(draft, name: name);
  }
  final live = engine.generateBracket(draft, randomSeed: 11);
  var complete = live;
  while (complete.status != TournamentStatus.completed) {
    final match = complete.matches.firstWhere(
      (m) => m.status == TournamentMatchStatus.ready,
    );
    complete = engine.confirmResult(
      complete,
      matchId: match.id,
      scoreA: 900,
      scoreB: 700,
    );
  }
  return [draft, live, complete];
}
