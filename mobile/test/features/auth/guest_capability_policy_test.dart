import 'package:ahdash_11/features/auth/domain/auth_user.dart';
import 'package:ahdash_11/features/auth/domain/guest_capability_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guest = GuestCapabilityPolicy(
    AuthUser(id: 'anonymous-jwt', username: 'ضيف', isGuest: true),
  );
  const member = GuestCapabilityPolicy(
    AuthUser(id: 'member', username: 'محمد', isGuest: false),
  );
  test(
    'guests and missing identities have the same minimal local capabilities',
    () {
      for (final capability in AppCapability.values) {
        expect(
          guest.allows(capability),
          GuestCapabilityPolicy.guestAllowed.contains(capability),
        );
        expect(
          const GuestCapabilityPolicy(null).allows(capability),
          guest.allows(capability),
        );
        expect(member.allows(capability), isTrue);
      }
    },
  );
  test('all supported local Party stages and Solo remain accessible', () {
    for (final route in [
      '/home',
      '/settings',
      '/how-to-play',
      '/party/categories',
      '/party/teams',
      '/party/splitter',
      '/party/helpers',
      '/party/ready',
      '/party/board',
      '/party/question',
      '/party/reveal',
      '/party/result',
      '/solo',
      '/solo/match',
      '/solo/result',
    ]) {
      expect(guest.allowsLocation(route), isTrue, reason: route);
    }
  });
  test(
    'identity-bound destinations and future unknown routes are closed by default',
    () {
      for (final route in [
        '/friends?teamId=abc',
        '/blocked-players',
        '/teams',
        '/teams/join?code=ABC',
        '/teams/abc',
        '/challenges/abc',
        '/profile',
        '/notifications',
        '/party/games',
        '/ranking',
        '/football-preferences',
        '/premium',
        '/store',
        '/wallet',
        '/report-problem',
        '/tournaments',
        '/tournaments/create',
        '/tournaments/bracket',
        '/tournaments/match/abc',
        '/new-account-feature',
      ]) {
        expect(guest.allowsLocation(route), isFalse, reason: route);
      }
    },
  );
  test('resume rejects external destinations, loops and traversal', () {
    for (final route in <String?>[
      null,
      '',
      'https://example.com',
      '//example.com/home',
      '/auth?next=/friends',
      '/account-required',
      '/online',
      '/unknown',
      '/teams/../home',
      '/teams/%2e%2e/home',
      '/friends#fragment',
      '/friends\\evil',
    ]) {
      expect(
        GuestCapabilityPolicy.safeReturnTo(route),
        '/home',
        reason: '$route',
      );
    }
  });
  test('safe intent survives encoding and account-mode selection', () {
    const destination = '/friends?teamId=existing-team';
    final gate = Uri.parse(GuestCapabilityPolicy.gateLocation(destination));
    expect(gate.path, '/account-required');
    expect(gate.queryParameters['next'], destination);
    final auth = Uri.parse(
      GuestCapabilityPolicy.authLocation(destination, create: true),
    );
    expect(auth.path, '/auth');
    expect(auth.queryParameters, {'next': destination, 'mode': 'create'});
  });
}
