import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/notifications/data/notifications_repository.dart';
import 'package:ahdash_11/features/notifications/presentation/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/phase6_fixture.dart';
import '../helpers/test_app.dart';
import '../helpers/visual_test_variant.dart';

enum _State { populated, allRead, empty, loading, error }

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
    for (final scale in const [1.0, 1.3, 2.0]) {
      for (final state in _State.values) {
        final variant = VisualTestVariant(size, scale);
        testWidgets('notifications ${state.name} ${variant.label}', (
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
          final loading = Completer<List<InboxNotification>>();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appConfigProvider.overrideWithValue(phase6Config),
                appServicesProvider.overrideWithValue(const AppServices.noop()),
                appPreferencesProvider.overrideWithBuild(
                  (ref, notifier) async =>
                      const AppPreferences(reducedMotion: true),
                ),
                authControllerProvider.overrideWithBuild(
                  (ref, notifier) async => phase6User,
                ),
                notificationsProvider.overrideWith((ref) {
                  if (state == _State.loading) return loading.future;
                  if (state == _State.error) {
                    return Future.error(
                      StateError('private notifications backend detail'),
                    );
                  }
                  if (state == _State.empty) {
                    return Future.value(const <InboxNotification>[]);
                  }
                  if (state == _State.allRead) {
                    return Future.value(
                      phase6Notifications
                          .map(
                            (item) => InboxNotification(
                              id: item.id,
                              type: item.type,
                              title: item.title,
                              body: item.body,
                              createdAt: item.createdAt,
                              readAt: item.readAt ?? item.createdAt,
                              data: item.data,
                            ),
                          )
                          .toList(growable: false),
                    );
                  }
                  return Future.value(phase6Notifications);
                }),
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
                  child: const NotificationsScreen(),
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
            find.byKey(const ValueKey('notifications-summary')),
            state == _State.populated ||
                    state == _State.allRead ||
                    state == _State.empty
                ? findsOneWidget
                : findsNothing,
          );
          expect(
            find.byKey(const ValueKey('notifications-empty')),
            state == _State.empty ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const ValueKey('notifications-loading')),
            state == _State.loading ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const ValueKey('notifications-error')),
            state == _State.error ? findsOneWidget : findsNothing,
          );
          await verifyVisual(
            tester,
            find.byType(MaterialApp),
            'goldens/notifications_review/${state.name}_${size.width.round()}x${size.height.round()}.png',
            variant,
          );
          expect(
            find.textContaining('private notifications backend'),
            findsNothing,
          );
        });
      }
    }
  }
}
