import 'dart:io';
import 'dart:ui' as ui;

import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/core/theme/app_colors.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_catalog_provider.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_game_screens.dart';
import 'package:ahdash_11/features/party/presentation/party_gameplay_visuals.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_screens.dart';
import 'package:ahdash_11/features/party/presentation/party_v2_ui.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/party_phase4_fixture.dart';
import '../helpers/test_app.dart';

const _boundary = ValueKey('test-app-boundary');

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final font = FontLoader('ThmanyahSans');
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      font.addFont(
        rootBundle.load('assets/fonts/thmanyah/thmanyahsans-$weight.otf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  final cases = <_CaptureCase>[
    _CaptureCase(
      'categories/category_selection_primary_390x844.png',
      const Size(390, 844),
      const PartyCategorySelectionScreen(),
    ),
    _CaptureCase(
      'categories/category_selection_compact_360x800.png',
      const Size(360, 800),
      const PartyCategorySelectionScreen(),
    ),
    _CaptureCase(
      'categories/category_selection_6_selected_390x844.png',
      const Size(390, 844),
      const PartyCategorySelectionScreen(),
      selectedCategoryIds: _categoryIds,
    ),
    _CaptureCase(
      'categories/category_selection_premium_locked_390x844.png',
      const Size(390, 844),
      const PartyCategorySelectionScreen(),
      catalog: _premiumCatalog,
    ),
    _CaptureCase(
      'categories/category_detail_normal_390x844.png',
      const Size(390, 844),
      PartyCategoryDetailPanel(
        category: _detailCategory,
        sample: _sample,
        playable: true,
      ),
    ),
    _CaptureCase(
      'categories/category_detail_premium_390x844.png',
      const Size(390, 844),
      PartyCategoryDetailPanel(
        category: _premiumDetailCategory,
        sample: _sample,
        playable: true,
        locked: true,
        onPremium: _noop,
      ),
    ),
    _CaptureCase(
      'categories/category_detail_media_fallback_390x844.png',
      const Size(390, 844),
      PartyCategoryDetailPanel(
        category: _fallbackDetailCategory,
        sample: _sample,
        playable: true,
      ),
      allowImageError: true,
    ),
    _CaptureCase(
      'helpers/helpers_default_390x844.png',
      const Size(390, 844),
      const PartyHelperSelectionScreen(),
      teams: _emptyHelperTeams,
      selectedCategoryIds: _categoryIds,
    ),
    _CaptureCase(
      'helpers/helpers_selected_390x844.png',
      const Size(390, 844),
      const PartyHelperSelectionScreen(),
      teams: _teams,
      selectedCategoryIds: _categoryIds,
    ),
    _CaptureCase(
      'ready/ready_primary_390x844.png',
      const Size(390, 844),
      const PartyReadyScreen(),
      selectedCategoryIds: _categoryIds,
      session: _midBoardSession,
    ),
    _CaptureCase(
      'ready/ready_compact_360x800.png',
      const Size(360, 800),
      const PartyReadyScreen(),
      selectedCategoryIds: _categoryIds,
      session: _midBoardSession,
    ),
    _CaptureCase(
      'board/board_fresh_390x844.png',
      const Size(390, 844),
      const PartyBoardScreen(),
      session: _freshBoardSession,
    ),
    _CaptureCase(
      'board/board_mid_game_390x844.png',
      const Size(390, 844),
      const PartyBoardScreen(),
      session: _midBoardSession,
    ),
    _CaptureCase(
      'board/board_near_complete_390x844.png',
      const Size(390, 844),
      const PartyBoardScreen(),
      session: _nearCompleteBoardSession,
    ),
    _CaptureCase(
      'board/board_compact_360x800.png',
      const Size(360, 800),
      const PartyBoardScreen(),
      session: _midBoardSession,
    ),
    _CaptureCase(
      'questions/text_question_primary_390x844.png',
      const Size(390, 844),
      PartyQuestionScreen(fixedNow: phase4Clock),
      session: _questionSession(),
    ),
    _CaptureCase(
      'questions/text_question_compact_360x800.png',
      const Size(360, 800),
      PartyQuestionScreen(fixedNow: phase4Clock),
      session: _questionSession(),
    ),
    _CaptureCase(
      'questions/text_question_helper_active_390x844.png',
      const Size(390, 844),
      PartyQuestionScreen(fixedNow: phase4Clock),
      session: _questionSession().copyWith(
        armedHelper: PartyHelperId.twoChances,
        helperActionDetail: 'جاوب جوابين مفعّل لهذا السؤال',
      ),
    ),
    _CaptureCase(
      'questions/image_question_primary_390x844.png',
      const Size(390, 844),
      PartyQuestionScreen(fixedNow: phase4Clock),
      session: _questionSession(image: true),
    ),
    _CaptureCase(
      'questions/image_question_compact_360x800.png',
      const Size(360, 800),
      PartyQuestionScreen(fixedNow: phase4Clock),
      session: _questionSession(image: true),
    ),
    _CaptureCase(
      'questions/image_question_loaded_390x844.png',
      const Size(390, 844),
      PartyQuestionScreen(fixedNow: phase4Clock),
      session: _questionSession(image: true),
    ),
    _CaptureCase(
      'questions/image_question_fallback_390x844.png',
      const Size(390, 844),
      PartyQuestionScreen(fixedNow: phase4Clock),
      session: _questionSession(image: true, missingImage: true),
      allowImageError: true,
    ),
    _CaptureCase(
      'reveal/answer_reveal_390x844.png',
      const Size(390, 844),
      const PartyRevealScreen(),
      session: _revealSession,
    ),
    _CaptureCase(
      'result/final_result_winner_390x844.png',
      const Size(390, 844),
      const PartyResultScreen(),
      session: _completedSession,
    ),
  ];

  for (final item in cases) {
    testWidgets('capture ${item.path}', (tester) async {
      await _pumpScreen(tester, item);
      if (item.allowImageError) {
        while (tester.takeException() != null) {}
      }
      expect(tester.takeException(), isNull);
      await _capture(tester, item.path);
    });
  }

  testWidgets('capture integrated category search state', (tester) async {
    await _pumpScreen(
      tester,
      const _CaptureCase(
        'categories/category_selection_search_390x844.png',
        Size(390, 844),
        PartyCategorySelectionScreen(),
        viewInsets: EdgeInsets.only(bottom: 300),
      ),
    );
    final search = find.byKey(const ValueKey('party-category-search'));
    await tester.enterText(search, 'سعودي');
    await tester.showKeyboard(search);
    await tester.pumpAndSettle();
    expect(find.text('الدوري السعودي'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'categories/category_selection_search_390x844.png');
  });

  testWidgets('capture selected scoring state', (tester) async {
    await _pumpScreen(
      tester,
      _CaptureCase(
        'reveal/scoring_selected_390x844.png',
        const Size(390, 844),
        const PartyRevealScreen(),
        session: _revealSession,
      ),
    );
    await tester.tap(find.text('صقور الجزيرة').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await _capture(tester, 'reveal/scoring_selected_390x844.png');
  });

  for (final entry in const {
    'artwork/category_pitch.png': PartyGameplayArtworkScene.category,
    'artwork/ready_floodlights.png': PartyGameplayArtworkScene.ready,
    'artwork/image_question_fallback.png':
        PartyGameplayArtworkScene.imageFallback,
    'artwork/final_result_trophy.png': PartyGameplayArtworkScene.result,
  }.entries) {
    testWidgets('capture ${entry.key}', (tester) async {
      await _pumpArtwork(tester, entry.value);
      await _capture(tester, entry.key);
    });
  }

  for (final frame in const [
    (path: 'motion_keyframes/reveal_00.png', progress: 0.0),
    (path: 'motion_keyframes/reveal_50.png', progress: .5),
    (path: 'motion_keyframes/reveal_100.png', progress: 1.0),
  ]) {
    testWidgets('capture ${frame.path}', (tester) async {
      await _pumpArtwork(
        tester,
        PartyGameplayArtworkScene.result,
        progress: frame.progress,
      );
      await _capture(tester, frame.path);
    });
  }

  testWidgets('capture primary green button states', (tester) async {
    _setViewport(tester, const Size(390, 390));
    await tester.pumpWidget(const ProviderScope(child: _ButtonStateSheet()));
    await tester.pump(const Duration(milliseconds: 100));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('button-pressed'))),
    );
    await tester.pump();
    await _capture(tester, 'details/primary_green_button_states.png');
    await gesture.up();
  });
}

