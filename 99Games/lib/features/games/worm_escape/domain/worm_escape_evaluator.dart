import 'dart:math';
import 'package:flutter/foundation.dart';
import 'worm_escape_engine.dart';
import 'worm_escape_models.dart';

/// Comprehensive structural metrics calculated for a [WormEscapeLevel].
@immutable
class WormEscapeMetrics {
  /// Maximum length of prerequisite chains before a deeply blocked worm can escape.
  final int maxDependencyDepth;

  /// Number of worms that can escape immediately at the initial board state.
  final int initiallyAvailableCount;

  /// Ratio of initially available worms to total worms (lower = more constrained).
  final double initialAvailabilityRatio;

  /// Total count of direct blocking relationships between worms.
  final int totalBlockers;

  /// Number of worms whose forward escape path is obstructed by 2 or more worms.
  final int multipleBlockerWormCount;

  /// Number of key worms whose escape unlocks 2 or more other dependent worms.
  final int convergingBlockersCount;

  /// Total number of worms on the board.
  final int totalWorms;

  /// Centralized objective difficulty score calculated from structural metrics.
  final double difficultyScore;

  const WormEscapeMetrics({
    required this.maxDependencyDepth,
    required this.initiallyAvailableCount,
    required this.initialAvailabilityRatio,
    required this.totalBlockers,
    required this.multipleBlockerWormCount,
    required this.convergingBlockersCount,
    required this.totalWorms,
    required this.difficultyScore,
  });

  @override
  String toString() =>
      'Score: ${difficultyScore.toStringAsFixed(1)} | '
      'Depth: $maxDependencyDepth | '
      'Avail: $initiallyAvailableCount/$totalWorms | '
      'Blockers: $totalBlockers | '
      'Multi: $multipleBlockerWormCount | '
      'Conv: $convergingBlockersCount';
}

/// Evaluator that constructs the dependency DAG and computes objective puzzle difficulty.
class WormEscapeEvaluator {
  WormEscapeEvaluator._();

  /// Builds a directed dependency adjacency map: `wormId -> Set<blockerWormIds>`.
  ///
  /// An edge `W -> B` indicates that worm `B` obstructs worm `W`'s escape path,
  /// meaning `B` must escape before `W` can escape.
  static Map<String, Set<String>> buildDependencyGraph(WormEscapeLevel level) {
    final engine = WormEscapeEngine.initial(level);
    final graph = <String, Set<String>>{};

    for (final worm in level.worms) {
      final blockers = <String>{};
      final path = engine.getEscapePath(worm);

      for (final pos in path) {
        for (final other in level.worms) {
          if (other.id != worm.id && other.occupies(pos)) {
            blockers.add(other.id);
          }
        }
      }
      graph[worm.id] = blockers;
    }

    return graph;
  }

  /// Calculates the dependency depth for a specific worm using memoized DFS.
  static int _calculateWormDepth(
    String wormId,
    Map<String, Set<String>> graph,
    Map<String, int> memo,
    Set<String> visiting,
  ) {
    if (memo.containsKey(wormId)) return memo[wormId]!;
    if (visiting.contains(wormId)) {
      // Cyclic dependency detected (should not occur in valid puzzles)
      return 0;
    }

    visiting.add(wormId);
    final blockers = graph[wormId] ?? const {};

    int depth = 0;
    if (blockers.isNotEmpty) {
      int maxChildDepth = 0;
      for (final blockerId in blockers) {
        final childDepth = _calculateWormDepth(
          blockerId,
          graph,
          memo,
          visiting,
        );
        maxChildDepth = max(maxChildDepth, childDepth);
      }
      depth = 1 + maxChildDepth;
    }

    visiting.remove(wormId);
    memo[wormId] = depth;
    return depth;
  }

  /// Evaluates all structural difficulty metrics for the given [level].
  ///
  /// Mathematical Formulation:
  /// - `Depth Weight (8.0)`: Measures sequential foresight required.
  /// - `Total Blockers Weight (2.5)`: Density of obstacles across the board.
  /// - `Multiple Blockers Weight (4.0)`: Paths obstructed by multiple distinct obstacles.
  /// - `Convergence Weight (3.0)`: Keystone worms that gate multiple downstream chains.
  /// - `Constraint Weight (15.0)`: Inverse of initial escape choices $(1 - \text{ratio})$.
  /// - `Sequence Length Weight (1.5)`: Total required moves to complete level.
  static WormEscapeMetrics evaluate(WormEscapeLevel level) {
    final graph = buildDependencyGraph(level);
    final memo = <String, int>{};

    int maxDepth = 0;
    int initiallyAvailable = 0;
    int totalBlockers = 0;
    int multipleBlockers = 0;

    // Track how many worms each blocker gates (in-degree)
    final blockedByCounts = <String, int>{};

    for (final entry in graph.entries) {
      final wormId = entry.key;
      final blockers = entry.value;

      totalBlockers += blockers.length;

      if (blockers.isEmpty) {
        initiallyAvailable++;
      } else if (blockers.length >= 2) {
        multipleBlockers++;
      }

      for (final b in blockers) {
        blockedByCounts[b] = (blockedByCounts[b] ?? 0) + 1;
      }

      final depth = _calculateWormDepth(wormId, graph, memo, {});
      maxDepth = max(maxDepth, depth);
    }

    // Converging blockers: worms whose escape unlocks 2 or more other worms
    int convergingCount = 0;
    for (final count in blockedByCounts.values) {
      if (count >= 2) {
        convergingCount++;
      }
    }

    final totalWorms = level.worms.length;
    final availRatio = totalWorms > 0 ? initiallyAvailable / totalWorms : 1.0;

    // Calculate normalized composite score
    final score =
        (maxDepth * 8.0) +
        (totalBlockers * 2.5) +
        (multipleBlockers * 4.0) +
        (convergingCount * 3.0) +
        ((1.0 - availRatio) * 15.0) +
        (totalWorms * 1.5);

    return WormEscapeMetrics(
      maxDependencyDepth: maxDepth,
      initiallyAvailableCount: initiallyAvailable,
      initialAvailabilityRatio: availRatio,
      totalBlockers: totalBlockers,
      multipleBlockerWormCount: multipleBlockers,
      convergingBlockersCount: convergingCount,
      totalWorms: totalWorms,
      difficultyScore: score,
    );
  }
}
