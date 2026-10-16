import 'package:shared_preferences/shared_preferences.dart';

/// Storage interface for Fruit Catcher high scores and statistics.
abstract interface class FruitCatcherStorage {
  Future<int> getBestScore();
  Future<void> setBestScore(int score);
  Future<void> resetAll();
}

/// SharedPreferences implementation of [FruitCatcherStorage].
class SharedFruitCatcherStorage implements FruitCatcherStorage {
  final SharedPreferences _prefs;

  const SharedFruitCatcherStorage(this._prefs);

  static const String _bestScoreKey = 'fruit_catcher_v1_best_score';

  @override
  Future<int> getBestScore() async {
    return _prefs.getInt(_bestScoreKey) ?? 0;
  }

  @override
  Future<void> setBestScore(int score) async {
    final current = await getBestScore();
    if (score > current) {
      await _prefs.setInt(_bestScoreKey, score);
    }
  }

  @override
  Future<void> resetAll() async {
    await _prefs.remove(_bestScoreKey);
  }
}
