import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/auth/presentation/auth_screen.dart';
import 'package:ahdash_11/features/content/domain/app_content.dart';
import 'package:ahdash_11/features/content/presentation/app_content_controller.dart';
import 'package:ahdash_11/features/home/presentation/home_screen.dart';
import 'package:ahdash_11/features/onboarding/presentation/launch_screen.dart';
import 'package:ahdash_11/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Phase2Screen { launch, onboarding, signIn, createAccount, home }

void main() {
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

  const sizes = [
    Size(800, 360),
    Size(844, 390),
    Size(915, 412),
    Size(1280, 720),
    Size(1366, 768),
  ];

  for (final size in sizes) {
    for (final screen in _Phase2Screen.values) {
      final dimensions = '${size.width.round()}x${size.height.round()}';
      final fileName = '${screen.name}_$dimensions.png';
      testWidgets('V9.2 Phase 2 $fileName', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(() {
          tester.view
            ..resetPhysicalSize()
            ..resetDevicePixelRatio();
        });
        final container = _container();
        addTearDown(container.dispose);
        final key = ValueKey(fileName);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              locale: const Locale('ar'),
              home: MediaQuery(
                data: MediaQueryData(size: size, disableAnimations: true),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: RepaintBoundary(key: key, child: _screen(screen)),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await _precacheImages(tester, key);
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(key),
          matchesGoldenFile(
            '../../../docs/visual-validation/v9-2-phase2/$fileName',
          ),
        );
      });
    }
  }
}

ProviderContainer _container() => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(_testConfig),
    appPreferencesProvider.overrideWithBuild(
      (ref, notifier) async => const AppPreferences(
        onboardingCompleted: true,
        soundEffects: false,
        haptics: false,
        reducedMotion: true,
      ),
    ),
    authControllerProvider.overrideWithBuild((ref, notifier) async => null),
    appContentProvider.overrideWithBuild(
      (ref, notifier) async => AppContentBundle.defaults,
    ),
    partyGameControllerProvider.overrideWithBuild(
      (ref, notifier) => const PartyGameState(restored: true),
    ),
    tournamentControllerProvider.overrideWithBuild(
      (ref, notifier) => const TournamentState(restored: true),
    ),
  ],
);

Widget _screen(_Phase2Screen screen) => switch (screen) {
  _Phase2Screen.launch => const LaunchScreen(autoNavigate: false),
  _Phase2Screen.onboarding => const OnboardingScreen(),
  _Phase2Screen.signIn => const AuthScreen(),
  _Phase2Screen.createAccount => const AuthScreen(
    initialMode: AuthMode.createAccount,
  ),
  _Phase2Screen.home => const HomeScreen(),
};

Future<void> _precacheImages(WidgetTester tester, Key key) async {
  final boundary = find.byKey(key);
  final providers = tester
      .widgetList<Image>(
        find.descendant(of: boundary, matching: find.byType(Image)),
      )
      .map((image) => image.image)
      .toList(growable: false);
  if (providers.isEmpty) return;
  final context = tester.element(boundary);
  await tester.runAsync(() async {
    await Future.wait(
      providers.map((provider) => precacheImage(provider, context)),
    );
  });
}

const _testConfig = AppConfig(
  environment: AppEnvironment.production,
  supabaseUrl: '',
  supabaseKey: '',
  firebaseEnabled: false,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
);
