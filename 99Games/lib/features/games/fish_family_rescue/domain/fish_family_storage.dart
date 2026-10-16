import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fish_family_level_data.dart';
import 'fish_family_models.dart';

/// Saved in-progress session for Fish Family Rescue.
@immutable
class FishFamilySavedSession {
  final int levelNumber;
  final int movesCount;
  final List<FishTank> tanks;

  const FishFamilySavedSession({
    required this.levelNumber,
    required this.movesCount,
    required this.tanks,
  });

  Map<String, dynamic> toJson() => {
    'levelNumber': levelNumber,
    'movesCount': movesCount,
    'tanks': tanks.map((t) => t.toJson()).toList(),
  };

  factory FishFamilySavedSession.fromJson(Map<String, dynamic> json) {
    return FishFamilySavedSession(
      levelNumber: json['levelNumber'] as int,
      movesCount: json['movesCount'] as int,
      tanks: (json['tanks'] as List<dynamic>)
          .map((t) => FishTank.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Storage interface for Fish Family Rescue persistence.
abstract interface class FishFamilyStorage {
  Future<int> getCurrentLevel();
  Future<void> setCurrentLevel(int levelNumber);

  Future<int> getUnlockedLevel();
  Future<void> setUnlockedLevel(int levelNumber);

  Future<Set<int>> getCompletedLevels();
  Future<void> markLevelCompleted(int levelNumber, {int? movesCount});

  Future<int?> getBestMoves(int levelNumber);

  Future<FishFamilySavedSession?> getSavedSession();
  Future<void> saveSession(FishFamilySavedSession session);
  Future<void> clearSavedSession();

  Future<void> resetAll();
}

/// SharedPreferences implementation of [FishFamilyStorage].
class SharedFishFamilyStorage implements FishFamilyStorage {
  final SharedPreferences _prefs;

  const SharedFishFamilyStorage(this._prefs);

  static const String _currentLevelKey = 'fish_family_v1_current_level';
  static const String _unlockedLevelKey = 'fish_family_v1_unlocked_level';
  static const String _completedLevelsKey = 'fish_family_v1_completed_levels';
  static const String _sessionKey = 'fish_family_v1_saved_session';

  String _bestMovesKey(int levelNumber) =>
      'fish_family_v1_lvl_${levelNumber}_best_moves';

  @override
  Future<int> getCurrentLevel() async {
    return _prefs.getInt(_currentLevelKey) ?? 1;
  }

  @override
  Future<void> setCurrentLevel(int levelNumber) async {
    await _prefs.setInt(_currentLevelKey, levelNumber);
  }

  @override
  Future<int> getUnlockedLevel() async {
    return _prefs.getInt(_unlockedLevelKey) ?? 1;
  }

  @override
  Future<void> setUnlockedLevel(int levelNumber) async {
    final current = await getUnlockedLevel();
    if (levelNumber > current) {
      await _prefs.setInt(_unlockedLevelKey, levelNumber);
    }
  }

  @override
  Future<Set<int>> getCompletedLevels() async {
    final list = _prefs.getStringList(_completedLevelsKey);
    if (list == null) return <int>{};
    return list.map((s) => int.tryParse(s) ?? 0).where((n) => n > 0).toSet();
  }

  @override
  Future<void> markLevelCompleted(int levelNumber, {int? movesCount}) async {
    final completed = await getCompletedLevels();
    completed.add(levelNumber);
    await _prefs.setStringList(
      _completedLevelsKey,
      completed.map((e) => e.toString()).toList(),
    );

    // Automatically unlock the next level
    if (levelNumber < FishFamilyLevelData.totalLevels) {
      await setUnlockedLevel(levelNumber + 1);
    }

    if (movesCount != null) {
      final currentBest = await getBestMoves(levelNumber);
      if (currentBest == null || movesCount < currentBest) {
        await _prefs.setInt(_bestMovesKey(levelNumber), movesCount);
      }
    }

    // Completed level clears active session for that level
    final session = await getSavedSession();
    if (session != null && session.levelNumber == levelNumber) {
      await clearSavedSession();
    }
  }

  @override
  Future<int?> getBestMoves(int levelNumber) async {
    return _prefs.getInt(_bestMovesKey(levelNumber));
  }

  @override
  Future<FishFamilySavedSession?> getSavedSession() async {
    final jsonStr = _prefs.getString(_sessionKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return FishFamilySavedSession.fromJson(map);
    } catch (_) {
      await clearSavedSession();
      return null;
    }
  }

  @override
  Future<void> saveSession(FishFamilySavedSession session) async {
    final jsonStr = jsonEncode(session.toJson());
    await _prefs.setString(_sessionKey, jsonStr);
  }

  @override
  Future<void> clearSavedSession() async {
    await _prefs.remove(_sessionKey);
  }

  @override
  Future<void> resetAll() async {
    await _prefs.remove(_currentLevelKey);
    await _prefs.remove(_unlockedLevelKey);
    await _prefs.remove(_completedLevelsKey);
    await _prefs.remove(_sessionKey);
    for (int i = 1; i <= FishFamilyLevelData.totalLevels; i++) {
      await _prefs.remove(_bestMovesKey(i));
    }
  }
}
