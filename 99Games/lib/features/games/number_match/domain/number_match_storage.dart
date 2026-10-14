import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'number_match_models.dart';

/// Contract for persisting and retrieving Number Match sessions and statistics.
abstract interface class NumberMatchStorage {
  Future<NumberMatchSavedSession?> getSavedSession();

  Future<void> saveSession(NumberMatchSavedSession session);

  Future<void> clearSavedSession();

  Future<NumberMatchStats> getStats();

  Future<void> recordGameStarted();

  Future<void> recordGameWon({required int score, required int pairsCleared});

  Future<void> updateBestScore(int score);

  Future<void> resetStats();
}

/// SharedPreferences-backed implementation of [NumberMatchStorage].
class SharedNumberMatchStorage implements NumberMatchStorage {
  final SharedPreferences _prefs;

  const SharedNumberMatchStorage(this._prefs);

  static const String _sessionKey = 'number_match_saved_session_v1';
  static const String _statsStartedKey = 'number_match_stats_v1_started';
  static const String _statsWonKey = 'number_match_stats_v1_won';
  static const String _statsBestScoreKey = 'number_match_stats_v1_best_score';
  static const String _statsTotalPairsKey = 'number_match_stats_v1_total_pairs';

  @override
  Future<NumberMatchSavedSession?> getSavedSession() async {
    try {
      final raw = _prefs.getString(_sessionKey);
      if (raw == null || raw.isEmpty) return null;
      return NumberMatchSavedSession.fromJson(raw);
    } catch (e) {
      debugPrint('Failed to deserialize saved Number Match session: $e');
      await clearSavedSession();
      return null;
    }
  }

  @override
  Future<void> saveSession(NumberMatchSavedSession session) async {
    try {
      final json = session.toJson();
      await _prefs.setString(_sessionKey, json);
    } catch (e) {
      debugPrint('Failed to save Number Match session: $e');
    }
  }

  @override
  Future<void> clearSavedSession() async {
    await _prefs.remove(_sessionKey);
  }

  @override
  Future<NumberMatchStats> getStats() async {
    final started = _prefs.getInt(_statsStartedKey) ?? 0;
    final won = _prefs.getInt(_statsWonKey) ?? 0;
    final bestScore = _prefs.getInt(_statsBestScoreKey) ?? 0;
    final totalPairs = _prefs.getInt(_statsTotalPairsKey) ?? 0;

    return NumberMatchStats(
      gamesStarted: started,
      gamesWon: won,
      bestScore: bestScore,
      totalPairsCleared: totalPairs,
    );
  }

  @override
  Future<void> recordGameStarted() async {
    final current = await getStats();
    await _prefs.setInt(_statsStartedKey, current.gamesStarted + 1);
  }

  @override
  Future<void> recordGameWon({
    required int score,
    required int pairsCleared,
  }) async {
    final current = await getStats();
    final newWon = current.gamesWon + 1;
    final newBestScore = score > current.bestScore ? score : current.bestScore;
    final newTotalPairs = current.totalPairsCleared + pairsCleared;

    await _prefs.setInt(_statsWonKey, newWon);
    await _prefs.setInt(_statsBestScoreKey, newBestScore);
    await _prefs.setInt(_statsTotalPairsKey, newTotalPairs);
  }

  @override
  Future<void> updateBestScore(int score) async {
    final current = await getStats();
    if (score > current.bestScore) {
      await _prefs.setInt(_statsBestScoreKey, score);
    }
  }

  @override
  Future<void> resetStats() async {
    await _prefs.remove(_statsStartedKey);
    await _prefs.remove(_statsWonKey);
    await _prefs.remove(_statsBestScoreKey);
    await _prefs.remove(_statsTotalPairsKey);
  }
}
