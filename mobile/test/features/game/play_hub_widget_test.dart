import 'package:ahdash_11/features/play/presentation/play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('Play Hub exposes only local Party and solo play', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(child: testApp(const PlayScreen())));
    await tester.pumpAndSettle();

    expect(find.text('نوع المنافسة'), findsOneWidget);
    expect(find.text('تحدي الفرق'), findsOneWidget);
    expect(find.text('اللعب الفردي'), findsOneWidget);
    expect(find.text('ابدأ اللعب الآن'), findsOneWidget);
    expect(find.text('أونلاين (قريبًا)'), findsNothing);
    expect(find.textContaining('مباراة عشوائية'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Play Hub remains usable with large Arabic text', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: testApp(
          const MediaQuery(
            data: MediaQueryData(
              size: Size(1280, 720),
              textScaler: TextScaler.linear(1.6),
              disableAnimations: true,
            ),
            child: PlayScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('نوع المنافسة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
