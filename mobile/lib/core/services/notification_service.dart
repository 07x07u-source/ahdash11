import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/supabase_user_mapper.dart';

abstract interface class NotificationService {
  Stream<AppNotificationEvent> get events;
  Future<String?> initialize();
  Future<AppNotificationEvent?> takeInitialEvent();
  Future<bool> requestPermission();
  Future<void> identify(String userId);
  Future<void> signOut();
  Future<void> dispose();
}

enum NotificationOpenSource { foreground, background, terminated }

abstract final class NotificationPermissionPolicy {
  static bool isAllowed(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;
}

final class AppNotificationEvent {
  const AppNotificationEvent({
    required this.title,
    required this.body,
    required this.route,
    required this.source,
  });

  final String title;
  final String body;
  final String route;
  final NotificationOpenSource source;
}

abstract final class NotificationNavigation {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static const _safeRoutes = {
    '/home',
    '/notifications',
    '/profile',
    '/store',
    '/ranking',
    '/friends',
    '/teams',
    '/tournaments',
  };

  static String resolve(Map<String, dynamic> data) {
    final explicit = data['deep_link']?.toString().trim();
    if (explicit != null) {
      if (_safeRoutes.contains(explicit)) return explicit;
      final uri = Uri.tryParse(explicit);
      if (uri == null ||
          uri.hasScheme ||
          uri.hasAuthority ||
          uri.hasFragment ||
          !explicit.startsWith('/') ||
          explicit.contains('\\')) {
        return '/notifications';
      }
      final segments = uri.pathSegments;
      if (segments.length == 2 &&
          (segments.first == 'teams' || segments.first == 'challenges') &&
          _uuid.hasMatch(segments.last)) {
        return '/${segments.first}/${segments.last}';
      }
      if ((uri.path == '/teams/join' || uri.path == '/tournaments/join') &&
          RegExp(
            r'^[A-Za-z0-9]{4,12}$',
          ).hasMatch(uri.queryParameters['code'] ?? '')) {
        return Uri(
          path: uri.path,
          queryParameters: {'code': uri.queryParameters['code']!},
        ).toString();
      }
    }
    return '/notifications';
  }
}

final class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Stream<AppNotificationEvent> get events => const Stream.empty();

  @override
  Future<String?> initialize() async => null;

  @override
  Future<AppNotificationEvent?> takeInitialEvent() async => null;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> dispose() async {}
}

final class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService(
    this._messaging,
    this._supabase, {
    required this.appVersion,
  });

  final FirebaseMessaging _messaging;
  final SupabaseClient? _supabase;
  final String appVersion;
  final StreamController<AppNotificationEvent> _events =
      StreamController<AppNotificationEvent>.broadcast();
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  AppNotificationEvent? _initialEvent;
  String? _token;

  @override
  Stream<AppNotificationEvent> get events => _events.stream;

  @override
  Future<String?> initialize() async {
    await _cancelSubscriptions();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    final settings = await _messaging.getNotificationSettings();
    if (NotificationPermissionPolicy.isAllowed(settings.authorizationStatus)) {
      _token = await _messaging.getToken();
    }
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (token) => unawaited(_rotateToken(token).catchError((_) {})),
    );
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (message) => _emit(message, NotificationOpenSource.foreground),
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _emit(message, NotificationOpenSource.background),
    );
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _initialEvent = _eventFrom(
        initialMessage,
        NotificationOpenSource.terminated,
      );
    }
    return _token;
  }

  @override
  Future<AppNotificationEvent?> takeInitialEvent() async {
    final event = _initialEvent;
    _initialEvent = null;
    return event;
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (!NotificationPermissionPolicy.isAllowed(settings.authorizationStatus)) {
      return false;
    }
    _token = await _messaging.getToken();
    final userId = _supabase?.auth.currentUser?.id;
    if (userId != null && _token != null) await _save(userId, _token!);
    return true;
  }

  @override
  Future<void> identify(String userId) async {
    final settings = await _messaging.getNotificationSettings();
    if (!NotificationPermissionPolicy.isAllowed(settings.authorizationStatus)) {
      return;
    }
    final token = _token ?? await _messaging.getToken();
    if (token == null) return;
    _token = token;
    await _save(userId, token);
  }

  Future<void> _save(String userId, String token) async {
    final client = _supabase;
    if (client == null ||
        client.auth.currentUser?.id != userId ||
        !supabaseCapabilities(client.auth.currentUser).hasAccount) {
      return;
    }
    await client.from('device_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
      'locale': 'ar',
      'app_version': appVersion,
      'is_active': true,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'token');
  }

  Future<void> _rotateToken(String token) async {
    final previousToken = _token;
    _token = token;
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null ||
        userId == null ||
        !supabaseCapabilities(client.auth.currentUser).hasAccount) {
      return;
    }
    if (previousToken != null && previousToken != token) {
      await client
          .from('device_tokens')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('token', previousToken);
    }
    await _save(userId, token);
  }

  void _emit(RemoteMessage message, NotificationOpenSource source) {
    if (_events.isClosed) return;
    _events.add(_eventFrom(message, source));
  }

  AppNotificationEvent _eventFrom(
    RemoteMessage message,
    NotificationOpenSource source,
  ) {
    return AppNotificationEvent(
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? 'افتح أحدعش للاطلاع على التفاصيل.',
      route: NotificationNavigation.resolve(message.data),
      source: source,
    );
  }

  @override
  Future<void> signOut() async {
    final client = _supabase;
    final token = _token;
    final userId = client?.auth.currentUser?.id;
    if (client == null || token == null || userId == null) {
      return;
    }
    await client
        .from('device_tokens')
        .update({'is_active': false})
        .eq('user_id', userId)
        .eq('token', token);
  }

  Future<void> _cancelSubscriptions() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
  }

  @override
  Future<void> dispose() async {
    await _cancelSubscriptions();
    await _events.close();
  }
}
