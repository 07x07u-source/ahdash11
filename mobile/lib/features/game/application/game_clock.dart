abstract interface class GameClock {
  DateTime nowUtc();

  Stream<DateTime> ticks(Duration interval);

  Future<void> wait(Duration duration);
}

final class SystemGameClock implements GameClock {
  const SystemGameClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  Stream<DateTime> ticks(Duration interval) =>
      Stream<DateTime>.periodic(interval, (_) => nowUtc());

  @override
  Future<void> wait(Duration duration) => Future<void>.delayed(duration);
}
