import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/notifications/data/notifications_repository.dart';
import 'package:ahdash_11/features/notifications/presentation/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase6_fixture.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('prioritizes unread notifications and filters the inbox', (
    tester,
  ) async {
    final repository = _FakeNotificationsRepository();
    await _pumpNotifications(tester, repository);

    expect(find.byKey(const ValueKey('notifications-summary')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notifications-recent-group')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notifications-previous-group')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('notifications-filter-unread')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('notifications-recent-group')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notifications-previous-group')),
      findsNothing,
    );
    expect(find.text(phase6Notifications.first.title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mark all read is guarded while the request is pending', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = _FakeNotificationsRepository()..markAllGate = gate;
    await _pumpNotifications(tester, repository);

    await tester.tap(find.byKey(const ValueKey('notifications-mark-all-read')));
    await tester.pump();

    expect(repository.markAllCalls, 1);
    expect(find.text('جارٍ التحديث'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.byKey(const ValueKey('notifications-mark-all-read')),
    );
    expect(button.onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.markAllCalls, 1);
    expect(find.text('تم تعليم جميع الإشعارات كمقروءة.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpNotifications(
  WidgetTester tester,
  _FakeNotificationsRepository repository,
) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(phase6Config),
        appServicesProvider.overrideWithValue(const AppServices.noop()),
        appPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => const AppPreferences(reducedMotion: true),
        ),
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => phase6User,
        ),
        notificationsRepositoryProvider.overrideWithValue(repository),
        notificationsProvider.overrideWith((ref) async => phase6Notifications),
      ],
      child: testApp(const NotificationsScreen(), theme: AppTheme.light),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository() : super(null);

  Completer<void>? markAllGate;
  int markAllCalls = 0;

  @override
  Future<void> markAllRead(String userId) async {
    markAllCalls += 1;
    await markAllGate?.future;
  }

  @override
  Future<void> markRead(String userId, String id) async {}
}
