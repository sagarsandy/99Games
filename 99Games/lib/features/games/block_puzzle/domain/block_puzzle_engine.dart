import 'dart:math';
import 'package:flutter/material.dart';
import 'block_puzzle_models.dart';

/// Pure Dart game engine for the 10x10 Block Puzzle.
class BlockPuzzleEngine {
  final Random _random;
  int _instanceCounter = 0;

  BlockPuzzleEngine({Random? random}) : _random = random ?? Random();

  static const int gridSize = 10;
  static const int totalCells = 100;
  static const int emptyCell = 0;

  /// Standard block puzzle shape catalog.
  static final List<BlockShape> standardShapes = [
    // 1. Single cell (1x1)
    const BlockShape(
      id: 'dot_1x1',
      name: 'Single',
      cells: [BlockCoordinate(0, 0)],
      color: Color(0xFFF59E0B), // Amber
    ),

    // 2. 2-cell horizontal line (1x2)
    const BlockShape(
      id: 'line_1x2',
      name: 'Line 2H',
      cells: [BlockCoordinate(0, 0), BlockCoordinate(0, 1)],
      color: Color(0xFF3B82F6), // Blue
    ),

    // 3. 2-cell vertical line (2x1)
    const BlockShape(
      id: 'line_2x1',
      name: 'Line 2V',
      cells: [BlockCoordinate(0, 0), BlockCoordinate(1, 0)],
      color: Color(0xFF3B82F6), // Blue
    ),

    // 4. 3-cell horizontal line (1x3)
    const BlockShape(
      id: 'line_1x3',
      name: 'Line 3H',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(0, 1),
        BlockCoordinate(0, 2),
      ],
      color: Color(0xFF10B981), // Emerald
    ),

