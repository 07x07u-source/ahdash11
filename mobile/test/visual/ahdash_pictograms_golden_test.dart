import 'package:ahdash_11/core/theme/app_colors.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/shared/presentation/ahdash_pictograms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('ThmanyahSans')
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Bold.otf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/thmanyah/thmanyahsans-Black.otf'),
          ))
        .load();
  });

  testWidgets('AHDASH raster pictogram V2 contact sheet', (tester) async {
    const size = Size(1600, 2520);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    const key = ValueKey('ahdash-pictograms-v2-contact-sheet');
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: RepaintBoundary(key: key, child: const _ContactSheet()),
        ),
      ),
    );
    await tester.pump();
    final context = tester.element(find.byKey(key));
    await tester.runAsync(() async {
      for (final pictogram in AhdashPictogram.values) {
        await precacheImage(AssetImage(pictogram.assetPath), context);
      }
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(key),
      matchesGoldenFile(
        '../../../docs/visual-validation/ahdash-pictograms-v2-contact-sheet.png',
      ),
    );
  });
}

final class _ContactSheet extends StatelessWidget {
  const _ContactSheet();

  static const labels = {
    AhdashPictogram.win: 'WIN',
    AhdashPictogram.champion: 'CHAMPION',
    AhdashPictogram.tournament: 'TOURNAMENT',
    AhdashPictogram.draw: 'DRAW',
    AhdashPictogram.premium: 'PREMIUM',
    AhdashPictogram.categoriesStep: 'CATEGORIES STEP',
    AhdashPictogram.teamsStep: 'TEAMS STEP',
    AhdashPictogram.questionStep: 'QUESTION STEP',
    AhdashPictogram.emptyGames: 'EMPTY GAMES',
    AhdashPictogram.emptyFriends: 'EMPTY FRIENDS',
    AhdashPictogram.twoChances: 'TWO CHANCES',
    AhdashPictogram.callFriend: 'CALL FRIEND',
    AhdashPictogram.risk: 'RISK',
    AhdashPictogram.bench: 'BENCH',
    AhdashPictogram.pass: 'PASS',
  };

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF3F1EA),
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'AHDASH | 11 — RASTER PICTOGRAM SYSTEM V2',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Color(0xFF101418),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '1024 × 1024 PNG masters • true alpha • Light Ink / Dark inverse / Gold • 48 / 80 / 128',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: context.ahdashColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AhdashPictogram.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 450,
              ),
              itemBuilder: (context, index) {
                final pictogram = AhdashPictogram.values[index];
                return _PictogramTile(
                  pictogram: pictogram,
                  label: labels[pictogram]!,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

final class _PictogramTile extends StatelessWidget {
  const _PictogramTile({required this.pictogram, required this.label});

  final AhdashPictogram pictogram;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFD9D5CB)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Color(0xFF101418),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _ToneRow(
                    label: 'LIGHT INK',
                    pictogram: pictogram,
                    tone: AhdashPictogramTone.standard,
                    background: Color(0xFFFBF7EF),
                    labelColor: Color(0xFF101418),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _ToneRow(
                    label: 'DARK INVERSE',
                    pictogram: pictogram,
                    tone: AhdashPictogramTone.inverse,
                    background: Color(0xFF101418),
                    labelColor: Color(0xFFFBF7EF),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _ToneRow(
                    label: 'GOLD',
                    pictogram: pictogram,
                    tone: AhdashPictogramTone.achievement,
                    background: Color(0xFFFBF7EF),
                    labelColor: Color(0xFF101418),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class _ToneRow extends StatelessWidget {
  const _ToneRow({
    required this.label,
    required this.pictogram,
    required this.tone,
    required this.background,
    required this.labelColor,
  });

  final String label;
  final AhdashPictogram pictogram;
  final AhdashPictogramTone tone;
  final Color background;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: labelColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          for (final iconSize in [48.0, 80.0, 128.0]) ...[
            AhdashPictogramView(
              pictogram: pictogram,
              size: iconSize,
              tone: tone,
              color: tone == AhdashPictogramTone.inverse
                  ? const Color(0xFFFBF7EF)
                  : null,
            ),
            if (iconSize != 128) const SizedBox(width: 8),
          ],
        ],
      ),
    ),
  );
}
