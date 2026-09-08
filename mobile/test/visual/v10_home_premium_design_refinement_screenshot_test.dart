import 'dart:io';
import 'dart:ui' as ui;

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/content/domain/app_content.dart';
import 'package:ahdash_11/features/content/presentation/app_content_controller.dart';
import 'package:ahdash_11/features/home/presentation/home_screen.dart';
import 'package:ahdash_11/features/party/presentation/party_catalog_provider.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_setup_screens.dart';
import 'package:ahdash_11/features/premium/presentation/premium_controller.dart';
import 'package:ahdash_11/features/premium/presentation/premium_screen.dart';
import 'package:ahdash_11/features/premium/presentation/premium_visuals.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:ahdash_11/shared/presentation/utility_v9.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/phase6_fixture.dart';

const _boundaryKey = ValueKey('home-premium-review-boundary');
const _reviewConfig = AppConfig(
  environment: AppEnvironment.development,
  supabaseUrl: '',
  supabaseKey: '',
  firebaseEnabled: false,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
);

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

  final premiumStates = <String, Widget>{
    'premium_monthly_selected_390x844': _premiumSurface(
      const PremiumView(
        plans: phase6Plans,
        available: true,
        selected: PremiumPlanPeriod.monthly,
      ),
    ),
    'premium_annual_selected_390x844': _premiumSurface(
      const PremiumView(
        plans: phase6Plans,
        available: true,
        selected: PremiumPlanPeriod.yearly,
      ),
    ),
    'premium_packages_loading_390x844': const AhdashUtilityScaffold(
      title: 'أحدعش Premium',
      child: PremiumLoadingView(),
    ),
    'premium_packages_unavailable_390x844': _premiumSurface(
      const PremiumView(available: true),
    ),
    'premium_active_subscriber_390x844': _premiumSurface(
      PremiumView(
        plans: phase6Plans,
        available: true,
        status: PremiumStatus(
          state: PremiumAccessState.active,
          managementUrl: Uri.https('example.test', '/manage'),
        ),
      ),
      manage: true,
    ),
    'premium_purchase_loading_390x844': _premiumSurface(
      const PremiumView(
        plans: phase6Plans,
        available: true,
        operation: PremiumOperation.buying,
      ),
    ),
  };

  for (final entry in premiumStates.entries) {
    testWidgets('capture ${entry.key}', (tester) async {
      await _pumpSurface(tester, entry.value, const Size(390, 844));
      expect(tester.takeException(), isNull);
      await _capture(tester, entry.key);
    });
  }

  testWidgets('premium states preserve store truth and active behavior', (
    tester,
  ) async {
    PremiumPlanPeriod? selected;
    await _pumpSurface(
      tester,
      AhdashUtilityScaffold(
        title: 'أحدعش Premium',
        child: PremiumContentView(
          value: const PremiumView(plans: phase6Plans, available: true),
          onSelect: (value) => selected = value,
          onPurchase: _falseResult,
          onRestore: _falseResult,
        ),
      ),
      const Size(390, 844),
    );
    expect(find.text(phase6Plans.first.price), findsOneWidget);
    expect(find.text(phase6Plans.last.price), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('premium-plan-yearly')));
    expect(selected, PremiumPlanPeriod.yearly);

    await _pumpSurface(
      tester,
      _premiumSurface(
        const PremiumView(
          plans: phase6Plans,
          available: true,
          status: PremiumStatus(state: PremiumAccessState.active),
        ),
      ),
      const Size(390, 844),
    );
    expect(find.byKey(const ValueKey('premium-active-subscriber')), findsOne);
    expect(find.byKey(const ValueKey('premium-subscribe')), findsNothing);

    await _pumpSurface(
      tester,
      _premiumSurface(const PremiumView(available: true)),
      const Size(390, 844),
    );
    expect(
      find.byKey(const ValueKey('premium-packages-unavailable')),
      findsOne,
    );
    expect(find.text(phase6Plans.first.price), findsNothing);
    expect(find.text(phase6Plans.last.price), findsNothing);
  });

  testWidgets('capture premium category lock and contextual gate', (
    tester,
  ) async {
    final router = await _pumpPartyCategories(tester, premium: false);
    addTearDown(router.dispose);
    expect(find.text('أساطير الكرة'), findsOneWidget);
    expect(find.byType(PremiumCategoryBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'premium_category_locked_390x844');

    await tester.tap(find.text('أساطير الكرة'));
    await tester.pumpAndSettle();
    expect(find.text('هذه الفئة ضمن Premium'), findsOneWidget);
    expect(find.byKey(const ValueKey('premium-gate-open')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'premium_category_gate_390x844');
  });

  testWidgets('capture premium category unlocked', (tester) async {
    final router = await _pumpPartyCategories(tester, premium: true);
    addTearDown(router.dispose);
    expect(find.text('أساطير الكرة'), findsOneWidget);
    expect(find.byType(PremiumCategoryBadge), findsNothing);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'premium_category_unlocked_390x844');
  });

  testWidgets('capture Home motion and Premium discovery states', (
    tester,
  ) async {
    final router = await _pumpHome(tester, reducedMotion: false);
    addTearDown(router.dispose);
    await tester.pump(const Duration(milliseconds: 380));
    expect(find.byKey(const ValueKey('home-party-hero')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('ahdash-football-artwork-motion')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, 'home_motion_keyframe_390x844');

    await tester.pumpAndSettle();
    final discovery = find.byKey(const ValueKey('home-premium-discovery'));
    await Scrollable.ensureVisible(
      tester.element(discovery),
      alignment: 0.32,
      duration: Duration.zero,
    );
    await tester.pump();
    await _capture(tester, 'home_premium_discovery_390x844');
  });

  testWidgets('reduced motion renders the Home artwork statically', (
    tester,
  ) async {
    final router = await _pumpHome(tester, reducedMotion: true);
    addTearDown(router.dispose);
    expect(
      find.byKey(const ValueKey('ahdash-football-artwork-motion')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('ahdash-football-artwork')), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Widget _premiumSurface(PremiumView value, {bool manage = false}) =>
    AhdashUtilityScaffold(
      title: 'أحدعش Premium',
      child: PremiumContentView(
        value: value,
        onSelect: (_) {},
        onPurchase: _falseResult,
        onRestore: _falseResult,
        onManage: manage ? () {} : null,
      ),
    );

Future<bool> _falseResult() async => false;

Future<void> _pumpSurface(WidgetTester tester, Widget child, Size size) async {
  _setViewport(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: _reviewBuilder,
      home: Directionality(textDirection: TextDirection.rtl, child: child),
    ),
  );
  // A fixed final frame keeps intentionally spinning store/checkout loaders
  // deterministic without waiting for them to settle forever.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
}

Future<GoRouter> _pumpPartyCategories(
  WidgetTester tester, {
  required bool premium,
}) async {
  _setViewport(tester, const Size(390, 844));
  final router = GoRouter(
    initialLocation: '/party/categories',
    routes: [
      GoRoute(
        path: '/party/categories',
        builder: (_, _) => const PartyCategorySelectionScreen(),
      ),
      for (final path in ['/home', '/premium'])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text(path)),
        ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        partyCatalogProvider.overrideWith((_) async => _premiumCatalog),
        partyEntitlementProvider.overrideWith((_) async => premium),
        partyGameControllerProvider.overrideWithBuild(
          (_, _) => const PartyGameState(restored: true),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
        builder: _reviewBuilder,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _precacheImages(tester);
  await tester.pump();
  return router;
}

Future<GoRouter> _pumpHome(
  WidgetTester tester, {
  required bool reducedMotion,
}) async {
  _setViewport(tester, const Size(390, 844));
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
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
        '/premium',
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
        appConfigProvider.overrideWithValue(_reviewConfig),
        appServicesProvider.overrideWithValue(AppServices.noop()),
        appPreferencesProvider.overrideWithBuild(
          (_, _) async => AppPreferences(reducedMotion: reducedMotion),
        ),
        appContentProvider.overrideWithBuild(
          (_, _) async => AppContentBundle.defaults,
        ),
        authControllerProvider.overrideWithBuild(
          (_, _) async => const AuthUser(
            id: 'review-account',
            username: 'محمد',
            isGuest: false,
          ),
        ),
        partyGameControllerProvider.overrideWithBuild(
          (_, _) => const PartyGameState(restored: true),
        ),
        tournamentControllerProvider.overrideWithBuild(
          (_, _) => const TournamentState(restored: true),
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
          key: _boundaryKey,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
              disableAnimations: reducedMotion,
            ),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await _precacheImages(tester);
  await tester.pump();
  return router;
}

Widget _reviewBuilder(BuildContext context, Widget? child) => RepaintBoundary(
  key: _boundaryKey,
  child: MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
    ),
    child: child!,
  ),
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(
    () => tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio(),
  );
}

Future<void> _precacheImages(WidgetTester tester) async {
  final imageContext = tester.element(find.byKey(_boundaryKey));
  final providers = tester
      .widgetList<Image>(find.byType(Image))
      .map((widget) => widget.image)
      .toList(growable: false);
  await tester.runAsync(
    () async => Future.wait(
      providers.map((provider) => precacheImage(provider, imageContext)),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  const output = String.fromEnvironment('HOME_PREMIUM_REVIEW_DIR');
  if (output.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$output/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

const _categoryNames = [
  'كأس العالم',
  'الدوري السعودي',
  'أساطير الكرة',
  'سوق الانتقالات',
  'خطط وتكتيك',
  'دوري أبطال أوروبا',
];

final _premiumCategories = List.generate(
  _categoryNames.length,
  (index) => QuizCategory(
    id: 'review-category-$index',
    name: _categoryNames[index],
    description: 'فئة كروية بأسئلة متنوعة من المحتوى المنشور.',
    iconName: 'sports_soccer',
    imageUrl:
        'assets/images/v10_h3_visual_fixtures/${['world_cup', 'saudi_league', 'legends', 'transfer_market', 'tactics', 'champions_league'][index]}.png',
    accentColor: const Color(0xFF1E874B),
    accessTier: index == 2 ? 'premium' : 'free',
  ),
);

final _premiumCatalog = PartyCatalog(
  categories: _premiumCategories,
  questions: const [],
  healthByCategoryId: {
    for (final category in _premiumCategories)
      category.id: const PartyCategoryHealth(easy: 2, medium: 2, hard: 2),
  },
);