    // 5. 3-cell vertical line (3x1)
    const BlockShape(
      id: 'line_3x1',
      name: 'Line 3V',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(1, 0),
        BlockCoordinate(2, 0),
      ],
      color: Color(0xFF10B981), // Emerald
    ),

    // 6. 4-cell horizontal line (1x4)
    const BlockShape(
      id: 'line_1x4',
      name: 'Line 4H',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(0, 1),
        BlockCoordinate(0, 2),
        BlockCoordinate(0, 3),
      ],
      color: Color(0xFF6366F1), // Indigo
    ),

    // 7. 4-cell vertical line (4x1)
    const BlockShape(
      id: 'line_4x1',
      name: 'Line 4V',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(1, 0),
        BlockCoordinate(2, 0),
        BlockCoordinate(3, 0),
      ],
      color: Color(0xFF6366F1), // Indigo
    ),

    // 8. 5-cell horizontal line (1x5)
    const BlockShape(
      id: 'line_1x5',
      name: 'Line 5H',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(0, 1),
        BlockCoordinate(0, 2),
        BlockCoordinate(0, 3),
        BlockCoordinate(0, 4),
      ],
      color: Color(0xFF8B5CF6), // Violet
    ),

    // 9. 5-cell vertical line (5x1)
    const BlockShape(
      id: 'line_5x1',
      name: 'Line 5V',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(1, 0),
        BlockCoordinate(2, 0),
        BlockCoordinate(3, 0),
        BlockCoordinate(4, 0),
      ],
      color: Color(0xFF8B5CF6), // Violet
    ),

    // 10. Small square (2x2)
    const BlockShape(
      id: 'square_2x2',
      name: 'Square 2x2',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(0, 1),
        BlockCoordinate(1, 0),
        BlockCoordinate(1, 1),
      ],
      color: Color(0xFFEC4899), // Pink
    ),

    // 11. Larger square (3x3)
    const BlockShape(
      id: 'square_3x3',
      name: 'Square 3x3',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(0, 1),
        BlockCoordinate(0, 2),
        BlockCoordinate(1, 0),
        BlockCoordinate(1, 1),
        BlockCoordinate(1, 2),
        BlockCoordinate(2, 0),
        BlockCoordinate(2, 1),
        BlockCoordinate(2, 2),
      ],
      color: Color(0xFFF43F5E), // Rose
    ),

    // 12. Small Corner L (2x2, 3 cells) - 4 orientations
    const BlockShape(
      id: 'corner_tl',
      name: 'Corner TL',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(0, 1),
        BlockCoordinate(1, 0),
      ],
      color: Color(0xFF06B6D4), // Cyan
    ),
    const BlockShape(
      id: 'corner_tr',
      name: 'Corner TR',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(0, 1),
        BlockCoordinate(1, 1),
      ],
      color: Color(0xFF06B6D4), // Cyan
    ),
    const BlockShape(
      id: 'corner_bl',
      name: 'Corner BL',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(1, 0),
        BlockCoordinate(1, 1),
      ],
      color: Color(0xFF06B6D4), // Cyan
    ),
    const BlockShape(
      id: 'corner_br',
      name: 'Corner BR',
      cells: [
        BlockCoordinate(0, 1),
        BlockCoordinate(1, 0),
        BlockCoordinate(1, 1),
      ],
      color: Color(0xFF06B6D4), // Cyan
    ),

    // 13. L-shaped pieces (3x3, 5 cells) - 4 orientations
    const BlockShape(
      id: 'L_3x3_bl',
      name: 'L 3x3 BL',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(1, 0),
        BlockCoordinate(2, 0),
        BlockCoordinate(2, 1),
        BlockCoordinate(2, 2),
      ],
      color: Color(0xFFF97316), // Orange
    ),
    const BlockShape(
      id: 'L_3x3_tl',
      name: 'L 3x3 TL',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(0, 1),
        BlockCoordinate(0, 2),
        BlockCoordinate(1, 0),
        BlockCoordinate(2, 0),
      ],
      color: Color(0xFFF97316), // Orange
    ),
    const BlockShape(
      id: 'L_3x3_tr',
      name: 'L 3x3 TR',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(0, 1),
        BlockCoordinate(0, 2),
        BlockCoordinate(1, 2),
        BlockCoordinate(2, 2),
      ],
      color: Color(0xFFF97316), // Orange
    ),
    const BlockShape(
      id: 'L_3x3_br',
      name: 'L 3x3 BR',
      cells: [
        BlockCoordinate(0, 2),
        BlockCoordinate(1, 2),
        BlockCoordinate(2, 0),
        BlockCoordinate(2, 1),
        BlockCoordinate(2, 2),
      ],
      color: Color(0xFFF97316), // Orange
    ),

    // 14. T-shaped pieces (4 cells) - 4 orientations
    const BlockShape(
      id: 'T_down',
      name: 'T Down',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(0, 1),
        BlockCoordinate(0, 2),
        BlockCoordinate(1, 1),
      ],
      color: Color(0xFF14B8A6), // Teal
    ),
    const BlockShape(
      id: 'T_up',
      name: 'T Up',
      cells: [
        BlockCoordinate(1, 0),
        BlockCoordinate(1, 1),
        BlockCoordinate(1, 2),
        BlockCoordinate(0, 1),
      ],
      color: Color(0xFF14B8A6), // Teal
    ),
    const BlockShape(
      id: 'T_right',
      name: 'T Right',
      cells: [
        BlockCoordinate(0, 0),
        BlockCoordinate(1, 0),
        BlockCoordinate(2, 0),
        BlockCoordinate(1, 1),
      ],
      color: Color(0xFF14B8A6), // Teal
    ),
    const BlockShape(
      id: 'T_left',
      name: 'T Left',
      cells: [
        BlockCoordinate(0, 1),
        BlockCoordinate(1, 1),
        BlockCoordinate(2, 1),
        BlockCoordinate(1, 0),
      ],
      color: Color(0xFF14B8A6), // Teal
    ),

    // 15. Plus shape (5 cells)
    const BlockShape(
      id: 'plus_3x3',
      name: 'Plus',
      cells: [
        BlockCoordinate(0, 1),
        BlockCoordinate(1, 0),
        BlockCoordinate(1, 1),
        BlockCoordinate(1, 2),
        BlockCoordinate(2, 1),
      ],
      color: Color(0xFFA855F7), // Purple
    ),
  ];

  /// Creates a fresh empty 10x10 board.
  List<int> createEmptyBoard() =>
      List.filled(totalCells, emptyCell, growable: false);

  /// Validates whether [shape] can be placed with its top-left anchor at ([anchorRow], [anchorCol]).
  bool canPlacePiece(
    List<int> board,
    BlockShape shape,
    int anchorRow,
    int anchorCol,
  ) {
    if (board.length != totalCells) return false;

    for (final cell in shape.cells) {
      final r = anchorRow + cell.row;
      final c = anchorCol + cell.col;

      if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) {
        return false; // Out of bounds
      }

      final index = r * gridSize + c;
      if (board[index] != emptyCell) {
        return false; // Already occupied
      }
    }
    return true;
  }

  /// Places [shape] onto [board] at ([anchorRow], [anchorCol]), clears any completed
  /// rows and columns, and computes the earned points.
  ///
  /// Throws [ArgumentError] if the placement is invalid.
  PlacementResult placePiece(
    List<int> board,
    BlockShape shape,
    int anchorRow,
    int anchorCol,
  ) {
    if (!canPlacePiece(board, shape, anchorRow, anchorCol)) {
      throw ArgumentError('Cannot place piece at ($anchorRow, $anchorCol)');
    }

    final newBoard = List<int>.from(board);
    final colorValue = shape.color.toARGB32();

    // 1. Stamp the piece cells onto the board
    for (final cell in shape.cells) {
      final r = anchorRow + cell.row;
      final c = anchorCol + cell.col;
      newBoard[r * gridSize + c] = colorValue;
    }

    // 2. Identify all completed rows
    final completedRows = <int>[];
    for (int r = 0; r < gridSize; r++) {
      bool isRowFull = true;
      for (int c = 0; c < gridSize; c++) {
        if (newBoard[r * gridSize + c] == emptyCell) {
          isRowFull = false;
          break;
        }
      }
      if (isRowFull) {
        completedRows.add(r);
      }
    }

    // 3. Identify all completed columns
    final completedCols = <int>[];
    for (int c = 0; c < gridSize; c++) {
      bool isColFull = true;
      for (int r = 0; r < gridSize; r++) {
        if (newBoard[r * gridSize + c] == emptyCell) {
          isColFull = false;
          break;
        }
      }
      if (isColFull) {
        completedCols.add(c);
      }
    }

    // 4. Collect unique cells to clear (properly handling intersections)
    final cellsToClear = <int>{};
    for (final r in completedRows) {
      for (int c = 0; c < gridSize; c++) {
        cellsToClear.add(r * gridSize + c);
      }
    }
    for (final c in completedCols) {
      for (int r = 0; r < gridSize; r++) {
        cellsToClear.add(r * gridSize + c);
      }
    }

    // Clear cells on the board
    for (final idx in cellsToClear) {
      newBoard[idx] = emptyCell;
    }

    // 5. Calculate score
    final placedPoints = shape.cellCount * 1;
    final clearedPoints = cellsToClear.length * 1;

    final totalLines = completedRows.length + completedCols.length;
    final bonusPoints = totalLines > 1 ? (totalLines - 1) * 10 : 0;
    final totalScoreEarned = placedPoints + clearedPoints + bonusPoints;

    return PlacementResult(
      newBoard: List.unmodifiable(newBoard),
      placedPoints: placedPoints,
      clearedPoints: clearedPoints,
      bonusPoints: bonusPoints,
      totalScoreEarned: totalScoreEarned,
      clearedRowsCount: completedRows.length,
      clearedColsCount: completedCols.length,
      clearedCellIndices: List.unmodifiable(cellsToClear),
    );
  }

  /// Checks if [shape] can be placed anywhere on [board].
  bool hasAnyValidPlacement(List<int> board, BlockShape shape) {
    for (int r = 0; r <= gridSize - shape.height; r++) {
      for (int c = 0; c <= gridSize - shape.width; c++) {
        if (canPlacePiece(board, shape, r, c)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Evaluates whether the game is over.
  /// Game is over ONLY if NONE of the remaining available pieces can legally fit.
  bool isGameOver(List<int> board, List<BlockPiece> pieces) {
    final remainingPieces = pieces.where((p) => !p.isUsed).toList();
    if (remainingPieces.isEmpty) {
      // If all pieces were used, new pieces will be generated, not game over.
      return false;
    }

    for (final piece in remainingPieces) {
      if (hasAnyValidPlacement(board, piece.shape)) {
        return false; // At least one piece can fit!
      }
    }

    return true; // None of the available pieces can fit anywhere!
  }

  /// Generates [count] random block pieces from [standardShapes].
  List<BlockPiece> generateNewPieces({int count = 3}) {
    final result = <BlockPiece>[];
    for (int i = 0; i < count; i++) {
      final shape = standardShapes[_random.nextInt(standardShapes.length)];
      _instanceCounter++;
      result.add(
        BlockPiece(
          instanceId:
              'piece_${_instanceCounter}_${DateTime.now().microsecondsSinceEpoch}',
          shape: shape,
        ),
      );
    }
    return List.unmodifiable(result);
  }
}
