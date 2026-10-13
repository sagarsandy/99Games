import 'dart:math';
import 'number_slide_models.dart';

/// Pure Dart game engine for the classic 15 Number Slide puzzle.
class NumberSlideEngine {
  final Random _random;

  NumberSlideEngine({Random? random}) : _random = random ?? Random();

  static const int gridSize = 4;
  static const int totalTiles = 16;
  static const int emptyTileValue = 0;

  /// The target solved board configuration: 1 to 15 followed by 0.
  static const List<int> solvedBoard = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    0,
  ];

  /// Returns true if [board] matches [solvedBoard].
  bool isSolved(List<int> board) {
    if (board.length != totalTiles) return false;
    for (int i = 0; i < totalTiles; i++) {
      if (board[i] != solvedBoard[i]) return false;
    }
    return true;
  }

  /// Finds the index of the empty cell (0). Returns -1 if not found.
  int getEmptyIndex(List<int> board) {
    return board.indexOf(emptyTileValue);
  }

  /// Checks if the tile at [tileIndex] can legally slide into the empty cell.
  bool canMove(List<int> board, int tileIndex) {
    if (tileIndex < 0 || tileIndex >= totalTiles) return false;
    if (board[tileIndex] == emptyTileValue) return false;

    final emptyIndex = getEmptyIndex(board);
    if (emptyIndex == -1) return false;

    final tileCoord = TileCoordinate.fromIndex(tileIndex);
    final emptyCoord = TileCoordinate.fromIndex(emptyIndex);

    return tileCoord.isAdjacentTo(emptyCoord);
  }

  /// Swaps the tile at [tileIndex] with the adjacent empty cell.
  ///
  /// Throws [ArgumentError] if the move is illegal.
  List<int> applyMove(List<int> board, int tileIndex) {
    if (!canMove(board, tileIndex)) {
      throw ArgumentError('Illegal move at index $tileIndex');
    }

    final emptyIndex = getEmptyIndex(board);
    final newBoard = List<int>.from(board);
    newBoard[emptyIndex] = newBoard[tileIndex];
    newBoard[tileIndex] = emptyTileValue;

    return List.unmodifiable(newBoard);
  }

  /// Returns indices of all tiles that can legally slide into the empty cell.
  List<int> getValidMoves(List<int> board) {
    final emptyIndex = getEmptyIndex(board);
    if (emptyIndex == -1) return const [];

    final emptyCoord = TileCoordinate.fromIndex(emptyIndex);
    final valid = <int>[];

    // Check 4 orthogonal neighbors
    final candidateCoords = [
      TileCoordinate(emptyCoord.row - 1, emptyCoord.col), // Above
      TileCoordinate(emptyCoord.row + 1, emptyCoord.col), // Below
      TileCoordinate(emptyCoord.row, emptyCoord.col - 1), // Left
      TileCoordinate(emptyCoord.row, emptyCoord.col + 1), // Right
    ];

    for (final coord in candidateCoords) {
      if (coord.row >= 0 &&
          coord.row < gridSize &&
          coord.col >= 0 &&
          coord.col < gridSize) {
        valid.add(coord.index);
      }
    }

    return valid;
  }

  /// Generates a solvable, scrambled board by performing a sequence of legal moves
  /// starting from [solvedBoard], actively avoiding immediate reversals.
  ///
  /// Guarantees:
  /// - Board is 100% solvable.
  /// - Board contains 1..15 and 0 exactly once.
  /// - Board is not already solved upon completion.
  List<int> generateSolvableBoard({int scrambleSteps = 120}) {
    List<int> currentBoard = List<int>.from(solvedBoard);
    int lastMovedValue = -1;

    for (int step = 0; step < scrambleSteps; step++) {
      final validMoves = getValidMoves(currentBoard);

      // Filter out moving back the tile that just moved, if alternative moves exist
      final filteredMoves = validMoves.where((index) {
        return currentBoard[index] != lastMovedValue;
      }).toList();

      final candidates = filteredMoves.isNotEmpty ? filteredMoves : validMoves;

      final chosenIndex = candidates[_random.nextInt(candidates.length)];
      lastMovedValue = currentBoard[chosenIndex];
      currentBoard = applyMove(currentBoard, chosenIndex);
    }

    // In the extremely rare event that the board ended up solved, nudge it
    if (isSolved(currentBoard)) {
      final valid = getValidMoves(currentBoard);
      final move1 = valid[_random.nextInt(valid.length)];
      currentBoard = applyMove(currentBoard, move1);
    }

    return List.unmodifiable(currentBoard);
  }

  /// Mathematical solvability validator for the 15-puzzle.
  ///
  /// A 4x4 puzzle is solvable if:
  /// - (blank row from bottom is odd && inversions is even) OR
  /// - (blank row from bottom is even && inversions is odd).
  bool isSolvable(List<int> board) {
    if (board.length != totalTiles) return false;

    // Verify all 0..15 numbers are present
    final seen = Set<int>.from(board);
    if (seen.length != totalTiles) return false;
    for (int i = 0; i < totalTiles; i++) {
      if (!seen.contains(i)) return false;
    }

    final emptyIndex = getEmptyIndex(board);
    final emptyRowFromTop = emptyIndex ~/ gridSize;
    final emptyRowFromBottom = gridSize - emptyRowFromTop; // 1-based (1..4)

    int inversions = 0;
    for (int i = 0; i < totalTiles; i++) {
      final a = board[i];
      if (a == emptyTileValue) continue;
      for (int j = i + 1; j < totalTiles; j++) {
        final b = board[j];
        if (b == emptyTileValue) continue;
        if (a > b) inversions++;
      }
    }

    final isBlankRowOdd = emptyRowFromBottom.isOdd;
    final isInvEven = inversions.isEven;

    return (isBlankRowOdd && isInvEven) || (!isBlankRowOdd && !isInvEven);
  }
}
