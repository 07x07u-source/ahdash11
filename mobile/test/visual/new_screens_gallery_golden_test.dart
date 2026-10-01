import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/categories/presentation/categories_controller.dart';
import 'package:ahdash_11/features/match/presentation/solo_home_screen.dart';
import 'package:ahdash_11/features/tournament/data/tournament_registration_repository.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      final loader = FontLoader('ThmanyahSans')
        ..addFont(
          rootBundle.load('assets/fonts/thmanyah/thmanyahsans-$weight.otf'),
        );
      await loader.load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final size in const [Size(360, 800), Size(390, 844)]) {
    final dimensions = '${size.width.round()}x${size.height.round()}';

    testWidgets('new tournament dashboard gallery $dimensions', (tester) async {
      await _pump(
        tester,
        size,
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(_config),
            tournamentControllerProvider.overrideWith(
              _IdleTournamentController.new,
            ),
            availableTournamentsProvider.overrideWith((ref) async => const []),
            myTournamentEntriesProvider.overrideWith((ref) async => const []),
          ],
          child: const TournamentDashboardScreen(),
        ),
      );
      await expectLater(
        find.byKey(const ValueKey('new-screens-boundary')),
        matchesGoldenFile(
          'goldens/v10_phase_f/tournament_dashboard_$dimensions.png',
        ),
      );
    });

    testWidgets('new solo home gallery $dimensions', (tester) async {
      await _pump(
        tester,
        size,
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(_config),
            categoriesProvider.overrideWithBuild(
              (ref, notifier) async => const [],
            ),
          ],
          child: const SoloHomeScreen(),
        ),
      );
      await expectLater(
        find.byKey(const ValueKey('new-screens-boundary')),
        matchesGoldenFile('goldens/v10_phase_f/solo_home_$dimensions.png'),
      );
    });
  }
}

Future<void> _pump(WidgetTester tester, Size size, Widget screen) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    testApp(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: RepaintBoundary(
          key: const ValueKey('new-screens-boundary'),
          child: screen,
        ),
      ),
      theme: AppTheme.light,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
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

final class _IdleTournamentController extends TournamentController {
  @override
  TournamentState build() => const TournamentState(restored: true);

  @override
  Future<void> restore() async {}
}
