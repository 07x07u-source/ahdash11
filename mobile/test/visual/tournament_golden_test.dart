import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/tournament/domain/tournament.dart';
import 'package:ahdash_11/features/tournament/domain/tournament_engine.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/visual_test_variant.dart';

enum _TournamentVisual {
  hub,
  create,
  teams,
  draw,
  bracket,
  semifinal,
  finalMatch,
  match,
  champion,
}

void main() => registerVisualTests();

void registerVisualTests({VisualTestVariant? variant}) {
  setUpAll(() async {
    await (FontLoader('ThmanyahSans')
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Regular.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Medium.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Bold.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Black.otf'),
          ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
  });

  final sizes = variant == null
      ? const [Size(390, 844), Size(360, 800)]
      : [variant.size];
  final fixtures = _Fixtures();

  for (final size in sizes) {
    for (final screen in _TournamentVisual.values) {
      final dimensions = '${size.width.round()}x${size.height.round()}';
      testWidgets('tournament ${screen.name} $dimensions light', (
        tester,
      ) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(() {
          tester.view
            ..resetPhysicalSize()
            ..resetDevicePixelRatio();
        });
        final fixture = fixtures.forScreen(screen);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              partyGameControllerProvider.overrideWithBuild(
                (ref, notifier) => const PartyGameState(restored: true),
              ),
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
                () => _FixtureTournamentController(fixture),
              ),
            ],
            child: testApp(
              MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(variant?.scale ?? 1),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: _screen(screen, fixture),
              ),
              theme: AppTheme.light,
            ),
          ),
        );
        await tester.pump();
        final images = find.byType(Image);
        await tester.runAsync(() async {
          for (final element in images.evaluate()) {
            await precacheImage((element.widget as Image).image, element);
          }
        });
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        await verifyVisual(
          tester,
          find.byType(MaterialApp),
          'goldens/v10_phase_c/${screen.name}_$dimensions.png',
          variant,
        );
      });
    }
  }

  for (final size in sizes) {
    final dimensions = '${size.width.round()}x${size.height.round()}';
    testWidgets('tournament create keyboard $dimensions', (tester) async {
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
            partyGameControllerProvider.overrideWithBuild(
              (ref, notifier) => const PartyGameState(restored: true),
            ),
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
              () => _FixtureTournamentController(fixtures.draft),
            ),
          ],
          child: testApp(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(variant?.scale ?? 1),
                disableAnimations: true,
                viewInsets: const EdgeInsets.only(bottom: 300),
                padding: const EdgeInsets.only(top: 47),
                viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: const TournamentCreateScreen(),
            ),
            theme: AppTheme.light,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tournament-name-field')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await verifyVisual(
        tester,
        find.byType(MaterialApp),
        'goldens/v10_phase_c/create_keyboard_$dimensions.png',
        variant,
      );
    });
  }
}

Widget _screen(_TournamentVisual screen, Tournament fixture) =>
    switch (screen) {
      _TournamentVisual.hub => const TournamentHubScreen(),
      _TournamentVisual.create => const TournamentCreateScreen(),
      _TournamentVisual.teams => const TournamentTeamsScreen(),
      _TournamentVisual.draw => const TournamentDrawScreen(),
      _TournamentVisual.bracket ||
      _TournamentVisual.semifinal => const TournamentBracketScreen(),
      _TournamentVisual.finalMatch => const TournamentBracketScreen(
        initialRound: 2,
      ),
      _TournamentVisual.match => TournamentMatchScreen(
        matchId: fixture.matches
            .where((match) => match.status == TournamentMatchStatus.ready)
            .first
            .id,
      ),
      _TournamentVisual.champion => const TournamentChampionScreen(),
    };

final class _FixtureTournamentController extends TournamentController {
  _FixtureTournamentController(this.fixture);
  final Tournament fixture;

  @override
  TournamentState build() => TournamentState(active: fixture, restored: true);

  @override
  Future<void> restore() async {}

  @override
  Future<Map<String, Object?>?> readWizard() async => {
    'name': 'بطولة الأساطير الشتوية',
    'step': 0,
    'rules': const TournamentRules(capacity: 8, playersPerTeam: 2).toJson(),
  };

  @override
  Future<void> saveWizard(Map<String, Object?> draft) async {}

  @override
  bool get canManage => true;
}

