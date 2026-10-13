import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_keys.dart';

/// Represents statistics for a game or game mode (e.g. wins, losses, draws).
class GameStats extends Equatable {
  final int wins;
  final int losses;
  final int draws;

  const GameStats({this.wins = 0, this.losses = 0, this.draws = 0});

  static const empty = GameStats();

  int get totalGames => wins + losses + draws;

  double get winRate => totalGames == 0 ? 0.0 : (wins / totalGames) * 100;

  GameStats copyWith({int? wins, int? losses, int? draws}) {
    return GameStats(
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
    );
  }

  @override
  List<Object?> get props => [wins, losses, draws];
}

/// Represents the best completed score/time for Number Slide.
class NumberSlideBestResult extends Equatable {
  final int moves;
  final int timeInSeconds;

  const NumberSlideBestResult({
    required this.moves,
    required this.timeInSeconds,
  });

  /// Evaluates whether [candidate] is strictly better than [this].
  /// Criteria:
  /// 1. Fewer moves is primary criterion.
  /// 2. Faster completion time as tiebreaker when moves are equal.
  bool isBeatenBy(NumberSlideBestResult candidate) {
    if (candidate.moves < moves) return true;
    if (candidate.moves == moves && candidate.timeInSeconds < timeInSeconds) {
      return true;
    }
    return false;
  }

  @override
  List<Object?> get props => [moves, timeInSeconds];
}

/// Contract for persisting and retrieving game statistics and best results.
abstract interface class GameStatsStorage {
  Future<GameStats> getStats({required String gameId, required String subKey});

  Future<void> saveStats({
    required String gameId,
    required String subKey,
    required GameStats stats,
  });

  Future<void> resetStats({required String gameId, required String subKey});

  Future<NumberSlideBestResult?> getNumberSlideBestResult();

  Future<bool> recordNumberSlideResult(NumberSlideBestResult candidate);

  Future<void> resetNumberSlideBestResult();

  Future<int> getBlockPuzzleBestScore();

  Future<bool> recordBlockPuzzleScore(int score);

  Future<void> resetBlockPuzzleBestScore();
}

/// SharedPreferences-backed implementation of [GameStatsStorage].
class SharedGameStatsStorage implements GameStatsStorage {
  final SharedPreferences _prefs;

  const SharedGameStatsStorage(this._prefs);

  String _buildKey(String gameId, String subKey, String metric) =>
      '${StorageKeys.gameStatsKey(gameId, subKey)}_$metric';

  static const String _numberSlideMovesKey = 'number_slide_best_moves';
  static const String _numberSlideTimeKey = 'number_slide_best_time';
  static const String _blockPuzzleBestScoreKey = 'block_puzzle_best_score';

  @override
  Future<GameStats> getStats({
    required String gameId,
    required String subKey,
  }) async {
    final wins = _prefs.getInt(_buildKey(gameId, subKey, 'wins')) ?? 0;
    final losses = _prefs.getInt(_buildKey(gameId, subKey, 'losses')) ?? 0;
    final draws = _prefs.getInt(_buildKey(gameId, subKey, 'draws')) ?? 0;

    return GameStats(wins: wins, losses: losses, draws: draws);
  }

  @override
  Future<void> saveStats({
    required String gameId,
    required String subKey,
    required GameStats stats,
  }) async {
    await _prefs.setInt(_buildKey(gameId, subKey, 'wins'), stats.wins);
    await _prefs.setInt(_buildKey(gameId, subKey, 'losses'), stats.losses);
    await _prefs.setInt(_buildKey(gameId, subKey, 'draws'), stats.draws);
  }

  @override
  Future<void> resetStats({
    required String gameId,
    required String subKey,
  }) async {
    await _prefs.remove(_buildKey(gameId, subKey, 'wins'));
    await _prefs.remove(_buildKey(gameId, subKey, 'losses'));
    await _prefs.remove(_buildKey(gameId, subKey, 'draws'));
  }

  @override
  Future<NumberSlideBestResult?> getNumberSlideBestResult() async {
    final moves = _prefs.getInt(_numberSlideMovesKey);
    final time = _prefs.getInt(_numberSlideTimeKey);

    if (moves == null || time == null) return null;
    return NumberSlideBestResult(moves: moves, timeInSeconds: time);
  }

  @override
  Future<bool> recordNumberSlideResult(NumberSlideBestResult candidate) async {
    final current = await getNumberSlideBestResult();
    if (current == null || current.isBeatenBy(candidate)) {
      await _prefs.setInt(_numberSlideMovesKey, candidate.moves);
      await _prefs.setInt(_numberSlideTimeKey, candidate.timeInSeconds);
      return true;
    }
    return false;
  }

  @override
  Future<void> resetNumberSlideBestResult() async {
    await _prefs.remove(_numberSlideMovesKey);
    await _prefs.remove(_numberSlideTimeKey);
  }

  @override
  Future<int> getBlockPuzzleBestScore() async {
    return _prefs.getInt(_blockPuzzleBestScoreKey) ?? 0;
  }

  @override
  Future<bool> recordBlockPuzzleScore(int score) async {
    final current = await getBlockPuzzleBestScore();
    if (score > current) {
      await _prefs.setInt(_blockPuzzleBestScoreKey, score);
      return true;
    }
    return false;
  }

  @override
  Future<void> resetBlockPuzzleBestScore() async {
    await _prefs.remove(_blockPuzzleBestScoreKey);
  }
}
