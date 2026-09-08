import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_preferences.dart';

enum FeedbackCue {
  tap,
  navigation,
  selection,
  correct,
  wrong,
  countdown,
  ready,
  copy,
  reward,
  win,
  loss,
}

enum HapticCue { selection, light, medium }

final class FeedbackPlan {
  const FeedbackPlan({required this.sound, this.soundType, this.haptic});

  final bool sound;
  final SystemSoundType? soundType;
  final HapticCue? haptic;
}

final feedbackServiceProvider = Provider<AppFeedbackService>(
  AppFeedbackService.new,
);

final class AppFeedbackService {
  AppFeedbackService(this.ref);

  final Ref ref;

  static FeedbackPlan planFor(FeedbackCue cue, AppPreferences settings) {
    return FeedbackPlan(
      sound: settings.soundEffects,
      soundType: settings.soundEffects
          ? switch (cue) {
              FeedbackCue.wrong || FeedbackCue.loss => SystemSoundType.alert,
              _ => SystemSoundType.click,
            }
          : null,
      haptic: settings.haptics
          ? switch (cue) {
              FeedbackCue.tap ||
              FeedbackCue.navigation ||
              FeedbackCue.selection ||
              FeedbackCue.countdown => HapticCue.selection,
              FeedbackCue.wrong || FeedbackCue.loss => HapticCue.light,
              FeedbackCue.correct ||
              FeedbackCue.ready ||
              FeedbackCue.copy ||
              FeedbackCue.reward ||
              FeedbackCue.win => HapticCue.medium,
            }
          : null,
    );
  }

  Future<void> play(FeedbackCue cue) async {
    final settings =
        ref.read(appPreferencesProvider).value ?? const AppPreferences();
    final plan = planFor(cue, settings);
    if (plan.soundType case final soundType?) {
      unawaited(SystemSound.play(soundType));
    }
    await switch (plan.haptic) {
      HapticCue.selection => HapticFeedback.selectionClick(),
      HapticCue.light => HapticFeedback.lightImpact(),
      HapticCue.medium => HapticFeedback.mediumImpact(),
      null => Future<void>.value(),
    };
  }
}
