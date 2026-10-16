import 'package:flutter/foundation.dart';
import 'emoji_connect_models.dart';

/// Validation report for an Emoji Connect board state.
@immutable
class EmojiConnectValidationResult {
  final bool isValid;
  final bool isCompleteWin;
  final String? errorMessage;
  final int coveredCellsCount;
  final int totalCells;
  final int connectedPairsCount;
  final int totalPairs;

  const EmojiConnectValidationResult({
    required this.isValid,
    required this.isCompleteWin,
    this.errorMessage,
    required this.coveredCellsCount,
    required this.totalCells,
    required this.connectedPairsCount,
    required this.totalPairs,
  });

  factory EmojiConnectValidationResult.invalid(
    String message, {
    int covered = 0,
    int totalCells = 0,
    int connected = 0,
    int totalPairs = 0,
  }) {
    return EmojiConnectValidationResult(
      isValid: false,
      isCompleteWin: false,
      errorMessage: message,
      coveredCellsCount: covered,
      totalCells: totalCells,
      connectedPairsCount: connected,
      totalPairs: totalPairs,
    );
  }
}

/// Domain puzzle validator and bounded constraint-based solver.
class EmojiConnectSolver {
  const EmojiConnectSolver._();

  /// Validates a board configuration against all Flow Free rules.
  static EmojiConnectValidationResult validate({
    required EmojiConnectLevel level,
    required Map<String, EmojiPath> paths,
  }) {
    final size = level.boardSize;
    final totalCells = size * size;
    final totalPairs = level.pairs.length;

    final cellOccupancy = <GridPosition, String>{};
    int connectedCount = 0;

    for (final pair in level.pairs) {
      final path = paths[pair.id];
      if (path == null || path.isEmpty) continue;

      final pts = path.points;

      // 1. Boundary check
      for (final p in pts) {
        if (!p.isWithinBounds(size)) {
          return EmojiConnectValidationResult.invalid(
            'Path for ${pair.emoji} leaves the board at $p.',
            covered: cellOccupancy.length,
            totalCells: totalCells,
            totalPairs: totalPairs,
          );
        }
      }

      // 2. Start point must be one of the pair's endpoints
      if (!pair.hasEndpoint(pts.first)) {
        return EmojiConnectValidationResult.invalid(
          'Path for ${pair.emoji} does not begin at an endpoint.',
          covered: cellOccupancy.length,
          totalCells: totalCells,
          totalPairs: totalPairs,
        );
      }

      // 3. Orthogonal connectivity & no consecutive duplicates
      for (int i = 0; i < pts.length - 1; i++) {
        if (!pts[i].isOrthogonalTo(pts[i + 1])) {
          return EmojiConnectValidationResult.invalid(
            'Diagonal or discontinuous movement in ${pair.emoji} path between ${pts[i]} and ${pts[i + 1]}.',
            covered: cellOccupancy.length,
            totalCells: totalCells,
            totalPairs: totalPairs,
          );
        }
      }

      // 4. No repeated cells within own path (no self-loops)
      final selfSet = <GridPosition>{};
      for (final p in pts) {
        if (!selfSet.add(p)) {
          return EmojiConnectValidationResult.invalid(
            'Path for ${pair.emoji} revisits cell $p.',
            covered: cellOccupancy.length,
            totalCells: totalCells,
            totalPairs: totalPairs,
          );
        }
      }

      // 5. Must not pass through another pair's endpoint
      for (final p in pts) {
        final epPair = level.getPairAtEndpoint(p);
        if (epPair != null && epPair.id != pair.id) {
          return EmojiConnectValidationResult.invalid(
            'Path for ${pair.emoji} crosses endpoint of ${epPair.emoji} at $p.',
            covered: cellOccupancy.length,
            totalCells: totalCells,
            totalPairs: totalPairs,
          );
        }
      }

      // 6. No overlapping paths with other pairs
      for (final p in pts) {
        if (cellOccupancy.containsKey(p)) {
          final otherPairId = cellOccupancy[p]!;
          final otherPair = level.getPairById(otherPairId);
          return EmojiConnectValidationResult.invalid(
            'Paths for ${pair.emoji} and ${otherPair?.emoji ?? otherPairId} overlap at $p.',
            covered: cellOccupancy.length,
            totalCells: totalCells,
            totalPairs: totalPairs,
          );
        }
        cellOccupancy[p] = pair.id;
      }

      // 7. Check if completed
      if (path.isComplete(pair)) {
        connectedCount++;
      }
    }

    final isAllConnected = connectedCount == totalPairs;
    final isFullCoverage = cellOccupancy.length == totalCells;
    final isWin = isAllConnected && isFullCoverage;

    return EmojiConnectValidationResult(
      isValid: true,
      isCompleteWin: isWin,
      coveredCellsCount: cellOccupancy.length,
      totalCells: totalCells,
      connectedPairsCount: connectedCount,
      totalPairs: totalPairs,
    );
  }

