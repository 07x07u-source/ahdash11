import 'dart:io';

import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/shared/presentation/v10_portrait.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'active Flutter and platform manifests keep phone portrait and iPad support',
    () {
      final main = File('lib/main.dart').readAsStringSync();
      final android = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final ios = File('ios/Runner/Info.plist').readAsStringSync();

      final phoneOrientations = _orientationArray(
        ios,
        'UISupportedInterfaceOrientations',
      );
      final ipadOrientations = _orientationArray(
        ios,
        'UISupportedInterfaceOrientations~ipad',
      );

      expect(main, contains('DeviceOrientation.portraitUp'));
      expect(main, isNot(contains('DeviceOrientation.landscape')));
      expect(main, isNot(contains('DeviceOrientation.portraitDown')));
      expect(android, contains('android:screenOrientation="portrait"'));
      expect(phoneOrientations, ['UIInterfaceOrientationPortrait']);
      expect(
        ipadOrientations,
        containsAll(const [
          'UIInterfaceOrientationPortrait',
          'UIInterfaceOrientationPortraitUpsideDown',
          'UIInterfaceOrientationLandscapeLeft',
          'UIInterfaceOrientationLandscapeRight',
        ]),
      );
    },
  );

  for (final size in const [
    Size(360, 800),
    Size(390, 844),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ]) {
    for (final scale in const [1.0, 1.2, 1.3]) {
      testWidgets('keyboard scaffold scrolls at $size, scale $scale', (
        tester,
      ) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(() {
          tester.view
            ..resetPhysicalSize()
            ..resetDevicePixelRatio();
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
                viewInsets: const EdgeInsets.only(bottom: 300),
              ),
              child: const Scaffold(
                body: AhdashV10KeyboardScroll(
                  child: Column(
                    children: [
                      TextField(textInputAction: TextInputAction.next),
                      SizedBox(height: 560),
                      TextField(textInputAction: TextInputAction.done),
                      SizedBox(height: 12),
                      FilledButton(onPressed: null, child: Text('متابعة')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey('v10-keyboard-scroll')),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('متابعة'));
        await tester.pump();
        expect(
          tester.getBottomRight(find.text('متابعة')).dy,
          lessThanOrEqualTo(size.height),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

List<String> _orientationArray(String plist, String key) {
  final match = RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*<array>(.*?)</array>',
    dotAll: true,
  ).firstMatch(plist);
  return RegExp(
    r'<string>(.*?)</string>',
  ).allMatches(match?.group(1) ?? '').map((value) => value.group(1)!).toList();
}
