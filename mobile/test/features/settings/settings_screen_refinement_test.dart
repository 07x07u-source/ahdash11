import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/premium/presentation/premium_controller.dart';
import 'package:ahdash_11/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase6_fixture.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('quick device controls persist and update immediately', (
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
    final storage = _MemoryPreferenceStorage();
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(phase6Config),
        appServicesProvider.overrideWithValue(const AppServices.noop()),
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => phase6User,
        ),
        preferenceStorageProvider.overrideWithValue(storage),
        premiumControllerProvider.overrideWithBuild(
          (ref, notifier) async => const PremiumView(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testApp(const SettingsScreen(), theme: AppTheme.light),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-device-preferences')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('settings-quick-sound')));
    await tester.pumpAndSettle();

    expect(storage.values['sound_effects_enabled'], isFalse);
    expect(container.read(appPreferencesProvider).value?.soundEffects, isFalse);
    expect(tester.takeException(), isNull);
  });
}

final class _MemoryPreferenceStorage extends PreferenceStorage {
  _MemoryPreferenceStorage();

  final values = <String, Object>{
    'sound_effects_enabled': true,
    'haptics_enabled': true,
    'reduced_motion_enabled': false,
  };

  @override
  Future<Object?> read(String key) async => values[key];

  @override
  Future<void> write(String key, Object value) async {
    values[key] = value;
  }
}
