import 'auth_user.dart';

/// Client UX policy only. Server JWT, ownership and RLS remain authoritative.
enum AppCapability {
  home,
  howToPlay,
  localParty,
  localSolo,
  localSettings,
  savedGames,
  tournaments,
  profile,
  friends,
  teamChallenge,
  notifications,
  ranking,
  footballPreferences,
  premium,
  reports,
  cloudSync,
  account,
}

final class GuestCapabilityPolicy {
  const GuestCapabilityPolicy(this.user);
  final AuthUser? user;

  bool get hasAccount => user != null && !user!.isGuest;
  static const guestAllowed = {
    AppCapability.home,
    AppCapability.howToPlay,
    AppCapability.localParty,
    AppCapability.localSolo,
    AppCapability.localSettings,
  };

  bool allows(AppCapability capability) =>
      hasAccount || guestAllowed.contains(capability);

  bool allowsLocation(String location) => allows(capabilityFor(location));

  static AppCapability capabilityFor(String location) {
    final path = Uri.tryParse(location)?.path ?? '';
    if (path == '/home') return AppCapability.home;
    if (path == '/how-to-play') return AppCapability.howToPlay;
    if (path == '/settings') return AppCapability.localSettings;
    if (path == '/party/games') return AppCapability.savedGames;
    if (const {
      '/party/categories',
      '/party/teams',
      '/party/splitter',
      '/party/helpers',
      '/party/ready',
      '/party/board',
      '/party/question',
      '/party/reveal',
      '/party/result',
      '/categories',
      '/play',
    }.contains(path)) {
      return AppCapability.localParty;
    }
    if (const {'/solo', '/solo/match', '/solo/result'}.contains(path)) {
      return AppCapability.localSolo;
    }
    if (RegExp(r'^/play/setup/[a-z-]+$').hasMatch(path)) {
      return AppCapability.localParty;
    }
    if (path == '/tournaments' || path.startsWith('/tournaments/')) {
      return AppCapability.tournaments;
    }
    if (path == '/profile') return AppCapability.profile;
    if (path == '/friends' || path == '/blocked-players') {
      return AppCapability.friends;
    }
    if (path == '/teams' ||
        path.startsWith('/teams/') ||
        path.startsWith('/challenges/')) {
      return AppCapability.teamChallenge;
    }
    if (path == '/notifications') return AppCapability.notifications;
    if (path == '/ranking') return AppCapability.ranking;
    if (path == '/football-preferences') {
      return AppCapability.footballPreferences;
    }
    if (path == '/premium' ||
        path.startsWith('/premium/') ||
        const {'/store', '/wallet'}.contains(path)) {
      return AppCapability.premium;
    }
    if (path == '/report-problem') return AppCapability.reports;
    return AppCapability.account; // New routes are restricted by default.
  }

  /// Resume only known local navigation targets, never arbitrary URLs or auth loops.
  static String safeReturnTo(String? raw) {
    if (raw == null || raw.isEmpty) return '/home';
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasFragment ||
        raw.contains('\\') ||
        uri.pathSegments.any((s) => s == '.' || s == '..')) {
      return '/home';
    }
    final path = uri.path;
    const exact = {
      '/home',
      '/how-to-play',
      '/settings',
      '/party/games',
      '/party/categories',
      '/party/teams',
      '/party/splitter',
      '/party/helpers',
      '/party/ready',
      '/party/board',
      '/party/question',
      '/party/reveal',
      '/party/result',
      '/categories',
      '/play',
      '/solo',
      '/solo/match',
      '/solo/result',
      '/tournaments',
      '/tournaments/create',
      '/tournaments/join',
      '/tournaments/teams',
      '/tournaments/registrations',
      '/tournaments/draw',
      '/tournaments/bracket',
      '/tournaments/champion',
      '/profile',
      '/friends',
      '/blocked-players',
      '/teams',
      '/teams/join',
      '/notifications',
      '/ranking',
      '/football-preferences',
      '/premium',
      '/premium/voucher',
      '/store',
      '/report-problem',
    };
    final dynamicRoute = RegExp(
      r'^/(teams|challenges|tournaments/match|play/setup)/[A-Za-z0-9_-]+$',
    ).hasMatch(path);
    return exact.contains(path) || dynamicRoute ? uri.toString() : '/home';
  }

  static String gateLocation(String destination, {AppCapability? capability}) =>
      Uri(
        path: '/account-required',
        queryParameters: {
          'next': safeReturnTo(destination),
          if (capability != null) 'feature': capability.name,
        },
      ).toString();

  static String authLocation(String destination, {bool create = false}) => Uri(
    path: '/auth',
    queryParameters: {
      'next': safeReturnTo(destination),
      if (create) 'mode': 'create',
    },
  ).toString();
}
