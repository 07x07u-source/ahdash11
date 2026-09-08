import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/categories/domain/categories_repository.dart';
import 'package:ahdash_11/features/categories/presentation/categories_controller.dart';
import 'package:ahdash_11/features/home/presentation/home_screen.dart';
import 'package:ahdash_11/features/match/domain/quiz_question.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_catalog_provider.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_screens.dart';
import 'package:ahdash_11/features/party/presentation/party_support_screens.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

enum _PartyVisual {
  home,
  howTo,
  categories,
  categoryDetail,
  teams,
  teamSplitter,
  helpers,
  ready,
}

void main() {
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
    await (FontLoader('ThmanyahSerifDisplay')..addFont(
          rootBundle.load(
            'assets/fonts/thmanyah/thmanyahserifdisplay-Black.otf',
          ),
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

  const sizes = [
    Size(800, 360),
    Size(844, 390),
    Size(915, 412),
    Size(1280, 720),
    Size(1366, 768),
  ];
  for (final size in sizes) {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      for (final screen in _PartyVisual.values) {
        final dimensions = '${size.width.round()}x${size.height.round()}';
        final fileName = '${screen.name}_${dimensions}_${brightness.name}.png';
        testWidgets('party ${screen.name} $dimensions ${brightness.name}', (
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
          final container = ProviderContainer(
            overrides: [
              appConfigProvider.overrideWithValue(
                const AppConfig(
                  environment: AppEnvironment.production,
                  supabaseUrl: 'https://example.supabase.co',
                  supabaseKey: 'public-anon-key',
                  firebaseEnabled: false,
                  adMobEnabled: false,
                  revenueCatAndroidKey: '',
                  revenueCatIosKey: '',
                ),
              ),
              appPreferencesProvider.overrideWithBuild(
                (ref, notifier) async => const AppPreferences(
                  soundEffects: false,
                  haptics: false,
                  reducedMotion: true,
                ),
              ),
              categoriesRepositoryProvider.overrideWithValue(
                _PartyGoldenCategoriesRepository(_categories),
              ),
              partyCatalogProvider.overrideWith((ref) async => _catalog),
              partyHelperCatalogProvider.overrideWith(
                (ref) async => defaultPartyHelperDefinitions,
              ),
              partyRuntimeSettingsProvider.overrideWith(
                (ref) async => const PartyRuntimeSettings(),
              ),
              partyGameControllerProvider.overrideWithBuild(
                (ref, notifier) => _stateFor(screen),
              ),
              tournamentControllerProvider.overrideWithBuild(
                (ref, notifier) => const TournamentState(restored: true),
              ),
            ],
          );
          addTearDown(container.dispose);
          final key = ValueKey(fileName);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: testApp(
                MediaQuery(
                  data: MediaQueryData(size: size, disableAnimations: true),
                  child: RepaintBoundary(key: key, child: _screen(screen)),
                ),
                theme: brightness == Brightness.dark
                    ? AppTheme.dark
                    : AppTheme.light,
              ),
            ),
          );
          await tester.pump();
          final boundary = find.byKey(key);
          final imageProviders = tester
              .widgetList<Image>(
                find.descendant(of: boundary, matching: find.byType(Image)),
              )
              .map((image) => image.image)
              .toList(growable: false);
          if (imageProviders.isNotEmpty) {
            final imageContext = tester.element(boundary);
            await tester.runAsync(() async {
              await Future.wait(
                imageProviders.map(
                  (provider) => precacheImage(provider, imageContext),
                ),
              );
            });
          }
          await tester.pump();
          // Give the first asset-backed question an extra raster frame. Without
          // this, the first dark image golden can capture before decoding while
          // later cases pass only because the asset cache is warm.
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pump();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(key),
            matchesGoldenFile(
              '../../../docs/visual-validation/party/$fileName',
            ),
          );
        });
      }
    }
  }
}

final class _PartyGoldenCategoriesRepository implements CategoriesRepository {
  const _PartyGoldenCategoriesRepository(this.values);

  final List<QuizCategory> values;

  @override
  Future<List<QuizCategory>> loadCategories({
    bool forceRefresh = false,
  }) async => values;
}

Widget _screen(_PartyVisual value) => switch (value) {
  _PartyVisual.home => const HomeScreen(),
  _PartyVisual.howTo => const HowToPlayScreen(),
  _PartyVisual.categories => const PartyCategorySelectionScreen(),
  _PartyVisual.categoryDetail => PartyCategoryDetailPanel(
    category: _categories.first,
    sample: _sampleQuestion,
  ),
  _PartyVisual.teams => const PartyTeamSetupScreen(),
  _PartyVisual.teamSplitter => const PartyTeamSplitterSheet(
    initialNames: ['سلمان', 'نواف', 'فيصل', 'تركي'],
  ),
  _PartyVisual.helpers => const PartyHelperSelectionScreen(),
  _PartyVisual.ready => const PartyReadyScreen(),
};

