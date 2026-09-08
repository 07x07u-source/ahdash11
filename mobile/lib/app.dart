import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/services/app_services.dart';
import 'core/services/notification_service.dart';
import 'core/settings/app_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/guest_capability_policy.dart';
import 'features/auth/presentation/capability_provider.dart';
import 'features/premium/presentation/premium_access_provider.dart';

final class AhdashApp extends ConsumerStatefulWidget {
  const AhdashApp({super.key});

  @override
  ConsumerState<AhdashApp> createState() => _AhdashAppState();
}

final class _AhdashAppState extends ConsumerState<AhdashApp>
    with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final NotificationService _notifications;
  StreamSubscription<AppNotificationEvent>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications = ref.read(appServicesProvider).notifications;
    _notificationSubscription = _notifications.events.listen(
      _handleNotification,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await _notifications.takeInitialEvent();
      if (initial != null && mounted) _handleNotification(initial);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_notificationSubscription?.cancel());
    unawaited(_notifications.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(premiumAccessProvider);
    }
  }

  void _handleNotification(AppNotificationEvent event) {
    if (!mounted) return;
    if (event.source == NotificationOpenSource.foreground) {
      if (!ref
          .read(capabilityPolicyProvider)
          .allows(AppCapability.notifications)) {
        return;
      }
      final messenger = _messengerKey.currentState;
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${event.title}\n${event.body}'),
            action: SnackBarAction(
              label: 'عرض',
              onPressed: () => _openNotificationRoute(event.route),
            ),
          ),
        );
      return;
    }
    _openNotificationRoute(event.route);
  }

  void _openNotificationRoute(String route) {
    final router = ref.read(appRouterProvider);
    final target = GuestCapabilityPolicy.safeReturnTo(route);
    router.go(
      ref.read(capabilityPolicyProvider).allowsLocation(target)
          ? target
          : GuestCapabilityPolicy.gateLocation(target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final preferences =
        ref.watch(appPreferencesProvider).value ?? const AppPreferences();
    return MaterialApp.router(
      title: 'أحدعش | 11',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // V9.2 is an approved light-only product scope. Retain the legacy dark
      // ThemeData for isolated previews without exposing it in production UX.
      themeMode: ThemeMode.light,
      themeAnimationDuration: preferences.reducedMotion
          ? Duration.zero
          : AppMotion.standard,
      themeAnimationCurve: AppMotion.curve,
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                MediaQuery.disableAnimationsOf(context) ||
                preferences.reducedMotion,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.6),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