void _noop() {}

Future<void> _pumpScreen(WidgetTester tester, _CaptureCase item) async {
  _setViewport(tester, item.size);
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  final state = PartyGameState(
    selectedCategoryIds: item.selectedCategoryIds,
    teams: item.teams,
    hasSetupDraft: true,
    teamSetupCompleted: true,
    splitterStatus: PartySplitterStatus.skipped,
    session: item.session,
    restored: true,
  );
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      appPreferencesProvider.overrideWithBuild(
        (_, _) async => const AppPreferences(
          soundEffects: false,
          haptics: false,
          reducedMotion: true,
        ),
      ),
      partyCatalogProvider.overrideWith((_) async => item.catalog ?? _catalog),
      partyEntitlementProvider.overrideWith((_) async => false),
      partyHelperCatalogProvider.overrideWith(
        (_) async => defaultPartyHelperDefinitions,
      ),
      partyRuntimeSettingsProvider.overrideWith(
        (_) async => const PartyRuntimeSettings(),
      ),
      partyGameControllerProvider.overrideWithBuild((_, _) => state),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: testApp(
        MediaQuery(
          data: MediaQueryData(
            size: item.size,
            devicePixelRatio: 1,
            textScaler: const TextScaler.linear(1),
            disableAnimations: true,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
            viewInsets: item.viewInsets,
          ),
          child: item.child,
        ),
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final images = item.allowImageError
      ? const <Image>[]
      : tester.widgetList<Image>(find.byType(Image)).toList();
  if (images.isNotEmpty) {
    final context = tester.element(find.byType(MaterialApp));
    await tester.runAsync(
      () => Future.wait(
        images.map((widget) => precacheImage(widget.image, context)),
      ),
    );
    await tester.pump();
  }
}

Future<void> _pumpArtwork(
  WidgetTester tester,
  PartyGameplayArtworkScene scene, {
  double progress = 1,
}) async {
  _setViewport(tester, const Size(390, 300));
  await tester.pumpWidget(
    testApp(
      Scaffold(
        backgroundColor: AppColors.paper0,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF173F34),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: PartyGameplayArtwork(
                scene: scene,
                accent: AppColors.primary,
                onDark: true,
                progress: progress,
              ),
            ),
          ),
        ),
      ),
      theme: AppTheme.light,
    ),
  );
  await tester.pump();
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

