import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_game_controller.dart';
import 'package:ahdash_11/features/party/presentation/party_game_screens.dart';
import 'package:ahdash_11/features/profile/presentation/profile_controller.dart';
import 'package:ahdash_11/features/profile/presentation/profile_screen.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_controller.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_screen.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/presentation/team_challenge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fake_social_repository.dart';
import '../fixtures/v10_feature_fixtures.dart';
import '../helpers/test_app.dart';
import '../helpers/visual_test_variant.dart';

enum _Surface { partyChampion, playerIdentity, challengeResult, rankingPodium }

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
      for (final surface in _Surface.values) {
        final variant = VisualTestVariant(size, scale);
        testWidgets('${surface.name} ${variant.label}', (tester) async {
          final textScale = ValueNotifier(
            surface == _Surface.challengeResult ? 1.0 : scale,
          );
          addTearDown(textScale.dispose);
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
                appConfigProvider.overrideWithValue(phase6Config),
                appServicesProvider.overrideWithValue(const AppServices.noop()),
                authControllerProvider.overrideWithBuild(
                  (ref, notifier) async => phase6User,
                ),
                appPreferencesProvider.overrideWithBuild(
                  (ref, notifier) async => const AppPreferences(
                    reducedMotion: true,
                    soundEffects: false,
                    haptics: false,
                  ),
                ),
                playerProfileProvider.overrideWith(
                  (ref) async => phase6Profile,
                ),
                leaderboardProvider.overrideWith(
                  (ref) async => V10FeatureFixtures.ranking,
                ),
                partyGameControllerProvider.overrideWithBuild(
                  (ref, notifier) => PartyGameState(
                    session: phase4CompletedSession(),
                    restored: true,
                  ),
                ),
                socialRepositoryProvider.overrideWithValue(
                  FakeSocialRepository(
                    challengeQuestion: teamChallengeQuestionFixture,
                    challengeResult: teamChallengeResultFixture,
                  ),
                ),
              ],
              child: testApp(
                ValueListenableBuilder<double>(
                  valueListenable: textScale,
                  builder: (context, currentScale, child) => MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      textScaler: TextScaler.linear(currentScale),
                      padding: const EdgeInsets.only(top: 47, bottom: 34),
                      viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                  child: switch (surface) {
                    _Surface.partyChampion => const PartyResultScreen(),
                    _Surface.playerIdentity => const ProfileScreen(),
                    _Surface.rankingPodium => const RankingScreen(),
                    _Surface.challengeResult => const TeamChallengeScreen(
                      challengeId: 'fixture',
                      enableCountdown: false,
                    ),
                  },
                ),
                theme: AppTheme.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (surface == _Surface.challengeResult) {
            await tester.ensureVisible(find.text('ريال مدريد'));
            await tester.tap(find.text('ريال مدريد'));
            await tester.pumpAndSettle();
            // Exercise the result at the target scale without changing the
            // unrelated question screen's layout under this visual fixture.
            textScale.value = scale;
            await tester.pumpAndSettle();
          }
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          final context = tester.element(find.byType(MaterialApp));
          await tester.runAsync(
            () => Future.wait(
              images.map((image) => precacheImage(image.image, context)),
            ),
          );
          await tester.pump();
          await verifyVisual(
            tester,
            find.byType(MaterialApp),
            'goldens/achievement_refinement/${surface.name}_${size.width.round()}x${size.height.round()}.png',
            variant,
          );
          if (surface == _Surface.challengeResult) {
            expect(find.text('658'), findsWidgets);
            expect(find.text('#2'), findsOneWidget);
          }
          if (surface == _Surface.playerIdentity) {
            expect(find.text('سلمان الحربي'), findsOneWidget);
            expect(find.text('Premium'), findsOneWidget);
          }
        });
      }
    }
  }
}
