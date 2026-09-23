import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/presentation/blocked_players_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fake_social_repository.dart';
import '../helpers/phase6_fixture.dart';
import '../helpers/test_app.dart';
import '../helpers/visual_test_variant.dart';

enum _State { populated, empty, loading, error, busy, unavailable }

const _rows = <Map<String, Object?>>[
  {
    'user_id': 'blocked-a',
    'display_name': 'سلمان الحربي',
    'username': 'Salman_11',
  },
  {
    'user_id': 'blocked-b',
    'display_name': 'عبدالرحمن محمد العتيبي',
    'username': 'football_fan',
  },
  {
    'user_id': 'blocked-c',
    'display_name': 'نواف القحطاني',
    'username': 'Nawaf_11',
  },
];

void main() {
  setUpAll(() async {
    final fonts = FontLoader('ThmanyahSans');
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      fonts.addFont(
        rootBundle.load('assets/fonts/thmanyah/thmanyahsans-$weight.otf'),
      );
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final size in const [Size(390, 844), Size(360, 800)]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final state in _State.values) {
        final variant = VisualTestVariant(size, scale);
        testWidgets('blocked ${state.name} ${variant.label}', (tester) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(() {
            tester.view
              ..resetPhysicalSize()
              ..resetDevicePixelRatio();
          });
          final repository = FakeSocialRepository(
            blockedPlayers: state == _State.empty ? [] : [..._rows],
          );
          final loading = Completer<List<Map<String, Object?>>>();
          if (state == _State.busy) repository.unblockGate = Completer<void>();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appConfigProvider.overrideWithValue(phase6Config),
                appServicesProvider.overrideWithValue(const AppServices.noop()),
                appPreferencesProvider.overrideWithBuild(
                  (ref, notifier) async =>
                      const AppPreferences(reducedMotion: true),
                ),
                socialRepositoryProvider.overrideWithValue(
                  state == _State.unavailable
                      ? SocialRepository(null)
                      : repository,
                ),
                if (state == _State.loading)
                  blockedPlayersProvider.overrideWith((ref) => loading.future),
                if (state == _State.error)
                  blockedPlayersProvider.overrideWith(
                    (ref) =>
                        Future.error(StateError('private backend details')),
                  ),
              ],
              child: testApp(
                MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                    padding: const EdgeInsets.only(top: 47, bottom: 34),
                    viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                  ),
                  child: const BlockedPlayersScreen(),
                ),
                theme: AppTheme.light,
              ),
            ),
          );
          if (state == _State.loading) {
            await tester.pump(const Duration(milliseconds: 100));
          } else {
            await tester.pumpAndSettle();
          }
          expect(
            find.byKey(const ValueKey('blocked-privacy-artwork')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('blocked-empty-artwork')),
            state == _State.empty ? findsOneWidget : findsNothing,
          );
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          final context = tester.element(find.byType(MaterialApp));
          await tester.runAsync(
            () => Future.wait(
              images.map((image) => precacheImage(image.image, context)),
            ),
          );
          await tester.pump();
          if (state == _State.busy) {
            final button = find.byKey(const ValueKey('unblock-blocked-a'));
            tester.widget<OutlinedButton>(button).onPressed!();
            await tester.pump();
            expect(repository.unblocks, 1);
            expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
          }
          await verifyVisual(
            tester,
            find.byType(MaterialApp),
            'goldens/blocked_review/${state.name}_${size.width.round()}x${size.height.round()}.png',
            variant,
          );
          expect(find.textContaining('private backend'), findsNothing);
          if (state == _State.unavailable) {
            expect(find.text('قائمة الحظر فارغة'), findsNothing);
          }
          if (state == _State.busy) {
            repository.unblockGate!.complete();
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('blocked-player-blocked-a')),
              findsNothing,
            );
            expect(
              find.byKey(const ValueKey('blocked-player-blocked-b')),
              findsOneWidget,
            );
          }
        });
      }
    }
  }
}
