import 'package:ahdash_11/features/categories/presentation/categories_controller.dart';
import 'package:ahdash_11/features/match/presentation/solo_setup_screen.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('Solo setup enables start only after selecting a category', (
    tester,
  ) async {
    await _pump(tester, categories: _categories);

    FilledButton startButton() => tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('solo-start-primary')),
        matching: find.byType(FilledButton),
      ),
    );

    expect(find.text('11 سؤال'), findsOneWidget);
    expect(startButton().onPressed, isNull);

    await tester.tap(find.text('الدوري السعودي'));
    await tester.pump();

    expect(find.text('1 محدد'), findsOneWidget);
    expect(startButton().onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Solo setup keeps the truthful unavailable state', (
    tester,
  ) async {
    await _pump(tester, categories: const []);

    expect(find.text('لا توجد أقسام متاحة الآن'), findsOneWidget);
    expect(find.text('ستظهر هنا الأقسام المنشورة الجاهزة للعب.'), findsOneWidget);
    expect(find.byKey(const ValueKey('solo-start-primary')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required List<QuizCategory> categories,
}) async {
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
        categoriesProvider.overrideWithBuild(
          (ref, notifier) async => categories,
        ),
      ],
      child: testApp(const SoloSetupScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

const _categories = [
  QuizCategory(
    id: 'solo-test-category',
    name: 'الدوري السعودي',
    description: 'أسئلة محلية',
    iconName: 'sports_soccer',
    accentColor: Color(0xFF246B53),
  ),
];
