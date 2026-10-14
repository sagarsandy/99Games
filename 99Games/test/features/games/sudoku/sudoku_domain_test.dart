import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/sudoku/domain/sudoku_engine.dart';
import 'package:mini_games_99/features/games/sudoku/domain/sudoku_generator.dart';
import 'package:mini_games_99/features/games/sudoku/domain/sudoku_models.dart';
import 'package:mini_games_99/features/games/sudoku/domain/sudoku_solver.dart';

void main() {
  late SudokuEngine engine;
  late SudokuSolver solver;
  late SudokuGenerator generator;

  // A known valid complete Sudoku solution
  final validCompleteBoard = [
    5,
    3,
    4,
    6,
    7,
    8,
    9,
    1,
    2,
    6,
    7,
    2,
    1,
    9,
    5,
    3,
    4,
    8,
    1,
    9,
    8,
    3,
    4,
    2,
    5,
    6,
    7,
    8,
    5,
    9,
    7,
    6,
    1,
    4,
    2,
    3,
    4,
    2,
    6,
    8,
    5,
    3,
    7,
    9,
    1,
    7,
    1,
    3,
    9,
    2,
    4,
    8,
    5,
    6,
    9,
    6,
    1,
    5,
    3,
    7,
    2,
    8,
    4,
    2,
    8,
    7,
    4,
    1,
    9,
    6,
    3,
    5,
    3,
    4,
    5,
    2,
    8,
    6,
    1,
    7,
    9,
  ];

  setUp(() {
    engine = const SudokuEngine();
    solver = SudokuSolver();
    generator = SudokuGenerator(solver: solver, random: Random(12345));
  });

  group('Sudoku Domain - Models & Coordinates', () {
    test('SudokuDifficulty values and clue targets', () {
      expect(SudokuDifficulty.easy.minClues, equals(35));
      expect(SudokuDifficulty.easy.maxClues, equals(40));
      expect(SudokuDifficulty.medium.minClues, equals(28));
      expect(SudokuDifficulty.medium.maxClues, equals(34));
      expect(SudokuDifficulty.hard.minClues, equals(22));
      expect(SudokuDifficulty.hard.maxClues, equals(27));
    });

    test('SudokuCellCoordinate conversions and box index', () {
      const coord = SudokuCellCoordinate(4, 7);
      expect(coord.row, equals(4));
      expect(coord.col, equals(7));
      expect(coord.index, equals(4 * 9 + 7)); // 43
      expect(coord.boxIndex, equals((4 ~/ 3) * 3 + (7 ~/ 3))); // 1 * 3 + 2 = 5

      final fromIdx = SudokuCellCoordinate.fromIndex(43);
      expect(fromIdx, equals(coord));
    });
  });

  group('Sudoku Domain - Engine Validation & Conflicts', () {
    test('valid solved board has no conflicts and evaluates complete', () {
      expect(solver.isValidGrid(validCompleteBoard), isTrue);
      expect(engine.getConflictingIndices(validCompleteBoard), isEmpty);
      expect(
        engine.isBoardCompleteAndValid(validCompleteBoard, validCompleteBoard),
        isTrue,
      );
    });

    test('detects duplicate conflict in a row', () {
      final board = List<int>.from(validCompleteBoard);
      // Row 0 has digits 5 and 3 at index 0 and 1. Set index 1 to 5 as duplicate!
      board[1] = 5;
      final conflicts = engine.getConflictingIndices(board);
      expect(conflicts.contains(0), isTrue);
      expect(conflicts.contains(1), isTrue);
      expect(solver.isValidGrid(board), isFalse);
    });

    test('detects duplicate conflict in a column', () {
      final board = List<int>.from(validCompleteBoard);
      // Col 0 has digits: row 0 index 0 is 5, row 1 index 9 is 6. Set index 9 to 5!
      board[9] = 5;
      final conflicts = engine.getConflictingIndices(board);
      expect(conflicts.contains(0), isTrue);
      expect(conflicts.contains(9), isTrue);
      expect(solver.isValidGrid(board), isFalse);
    });

    test('detects duplicate conflict in a 3x3 subgrid', () {
      final board = List<int>.from(validCompleteBoard);
      // Subgrid 0 (top-left): cell (0,0)=5, cell (1,1)=7. Set (1,1)=5!
      final idx1 = 0;
      final idx2 = 1 * 9 + 1; // 10
      board[idx2] = 5;
      final conflicts = engine.getConflictingIndices(board);
      expect(conflicts.contains(idx1), isTrue);
      expect(conflicts.contains(idx2), isTrue);
    });

    test('calculateCandidates returns correct set of legal digits', () {
      final board = List<int>.filled(81, 0);
      // Place 1..8 in row 0, leaving index 8 empty
      for (int c = 0; c < 8; c++) {
        board[c] = c + 1;
      }
      final candidates = engine.calculateCandidates(board, 8);
      expect(candidates, equals({9}));
    });

    test('countRemainingNumbers counts instances needed on board', () {
      final board = List<int>.filled(81, 0);
      board[0] = 5;
      board[1] = 5;
      final remaining = engine.countRemainingNumbers(board);
      expect(remaining[5], equals(7)); // 9 - 2
      expect(remaining[1], equals(9));
    });

    test('getRelatedIndices returns 20 distinct neighbors for a cell', () {
      final related = engine.getRelatedIndices(0);
      // Same row (9), same col (9), same box (9) minus duplicates = 21 cells including itself
      expect(related.contains(0), isTrue);
      expect(related.contains(1), isTrue); // same row
      expect(related.contains(9), isTrue); // same col
      expect(related.contains(10), isTrue); // same 3x3 box
      expect(related.length, equals(21));
    });
  });

  group('Sudoku Domain - Solver & Uniqueness', () {
    test('solver finds valid solution for partial board', () {
      final puzzle = generator.generatePuzzle(
        difficulty: SudokuDifficulty.easy,
      );
      final solution = solver.solve(puzzle.clues);
      expect(solution, isNotNull);
      expect(solver.isValidGrid(solution!), isTrue);
      expect(solution, equals(puzzle.solution));
    });

    test('countSolutions returns 0 for contradictory or unsolvable board', () {
      final board = List<int>.filled(81, 0);
      // Place two 5s in row 0
      board[0] = 5;
      board[1] = 5;
      expect(solver.countSolutions(board, limit: 2), equals(0));
    });

    test(
      'countSolutions returns 2 for ambiguous board with multiple solutions',
      () {
        final board = List<int>.filled(81, 0);
        // Almost empty board has thousands of solutions; limit: 2 stops immediately at 2
        expect(solver.countSolutions(board, limit: 2), equals(2));
      },
    );
  });

  group('Sudoku Domain - Puzzle Generation', () {
    for (final difficulty in SudokuDifficulty.values) {
      test(
        'generates valid uniquely solvable puzzle for ${difficulty.label}',
        () {
          final puzzle = generator.generatePuzzle(difficulty: difficulty);
          expect(puzzle.clues.length, equals(81));
          expect(puzzle.solution.length, equals(81));
          expect(puzzle.difficulty, equals(difficulty));

          // Clue count within range
          expect(
            puzzle.clueCount,
            greaterThanOrEqualTo(difficulty.minClues - 1),
          );
          expect(puzzle.clueCount, lessThanOrEqualTo(difficulty.maxClues + 1));

          // Valid complete solution
          expect(solver.isValidGrid(puzzle.solution), isTrue);

          // Exactly one solution!
          final solutions = solver.countSolutions(puzzle.clues, limit: 2);
          expect(solutions, equals(1));
        },
      );
    }

    test('generateCompleteGrid creates a randomized valid 81-digit grid', () {
      final grid1 = generator.generateCompleteGrid();
      final grid2 = generator.generateCompleteGrid();

      expect(grid1, isNotNull);
      expect(grid2, isNotNull);
      expect(solver.isValidGrid(grid1!), isTrue);
      expect(solver.isValidGrid(grid2!), isTrue);
      // Random generation should produce distinct solutions
      expect(grid1, isNot(equals(grid2)));
    });
  });
}
