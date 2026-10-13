import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_keys.dart';

/// Contract for general application settings.
abstract interface class AppPreferences {
  ThemeMode getThemeMode();
  ValueNotifier<ThemeMode> get themeModeNotifier;
  Future<void> setThemeMode(ThemeMode mode);

  bool isSoundEnabled();
  Future<void> setSoundEnabled(bool enabled);

  bool isHapticsEnabled();
  Future<void> setHapticsEnabled(bool enabled);
}

/// Implementation of [AppPreferences] backed by [SharedPreferences].
class SharedAppPreferences implements AppPreferences {
  final SharedPreferences _prefs;
  late final ValueNotifier<ThemeMode> _themeModeNotifier;

  SharedAppPreferences(this._prefs) {
    _themeModeNotifier = ValueNotifier<ThemeMode>(getThemeMode());
  }

  @override
  ValueNotifier<ThemeMode> get themeModeNotifier => _themeModeNotifier;

  @override
  ThemeMode getThemeMode() {
    final raw = _prefs.getString(StorageKeys.themeMode);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(StorageKeys.themeMode, value);
    _themeModeNotifier.value = mode;
  }

  @override
  bool isSoundEnabled() => _prefs.getBool(StorageKeys.soundEnabled) ?? true;

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(StorageKeys.soundEnabled, enabled);
  }

  @override
  bool isHapticsEnabled() => _prefs.getBool(StorageKeys.hapticsEnabled) ?? true;

  @override
  Future<void> setHapticsEnabled(bool enabled) async {
    await _prefs.setBool(StorageKeys.hapticsEnabled, enabled);
  }
}
