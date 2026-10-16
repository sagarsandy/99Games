import 'package:shared_preferences/shared_preferences.dart';

/// Storage interface for Memory Match high scores and level progression.
abstract interface class MemoryMatchStorage {
  Future<int> getHighestUnlockedLevel();
  Future<void> setHighestUnlockedLevel(int level);

  Future<int> getBestScore(int level);
  Future<void> setBestScore(int level, int score);

  Future<int?> getBestMoves(int level);
  Future<void> setBestMoves(int level, int moves);

  Future<int?> getBestTime(int level);
  Future<void> setBestTime(int level, int seconds);

  Future<int> getTotalBestScore();
  Future<void> resetAll();
}

/// SharedPreferences implementation of [MemoryMatchStorage].
class SharedMemoryMatchStorage implements MemoryMatchStorage {
  final SharedPreferences _prefs;

  const SharedMemoryMatchStorage(this._prefs);

  static const String _unlockedLevelKey = 'memory_match_v1_unlocked_level';
  static const String _scorePrefix = 'memory_match_v1_score_lvl_';
  static const String _movesPrefix = 'memory_match_v1_moves_lvl_';
  static const String _timePrefix = 'memory_match_v1_time_lvl_';

  @override
  Future<int> getHighestUnlockedLevel() async {
    final lvl = _prefs.getInt(_unlockedLevelKey) ?? 1;
    return lvl.clamp(1, 20);
  }

  @override
  Future<void> setHighestUnlockedLevel(int level) async {
    final current = await getHighestUnlockedLevel();
    if (level > current) {
      await _prefs.setInt(_unlockedLevelKey, level.clamp(1, 20));
    }
  }

  @override
  Future<int> getBestScore(int level) async {
    return _prefs.getInt('$_scorePrefix$level') ?? 0;
  }

  @override
  Future<void> setBestScore(int level, int score) async {
    final current = await getBestScore(level);
    if (score > current) {
      await _prefs.setInt('$_scorePrefix$level', score);
    }
  }

  @override
  Future<int?> getBestMoves(int level) async {
    return _prefs.getInt('$_movesPrefix$level');
  }

  @override
  Future<void> setBestMoves(int level, int moves) async {
    final current = await getBestMoves(level);
    if (current == null || moves < current) {
      await _prefs.setInt('$_movesPrefix$level', moves);
    }
  }

  @override
  Future<int?> getBestTime(int level) async {
    return _prefs.getInt('$_timePrefix$level');
  }

  @override
  Future<void> setBestTime(int level, int seconds) async {
    final current = await getBestTime(level);
    if (current == null || seconds < current) {
      await _prefs.setInt('$_timePrefix$level', seconds);
    }
  }

  @override
  Future<int> getTotalBestScore() async {
    int total = 0;
    for (int lvl = 1; lvl <= 20; lvl++) {
      total += await getBestScore(lvl);
    }
    return total;
  }

  @override
  Future<void> resetAll() async {
    await _prefs.remove(_unlockedLevelKey);
    for (int lvl = 1; lvl <= 20; lvl++) {
      await _prefs.remove('$_scorePrefix$lvl');
      await _prefs.remove('$_movesPrefix$lvl');
      await _prefs.remove('$_timePrefix$lvl');
    }
  }
}
