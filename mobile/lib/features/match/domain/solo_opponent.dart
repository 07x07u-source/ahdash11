import 'dart:math';

enum SoloOpponentLevel { easy, medium, hard, legend }

final class SoloOpponentProfile {
  const SoloOpponentProfile({
    required this.correctProbability,
    required this.averageResponseTime,
    required this.responseJitter,
  });

  factory SoloOpponentProfile.forLevel(SoloOpponentLevel level) =>
      switch (level) {
        SoloOpponentLevel.easy => const SoloOpponentProfile(
          correctProbability: 0.42,
          averageResponseTime: Duration(milliseconds: 10500),
          responseJitter: Duration(milliseconds: 3500),
        ),
        SoloOpponentLevel.medium => const SoloOpponentProfile(
          correctProbability: 0.62,
          averageResponseTime: Duration(milliseconds: 8200),
          responseJitter: Duration(milliseconds: 2700),
        ),
        SoloOpponentLevel.hard => const SoloOpponentProfile(
          correctProbability: 0.78,
          averageResponseTime: Duration(milliseconds: 5700),
          responseJitter: Duration(milliseconds: 1800),
        ),
        SoloOpponentLevel.legend => const SoloOpponentProfile(
          correctProbability: 0.91,
          averageResponseTime: Duration(milliseconds: 3700),
          responseJitter: Duration(milliseconds: 1100),
        ),
      };

  final double correctProbability;
  final Duration averageResponseTime;
  final Duration responseJitter;
}

final class SoloOpponentAnswer {
  const SoloOpponentAnswer({required this.correct, required this.responseTime});

  final bool correct;
  final Duration responseTime;
}

final class SoloOpponent {
  SoloOpponent(SoloOpponentProfile profile, {int seed = 11})
    : _profile = profile,
      _random = Random(seed);

  final SoloOpponentProfile _profile;
  final Random _random;

  SoloOpponentAnswer answer() {
    final jitter = (_random.nextDouble() * 2) - 1;
    final milliseconds =
        _profile.averageResponseTime.inMilliseconds +
        (_profile.responseJitter.inMilliseconds * jitter).round();
    return SoloOpponentAnswer(
      correct: _random.nextDouble() <= _profile.correctProbability,
      responseTime: Duration(milliseconds: milliseconds.clamp(500, 30000)),
    );
  }
}
