import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_repository.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/content/domain/app_content.dart';
import 'package:ahdash_11/features/content/presentation/app_content_controller.dart';
import 'package:ahdash_11/features/home/presentation/home_screen.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/shared/presentation/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
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
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
  });

  for (final size in const [Size(360, 800), Size(390, 844), Size(430, 932)]) {
    testWidgets('AHDASH main dock on Home ${size.width}x${size.height}', (
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
          appConfigProvider.overrideWithValue(_config),
          appServicesProvider.overrideWithValue(const AppServices.noop()),
          appPreferencesProvider.overrideWithBuild(
            (ref, notifier) async => const AppPreferences(reducedMotion: true),
          ),
          appContentProvider.overrideWithBuild(
            (ref, notifier) async => AppContentBundle.defaults,
          ),
          authRepositoryProvider.overrideWithValue(const _AuthRepository()),
          partyGameControllerProvider.overrideWithBuild(
            (ref, notifier) => const PartyGameState(restored: true),
          ),
          tournamentControllerProvider.overrideWithBuild(
            (ref, notifier) => const TournamentState(restored: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      const boundaryKey = ValueKey('entry-main-dock-boundary');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                disableAnimations: true,
                padding: const EdgeInsets.only(top: 47, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: const RepaintBoundary(
                key: boundaryKey,
                child: AppShell(location: '/home', child: HomeScreen()),
              ),
            ),
            theme: AppTheme.light,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundary = find.byKey(boundaryKey);
      final imageContext = tester.element(boundary);
      final images = tester
          .widgetList<Image>(
            find.descendant(of: boundary, matching: find.byType(Image)),
          )
          .map((image) => image.image)
          .toList();
      await tester.runAsync(() async {
        await Future.wait(
          images.map((image) => precacheImage(image, imageContext)),
        );
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('main-dock-home')), findsOneWidget);
      expect(find.text('Online'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        boundary,
        matchesGoldenFile(
          'goldens/v10_entry_refinement/main_dock_home_${size.width.round()}x${size.height.round()}.png',
        ),
      );
    });
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

final class _AuthRepository implements AuthRepository {
  const _AuthRepository();

  static const user = AuthUser(
    id: 'entry-golden-player',
    username: 'سلمان',
    isGuest: false,
  );

  @override
  Future<AuthUser?> restore() async => user;

  @override
  Future<AuthUser> continueAsGuest() async => user;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async => user;

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) async => user;

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) async =>
      const SocialSignInAuthenticated(user);

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}
