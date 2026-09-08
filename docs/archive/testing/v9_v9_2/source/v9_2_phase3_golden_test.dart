import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_catalog_provider.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_screens.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

enum _Phase3Screen {
  categories,
  categoryDetail,
  teams,
  splitter,
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
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
  });

  for (final size in const [
    Size(800, 360),
    Size(844, 390),
    Size(915, 412),
    Size(1280, 720),
    Size(1366, 768),
  ]) {
    for (final screen in _Phase3Screen.values) {
      final dimensions = '${size.width.round()}x${size.height.round()}';
      testWidgets('V9.2 Phase 3 ${screen.name} $dimensions light', (
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
        final key = ValueKey('${screen.name}-$dimensions');
        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(_config),
            appPreferencesProvider.overrideWithBuild(
              (ref, notifier) async => const AppPreferences(
                soundEffects: false,
                haptics: false,
                reducedMotion: true,
              ),
            ),
            partyCatalogProvider.overrideWith((ref) async => _catalog),
            partyEntitlementProvider.overrideWith((ref) async => false),
            partyHelperCatalogProvider.overrideWith(
              (ref) async => defaultPartyHelperDefinitions,
            ),
            partyRuntimeSettingsProvider.overrideWith(
              (ref) async => const PartyRuntimeSettings(),
            ),
            partyGameControllerProvider.overrideWithBuild(
              (ref, notifier) => _stateFor(screen),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: testApp(
              MediaQuery(
                data: MediaQueryData(size: size, disableAnimations: true),
                child: RepaintBoundary(key: key, child: _screen(screen)),
              ),
              theme: AppTheme.light,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(key),
          matchesGoldenFile(
            '../../../docs/visual-validation/v9_2_phase3/'
            '${screen.name}_${dimensions}_light.png',
          ),
        );
      });
    }
  }
}

Widget _screen(_Phase3Screen screen) => switch (screen) {
  _Phase3Screen.categories => const PartyCategorySelectionScreen(),
  _Phase3Screen.categoryDetail => PartyCategoryDetailPanel(
    category: _categories.first,
  ),
  _Phase3Screen.teams => const PartyTeamSetupScreen(),
  _Phase3Screen.splitter => const PartyTeamSplitterScreen(),
  _Phase3Screen.helpers => const PartyHelperSelectionScreen(),
  _Phase3Screen.ready => const PartyReadyScreen(),
};

PartyGameState _stateFor(_Phase3Screen screen) => PartyGameState(
  selectedCategoryIds: screen == _Phase3Screen.categories
      ? _categoryIds.take(4).toList(growable: false)
      : _categoryIds,
  teams: screen == _Phase3Screen.helpers ? _helperPreviewTeams : _readyTeams,
  teamSetupCompleted: screen != _Phase3Screen.categories,
  splitterStatus: screen == _Phase3Screen.splitter
      ? PartySplitterStatus.completed
      : PartySplitterStatus.skipped,
  splitterPlayers: const ['سلمان', 'نواف', 'فيصل', 'تركي'],
  favoriteCategoryIds: const {'category-0', 'category-3'},
  hasSetupDraft: true,
  restored: true,
);

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
    slug: 'category-$index',
    name: const [
      'دوري روشن السعودي',
      'دوري أبطال أوروبا',
      'المنتخبات',
      'سوق الانتقالات',
      'أساطير الملاعب',
      'عين الصقر',
    ][index],
    description: 'وصف منشور يعرّف محتوى الفئة باختصار.',
    iconName: 'sports_soccer',
    accentColor: Color(
      const [
        0xFF78B814,
        0xFFB77A00,
        0xFF2368A2,
        0xFFB63863,
        0xFF7446A8,
        0xFF14805D,
      ][index],
    ),
    subcategories: const ['محلية', 'عالمية'],
    groupKey: index.isEven ? 'competitions' : 'players',
    seasonLabel: '2026/27',
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

const _readyTeams = [
  PartyTeam(
    name: 'الصقور',
    colorValue: 0xFF2368A2,
    players: ['سلمان', 'فيصل'],
    selectedHelpers: {
      PartyHelperId.twoChances,
      PartyHelperId.callFriend,
      PartyHelperId.bench,
    },
  ),
  PartyTeam(
    name: 'النجوم',
    colorValue: 0xFFB63863,
    players: ['نواف', 'تركي'],
    selectedHelpers: {
      PartyHelperId.risk,
      PartyHelperId.pass,
      PartyHelperId.bench,
    },
  ),
];

const _helperPreviewTeams = [
  PartyTeam(
    name: 'الصقور',
    colorValue: 0xFF2368A2,
    players: ['سلمان', 'فيصل'],
    selectedHelpers: {PartyHelperId.twoChances, PartyHelperId.callFriend},
  ),
  PartyTeam(
    name: 'النجوم',
    colorValue: 0xFFB63863,
    players: ['نواف', 'تركي'],
    selectedHelpers: {PartyHelperId.risk, PartyHelperId.pass},
  ),
];
