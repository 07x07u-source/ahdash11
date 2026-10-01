import 'package:ahdash_11/features/home/presentation/streak_milestone_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the earned days and continues into the game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var continued = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StreakMilestoneCelebration(
            days: 10,
            emoji: '🔥',
            onContinue: () => continued = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('streak-milestone-days')), findsOneWidget);
    expect(find.text('يوم بدون انقطاع!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('streak-milestone-continue')));
    expect(continued, isTrue);
  });
}
