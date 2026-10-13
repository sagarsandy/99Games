import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/number_slide/domain/number_slide_engine.dart';

void main() {
  late NumberSlideEngine engine;

  setUp(() {
    engine = NumberSlideEngine();
  });

  group('NumberSlideEngine - Solved Board and Representation', () {
    test('correct solved board representation is 1..15 followed by 0', () {
      expect(NumberSlideEngine.solvedBoard.length, 16);
      expect(
        NumberSlideEngine.solvedBoard,
        equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0]),
      );
    });

    test('isSolved returns true for solved board and false otherwise', () {
      expect(engine.isSolved(NumberSlideEngine.solvedBoard), isTrue);

      // Board with two tiles swapped
      final unsolved = List<int>.from(NumberSlideEngine.solvedBoard);
      unsolved[14] = 0;
      unsolved[15] = 15;
      expect(engine.isSolved(unsolved), isFalse);
    });

    test('getEmptyIndex finds 0 correctly', () {
      expect(engine.getEmptyIndex(NumberSlideEngine.solvedBoard), 15);

      final boardWithCenterEmpty = [
        1,
        2,
        3,
        4,
        5,
        0,
        7,
        8,
        9,
        6,
        11,
        12,
        13,
        14,
        15,
        10,
      ];
      expect(engine.getEmptyIndex(boardWithCenterEmpty), 5);
    });
  });

  group('NumberSlideEngine - Movement Rules', () {
    test('horizontal and vertical moves into empty cell are legal', () {
      // Empty cell is at 15 (bottom right: row 3, col 3)
      final board = NumberSlideEngine.solvedBoard;

      // Above (index 11) is legal
      expect(engine.canMove(board, 11), isTrue);
      // Left (index 14) is legal
      expect(engine.canMove(board, 14), isTrue);

      // Distant cells are not legal
      expect(engine.canMove(board, 0), isFalse);
      expect(engine.canMove(board, 13), isFalse);
    });

    test('rejection of diagonal and invalid moves', () {
      // Empty cell is at 15
      final board = NumberSlideEngine.solvedBoard;

      // Diagonal neighbor (index 10: row 2, col 2)
      expect(engine.canMove(board, 10), isFalse);

      // The empty cell itself
      expect(engine.canMove(board, 15), isFalse);

      // Out of bounds
      expect(engine.canMove(board, -1), isFalse);
      expect(engine.canMove(board, 16), isFalse);
    });

    test(
      'applyMove swaps tile with empty cell and returns immutable board',
      () {
        final board = NumberSlideEngine.solvedBoard;
        final moved = engine.applyMove(board, 14);

        // Original board is unchanged
        expect(board[14], 15);
        expect(board[15], 0);

        // New board has tile 15 at index 15 and 0 at index 14
        expect(moved[14], 0);
        expect(moved[15], 15);
        expect(() => moved[14] = 99, throwsUnsupportedError);
      },
    );

    test('applyMove throws ArgumentError when move is illegal', () {
      final board = NumberSlideEngine.solvedBoard;
      expect(() => engine.applyMove(board, 0), throwsArgumentError);
      expect(() => engine.applyMove(board, 10), throwsArgumentError);
    });

    test('getValidMoves returns all adjacent movable tiles', () {
      // When empty is in corner (15), exactly 2 valid moves: 11, 14
      final cornerValid = engine.getValidMoves(NumberSlideEngine.solvedBoard);
      expect(cornerValid.toSet(), equals({11, 14}));

      // When empty is in center (5: row 1, col 1), exactly 4 valid moves: 1, 4, 6, 9
      final centerBoard = [
        1,
        2,
        3,
        4,
        5,
        0,
        7,
        8,
        9,
        6,
        11,
        12,
        13,
        14,
        15,
        10,
      ];
      final centerValid = engine.getValidMoves(centerBoard);
      expect(centerValid.toSet(), equals({1, 4, 6, 9}));
    });
  });

  group('NumberSlideEngine - Generation and Solvability', () {
    test('every generated board contains 1..15 and 0 exactly once', () {
      for (int i = 0; i < 10; i++) {
        final generated = engine.generateSolvableBoard(scrambleSteps: 50);
        expect(generated.length, 16);
        expect(generated.toSet().length, 16);
        for (int v = 0; v <= 15; v++) {
          expect(generated.contains(v), isTrue, reason: 'Missing $v');
        }
      }
    });

    test('generated boards are not already solved', () {
      for (int i = 0; i < 10; i++) {
        final generated = engine.generateSolvableBoard(scrambleSteps: 60);
        expect(engine.isSolved(generated), isFalse);
      }
    });

    test('every generated board is mathematically solvable', () {
      for (int i = 0; i < 20; i++) {
        final generated = engine.generateSolvableBoard(scrambleSteps: 80);
        expect(engine.isSolvable(generated), isTrue);
      }
    });

    test('deterministic generation behavior with seeded Random', () {
      final engineA = NumberSlideEngine(random: Random(12345));
      final engineB = NumberSlideEngine(random: Random(12345));

      final boardA = engineA.generateSolvableBoard(scrambleSteps: 40);
      final boardB = engineB.generateSolvableBoard(scrambleSteps: 40);

      expect(boardA, equals(boardB));
    });
  });
}
