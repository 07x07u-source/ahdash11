import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_preferences.dart';

const defaultGameStreakEmoji = '🔥';

/// Unicode emoji rendered by the active platform emoji font (Apple on iOS).
/// They are deliberately kept as text instead of image assets so the user
/// gets the native iPhone appearance and accessibility remains intact.
const gameStreakEmojiOptions = <String>[
  defaultGameStreakEmoji,
  '⚡️',
  '🌟',
  '🏆',
  '🚀',
  '🎯',
  '💎',
  '👑',
  '🎮',
  '🌈',
  '🦁',
  '🦋',
];

const _streakDaysKey = 'game_streak_days_v1';
const _streakLastEntryKey = 'game_streak_last_entry_v1';
const _streakEmojiKey = 'game_streak_emoji_v1';
const _streakCelebratedMilestoneKey = 'game_streak_celebrated_milestone_v1';

/// Returns the latest celebration checkpoint earned by [days].
///
/// The first celebrations happen at 10, 50 and 100 days. From there every
/// additional 100 days is celebrated, with a special one-year checkpoint.
int? streakMilestoneAtOrBelow(int days) {
  if (days < 10) return null;
  var milestone = 10;
  if (days >= 50) milestone = 50;
  if (days >= 100) milestone = (days ~/ 100) * 100;
  if (days >= 365 && days < 400) milestone = 365;
  return milestone;
}

final gameStreakProvider =
    AsyncNotifierProvider<GameStreakController, GameStreakState>(
      GameStreakController.new,
    );

@immutable
final class GameStreakState {
  const GameStreakState({
    this.days = 0,
    this.lastEntryDate,
    this.emoji = defaultGameStreakEmoji,
    this.celebratedMilestone = 0,
  });

  final int days;
  final String? lastEntryDate;
  final String emoji;
  final int celebratedMilestone;

  String get safeEmoji =>
      gameStreakEmojiOptions.contains(emoji) ? emoji : defaultGameStreakEmoji;

  GameStreakState copyWith({
    int? days,
    String? lastEntryDate,
    String? emoji,
    int? celebratedMilestone,
  }) {
    return GameStreakState(
      days: days ?? this.days,
      lastEntryDate: lastEntryDate ?? this.lastEntryDate,
      emoji: emoji ?? this.emoji,
      celebratedMilestone: celebratedMilestone ?? this.celebratedMilestone,
    );
  }
}

final class GameStreakController extends AsyncNotifier<GameStreakState> {
  Future<void> _pending = Future<void>.value();

  @override
  Future<GameStreakState> build() async {
    try {
      final storage = ref.read(preferenceStorageProvider);
      final days = int.tryParse('${await storage.read(_streakDaysKey)}') ?? 0;
      final lastEntry = await storage.read(_streakLastEntryKey) as String?;
      final storedEmoji = await storage.read(_streakEmojiKey) as String?;
      final celebratedMilestone =
          int.tryParse(
            '${await storage.read(_streakCelebratedMilestoneKey) ?? ''}',
          ) ??
          0;
      return GameStreakState(
        days: days.clamp(0, 9999).toInt(),
        lastEntryDate: lastEntry,
        emoji: gameStreakEmojiOptions.contains(storedEmoji)
            ? storedEmoji!
            : defaultGameStreakEmoji,
        celebratedMilestone: celebratedMilestone.clamp(0, 9999).toInt(),
      );
    } on Object {
      // A local-storage outage must never block entering a game.
      return const GameStreakState();
    }
  }

  /// Records one game entry for the local calendar day.
  ///
  /// This operation is idempotent for repeated widget mounts on the same day.
  Future<void> recordToday({DateTime? now}) {
    return _enqueue(() async {
      final current = state.value ?? await future;
      final today = _dateKey(now ?? DateTime.now());
      if (current.lastEntryDate == today) return;

      final previous = _parseDateKey(current.lastEntryDate);
      final currentDate = _parseDateKey(today)!;
      final consecutive =
          previous != null && currentDate.difference(previous).inDays == 1;
      final next = current.copyWith(
        days: consecutive ? current.days + 1 : 1,
        lastEntryDate: today,
        celebratedMilestone: consecutive ? current.celebratedMilestone : 0,
      );
      await _persist(next);
      state = AsyncData(next);
    });
  }

  /// Claims the latest earned milestone so it is celebrated once per streak.
  Future<int?> claimPendingMilestone() async {
    int? claimed;
    await _enqueue(() async {
      final current = state.value ?? await future;
      final milestone = streakMilestoneAtOrBelow(current.days);
      if (milestone == null || milestone <= current.celebratedMilestone) return;

      final next = current.copyWith(celebratedMilestone: milestone);
      try {
        await ref
            .read(preferenceStorageProvider)
            .write(_streakCelebratedMilestoneKey, '$milestone');
      } catch (_) {
        // Claim it for this session even if the local store is unavailable.
      }
      state = AsyncData(next);
      claimed = milestone;
    });
    return claimed;
  }

  Future<void> setEmoji(String emoji, {bool premium = false}) {
    if (!premium || !gameStreakEmojiOptions.contains(emoji)) {
      return Future<void>.value();
    }
    return _enqueue(() async {
      final current = state.value ?? await future;
      final next = current.copyWith(emoji: emoji);
      try {
        await ref.read(preferenceStorageProvider).write(_streakEmojiKey, emoji);
      } catch (_) {
        // Keep the selection for this session when persistence is unavailable.
      }
      state = AsyncData(next);
    });
  }

  Future<void> _persist(GameStreakState value) async {
    try {
      final storage = ref.read(preferenceStorageProvider);
      await storage.write(_streakDaysKey, '${value.days}');
      await storage.write(_streakLastEntryKey, value.lastEntryDate ?? '');
      await storage.write(_streakEmojiKey, value.safeEmoji);
      await storage.write(
        _streakCelebratedMilestoneKey,
        '${value.celebratedMilestone}',
      );
    } catch (_) {
      // Streak UI remains usable even when the platform store is unavailable.
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    return _pending = _pending.catchError((_) {}).then((_) => operation());
  }
}

String _dateKey(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

DateTime? _parseDateKey(String? value) {
  if (value == null || value.length != 10) return null;
  final parts = value.split('-').map(int.tryParse).toList(growable: false);
  if (parts.any((part) => part == null)) return null;
  return DateTime.utc(parts[0]!, parts[1]!, parts[2]!);
}