Future<void> _capture(WidgetTester tester, String relativePath) async {
  const output = String.fromEnvironment('GAMEPLAY_VISUAL_DIR');
  if (output.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundary),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$output/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

final class _ButtonStateSheet extends StatelessWidget {
  const _ButtonStateSheet();

  @override
  Widget build(BuildContext context) => testApp(
    Scaffold(
      backgroundColor: AppColors.paper0,
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'حالات الزر الأساسي',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            PartyPrimaryButton(
              key: const ValueKey('button-normal'),
              label: 'عادي',
              onPressed: _noop,
              feedback: false,
            ),
            const SizedBox(height: 10),
            PartyPrimaryButton(
              key: const ValueKey('button-pressed'),
              label: 'مضغوط',
              onPressed: _noop,
              feedback: false,
            ),
            const SizedBox(height: 10),
            const PartyPrimaryButton(label: 'غير متاح', onPressed: null),
            const SizedBox(height: 10),
            const PartyPrimaryButton(
              label: 'جارٍ التحميل',
              onPressed: null,
              busy: true,
            ),
          ],
        ),
      ),
    ),
    theme: AppTheme.light,
  );
}

final class _CaptureCase {
  const _CaptureCase(
    this.path,
    this.size,
    this.child, {
    this.session,
    this.catalog,
    this.teams = _teams,
    this.selectedCategoryIds = const [],
    this.viewInsets = EdgeInsets.zero,
    this.allowImageError = false,
  });

  final String path;
  final Size size;
  final Widget child;
  final PartyGameSession? session;
  final PartyCatalog? catalog;
  final List<PartyTeam> teams;
  final List<String> selectedCategoryIds;
  final EdgeInsets viewInsets;
  final bool allowImageError;
}

const _sample = QuizQuestion(
  id: 'sample',
  text: 'من سجل هدف الفوز في النهائي القاري؟',
  options: ['اللاعب أحدعش'],
  correctOptionIndex: 0,
  categoryId: 'category-0',
  difficulty: QuestionDifficulty.easy,
  correctAnswer: 'اللاعب أحدعش',
  pointValue: 100,
);

