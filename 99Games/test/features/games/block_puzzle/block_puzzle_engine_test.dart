import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/block_puzzle/domain/block_puzzle_engine.dart';
import 'package:mini_games_99/features/games/block_puzzle/domain/block_puzzle_models.dart';

void main() {
  late BlockPuzzleEngine engine;

  setUp(() {
    engine = BlockPuzzleEngine(random: Random(42));
  });

  group('BlockPuzzleEngine - Board and Piece Definitions', () {
    test('initial board is an empty 10x10 grid of 100 zeros', () {
      final board = engine.createEmptyBoard();
      expect(board.length, 100);
      expect(
        board.every((cell) => cell == BlockPuzzleEngine.emptyCell),
        isTrue,
      );
    });

    test('all standard piece definitions are valid and normalized', () {
      expect(BlockPuzzleEngine.standardShapes.length, greaterThanOrEqualTo(14));

      for (final shape in BlockPuzzleEngine.standardShapes) {
        expect(shape.id, isNotEmpty);
        expect(shape.name, isNotEmpty);
        expect(shape.cells, isNotEmpty);
        expect(shape.color, isNotNull);

        // Normalized: Minimum row and col must start at 0
        final minRow = shape.cells.map((c) => c.row).reduce(min);
        final minCol = shape.cells.map((c) => c.col).reduce(min);
        expect(minRow, 0, reason: '${shape.id} row anchor should start at 0');
        expect(minCol, 0, reason: '${shape.id} col anchor should start at 0');

        // Bounding box dimensions
        final maxRow = shape.cells.map((c) => c.row).reduce(max);
        final maxCol = shape.cells.map((c) => c.col).reduce(max);
        expect(shape.height, maxRow + 1);
        expect(shape.width, maxCol + 1);
        expect(shape.cellCount, shape.cells.length);
      }
    });

    test('catalog contains all minimum required shapes', () {
      final ids = BlockPuzzleEngine.standardShapes.map((s) => s.id).toSet();
      expect(ids.contains('dot_1x1'), isTrue); // 1. Single cell
      expect(ids.contains('line_1x2'), isTrue); // 2. 2-cell horizontal line
      expect(ids.contains('line_2x1'), isTrue); // 3. 2-cell vertical line
      expect(ids.contains('line_1x3'), isTrue); // 4. 3-cell horizontal line
      expect(ids.contains('line_3x1'), isTrue); // 5. 3-cell vertical line
      expect(ids.contains('line_1x4'), isTrue); // 6. 4-cell horizontal line
      expect(ids.contains('line_4x1'), isTrue); // 7. 4-cell vertical line
      expect(ids.contains('line_1x5'), isTrue); // 8. 5-cell horizontal line
      expect(ids.contains('line_5x1'), isTrue); // 9. 5-cell vertical line
      expect(ids.contains('square_2x2'), isTrue); // 10. Small square
      expect(ids.contains('square_3x3'), isTrue); // 11. Larger square
      expect(ids.contains('corner_tl'), isTrue); // 12. Corner / L
      expect(ids.contains('L_3x3_bl'), isTrue); // 13. L-shape 3x3
      expect(ids.contains('T_down'), isTrue); // 14. T-shape
    });
  });

  group('BlockPuzzleEngine - Placement Validation', () {
    test('legal placement succeeds on empty board', () {
      final board = engine.createEmptyBoard();
      const dotShape = BlockShape(
        id: 'dot',
        name: 'Dot',
        cells: [BlockCoordinate(0, 0)],
        color: Color(0xFFF59E0B),
      );

      expect(engine.canPlacePiece(board, dotShape, 0, 0), isTrue);
      expect(engine.canPlacePiece(board, dotShape, 9, 9), isTrue);
      expect(engine.canPlacePiece(board, dotShape, 4, 5), isTrue);

      final result = engine.placePiece(board, dotShape, 4, 5);
      expect(result.placedPoints, 1);
      expect(result.clearedPoints, 0);
      expect(result.bonusPoints, 0);
      expect(result.totalScoreEarned, 1);
      expect(result.newBoard[4 * 10 + 5], dotShape.color.toARGB32());
    });

    test('overlapping placement is rejected', () {
      final board = engine.createEmptyBoard();
      const dotShape = BlockShape(
        id: 'dot',
        name: 'Dot',
        cells: [BlockCoordinate(0, 0)],
        color: Color(0xFFF59E0B),
      );

      final firstResult = engine.placePiece(board, dotShape, 2, 3);
      expect(
        engine.canPlacePiece(firstResult.newBoard, dotShape, 2, 3),
        isFalse,
      );
      expect(
        () => engine.placePiece(firstResult.newBoard, dotShape, 2, 3),
        throwsArgumentError,
      );
    });

    test('out-of-bounds placement is rejected', () {
      final board = engine.createEmptyBoard();
      const lineShape = BlockShape(
        id: 'line_1x3',
        name: 'Line 3H',
        cells: [
          BlockCoordinate(0, 0),
          BlockCoordinate(0, 1),
          BlockCoordinate(0, 2),
        ],
        color: Color(0xFF10B981),
      );

      // Col 8 with width 3 reaches col 10 (out of bounds)
      expect(engine.canPlacePiece(board, lineShape, 0, 8), isFalse);
      expect(engine.canPlacePiece(board, lineShape, 0, 9), isFalse);
      expect(engine.canPlacePiece(board, lineShape, -1, 0), isFalse);
      expect(engine.canPlacePiece(board, lineShape, 0, -1), isFalse);
      expect(engine.canPlacePiece(board, lineShape, 10, 0), isFalse);
      expect(
        () => engine.placePiece(board, lineShape, 0, 8),
        throwsArgumentError,
      );
    });
  });

  group('BlockPuzzleEngine - Line Clearing and Scoring', () {
    test('single completed row is cleared and scored correctly', () {
      final board = engine.createEmptyBoard();
      // Pre-fill row 3 except last cell (col 9)
      for (int c = 0; c < 9; c++) {
        board[3 * 10 + c] = 0xFFFFFFFF;
      }

      const dot = BlockShape(
        id: 'dot',
        name: 'Dot',
        cells: [BlockCoordinate(0, 0)],
        color: Color(0xFFF59E0B),
      );

      // Place dot at (3, 9) to complete row 3
      final result = engine.placePiece(board, dot, 3, 9);
      expect(result.clearedRowsCount, 1);
      expect(result.clearedColsCount, 0);
      expect(result.clearedCellIndices.length, 10);
      // Entire row 3 is cleared back to empty
      for (int c = 0; c < 10; c++) {
        expect(result.newBoard[3 * 10 + c], BlockPuzzleEngine.emptyCell);
      }
      // Placed: 1 pt. Cleared: 10 pts. Bonus: 0 (only 1 line). Total: 11
      expect(result.placedPoints, 1);
      expect(result.clearedPoints, 10);
      expect(result.bonusPoints, 0);
      expect(result.totalScoreEarned, 11);
    });

    test('single completed column is cleared and scored correctly', () {
      final board = engine.createEmptyBoard();
      // Pre-fill col 4 except row 9
      for (int r = 0; r < 9; r++) {
        board[r * 10 + 4] = 0xFFFFFFFF;
      }

      const dot = BlockShape(
        id: 'dot',
        name: 'Dot',
        cells: [BlockCoordinate(0, 0)],
        color: Color(0xFFF59E0B),
      );

      final result = engine.placePiece(board, dot, 9, 4);
      expect(result.clearedRowsCount, 0);
      expect(result.clearedColsCount, 1);
      expect(result.clearedCellIndices.length, 10);
      for (int r = 0; r < 10; r++) {
        expect(result.newBoard[r * 10 + 4], BlockPuzzleEngine.emptyCell);
      }
      expect(result.placedPoints, 1);
      expect(result.clearedPoints, 10);
      expect(result.bonusPoints, 0);
      expect(result.totalScoreEarned, 11);
    });

    test('multiple rows cleared in one move awards multi-line bonus', () {
      final board = engine.createEmptyBoard();
      // Pre-fill rows 2 and 3 except col 0
      for (int c = 1; c < 10; c++) {
        board[2 * 10 + c] = 0xFFFFFFFF;
        board[3 * 10 + c] = 0xFFFFFFFF;
      }

      // Vertical 2-cell piece at (2, 0)
      const line2V = BlockShape(
        id: 'line_2x1',
        name: 'Line 2V',
        cells: [BlockCoordinate(0, 0), BlockCoordinate(1, 0)],
        color: Color(0xFF3B82F6),
      );

      final result = engine.placePiece(board, line2V, 2, 0);
      expect(result.clearedRowsCount, 2);
      expect(result.clearedColsCount, 0);
      expect(result.clearedCellIndices.length, 20);
      // Placed: 2 pts. Cleared: 20 pts. Bonus: (2 - 1) * 10 = 10 pts. Total: 32 pts
      expect(result.placedPoints, 2);
      expect(result.clearedPoints, 20);
      expect(result.bonusPoints, 10);
      expect(result.totalScoreEarned, 32);
    });

    test('multiple columns cleared in one move awards multi-line bonus', () {
      final board = engine.createEmptyBoard();
      // Pre-fill cols 5 and 6 except row 0
      for (int r = 1; r < 10; r++) {
        board[r * 10 + 5] = 0xFFFFFFFF;
        board[r * 10 + 6] = 0xFFFFFFFF;
      }

      // Horizontal 2-cell piece at (0, 5)
      const line2H = BlockShape(
        id: 'line_1x2',
        name: 'Line 2H',
        cells: [BlockCoordinate(0, 0), BlockCoordinate(0, 1)],
        color: Color(0xFF3B82F6),
      );

      final result = engine.placePiece(board, line2H, 0, 5);
      expect(result.clearedRowsCount, 0);
      expect(result.clearedColsCount, 2);
      expect(result.clearedCellIndices.length, 20);
      expect(result.placedPoints, 2);
      expect(result.clearedPoints, 20);
      expect(result.bonusPoints, 10);
      expect(result.totalScoreEarned, 32);
    });

    test('simultaneous row and column clearing deduplicates intersection', () {
      final board = engine.createEmptyBoard();
      // Pre-fill row 4 (except col 4) and col 4 (except row 4)
      for (int c = 0; c < 10; c++) {
        if (c != 4) board[4 * 10 + c] = 0xFFFFFFFF;
      }
      for (int r = 0; r < 10; r++) {
        if (r != 4) board[r * 10 + 4] = 0xFFFFFFFF;
      }

      const dot = BlockShape(
        id: 'dot',
        name: 'Dot',
        cells: [BlockCoordinate(0, 0)],
        color: Color(0xFFF59E0B),
      );

      final result = engine.placePiece(board, dot, 4, 4);
      expect(result.clearedRowsCount, 1);
      expect(result.clearedColsCount, 1);

      // Intersection at (4, 4) must NOT be counted twice!
      // Total unique cleared cells: 10 + 10 - 1 = 19
      expect(result.clearedCellIndices.length, 19);
      expect(result.placedPoints, 1);
      expect(result.clearedPoints, 19);
      // Total lines = 2 -> bonus = (2 - 1) * 10 = 10
      expect(result.bonusPoints, 10);
      expect(result.totalScoreEarned, 30);
    });

    test('non-cleared rows and columns remain untouched and intact', () {
      final board = engine.createEmptyBoard();
      // Put a sentinel value at (0, 0)
      board[0] = 0x12345678;

      // Fill row 9 except col 9
      for (int c = 0; c < 9; c++) {
        board[9 * 10 + c] = 0xFFFFFFFF;
      }

      const dot = BlockShape(
        id: 'dot',
        name: 'Dot',
        cells: [BlockCoordinate(0, 0)],
        color: Color(0xFFF59E0B),
      );

      final result = engine.placePiece(board, dot, 9, 9);
      expect(result.clearedRowsCount, 1);
      // Row 9 is cleared, but cell (0, 0) is still intact
      expect(result.newBoard[0], 0x12345678);
    });
  });

  group('BlockPuzzleEngine - Game Over Detection', () {
    test('hasAnyValidPlacement returns true when empty space fits shape', () {
      final board = engine.createEmptyBoard();
      const dot = BlockShape(
        id: 'dot',
        name: 'Dot',
        cells: [BlockCoordinate(0, 0)],
        color: Color(0xFFF59E0B),
      );
      expect(engine.hasAnyValidPlacement(board, dot), isTrue);

      // Completely full board
      final fullBoard = List.filled(100, 0xFFFFFFFF);
      expect(engine.hasAnyValidPlacement(fullBoard, dot), isFalse);
    });

    test(
      'game is not over if at least one available piece can legally fit',
      () {
        // Board with only cell (0, 0) free
        final board = List.filled(100, 0xFFFFFFFF);
        board[0] = BlockPuzzleEngine.emptyCell;

        const dot = BlockShape(
          id: 'dot',
          name: 'Dot',
          cells: [BlockCoordinate(0, 0)],
          color: Color(0xFFF59E0B),
        );
        const line5 = BlockShape(
          id: 'line_1x5',
          name: 'Line 5H',
          cells: [
            BlockCoordinate(0, 0),
            BlockCoordinate(0, 1),
            BlockCoordinate(0, 2),
            BlockCoordinate(0, 3),
            BlockCoordinate(0, 4),
          ],
          color: Color(0xFF8B5CF6),
        );

        final pieces = [
          const BlockPiece(instanceId: 'p1', shape: line5), // cannot fit
          const BlockPiece(instanceId: 'p2', shape: dot), // can fit!
        ];

        expect(engine.isGameOver(board, pieces), isFalse);
      },
    );

    test('game is over when NO available piece can legally fit', () {
      // Board with only 1 empty cell at (0, 0)
      final board = List.filled(100, 0xFFFFFFFF);
      board[0] = BlockPuzzleEngine.emptyCell;

      const line2 = BlockShape(
        id: 'line_1x2',
        name: 'Line 2H',
        cells: [BlockCoordinate(0, 0), BlockCoordinate(0, 1)],
        color: Color(0xFF3B82F6),
      );

      final pieces = [
        const BlockPiece(
          instanceId: 'p1',
          shape: line2,
        ), // requires 2 adjacent cells
        const BlockPiece(instanceId: 'p2', shape: line2),
      ];

      expect(engine.isGameOver(board, pieces), isTrue);
    });

    test(
      'game is not over when all pieces are already used (awaiting replenishment)',
      () {
        final board = List.filled(100, 0xFFFFFFFF);
        const dot = BlockShape(
          id: 'dot',
          name: 'Dot',
          cells: [BlockCoordinate(0, 0)],
          color: Color(0xFFF59E0B),
        );

        final pieces = [
          const BlockPiece(instanceId: 'p1', shape: dot, isUsed: true),
          const BlockPiece(instanceId: 'p2', shape: dot, isUsed: true),
          const BlockPiece(instanceId: 'p3', shape: dot, isUsed: true),
        ];

        expect(engine.isGameOver(board, pieces), isFalse);
      },
    );
  });

  group('BlockPuzzleEngine - Generation and Pieces', () {
    test('generateNewPieces creates specified count of active pieces', () {
      final pieces = engine.generateNewPieces(count: 3);
      expect(pieces.length, 3);
      for (final piece in pieces) {
        expect(piece.isUsed, isFalse);
        expect(piece.instanceId, isNotEmpty);
        expect(piece.shape, isNotNull);
      }
    });
  });
}
