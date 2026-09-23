import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding teaches the four truthful Party concepts', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 720));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: Locale('ar'),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: OnboardingScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اختار الفئات'), findsOneWidget);
    expect(find.text('كوّن الفرق'), findsOneWidget);
    expect(find.text('جاوب'), findsOneWidget);
    expect(find.text('احسم الفوز'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
    expect(find.textContaining('Player11'), findsNothing);
    expect(find.textContaining('36 سؤال'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact onboarding supports next, back and persisted skip', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    SharedPreferences.setMockInitialValues({});
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (_, _) => const Scaffold(body: Text('AUTH')),
        ),
        GoRoute(
          path: '/how-to-play',
          builder: (_, _) => const Scaffold(body: Text('HOW_TO')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('ar'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('خطوة 1 من 4'), findsOneWidget);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('خطوة 2 من 4'), findsOneWidget);
    await tester.tap(find.text('السابق'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('خطوة 1 من 4'), findsOneWidget);

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    expect(find.text('AUTH'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('onboarding_complete'), isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [
    Size(360, 800),
    Size(390, 844),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ]) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('all onboarding steps stay aligned at $size scale $scale', (
        tester,
      ) async {
        _setSize(tester, size);
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light,
              locale: const Locale('ar'),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: const Directionality(
                  textDirection: TextDirection.rtl,
                  child: OnboardingScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleTops = <double>[];
        for (final title in [
          'اختار الفئات',
          'كوّن الفرق',
          'جاوب',
          'احسم الفوز',
        ]) {
          final titleFinder = find.text(title);
          expect(titleFinder, findsOneWidget);
          titleTops.add(tester.getTopLeft(titleFinder).dy);
          final action = find.byKey(
            const ValueKey('onboarding-primary-action'),
          );
          expect(
            tester.getBottomRight(action).dy,
            lessThanOrEqualTo(size.height),
          );
          if (title != 'احسم الفوز') {
            await tester.tap(find.text('التالي'));
            await tester.pumpAndSettle();
          }
        }
        expect(
          titleTops.reduce((a, b) => a > b ? a : b) -
              titleTops.reduce((a, b) => a < b ? a : b),
          lessThan(32),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
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