const _categoryNames = [
  'كأس العالم',
  'الدوري السعودي',
  'أساطير الكرة',
  'سوق الانتقالات',
  'خطط وتكتيك',
  'دوري أبطال أوروبا',
];

const _categoryImages = [
  'assets/images/v10_h3_visual_fixtures/world_cup.png',
  'assets/images/v10_h3_visual_fixtures/saudi_league.png',
  'assets/images/v10_h3_visual_fixtures/legends.png',
  'assets/images/v10_h3_visual_fixtures/transfer_market.png',
  'assets/images/v10_h3_visual_fixtures/tactics.png',
  'assets/images/v10_h3_visual_fixtures/champions_league.png',
];

final _categories = List.generate(
  6,
  (index) => QuizCategory(
    id: 'category-$index',
    name: _categoryNames[index],
    description: index == 1
        ? 'هوية الكرة السعودية من المدرج إلى لحظة الحسم.'
        : 'فئة كروية بأسئلة متنوعة من المحتوى المنشور.',
    iconName: 'sports_soccer',
    imageUrl: _categoryImages[index],
    accentColor: Color(phase4BoardSession.categories[index].colorValue),
  ),
);

final _premiumCategories = [
  QuizCategory(
    id: 'category-0',
    name: 'كواليس البطولات',
    description: 'فئة حصرية لمشتركي Premium.',
    iconName: 'workspace_premium',
    imageUrl: _categoryImages.first,
    accentColor: AppColors.gold,
    accessTier: 'premium',
  ),
  ..._categories.skip(1),
];

List<QuizQuestion> _questionsFor(List<QuizCategory> categories) =>
    List.generate(
      36,
      (index) => QuizQuestion(
        id: 'catalog-$index',
        text: 'سؤال ${index + 1}',
        options: const ['إجابة'],
        correctOptionIndex: 0,
        categoryId: categories[index ~/ 6].id,
        difficulty: QuestionDifficulty.values[(index % 6) ~/ 2],
        correctAnswer: 'إجابة',
        pointValue: index % 6 < 2
            ? 100
            : index % 6 < 4
            ? 200
            : 300,
      ),
    );

PartyCatalog _buildCatalog(List<QuizCategory> categories) => PartyCatalog(
  categories: categories,
  questions: _questionsFor(categories),
  healthByCategoryId: {
    for (final category in categories)
      category.id: const PartyCategoryHealth(easy: 2, medium: 2, hard: 2),
  },
);

final _catalog = _buildCatalog(_categories);
final _premiumCatalog = _buildCatalog(_premiumCategories);
final _categoryIds = _categories.map((category) => category.id).toList();

final _detailCategory = QuizCategory(
  id: 'category-detail',
  name: 'الدوري السعودي',
  description: 'هوية الكرة السعودية من المدرج إلى لحظة الحسم.',
  iconName: 'sports_soccer',
  imageUrl: 'assets/images/v10_h3_visual_fixtures/saudi_detail.png',
  accentColor: const Color(0xFF1E874B),
  seasonLabel: 'الموسم الحالي',
  gameplayInstructions: 'اختر الفئة ضمن تشكيلتك ثم ابدأ المنافسة.',
);

final _premiumDetailCategory = QuizCategory(
  id: 'category-premium',
  name: 'كواليس البطولات',
  description: 'تفاصيل حصرية من البطولات الكبرى، متاحة عبر Premium.',
  iconName: 'workspace_premium',
  imageUrl: _categoryImages.first,
  accentColor: AppColors.gold,
  accessTier: 'premium',
);

const _fallbackDetailCategory = QuizCategory(
  id: 'category-fallback',
  name: 'خطط وتكتيك',
  description: 'اقرأ الملعب واختبر معرفتك بالتشكيلات والتحولات.',
  iconName: 'sports_soccer',
  imageUrl: 'assets/images/does_not_exist.png',
  accentColor: Color(0xFF1E874B),
);

const _teams = [
  PartyTeam(
    name: 'صقور الجزيرة',
    colorValue: 0xFFE43D74,
    players: ['سلمان', 'فيصل'],
    selectedHelpers: {
      PartyHelperId.twoChances,
      PartyHelperId.callFriend,
      PartyHelperId.risk,
    },
  ),
  PartyTeam(
    name: 'ذئاب المدرج',
    colorValue: 0xFF1E874B,
    players: ['نواف', 'تركي'],
    selectedHelpers: {
      PartyHelperId.bench,
      PartyHelperId.pass,
      PartyHelperId.twoChances,
    },
  ),
];

