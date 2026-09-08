import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/services/app_error_reporter.dart';
import 'core/services/app_services.dart';

Future<void> main() async {
  var activeServices = const AppServices.noop();
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      final config = AppConfig.fromEnvironment();
      try {
        activeServices = await AppBootstrap.initialize(config);
      } catch (error, stackTrace) {
        FlutterError.presentError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
        runApp(const _StartupFailureApp());
        return;
      }

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        final stack = details.stack ?? StackTrace.current;
        unawaited(
          activeServices.crashReporter.record(
            details.exception,
            stack,
            fatal: true,
          ),
        );
        unawaited(
          activeServices.errors.report(
            severity: AppErrorSeverity.critical,
            category: AppErrorCategory.unexpectedState,
            feature: 'flutter_framework',
            error: details.exception,
            stackTrace: stack,
          ),
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(
          activeServices.crashReporter.record(error, stack, fatal: true),
        );
        unawaited(
          activeServices.errors.report(
            severity: AppErrorSeverity.critical,
            category: AppErrorCategory.unexpectedState,
            feature: 'platform_dispatcher',
            error: error,
            stackTrace: stack,
          ),
        );
        return true;
      };

      runApp(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            appServicesProvider.overrideWithValue(activeServices),
          ],
          child: const AhdashApp(),
        ),
      );
    },
    (error, stack) {
      unawaited(activeServices.crashReporter.record(error, stack, fatal: true));
      unawaited(
        activeServices.errors.report(
          severity: AppErrorSeverity.critical,
          category: AppErrorCategory.unexpectedState,
          feature: 'root_zone',
          error: error,
          stackTrace: stack,
        ),
      );
    },
  );
}

final class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F5F1),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: Color(0xFFC83443),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'تعذر تجهيز أحدعش',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'تأكد من اتصال الإنترنت ثم أغلق التطبيق وافتحه مرة ثانية. لم تُعرض تفاصيل تقنية حفاظًا على الخصوصية.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: 1.6,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
