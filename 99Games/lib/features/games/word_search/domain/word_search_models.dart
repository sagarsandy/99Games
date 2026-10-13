import 'package:equatable/equatable.dart';

/// Supported difficulty levels for Word Search.
enum WordSearchDifficulty {
  easy(
    label: 'Easy',
    gridSize: 8,
    targetWordCount: 6,
    minWordLength: 3,
    maxWordLength: 5,
    allowedDirections: [
      WordDirection.horizontalRight,
      WordDirection.horizontalLeft,
      WordDirection.verticalDown,
      WordDirection.verticalUp,
    ],
  ),
  medium(
    label: 'Medium',
    gridSize: 10,
    targetWordCount: 10,
    minWordLength: 4,
    maxWordLength: 7,
    allowedDirections: WordDirection.values,
  ),
  hard(
    label: 'Hard',
    gridSize: 12,
    targetWordCount: 15,
    minWordLength: 5,
    maxWordLength: 9,
    allowedDirections: WordDirection.values,
  );

  final String label;
  final int gridSize;
  final int targetWordCount;
  final int minWordLength;
  final int maxWordLength;
  final List<WordDirection> allowedDirections;

  const WordSearchDifficulty({
    required this.label,
    required this.gridSize,
    required this.targetWordCount,
    required this.minWordLength,
    required this.maxWordLength,
    required this.allowedDirections,
  });
}

/// A 0-indexed coordinate in the Word Search letter grid.
class GridCoordinate extends Equatable {
  final int row;
  final int col;

  const GridCoordinate(this.row, this.col);

  @override
  List<Object?> get props => [row, col];

  @override
  String toString() => '($row, $col)';
}

/// All eight straight-line word placement and selection directions.
enum WordDirection {
  horizontalRight(0, 1),
  horizontalLeft(0, -1),
  verticalDown(1, 0),
  verticalUp(-1, 0),
  diagonalDownRight(1, 1),
  diagonalUpLeft(-1, -1),
  diagonalDownLeft(1, -1),
  diagonalUpRight(-1, 1);

  final int deltaRow;
  final int deltaCol;

  const WordDirection(this.deltaRow, this.deltaCol);

  bool get isDiagonal => deltaRow != 0 && deltaCol != 0;
}

/// Represents a successfully placed target word within the letter grid.
class PlacedWord extends Equatable {
  final String word;
  final GridCoordinate start;
  final GridCoordinate end;
  final WordDirection direction;
  final List<GridCoordinate> coordinates;

  const PlacedWord({
    required this.word,
    required this.start,
    required this.end,
    required this.direction,
    required this.coordinates,
  });

  bool containsCoordinate(GridCoordinate coord) => coordinates.contains(coord);

  @override
  List<Object?> get props => [word, start, end, direction, coordinates];
}

/// Represents a target word discovered by the player.
class FoundWord extends Equatable {
  final String word;
  final List<GridCoordinate> coordinates;
  final int colorIndex;

  const FoundWord({
    required this.word,
    required this.coordinates,
    required this.colorIndex,
  });

  bool containsCoordinate(GridCoordinate coord) => coordinates.contains(coord);

  @override
  List<Object?> get props => [word, coordinates, colorIndex];
}

/// Complete representation of an immutable Word Search puzzle.
class WordSearchPuzzle extends Equatable {
  final List<List<String>> grid;
  final List<String> targetWords;
  final List<PlacedWord> placedWords;
  final WordSearchDifficulty difficulty;

  const WordSearchPuzzle({
    required this.grid,
    required this.targetWords,
    required this.placedWords,
    required this.difficulty,
  });

  int get size => grid.length;

  String getLetter(int row, int col) => grid[row][col];

  bool containsWord(String word) =>
      placedWords.any((pw) => pw.word.toUpperCase() == word.toUpperCase());

  @override
  List<Object?> get props => [grid, targetWords, placedWords, difficulty];
}
