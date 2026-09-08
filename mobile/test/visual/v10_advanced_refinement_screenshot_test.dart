import 'dart:io';
import 'dart:ui' as ui;

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/services/purchase_service.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_colors.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/premium/presentation/premium_controller.dart';
import 'package:ahdash_11/features/premium/presentation/premium_visuals.dart';
import 'package:ahdash_11/features/settings/presentation/settings_screen.dart';
import 'package:ahdash_11/shared/presentation/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/phase6_fixture.dart';
import '../helpers/test_app.dart';

const _boundary = ValueKey('test-app-boundary');

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
  });

  final settingsStates =
      <({String name, Size size, AuthUser user, bool active})>[
        (
          name: 'settings/settings_signed_in_390x844.png',
          size: const Size(390, 844),
          user: phase6User,
          active: false,
        ),
        (
          name: 'settings/settings_guest_390x844.png',
          size: const Size(390, 844),
          user: const AuthUser(id: 'guest', username: 'ضيف', isGuest: true),
          active: false,
        ),
        (
          name: 'settings/settings_subscriber_390x844.png',
          size: const Size(390, 844),
          user: phase6User,
          active: true,
        ),
        (
          name: 'settings/settings_compact_360x800.png',
          size: const Size(360, 800),
          user: phase6User,
          active: false,
        ),
      ];

  for (final state in settingsStates) {
    testWidgets('capture ${state.name}', (tester) async {
      await _pumpSettings(
        tester,
        size: state.size,
        user: state.user,
        active: state.active,
      );
      expect(tester.takeException(), isNull);
      await _capture(tester, state.name);
    });
  }

  testWidgets('capture settings support and session area', (tester) async {
    await _pumpSettings(
      tester,
      size: const Size(390, 844),
      user: phase6User,
      active: false,
    );
    final signOut = find.byKey(const ValueKey('settings-sign-out'));
    await tester.scrollUntilVisible(
      signOut,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(signOut, findsOneWidget);
    await _capture(tester, 'settings/settings_signed_in_bottom_390x844.png');
  });

  for (final entry in const {
    'artwork/home_hero_exploration_a_gathering.png':
        PremiumArtworkScene.homeGathering,
    'artwork/home_hero_exploration_b_tactics.png':
        PremiumArtworkScene.homeTactics,
    'artwork/home_hero_exploration_c_floodlights.png':
        PremiumArtworkScene.homeFloodlights,
    'artwork/premium_locked_categories.png': PremiumArtworkScene.categories,
    'artwork/premium_unlocked_categories.png':
        PremiumArtworkScene.unlockedCategories,
    'artwork/premium_ads_free_flow.png': PremiumArtworkScene.noAds,
  }.entries) {
    testWidgets('capture ${entry.key}', (tester) async {
      await _pumpArtwork(tester, entry.value);
      expect(tester.takeException(), isNull);
      await _capture(tester, entry.key);
    });
  }

  for (final frame in const [
    (name: 'motion_keyframes/home_hero_00.png', progress: 0.0),
    (name: 'motion_keyframes/home_hero_50.png', progress: .5),
    (name: 'motion_keyframes/home_hero_100.png', progress: 1.0),
  ]) {
    testWidgets('capture ${frame.name}', (tester) async {
      await _pumpArtwork(
        tester,
        PremiumArtworkScene.homeGathering,
        progress: frame.progress,
      );
      await _capture(tester, frame.name);
    });
  }

  testWidgets('capture representative state treatments', (tester) async {
    await _pumpSurface(
      tester,
      const AppMessageState(
        icon: Icons.sports_soccer_rounded,
        title: 'ما عندك ألعاب محفوظة',
        message: 'ابدأ لعبة جماعية، ونحفظ تقدمها على هذا الجهاز.',
        actionLabel: 'ابدأ لعبة',
        onAction: _noop,
      ),
    );
    await _capture(tester, 'empty_states/editorial_empty_state.png');

    await _pumpSurface(
      tester,
      const Padding(
        padding: EdgeInsets.all(24),
        child: LoadingSkeleton(lines: 5),
      ),
    );
    await _capture(tester, 'loading_states/contextual_loading.png');

    await _pumpSurface(
      tester,
      const AppMessageState(
        icon: Icons.sync_problem_rounded,
        title: 'تعذر تحميل المحتوى',
        message: 'تحقق من الاتصال وأعد المحاولة.',
        actionLabel: 'أعد المحاولة',
        onAction: _noop,
      ),
    );
    await _capture(tester, 'error_states/editorial_error_state.png');
  });
}

void _noop() {}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required Size size,
  required AuthUser user,
  required bool active,
}) async {
  _setViewport(tester, size);
  final premium = PremiumView(
    plans: phase6Plans,
    available: true,
    status: PremiumStatus(
      state: active ? PremiumAccessState.active : PremiumAccessState.inactive,
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(phase6Config),
        appServicesProvider.overrideWithValue(const AppServices.noop()),
        authControllerProvider.overrideWithBuild((_, _) async => user),
        appPreferencesProvider.overrideWithBuild(
          (_, _) async => const AppPreferences(),
        ),
        premiumControllerProvider.overrideWithBuild((_, _) async => premium),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => RepaintBoundary(
          key: _boundary,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 47, bottom: 34),
              viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpArtwork(
  WidgetTester tester,
  PremiumArtworkScene scene, {
  double progress = 1,
}) async {
  const size = Size(390, 300);
  _setViewport(tester, size);
  await tester.pumpWidget(
    testApp(
      Scaffold(
        backgroundColor: AppColors.paper0,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  scene == PremiumArtworkScene.homeGathering ||
                      scene == PremiumArtworkScene.premium
                  ? const Color(0xFF173F34)
                  : AppColors.paper1,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SizedBox.expand(
                child: AhdashFootballArtwork(scene: scene, progress: progress),
              ),
            ),
          ),
        ),
      ),
      theme: AppTheme.light,
    ),
  );
  await tester.pump();
}

Future<void> _pumpSurface(WidgetTester tester, Widget child) async {
  const size = Size(390, 460);
  _setViewport(tester, size);
  await tester.pumpWidget(
    testApp(
      Scaffold(backgroundColor: AppColors.paper0, body: child),
      theme: AppTheme.light,
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

Future<void> _capture(WidgetTester tester, String relativePath) async {
  const output = String.fromEnvironment('ADVANCED_VISUAL_DIR');
  if (output.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundary),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$output/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
