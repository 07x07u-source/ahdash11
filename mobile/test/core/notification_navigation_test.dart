import 'package:ahdash_11/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification permission denial is never treated as enabled', () {
    expect(
      NotificationPermissionPolicy.isAllowed(AuthorizationStatus.denied),
      isFalse,
    );
    expect(
      NotificationPermissionPolicy.isAllowed(AuthorizationStatus.notDetermined),
      isFalse,
    );
    expect(
      NotificationPermissionPolicy.isAllowed(AuthorizationStatus.authorized),
      isTrue,
    );
  });

  group('NotificationNavigation', () {
    test('accepts only known app destinations', () {
      expect(NotificationNavigation.resolve({'deep_link': '/store'}), '/store');
      expect(NotificationNavigation.resolve({'deep_link': '/teams'}), '/teams');
      expect(
        NotificationNavigation.resolve({
          'deep_link': '/teams/11111111-1111-4111-8111-111111111111',
        }),
        '/teams/11111111-1111-4111-8111-111111111111',
      );
      expect(
        NotificationNavigation.resolve({'deep_link': '/teams/not-a-uuid'}),
        '/notifications',
      );
      expect(
        NotificationNavigation.resolve({'deep_link': '/settings/delete'}),
        '/notifications',
      );
      expect(
        NotificationNavigation.resolve({
          'deep_link': '/teams/join?code=11TEAM24',
        }),
        '/teams/join?code=11TEAM24',
      );
      expect(
        NotificationNavigation.resolve({
          'deep_link': '/tournaments/join?code=A11CUP26',
        }),
        '/tournaments/join?code=A11CUP26',
      );
      expect(
        NotificationNavigation.resolve({'deep_link': 'https://evil.test'}),
        '/notifications',
      );
    });

    test('legacy live-match invitations no longer open gameplay', () {
      expect(
        NotificationNavigation.resolve({
          'type': 'match_invite',
          'match_id': '123e4567-e89b-42d3-a456-426614174000',
        }),
        '/notifications',
      );
      expect(
        NotificationNavigation.resolve({
          'type': 'match_invite',
          'match_id': '../../settings',
        }),
        '/notifications',
      );
    });

    test('falls back safely for deleted or incomplete content', () {
      expect(NotificationNavigation.resolve({}), '/notifications');
      expect(
        NotificationNavigation.resolve({'type': 'promotion'}),
        '/notifications',
      );
    });
  });
}
