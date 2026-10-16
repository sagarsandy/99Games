import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'word_circle_level_data.dart';

/// Saved in-progress puzzle session for Word Circle.
@immutable
class WordCircleSavedSession {
  final int levelNumber;
  final List<String> foundTargetWords;
  final List<String> foundBonusWords;
  final List<String> hintedCellKeys;
  final int score;

  const WordCircleSavedSession({
    required this.levelNumber,
    required this.foundTargetWords,
    required this.foundBonusWords,
    required this.hintedCellKeys,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
    'levelNumber': levelNumber,
    'foundTargetWords': foundTargetWords,
    'foundBonusWords': foundBonusWords,
    'hintedCellKeys': hintedCellKeys,
    'score': score,
  };

  factory WordCircleSavedSession.fromJson(Map<String, dynamic> json) {
    return WordCircleSavedSession(
      levelNumber: json['levelNumber'] as int,
      foundTargetWords: List<String>.from(json['foundTargetWords'] as List),
      foundBonusWords: List<String>.from(json['foundBonusWords'] as List),
      hintedCellKeys: List<String>.from(json['hintedCellKeys'] as List),
      score: json['score'] as int,
    );
  }
}

/// Storage interface for Word Circle progress and session persistence.
abstract interface class WordCircleStorage {
  Future<int> getCurrentLevel();
  Future<void> setCurrentLevel(int levelNumber);

  Future<int> getUnlockedLevel();
  Future<void> setUnlockedLevel(int levelNumber);

  Future<Set<int>> getCompletedLevels();
  Future<void> markLevelCompleted(int levelNumber, {int? score});

  Future<int?> getBestScore(int levelNumber);

  Future<WordCircleSavedSession?> getSavedSession();
  Future<void> saveSession(WordCircleSavedSession session);
  Future<void> clearSavedSession();

  Future<void> resetAll();
}

/// SharedPreferences implementation of [WordCircleStorage].
class SharedWordCircleStorage implements WordCircleStorage {
  final SharedPreferences _prefs;

  const SharedWordCircleStorage(this._prefs);

  static const String _currentLevelKey = 'word_circle_v1_current_level';
  static const String _unlockedLevelKey = 'word_circle_v1_unlocked_level';
  static const String _completedLevelsKey = 'word_circle_v1_completed_levels';
  static const String _sessionKey = 'word_circle_v1_saved_session';

  String _bestScoreKey(int levelNumber) =>
      'word_circle_v1_lvl_${levelNumber}_best_score';

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
  Future<void> markLevelCompleted(int levelNumber, {int? score}) async {
    final completed = await getCompletedLevels();
    completed.add(levelNumber);
    await _prefs.setStringList(
      _completedLevelsKey,
      completed.map((e) => e.toString()).toList(),
    );

    if (levelNumber < WordCircleLevelData.totalLevels) {
      await setUnlockedLevel(levelNumber + 1);
    }

    if (score != null) {
      final currentBest = await getBestScore(levelNumber);
      if (currentBest == null || score > currentBest) {
        await _prefs.setInt(_bestScoreKey(levelNumber), score);
      }
    }

    final session = await getSavedSession();
    if (session != null && session.levelNumber == levelNumber) {
      await clearSavedSession();
    }
  }

  @override
  Future<int?> getBestScore(int levelNumber) async {
    return _prefs.getInt(_bestScoreKey(levelNumber));
  }

  @override
  Future<WordCircleSavedSession?> getSavedSession() async {
    final jsonStr = _prefs.getString(_sessionKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WordCircleSavedSession.fromJson(map);
    } catch (_) {
      await clearSavedSession();
      return null;
    }
  }

  @override
  Future<void> saveSession(WordCircleSavedSession session) async {
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
    for (int i = 1; i <= WordCircleLevelData.totalLevels; i++) {
      await _prefs.remove(_bestScoreKey(i));
    }
  }
}
