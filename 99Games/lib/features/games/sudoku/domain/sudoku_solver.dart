import 'dart:math';

/// Fast, bitmask-based backtracking Sudoku solver.
///
/// Implements the Minimum Remaining Values (MRV) heuristic for search tree pruning.
/// Supports bounded solution counting to verify puzzle uniqueness (stopping as soon as limit is reached).
class SudokuSolver {
  /// All 9 possible digits represented as a bitmask (bits 0..8 set).
  static const int allDigitsMask = 0x1FF;

  /// Counts the number of valid solutions for [grid], capped at [limit].
  ///
  /// Returns:
  /// - 0: Unsolvable puzzle (or contradictory clues)
  /// - 1: Uniquely solvable puzzle
  /// - 2: Multiple solutions (or more, if limit > 2)
  int countSolutions(List<int> grid, {int limit = 2}) {
    assert(grid.length == 81);
    final workGrid = List<int>.from(grid);

    final rowMask = List<int>.filled(9, 0);
    final colMask = List<int>.filled(9, 0);
    final boxMask = List<int>.filled(9, 0);

    // Initialize bitmasks and check for initial contradictions
    for (int i = 0; i < 81; i++) {
      final val = workGrid[i];
      if (val != 0) {
        if (val < 1 || val > 9) return 0;
        final r = i ~/ 9;
        final c = i % 9;
        final b = (r ~/ 3) * 3 + (c ~/ 3);
        final bit = 1 << (val - 1);

        if ((rowMask[r] & bit) != 0 ||
            (colMask[c] & bit) != 0 ||
            (boxMask[b] & bit) != 0) {
          return 0; // Contradictory clue in initial grid
        }

        rowMask[r] |= bit;
        colMask[c] |= bit;
        boxMask[b] |= bit;
      }
    }

    int solutions = 0;

    void backtrack() {
      if (solutions >= limit) return;

      // Find empty cell with fewest remaining candidates (MRV)
      int bestIndex = -1;
      int minCandidates = 10;
      int bestCandidatesMask = 0;

      for (int i = 0; i < 81; i++) {
        if (workGrid[i] == 0) {
          final r = i ~/ 9;
          final c = i % 9;
          final b = (r ~/ 3) * 3 + (c ~/ 3);
          final used = rowMask[r] | colMask[c] | boxMask[b];
          final available = (~used) & allDigitsMask;

          final candidateCount = _popCount(available);
          if (candidateCount == 0) {
            return; // Dead end: empty cell has no legal candidates
          }

          if (candidateCount < minCandidates) {
            minCandidates = candidateCount;
            bestIndex = i;
            bestCandidatesMask = available;
            if (minCandidates == 1) break; // Optimal choice found
          }
        }
      }

      // If no empty cells remain, a valid solution was found!
      if (bestIndex == -1) {
        solutions++;
        return;
      }

      final r = bestIndex ~/ 9;
      final c = bestIndex % 9;
      final b = (r ~/ 3) * 3 + (c ~/ 3);

      for (int digit = 1; digit <= 9; digit++) {
        final bit = 1 << (digit - 1);
        if ((bestCandidatesMask & bit) != 0) {
          workGrid[bestIndex] = digit;
          rowMask[r] |= bit;
          colMask[c] |= bit;
          boxMask[b] |= bit;

          backtrack();

          // Undo move
          workGrid[bestIndex] = 0;
          rowMask[r] &= ~bit;
          colMask[c] &= ~bit;
          boxMask[b] &= ~bit;

          if (solutions >= limit) return;
        }
      }
    }

    backtrack();
    return solutions;
  }

  /// Solves [grid] and returns the complete 81-digit solution, or `null` if unsolvable.
  /// If [random] is provided, candidate branches are shuffled for random generation.
  List<int>? solve(List<int> grid, {Random? random}) {
    assert(grid.length == 81);
    final workGrid = List<int>.from(grid);

    final rowMask = List<int>.filled(9, 0);
    final colMask = List<int>.filled(9, 0);
    final boxMask = List<int>.filled(9, 0);

    for (int i = 0; i < 81; i++) {
      final val = workGrid[i];
      if (val != 0) {
        if (val < 1 || val > 9) return null;
        final r = i ~/ 9;
        final c = i % 9;
        final b = (r ~/ 3) * 3 + (c ~/ 3);
        final bit = 1 << (val - 1);

        if ((rowMask[r] & bit) != 0 ||
            (colMask[c] & bit) != 0 ||
            (boxMask[b] & bit) != 0) {
          return null; // Contradictory input
        }

        rowMask[r] |= bit;
        colMask[c] |= bit;
        boxMask[b] |= bit;
      }
    }

    List<int>? foundSolution;

    bool backtrack() {
      int bestIndex = -1;
      int minCandidates = 10;
      int bestCandidatesMask = 0;

      for (int i = 0; i < 81; i++) {
        if (workGrid[i] == 0) {
          final r = i ~/ 9;
          final c = i % 9;
          final b = (r ~/ 3) * 3 + (c ~/ 3);
          final used = rowMask[r] | colMask[c] | boxMask[b];
          final available = (~used) & allDigitsMask;

          final candidateCount = _popCount(available);
          if (candidateCount == 0) return false;

          if (candidateCount < minCandidates) {
            minCandidates = candidateCount;
            bestIndex = i;
            bestCandidatesMask = available;
            if (minCandidates == 1) break;
          }
        }
      }

      if (bestIndex == -1) {
        foundSolution = List<int>.from(workGrid);
        return true;
      }

      final r = bestIndex ~/ 9;
      final c = bestIndex % 9;
      final b = (r ~/ 3) * 3 + (c ~/ 3);

      final candidateDigits = <int>[];
      for (int digit = 1; digit <= 9; digit++) {
        if ((bestCandidatesMask & (1 << (digit - 1))) != 0) {
          candidateDigits.add(digit);
        }
      }

      if (random != null) {
        candidateDigits.shuffle(random);
      }

      for (final digit in candidateDigits) {
        final bit = 1 << (digit - 1);
        workGrid[bestIndex] = digit;
        rowMask[r] |= bit;
        colMask[c] |= bit;
        boxMask[b] |= bit;

        if (backtrack()) return true;

        workGrid[bestIndex] = 0;
        rowMask[r] &= ~bit;
        colMask[c] &= ~bit;
        boxMask[b] &= ~bit;
      }

      return false;
    }

    final hasSolution = backtrack();
    return hasSolution ? foundSolution : null;
  }

  /// Checks if [grid] contains any Sudoku rule violations in rows, columns, or boxes.
  bool isValidGrid(List<int> grid) {
    if (grid.length != 81) return false;

    final rowMask = List<int>.filled(9, 0);
    final colMask = List<int>.filled(9, 0);
    final boxMask = List<int>.filled(9, 0);

    for (int i = 0; i < 81; i++) {
      final val = grid[i];
      if (val != 0) {
        if (val < 1 || val > 9) return false;
        final r = i ~/ 9;
        final c = i % 9;
        final b = (r ~/ 3) * 3 + (c ~/ 3);
        final bit = 1 << (val - 1);

        if ((rowMask[r] & bit) != 0 ||
            (colMask[c] & bit) != 0 ||
            (boxMask[b] & bit) != 0) {
          return false;
        }

        rowMask[r] |= bit;
        colMask[c] |= bit;
        boxMask[b] |= bit;
      }
    }

    return true;
  }

  /// Returns population count (number of set bits in an integer).
  int _popCount(int mask) {
    int count = 0;
    int m = mask;
    while (m > 0) {
      m &= (m - 1);
      count++;
    }
    return count;
  }
}
