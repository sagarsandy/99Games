import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reaction_test_models.dart';

/// Contract for persisting Reaction Test statistics and history.
abstract interface class ReactionTestStorage {
  Future<ReactionTestStats> getStats();

  Future<void> recordCompletedSession(List<RoundOutcome> outcomes);

  Future<void> resetStats();
}

/// SharedPreferences implementation of [ReactionTestStorage].
class SharedReactionTestStorage implements ReactionTestStorage {
  final SharedPreferences _prefs;

  const SharedReactionTestStorage(this._prefs);

  static const String _statsGamesPlayedKey = 'reaction_test_v1_games_played';
  static const String _statsValidReactionsKey =
      'reaction_test_v1_valid_reactions';
  static const String _statsFalseStartsKey = 'reaction_test_v1_false_starts';
  static const String _statsBestSingleMsKey = 'reaction_test_v1_best_single_ms';
  static const String _statsBestAverageMsKey = 'reaction_test_v1_best_avg_ms';
  static const String _statsLastSessionKey = 'reaction_test_v1_last_session';

  @override
  Future<ReactionTestStats> getStats() async {
    try {
      final played = _prefs.getInt(_statsGamesPlayedKey) ?? 0;
      final valid = _prefs.getInt(_statsValidReactionsKey) ?? 0;
      final falseStarts = _prefs.getInt(_statsFalseStartsKey) ?? 0;
      final bestSingle = _prefs.getInt(_statsBestSingleMsKey);
      final bestAvg = _prefs.getDouble(_statsBestAverageMsKey);

      List<RoundOutcome>? lastOutcomes;
      final rawSession = _prefs.getString(_statsLastSessionKey);
      if (rawSession != null && rawSession.isNotEmpty) {
        try {
          final list = jsonDecode(rawSession) as List<dynamic>;
          lastOutcomes = list
              .map((item) => RoundOutcome.fromMap(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Error decoding last session outcomes: $e');
        }
      }

      return ReactionTestStats(
        totalGamesPlayed: played,
        totalValidReactions: valid,
        totalFalseStarts: falseStarts,
        bestSingleMs: bestSingle,
        bestSessionAverageMs: bestAvg,
        lastSessionOutcomes: lastOutcomes,
      );
    } catch (e) {
      debugPrint('Error retrieving reaction test stats: $e');
      return const ReactionTestStats();
    }
  }

  @override
  Future<void> recordCompletedSession(List<RoundOutcome> outcomes) async {
    final current = await getStats();
    final summary = ReactionTestSessionSummary(outcomes);

    final newGamesPlayed = current.totalGamesPlayed + 1;
    final newValidReactions = current.totalValidReactions + summary.validCount;
    final newFalseStarts = current.totalFalseStarts + summary.falseStartCount;

    // Calculate new best single reaction time
    int? newBestSingle = current.bestSingleMs;
    if (summary.fastestMs != null) {
      if (newBestSingle == null || summary.fastestMs! < newBestSingle) {
        newBestSingle = summary.fastestMs;
      }
    }

    // Calculate new best session average
    double? newBestAvg = current.bestSessionAverageMs;
    if (summary.averageMs != null) {
      if (newBestAvg == null || summary.averageMs! < newBestAvg) {
        newBestAvg = summary.averageMs;
      }
    }

    await _prefs.setInt(_statsGamesPlayedKey, newGamesPlayed);
    await _prefs.setInt(_statsValidReactionsKey, newValidReactions);
    await _prefs.setInt(_statsFalseStartsKey, newFalseStarts);

    if (newBestSingle != null) {
      await _prefs.setInt(_statsBestSingleMsKey, newBestSingle);
    }

    if (newBestAvg != null) {
      await _prefs.setDouble(_statsBestAverageMsKey, newBestAvg);
    }

    try {
      final rawJson = jsonEncode(outcomes.map((o) => o.toMap()).toList());
      await _prefs.setString(_statsLastSessionKey, rawJson);
    } catch (e) {
      debugPrint('Error saving last session outcomes: $e');
    }
  }

  @override
  Future<void> resetStats() async {
    await _prefs.remove(_statsGamesPlayedKey);
    await _prefs.remove(_statsValidReactionsKey);
    await _prefs.remove(_statsFalseStartsKey);
    await _prefs.remove(_statsBestSingleMsKey);
    await _prefs.remove(_statsBestAverageMsKey);
    await _prefs.remove(_statsLastSessionKey);
  }
}
