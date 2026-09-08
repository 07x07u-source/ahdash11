import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/storage/app_database.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_catalog_provider.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_game_screens.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_screens.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/party_phase4_fixture.dart';
import '../helpers/test_app.dart';
import '../helpers/visual_test_variant.dart';

void main() => registerVisualTests();

void registerVisualTests({VisualTestVariant? variant}) {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await (FontLoader('ThmanyahSans')
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Regular.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Medium.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Bold.otf'),
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

  final setupCases = <_GoldenCase>[
    _GoldenCase(
      '06_categories_390x844',
      const Size(390, 844),
      const PartyCategorySelectionScreen(),
    ),
    _GoldenCase(
      '06_categories_360x800',
      const Size(360, 800),
      const PartyCategorySelectionScreen(),
    ),
    _GoldenCase(
      '06_search_keyboard_390x844',
      const Size(390, 844),
      const PartyCategorySelectionScreen(),
      focusKey: 'party-category-search',
    ),
    _GoldenCase(
      '07_detail_390x844',
      const Size(390, 844),
      PartyCategoryDetailPanel(category: _detailCategory, sample: _sample),
    ),
    _GoldenCase(
      '07_detail_360x800',
      const Size(360, 800),
      PartyCategoryDetailPanel(category: _detailCategory, sample: _sample),
    ),
    _GoldenCase(
      '08_teams_390x844',
      const Size(390, 844),
      const PartyTeamSetupScreen(),
    ),
    _GoldenCase(
      '08_teams_360x800',
      const Size(360, 800),
      const PartyTeamSetupScreen(),
    ),
    _GoldenCase(
      '08_teams_keyboard_390x844',
      const Size(390, 844),
      const PartyTeamSetupScreen(),
      focusKey: 'party-team-name-0',
    ),
    _GoldenCase(
      '08_teams_keyboard_360x800',
      const Size(360, 800),
      const PartyTeamSetupScreen(),
      focusKey: 'party-team-name-0',
    ),
    _GoldenCase(
      '09_splitter_390x844',
      const Size(390, 844),
      const PartyTeamSplitterScreen(),
      splitterCompleted: true,
    ),
    _GoldenCase(
      '09_splitter_360x800',
      const Size(360, 800),
      const PartyTeamSplitterScreen(),
      splitterCompleted: true,
    ),
    _GoldenCase(
      '09_splitter_keyboard_390x844',
      const Size(390, 844),
      const PartyTeamSplitterScreen(),
      focusKey: 'party-splitter-player-input',
    ),
    _GoldenCase(
      '10_helpers_390x844',
      const Size(390, 844),
      const PartyHelperSelectionScreen(),
    ),
    _GoldenCase(
      '10_helpers_360x800',
      const Size(360, 800),
      const PartyHelperSelectionScreen(),
    ),
    _GoldenCase(
      '11_ready_390x844',
      const Size(390, 844),
      const PartyReadyScreen(),
    ),
    _GoldenCase(
      '11_ready_360x800',
      const Size(360, 800),
      const PartyReadyScreen(),
    ),
  ];
  for (final item in setupCases) {
    if (variant != null && item.size.width != 390) continue;
    testWidgets('V10 Phase B ${item.name}', (tester) async {
      await _pumpGolden(
        tester,
        item,
        session: phase4BoardSession,
        variant: variant,
      );
    });
  }

  final gameplayCases = <_GoldenCase>[
    for (final size in const [Size(390, 844), Size(360, 800)]) ...[
      _GoldenCase(
        '12_board_${size.width.round()}x${size.height.round()}',
        size,
        const PartyBoardScreen(),
        session: _v10BoardSession,
        lockedSafeAreas: true,
      ),
      _GoldenCase(
        '13_text_${size.width.round()}x${size.height.round()}',
        size,
        PartyQuestionScreen(fixedNow: phase4Clock),
        session: _v10QuestionSession(),
        lockedSafeAreas: true,
      ),
      _GoldenCase(
        '14_image_${size.width.round()}x${size.height.round()}',
        size,
        PartyQuestionScreen(fixedNow: phase4Clock),
        session: _v10QuestionSession(image: true),
        lockedSafeAreas: true,
      ),
      _GoldenCase(
        '15_reveal_${size.width.round()}x${size.height.round()}',
        size,
        const PartyRevealScreen(),
        session: _v10RevealSession(),
        lockedSafeAreas: true,
      ),
      _GoldenCase(
        '16_result_${size.width.round()}x${size.height.round()}',
        size,
        const PartyResultScreen(),
        session: _v10CompletedSession(),
        lockedSafeAreas: true,
      ),
    ],
  ];
  for (final item in gameplayCases) {
    if (variant != null && item.size.width != 390) continue;
    testWidgets('V10 Phase B ${item.name}', (tester) async {
      await _pumpGolden(tester, item, session: item.session!, variant: variant);
    });
  }
}

const _v10Teams = [
  PartyTeam(
    name: 'صقور الجزيرة',
    colorValue: 0xFF1E874B,
    players: ['سلمان', 'فيصل'],
    selectedHelpers: {PartyHelperId.risk, PartyHelperId.twoChances},
  ),
  PartyTeam(
    name: 'ذئاب المدرج',
    colorValue: 0xFFE43D74,
    players: ['نواف', 'تركي'],
  ),
];

const _v10BoardTeams = [
  PartyTeam(
    name: 'صقور الجزيرة',
    colorValue: 0xFFE43D74,
    players: ['سلمان', 'فيصل'],
    selectedHelpers: {PartyHelperId.risk, PartyHelperId.twoChances},
  ),
  PartyTeam(
    name: 'ذئاب المدرج',
    colorValue: 0xFF1E874B,
    players: ['نواف', 'تركي'],
  ),
];

const _v10HelperDefinitions = [
  PartyHelperDefinition(
    id: PartyHelperId.twoChances,
    label: 'جاوب جوابين (٢ متبقي)',
    description: 'فرصتان للإجابة',
    iconKey: 'looks_two',
    timing: PartyHelperTiming.beforeQuestion,
  ),
  PartyHelperDefinition(
    id: PartyHelperId.risk,
    label: 'الحفرة (١ متبقي)',
    description: 'إجابة صحيحة تخصم من الخصم',
    iconKey: 'trending_up',
    timing: PartyHelperTiming.beforeQuestion,
  ),
];

final _v10BoardSession = phase4BoardSession.copyWith(
  teams: _v10BoardTeams,
  helperDefinitions: _v10HelperDefinitions,
  categories: [
    for (var index = 0; index < phase4BoardSession.categories.length; index++)
      PartyCategorySnapshot(
        id: phase4BoardSession.categories[index].id,
        name: const [
          'انتقال',
          'أساطير',
          'انتقال',
          'تاريخ',
          'عالمي',
          'سعودي',
        ][index],
        colorValue: phase4BoardSession.categories[index].colorValue,
        ownerTeamIndex: phase4BoardSession.categories[index].ownerTeamIndex,
        questions: [
          for (
            var questionIndex = 0;
            questionIndex <
                phase4BoardSession.categories[index].questions.length;
            questionIndex++
          )
            phase4BoardSession.categories[index].questions[questionIndex]
                .copyWith(used: index < 2 && questionIndex < 2),
        ],
      ),
  ],
);

const _v10ReadyTeams = [
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

const _v10SplitterTeams = [
  PartyTeam(
    name: 'صقور الجزيرة',
    colorValue: 0xFFE43D74,
    players: ['أحمد', 'فيصل', 'محمد'],
  ),
  PartyTeam(
    name: 'ذئاب المدرج',
    colorValue: 0xFF1E874B,
    players: ['سعود', 'خالد', 'عبدالله'],
  ),
];

PartyGameSession _v10QuestionSession({bool image = false}) {
  final sourceCategory = _v10BoardSession.categories.first;
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
        ? 'assets/images/backgrounds/v10_question_stadium.png'
        : null,
    mechanicConfig: image
        ? const {'aspect_ratio': 2.1518987342, 'focal_x': 0.5, 'focal_y': 0.5}
        : const {},
    explanation:
        'سجل هدف الحسم التاريخي في الدقيقة ١٠٤ من الشوط الإضافي الأول ليتوج فريقه باللقب الغالي.',
  );
  final category = PartyCategorySnapshot(
    id: sourceCategory.id,
    name: image ? 'ملاعب وتاريخ' : 'دوري روشن السعودي للمحترفين',
    colorValue: 0xFF1E874B,
    ownerTeamIndex: 0,
    questions: [question, ...sourceCategory.questions.skip(1)],
  );
  return _v10BoardSession.copyWith(
    teams: _v10Teams,
    categories: [category, ..._v10BoardSession.categories.skip(1)],
    activeQuestionId: question.id,
    questionTimerStartedAt: phase4Clock.subtract(
      Duration(seconds: image ? 12 : 6),
    ),
    questionTimerDurationSeconds: 30,
  );
}

PartyGameSession _v10RevealSession() =>
    _v10QuestionSession().copyWith(revealed: true, clearQuestionTimer: true);

PartyGameSession _v10CompletedSession() => _v10BoardSession.copyWith(
  categories: [
    for (final category in _v10BoardSession.categories)
      category.copyWith(
        questions: [
          for (final question in category.questions)
            question.copyWith(used: true),
        ],
      ),
  ],
  scores: const [900, 500],
  scoreEvents: phase4CompletedSession().scoreEvents,
  completedAt: phase4Clock,
);

Future<void> _pumpGolden(
  WidgetTester tester,
  _GoldenCase item, {
  required PartyGameSession session,
  VisualTestVariant? variant,
}) async {
  tester.view
    ..physicalSize = variant?.size ?? item.size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      appPreferencesProvider.overrideWithBuild(
        (ref, notifier) async => const AppPreferences(
          soundEffects: false,
          haptics: false,
          reducedMotion: true,
        ),
      ),
      partyCatalogProvider.overrideWith((ref) async => _catalog),
      partyHelperCatalogProvider.overrideWith(
        (ref) async => defaultPartyHelperDefinitions,
      ),
      partyRuntimeSettingsProvider.overrideWith(
        (ref) async => const PartyRuntimeSettings(),
      ),
      partyGameControllerProvider.overrideWithBuild(
        (ref, notifier) => PartyGameState(
          selectedCategoryIds: _categories.map((e) => e.id).toList(),
          teams: item.name.startsWith('09_splitter')
              ? _v10SplitterTeams
              : _v10ReadyTeams,
          hasSetupDraft: true,
          teamSetupCompleted: true,
          splitterStatus: item.splitterCompleted
              ? PartySplitterStatus.completed
              : PartySplitterStatus.skipped,
          splitterPlayers: const [
            'فيصل',
            'خالد',
            'سعود',
            'أحمد',
            'محمد',
            'عبدالله',
          ],
          // Review new layouts with real helper identities/timing. Keep the
          // legacy pixel-comparison fixture unchanged for its existing Goldens.
          session: variant == null
              ? session
              : session.copyWith(
                  helperDefinitions: defaultPartyHelperDefinitions,
                  teams: [
                    for (final team in session.teams)
                      team.copyWith(
                        selectedHelpers: {
                          PartyHelperId.twoChances,
                          PartyHelperId.callFriend,
                          PartyHelperId.risk,
                        },
                      ),
                  ],
                ),
          restored: true,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  final boundaryKey = ValueKey('golden-${item.name}');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: testApp(
        MediaQuery(
          data: MediaQueryData(
            size: variant?.size ?? item.size,
            devicePixelRatio: variant == null ? 1 : 2,
            textScaler: TextScaler.linear(variant?.scale ?? 1),
            disableAnimations: true,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
            viewInsets: item.focusKey == null
                ? EdgeInsets.zero
                : const EdgeInsets.only(bottom: 300),
          ),
          child: RepaintBoundary(key: boundaryKey, child: item.child),
        ),
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final images = tester
      .widgetList<Image>(
        find.descendant(
          of: find.byKey(boundaryKey),
          matching: find.byType(Image),
        ),
      )
      .map((widget) => widget.image)
      .toList(growable: false);
  if (images.isNotEmpty) {
    final imageContext = tester.element(find.byKey(boundaryKey));
    await tester.runAsync(
      () => Future.wait(
        images.map((provider) => precacheImage(provider, imageContext)),
      ),
    );
    await tester.pump();
  }
  if (item.focusKey != null) {
    final field = find.byKey(ValueKey(item.focusKey!));
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.showKeyboard(field);
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
  await verifyVisual(
    tester,
    find.byKey(boundaryKey),
    'goldens/v10_phase_b/${item.name}.png',
    variant,
  );
}

final class _GoldenCase {
  const _GoldenCase(
    this.name,
    this.size,
    this.child, {
    this.focusKey,
    this.session,
    this.lockedSafeAreas = false,
    this.splitterCompleted = false,
  });
  final String name;
  final Size size;
  final Widget child;
  final String? focusKey;
  final PartyGameSession? session;
  final bool lockedSafeAreas;
  final bool splitterCompleted;
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
        ? 'وصف الفئة من مزود البيانات — يتغير حسب الفئة المختارة'
        : 'فئة كروية بأسئلة متنوعة من المحتوى المنشور.',
    iconName: 'sports_soccer',
    imageUrl: _categoryImages[index],
    accentColor: Color(phase4BoardSession.categories[index].colorValue),
  ),
);

final _detailCategory = QuizCategory(
  id: 'category-detail',
  name: 'الدوري السعودي',
  description: 'وصف الفئة من مزود البيانات — يتغير حسب الفئة المختارة',
  iconName: 'sports_soccer',
  imageUrl: 'assets/images/v10_h3_visual_fixtures/saudi_detail.png',
  accentColor: const Color(0xFF1E874B),
);

final _catalog = PartyCatalog(
  categories: _categories,
  questions: List.generate(
    36,
    (index) => QuizQuestion(
      id: 'catalog-$index',
      text: 'سؤال ${index + 1}',
      options: const ['إجابة'],
      correctOptionIndex: 0,
      categoryId: 'category-${index ~/ 6}',
      difficulty: QuestionDifficulty.values[(index % 6) ~/ 2],
      correctAnswer: 'إجابة',
      pointValue: index % 6 < 2
          ? 100
          : index % 6 < 4
          ? 200
          : 300,
    ),
  ),
  healthByCategoryId: {
    for (final category in _categories)
      category.id: const PartyCategoryHealth(easy: 2, medium: 2, hard: 2),
  },
);
