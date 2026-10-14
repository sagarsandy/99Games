import 'package:flutter/foundation.dart';

/// Pure Dart domain engine containing Sudoku validation, rule checks,
/// conflict detection, candidate calculations, and completion verification.
class SudokuEngine {
  const SudokuEngine();

  /// Returns true if [index] is a prefilled immutable clue.
  bool isClue(List<int> clues, int index) {
    assert(index >= 0 && index < 81);
    return clues[index] != 0;
  }

  /// Returns true if cell at [index] is empty (0).
  bool isEmpty(List<int> board, int index) {
    assert(index >= 0 && index < 81);
    return board[index] == 0;
  }

  /// Returns true if [value] is the intended correct digit from the [solution].
  bool isCorrectEntry(List<int> solution, int index, int value) {
    assert(index >= 0 && index < 81);
    return solution[index] == value;
  }

  /// Checks if the board is completely filled and matches the [solution].
  bool isBoardCompleteAndValid(List<int> board, List<int> solution) {
    assert(board.length == 81);
    assert(solution.length == 81);
    if (board.any((v) => v == 0)) return false;
    return listEquals(board, solution);
  }

  /// Finds all cell indices that are currently in conflict (duplicate values in same row, col, or 3x3 box).
  Set<int> getConflictingIndices(List<int> board) {
    assert(board.length == 81);
    final conflicts = <int>{};

    // 1. Check Rows
    for (int r = 0; r < 9; r++) {
      final seen = <int, int>{}; // value -> first index
      for (int c = 0; c < 9; c++) {
        final idx = r * 9 + c;
        final val = board[idx];
        if (val != 0) {
          if (seen.containsKey(val)) {
            conflicts.add(seen[val]!);
            conflicts.add(idx);
          } else {
            seen[val] = idx;
          }
        }
      }
    }

    // 2. Check Columns
    for (int c = 0; c < 9; c++) {
      final seen = <int, int>{};
      for (int r = 0; r < 9; r++) {
        final idx = r * 9 + c;
        final val = board[idx];
        if (val != 0) {
          if (seen.containsKey(val)) {
            conflicts.add(seen[val]!);
            conflicts.add(idx);
          } else {
            seen[val] = idx;
          }
        }
      }
    }

    // 3. Check 3x3 Subgrids
    for (int b = 0; b < 9; b++) {
      final seen = <int, int>{};
      final startR = (b ~/ 3) * 3;
      final startC = (b % 3) * 3;
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          final idx = (startR + r) * 9 + (startC + c);
          final val = board[idx];
          if (val != 0) {
            if (seen.containsKey(val)) {
              conflicts.add(seen[val]!);
              conflicts.add(idx);
            } else {
              seen[val] = idx;
            }
          }
        }
      }
    }

    return conflicts;
  }

  /// Calculates all valid candidate numbers (1–9) for [index] based on current [board] state.
  Set<int> calculateCandidates(List<int> board, int index) {
    assert(index >= 0 && index < 81);
    if (board[index] != 0) return {};

    final r = index ~/ 9;
    final c = index % 9;
    final b = (r ~/ 3) * 3 + (c ~/ 3);

    final usedDigits = <int>{};

    // Check Row
    for (int col = 0; col < 9; col++) {
      final val = board[r * 9 + col];
      if (val != 0) usedDigits.add(val);
    }

    // Check Column
    for (int row = 0; row < 9; row++) {
      final val = board[row * 9 + c];
      if (val != 0) usedDigits.add(val);
    }

    // Check Box
    final startR = (b ~/ 3) * 3;
    final startC = (b % 3) * 3;
    for (int dr = 0; dr < 3; dr++) {
      for (int dc = 0; dc < 3; dc++) {
        final val = board[(startR + dr) * 9 + (startC + dc)];
        if (val != 0) usedDigits.add(val);
      }
    }

    final candidates = <int>{};
    for (int d = 1; d <= 9; d++) {
      if (!usedDigits.contains(d)) {
        candidates.add(d);
      }
    }
    return candidates;
  }

  /// Returns indices of all cells related to [selectedIndex]:
  /// same row, same column, or same 3x3 box.
  Set<int> getRelatedIndices(int selectedIndex) {
    assert(selectedIndex >= 0 && selectedIndex < 81);
    final r = selectedIndex ~/ 9;
    final c = selectedIndex % 9;
    final b = (r ~/ 3) * 3 + (c ~/ 3);

    final related = <int>{};

    // Same row
    for (int col = 0; col < 9; col++) {
      related.add(r * 9 + col);
    }

    // Same column
    for (int row = 0; row < 9; row++) {
      related.add(row * 9 + c);
    }

    // Same box
    final startR = (b ~/ 3) * 3;
    final startC = (b % 3) * 3;
    for (int dr = 0; dr < 3; dr++) {
      for (int dc = 0; dc < 3; dc++) {
        related.add((startR + dr) * 9 + (startC + dc));
      }
    }

    return related;
  }

  /// Counts the remaining instances of each number (1–9) that need to be placed on the board.
  Map<int, int> countRemainingNumbers(List<int> board) {
    final counts = {for (int d = 1; d <= 9; d++) d: 9};
    for (final val in board) {
      if (val >= 1 && val <= 9) {
        counts[val] = (counts[val] ?? 9) - 1;
      }
    }
    return counts;
  }
}
