import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/ahdash_icons.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('atlas captures Sign In at text scale 1.3', (tester) async {
    await _pump(tester, mode: AuthMode.signIn, textScale: 1.3);
    await _capture(tester, 'auth_sign_in_text_scale_1.3_390x844.png');
  });

  testWidgets('atlas captures Create Account at text scale 1.3', (
    tester,
  ) async {
    await _pump(tester, mode: AuthMode.createAccount, textScale: 1.3);
    await _capture(tester, 'auth_create_account_text_scale_1.3_390x844.png');
  });

  for (final mode in AuthMode.values) {
    testWidgets('atlas captures ${mode.name} validation errors', (
      tester,
    ) async {
      await _pump(tester, mode: mode);
      await tester.tap(find.byKey(const ValueKey('auth-primary-action')));
      await tester.pumpAndSettle();
      expect(find.text('أدخل بريدًا إلكترونيًا صحيحًا'), findsOneWidget);
      await _capture(tester, 'auth_${mode.name}_validation_390x844.png');
    });
  }

  testWidgets('atlas captures filled Sign In with visible password', (
    tester,
  ) async {
    await _pump(tester, mode: AuthMode.signIn);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'fixture@example.test');
    await tester.enterText(fields.at(1), 'FixturePass11');
    await tester.tap(find.byIcon(AhdashIcons.visibility));
    await tester.pumpAndSettle();
    await _capture(tester, 'auth_sign_in_password_visible_390x844.png');
  });

  testWidgets('atlas captures filled Create Account form', (tester) async {
    await _pump(tester, mode: AuthMode.createAccount);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'لاعب اختبار');
    await tester.enterText(fields.at(1), 'fixture@example.test');
    await tester.enterText(fields.at(2), 'FixturePass11');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _capture(tester, 'auth_create_account_filled_fixture_390x844.png');
  });

  testWidgets('atlas captures local submit progress', (tester) async {
    await _pump(
      tester,
      mode: AuthMode.signIn,
      repository: _AtlasAuthRepository.gated(signInGate: Completer<AuthUser>()),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'fixture@example.test');
    await tester.enterText(fields.at(1), 'FixturePass11');
    await tester.tap(find.byKey(const ValueKey('auth-primary-action')));
    await tester.pump();
    await _capture(tester, 'auth_sign_in_submitting_fixture_390x844.png');
  });

  testWidgets('atlas captures Google action progress', (tester) async {
    await _pump(
      tester,
      mode: AuthMode.signIn,
      repository: _AtlasAuthRepository.gated(socialGate: Completer<AuthUser>()),
    );
    await tester.tap(find.byKey(const ValueKey('auth-google-action')));
    await tester.pump();
    await _capture(tester, 'auth_google_loading_fixture_390x844.png');
  });

  testWidgets('atlas captures safe Google failure', (tester) async {
    await _pump(
      tester,
      mode: AuthMode.signIn,
      repository: const _AtlasAuthRepository(failSocial: true),
    );
    await tester.tap(find.byKey(const ValueKey('auth-google-action')));
    await tester.pumpAndSettle();
    expect(find.textContaining('StateError'), findsNothing);
    await _capture(tester, 'auth_google_failure_fixture_390x844.png');
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required AuthMode mode,
  double textScale = 1,
  AuthRepository repository = const _AtlasAuthRepository(),
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(() {
    FocusManager.instance.primaryFocus?.unfocus();
    debugDefaultTargetPlatformOverride = null;
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      appConfigProvider.overrideWithValue(_config),
      appServicesProvider.overrideWithValue(const AppServices.noop()),
      appPreferencesProvider.overrideWithBuild(
        (ref, notifier) async => const AppPreferences(reducedMotion: true),
      ),
      appContentProvider.overrideWithBuild(
        (ref, notifier) async => AppContentBundle.defaults,
      ),
      authRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: testApp(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
          ),
          child: RepaintBoundary(
            key: const ValueKey('atlas-auth-boundary'),
            child: AuthScreen(initialMode: mode),
          ),
        ),
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final boundary = find.byKey(const ValueKey('atlas-auth-boundary'));
  final providers = tester
      .widgetList<Image>(
        find.descendant(of: boundary, matching: find.byType(Image)),
      )
      .map((image) => image.image)
      .toList(growable: false);
  await tester.runAsync(() async {
    await Future.wait(
      providers.map(
        (provider) => precacheImage(provider, tester.element(boundary)),
      ),
    );
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  const output = String.fromEnvironment('V10_ATLAS_SOURCE_DIR');
  if (output.isNotEmpty) {
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('atlas-auth-boundary')),
      );
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('$output/$name');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }
  debugDefaultTargetPlatformOverride = null;
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

final class _AtlasAuthRepository implements AuthRepository {
  const _AtlasAuthRepository({this.failSocial = false})
    : signInGate = null,
      socialGate = null;

  _AtlasAuthRepository.gated({this.signInGate, this.socialGate})
    : failSocial = false;

  final Completer<AuthUser>? signInGate;
  final Completer<AuthUser>? socialGate;
  final bool failSocial;

  @override
  Future<AuthUser?> restore() async => null;

  @override
  Future<AuthUser> continueAsGuest() async =>
      const AuthUser(id: 'fixture-atlas-guest', username: 'ضيف', isGuest: true);

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      signInGate?.future ??
      Future<AuthUser>.value(
        const AuthUser(
          id: 'fixture-atlas-account',
          username: 'fixture',
          isGuest: false,
        ),
      );

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) async => const AuthUser(
    id: 'fixture-atlas-created',
    username: 'fixture-created',
    isGuest: false,
  );

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) async {
    if (failSocial) throw StateError('fixture social failure');
    final user =
        await (socialGate?.future ??
            Future<AuthUser>.value(
              const AuthUser(
                id: 'fixture-atlas-social',
                username: 'fixture',
                isGuest: false,
              ),
            ));
    return SocialSignInAuthenticated(user);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}
