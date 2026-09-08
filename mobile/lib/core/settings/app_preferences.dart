import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

enum Player11Variant {
  male,
  female;

  String get labelAr => switch (this) {
    Player11Variant.male => 'لاعب 11',
    Player11Variant.female => 'لاعبة 11',
  };

  String get assetPath => switch (this) {
    Player11Variant.male => 'assets/player11/player11-male-card.png',
    Player11Variant.female => 'assets/player11/player11-female-card.png',
  };
}

@immutable
final class AppPreferences {
  const AppPreferences({
    this.theme = AppThemePreference.system,
    this.soundEffects = true,
    this.haptics = true,
    this.reducedMotion = false,
    this.player11Variant = Player11Variant.male,
    this.onboardingCompleted = false,
  });

  final AppThemePreference theme;
  final bool soundEffects;
  final bool haptics;
  final bool reducedMotion;
  final Player11Variant player11Variant;
  final bool onboardingCompleted;

  ThemeMode get themeMode => switch (theme) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  AppPreferences copyWith({
    AppThemePreference? theme,
    bool? soundEffects,
    bool? haptics,
    bool? reducedMotion,
    Player11Variant? player11Variant,
    bool? onboardingCompleted,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      soundEffects: soundEffects ?? this.soundEffects,
      haptics: haptics ?? this.haptics,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      player11Variant: player11Variant ?? this.player11Variant,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );

final preferenceStorageProvider = Provider<PreferenceStorage>(
  (ref) => const PreferenceStorage(),
);

/// Existing small preference keys only; no account/game/entitlement data.
class PreferenceStorage {
  const PreferenceStorage();
  Future<Object?> read(String key) async =>
      (await SharedPreferences.getInstance()).get(key);
  Future<void> write(String key, Object value) async {
    final storage = await SharedPreferences.getInstance();
    final saved = value is bool
        ? await storage.setBool(key, value)
        : await storage.setString(key, value as String);
    if (!saved) throw StateError('Preference unavailable');
  }
}

final class AppPreferencesController extends AsyncNotifier<AppPreferences> {
  Future<void> _pending = Future<void>.value();
  @override
  Future<AppPreferences> build() async {
    try {
      final storage = ref.watch(preferenceStorageProvider);
      final theme = await storage.read('appearance_theme');
      final variant = await storage.read('player11_variant');
      return AppPreferences(
        theme: AppThemePreference.values.firstWhere(
          (v) => v.name == theme,
          orElse: () => AppThemePreference.system,
        ),
        soundEffects:
            (await storage.read('sound_effects_enabled')) as bool? ?? true,
        haptics: (await storage.read('haptics_enabled')) as bool? ?? true,
        reducedMotion:
            (await storage.read('reduced_motion_enabled')) as bool? ?? false,
        player11Variant: Player11Variant.values.firstWhere(
          (v) => v.name == variant,
          orElse: () => Player11Variant.male,
        ),
        onboardingCompleted:
            (await storage.read('onboarding_complete')) as bool? ?? false,
      );
    } on Object {
      return const AppPreferences();
    }
  }

  Future<void> _save(
    String key,
    Object value,
    AppPreferences Function(AppPreferences) update,
  ) {
    return _pending = _pending.catchError((_) {}).then((_) async {
      await ref.read(preferenceStorageProvider).write(key, value);
      state = AsyncData(update(state.value ?? const AppPreferences()));
    });
  }

  Future<void> setTheme(AppThemePreference value) =>
      _save('appearance_theme', value.name, (v) => v.copyWith(theme: value));
  Future<void> setSoundEffects(bool value) => _save(
    'sound_effects_enabled',
    value,
    (v) => v.copyWith(soundEffects: value),
  );
  Future<void> setHaptics(bool value) =>
      _save('haptics_enabled', value, (v) => v.copyWith(haptics: value));
  Future<void> setReducedMotion(bool value) => _save(
    'reduced_motion_enabled',
    value,
    (v) => v.copyWith(reducedMotion: value),
  );
  Future<void> setPlayer11Variant(Player11Variant value) => _save(
    'player11_variant',
    value.name,
    (v) => v.copyWith(player11Variant: value),
  );
  Future<void> completeOnboarding() => _save(
    'onboarding_complete',
    true,
    (v) => v.copyWith(onboardingCompleted: true),
  );
}
