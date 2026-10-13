import 'dart:math';
import 'word_search_dictionary.dart';
import 'word_search_models.dart';

/// Pure Dart domain engine for Word Search grid generation,
/// straight-line coordinate calculation, and word matching.
///
/// Contains zero dependencies on Flutter widgets, Cubit, or storage.
class WordSearchEngine {
  final WordSearchDictionary _dictionary;
  final Random _defaultRandom;

  WordSearchEngine({WordSearchDictionary? dictionary, Random? random})
    : _dictionary = dictionary ?? WordSearchDictionary(),
      _defaultRandom = random ?? Random();

  /// Calculates a list of coordinates forming a straight line between [start]
  /// and [end] (horizontal, vertical, or 45-degree diagonal).
  ///
  /// Returns `null` if the selection is not a straight line.
  List<GridCoordinate>? getStraightLineCoordinates(
    GridCoordinate start,
    GridCoordinate end,
  ) {
    final dRow = end.row - start.row;
    final dCol = end.col - start.col;

    // Single cell selection
    if (dRow == 0 && dCol == 0) {
      return [start];
    }

    final isHorizontal = dRow == 0 && dCol != 0;
    final isVertical = dCol == 0 && dRow != 0;
    final isDiagonal = dRow.abs() == dCol.abs();

    if (!isHorizontal && !isVertical && !isDiagonal) {
      return null;
    }

    final stepRow = dRow == 0 ? 0 : (dRow > 0 ? 1 : -1);
    final stepCol = dCol == 0 ? 0 : (dCol > 0 ? 1 : -1);
    final steps = max(dRow.abs(), dCol.abs());

    final coordinates = <GridCoordinate>[];
    for (int i = 0; i <= steps; i++) {
      coordinates.add(
        GridCoordinate(start.row + i * stepRow, start.col + i * stepCol),
      );
    }

    return coordinates;
  }

  /// Extracts the string along the given [coordinates] from [grid].
  String extractStringFromGrid(
    List<List<String>> grid,
    List<GridCoordinate> coordinates,
  ) {
    final buffer = StringBuffer();
    for (final coord in coordinates) {
      if (coord.row >= 0 &&
          coord.row < grid.length &&
          coord.col >= 0 &&
          coord.col < grid[0].length) {
        buffer.write(grid[coord.row][coord.col]);
      }
    }
    return buffer.toString().toUpperCase();
  }

  /// Evaluates whether the letters formed along [coordinates] match any
  /// un-found word in [targetWords] in either forward or reverse direction.
  ///
  /// Returns the matching target word string if found, or `null`.
  String? checkSelectionMatch({
    required List<List<String>> grid,
    required List<GridCoordinate> coordinates,
    required List<String> targetWords,
    required Set<String> alreadyFoundWords,
  }) {
    if (coordinates.isEmpty) return null;

    final forward = extractStringFromGrid(grid, coordinates);
    final reverse = forward.split('').reversed.join();

    for (final target in targetWords) {
      final normalizedTarget = target.toUpperCase();
      if (alreadyFoundWords.contains(normalizedTarget)) {
        continue;
      }

      if (forward == normalizedTarget || reverse == normalizedTarget) {
        return normalizedTarget;
      }
    }

    return null;
  }

  /// Verifies whether [word] can be legally placed at [start] along [direction]
  /// on [grid], respecting bounds and allowing compatible overlaps.
  bool canPlaceWord(
    List<List<String?>> grid,
    String word,
    GridCoordinate start,
    WordDirection direction,
  ) {
    final size = grid.length;
    final endRow = start.row + direction.deltaRow * (word.length - 1);
    final endCol = start.col + direction.deltaCol * (word.length - 1);

    if (start.row < 0 ||
        start.row >= size ||
        start.col < 0 ||
        start.col >= size ||
        endRow < 0 ||
        endRow >= size ||
        endCol < 0 ||
        endCol >= size) {
      return false;
    }

    for (int i = 0; i < word.length; i++) {
      final r = start.row + direction.deltaRow * i;
      final c = start.col + direction.deltaCol * i;
      final existingLetter = grid[r][c];

      if (existingLetter != null && existingLetter != word[i]) {
        return false; // Conflicting letter
      }
    }

    return true;
  }

