import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Phases of the Reaction Test game.
enum ReactionPhase {
  /// Initial landing screen with challenge details, personal best, and Start button.
  intro,

  /// Red waiting screen; random delay is ticking down.
  waiting,

  /// Screen turned green; stopwatch is running, awaiting tap.
  green,

  /// Player tapped successfully after green; showing round reaction time.
  roundResult,

  /// Player tapped prematurely before green; showing false start feedback.
  falseStart,

  /// All 5 rounds finished; showing comprehensive breakdown and statistics.
  completed,
}

/// Descriptive rating category for a reaction time.
enum ReactionCategory {
  veryFast('Very fast'),
  fast('Fast'),
  typical('Typical range'),
  needsPractice('Keep practicing'),
  falseStart('False start');

  final String label;
  const ReactionCategory(this.label);

  /// Evaluates an elapsed millisecond value into an approximate performance category.
  static ReactionCategory fromMs(int? ms) {
    if (ms == null) return ReactionCategory.falseStart;
    if (ms < 200) return ReactionCategory.veryFast;
    if (ms <= 250) return ReactionCategory.fast;
    if (ms <= 350) return ReactionCategory.typical;
    return ReactionCategory.needsPractice;
  }
}

/// Represents the immutable outcome of a single round.
@immutable
class RoundOutcome {
  final int roundNumber;
  final bool isFalseStart;
  final int? reactionTimeMs;

  const RoundOutcome({
    required this.roundNumber,
    required this.isFalseStart,
    this.reactionTimeMs,
  });

  ReactionCategory get category => isFalseStart
      ? ReactionCategory.falseStart
      : ReactionCategory.fromMs(reactionTimeMs);

  String get formattedResult =>
      isFalseStart ? 'Too early!' : '${reactionTimeMs ?? 0} ms';

  Map<String, dynamic> toMap() {
    return {
      'roundNumber': roundNumber,
      'isFalseStart': isFalseStart,
      'reactionTimeMs': reactionTimeMs,
    };
  }

  factory RoundOutcome.fromMap(Map<String, dynamic> map) {
    return RoundOutcome(
      roundNumber: map['roundNumber'] as int,
      isFalseStart: map['isFalseStart'] as bool? ?? false,
      reactionTimeMs: map['reactionTimeMs'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoundOutcome &&
          runtimeType == other.runtimeType &&
          roundNumber == other.roundNumber &&
          isFalseStart == other.isFalseStart &&
          reactionTimeMs == other.reactionTimeMs;

  @override
  int get hashCode => Object.hash(roundNumber, isFalseStart, reactionTimeMs);

  @override
  String toString() =>
      'RoundOutcome(round: $roundNumber, falseStart: $isFalseStart, ms: $reactionTimeMs)';
}

/// Summary calculations for a completed or in-progress 5-round session.
@immutable
class ReactionTestSessionSummary {
  final List<RoundOutcome> outcomes;

  const ReactionTestSessionSummary(this.outcomes);

  List<int> get validReactionTimes => outcomes
      .where((o) => !o.isFalseStart && o.reactionTimeMs != null)
      .map((o) => o.reactionTimeMs!)
      .toList();

  int get falseStartCount => outcomes.where((o) => o.isFalseStart).length;

  int get validCount => validReactionTimes.length;

  bool get isAllFalseStarts =>
      outcomes.isNotEmpty && validReactionTimes.isEmpty;

  double? get averageMs {
    if (validReactionTimes.isEmpty) return null;
    final total = validReactionTimes.reduce((a, b) => a + b);
    return total / validReactionTimes.length;
  }

  int? get fastestMs {
    if (validReactionTimes.isEmpty) return null;
    return validReactionTimes.reduce((a, b) => a < b ? a : b);
  }

  int? get slowestMs {
    if (validReactionTimes.isEmpty) return null;
    return validReactionTimes.reduce((a, b) => a > b ? a : b);
  }

  ReactionCategory? get averageCategory {
    final avg = averageMs;
    if (avg == null) return null;
    return ReactionCategory.fromMs(avg.round());
  }
}

/// Persistent statistics for Reaction Test.
@immutable
class ReactionTestStats {
  final int totalGamesPlayed;
  final int totalValidReactions;
  final int totalFalseStarts;
  final int? bestSingleMs;
  final double? bestSessionAverageMs;
  final List<RoundOutcome>? lastSessionOutcomes;

  const ReactionTestStats({
    this.totalGamesPlayed = 0,
    this.totalValidReactions = 0,
    this.totalFalseStarts = 0,
    this.bestSingleMs,
    this.bestSessionAverageMs,
    this.lastSessionOutcomes,
  });

  ReactionTestStats copyWith({
    int? totalGamesPlayed,
    int? totalValidReactions,
    int? totalFalseStarts,
    int? bestSingleMs,
    double? bestSessionAverageMs,
    List<RoundOutcome>? lastSessionOutcomes,
  }) {
    return ReactionTestStats(
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalValidReactions: totalValidReactions ?? this.totalValidReactions,
      totalFalseStarts: totalFalseStarts ?? this.totalFalseStarts,
      bestSingleMs: bestSingleMs ?? this.bestSingleMs,
      bestSessionAverageMs: bestSessionAverageMs ?? this.bestSessionAverageMs,
      lastSessionOutcomes: lastSessionOutcomes ?? this.lastSessionOutcomes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalGamesPlayed': totalGamesPlayed,
      'totalValidReactions': totalValidReactions,
      'totalFalseStarts': totalFalseStarts,
      'bestSingleMs': bestSingleMs,
      'bestSessionAverageMs': bestSessionAverageMs,
      'lastSessionOutcomes': lastSessionOutcomes
          ?.map((o) => o.toMap())
          .toList(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory ReactionTestStats.fromMap(Map<String, dynamic> map) {
    final rawOutcomes = map['lastSessionOutcomes'] as List<dynamic>?;
    final outcomes = rawOutcomes
        ?.map((item) => RoundOutcome.fromMap(item as Map<String, dynamic>))
        .toList();

    return ReactionTestStats(
      totalGamesPlayed: map['totalGamesPlayed'] as int? ?? 0,
      totalValidReactions: map['totalValidReactions'] as int? ?? 0,
      totalFalseStarts: map['totalFalseStarts'] as int? ?? 0,
      bestSingleMs: map['bestSingleMs'] as int?,
      bestSessionAverageMs: (map['bestSessionAverageMs'] as num?)?.toDouble(),
      lastSessionOutcomes: outcomes,
    );
  }

  factory ReactionTestStats.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return ReactionTestStats.fromMap(map);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionTestStats &&
          runtimeType == other.runtimeType &&
          totalGamesPlayed == other.totalGamesPlayed &&
          totalValidReactions == other.totalValidReactions &&
          totalFalseStarts == other.totalFalseStarts &&
          bestSingleMs == other.bestSingleMs &&
          bestSessionAverageMs == other.bestSessionAverageMs &&
          listEquals(lastSessionOutcomes, other.lastSessionOutcomes);

  @override
  int get hashCode => Object.hash(
    totalGamesPlayed,
    totalValidReactions,
    totalFalseStarts,
    bestSingleMs,
    bestSessionAverageMs,
    lastSessionOutcomes == null ? 0 : Object.hashAll(lastSessionOutcomes!),
  );
}
