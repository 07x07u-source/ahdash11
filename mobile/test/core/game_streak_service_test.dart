import 'package:ahdash_11/core/services/game_streak_service.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records one entry per day and resets after a missed day', () async {
    final storage = _MemoryPreferenceStorage();
    final container = ProviderContainer(
      overrides: [preferenceStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final controller = container.read(gameStreakProvider.notifier);
    await container.read(gameStreakProvider.future);

    await controller.recordToday(now: DateTime(2026, 9, 29, 9));
    expect(container.read(gameStreakProvider).value?.days, 1);

    await controller.recordToday(now: DateTime(2026, 9, 29, 21));
    expect(container.read(gameStreakProvider).value?.days, 1);

    await controller.recordToday(now: DateTime(2026, 9, 30, 9));
    expect(container.read(gameStreakProvider).value?.days, 2);

    await controller.recordToday(now: DateTime(2026, 10, 2, 9));
    expect(container.read(gameStreakProvider).value?.days, 1);
  });

  test('premium emoji choices are validated and persisted', () async {
    final storage = _MemoryPreferenceStorage();
    final container = ProviderContainer(
      overrides: [preferenceStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final controller = container.read(gameStreakProvider.notifier);
    await container.read(gameStreakProvider.future);
    await controller.setEmoji('🚀', premium: true);
    expect(container.read(gameStreakProvider).value?.safeEmoji, '🚀');

    await controller.setEmoji('not-an-emoji', premium: true);
    expect(container.read(gameStreakProvider).value?.safeEmoji, '🚀');
    expect(storage.values['game_streak_emoji_v1'], '🚀');

    await controller.setEmoji('🏆');
    expect(container.read(gameStreakProvider).value?.safeEmoji, '🚀');
  });

  test('claims each checkpoint once per streak', () async {
    final storage = _MemoryPreferenceStorage();
    final container = ProviderContainer(
      overrides: [preferenceStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final controller = container.read(gameStreakProvider.notifier);
    await container.read(gameStreakProvider.future);

    for (var day = 1; day <= 9; day++) {
      await controller.recordToday(now: DateTime(2026, 1, day));
    }
    expect(await controller.claimPendingMilestone(), isNull);

    await controller.recordToday(now: DateTime(2026, 1, 10));
    expect(await controller.claimPendingMilestone(), 10);
    expect(await controller.claimPendingMilestone(), isNull);

    for (var day = 11; day <= 50; day++) {
      await controller.recordToday(
        now: DateTime(2026, 1, 1).add(Duration(days: day - 1)),
      );
    }
    expect(await controller.claimPendingMilestone(), 50);
    expect(await controller.claimPendingMilestone(), isNull);

    for (var day = 51; day <= 100; day++) {
      await controller.recordToday(
        now: DateTime(2026, 1, 1).add(Duration(days: day - 1)),
      );
    }
    expect(await controller.claimPendingMilestone(), 100);

    await controller.recordToday(now: DateTime(2026, 4, 1));
    expect(container.read(gameStreakProvider).value?.days, 1);
    expect(await controller.claimPendingMilestone(), isNull);
  });

  test('milestone helper catches up to the latest earned checkpoint', () {
    expect(streakMilestoneAtOrBelow(9), isNull);
    expect(streakMilestoneAtOrBelow(10), 10);
    expect(streakMilestoneAtOrBelow(57), 50);
    expect(streakMilestoneAtOrBelow(100), 100);
    expect(streakMilestoneAtOrBelow(365), 365);
    expect(streakMilestoneAtOrBelow(401), 400);
  });
}

final class _MemoryPreferenceStorage extends PreferenceStorage {
  final values = <String, Object?>{};

  @override
  Future<Object?> read(String key) async => values[key];

  @override
  Future<void> write(String key, Object value) async {
    values[key] = value;
  }
}
