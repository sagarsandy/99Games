import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emoji_connect_models.dart';

/// Contract for persisting Emoji Connect preferences, progress, and saved sessions.
abstract interface class EmojiConnectStorage {
  Future<EmojiConnectDifficulty> getSelectedDifficulty();
  Future<void> setSelectedDifficulty(EmojiConnectDifficulty difficulty);

  Future<int> getCurrentLevel(EmojiConnectDifficulty difficulty);
  Future<void> setCurrentLevel(EmojiConnectDifficulty difficulty, int levelId);

  Future<int> getUnlockedLevel(EmojiConnectDifficulty difficulty);
  Future<void> setUnlockedLevel(EmojiConnectDifficulty difficulty, int levelId);

  Future<Set<int>> getCompletedLevels(EmojiConnectDifficulty difficulty);
  Future<void> markLevelCompleted(
    EmojiConnectDifficulty difficulty,
    int levelId, {
    int? timeSeconds,
  });

  Future<int?> getBestTime(EmojiConnectDifficulty difficulty, int levelId);

  Future<EmojiConnectSavedSession?> getSavedSession();
  Future<void> saveSession(EmojiConnectSavedSession session);
  Future<void> clearSavedSession();

  Future<void> resetAll();
}

/// SharedPreferences-backed implementation of [EmojiConnectStorage].
class SharedEmojiConnectStorage implements EmojiConnectStorage {
  final SharedPreferences _prefs;

  const SharedEmojiConnectStorage(this._prefs);

  static const String _diffKey = 'emoji_connect_v1_selected_difficulty';
  static const String _sessionKey = 'emoji_connect_v1_saved_session';

  String _currentLevelKey(EmojiConnectDifficulty diff) =>
      'emoji_connect_v1_${diff.name}_current_level';

  String _unlockedLevelKey(EmojiConnectDifficulty diff) =>
      'emoji_connect_v1_${diff.name}_unlocked_level';

  String _completedLevelsKey(EmojiConnectDifficulty diff) =>
      'emoji_connect_v1_${diff.name}_completed_levels';

  String _bestTimeKey(EmojiConnectDifficulty diff, int levelId) =>
      'emoji_connect_v1_${diff.name}_lvl_${levelId}_best_time';

  @override
  Future<EmojiConnectDifficulty> getSelectedDifficulty() async {
    final name = _prefs.getString(_diffKey);
    if (name == null) return EmojiConnectDifficulty.easy;
    return EmojiConnectDifficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => EmojiConnectDifficulty.easy,
    );
  }

  @override
  Future<void> setSelectedDifficulty(EmojiConnectDifficulty difficulty) async {
    await _prefs.setString(_diffKey, difficulty.name);
  }

  @override
  Future<int> getCurrentLevel(EmojiConnectDifficulty difficulty) async {
    return _prefs.getInt(_currentLevelKey(difficulty)) ?? 1;
  }

  @override
  Future<void> setCurrentLevel(
    EmojiConnectDifficulty difficulty,
    int levelId,
  ) async {
    await _prefs.setInt(_currentLevelKey(difficulty), levelId);
  }

  @override
  Future<int> getUnlockedLevel(EmojiConnectDifficulty difficulty) async {
    // Level 1 is always unlocked by default
    return _prefs.getInt(_unlockedLevelKey(difficulty)) ?? 1;
  }

  @override
  Future<void> setUnlockedLevel(
    EmojiConnectDifficulty difficulty,
    int levelId,
  ) async {
    final current = await getUnlockedLevel(difficulty);
    if (levelId > current) {
      await _prefs.setInt(_unlockedLevelKey(difficulty), levelId);
    }
  }

  @override
  Future<Set<int>> getCompletedLevels(EmojiConnectDifficulty difficulty) async {
    final list = _prefs.getStringList(_completedLevelsKey(difficulty));
    if (list == null) return {};
    return list.map(int.tryParse).whereType<int>().toSet();
  }

  @override
  Future<void> markLevelCompleted(
    EmojiConnectDifficulty difficulty,
    int levelId, {
    int? timeSeconds,
  }) async {
    final completed = await getCompletedLevels(difficulty);
    completed.add(levelId);
    await _prefs.setStringList(
      _completedLevelsKey(difficulty),
      completed.map((e) => e.toString()).toList(),
    );

    // Unlock next level
    await setUnlockedLevel(difficulty, levelId + 1);

    // Record best time
    if (timeSeconds != null) {
      final currentBest = await getBestTime(difficulty, levelId);
      if (currentBest == null || timeSeconds < currentBest) {
        await _prefs.setInt(_bestTimeKey(difficulty, levelId), timeSeconds);
      }
    }
  }

  @override
  Future<int?> getBestTime(
    EmojiConnectDifficulty difficulty,
    int levelId,
  ) async {
    return _prefs.getInt(_bestTimeKey(difficulty, levelId));
  }

  @override
  Future<EmojiConnectSavedSession?> getSavedSession() async {
    try {
      final raw = _prefs.getString(_sessionKey);
      if (raw == null || raw.isEmpty) return null;
      return EmojiConnectSavedSession.fromJson(raw);
    } catch (e) {
      debugPrint('Failed to deserialize saved Emoji Connect session: $e');
      await clearSavedSession();
      return null;
    }
  }

  @override
  Future<void> saveSession(EmojiConnectSavedSession session) async {
    try {
      await _prefs.setString(_sessionKey, session.toJson());
    } catch (e) {
      debugPrint('Failed to save Emoji Connect session: $e');
    }
  }

  @override
  Future<void> clearSavedSession() async {
    await _prefs.remove(_sessionKey);
  }

  @override
  Future<void> resetAll() async {
    for (final diff in EmojiConnectDifficulty.values) {
      await _prefs.remove(_currentLevelKey(diff));
      await _prefs.remove(_unlockedLevelKey(diff));
      await _prefs.remove(_completedLevelsKey(diff));
      for (int i = 1; i <= 20; i++) {
        await _prefs.remove(_bestTimeKey(diff, i));
      }
    }
    await _prefs.remove(_diffKey);
    await clearSavedSession();
  }
}