  /// Solves a puzzle using reference solution or bounded backtracking with pruning.
  static Map<String, List<GridPosition>>? solve(
    EmojiConnectLevel level, {
    int maxSteps = 50000,
  }) {
    // 1. If reference solution is valid, return it directly
    if (level.referenceSolution.isNotEmpty) {
      final paths = level.referenceSolution.map(
        (k, pts) => MapEntry(k, EmojiPath(pairId: k, points: pts)),
      );
      final res = validate(level: level, paths: paths);
      if (res.isCompleteWin) {
        return level.referenceSolution;
      }
    }

    // 2. Bounded backtracking solver with dead-end pruning
    final size = level.boardSize;
    final grid = List.generate(size, (_) => List.filled(size, -1));

    // Place endpoints on grid
    for (int i = 0; i < level.pairs.length; i++) {
      final p = level.pairs[i];
      grid[p.endpointA.row][p.endpointA.col] = i;
      grid[p.endpointB.row][p.endpointB.col] = i;
    }

    final paths = List.generate(
      level.pairs.length,
      (i) => [level.pairs[i].endpointA],
    );
    int steps = 0;

    bool backtrack(int pairIdx) {
      if (steps++ > maxSteps) return false;

      if (pairIdx == level.pairs.length) {
        // All pairs connected. Check full coverage.
        for (int r = 0; r < size; r++) {
          for (int c = 0; c < size; c++) {
            if (grid[r][c] == -1) return false;
          }
        }
        return true;
      }

      final pair = level.pairs[pairIdx];
      final curr = paths[pairIdx].last;
      final target = pair.endpointB;

      // Check if reached target
      if (curr == target) {
        return backtrack(pairIdx + 1);
      }

      // Orthogonal neighbors
      final neighbors = [
        GridPosition(curr.row - 1, curr.col),
        GridPosition(curr.row + 1, curr.col),
        GridPosition(curr.row, curr.col - 1),
        GridPosition(curr.row, curr.col + 1),
      ];

      for (final n in neighbors) {
        if (!n.isWithinBounds(size)) continue;

        if (n == target) {
          paths[pairIdx].add(n);
          if (backtrack(pairIdx + 1)) return true;
          paths[pairIdx].removeLast();
          continue;
        }

        // Must be unvisited
        if (grid[n.row][n.col] == -1) {
          // Dead-end pruning check: ensures we don't trap adjacent free cells
          grid[n.row][n.col] = pairIdx;
          paths[pairIdx].add(n);

          bool deadEnd = false;
          // Check neighbors of n
          for (final check in [
            GridPosition(n.row - 1, n.col),
            GridPosition(n.row + 1, n.col),
            GridPosition(n.row, n.col - 1),
            GridPosition(n.row, n.col + 1),
          ]) {
            if (check.isWithinBounds(size) &&
                grid[check.row][check.col] == -1) {
              int freeNeighbors = 0;
              for (final fn in check.orthogonalNeighbors(size)) {
                if (grid[fn.row][fn.col] == -1 || fn == target) {
                  freeNeighbors++;
                }
              }
              if (freeNeighbors < 2) {
                deadEnd = true;
                break;
              }
            }
          }

          if (!deadEnd && backtrack(pairIdx)) {
            return true;
          }

          paths[pairIdx].removeLast();
          grid[n.row][n.col] = -1;
        }
      }

      return false;
    }

    // Reset grid endpoint markers for search
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        grid[r][c] = -1;
      }
    }
    for (int i = 0; i < level.pairs.length; i++) {
      final p = level.pairs[i];
      grid[p.endpointA.row][p.endpointA.col] = i;
    }

    if (backtrack(0)) {
      final result = <String, List<GridPosition>>{};
      for (int i = 0; i < level.pairs.length; i++) {
        result[level.pairs[i].id] = List.unmodifiable(paths[i]);
      }
      return result;
    }

    return null;
  }
}
