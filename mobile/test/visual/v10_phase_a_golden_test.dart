import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_repository.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/auth/presentation/auth_screen.dart';
import 'package:ahdash_11/features/content/domain/app_content.dart';
import 'package:ahdash_11/features/content/presentation/app_content_controller.dart';
import 'package:ahdash_11/features/home/presentation/home_screen.dart';
import 'package:ahdash_11/features/onboarding/presentation/launch_screen.dart';
import 'package:ahdash_11/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

enum _State {
  launch,
  onboarding1,
  onboarding2,
  onboarding3,
  onboarding4,
  signIn,
  signInKeyboard,
  create,
  createKeyboard,
  home,
}

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

  for (final size in const [Size(360, 800), Size(390, 844)]) {
    for (final state in _State.values) {
      testWidgets('V10 Phase A ${state.name} ${size.width}x${size.height}', (
        tester,
      ) async {
        FocusManager.instance.primaryFocus?.unfocus();
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(() {
          tester.view
            ..resetPhysicalSize()
            ..resetDevicePixelRatio();
        });
        final keyboard =
            state == _State.signInKeyboard || state == _State.createKeyboard;
        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(_config),
            appServicesProvider.overrideWithValue(AppServices.noop()),
            appPreferencesProvider.overrideWithBuild(
              (ref, notifier) async =>
                  const AppPreferences(reducedMotion: true),
            ),
            appContentProvider.overrideWithBuild(
              (ref, notifier) async => AppContentBundle.defaults,
            ),
            authRepositoryProvider.overrideWithValue(
              const _GoldenAuthRepository(),
            ),
            partyGameControllerProvider.overrideWithBuild(
              (ref, notifier) => const PartyGameState(restored: true),
            ),
            tournamentControllerProvider.overrideWithBuild(
              (ref, notifier) => const TournamentState(restored: true),
            ),
          ],
        );
        addTearDown(container.dispose);
        const boundaryKey = ValueKey('v10-phase-a-boundary');
        final screen = switch (state) {
          _State.launch => const LaunchScreen(autoNavigate: false),
          _State.onboarding1 ||
          _State.onboarding2 ||
          _State.onboarding3 ||
          _State.onboarding4 => const OnboardingScreen(),
          _State.signIn || _State.signInKeyboard => AuthScreen(
            key: ValueKey('${state.name}-${size.width}'),
          ),
          _State.create || _State.createKeyboard => AuthScreen(
            key: ValueKey('${state.name}-${size.width}'),
            initialMode: AuthMode.createAccount,
          ),
          _State.home => const HomeScreen(),
        };
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: testApp(
              MediaQuery(
                data: MediaQueryData(
                  size: size,
                  disableAnimations: true,
                  padding: state == _State.launch
                      ? EdgeInsets.zero
                      : const EdgeInsets.only(top: 47, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                  viewInsets: EdgeInsets.only(bottom: keyboard ? 300 : 0),
                ),
                child: RepaintBoundary(key: boundaryKey, child: screen),
              ),
              theme: AppTheme.light,
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (state == _State.signIn || state == _State.create) {
          expect(
            find.byKey(const ValueKey('auth-google-action')),
            findsOneWidget,
          );
        }
        if (state == _State.signInKeyboard) {
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.first, 'saudi.fan@ahdash.sa');
          await tester.enterText(fields.last, 'pass');
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        } else if (state == _State.createKeyboard) {
          await tester.enterText(
            find.byType(TextFormField).first,
            'محمد السديري',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        }
        final onboardingStep = switch (state) {
          _State.onboarding2 => 1,
          _State.onboarding3 => 2,
          _State.onboarding4 => 3,
          _ => 0,
        };
        for (var index = 0; index < onboardingStep; index++) {
          await tester.tap(find.text('التالي'));
          await tester.pumpAndSettle();
        }
        final boundary = find.byKey(boundaryKey);
        final images = tester
            .widgetList<Image>(
              find.descendant(of: boundary, matching: find.byType(Image)),
            )
            .map((image) => image.image)
            .toList();
        final imageContext = tester.element(boundary);
        await tester.runAsync(() async {
          await Future.wait(
            images.map((image) => precacheImage(image, imageContext)),
          );
        });
        await tester.pumpAndSettle();
        if (keyboard) {
          await tester.ensureVisible(find.byType(TextFormField).first);
          await tester.pumpAndSettle();
          await tester.showKeyboard(find.byType(TextFormField).first);
          await tester.pumpAndSettle();
          await tester.drag(
            find.byKey(const ValueKey('v10-keyboard-scroll')),
            const Offset(0, 1000),
          );
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        final dimensions = '${size.width.round()}x${size.height.round()}';
        await expectLater(
          boundary,
          matchesGoldenFile(
            'goldens/v10_phase_a/${state.name}_$dimensions.png',
          ),
        );
        FocusManager.instance.primaryFocus?.unfocus();
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}

const _config = AppConfig(
  environment: AppEnvironment.production,
  supabaseUrl: 'https://example.supabase.co',
  supabaseKey: 'golden-anon-key',
  firebaseEnabled: false,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
  googleAuthEnabled: true,
  appleAuthEnabled: true,
);

final class _GoldenAuthRepository implements AuthRepository {
  const _GoldenAuthRepository();

  @override
  Future<AuthUser?> restore() async => null;
  @override
  Future<AuthUser> continueAsGuest() async =>
      const AuthUser(id: 'guest', username: 'ضيف', isGuest: true);
  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) => throw UnimplementedError();
  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) =>
      throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
}
