import 'package:ahdash_11/core/services/feedback_service.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sound disabled removes every sound request', () {
    const settings = AppPreferences(soundEffects: false);
    for (final cue in FeedbackCue.values) {
      final plan = AppFeedbackService.planFor(cue, settings);
      expect(plan.sound, isFalse);
      expect(plan.soundType, isNull);
    }
  });

  test('haptics disabled removes every vibration request', () {
    const settings = AppPreferences(haptics: false);
    for (final cue in FeedbackCue.values) {
      expect(AppFeedbackService.planFor(cue, settings).haptic, isNull);
    }
  });

  test('urgent cues stay differentiated without heavy vibration', () {
    const settings = AppPreferences();
    expect(
      AppFeedbackService.planFor(FeedbackCue.wrong, settings).soundType,
      SystemSoundType.alert,
    );
    expect(
      AppFeedbackService.planFor(FeedbackCue.wrong, settings).haptic,
      HapticCue.light,
    );
    expect(
      AppFeedbackService.planFor(FeedbackCue.countdown, settings).haptic,
      HapticCue.selection,
    );
    expect(
      AppFeedbackService.planFor(FeedbackCue.correct, settings).haptic,
      HapticCue.medium,
    );
  });
}
