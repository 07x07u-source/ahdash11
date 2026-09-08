import 'package:ahdash_11/features/settings/presentation/notification_preferences_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing promotion preference remains opt-in and off by default', () {
    final preferences = mergeNotificationPreferences({
      'friend_requests': false,
    });

    expect(preferences['friend_requests'], isFalse);
    expect(preferences['match_invites'], isTrue);
    expect(preferences['promotions'], isFalse);
  });
}
