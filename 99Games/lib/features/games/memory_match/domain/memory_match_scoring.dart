import 'package:equatable/equatable.dart';

/// Breakdown of score components awarded upon level completion.
class MemoryMatchScoreBreakdown extends Equatable {
  final int pairCount;
  final int moves;
  final int elapsedSeconds;
  final int baseScore;
  final int efficiencyBonus;
  final int timeBonus;
  final int totalScore;

  const MemoryMatchScoreBreakdown({
    required this.pairCount,
    required this.moves,
    required this.elapsedSeconds,
    required this.baseScore,
    required this.efficiencyBonus,
    required this.timeBonus,
    required this.totalScore,
  });

  @override
  List<Object?> get props => [
    pairCount,
    moves,
    elapsedSeconds,
    baseScore,
    efficiencyBonus,
    timeBonus,
    totalScore,
  ];
}

/// Pure domain scoring engine for Memory Match.
class MemoryMatchScoring {
  const MemoryMatchScoring();

  /// Calculates the base score awarded for matched pairs (10 pts per pair).
  static int calculateBaseScore(int pairCount) {
    if (pairCount <= 0) return 0;
    return pairCount * 10;
  }

  /// Calculates efficiency bonus based on moves used vs total pairs.
  ///
  /// Formula: ⌊50 * max(0, (2P - M) / P)⌋ clamped to [0, 50].
  static int calculateEfficiencyBonus({
    required int pairCount,
    required int moves,
  }) {
    if (pairCount <= 0 || moves < pairCount) return 0;
    final ratio = (2 * pairCount - moves) / pairCount;
    if (ratio <= 0.0) return 0;
    final bonus = (50 * ratio).floor();
    return bonus.clamp(0, 50);
  }

  /// Calculates time bonus based on elapsed seconds vs target time (8s per pair).
  ///
  /// Formula: Target = 8P. Bonus = ⌊50 * max(0, (Target - T) / Target)⌋ clamped to [0, 50].
  static int calculateTimeBonus({
    required int pairCount,
    required int elapsedSeconds,
  }) {
    if (pairCount <= 0) return 0;
    final targetTime = 8 * pairCount;
    if (targetTime <= 0 || elapsedSeconds >= targetTime) return 0;
    if (elapsedSeconds < 0) return 50;

    final ratio = (targetTime - elapsedSeconds) / targetTime;
    if (ratio <= 0.0) return 0;
    final bonus = (50 * ratio).floor();
    return bonus.clamp(0, 50);
  }

  /// Computes complete score breakdown for a completed level.
  static MemoryMatchScoreBreakdown calculateScore({
    required int pairCount,
    required int moves,
    required int elapsedSeconds,
  }) {
    final base = calculateBaseScore(pairCount);
    final eff = calculateEfficiencyBonus(pairCount: pairCount, moves: moves);
    final time = calculateTimeBonus(
      pairCount: pairCount,
      elapsedSeconds: elapsedSeconds,
    );
    final total = base + eff + time;

    return MemoryMatchScoreBreakdown(
      pairCount: pairCount,
      moves: moves,
      elapsedSeconds: elapsedSeconds,
      baseScore: base,
      efficiencyBonus: eff,
      timeBonus: time,
      totalScore: total,
    );
  }
}
