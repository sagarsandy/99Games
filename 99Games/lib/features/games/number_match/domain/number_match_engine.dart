import 'dart:math';
import 'number_match_models.dart';

/// Pure Dart game engine handling all rules, connections, validation,
/// hint discovery, and continuation logic for Classic Number Match / Take Ten.
class NumberMatchEngine {
  /// Number of columns per row in standard Take Ten / Number Match layout.
  static const int columns = 9;

  /// Default points awarded for clearing any valid pair.
  static const int pairScore = 10;

  /// Bonus points awarded when all 9 numbers in a row become completely cleared.
  static const int rowClearBonus = 10;

  /// Bonus points awarded upon successfully clearing the entire board (winning).
  static const int winBonus = 100;

  /// The classic deterministic 27-digit Take Ten sequence (1..9 followed by 11..19 without 0).
  static const List<int> classicTakeTenDigits = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, // Row 1 (1 to 9)
    1, 1, 1, 2, 1, 3, 1, 4, 1, // Row 2 (11 to 14, first digit of 15)
    5, 1, 6, 1, 7, 1, 8, 1, 9, // Row 3 (second digit of 15 to 19)
  ];

  const NumberMatchEngine();

  /// Calculates the 0-indexed row for a sequence index.
  int rowOf(int index) => index ~/ columns;

  /// Calculates the 0-indexed column for a sequence index.
  int colOf(int index) => index % columns;

  /// Total number of rows required to display the tiles.
  int totalRows(int tileCount) =>
      tileCount == 0 ? 0 : ((tileCount - 1) ~/ columns) + 1;

  /// Checks if two values form a valid pair: identical or sum to 10.
  bool isValueMatch(int a, int b) {
    if (a < 1 || a > 9 || b < 1 || b > 9) return false;
    return (a == b) || (a + b == 10);
  }

  /// Creates the classic deterministic Take Ten board with 27 tiles.
  List<NumberMatchTile> createClassicBoard() {
    return List.generate(
      classicTakeTenDigits.length,
      (i) => NumberMatchTile(
        id: i,
        value: classicTakeTenDigits[i],
        isCleared: false,
      ),
    );
  }

  /// Creates a randomized playable board with a guaranteed minimum number of valid pairs.
  List<NumberMatchTile> createRandomBoard({int rowCount = 3, Random? random}) {
    final rng = random ?? Random();
    final count = rowCount * columns;

    for (int attempt = 0; attempt < 50; attempt++) {
      final tiles = <NumberMatchTile>[];
      for (int i = 0; i < count; i++) {
        tiles.add(
          NumberMatchTile(id: i, value: rng.nextInt(9) + 1, isCleared: false),
        );
      }

      // Ensure at least 3 valid pairs exist to make the initial board engaging
      final pairs = findAllValidPairs(tiles);
      if (pairs.length >= 3) {
        return tiles;
      }
    }

    // Fallback to classic board if random attempts fail
    return createClassicBoard();
  }

  /// Validates whether the tiles at [indexA] and [indexB] form a legal match.
  MatchValidationResult validateMatch(
    int indexA,
    int indexB,
    List<NumberMatchTile> tiles,
  ) {
    if (indexA == indexB) {
      return MatchValidationResult.sameTile;
    }

    if (indexA < 0 ||
        indexA >= tiles.length ||
        indexB < 0 ||
        indexB >= tiles.length) {
      return MatchValidationResult.notConnected;
    }

    final tileA = tiles[indexA];
    final tileB = tiles[indexB];

    if (tileA.isCleared || tileB.isCleared) {
      return MatchValidationResult.alreadyCleared;
    }

    if (!isValueMatch(tileA.value, tileB.value)) {
      return MatchValidationResult.valuesDoNotMatch;
    }

    final i = min(indexA, indexB);
    final j = max(indexA, indexB);

    final rowI = rowOf(i);
    final colI = colOf(i);
    final rowJ = rowOf(j);
    final colJ = colOf(j);

    // 1. Sequential Line of Sight (Reading Order)
    // Connects adjacent numbers in reading order, row-boundary wraps,
    // and numbers with only cleared spaces between them.
    bool sequentialConnected = true;
    for (int k = i + 1; k < j; k++) {
      if (!tiles[k].isCleared) {
        sequentialConnected = false;
        break;
      }
    }
    if (sequentialConnected) {
      return MatchValidationResult.valid;
    }

    // 2. Vertical Line of Sight (Same Column)
    if (colI == colJ) {
      bool verticalConnected = true;
      for (int r = rowI + 1; r < rowJ; r++) {
        final idx = r * columns + colI;
        if (idx < tiles.length && !tiles[idx].isCleared) {
          verticalConnected = false;
          break;
        }
      }
      if (verticalConnected) {
        return MatchValidationResult.valid;
      }
    }

    // 3. Diagonal Line of Sight
    final dRow = rowJ - rowI;
    final dCol = colJ - colI;
    if (dRow > 0 && dRow == dCol.abs()) {
      final stepCol = dCol > 0 ? 1 : -1;
      bool diagonalConnected = true;
      for (int step = 1; step < dRow; step++) {
        final r = rowI + step;
        final c = colI + step * stepCol;
        final idx = r * columns + c;
        if (idx < tiles.length && !tiles[idx].isCleared) {
          diagonalConnected = false;
          break;
        }
      }
      if (diagonalConnected) {
        return MatchValidationResult.valid;
      }
    }

    // Check if path is along straight line but blocked
    final isStraightLine =
        (rowI == rowJ) || (colI == colJ) || (dRow > 0 && dRow == dCol.abs());
    if (isStraightLine) {
      return MatchValidationResult.blockedPath;
    }

    return MatchValidationResult.notConnected;
  }

  /// Checks whether two indices can connect and match.
  bool canMatch(int indexA, int indexB, List<NumberMatchTile> tiles) {
    return validateMatch(indexA, indexB, tiles).isValid;
  }

  /// Finds the first currently valid pair on the board (used for hints).
  NumberMatchPair? findFirstValidPair(List<NumberMatchTile> tiles) {
    final length = tiles.length;
    for (int i = 0; i < length; i++) {
      if (tiles[i].isCleared) continue;
      for (int j = i + 1; j < length; j++) {
        if (tiles[j].isCleared) continue;
        if (canMatch(i, j, tiles)) {
          return NumberMatchPair(i, j);
        }
      }
    }
    return null;
  }

  /// Finds all currently valid pairs on the board.
  List<NumberMatchPair> findAllValidPairs(List<NumberMatchTile> tiles) {
    final pairs = <NumberMatchPair>[];
    final length = tiles.length;
    for (int i = 0; i < length; i++) {
      if (tiles[i].isCleared) continue;
      for (int j = i + 1; j < length; j++) {
        if (tiles[j].isCleared) continue;
        if (canMatch(i, j, tiles)) {
          pairs.add(NumberMatchPair(i, j));
        }
      }
    }
    return pairs;
  }

  /// Appends copies of all remaining active (non-cleared) numbers
  /// to the end of the sequence with fresh IDs.
  ///
  /// Returns a record with the new list of tiles and the count of added tiles.
  ({List<NumberMatchTile> tiles, int addedCount}) addRemainingNumbers(
    List<NumberMatchTile> currentTiles,
  ) {
    final activeTiles = currentTiles.where((t) => !t.isCleared).toList();
    if (activeTiles.isEmpty) {
      return (tiles: List<NumberMatchTile>.from(currentTiles), addedCount: 0);
    }

    int nextId = currentTiles.isEmpty
        ? 0
        : (currentTiles.map((t) => t.id).reduce(max) + 1);

    final newTiles = List<NumberMatchTile>.from(currentTiles);
    for (final active in activeTiles) {
      newTiles.add(
        NumberMatchTile(id: nextId++, value: active.value, isCleared: false),
      );
    }

    return (tiles: newTiles, addedCount: activeTiles.length);
  }

  /// Checks if all cells in a given row are cleared.
  bool isRowCompletelyCleared(int rowIndex, List<NumberMatchTile> tiles) {
    final startIdx = rowIndex * columns;
    final endIdx = min(startIdx + columns, tiles.length);

    if (startIdx >= tiles.length) return false;
    // A complete row has [columns] cells
    if (endIdx - startIdx < columns) {
      // Partial row at the end of the sequence
      for (int i = startIdx; i < endIdx; i++) {
        if (!tiles[i].isCleared) return false;
      }
      return true;
    }

    for (int i = startIdx; i < endIdx; i++) {
      if (!tiles[i].isCleared) return false;
    }
    return true;
  }

  /// Calculates bonus points awarded for newly completed cleared rows.
  int calculateRowClearBonus({
    required int indexA,
    required int indexB,
    required List<NumberMatchTile> beforeTiles,
    required List<NumberMatchTile> afterTiles,
  }) {
    int bonus = 0;
    final rowA = rowOf(indexA);
    final rowB = rowOf(indexB);

    final checkedRows = <int>{rowA, rowB};
    for (final r in checkedRows) {
      final wasCleared = isRowCompletelyCleared(r, beforeTiles);
      final isNowCleared = isRowCompletelyCleared(r, afterTiles);
      if (!wasCleared && isNowCleared) {
        bonus += rowClearBonus;
      }
    }

    return bonus;
  }

  /// Returns true if all numbers on the board are cleared and board is non-empty.
  bool isGameWon(List<NumberMatchTile> tiles) {
    if (tiles.isEmpty) return false;
    return tiles.every((t) => t.isCleared);
  }

  /// Counts the total number of remaining active (uncleared) numbers.
  int activeNumberCount(List<NumberMatchTile> tiles) {
    return tiles.where((t) => !t.isCleared).length;
  }
}
