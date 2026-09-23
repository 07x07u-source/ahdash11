import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

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
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

const _output = String.fromEnvironment('AUTH_ROUNDED_PREVIEW_DIR');

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
      name: '01_sign_in_390x844.png',
      size: Size(390, 844),
      mode: AuthMode.signIn,
      keyboard: false,
    ),
    (
      name: '02_create_account_390x844.png',
      size: Size(390, 844),
      mode: AuthMode.createAccount,
      keyboard: false,
    ),
    (
      name: '03_sign_in_keyboard_390x844.png',
      size: Size(390, 844),
      mode: AuthMode.signIn,
      keyboard: true,
    ),
    (
      name: '04_sign_in_compact_360x800.png',
      size: Size(360, 800),
      mode: AuthMode.signIn,
      keyboard: false,
    ),
    (
      name: '05_create_account_keyboard_390x844.png',
      size: Size(390, 844),
      mode: AuthMode.createAccount,
      keyboard: true,
    ),
    (
      name: '06_create_account_compact_360x800.png',
      size: Size(360, 800),
      mode: AuthMode.createAccount,
      keyboard: false,
    ),
  ];

  for (final scenario in cases) {
    testWidgets('simple rounded auth ${scenario.name}', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      tester.view
        ..physicalSize = scenario.size
        ..devicePixelRatio = 1;
      addTearDown(() {
        FocusManager.instance.primaryFocus?.unfocus();
        debugDefaultTargetPlatformOverride = null;
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
          authRepositoryProvider.overrideWithValue(const _Repository()),
          authStateChangesProvider.overrideWithValue(const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);
      final boundary = ValueKey('auth-rounded-${scenario.name}');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(
            MediaQuery(
              data: MediaQueryData(
                size: scenario.size,
                padding: const EdgeInsets.only(top: 47, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                viewInsets: EdgeInsets.only(
                  bottom: scenario.keyboard ? 300 : 0,
                ),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: boundary,
                child: AuthScreen(initialMode: scenario.mode),
              ),
            ),
            theme: AppTheme.light,
          ),
        ),
      );
      await tester.pumpAndSettle();

      if (scenario.keyboard) {
        final email = find.byType(TextFormField).first;
        await tester.enterText(email, 'player@ahdash.sa');
        await tester.showKeyboard(email);
        await tester.ensureVisible(email);
        await tester.pumpAndSettle();
      }

      final imageProviders = tester
          .widgetList<Image>(
            find.descendant(
              of: find.byKey(boundary),
              matching: find.byType(Image),
            ),
          )
          .map((image) => image.image)
          .toList(growable: false);
      await tester.runAsync(() async {
        await Future.wait(
          imageProviders.map(
            (provider) =>
                precacheImage(provider, tester.element(find.byKey(boundary))),
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      if (_output.isNotEmpty) {
        await _capture(tester, boundary, scenario.name);
      }
      debugDefaultTargetPlatformOverride = null;
    });
  }
}

Future<void> _capture(
  WidgetTester tester,
  ValueKey<String> boundaryKey,
  String name,
) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_output/$name');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
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

  static const user = AuthUser(
    id: 'rounded-auth-player',
    username: 'لاعب',
    isGuest: false,
  );

  @override
  Future<AuthUser?> restore() async => null;
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
