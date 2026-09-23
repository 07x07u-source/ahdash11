import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/shared/presentation/app_shell.dart';
import 'package:ahdash_11/shared/presentation/app_states.dart';
import 'package:ahdash_11/shared/presentation/components.dart';
import 'package:ahdash_11/shared/presentation/v10_portrait.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared buttons expose one actionable Arabic semantic node', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _surface(
        Column(
          children: [
            AhdashButton(label: 'حفظ', onPressed: () {}),
            AhdashV10PrimaryButton(label: 'ابدأ اللعب', onPressed: () {}),
          ],
        ),
      ),
    );

    for (final label in ['حفظ', 'ابدأ اللعب']) {
      final finder = find.bySemanticsLabel(label);
      expect(finder, findsOneWidget);
      expect(
        tester
            .getSemantics(finder)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    }
    semantics.dispose();
  });

  testWidgets('loading controls announce progress without a tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _surface(
        Column(
          children: const [
            AhdashButton(label: 'حفظ', onPressed: null, loading: true),
            AhdashV10PrimaryButton(
              label: 'ابدأ اللعب',
              onPressed: null,
              loading: true,
            ),
          ],
        ),
      ),
    );

    for (final label in ['حفظ، جارٍ التنفيذ', 'ابدأ اللعب، جارٍ التنفيذ']) {
      final finder = find.bySemanticsLabel(label);
      expect(finder, findsOneWidget);
      expect(
        tester
            .getSemantics(finder)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
    }
    semantics.dispose();
  });

  testWidgets('loading skeleton is announced and respects reduced motion', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _surface(const LoadingSkeleton(lines: 2), reducedMotion: true),
    );

    expect(find.bySemanticsLabel('جارٍ تحميل المحتوى'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LoadingSkeleton),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('main shell keeps the system area transparent under the dock', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ProviderScope(
          child: AppShell(
            location: '/home',
            child: Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );

    final regions = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byWidgetPredicate(
            (widget) => widget is AnnotatedRegion<SystemUiOverlayStyle>,
          ),
        )
        .toList();
    expect(
      regions.any(
        (region) =>
            region.value.systemNavigationBarColor == Colors.transparent &&
            region.value.systemNavigationBarIconBrightness == Brightness.dark,
      ),
      isTrue,
    );
  });
}

Widget _surface(Widget child, {bool reducedMotion = false}) => MaterialApp(
  theme: AppTheme.light,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);
