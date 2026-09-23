import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/presentation/team_challenge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fake_social_repository.dart';
import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('ThmanyahSans')
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Regular.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Medium.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Bold.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Black.otf'),
          ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final size in const [Size(390, 844), Size(360, 800)]) {
    final dimensions = '${size.width.round()}x${size.height.round()}';

    testWidgets('team challenge result $dimensions', (tester) async {
      _setViewport(tester, size);
      await tester.pumpWidget(_scope(size, available: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ريال مدريد'));
      await tester.pumpAndSettle();
      final artwork = tester.widget<Image>(find.byType(Image));
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() => precacheImage(artwork.image, context));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/v10_phase_d/teamChallengeResult_$dimensions.png',
        ),
      );
    });

    testWidgets('team challenge unavailable $dimensions', (tester) async {
      _setViewport(tester, size);
      await tester.pumpWidget(_scope(size, available: false));
      await tester.pumpAndSettle();
      final artwork = tester.widget<Image>(find.byType(Image));
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() => precacheImage(artwork.image, context));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/v10_phase_d/teamChallengeUnavailable_$dimensions.png',
        ),
      );
    });
  }
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

Widget _scope(Size size, {required bool available}) => ProviderScope(
  overrides: [
    socialRepositoryProvider.overrideWithValue(
      FakeSocialRepository(
        challengeQuestion: available ? teamChallengeQuestionFixture : null,
        challengeResult: available ? teamChallengeResultFixture : null,
      ),
    ),
  ],
  child: testApp(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: const EdgeInsets.only(top: 47, bottom: 34),
        viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
        disableAnimations: true,
      ),
      child: const TeamChallengeScreen(
        challengeId: 'challenge-fixture',
        enableCountdown: false,
      ),
    ),
    theme: AppTheme.light,
  ),
);
