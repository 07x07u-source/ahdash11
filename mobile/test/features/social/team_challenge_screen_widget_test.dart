import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/presentation/team_challenge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fake_social_repository.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('team challenge moves from question to verified result', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
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
            FakeSocialRepository(
              challengeQuestion: teamChallengeQuestionFixture,
              challengeResult: teamChallengeResultFixture,
            ),
          ),
        ],
        child: testApp(
          const MediaQuery(
            data: MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: 47, bottom: 34),
              viewPadding: EdgeInsets.only(top: 47, bottom: 34),
              disableAnimations: true,
            ),
            child: TeamChallengeScreen(
              challengeId: 'challenge-fixture',
              enableCountdown: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تحدي ليلة الكورة'), findsOneWidget);
    expect(find.text('ريال مدريد'), findsOneWidget);
    expect(find.text('320'), findsOneWidget);

    await tester.tap(find.text('ريال مدريد'));
    await tester.pumpAndSettle();

    expect(find.text('نتيجة ترفع الرأس'), findsOneWidget);
    expect(find.text('658'), findsWidgets);
    expect(find.text('سلمان الحربي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable challenge explains that no attempt was recorded', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(FakeSocialRepository()),
        ],
        child: testApp(
          const TeamChallengeScreen(
            challengeId: 'unavailable',
            enableCountdown: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('التحدي غير متاح الآن'), findsOneWidget);
    expect(find.text('لن تُسجّل عليك أي محاولة'), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-error-back')), findsOneWidget);
  });

  testWidgets('team challenge fits compact accessibility viewport', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 800)
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
            FakeSocialRepository(
              challengeQuestion: teamChallengeQuestionFixture,
              challengeResult: teamChallengeResultFixture,
            ),
          ),
        ],
        child: testApp(
          const MediaQuery(
            data: MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.3),
              disableAnimations: true,
            ),
            child: TeamChallengeScreen(
              challengeId: 'challenge-fixture',
              enableCountdown: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ريال مدريد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
