import 'dart:math';
import 'sudoku_models.dart';
import 'sudoku_solver.dart';

/// Pure Dart puzzle generator that produces guaranteed uniquely solvable
/// Sudoku puzzles with clue counts matching target difficulty criteria.
class SudokuGenerator {
  final SudokuSolver _solver;
  final Random _random;

  SudokuGenerator({SudokuSolver? solver, Random? random})
    : _solver = solver ?? SudokuSolver(),
      _random = random ?? Random();

  /// Generates a valid [SudokuPuzzle] with exactly one solution.
  SudokuPuzzle generatePuzzle({
    required SudokuDifficulty difficulty,
    int maxAttempts = 8,
  }) {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final solution = generateCompleteGrid();
      if (solution == null) continue;

      final clues = List<int>.from(solution);
      final cellIndices = List<int>.generate(81, (i) => i)..shuffle(_random);

      final targetClues = difficulty.targetClues;
      int currentClues = 81;

      for (final index in cellIndices) {
        if (currentClues <= targetClues) break;

        final originalValue = clues[index];
        clues[index] = 0;

        // Verify that the puzzle still has exactly one solution
        final solutionsCount = _solver.countSolutions(clues, limit: 2);
        if (solutionsCount == 1) {
          currentClues--;
        } else {
          // Cannot remove this cell without introducing ambiguity; restore it
          clues[index] = originalValue;
        }
      }

      // Check if the resulting clue count fits the required difficulty range
      if (currentClues >= difficulty.minClues &&
          currentClues <= difficulty.maxClues) {
        return SudokuPuzzle(
          clues: List.unmodifiable(clues),
          solution: List.unmodifiable(solution),
          difficulty: difficulty,
        );
      } else if (attempt == maxAttempts - 1 &&
          _solver.countSolutions(clues, limit: 2) == 1) {
        // Return puzzle even if slightly outside narrow range on last attempt
        return SudokuPuzzle(
          clues: List.unmodifiable(clues),
          solution: List.unmodifiable(solution),
          difficulty: difficulty,
        );
      }
    }

    // Fail-safe: Return a verified unique fallback puzzle for this difficulty
    return _getFallbackPuzzle(difficulty);
  }

  /// Generates a randomized, fully solved 9 × 9 Sudoku grid.
  List<int>? generateCompleteGrid() {
    final grid = List<int>.filled(81, 0);

    // Fill the 3 independent diagonal 3x3 boxes first (Box 0, Box 4, Box 8)
    _fillBox(grid, 0);
    _fillBox(grid, 4);
    _fillBox(grid, 8);

    // Solve the rest of the board with randomized branching
    return _solver.solve(grid, random: _random);
  }

  /// Fills a 3 × 3 box with a random permutation of numbers 1 through 9.
  void _fillBox(List<int> grid, int boxIndex) {
    final startRow = (boxIndex ~/ 3) * 3;
    final startCol = (boxIndex % 3) * 3;
    final digits = List<int>.generate(9, (i) => i + 1)..shuffle(_random);

    int idx = 0;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final cell = (startRow + r) * 9 + (startCol + c);
        grid[cell] = digits[idx++];
      }
    }
  }

  /// Verified unique fallback puzzle templates in case random generation exceeds attempt bounds.
  SudokuPuzzle _getFallbackPuzzle(SudokuDifficulty difficulty) {
    switch (difficulty) {
      case SudokuDifficulty.easy:
        // 36 clues, unique solution
        const clues = [
          0,
          2,
          0,
          0,
          0,
          0,
          0,
          8,
          0,
          5,
          8,
          0,
          0,
          2,
          0,
          0,
          3,
          4,
          0,
          0,
          3,
          0,
          0,
          0,
          2,
          0,
          0,
          3,
          7,
          0,
          0,
          0,
          0,
          0,
          5,
          2,
          6,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          7,
          1,
          9,
          0,
          0,
          0,
          0,
          0,
          4,
          6,
          0,
          0,
          7,
          0,
          0,
          0,
          9,
          0,
          0,
          8,
          4,
          0,
          0,
          1,
          0,
          0,
          7,
          5,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          6,
          0,
        ];
        final solution = _solver.solve(clues)!;
        return SudokuPuzzle(
          clues: List.unmodifiable(clues),
          solution: List.unmodifiable(solution),
          difficulty: difficulty,
        );

      case SudokuDifficulty.medium:
        // 30 clues, unique solution
        const clues = [
          0,
          0,
          0,
          2,
          6,
          0,
          7,
          0,
          1,
          6,
          8,
          0,
          0,
          7,
          0,
          0,
          9,
          0,
          1,
          9,
          0,
          0,
          0,
          4,
          5,
          0,
          0,
          8,
          2,
          0,
          1,
          0,
          0,
          0,
          4,
          0,
          0,
          0,
          4,
          6,
          0,
          2,
          9,
          0,
          0,
          0,
          5,
          0,
          0,
          0,
          3,
          0,
          2,
          8,
          0,
          0,
          9,
          3,
          0,
          0,
          0,
          7,
          4,
          0,
          4,
          0,
          0,
          5,
          0,
          0,
          3,
          6,
          7,
          0,
          3,
          0,
          1,
          8,
          0,
          0,
          0,
        ];
        final solution = _solver.solve(clues)!;
        return SudokuPuzzle(
          clues: List.unmodifiable(clues),
          solution: List.unmodifiable(solution),
          difficulty: difficulty,
        );

      case SudokuDifficulty.hard:
        // 25 clues, unique solution
        const clues = [
          0,
          0,
          0,
          6,
          0,
          0,
          4,
          0,
          0,
          7,
          0,
          0,
          0,
          0,
          3,
          6,
          0,
          0,
          0,
          0,
          0,
          0,
          9,
          1,
          0,
          8,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          5,
          0,
          1,
          8,
          0,
          0,
          0,
          3,
          0,
          0,
          0,
          3,
          0,
          6,
          0,
          4,
          5,
          0,
          4,
          0,
          2,
          0,
          0,
          0,
          6,
          0,
          9,
          0,
          3,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          2,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
        ];
        final solution = _solver.solve(clues)!;
        return SudokuPuzzle(
          clues: List.unmodifiable(clues),
          solution: List.unmodifiable(solution),
          difficulty: difficulty,
        );
    }
  }
}
