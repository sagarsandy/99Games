import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/number_match/domain/number_match_engine.dart';
import 'package:mini_games_99/features/games/number_match/domain/number_match_models.dart';

void main() {
  const engine = NumberMatchEngine();

  group('NumberMatchEngine - Pair Value Validation', () {
    test('identical numbers form a valid pair', () {
      for (int i = 1; i <= 9; i++) {
        expect(engine.isValueMatch(i, i), isTrue);
      }
    });

    test('numbers summing to 10 form a valid pair', () {
      expect(engine.isValueMatch(1, 9), isTrue);
      expect(engine.isValueMatch(9, 1), isTrue);
      expect(engine.isValueMatch(2, 8), isTrue);
      expect(engine.isValueMatch(8, 2), isTrue);
      expect(engine.isValueMatch(3, 7), isTrue);
      expect(engine.isValueMatch(7, 3), isTrue);
      expect(engine.isValueMatch(4, 6), isTrue);
      expect(engine.isValueMatch(6, 4), isTrue);
      expect(engine.isValueMatch(5, 5), isTrue);
    });

    test('invalid pairs neither equal nor summing to 10 are rejected', () {
      expect(engine.isValueMatch(1, 2), isFalse);
      expect(engine.isValueMatch(3, 5), isFalse);
      expect(engine.isValueMatch(4, 7), isFalse);
      expect(engine.isValueMatch(8, 9), isFalse);
      expect(engine.isValueMatch(2, 6), isFalse);
    });

    test('out of range values are rejected', () {
      expect(engine.isValueMatch(0, 10), isFalse);
      expect(engine.isValueMatch(-1, 11), isFalse);
    });
  });

  group('NumberMatchEngine - Connection Rules', () {
    test('a cell cannot match with itself', () {
      final tiles = [
        const NumberMatchTile(id: 0, value: 5),
        const NumberMatchTile(id: 1, value: 5),
      ];
      final result = engine.validateMatch(0, 0, tiles);
      expect(result.isValid, isFalse);
      expect(result.status, equals(MatchValidationStatus.sameTile));
    });

    test('already cleared cells cannot participate in matches', () {
      final tiles = [
        const NumberMatchTile(id: 0, value: 5, isCleared: true),
        const NumberMatchTile(id: 1, value: 5),
      ];
      final result = engine.validateMatch(0, 1, tiles);
      expect(result.isValid, isFalse);
      expect(result.status, equals(MatchValidationStatus.alreadyCleared));
    });

    test('horizontally adjacent numbers match', () {
      final tiles = [
        const NumberMatchTile(id: 0, value: 3),
        const NumberMatchTile(id: 1, value: 7), // 3 + 7 = 10
      ];
      final result = engine.validateMatch(0, 1, tiles);
      expect(result.isValid, isTrue);
    });

    test('horizontally separated numbers across cleared cells match', () {
      final tiles = [
        const NumberMatchTile(id: 0, value: 4),
        const NumberMatchTile(id: 1, value: 2, isCleared: true),
        const NumberMatchTile(id: 2, value: 8, isCleared: true),
        const NumberMatchTile(id: 3, value: 6), // 4 + 6 = 10
      ];
      final result = engine.validateMatch(0, 3, tiles);
      expect(result.isValid, isTrue);
    });

    test(
      'horizontally separated numbers blocked by an active number are rejected',
      () {
        final tiles = [
          const NumberMatchTile(id: 0, value: 4),
          const NumberMatchTile(
            id: 1,
            value: 2,
            isCleared: false,
          ), // Active blocker
          const NumberMatchTile(id: 2, value: 6), // 4 + 6 = 10
        ];
        final result = engine.validateMatch(0, 2, tiles);
        expect(result.isValid, isFalse);
        expect(result.status, equals(MatchValidationStatus.blockedPath));
      },
    );

    test('vertically adjacent numbers match (same column, adjacent rows)', () {
      // 9 columns: index 2 and index 11 (2 + 9) are in column 2, rows 0 and 1
      final tiles = List.generate(
        18,
        (i) => NumberMatchTile(id: i, value: (i == 2 || i == 11) ? 5 : 1),
      );
      final result = engine.validateMatch(2, 11, tiles);
      expect(result.isValid, isTrue);
    });

    test('vertically separated numbers across cleared cells match', () {
      // Row 0 col 3 (idx 3), Row 1 col 3 (idx 12 cleared), Row 2 col 3 (idx 21)
      final tiles = List.generate(
        27,
        (i) => NumberMatchTile(
          id: i,
          value: (i == 3)
              ? 8
              : (i == 21)
              ? 2
              : 7,
          isCleared: i == 12,
        ),
      );
      final result = engine.validateMatch(3, 21, tiles);
      expect(result.isValid, isTrue);
    });

    test('vertically separated numbers blocked by active cell are rejected', () {
      // Row 0 col 3 (idx 3), Row 1 col 3 (idx 12 active), Row 2 col 3 (idx 21)
      final tiles = List.generate(
        27,
        (i) => NumberMatchTile(
          id: i,
          value: (i == 3)
              ? 8
              : (i == 21)
              ? 2
              : 7,
          isCleared: false,
        ),
      );
      final result = engine.validateMatch(3, 21, tiles);
      expect(result.isValid, isFalse);
      expect(result.status, equals(MatchValidationStatus.blockedPath));
    });

    test('diagonally adjacent numbers match', () {
      // Row 0 col 2 (idx 2), Row 1 col 3 (idx 12)
      final tiles = List.generate(
        18,
        (i) => NumberMatchTile(id: i, value: (i == 2 || i == 12) ? 6 : 1),
      );
      final result = engine.validateMatch(2, 12, tiles);
      expect(result.isValid, isTrue);
    });

    test('diagonally separated numbers across cleared cells match', () {
      // Row 0 col 0 (idx 0), Row 1 col 1 (idx 10 cleared), Row 2 col 2 (idx 20)
      final tiles = List.generate(
        27,
        (i) => NumberMatchTile(
          id: i,
          value: (i == 0 || i == 20) ? 9 : 1,
          isCleared: i == 10,
        ),
      );
      final result = engine.validateMatch(0, 20, tiles);
      expect(result.isValid, isTrue);
    });

    test(
      'sequential reading order line of sight connects across row boundaries',
      () {
        // End of row 0 (idx 8) and start of row 1 (idx 9)
        final tiles = List.generate(
          18,
          (i) => NumberMatchTile(id: i, value: (i == 8 || i == 9) ? 4 : 1),
        );
        final result = engine.validateMatch(8, 9, tiles);
        expect(result.isValid, isTrue);
      },
    );

    test('sequential reading order connects across multiple cleared rows', () {
      // Index 8 has 7, index 22 has 3. All cells from 9 to 21 are cleared.
      final tiles = List.generate(
        27,
        (i) => NumberMatchTile(
          id: i,
          value: (i == 8)
              ? 7
              : (i == 22)
              ? 3
              : 1,
          isCleared: (i > 8 && i < 22),
        ),
      );
      final result = engine.validateMatch(8, 22, tiles);
      expect(result.isValid, isTrue);
    });
  });

  group('NumberMatchEngine - Board Generation and Add Numbers', () {
    test(
      'createClassicBoard returns exactly 27 tiles matching Take Ten sequence',
      () {
        final board = engine.createClassicBoard();
        expect(board.length, equals(27));
        expect(
          board.map((t) => t.value).toList(),
          equals(NumberMatchEngine.classicTakeTenDigits),
        );
        expect(board.every((t) => !t.isCleared), isTrue);
      },
    );

    test(
      'createRandomBoard produces playable board with at least 3 valid pairs',
      () {
        final board = engine.createRandomBoard(rowCount: 3, random: Random(42));
        expect(board.length, equals(27));
        final pairs = engine.findAllValidPairs(board);
        expect(pairs.length, greaterThanOrEqualTo(3));
      },
    );

    test(
      'addRemainingNumbers appends active numbers in order with unique IDs',
      () {
        final initialTiles = [
          const NumberMatchTile(id: 0, value: 1, isCleared: true),
          const NumberMatchTile(id: 1, value: 5, isCleared: false),
          const NumberMatchTile(id: 2, value: 9, isCleared: true),
          const NumberMatchTile(id: 3, value: 5, isCleared: false),
        ];

        final result = engine.addRemainingNumbers(initialTiles);
        expect(result.addedCount, equals(2));
        expect(result.tiles.length, equals(6));

        // Check appended tiles
        expect(result.tiles[4].value, equals(5));
        expect(result.tiles[4].id, equals(4));
        expect(result.tiles[4].isCleared, isFalse);

        expect(result.tiles[5].value, equals(5));
        expect(result.tiles[5].id, equals(5));
        expect(result.tiles[5].isCleared, isFalse);

        // They should now form a valid pair!
        expect(engine.canMatch(4, 5, result.tiles), isTrue);
      },
    );

    test('addRemainingNumbers on completely cleared board adds 0 numbers', () {
      final initialTiles = [
        const NumberMatchTile(id: 0, value: 1, isCleared: true),
        const NumberMatchTile(id: 1, value: 9, isCleared: true),
      ];

      final result = engine.addRemainingNumbers(initialTiles);
      expect(result.addedCount, equals(0));
      expect(result.tiles.length, equals(2));
    });
  });

  group('NumberMatchEngine - Win, Row Clearance, and Hints', () {
    test('isGameWon returns true when all tiles are cleared and non-empty', () {
      final tiles = [
        const NumberMatchTile(id: 0, value: 5, isCleared: true),
        const NumberMatchTile(id: 1, value: 5, isCleared: true),
      ];
      expect(engine.isGameWon(tiles), isTrue);
    });

    test('isGameWon returns false when active tiles remain', () {
      final tiles = [
        const NumberMatchTile(id: 0, value: 5, isCleared: true),
        const NumberMatchTile(id: 1, value: 5, isCleared: false),
      ];
      expect(engine.isGameWon(tiles), isFalse);
    });

    test('isRowCompletelyCleared detects fully cleared row', () {
      final tiles = List.generate(
        18,
        (i) => NumberMatchTile(id: i, value: 1, isCleared: i < 9),
      );
      expect(engine.isRowCompletelyCleared(0, tiles), isTrue);
      expect(engine.isRowCompletelyCleared(1, tiles), isFalse);
    });

    test(
      'calculateRowClearBonus awards bonus when matching completes a row',
      () {
        // Row 0 has 7 cleared cells and 2 active cells at idx 0 and idx 1
        final before = List.generate(
          9,
          (i) => NumberMatchTile(id: i, value: 5, isCleared: i >= 2),
        );

        final after = List.generate(
          9,
          (i) => NumberMatchTile(id: i, value: 5, isCleared: true),
        );

        final bonus = engine.calculateRowClearBonus(
          indexA: 0,
          indexB: 1,
          beforeTiles: before,
          afterTiles: after,
        );
        expect(bonus, equals(NumberMatchEngine.rowClearBonus));
      },
    );

    test('findFirstValidPair finds first available pair or returns null', () {
      final classic = engine.createClassicBoard();
      final pair = engine.findFirstValidPair(classic);
      expect(pair, isNotNull);
      expect(
        engine.canMatch(pair!.firstIndex, pair.secondIndex, classic),
        isTrue,
      );

      final noPairsBoard = [
        const NumberMatchTile(id: 0, value: 1),
        const NumberMatchTile(id: 1, value: 2),
      ];
      expect(engine.findFirstValidPair(noPairsBoard), isNull);
    });
  });
}
