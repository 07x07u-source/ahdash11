import 'dart:io';
import 'dart:ui' as ui;

import 'package:ahdash_11/core/theme/app_colors.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/home/presentation/streak_milestone_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// Optional output directory for real Flutter screenshots used by the design
/// review gallery. Without the define, this remains a normal visual smoke test.
const _output = String.fromEnvironment('STREAK_SCREENSHOT_DIR');

void main() {
  setUpAll(() async {
    // Keep diagnostics out of exported review images. Some local Flutter test
    // sessions leave baseline painting enabled through the rendering service.
    _disableFlutterDiagnostics();
    final font = FontLoader('ThmanyahSans');
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      font.addFont(
        rootBundle.load('assets/fonts/thmanyah/thmanyahsans-$weight.otf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  const milestones = <({int days, String emoji})>[
    (days: 10, emoji: '🔥'),
    (days: 50, emoji: '🔥'),
    (days: 100, emoji: '🏆'),
    (days: 365, emoji: '👑'),
  ];

  for (final milestone in milestones) {
    testWidgets(
      'captures the ${milestone.days}-day streak milestone screen',
      (tester) async {
        _disableFlutterDiagnostics();
        tester.view
          ..physicalSize = const Size(390, 844)
          ..devicePixelRatio = 1;
        addTearDown(() {
          tester.view
            ..resetPhysicalSize()
            ..resetDevicePixelRatio();
        });

        Widget buildScreen() => ProviderScope(
          child: testApp(
            ColoredBox(
              color: AppColors.paper0,
              child: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: StreakMilestoneCelebration(
                  days: milestone.days,
                  emoji: milestone.emoji,
                  onContinue: () {},
                ),
              ),
            ),
            theme: AppTheme.light,
          ),
        );

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();
        _disableFlutterDiagnostics();
        // Remount once after disabling diagnostics so the repaint boundary does
        // not retain a debug paint layer from a previous local test session.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();
        _disableFlutterDiagnostics();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('streak-milestone-days')), findsOneWidget);

        if (_output.isEmpty) return;
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('test-app-boundary')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '$_output/streak_${milestone.days}_days_390x844.png',
          );
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      },
    );
  }
}

void _disableFlutterDiagnostics() {
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugPaintTextLayoutBoxes = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugRepaintTextRainbowEnabled = false;
}
