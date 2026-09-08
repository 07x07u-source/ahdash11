import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Player11 variant persists locally without changing auth data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        (await container.read(appPreferencesProvider.future)).player11Variant,
        Player11Variant.male,
      );

      await container
          .read(appPreferencesProvider.notifier)
          .setPlayer11Variant(Player11Variant.female);

      expect(
        container.read(appPreferencesProvider).value?.player11Variant,
        Player11Variant.female,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('player11_variant'),
        'female',
      );
    },
  );
}
