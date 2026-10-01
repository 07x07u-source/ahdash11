import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_support_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('طريقة اللعب تعرض ست شاشات مستقلة', (tester) async {
    const size = Size(390, 844);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1
      ..viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio()
        ..resetViewPadding();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partyGameControllerProvider.overrideWithBuild(
            (ref, notifier) => const PartyGameState(restored: true),
          ),
        ],
        child: testApp(const HowToPlayScreen(), theme: AppTheme.light),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MaterialApp));
    const assets = [
      'assets/images/onboarding/onboarding_categories_ahdash.png',
      'assets/images/onboarding/onboarding_teams_ahdash.png',
      'assets/images/onboarding/onboarding_helpers_ahdash.png',
      'assets/images/onboarding/onboarding_timer_ahdash.png',
      'assets/images/onboarding/onboarding_answer_ahdash.png',
      'assets/images/onboarding/onboarding_victory_ahdash.png',
    ];
    await tester.runAsync(
      () => Future.wait(
        assets.map((asset) => precacheImage(AssetImage(asset), context)),
      ),
    );
    await tester.pump();

    for (var index = 0; index < assets.length; index++) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/how_to_play_six/how_to_play_${index + 1}_390x844.png',
        ),
      );
      if (index != assets.length - 1) {
        await tester.tap(find.text('التالي'));
        await tester.pumpAndSettle();
      }
    }
  });
}
