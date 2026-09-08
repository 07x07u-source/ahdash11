import 'dart:io';
import 'dart:ui' as ui;
import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/auth/presentation/auth_gate.dart';
import 'package:ahdash_11/features/content/domain/app_content.dart';
import 'package:ahdash_11/features/content/presentation/app_content_controller.dart';
import 'package:ahdash_11/features/home/presentation/home_screen.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const reviewBoundary = ValueKey('ui-review-boundary');

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
  for (final size in const [
    Size(360, 800),
    Size(390, 844),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ]) {
    for (final scale in [1.0, 1.2, 1.3]) {
      for (final guest in [false, true]) {
        testWidgets(
          'review Home ${guest ? 'guest' : 'account'} ${size.width.toInt()} scale $scale',
          (tester) async {
            final router = await pumpReviewHome(
              tester,
              size: size,
              scale: scale,
              guest: guest,
            );
            addTearDown(router.dispose);
            expect(find.text('ابدأ لعبة'), findsOneWidget);
            expect(find.textContaining('Online'), findsNothing);
            expect(find.textContaining('قريبًا'), findsNothing);
            expect(tester.takeException(), isNull);
            await captureReview(
              tester,
              'home_${guest ? 'guest' : 'account'}_${size.width.toInt()}x${size.height.toInt()}_scale$scale',
            );
            for (final title in [
              'أنشئ بطولة',
              'العب لحالك',
              'تحدي فريق',
              'ألعاب محفوظة',
              'طريقة اللعب',
            ]) {
              await tester.ensureVisible(find.text(title));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  }
  for (final scale in [1.0, 1.3]) {
    testWidgets('review guest Auth Gate scale $scale', (tester) async {
      final router = await pumpReviewHome(
        tester,
        size: const Size(390, 844),
        scale: scale,
        guest: true,
        initialLocation: '/account-required?next=%2Ffriends',
      );
      addTearDown(router.dispose);
      expect(find.byKey(const ValueKey('gate-sign-in')), findsOneWidget);
      expect(find.byKey(const ValueKey('gate-create-account')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureReview(tester, 'guest_auth_gate_390x844_scale$scale');
    });
  }
}

Future<GoRouter> pumpReviewHome(
  WidgetTester tester, {
  required Size size,
  required double scale,
  required bool guest,
  String initialLocation = '/home',
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(
    () => tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio(),
  );
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/account-required',
        builder: (_, s) => AuthGateScreen(
          destination: s.uri.queryParameters['next'] ?? '/home',
        ),
      ),
      for (final path in [
        '/party/categories',
        '/tournaments/create',
        '/solo',
        '/teams',
        '/party/games',
        '/ranking',
        '/friends',
        '/how-to-play',
        '/profile',
        '/settings',
        '/notifications',
        '/auth',
      ])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text(path)),
        ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            environment: AppEnvironment.development,
            supabaseUrl: '',
            supabaseKey: '',
            firebaseEnabled: false,
            adMobEnabled: false,
            revenueCatAndroidKey: '',
            revenueCatIosKey: '',
          ),
        ),
        appServicesProvider.overrideWithValue(AppServices.noop()),
        appPreferencesProvider.overrideWithBuild(
          (ref, n) async => const AppPreferences(reducedMotion: true),
        ),
        appContentProvider.overrideWithBuild(
          (ref, n) async => AppContentBundle.defaults,
        ),
        authControllerProvider.overrideWithBuild(
          (ref, n) async => AuthUser(
            id: guest ? 'guest' : 'account',
            username: 'محمد',
            isGuest: guest,
          ),
        ),
        partyGameControllerProvider.overrideWithBuild(
          (ref, n) => const PartyGameState(restored: true),
        ),
        tournamentControllerProvider.overrideWithBuild(
          (ref, n) => const TournamentState(restored: true),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
        builder: (context, child) => RepaintBoundary(
          key: reviewBoundary,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              devicePixelRatio: 2,
              textScaler: TextScaler.linear(scale),
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
            ),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final imageContext = tester.element(find.byKey(reviewBoundary));
  final images = tester
      .widgetList<Image>(find.byType(Image))
      .map((i) => i.image)
      .toList();
  await tester.runAsync(() async {
    await Future.wait(images.map((i) => precacheImage(i, imageContext)));
  });
  await tester.pumpAndSettle();
  return router;
}

Future<void> captureReview(WidgetTester tester, String name) async {
  const output = String.fromEnvironment('UI_REVIEW_DIR');
  if (output.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(reviewBoundary),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$output/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
