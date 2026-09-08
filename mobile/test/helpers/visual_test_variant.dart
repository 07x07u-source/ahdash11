import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Additional responsiveness checks. Existing Golden assertions remain intact.
final class VisualTestVariant {
  const VisualTestVariant(this.size, this.scale);
  final Size size;
  final double scale;
  String get label =>
      '${size.width.toInt()}x${size.height.toInt()}_scale$scale';
}

Future<void> verifyVisual(
  WidgetTester tester,
  Finder finder,
  String golden,
  VisualTestVariant? variant,
) async {
  expect(tester.takeException(), isNull);
  if (variant == null) {
    await expectLater(finder, matchesGoldenFile(golden));
    return;
  }
  // Verify accessibility isn't "fixed" by turning text scaling off downstream.
  for (final element in find.byType(Text).evaluate()) {
    expect(
      MediaQuery.textScalerOf(element).scale(10),
      closeTo(variant.scale * 10, 0.01),
      reason: 'Text scaling was overridden: ${element.widget}',
    );
  }
  expect(tester.view.physicalSize, variant.size);
  const output = String.fromEnvironment('UI_REVIEW_DIR');
  if (output.isEmpty) return;
  final stem = golden.split('/').last.replaceAll(RegExp(r'_\d+x\d+\.png$'), '');
  final folder = golden.contains('phase_b')
      ? 'party'
      : golden.contains('phase_c')
      ? 'tournament'
      : 'account';
  // The root test repaint boundary captures actual Flutter pixels, not a baseline.
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('test-app-boundary')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$output/$folder/${stem}_${variant.label}.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
