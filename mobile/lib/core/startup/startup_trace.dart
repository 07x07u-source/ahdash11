import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

@immutable
final class StartupCheckpoint {
  const StartupCheckpoint(this.name, this.elapsed);

  final String name;
  final Duration elapsed;
}

/// Lightweight startup markers visible in DevTools without collecting user data.
abstract final class StartupTrace {
  static final Stopwatch _clock = Stopwatch()..start();
  static final List<StartupCheckpoint> _checkpoints = <StartupCheckpoint>[];

  static void mark(String name) {
    final elapsed = _clock.elapsed;
    _checkpoints.add(StartupCheckpoint(name, elapsed));
    developer.Timeline.instantSync(
      'ahdash.startup.$name',
      arguments: <String, Object>{'elapsed_ms': elapsed.inMilliseconds},
    );
    if (kDebugMode) {
      debugPrint('[startup +${elapsed.inMilliseconds}ms] $name');
    }
  }

  @visibleForTesting
  static List<StartupCheckpoint> get checkpoints =>
      List<StartupCheckpoint>.unmodifiable(_checkpoints);
}
