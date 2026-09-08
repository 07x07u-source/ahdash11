import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/game/domain/game_mode.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_catalog_provider.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_screens.dart';
import 'package:ahdash_11/features/party/presentation/party_v2_ui.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:ahdash_11/shared/presentation/ahdash_pictograms.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => _testDatabase = AppDatabase(NativeDatabase.memory()));
  tearDownAll(() => _testDatabase.close());

  testWidgets(
    'Category Selection shows loading, empty, and safe error states',
    (tester) async {
      final pending = Completer<PartyCatalog>();
      await _pump(
        tester,
        const PartyCategorySelectionScreen(),
        catalog: pending.future,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await _pump(
        tester,
        const PartyCategorySelectionScreen(),
        catalog: Future.value(
          const PartyCatalog(categories: [], questions: []),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('لا توجد فئات منشورة بعد.'), findsOneWidget);

      final failure = Completer<PartyCatalog>();
      await _pump(
        tester,
        const PartyCategorySelectionScreen(),
        catalog: failure.future,
      );
      failure.completeError(StateError('private backend detail'));
      await tester.pumpAndSettle();
      expect(find.text('تعذر تحميل الفئات الآن.'), findsOneWidget);
      expect(find.textContaining('private backend detail'), findsNothing);
    },
  );

  testWidgets('Category search handles Arabic, no-results, and clear', (
    tester,
  ) async {
    await _pump(
      tester,
      const PartyCategorySelectionScreen(),
      catalog: Future.value(_catalog),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('party-category-search')),
      'غير موجود',
    );
    await tester.pump();
    expect(find.text('ما لقينا فئة جاهزة بهذا البحث.'), findsOneWidget);
    expect(find.byTooltip('مسح البحث'), findsOneWidget);

    await tester.tap(find.byTooltip('مسح البحث'));
    await tester.pump();
    expect(find.text(_categories.first.name), findsOneWidget);
  });

  testWidgets('Category Selection exposes the real selected state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const PartyCategorySelectionScreen(),
      catalog: Future.value(_catalog),
      state: PartyGameState(
        selectedCategoryIds: [_categoryIds.first],
        hasSetupDraft: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('فئة 1.*مختارة')), findsOneWidget);
    expect(find.textContaining('1 من 6'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Category Detail uses published data without a fake trial', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 720)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
    await _pump(
      tester,
      PartyCategoryDetailPanel(category: _categories.first, playable: true),
    );

    expect(find.text(_categories.first.name), findsOneWidget);
    expect(find.text('وصف منشور'), findsOneWidget);
    expect(find.text('عدد الأسئلة متغير'), findsOneWidget);
    expect(find.textContaining('تجربة'), findsNothing);
  });

  testWidgets('Team Setup reports duplicate names inline in Arabic', (
    tester,
  ) async {
    await _pump(
      tester,
      const PartyTeamSetupScreen(),
      state: PartyGameState(
        selectedCategoryIds: _categoryIds,
        teams: const [
          PartyTeam(name: 'الصقور', colorValue: 0xFF2368A2),
          PartyTeam(name: ' الصقور ', colorValue: 0xFFB63863),
        ],
        hasSetupDraft: true,
      ),
    );
    expect(find.text('اختر اسمين مختلفين للفريقين.'), findsOneWidget);
    final next = tester.widget<PartyPrimaryButton>(
      find.widgetWithText(PartyPrimaryButton, 'التالي'),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets(
    'optional splitter keeps a skip action and real entered players',
    (tester) async {
      await _pump(
        tester,
        const PartyTeamSplitterScreen(),
        state: PartyGameState(
          selectedCategoryIds: _categoryIds,
          teamSetupCompleted: true,
          splitterStatus: PartySplitterStatus.requested,
          splitterPlayers: const ['آلاء', 'هند'],
          hasSetupDraft: true,
        ),
      );
      expect(find.text('تخطي'), findsOneWidget);
      expect(find.textContaining('سلمان'), findsNothing);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'آلاء\nهند');
    },
  );

  testWidgets('Helpers render five real labels and distinct pictograms', (
    tester,
  ) async {
    await _pump(
      tester,
      const PartyHelperSelectionScreen(),
      state: PartyGameState(
        selectedCategoryIds: _categoryIds,
        teamSetupCompleted: true,
        splitterStatus: PartySplitterStatus.skipped,
        hasSetupDraft: true,
      ),
    );
    for (final helper in PartyHelperId.values) {
      await tester.scrollUntilVisible(find.text(helper.label), 100);
      expect(find.text(helper.label), findsWidgets);
    }
    // The list is lazy; inspect each helper's visible pictogram while scrolling.
    for (final helper in PartyHelperId.values.reversed) {
      await tester.scrollUntilVisible(find.text(helper.label), -100);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is AhdashPictogramView &&
              w.pictogram == partyHelperPictogram(helper, helper.iconKey),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('Ready Start reflects the canonical validation result', (
    tester,
  ) async {
    await _pump(
      tester,
      const PartyReadyScreen(),
      catalog: Future.value(_catalog),
      state: PartyGameState(
        selectedCategoryIds: _categoryIds,
        teamSetupCompleted: true,
        splitterStatus: PartySplitterStatus.skipped,
        hasSetupDraft: true,
      ),
    );
    await tester.pumpAndSettle();
    var start = tester.widget<PartyPrimaryButton>(
      find.widgetWithText(PartyPrimaryButton, 'يلا نبدأ'),
    );
    expect(start.onPressed, isNull);

    await _pump(
      tester,
      const PartyReadyScreen(),
      catalog: Future.value(_catalog),
      state: PartyGameState(
        selectedCategoryIds: _categoryIds,
        teams: _readyTeams,
        teamSetupCompleted: true,
        splitterStatus: PartySplitterStatus.completed,
        hasSetupDraft: true,
      ),
    );
    await tester.pumpAndSettle();
    start = tester.widget<PartyPrimaryButton>(
      find.widgetWithText(PartyPrimaryButton, 'يلا نبدأ'),
    );
    expect(start.onPressed, isNotNull);
  });

  testWidgets('Ready exposes loading and a safe retryable error', (
    tester,
  ) async {
    await _pump(
      tester,
      const PartyReadyScreen(),
      catalog: Future.value(_catalog),
      state: PartyGameState(
        selectedCategoryIds: _categoryIds,
        teams: _readyTeams,
        teamSetupCompleted: true,
        splitterStatus: PartySplitterStatus.completed,
        hasSetupDraft: true,
        busy: true,
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await _pump(
      tester,
      const PartyReadyScreen(),
      catalog: Future.value(_catalog),
      state: PartyGameState(
        selectedCategoryIds: _categoryIds,
        teams: _readyTeams,
        teamSetupCompleted: true,
        splitterStatus: PartySplitterStatus.completed,
        hasSetupDraft: true,
        error: 'تعذر بدء الجولة. حاول مرة أخرى.',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('تعذر بدء الجولة. حاول مرة أخرى.'), findsOneWidget);
    final retry = tester.widget<PartyPrimaryButton>(
      find.widgetWithText(PartyPrimaryButton, 'يلا نبدأ'),
    );
    expect(retry.onPressed, isNotNull);
  });

  testWidgets('Ready success starts once and navigates to the board', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_config),
        appDatabaseProvider.overrideWithValue(database),
        appPreferencesProvider.overrideWithBuild(
          (ref, notifier) async =>
              const AppPreferences(soundEffects: false, haptics: false),
        ),
        partyCatalogProvider.overrideWith((ref) async => _playableCatalog),
        partyEntitlementProvider.overrideWith((ref) async => false),
        partyHelperCatalogProvider.overrideWith(
          (ref) async => defaultPartyHelperDefinitions,
        ),
        partyRuntimeSettingsProvider.overrideWith(
          (ref) async => const PartyRuntimeSettings(),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });
    final controller = container.read(partyGameControllerProvider.notifier);
    controller.beginNewGame();
    controller.setRandomCategories(_categoryIds);
    controller.updateTeam(0, name: 'الصقور');
    controller.updateTeam(1, name: 'النجوم');
    expect(controller.completeTeamSetup(useSplitter: false), isNull);
    for (final helper in const [
      PartyHelperId.twoChances,
      PartyHelperId.callFriend,
      PartyHelperId.risk,
    ]) {
      expect(controller.toggleHelper(0, helper), isTrue);
      expect(controller.toggleHelper(1, helper), isTrue);
    }

    final router = GoRouter(
      initialLocation: '/party/ready',
      routes: [
        GoRoute(
          path: '/party/ready',
          builder: (_, _) => const PartyReadyScreen(),
        ),
        GoRoute(
          path: '/party/board',
          builder: (_, _) => const Scaffold(body: Text('BOARD')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PartyPrimaryButton, 'يلا نبدأ'));
    await tester.pumpAndSettle();

    expect(find.text('BOARD'), findsOneWidget);
    expect(container.read(partyGameControllerProvider).session, isNotNull);
  });

  for (final size in const [
    Size(360, 800),
    Size(390, 844),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ]) {
    testWidgets('core setup screens fit RTL at ${size.width}×${size.height}', (
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
      for (final screen in <Widget>[
        const PartyTeamSetupScreen(),
        const PartyTeamSplitterScreen(),
        const PartyHelperSelectionScreen(),
        const PartyReadyScreen(),
      ]) {
        await _pump(
          tester,
          screen,
          catalog: Future.value(_catalog),
          state: PartyGameState(
            selectedCategoryIds: _categoryIds,
            teams: _readyTeams,
            teamSetupCompleted: true,
            splitterStatus: PartySplitterStatus.completed,
            splitterPlayers: const ['سلمان', 'نواف'],
            hasSetupDraft: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} at $size',
        );
        expect(
          Directionality.of(tester.element(find.byType(screen.runtimeType))),
          TextDirection.rtl,
        );
        expect(find.textContaining('Coin'), findsNothing);
        expect(find.textContaining('Online'), findsNothing);
      }
    });
  }

  for (final size in const [Size(360, 800), Size(390, 844)]) {
    testWidgets('keyboard-safe Party inputs at ${size.width}×${size.height}', (
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
      final state = PartyGameState(
        selectedCategoryIds: _categoryIds,
        teams: _readyTeams,
        hasSetupDraft: true,
      );
      for (final entry in <(Widget, String)>[
        (const PartyCategorySelectionScreen(), 'party-category-search'),
        (const PartyTeamSetupScreen(), 'party-team-name-0'),
        (const PartyTeamSetupScreen(), 'party-team-name-1'),
        (
          const PartyTeamSplitterSheet(initialNames: ['سلمان', 'نواف']),
          'party-splitter-player-input',
        ),
      ]) {
        await _pump(
          tester,
          entry.$1,
          catalog: Future.value(_catalog),
          state: state,
        );
        await tester.pumpAndSettle();
        final field = find.byKey(ValueKey(entry.$2));
        await tester.tap(field);
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isTrue);
        expect(tester.getRect(field).top, lessThan(size.height - 300));
        expect(tester.takeException(), isNull);
      }
    });
  }

  for (final scale in const [1.0, 1.2, 1.3]) {
    testWidgets(
      'Team Splitter supports long Arabic names at text scale $scale',
      (tester) async {
        tester.view
          ..physicalSize = const Size(390, 844)
          ..devicePixelRatio = 1;
        addTearDown(() {
          tester.view
            ..resetPhysicalSize()
            ..resetDevicePixelRatio();
        });
        await _pump(
          tester,
          const PartyTeamSplitterScreen(),
          textScaler: TextScaler.linear(scale),
          catalog: Future.value(_catalog),
          state: PartyGameState(
            selectedCategoryIds: _categoryIds,
            teams: const [
              PartyTeam(
                name: 'صقور الجزيرة العربية',
                colorValue: 0xFFB63863,
                players: [
                  'عبدالرحمن بن محمد القحطاني',
                  'فيصل عبدالله الشهراني',
                  'محمد بن أحمد الغامدي',
                ],
              ),
              PartyTeam(
                name: 'ذئاب المدرج الأخضر',
                colorValue: 0xFF1E874B,
                players: [
                  'سعود بن خالد العتيبي',
                  'خالد عبدالعزيز الدوسري',
                  'عبدالله بن ناصر المطيري',
                ],
              ),
            ],
            teamSetupCompleted: true,
            splitterStatus: PartySplitterStatus.completed,
            splitterPlayers: const [
              'عبدالرحمن بن محمد القحطاني',
              'فيصل عبدالله الشهراني',
              'محمد بن أحمد الغامدي',
              'سعود بن خالد العتيبي',
              'خالد عبدالعزيز الدوسري',
              'عبدالله بن ناصر المطيري',
            ],
            hasSetupDraft: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('عبدالرحمن'), findsWidgets);
      },
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  PartyGameState state = const PartyGameState(restored: true),
  Future<PartyCatalog>? catalog,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        appDatabaseProvider.overrideWithValue(_testDatabase),
        appConfigProvider.overrideWithValue(_config),
        partyCatalogProvider.overrideWith(
          (ref) =>
              catalog ??
              Future.value(const PartyCatalog(categories: [], questions: [])),
        ),
        partyEntitlementProvider.overrideWith((ref) async => false),
        partyHelperCatalogProvider.overrideWith(
          (ref) async => defaultPartyHelperDefinitions,
        ),
        partyRuntimeSettingsProvider.overrideWith(
          (ref) async => const PartyRuntimeSettings(),
        ),
        partyGameControllerProvider.overrideWithBuild((ref, notifier) => state),
      ],
      child: testApp(
        MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: screen,
        ),
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pump();
}

late AppDatabase _testDatabase;

const _config = AppConfig(
  environment: AppEnvironment.development,
  supabaseUrl: '',
  supabaseKey: '',
  firebaseEnabled: false,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
);

final _categoryIds = List.generate(6, (index) => 'category-$index');
final _categories = List.generate(
  6,
  (index) => QuizCategory(
    id: _categoryIds[index],
    name: 'فئة ${index + 1}',
    description: 'وصف منشور',
    iconName: 'sports_soccer',
    accentColor: const Color(0xFF14805D),
  ),
);
final _catalog = PartyCatalog(
  categories: _categories,
  questions: const [],
  healthByCategoryId: {
    for (final id in _categoryIds)
      id: const PartyCategoryHealth(easy: 2, medium: 2, hard: 2),
  },
);
final _playableCatalog = PartyCatalog(
  categories: _categories,
  questions: _questionPool,
  healthByCategoryId: {
    for (final id in _categoryIds)
      id: const PartyCategoryHealth(easy: 2, medium: 2, hard: 2),
  },
);
final _questionPool = [
  for (final category in _categories)
    for (final difficulty in const [
      QuestionDifficulty.easy,
      QuestionDifficulty.medium,
      QuestionDifficulty.hard,
    ])
      for (var index = 0; index < 2; index++)
        QuizQuestion(
          id: '${category.id}-${difficulty.name}-$index',
          text: 'سؤال ${category.id} ${difficulty.name} $index',
          options: const ['الإجابة', 'ب', 'ج', 'د'],
          correctOptionIndex: 0,
          categoryId: category.id,
          difficulty: difficulty,
          gameType: GameType.classic,
          format: QuestionFormat.openAnswer,
          correctAnswer: 'الإجابة',
        ),
];
final _readyTeams = [
  const PartyTeam(
    name: 'الصقور',
    colorValue: 0xFF2368A2,
    players: ['سلمان'],
    selectedHelpers: {
      PartyHelperId.twoChances,
      PartyHelperId.callFriend,
      PartyHelperId.bench,
    },
  ),
  const PartyTeam(
    name: 'النجوم',
    colorValue: 0xFFB63863,
    players: ['نواف'],
    selectedHelpers: {
      PartyHelperId.risk,
      PartyHelperId.pass,
      PartyHelperId.bench,
    },
  ),
];
