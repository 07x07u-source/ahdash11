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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

typedef _Case = ({String name, Size size, AuthMode mode, bool keyboard});

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

  const cases = <_Case>[
    (
      name: '03_sign_in_primary_390x844',
      size: Size(390, 844),
      mode: AuthMode.signIn,
      keyboard: false,
    ),
    (
      name: '03_sign_in_compact_360x800',
      size: Size(360, 800),
      mode: AuthMode.signIn,
      keyboard: false,
    ),
    (
      name: '03_sign_in_keyboard_390x844',
      size: Size(390, 844),
      mode: AuthMode.signIn,
      keyboard: true,
    ),
    (
      name: '04_create_account_primary_390x844',
      size: Size(390, 844),
      mode: AuthMode.createAccount,
      keyboard: false,
    ),
    (
      name: '04_create_account_compact_360x800',
      size: Size(360, 800),
      mode: AuthMode.createAccount,
      keyboard: false,
    ),
    (
      name: '04_create_account_keyboard_390x844',
      size: Size(390, 844),
      mode: AuthMode.createAccount,
      keyboard: true,
    ),
  ];

  for (final scenario in cases) {
    testWidgets('Android Auth UX ${scenario.name}', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view
        ..physicalSize = scenario.size
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(_config),
          appServicesProvider.overrideWithValue(AppServices.noop()),
          appPreferencesProvider.overrideWithBuild(
            (ref, notifier) async => const AppPreferences(reducedMotion: true),
          ),
          appContentProvider.overrideWithBuild(
            (ref, notifier) async => AppContentBundle.defaults,
          ),
          authRepositoryProvider.overrideWithValue(const _Repository()),
        ],
      );
      addTearDown(container.dispose);
      final boundaryKey = ValueKey('auth-ux-${scenario.name}');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(
            MediaQuery(
              data: MediaQueryData(
                size: scenario.size,
                disableAnimations: true,
                padding: const EdgeInsets.only(top: 47, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                viewInsets: EdgeInsets.only(
                  bottom: scenario.keyboard ? 300 : 0,
                ),
              ),
              child: RepaintBoundary(
                key: boundaryKey,
                child: AuthScreen(
                  key: ValueKey(scenario.name),
                  initialMode: scenario.mode,
                ),
              ),
            ),
            theme: AppTheme.light,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('auth-google-action')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-apple-action')), findsNothing);
      final imageProviders = tester
          .widgetList<Image>(
            find.descendant(
              of: find.byKey(boundaryKey),
              matching: find.byType(Image),
            ),
          )
          .map((image) => image.image)
          .toList(growable: false);
      await tester.runAsync(() async {
        await Future.wait(
          imageProviders.map(
            (provider) => precacheImage(
              provider,
              tester.element(find.byKey(boundaryKey)),
            ),
          ),
        );
      });
      await tester.pumpAndSettle();
      if (scenario.keyboard) {
        final field = find.byType(TextFormField).first;
        await tester.enterText(
          field,
          scenario.mode == AuthMode.signIn
              ? 'player@ahdash.sa'
              : 'محمد السديري',
        );
        await tester.showKeyboard(field);
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/auth_ux_repair/${scenario.name}.png'),
      );
      FocusManager.instance.primaryFocus?.unfocus();
      debugDefaultTargetPlatformOverride = null;
    });
  }
}

const _config = AppConfig(
  environment: AppEnvironment.production,
  supabaseUrl: 'https://example.supabase.co',
  supabaseKey: 'public-anon-key',
  firebaseEnabled: true,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
  googleAuthEnabled: true,
  appleAuthEnabled: true,
);

final class _Repository implements AuthRepository {
  const _Repository();

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