  /// Generates a complete, verified [WordSearchPuzzle] at [difficulty].
  ///
  /// Accepts an optional [random] generator for deterministic testing.
  WordSearchPuzzle generatePuzzle({
    required WordSearchDifficulty difficulty,
    List<String>? candidateWords,
    Random? random,
    int maxPlacementAttemptsPerWord = 150,
    int maxPuzzleRetries = 10,
  }) {
    final rng = random ?? _defaultRandom;
    final size = difficulty.gridSize;
    final targetCount = difficulty.targetWordCount;

    // Retrieve or sanitize candidate words
    final availableWords =
        (candidateWords ?? _dictionary.getCandidatesForDifficulty(difficulty))
            .map((w) => w.trim().toUpperCase())
            .where(
              (w) =>
                  w.length >= difficulty.minWordLength &&
                  w.length <= difficulty.maxWordLength &&
                  w.length <= size,
            )
            .toSet()
            .toList();

    for (int retry = 0; retry < maxPuzzleRetries; retry++) {
      final grid = List.generate(size, (_) => List<String?>.filled(size, null));
      final placedWords = <PlacedWord>[];
      final pool = List<String>.from(availableWords)..shuffle(rng);

      while (placedWords.length < targetCount && pool.isNotEmpty) {
        final word = pool.removeAt(0);
        final placed = _attemptPlaceWord(
          grid: grid,
          word: word,
          allowedDirections: difficulty.allowedDirections,
          rng: rng,
          maxAttempts: maxPlacementAttemptsPerWord,
        );

        if (placed != null) {
          placedWords.add(placed);
        }
      }

      // If we reached the target word count, finalize and return
      if (placedWords.length >= targetCount) {
        return _finalizePuzzle(
          grid: grid,
          placedWords: placedWords,
          difficulty: difficulty,
          rng: rng,
        );
      }
    }

    // Fallback: If placement was constrained, try one more pass and return
    // whatever words were successfully placed (ensuring no absent target words)
    final grid = List.generate(size, (_) => List<String?>.filled(size, null));
    final placedWords = <PlacedWord>[];
    final pool = List<String>.from(availableWords)..shuffle(rng);

    while (placedWords.length < targetCount && pool.isNotEmpty) {
      final word = pool.removeAt(0);
      final placed = _attemptPlaceWord(
        grid: grid,
        word: word,
        allowedDirections: difficulty.allowedDirections,
        rng: rng,
        maxAttempts: maxPlacementAttemptsPerWord * 2,
      );

      if (placed != null) {
        placedWords.add(placed);
      }
    }

    return _finalizePuzzle(
      grid: grid,
      placedWords: placedWords,
      difficulty: difficulty,
      rng: rng,
    );
  }

  PlacedWord? _attemptPlaceWord({
    required List<List<String?>> grid,
    required String word,
    required List<WordDirection> allowedDirections,
    required Random rng,
    required int maxAttempts,
  }) {
    final size = grid.length;
    final directions = List<WordDirection>.from(allowedDirections);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final direction = directions[rng.nextInt(directions.length)];

      // Calculate legal start ranges based on direction vector
      final minRow = direction.deltaRow < 0 ? word.length - 1 : 0;
      final maxRow = direction.deltaRow > 0 ? size - word.length : size - 1;

      final minCol = direction.deltaCol < 0 ? word.length - 1 : 0;
      final maxCol = direction.deltaCol > 0 ? size - word.length : size - 1;

      if (maxRow < minRow || maxCol < minCol) continue;

      final startRow = minRow + rng.nextInt(maxRow - minRow + 1);
      final startCol = minCol + rng.nextInt(maxCol - minCol + 1);
      final start = GridCoordinate(startRow, startCol);

      if (canPlaceWord(grid, word, start, direction)) {
        final coordinates = <GridCoordinate>[];
        for (int i = 0; i < word.length; i++) {
          final r = start.row + direction.deltaRow * i;
          final c = start.col + direction.deltaCol * i;
          grid[r][c] = word[i];
          coordinates.add(GridCoordinate(r, c));
        }

        final end = coordinates.last;
        return PlacedWord(
          word: word,
          start: start,
          end: end,
          direction: direction,
          coordinates: coordinates,
        );
      }
    }

    return null;
  }

  WordSearchPuzzle _finalizePuzzle({
    required List<List<String?>> grid,
    required List<PlacedWord> placedWords,
    required WordSearchDifficulty difficulty,
    required Random rng,
  }) {
    final size = grid.length;
    final finalizedGrid = List.generate(
      size,
      (r) => List.generate(size, (c) {
        final letter = grid[r][c];
        if (letter != null) return letter;
        // Random uppercase letter A-Z
        return String.fromCharCode(65 + rng.nextInt(26));
      }),
    );

    final targetWords = placedWords.map((pw) => pw.word).toList()..sort();

    return WordSearchPuzzle(
      grid: finalizedGrid,
      targetWords: targetWords,
      placedWords: placedWords,
      difficulty: difficulty,
    );
  }

  /// Checks whether all target words have been found.
  bool isPuzzleCompleted({
    required List<String> targetWords,
    required List<FoundWord> foundWords,
  }) {
    if (targetWords.isEmpty) return false;
    final foundSet = foundWords.map((f) => f.word.toUpperCase()).toSet();
    return targetWords.every((w) => foundSet.contains(w.toUpperCase()));
  }
}
