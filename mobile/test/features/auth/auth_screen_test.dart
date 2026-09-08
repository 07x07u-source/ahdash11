import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/ads_service.dart';
import 'package:ahdash_11/core/services/analytics_service.dart';
import 'package:ahdash_11/core/services/app_error_reporter.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/services/crash_reporter.dart';
import 'package:ahdash_11/core/services/notification_service.dart';
import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_repository.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/auth/presentation/auth_screen.dart';
import 'package:ahdash_11/features/content/domain/app_content.dart';
import 'package:ahdash_11/features/content/presentation/app_content_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('sign in exposes the approved email and guest paths', (
    tester,
  ) async {
    _setSize(tester, const Size(844, 390));
    final repository = _FakeAuthRepository();
    final router = await _pumpAuth(tester, repository);
    addTearDown(router.dispose);

    expect(find.text('مستعد تثبت إنك تعرف الكورة؟'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('الدخول كضيف'), findsOneWidget);
    expect(find.textContaining('إنشاء حساب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign in renders loading then a safe error', (tester) async {
    _setSize(tester, const Size(844, 390));
    final completer = Completer<AuthUser>();
    final repository = _FakeAuthRepository(signInCompleter: completer);
    final router = await _pumpAuth(tester, repository);
    addTearDown(router.dispose);

    await _enterSignIn(tester);
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.completeError(Exception('RAW_SUPABASE_FAILURE'));
    await tester.pumpAndSettle();
    expect(
      find.text('تعذر إكمال العملية. راجع البيانات وحاول مرة أخرى.'),
      findsOneWidget,
    );
    expect(find.textContaining('RAW_SUPABASE_FAILURE'), findsNothing);
    expect(repository.signInCalls, 1);
  });

  testWidgets('successful sign in navigates to Home', (tester) async {
    _setSize(tester, const Size(844, 390));
    final repository = _FakeAuthRepository(
      signInResult: const AuthUser(
        id: 'signed-in',
        username: 'لاعب',
        isGuest: false,
      ),
    );
    final router = await _pumpAuth(tester, repository);
    addTearDown(router.dispose);

    await _enterSignIn(tester);
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(repository.signInCalls, 1);
  });

  testWidgets('create account validates real fields and toggles password', (
    tester,
  ) async {
    _setSize(tester, const Size(844, 390));
    final repository = _FakeAuthRepository(
      signUpResult: const AuthUser(
        id: 'new-player',
        username: 'سلمان',
        isGuest: false,
      ),
    );
    final router = await _pumpAuth(
      tester,
      repository,
      mode: AuthMode.createAccount,
    );
    addTearDown(router.dispose);

    expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.tap(find.byKey(const ValueKey('auth-primary-action')));
    await tester.pump();
    expect(find.text('اكتب اسمًا من 3 أحرف على الأقل'), findsOneWidget);
    expect(find.text('أدخل بريدًا إلكترونيًا صحيحًا'), findsOneWidget);
    expect(find.text('استخدم 8 أحرف على الأقل'), findsOneWidget);
    expect(repository.signUpCalls, 0);

    await tester.enterText(find.byType(TextFormField).at(0), 'سلمان');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'salman@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password11');
    final passwordEditor = find.descendant(
      of: find.byType(TextFormField).at(2),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(passwordEditor).obscureText, isTrue);
    await tester.tap(find.byTooltip('إظهار كلمة المرور'));
    await tester.pump();
    expect(tester.widget<EditableText>(passwordEditor).obscureText, isFalse);
    await tester.tap(find.byKey(const ValueKey('auth-primary-action')));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(repository.signUpCalls, 1);
  });

  testWidgets('Android shows usable Google and never advertises Apple', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repository = _FakeAuthRepository(
      socialResult: const SocialSignInAuthenticated(
        AuthUser(id: 'google-player', username: 'لاعب', isGuest: false),
      ),
    );
    final router = await _pumpAuth(tester, repository, config: _googleConfig);
    addTearDown(router.dispose);

    expect(find.byKey(const ValueKey('auth-google-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-apple-action')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('auth-google-action')));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(repository.socialCalls, 1);
  });

  testWidgets('Google is absent only when configuration is unavailable', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repository = _FakeAuthRepository();
    final router = await _pumpAuth(tester, repository);
    addTearDown(router.dispose);

    expect(_testConfig.googleAuthAvailable, isFalse);
    expect(find.byKey(const ValueKey('auth-google-action')), findsNothing);
  });

  testWidgets('Google configuration failure stays visible and is localized', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repository = _FakeAuthRepository(
      socialError: const SocialSignInException(
        SocialSignInFailureCode.configuration,
      ),
    );
    final router = await _pumpAuth(tester, repository, config: _googleConfig);
    addTearDown(router.dispose);

    await tester.tap(find.byKey(const ValueKey('auth-google-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-google-action')), findsOneWidget);
    expect(find.text('إعداد تسجيل الدخول بقوقل يحتاج مراجعة.'), findsOneWidget);
  });

  testWidgets('guest action is visually separate and navigates once', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repository = _FakeAuthRepository();
    final router = await _pumpAuth(tester, repository);
    addTearDown(router.dispose);

    await tester.tap(find.byKey(const ValueKey('auth-guest-action')));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(repository.guestCalls, 1);
  });

  for (final size in const [
    Size(360, 800),
    Size(390, 844),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ]) {
    for (final scale in const [1.0, 1.2, 1.3]) {
      for (final mode in AuthMode.values) {
        for (final keyboardInset in const [0.0, 300.0]) {
          testWidgets(
            '${mode.name} fits $size at scale $scale inset $keyboardInset',
            (tester) async {
              _setSize(tester, size);
              final repository = _FakeAuthRepository();
              final router = await _pumpAuth(
                tester,
                repository,
                mode: mode,
                config: _googleConfig,
                textScale: scale,
                keyboardInset: keyboardInset,
              );
              addTearDown(router.dispose);

              expect(
                find.byKey(const ValueKey('auth-google-action')),
                findsOneWidget,
              );
              final action = find.byKey(const ValueKey('auth-primary-action'));
              await tester.ensureVisible(action);
              await tester.pump();
              expect(action, findsOneWidget);
              expect(
                tester.getBottomRight(action).dy,
                lessThanOrEqualTo(size.height),
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}

Future<GoRouter> _pumpAuth(
  WidgetTester tester,
  _FakeAuthRepository repository, {
  AuthMode mode = AuthMode.signIn,
  AppConfig config = _testConfig,
  double textScale = 1,
  double keyboardInset = 0,
}) async {
  final router = GoRouter(
    initialLocation: '/auth',
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, _) => AuthScreen(initialMode: mode),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appServicesProvider.overrideWithValue(_testServices),
        appPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => const AppPreferences(reducedMotion: true),
        ),
        appContentProvider.overrideWithBuild(
          (ref, notifier) async => AppContentBundle.defaults,
        ),
        authRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _enterSignIn(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).at(0),
    'player@example.com',
  );
  await tester.enterText(find.byType(TextFormField).at(1), 'password11');
}

void _setSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.signInCompleter,
    this.signInResult,
    this.signUpResult,
    this.socialResult,
    this.socialError,
  });

  final Completer<AuthUser>? signInCompleter;
  final AuthUser? signInResult;
  final AuthUser? signUpResult;
  final SocialSignInResult? socialResult;
  final Object? socialError;
  int signInCalls = 0;
  int signUpCalls = 0;
  int socialCalls = 0;
  int guestCalls = 0;

  @override
  Future<AuthUser?> restore() async => null;

  @override
  Future<AuthUser> continueAsGuest() async {
    guestCalls += 1;
    return const AuthUser(id: 'guest', username: 'ضيف', isGuest: true);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    if (signInCompleter != null) return signInCompleter!.future;
    return signInResult!;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    signUpCalls += 1;
    return signUpResult!;
  }

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) async {
    socialCalls += 1;
    if (socialError != null) throw socialError!;
    return socialResult!;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
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

const _googleConfig = AppConfig(
  environment: AppEnvironment.production,
  supabaseUrl: 'https://example.supabase.co',
  supabaseKey: 'public-anon-key',
  firebaseEnabled: true,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
  googleAuthEnabled: true,
);

const _testServices = AppServices(
  analytics: NoopAnalyticsService(),
  crashReporter: NoopCrashReporter(),
  notifications: NoopNotificationService(),
  ads: NoopAdsService(),
  purchases: NoopPurchaseService(),
  errors: NoopAppErrorReporter(),
);