PartyGameState _stateFor(_PartyVisual value) => PartyGameState(
  selectedCategoryIds: _categories.map((category) => category.id).toList(),
  teams: _teams,
  favoriteCategoryIds: const {'c0', 'c2'},
  session: _session,
  restored: true,
);

final _catalog = PartyCatalog(
  categories: _categories,
  questions: const [_sampleQuestion],
  healthByCategoryId: {
    for (final category in _categories)
      category.id: const PartyCategoryHealth(easy: 2, medium: 2, hard: 2),
  },
);
const _sampleQuestion = QuizQuestion(
  id: 'sample-question',
  text: 'من سجل هدف الفوز في النهائي القاري؟',
  options: ['اللاعب أحدعش', 'لاعب ثانٍ', 'لاعب ثالث', 'لاعب رابع'],
  correctOptionIndex: 0,
  categoryId: 'c0',
  difficulty: QuestionDifficulty.easy,
  correctAnswer: 'اللاعب أحدعش',
  explanation: 'معلومة قصيرة موثقة تظهر بعد كشف الإجابة.',
  pointValue: 100,
);
final _categories = List.generate(
  6,
  (index) => QuizCategory(
    id: 'c$index',
    name: [
      'دوري روشن السعودي للمحترفين',
      'دوري الأبطال',
      'المنتخبات',
      'سوق الانتقالات',
      'الأساطير',
      'عين الصقر',
    ][index],
    description: 'ستة أسئلة جاهزة ومتوازنة',
    iconName: 'sports_soccer',
    imageUrl: 'assets/visuals/eagle-eye-cover.png',
    accentColor: Color(
      [
        0xFF78B814,
        0xFFB77A00,
        0xFF2368A2,
        0xFFB63863,
        0xFF7446A8,
        0xFF14805D,
      ][index],
    ),
    groupKey: [
      'saudi',
      'leagues',
      'national_teams',
      'leagues',
      'players',
      'images',
    ][index],
    seasonLabel: index == 0 ? '2026/27' : null,
    featured: index == 1,
    isNew: index == 5,
  ),
);
const _teams = [
  PartyTeam(
    name: 'صقور الجزيرة العربية',
    colorValue: 0xFF2368A2,
    players: ['سلمان عبدالعزيز طويل الاسم', 'فيصل محمد'],
    selectedHelpers: {
      PartyHelperId.risk,
      PartyHelperId.twoChances,
      PartyHelperId.callFriend,
    },
  ),
  PartyTeam(
    name: 'ذئاب المدرج الجنوبي',
    colorValue: 0xFFB63863,
    players: ['نواف', 'تركي'],
    selectedHelpers: {
      PartyHelperId.pass,
      PartyHelperId.bench,
      PartyHelperId.callFriend,
    },
  ),
];
final _session = PartyGameSession(
  id: 'golden-party',
  teams: _teams,
  categories: List.generate(
    6,
    (categoryIndex) => PartyCategorySnapshot(
      id: 'c$categoryIndex',
      name: _categories[categoryIndex].name,
      colorValue: _categories[categoryIndex].accentColor.toARGB32(),
      ownerTeamIndex: categoryIndex < 3 ? 0 : 1,
      imageUrl: _categories[categoryIndex].imageUrl,
      focalX: _categories[categoryIndex].focalX,
      focalY: _categories[categoryIndex].focalY,
      questions: List.generate(
        6,
        (questionIndex) => PartyQuestionSnapshot(
          id: 'q-$categoryIndex-$questionIndex',
          categoryId: 'c$categoryIndex',
          text: questionIndex == 0
              ? 'من اللاعب الذي يظهر في هذه اللقطة الكروية؟'
              : 'من سجل هدف الفوز في نهائي البطولة القارية بعد مباراة امتدت إلى الأشواط الإضافية؟',
          answer: 'اللاعب أحدعش',
          difficulty: questionIndex < 2
              ? QuestionDifficulty.easy
              : questionIndex < 4
              ? QuestionDifficulty.medium
              : QuestionDifficulty.hard,
          pointValue: questionIndex < 2
              ? 100
              : questionIndex < 4
              ? 200
              : 300,
          format: questionIndex == 0
              ? PartyQuestionFormat.image
              : PartyQuestionFormat.openAnswer,
          imageUrl: questionIndex == 0
              ? 'assets/visuals/eagle-eye-cover.png'
              : null,
          explanation: 'معلومة قصيرة موثقة تظهر بعد كشف الإجابة.',
        ),
      ),
    ),
  ),
  timerSeconds: 30,
  createdAt: DateTime(2026, 8, 30),
  scores: const [700, 500],
);
