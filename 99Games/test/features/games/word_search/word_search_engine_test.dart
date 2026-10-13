import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/word_search/domain/word_search_dictionary.dart';
import 'package:mini_games_99/features/games/word_search/domain/word_search_engine.dart';
import 'package:mini_games_99/features/games/word_search/domain/word_search_models.dart';

void main() {
  late WordSearchEngine engine;
  late WordSearchDictionary dictionary;

  setUp(() {
    dictionary = WordSearchDictionary();
    engine = WordSearchEngine(dictionary: dictionary);
  });

  group('WordSearchDictionary', () {
    test('contains multiple categories with age-appropriate words', () {
      expect(dictionary.categoryNames.length, greaterThanOrEqualTo(5));
      expect(dictionary.categoryNames, contains('Animals'));
      expect(dictionary.categoryNames, contains('Nature'));
      expect(dictionary.categoryNames, contains('Space'));
    });

    test('getCandidatesForDifficulty filters by length and bounds', () {
      final easyCandidates = dictionary.getCandidatesForDifficulty(
        WordSearchDifficulty.easy,
      );
      for (final word in easyCandidates) {
        expect(word.length, greaterThanOrEqualTo(3));
        expect(word.length, lessThanOrEqualTo(5));
        expect(RegExp(r'^[A-Z]+$').hasMatch(word), isTrue);
      }

      final hardCandidates = dictionary.getCandidatesForDifficulty(
        WordSearchDifficulty.hard,
      );
      for (final word in hardCandidates) {
        expect(word.length, greaterThanOrEqualTo(5));
        expect(word.length, lessThanOrEqualTo(9));
      }
    });

    test(
      'getWordsForDifficulty returns requested count or available limit',
      () {
        final words = dictionary.getWordsForDifficulty(
          WordSearchDifficulty.easy,
          count: 5,
          random: Random(42),
        );
        expect(words.length, 5);
        expect(words.toSet().length, 5);
      },
    );
  });

  group('WordSearchEngine - Straight-line Coordinate Calculation', () {
    test('horizontal selections (both directions) are valid', () {
      // Left to right
      final lr = engine.getStraightLineCoordinates(
        const GridCoordinate(2, 1),
        const GridCoordinate(2, 4),
      );
      expect(
        lr,
        equals([
          const GridCoordinate(2, 1),
          const GridCoordinate(2, 2),
          const GridCoordinate(2, 3),
          const GridCoordinate(2, 4),
        ]),
      );

      // Right to left
      final rl = engine.getStraightLineCoordinates(
        const GridCoordinate(2, 4),
        const GridCoordinate(2, 1),
      );
      expect(
        rl,
        equals([
          const GridCoordinate(2, 4),
          const GridCoordinate(2, 3),
          const GridCoordinate(2, 2),
          const GridCoordinate(2, 1),
        ]),
      );
    });

    test('vertical selections (both directions) are valid', () {
      // Top to bottom
      final tb = engine.getStraightLineCoordinates(
        const GridCoordinate(1, 3),
        const GridCoordinate(4, 3),
      );
      expect(
        tb,
        equals([
          const GridCoordinate(1, 3),
          const GridCoordinate(2, 3),
          const GridCoordinate(3, 3),
          const GridCoordinate(4, 3),
        ]),
      );

      // Bottom to top
      final bt = engine.getStraightLineCoordinates(
        const GridCoordinate(4, 3),
        const GridCoordinate(1, 3),
      );
      expect(
        bt,
        equals([
          const GridCoordinate(4, 3),
          const GridCoordinate(3, 3),
          const GridCoordinate(2, 3),
          const GridCoordinate(1, 3),
        ]),
      );
    });

    test('diagonal selections across all 4 diagonals are valid', () {
      // Top-left to bottom-right
      final tlBr = engine.getStraightLineCoordinates(
        const GridCoordinate(0, 0),
        const GridCoordinate(3, 3),
      );
      expect(
        tlBr,
        equals([
          const GridCoordinate(0, 0),
          const GridCoordinate(1, 1),
          const GridCoordinate(2, 2),
          const GridCoordinate(3, 3),
        ]),
      );

      // Bottom-right to top-left
      final brTl = engine.getStraightLineCoordinates(
        const GridCoordinate(3, 3),
        const GridCoordinate(0, 0),
      );
      expect(
        brTl,
        equals([
          const GridCoordinate(3, 3),
          const GridCoordinate(2, 2),
          const GridCoordinate(1, 1),
          const GridCoordinate(0, 0),
        ]),
      );

      // Top-right to bottom-left
      final trBl = engine.getStraightLineCoordinates(
        const GridCoordinate(0, 3),
        const GridCoordinate(3, 0),
      );
      expect(
        trBl,
        equals([
          const GridCoordinate(0, 3),
          const GridCoordinate(1, 2),
          const GridCoordinate(2, 1),
          const GridCoordinate(3, 0),
        ]),
      );

      // Bottom-left to top-right
      final blTr = engine.getStraightLineCoordinates(
        const GridCoordinate(3, 0),
        const GridCoordinate(0, 3),
      );
      expect(
        blTr,
        equals([
          const GridCoordinate(3, 0),
          const GridCoordinate(2, 1),
          const GridCoordinate(1, 2),
          const GridCoordinate(0, 3),
        ]),
      );
    });

    test('single cell selection returns one coordinate', () {
      final single = engine.getStraightLineCoordinates(
        const GridCoordinate(4, 4),
        const GridCoordinate(4, 4),
      );
      expect(single, equals([const GridCoordinate(4, 4)]));
    });

    test('invalid non-straight line selections return null', () {
      // Knight move or irregular angle
      final knight = engine.getStraightLineCoordinates(
        const GridCoordinate(1, 1),
        const GridCoordinate(3, 2),
      );
      expect(knight, isNull);

      final skew = engine.getStraightLineCoordinates(
        const GridCoordinate(0, 1),
        const GridCoordinate(4, 2),
      );
      expect(skew, isNull);
    });
  });

  group('WordSearchEngine - Placement and Overlap Validation', () {
    test('compatible overlapping letters succeed', () {
      final grid = List.generate(8, (_) => List<String?>.filled(8, null));

      // Place CAT horizontally at (0, 0) -> C(0,0), A(0,1), T(0,2)
      grid[0][0] = 'C';
      grid[0][1] = 'A';
      grid[0][2] = 'T';

      // Place TEA vertically starting at (0, 2) sharing 'T' at (0, 2)
      // T(0,2), E(1,2), A(2,2)
      final canPlaceTea = engine.canPlaceWord(
        grid,
        'TEA',
        const GridCoordinate(0, 2),
        WordDirection.verticalDown,
      );
      expect(canPlaceTea, isTrue);
    });

    test('conflicting overlapping letters are rejected', () {
      final grid = List.generate(8, (_) => List<String?>.filled(8, null));

      // Place DOG at (1, 1) -> D(1,1), O(1,2), G(1,3)
      grid[1][1] = 'D';
      grid[1][2] = 'O';
      grid[1][3] = 'G';

      // Attempt to place CAT vertically at (0, 2) where (1, 2) requires 'A', but has 'O'
      final canPlaceCat = engine.canPlaceWord(
        grid,
        'CAT',
        const GridCoordinate(0, 2),
        WordDirection.verticalDown,
      );
      expect(canPlaceCat, isFalse);
    });

    test('out-of-bounds placements are rejected', () {
      final grid = List.generate(8, (_) => List<String?>.filled(8, null));

      // Length 4 starting at col 6 going horizontal right -> exceeds col 7
      final exceedsRight = engine.canPlaceWord(
        grid,
        'LION',
        const GridCoordinate(2, 6),
        WordDirection.horizontalRight,
      );
      expect(exceedsRight, isFalse);

      // Length 4 starting at row 1 going vertical up -> exceeds row 0
      final exceedsTop = engine.canPlaceWord(
        grid,
        'LION',
        const GridCoordinate(1, 2),
        WordDirection.verticalUp,
      );
      expect(exceedsTop, isFalse);
    });
  });

  group('WordSearchEngine - Word Matching', () {
    final sampleGrid = [
      ['C', 'A', 'T', 'S'],
      ['O', 'X', 'Y', 'Z'],
      ['D', 'E', 'E', 'R'],
      ['E', 'F', 'G', 'H'],
    ];

    test('matches forward word selection', () {
      final coords = [
        const GridCoordinate(0, 0),
        const GridCoordinate(0, 1),
        const GridCoordinate(0, 2),
      ];

      final match = engine.checkSelectionMatch(
        grid: sampleGrid,
        coordinates: coords,
        targetWords: ['CAT', 'DOG'],
        alreadyFoundWords: {},
      );

      expect(match, equals('CAT'));
    });

    test('matches reverse word selection (dragged in opposite direction)', () {
      // Player selected T -> A -> C
      final coords = [
        const GridCoordinate(0, 2),
        const GridCoordinate(0, 1),
        const GridCoordinate(0, 0),
      ];

      final match = engine.checkSelectionMatch(
        grid: sampleGrid,
        coordinates: coords,
        targetWords: ['CAT', 'DOG'],
        alreadyFoundWords: {},
      );

      expect(match, equals('CAT'));
    });

    test('does not rematch an already-found word', () {
      final coords = [
        const GridCoordinate(0, 0),
        const GridCoordinate(0, 1),
        const GridCoordinate(0, 2),
      ];

      final match = engine.checkSelectionMatch(
        grid: sampleGrid,
        coordinates: coords,
        targetWords: ['CAT'],
        alreadyFoundWords: {'CAT'},
      );

      expect(match, isNull);
    });

    test('returns null for non-target word selection', () {
      final coords = [
        const GridCoordinate(1, 0),
        const GridCoordinate(1, 1),
        const GridCoordinate(1, 2),
      ]; // 'OXY'

      final match = engine.checkSelectionMatch(
        grid: sampleGrid,
        coordinates: coords,
        targetWords: ['CAT', 'DEER'],
        alreadyFoundWords: {},
      );

      expect(match, isNull);
    });
  });

  group('WordSearchEngine - Grid Generation across Difficulties', () {
    test(
      'Easy difficulty generates 8x8 grid with valid dimensions and words',
      () {
        final puzzle = engine.generatePuzzle(
          difficulty: WordSearchDifficulty.easy,
          random: Random(100),
        );

        expect(puzzle.size, 8);
        expect(puzzle.grid.length, 8);
        for (final row in puzzle.grid) {
          expect(row.length, 8);
          for (final cell in row) {
            expect(RegExp(r'^[A-Z]$').hasMatch(cell), isTrue);
          }
        }

        expect(puzzle.targetWords.length, greaterThanOrEqualTo(5));
        expect(puzzle.targetWords.length, lessThanOrEqualTo(8));
        // Verify every target word is present in placedWords
        for (final target in puzzle.targetWords) {
          expect(
            puzzle.placedWords.any((pw) => pw.word == target),
            isTrue,
            reason: 'Target word $target must be placed in grid',
          );
        }
      },
    );

    test('Medium difficulty generates 10x10 grid with 8 directions', () {
      final puzzle = engine.generatePuzzle(
        difficulty: WordSearchDifficulty.medium,
        random: Random(200),
      );

      expect(puzzle.size, 10);
      expect(puzzle.targetWords.length, greaterThanOrEqualTo(8));
      expect(puzzle.targetWords.length, lessThanOrEqualTo(12));

      for (final target in puzzle.targetWords) {
        expect(puzzle.placedWords.any((pw) => pw.word == target), isTrue);
      }
    });

    test('Hard difficulty generates 12x12 grid with longer words', () {
      final puzzle = engine.generatePuzzle(
        difficulty: WordSearchDifficulty.hard,
        random: Random(300),
      );

      expect(puzzle.size, 12);
      expect(puzzle.targetWords.length, greaterThanOrEqualTo(12));

      for (final target in puzzle.targetWords) {
        expect(puzzle.placedWords.any((pw) => pw.word == target), isTrue);
      }
    });

    test('every placed word matches letters in the final generated grid', () {
      final puzzle = engine.generatePuzzle(
        difficulty: WordSearchDifficulty.medium,
        random: Random(555),
      );

      for (final pw in puzzle.placedWords) {
        final extracted = pw.coordinates
            .map((c) => puzzle.grid[c.row][c.col])
            .join();
        expect(
          extracted,
          equals(pw.word),
          reason: 'Grid letters at placed coordinates must match word',
        );
      }
    });

    test('deterministic generation behavior with seeded Random', () {
      final puzzleA = engine.generatePuzzle(
        difficulty: WordSearchDifficulty.easy,
        random: Random(12345),
      );
      final puzzleB = engine.generatePuzzle(
        difficulty: WordSearchDifficulty.easy,
        random: Random(12345),
      );

      expect(puzzleA.targetWords, equals(puzzleB.targetWords));
      expect(puzzleA.grid, equals(puzzleB.grid));
    });

    test('puzzle completion is detected correctly', () {
      final targetWords = ['CAT', 'DOG', 'BIRD'];
      final incomplete = [
        const FoundWord(word: 'CAT', coordinates: [], colorIndex: 0),
      ];

      expect(
        engine.isPuzzleCompleted(
          targetWords: targetWords,
          foundWords: incomplete,
        ),
        isFalse,
      );

      final complete = [
        const FoundWord(word: 'CAT', coordinates: [], colorIndex: 0),
        const FoundWord(word: 'DOG', coordinates: [], colorIndex: 1),
        const FoundWord(word: 'BIRD', coordinates: [], colorIndex: 2),
      ];

      expect(
        engine.isPuzzleCompleted(
          targetWords: targetWords,
          foundWords: complete,
        ),
        isTrue,
      );
    });
  });
}