final class _Fixtures {
  _Fixtures() {
    var id = 0;
    final engine = TournamentEngine(idFactory: () => 'fixture-${id++}');
    draft = engine.create(
      name: 'بطولة الشتاء الكبرى',
      organizerId: 'organizer',
      rules: const TournamentRules(capacity: 8, playersPerTeam: 2),
      now: DateTime.utc(2026, 8, 31),
    );
    for (var index = 0; index < 8; index++) {
      draft = engine.addTeam(
        draft,
        name: [
          'صقور الجزيرة',
          'ذئاب المدرج',
          'نجوم الرياض',
          'الموج الأزرق',
          'الأساطير',
          'قلعة الفرسان',
          'نمور الملاعب',
          'الملكي',
        ][index],
        players: ['لاعب ${index * 2 + 1}', 'لاعب ${index * 2 + 2}'],
      );
    }
    var bracketDraft = engine.create(
      name: 'بطولة الشتاء الكبرى',
      organizerId: 'organizer',
      rules: const TournamentRules(capacity: 8, playersPerTeam: 2),
      now: DateTime.utc(2026, 8, 31),
    );
    for (final name in [
      'نجوم الرياض',
      'الموج الأزرق',
      'ذئاب المدرج',
      'قلعة الفرسان',
      'صقور الجزيرة',
      'الأساطير',
      'نمور الملاعب',
      'الملكي',
    ]) {
      bracketDraft = engine.addTeam(bracketDraft, name: name);
    }
    bracket = engine.generateBracket(bracketDraft, randomSeed: 11);
    final bracketMatches = bracket.matches
        .where((match) => match.round == 1)
        .toList();
    bracket = engine.confirmResult(
      bracket,
      matchId: bracketMatches[0].id,
      scoreA: 3,
      scoreB: 1,
    );
    bracket = engine.confirmResult(
      bracket,
      matchId: bracketMatches[1].id,
      scoreA: 0,
      scoreB: 2,
    );

    var hubDraft = engine.create(
      name: 'بطولة الشتاء الكبرى',
      organizerId: 'organizer',
      rules: const TournamentRules(capacity: 8, playersPerTeam: 2),
      now: DateTime.utc(2026, 8, 31),
    );
    for (final name in [
      'نجوم الرياض',
      'الموج الأزرق',
      'ذئاب المدرج',
      'قلعة الفرسان',
      'الأساطير',
      'الملكي',
      'صقور الجزيرة',
      'العميد',
    ]) {
      hubDraft = engine.addTeam(hubDraft, name: name);
    }
    hub = engine.generateBracket(hubDraft, randomSeed: 11);
    final hubMatches = hub.matches.where((match) => match.round == 1).toList();
    for (final match in hubMatches.take(2)) {
      hub = engine.confirmResult(
        hub,
        matchId: match.id,
        scoreA: 300,
        scoreB: 100,
      );
    }

    var semifinalDraft = engine.create(
      name: 'كأس الأربعة',
      organizerId: 'organizer',
      rules: const TournamentRules(capacity: 4),
      now: DateTime.utc(2026, 8, 31),
    );
    for (final name in ['الصقور', 'المدرج', 'التكتيك', 'الأساطير']) {
      semifinalDraft = engine.addTeam(semifinalDraft, name: name);
    }
    semifinal = engine.generateBracket(semifinalDraft, randomSeed: 11);
    final semifinalMatches = semifinal.matches
        .where((match) => match.round == 1)
        .toList();
    finalStage = semifinal;
    for (final match in semifinalMatches) {
      finalStage = engine.confirmResult(
        finalStage,
        matchId: match.id,
        scoreA: 600,
        scoreB: 300,
      );
    }
    final finalMatch = finalStage.matches.singleWhere(
      (match) => match.round == 2,
    );
    champion = engine.confirmResult(
      finalStage,
      matchId: finalMatch.id,
      scoreA: 900,
      scoreB: 700,
    );

    var matchDraft = engine.create(
      name: 'بطولة الشتاء الكبرى',
      organizerId: 'organizer',
      rules: const TournamentRules(capacity: 4),
      now: DateTime.utc(2026, 8, 31),
    );
    for (final name in [
      'نجوم الرياض',
      'صقور الجزيرة',
      'الموج الأزرق',
      'ذئاب المدرج',
    ]) {
      matchDraft = engine.addTeam(matchDraft, name: name);
    }
    matchStage = engine.generateBracket(matchDraft, randomSeed: 3);

    var championDraft = engine.create(
      name: 'بطولة أحدعش الليلية',
      organizerId: 'organizer',
      rules: const TournamentRules(capacity: 4),
      now: DateTime.utc(2026, 8, 31),
    );
    for (final name in ['الأساطير', 'المدرج', 'صقور الجزيرة', 'التكتيك']) {
      championDraft = engine.addTeam(championDraft, name: name);
    }
    var championStage = engine.generateBracket(championDraft, randomSeed: 11);
    for (final match
        in championStage.matches.where((match) => match.round == 1).toList()) {
      final a = championStage.team(match.teamAId)!.name;
      final b = championStage.team(match.teamBId)!.name;
      final aWins = a == 'الأساطير' || (a == 'صقور الجزيرة' && b != 'الأساطير');
      championStage = engine.confirmResult(
        championStage,
        matchId: match.id,
        scoreA: aWins ? 600 : 300,
        scoreB: aWins ? 300 : 600,
      );
    }
    final championship = championStage.matches.singleWhere(
      (match) => match.round == 2,
    );
    final championshipA = championStage.team(championship.teamAId)!.name;
    champion = engine.confirmResult(
      championStage,
      matchId: championship.id,
      scoreA: championshipA == 'الأساطير' ? 900 : 700,
      scoreB: championshipA == 'الأساطير' ? 700 : 900,
    );
  }

  late Tournament draft;
  late Tournament hub;
  late Tournament bracket;
  late Tournament semifinal;
  late Tournament finalStage;
  late Tournament matchStage;
  late Tournament champion;

  Tournament forScreen(_TournamentVisual screen) => switch (screen) {
    _TournamentVisual.hub => hub,
    _TournamentVisual.teams || _TournamentVisual.draw => draft,
    _TournamentVisual.create => draft,
    _TournamentVisual.bracket => bracket,
    _TournamentVisual.semifinal => semifinal,
    _TournamentVisual.finalMatch => finalStage,
    _TournamentVisual.match => matchStage,
    _TournamentVisual.champion => champion,
  };
}
