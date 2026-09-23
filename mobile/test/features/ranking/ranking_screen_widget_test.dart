import 'package:ahdash_11/features/ranking/presentation/ranking_controller.dart';
import 'package:ahdash_11/features/ranking/presentation/ranking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/v10_feature_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('ranking presents the verified podium and localized tiers', (
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
          leaderboardProvider.overrideWith(
            (ref) async => V10FeatureFixtures.ranking,
          ),
        ],
        child: testApp(const RankingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('منصة المتصدرين'), findsOneWidget);
    expect(find.text('موثّق'), findsOneWidget);
    expect(find.text('نواف العتيبي'), findsWidgets);
    expect(find.text('ماسي'), findsWidgets);
    expect(find.byKey(const ValueKey('ranking-real-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty ranking never invents players or positions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [leaderboardProvider.overrideWith((ref) async => const [])],
        child: testApp(const RankingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الصدارة تنتظر أول نتيجة'), findsOneWidget);
    expect(find.text('لا توجد مراكز أو نتائج تجريبية'), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-real-list')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
