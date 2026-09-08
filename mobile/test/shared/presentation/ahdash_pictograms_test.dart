import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/shared/presentation/ahdash_pictograms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every pictogram has a bundled non-empty PNG asset', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final pictogram in AhdashPictogram.values) {
      expect(pictogram.assetPath, endsWith('.png'));
      final data = await rootBundle.load(pictogram.assetPath);
      expect(data.lengthInBytes, greaterThan(0), reason: pictogram.assetPath);
    }
  });

  testWidgets('all supported sizes render in light and dark themes', (
    tester,
  ) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                children: [
                  for (final pictogram in AhdashPictogram.values)
                    for (final size in [24.0, 32.0, 48.0, 64.0, 96.0])
                      AhdashPictogramView(pictogram: pictogram, size: size),
                ],
              ),
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(Wrap));
      await tester.runAsync(() async {
        await Future.wait(
          AhdashPictogram.values.map(
            (pictogram) =>
                precacheImage(AssetImage(pictogram.assetPath), context),
          ),
        );
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('semantic label is opt-in and decorative images stay silent', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Row(
          children: [
            AhdashPictogramView(pictogram: AhdashPictogram.tournament),
            AhdashPictogramView(
              pictogram: AhdashPictogram.win,
              semanticLabel: 'فوز أحدعش',
            ),
          ],
        ),
      ),
    );

    expect(find.bySemanticsLabel('فوز أحدعش'), findsOneWidget);
    expect(find.bySemanticsLabel('بطولة'), findsNothing);
    semantics.dispose();
  });
}
