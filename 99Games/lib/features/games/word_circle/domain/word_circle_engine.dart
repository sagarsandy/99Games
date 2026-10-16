import 'word_circle_dictionary.dart';
import 'word_circle_models.dart';

/// Exception thrown when a level definition violates puzzle constraints.
class WordCircleValidationException implements Exception {
  final String message;
  const WordCircleValidationException(this.message);

  @override
  String toString() => 'WordCircleValidationException: $message';
}

/// Core domain engine for Word Circle puzzle rules, crossword grid mapping,
/// word validation, scoring, and level completion.
class WordCircleEngine {
  const WordCircleEngine();

  /// Submits and evaluates a word formed by the player.
  WordCircleSubmissionResult submitWord({
    required String rawWord,
    required WordCircleLevel level,
    required Set<String> foundTargetWords,
    required Set<String> foundBonusWords,
  }) {
    final word = rawWord.trim().toUpperCase();

    if (word.length < WordCircleDictionary.minWordLength) {
      return WordCircleSubmissionResult(
        status: WordSubmissionStatus.tooShort,
        word: word,
        message:
            'Too short (min ${WordCircleDictionary.minWordLength} letters)',
      );
    }

    // 1. Check if word is one of the target words for this level
    TargetWord? matchedTarget;
    for (final target in level.targetWords) {
      if (target.word.toUpperCase() == word) {
        matchedTarget = target;
        break;
      }
    }

    if (matchedTarget != null) {
      if (foundTargetWords.contains(word)) {
        return WordCircleSubmissionResult(
          status: WordSubmissionStatus.alreadyFound,
          word: word,
          message: 'Already found!',
          matchedTarget: matchedTarget,
        );
      }

      final points = word.length * 10;
      return WordCircleSubmissionResult(
        status: WordSubmissionStatus.newTarget,
        word: word,
        message: 'Target word! +$points',
        pointsEarned: points,
        matchedTarget: matchedTarget,
      );
    }

    // 2. Check if word is a valid bonus word
    if (WordCircleDictionary.isValidWord(word)) {
      if (!isWordFormableFromLetters(word, level.letters)) {
        return WordCircleSubmissionResult(
          status: WordSubmissionStatus.invalidWord,
          word: word,
          message: 'Not on the wheel',
        );
      }

      if (foundBonusWords.contains(word)) {
        return WordCircleSubmissionResult(
          status: WordSubmissionStatus.alreadyFound,
          word: word,
          message: 'Already found!',
        );
      }

      final points = word.length * 5;
      return WordCircleSubmissionResult(
        status: WordSubmissionStatus.newBonus,
        word: word,
        message: 'Bonus word! +$points',
        pointsEarned: points,
      );
    }

    // 3. Invalid word
    return WordCircleSubmissionResult(
      status: WordSubmissionStatus.invalidWord,
      word: word,
      message: 'Not in word list',
    );
  }

  /// Evaluates whether all target words for [level] have been discovered.
  bool isLevelComplete(WordCircleLevel level, Set<String> foundTargetWords) {
    if (level.targetWords.isEmpty) return false;
    for (final target in level.targetWords) {
      if (!foundTargetWords.contains(target.word.toUpperCase())) {
        return false;
      }
    }
    return true;
  }

  /// Builds a map of all crossword cells for the current level state.
  /// Keys are formatted as `'row,col'`.
  Map<String, CrosswordCell> generateCrosswordGrid({
    required WordCircleLevel level,
    required Set<String> foundTargetWords,
    required Set<String> hintedCellKeys,
  }) {
    final cellMap = <String, CrosswordCell>{};

    for (final target in level.targetWords) {
      final isWordFound = foundTargetWords.contains(target.word.toUpperCase());

      for (int i = 0; i < target.length; i++) {
        final r = target.isHorizontal ? target.row : target.row + i;
        final c = target.isHorizontal ? target.col + i : target.col;
        final key = '$r,$c';
        final char = target.word[i].toUpperCase();

        final isHinted = hintedCellKeys.contains(key);
        final isRevealed = isWordFound;

        if (cellMap.containsKey(key)) {
          final existing = cellMap[key]!;
          cellMap[key] = existing.copyWith(
            isRevealed: existing.isRevealed || isRevealed,
            isHinted: existing.isHinted || isHinted,
            targetWordIds: {...existing.targetWordIds, target.id},
          );
        } else {
          cellMap[key] = CrosswordCell(
            row: r,
            col: c,
            letter: char,
            isRevealed: isRevealed,
            isHinted: isHinted,
            targetWordIds: {target.id},
          );
        }
      }
    }

    return cellMap;
  }

  /// Finds the next unrevealed, unhinted cell key (`'row,col'`) to reveal as a hint.
  String? getNextHintCell({
    required WordCircleLevel level,
    required Set<String> foundTargetWords,
    required Set<String> hintedCellKeys,
  }) {
    final grid = generateCrosswordGrid(
      level: level,
      foundTargetWords: foundTargetWords,
      hintedCellKeys: hintedCellKeys,
    );

    for (final target in level.targetWords) {
      if (foundTargetWords.contains(target.word.toUpperCase())) continue;

      for (int i = 0; i < target.length; i++) {
        final r = target.isHorizontal ? target.row : target.row + i;
        final c = target.isHorizontal ? target.col + i : target.col;
        final key = '$r,$c';

        final cell = grid[key];
        if (cell != null && !cell.isRevealed && !cell.isHinted) {
          return key;
        }
      }
    }

    return null;
  }

  /// Verifies whether [word] can be formed from available [letters]
  /// without using any letter position more than once.
  bool isWordFormableFromLetters(String word, List<String> letters) {
    final available = letters.map((l) => l.toUpperCase()).toList();
    final chars = word.toUpperCase().split('');

    for (final ch in chars) {
      final idx = available.indexOf(ch);
      if (idx == -1) return false;
      available.removeAt(idx);
    }
    return true;
  }

  /// Validates that a [level] adheres strictly to puzzle integrity rules.
  void validateLevel(WordCircleLevel level) {
    if (level.targetWords.isEmpty) {
      throw WordCircleValidationException(
        'Level ${level.id} has no target words',
      );
    }

    final grid = <String, String>{};

    for (final target in level.targetWords) {
      final upperWord = target.word.toUpperCase();

      // 1. Must be formable from letters
      if (!isWordFormableFromLetters(upperWord, level.letters)) {
        throw WordCircleValidationException(
          'Level ${level.id}: Target word "$upperWord" cannot be formed from letters ${level.letters}',
        );
      }

      // 2. Must be in dictionary
      if (!WordCircleDictionary.isValidWord(upperWord)) {
        throw WordCircleValidationException(
          'Level ${level.id}: Target word "$upperWord" is not in dictionary',
        );
      }

      // 3. Grid bounds
      for (int i = 0; i < target.length; i++) {
        final r = target.isHorizontal ? target.row : target.row + i;
        final c = target.isHorizontal ? target.col + i : target.col;
        final ch = upperWord[i];

        if (r < 0 || r >= level.rows || c < 0 || c >= level.cols) {
          throw WordCircleValidationException(
            'Level ${level.id}: Target word "$upperWord" extends out of bounds at ($r, $c)',
          );
        }

        final key = '$r,$c';
        if (grid.containsKey(key)) {
          if (grid[key] != ch) {
            throw WordCircleValidationException(
              'Level ${level.id}: Crossword conflict at ($r, $c): "${grid[key]}" vs "$ch"',
            );
          }
        } else {
          grid[key] = ch;
        }
      }
    }
  }
}
