import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_support_screens.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_controller.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_screen.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/presentation/team_challenge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fake_social_repository.dart';
import '../helpers/test_app.dart';
import '../helpers/visual_test_variant.dart';

enum _EmptySurface { savedGamesEmpty, challengeUnavailable, rankingEmpty }

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
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final surface in _EmptySurface.values) {
        final variant = VisualTestVariant(size, scale);
        testWidgets('${surface.name} ${variant.label}', (tester) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(() {
            tester.view
              ..resetPhysicalSize()
              ..resetDevicePixelRatio();
          });
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                socialRepositoryProvider.overrideWithValue(
                  FakeSocialRepository(),
                ),
                leaderboardProvider.overrideWith((ref) async => const []),
                authControllerProvider.overrideWithBuild(
                  (ref, notifier) async => null,
                ),
              ],
              child: testApp(
                MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(top: 47, bottom: 34),
                    viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                    disableAnimations: true,
                  ),
                  child: switch (surface) {
                    _EmptySurface.savedGamesEmpty => SavedGamesPortraitPage(
                      restored: true,
                      sessions: const [],
                      onOpen: (_) {},
                      onStart: () {},
                      onHome: () {},
                    ),
                    _EmptySurface.challengeUnavailable =>
                      const TeamChallengeScreen(
                        challengeId: 'unavailable',
                        enableCountdown: false,
                      ),
                    _EmptySurface.rankingEmpty => const RankingScreen(),
                  },
                ),
                theme: AppTheme.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          expect(images, hasLength(1));
          expect(images.single.excludeFromSemantics, isTrue);
          final context = tester.element(find.byType(MaterialApp));
          await tester.runAsync(
            () => precacheImage(images.single.image, context),
          );
          await tester.pump();
          await verifyVisual(
            tester,
            find.byType(MaterialApp),
            'goldens/state_refinement/${surface.name}_${size.width.round()}x${size.height.round()}.png',
            variant,
          );
          if (surface == _EmptySurface.savedGamesEmpty) {
            await tester.ensureVisible(find.text('ابدأ لعبة'));
          } else if (surface == _EmptySurface.challengeUnavailable) {
            final back = find.byKey(const ValueKey('challenge-error-back'));
            expect(
              tester.getBottomRight(back).dy,
              lessThanOrEqualTo(size.height - 34),
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