const _emptyHelperTeams = [
  PartyTeam(
    name: 'صقور الجزيرة',
    colorValue: 0xFFE43D74,
    players: ['سلمان', 'فيصل'],
  ),
  PartyTeam(
    name: 'ذئاب المدرج',
    colorValue: 0xFF1E874B,
    players: ['نواف', 'تركي'],
  ),
];

PartyGameSession _boardSession({
  required int usedThrough,
}) => phase4BoardSession.copyWith(
  teams: _teams,
  helperDefinitions: defaultPartyHelperDefinitions,
  categories: [
    for (
      var categoryIndex = 0;
      categoryIndex < phase4BoardSession.categories.length;
      categoryIndex++
    )
      PartyCategorySnapshot(
        id: phase4BoardSession.categories[categoryIndex].id,
        name: const [
          'انتقالات',
          'أساطير',
          'ملاعب',
          'تاريخ',
          'عالمي',
          'سعودي',
        ][categoryIndex],
        colorValue: phase4BoardSession.categories[categoryIndex].colorValue,
        ownerTeamIndex:
            phase4BoardSession.categories[categoryIndex].ownerTeamIndex,
        questions: [
          for (
            var questionIndex = 0;
            questionIndex <
                phase4BoardSession.categories[categoryIndex].questions.length;
            questionIndex++
          )
            phase4BoardSession
                .categories[categoryIndex]
                .questions[questionIndex]
                .copyWith(
                  used: categoryIndex * 6 + questionIndex < usedThrough,
                ),
        ],
      ),
  ],
  scores: usedThrough == 0
      ? const [0, 0]
      : usedThrough < 30
      ? const [500, 400]
      : const [1100, 900],
  turnTeamIndex: usedThrough.isEven ? 0 : 1,
);

final _freshBoardSession = _boardSession(usedThrough: 0);
final _midBoardSession = _boardSession(usedThrough: 12);
final _nearCompleteBoardSession = _boardSession(usedThrough: 35);

PartyGameSession _questionSession({
  bool image = false,
  bool missingImage = false,
}) {
  final sourceCategory = _midBoardSession.categories.first;
  final sourceQuestion = sourceCategory.questions.first;
  final question = PartyQuestionSnapshot(
    id: sourceQuestion.id,
    categoryId: sourceCategory.id,
    text: image
        ? 'في أي مدينة سعودية يقع هذا الملعب التاريخي الذي احتضن نهائيات دولية كبرى؟'
        : 'من سجل هدف الفوز في نهائي البطولة القارية بعد مباراة امتدت إلى الأشواط الإضافية؟',
    answer: 'ماجد عبد الله',
    alternativeAnswers: const [],
    difficulty: QuestionDifficulty.easy,
    pointValue: image ? 200 : 100,
    format: image ? PartyQuestionFormat.image : PartyQuestionFormat.openAnswer,
    imageUrl: image
        ? missingImage
              ? 'assets/images/does_not_exist.png'
              : 'assets/images/backgrounds/v10_question_stadium.png'
        : null,
    mechanicConfig: image
        ? const {'aspect_ratio': 2.1518987342, 'focal_x': 0.5, 'focal_y': 0.5}
        : const {},
    explanation: 'سجل هدف الحسم في الشوط الإضافي الأول.',
  );
  final category = PartyCategorySnapshot(
    id: sourceCategory.id,
    name: image ? 'ملاعب وتاريخ' : 'دوري روشن السعودي للمحترفين',
    colorValue: 0xFF1E874B,
    ownerTeamIndex: 0,
    questions: [question, ...sourceCategory.questions.skip(1)],
  );
  return _midBoardSession.copyWith(
    categories: [category, ..._midBoardSession.categories.skip(1)],
    activeQuestionId: question.id,
    answeringTeamIndex: 0,
    questionTimerStartedAt: phase4Clock.subtract(
      Duration(seconds: image ? 12 : 6),
    ),
    questionTimerDurationSeconds: 30,
  );
}

final _revealSession = _questionSession().copyWith(
  revealed: true,
  clearQuestionTimer: true,
);

final _completedSession = _boardSession(usedThrough: 36).copyWith(
  scores: const [1400, 1100],
  scoreEvents: phase4CompletedSession().scoreEvents,
  completedAt: phase4Clock,
);
