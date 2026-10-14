import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sudoku_models.dart';

/// Contract for persisting and retrieving Sudoku sessions and statistics.
abstract interface class SudokuStorage {
  Future<SudokuSavedSession?> getSavedSession();

  Future<void> saveSession(SudokuSavedSession session);

  Future<void> clearSavedSession();

  Future<SudokuStats> getStats(SudokuDifficulty difficulty);

  Future<void> recordGameResult({
    required SudokuDifficulty difficulty,
    required bool won,
    int? timeInSeconds,
  });

  Future<void> resetStats(SudokuDifficulty difficulty);
}

/// SharedPreferences-backed implementation of [SudokuStorage].
class SharedSudokuStorage implements SudokuStorage {
  final SharedPreferences _prefs;

  const SharedSudokuStorage(this._prefs);

  static const String _sessionKey = 'sudoku_saved_session_v1';

  String _statsKey(SudokuDifficulty difficulty, String metric) =>
      'sudoku_stats_${difficulty.name}_$metric';

  @override
  Future<SudokuSavedSession?> getSavedSession() async {
    try {
      final raw = _prefs.getString(_sessionKey);
      if (raw == null || raw.isEmpty) return null;
      return SudokuSavedSession.fromJson(raw);
    } catch (e) {
      debugPrint('Failed to deserialize saved Sudoku session: $e');
      // If corrupted, clean up to prevent recurring crashes
      await clearSavedSession();
      return null;
    }
  }

  @override
  Future<void> saveSession(SudokuSavedSession session) async {
    try {
      final json = session.toJson();
      await _prefs.setString(_sessionKey, json);
    } catch (e) {
      debugPrint('Failed to save Sudoku session: $e');
    }
  }

  @override
  Future<void> clearSavedSession() async {
    await _prefs.remove(_sessionKey);
  }

  @override
  Future<SudokuStats> getStats(SudokuDifficulty difficulty) async {
    final completed = _prefs.getInt(_statsKey(difficulty, 'completed')) ?? 0;
    final won = _prefs.getInt(_statsKey(difficulty, 'won')) ?? 0;
    final lost = _prefs.getInt(_statsKey(difficulty, 'lost')) ?? 0;
    final bestTime = _prefs.getInt(_statsKey(difficulty, 'best_time'));

    return SudokuStats(
      gamesCompleted: completed,
      gamesWon: won,
      gamesLost: lost,
      bestTimeSeconds: bestTime,
    );
  }

  @override
  Future<void> recordGameResult({
    required SudokuDifficulty difficulty,
    required bool won,
    int? timeInSeconds,
  }) async {
    final current = await getStats(difficulty);
    final newCompleted = current.gamesCompleted + 1;
    final newWon = won ? current.gamesWon + 1 : current.gamesWon;
    final newLost = won ? current.gamesLost : current.gamesLost + 1;

    int? newBestTime = current.bestTimeSeconds;
    if (won && timeInSeconds != null) {
      if (newBestTime == null || timeInSeconds < newBestTime) {
        newBestTime = timeInSeconds;
      }
    }

    await _prefs.setInt(_statsKey(difficulty, 'completed'), newCompleted);
    await _prefs.setInt(_statsKey(difficulty, 'won'), newWon);
    await _prefs.setInt(_statsKey(difficulty, 'lost'), newLost);
    if (newBestTime != null) {
      await _prefs.setInt(_statsKey(difficulty, 'best_time'), newBestTime);
    }
  }

  @override
  Future<void> resetStats(SudokuDifficulty difficulty) async {
    await _prefs.remove(_statsKey(difficulty, 'completed'));
    await _prefs.remove(_statsKey(difficulty, 'won'));
    await _prefs.remove(_statsKey(difficulty, 'lost'));
    await _prefs.remove(_statsKey(difficulty, 'best_time'));
  }
}
