import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'worm_escape_level_data.dart';
import 'worm_escape_models.dart';

/// Saved in-progress session data for Worm Escape.
@immutable
class WormEscapeSavedSession {
  final String levelId;
  final WormEscapeDifficulty difficulty;
  final int levelNumber;
  final List<String> escapedWormIds;
  final int movesCount;

  const WormEscapeSavedSession({
    required this.levelId,
    required this.difficulty,
    required this.levelNumber,
    required this.escapedWormIds,
    required this.movesCount,
  });

  Map<String, dynamic> toJson() => {
    'levelId': levelId,
    'difficulty': difficulty.name,
    'levelNumber': levelNumber,
    'escapedWormIds': escapedWormIds,
    'movesCount': movesCount,
  };

  factory WormEscapeSavedSession.fromJson(Map<String, dynamic> json) =>
      WormEscapeSavedSession(
        levelId: json['levelId'] as String,
        difficulty: WormEscapeDifficulty.values.byName(
          json['difficulty'] as String,
        ),
        levelNumber: json['levelNumber'] as int,
        escapedWormIds: (json['escapedWormIds'] as List<dynamic>)
            .cast<String>(),
        movesCount: json['movesCount'] as int,
      );
}

/// Storage interface for Worm Escape game persistence.
abstract interface class WormEscapeStorage {
  Future<WormEscapeDifficulty> getSelectedDifficulty();
  Future<void> setSelectedDifficulty(WormEscapeDifficulty difficulty);

  Future<int> getCurrentLevel(WormEscapeDifficulty difficulty);
  Future<void> setCurrentLevel(
    WormEscapeDifficulty difficulty,
    int levelNumber,
  );

  Future<int> getUnlockedLevel(WormEscapeDifficulty difficulty);
  Future<void> setUnlockedLevel(
    WormEscapeDifficulty difficulty,
    int levelNumber,
  );

  Future<Set<int>> getCompletedLevels(WormEscapeDifficulty difficulty);
  Future<void> markLevelCompleted(
    WormEscapeDifficulty difficulty,
    int levelNumber, {
    int? movesCount,
  });

  Future<int?> getBestMoves(WormEscapeDifficulty difficulty, int levelNumber);

  Future<WormEscapeSavedSession?> getSavedSession();
  Future<void> saveSession(WormEscapeSavedSession session);
  Future<void> clearSavedSession();

  Future<void> resetAll();
}

/// SharedPreferences implementation of [WormEscapeStorage].
class SharedWormEscapeStorage implements WormEscapeStorage {
  final SharedPreferences _prefs;

  const SharedWormEscapeStorage(this._prefs);

  static const String _diffKey = 'worm_escape_v1_selected_difficulty';
  static const String _sessionKey = 'worm_escape_v1_saved_session';

  String _currentLevelKey(WormEscapeDifficulty diff) =>
      'worm_escape_v1_${diff.name}_current_level';

  String _unlockedLevelKey(WormEscapeDifficulty diff) =>
      'worm_escape_v1_${diff.name}_unlocked_level';

  String _completedLevelsKey(WormEscapeDifficulty diff) =>
      'worm_escape_v1_${diff.name}_completed_levels';

  String _bestMovesKey(WormEscapeDifficulty diff, int levelNumber) =>
      'worm_escape_v1_${diff.name}_lvl_${levelNumber}_best_moves';

  @override
  Future<WormEscapeDifficulty> getSelectedDifficulty() async {
    final name = _prefs.getString(_diffKey);
    if (name == null) return WormEscapeDifficulty.easy;
    return WormEscapeDifficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => WormEscapeDifficulty.easy,
    );
  }

  @override
  Future<void> setSelectedDifficulty(WormEscapeDifficulty difficulty) async {
    await _prefs.setString(_diffKey, difficulty.name);
  }

  @override
  Future<int> getCurrentLevel(WormEscapeDifficulty difficulty) async {
    return _prefs.getInt(_currentLevelKey(difficulty)) ?? 1;
  }

  @override
  Future<void> setCurrentLevel(
    WormEscapeDifficulty difficulty,
    int levelNumber,
  ) async {
    await _prefs.setInt(_currentLevelKey(difficulty), levelNumber);
  }

  @override
  Future<int> getUnlockedLevel(WormEscapeDifficulty difficulty) async {
    return _prefs.getInt(_unlockedLevelKey(difficulty)) ?? 1;
  }

  @override
  Future<void> setUnlockedLevel(
    WormEscapeDifficulty difficulty,
    int levelNumber,
  ) async {
    final current = await getUnlockedLevel(difficulty);
    if (levelNumber > current) {
      await _prefs.setInt(_unlockedLevelKey(difficulty), levelNumber);
    }
  }

  @override
  Future<Set<int>> getCompletedLevels(WormEscapeDifficulty difficulty) async {
    final list = _prefs.getStringList(_completedLevelsKey(difficulty));
    if (list == null) return {};
    return list.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
  }

  @override
  Future<void> markLevelCompleted(
    WormEscapeDifficulty difficulty,
    int levelNumber, {
    int? movesCount,
  }) async {
    final completed = await getCompletedLevels(difficulty);
    completed.add(levelNumber);
    await _prefs.setStringList(
      _completedLevelsKey(difficulty),
      completed.map((e) => e.toString()).toList(),
    );

    // Automatically unlock next level
    await setUnlockedLevel(difficulty, levelNumber + 1);

    // Save best moves
    if (movesCount != null && movesCount > 0) {
      final best = await getBestMoves(difficulty, levelNumber);
      if (best == null || movesCount < best) {
        await _prefs.setInt(_bestMovesKey(difficulty, levelNumber), movesCount);
      }
    }
  }

  @override
  Future<int?> getBestMoves(
    WormEscapeDifficulty difficulty,
    int levelNumber,
  ) async {
    return _prefs.getInt(_bestMovesKey(difficulty, levelNumber));
  }

  @override
  Future<WormEscapeSavedSession?> getSavedSession() async {
    final jsonStr = _prefs.getString(_sessionKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WormEscapeSavedSession.fromJson(map);
    } catch (e) {
      debugPrint('Failed to deserialize saved Worm Escape session: $e');
      return null;
    }
  }

  @override
  Future<void> saveSession(WormEscapeSavedSession session) async {
    final jsonStr = jsonEncode(session.toJson());
    await _prefs.setString(_sessionKey, jsonStr);
  }

  @override
  Future<void> clearSavedSession() async {
    await _prefs.remove(_sessionKey);
  }

  @override
  Future<void> resetAll() async {
    await _prefs.remove(_diffKey);
    await _prefs.remove(_sessionKey);
    for (final diff in WormEscapeDifficulty.values) {
      await _prefs.remove(_currentLevelKey(diff));
      await _prefs.remove(_unlockedLevelKey(diff));
      await _prefs.remove(_completedLevelsKey(diff));
      final count = WormEscapeLevelData.getLevelCount(diff);
      for (int i = 1; i <= count; i++) {
        await _prefs.remove(_bestMovesKey(diff, i));
      }
    }
  }
}
