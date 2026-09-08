import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/party/domain/party_game.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_game_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/party_phase4_fixture.dart';
import '../helpers/test_app.dart';

enum _Phase4Screen { board, textQuestion, imageQuestion, reveal, result }

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

  for (final size in const [
    Size(800, 360),
    Size(844, 390),
    Size(915, 412),
    Size(1280, 720),
    Size(1366, 768),
  ]) {
    for (final screen in _Phase4Screen.values) {
      final dimensions = '${size.width.round()}x${size.height.round()}';
      testWidgets('V9.2 Phase 4 ${screen.name} $dimensions light', (
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
        final key = ValueKey('phase4-${screen.name}-$dimensions');
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
            partyGameControllerProvider.overrideWithBuild(
              (ref, notifier) =>
                  PartyGameState(session: _session(screen), restored: true),
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
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await expectLater(
          boundary,
          matchesGoldenFile(
            '../../../docs/visual-validation/v9_2_phase4/'
            '${screen.name}_$dimensions.png',
          ),
        );
      });
    }
  }
}

const _config = AppConfig(
  environment: AppEnvironment.production,
  supabaseUrl: '',
  supabaseKey: '',
  firebaseEnabled: false,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
);

Widget _screen(_Phase4Screen screen) => switch (screen) {
  _Phase4Screen.board => const PartyBoardScreen(),
  _Phase4Screen.textQuestion => PartyQuestionScreen(fixedNow: phase4Clock),
  _Phase4Screen.imageQuestion => PartyQuestionScreen(fixedNow: phase4Clock),
  _Phase4Screen.reveal => const PartyRevealScreen(),
  _Phase4Screen.result => const PartyResultScreen(),
};

PartyGameSession _session(_Phase4Screen screen) => switch (screen) {
  _Phase4Screen.board => phase4BoardSession,
  _Phase4Screen.textQuestion => phase4QuestionSession(),
  _Phase4Screen.imageQuestion => phase4QuestionSession(image: true),
  _Phase4Screen.reveal => phase4RevealSession(),
  _Phase4Screen.result => phase4CompletedSession(),
};
