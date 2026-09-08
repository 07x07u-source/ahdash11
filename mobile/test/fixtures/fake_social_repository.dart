// Deterministic test fake. Production code must never import this file.
import 'dart:async';

import 'package:ahdash_11/features/social/data/social_repository.dart';

final class FakeSocialRepository extends SocialRepository {
  FakeSocialRepository({
    this.dashboard = const {'friends': [], 'inbox': [], 'outbox': []},
    this.searchResults = const [],
    this.blockedPlayers = const [],
  }) : super(null);

  Map<String, Object?> dashboard;
  List<Map<String, Object?>> searchResults;
  List<Map<String, Object?>> blockedPlayers;
  Object? dashboardError;
  Object? searchError;
  Object? sendError;
  Object? blockError;
  Object? unblockError;
  Completer<void>? searchGate;
  Completer<void>? sendGate;
  Completer<void>? blockGate;
  Completer<void>? unblockGate;
  int dashboardLoads = 0;
  int searches = 0;
  int sends = 0;
  int blocks = 0;
  int unblocks = 0;
  int responses = 0;
  int removals = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<Map<String, Object?>> loadFriendDashboard() async {
    dashboardLoads++;
    if (dashboardError case final error?) throw error;
    return dashboard;
  }

  @override
  Future<List<Map<String, Object?>>> searchPlayers(String query) async {
    searches++;
    if (searchError case final error?) throw error;
    await searchGate?.future;
    return searchResults;
  }

  @override
  Future<void> sendFriendRequest(String userId) async {
    sends++;
    if (sendError case final error?) throw error;
    await sendGate?.future;
  }

  @override
  Future<void> respondFriendRequest(
    String requestId, {
    required bool accept,
  }) async {
    responses++;
  }

  @override
  Future<void> removeFriend(String userId) async {
    removals++;
  }

  @override
  Future<void> blockPlayer(String userId) async {
    blocks++;
    if (blockError case final error?) throw error;
    await blockGate?.future;
    dashboard = const {'friends': [], 'inbox': [], 'outbox': []};
  }

  @override
  Future<List<Map<String, Object?>>> loadBlockedPlayers() async {
    return blockedPlayers;
  }

  @override
  Future<void> unblockPlayer(String userId) async {
    unblocks++;
    if (unblockError case final error?) throw error;
    await unblockGate?.future;
    blockedPlayers = blockedPlayers
        .where((row) => row['user_id'] != userId)
        .toList(growable: false);
  }
}
