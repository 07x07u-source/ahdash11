import 'package:ahdash_11/app.dart';
import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold launch reaches onboarding then authentication', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const config = AppConfig(
      environment: AppEnvironment.development,
      supabaseUrl: '',
      supabaseKey: '',
      firebaseEnabled: false,
      adMobEnabled: false,
      revenueCatAndroidKey: '',
      revenueCatIosKey: '',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          appServicesProvider.overrideWithValue(const AppServices.noop()),
        ],
        child: const AhdashApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الكورة تعرف أهلها'), findsOneWidget);
    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    expect(find.text('الدخول كضيف'), findsOneWidget);
  });
}
