import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/word_circle/domain/word_circle_dictionary.dart';
import 'package:mini_games_99/features/games/word_circle/domain/word_circle_engine.dart';
import 'package:mini_games_99/features/games/word_circle/domain/word_circle_level_data.dart';
import 'package:mini_games_99/features/games/word_circle/domain/word_circle_models.dart';

void main() {
  const engine = WordCircleEngine();

  group(
    'WordCircle Level Validator & Mathematical Integrity (All 20 Levels)',
    () {
      test('Exactly 20 curated levels exist', () {
        final levels = WordCircleLevelData.getAllLevels();
        expect(levels.length, equals(20));
        expect(WordCircleLevelData.totalLevels, equals(20));
      });

      test('Every level passes engine.validateLevel without throwing', () {
        final levels = WordCircleLevelData.getAllLevels();
        for (final lvl in levels) {
          expect(() => engine.validateLevel(lvl), returnsNormally);
        }
      });

      test('Every target word in all 20 levels is in WordCircleDictionary', () {
        final levels = WordCircleLevelData.getAllLevels();
        for (final lvl in levels) {
          for (final target in lvl.targetWords) {
            expect(
              WordCircleDictionary.isValidWord(target.word),
              isTrue,
              reason: 'Level ${lvl.id}: ${target.word} must be in dictionary',
            );
          }
        }
      });

      test(
        'Every level can be completed by submitting its reference target words',
        () {
          final levels = WordCircleLevelData.getAllLevels();
          for (final lvl in levels) {
            final found = <String>{};
            for (final target in lvl.targetWords) {
              final res = engine.submitWord(
                rawWord: target.word,
                level: lvl,
                foundTargetWords: found,
                foundBonusWords: const {},
              );
              expect(res.status, equals(WordSubmissionStatus.newTarget));
              expect(res.pointsEarned, equals(target.word.length * 10));
              found.add(target.word.toUpperCase());
            }
            expect(engine.isLevelComplete(lvl, found), isTrue);
          }
        },
      );

      test('Level completion strictly requires ALL target words', () {
        final lvl = WordCircleLevelData.getLevel(1); // CAT, ACT
        expect(engine.isLevelComplete(lvl, {'CAT'}), isFalse);
        expect(engine.isLevelComplete(lvl, {'ACT'}), isFalse);
        expect(engine.isLevelComplete(lvl, {'CAT', 'ACT'}), isTrue);
      });

      test(
        'Crossword grid coordinates and cell letter intersections agree',
        () {
          final levels = WordCircleLevelData.getAllLevels();
          for (final lvl in levels) {
            final grid = engine.generateCrosswordGrid(
              level: lvl,
              foundTargetWords: const {},
              hintedCellKeys: const {},
            );

            for (final target in lvl.targetWords) {
              for (int i = 0; i < target.length; i++) {
                final r = target.isHorizontal ? target.row : target.row + i;
                final c = target.isHorizontal ? target.col + i : target.col;
                final key = '$r,$c';

                expect(grid.containsKey(key), isTrue);
                expect(grid[key]!.letter, equals(target.word[i].toUpperCase()));
                expect(grid[key]!.targetWordIds.contains(target.id), isTrue);
              }
            }
          }
        },
      );
    },
  );

  group('WordCircleEngine Word Submission & Scoring Tests', () {
    final lvl = WordCircleLevelData.getLevel(
      3,
    ); // E, N, P, T -> PEN, NET, TEN (bonus: PET)

    test('Valid target word earns length * 10 points and matches target', () {
      final res = engine.submitWord(
        rawWord: 'pen',
        level: lvl,
        foundTargetWords: const {},
        foundBonusWords: const {},
      );

      expect(res.status, equals(WordSubmissionStatus.newTarget));
      expect(res.word, equals('PEN'));
      expect(res.pointsEarned, equals(30));
      expect(res.matchedTarget?.word, equals('PEN'));
    });

    test('Bonus word earns length * 5 points without completing target', () {
      final res = engine.submitWord(
        rawWord: 'pet',
        level: lvl,
        foundTargetWords: const {},
        foundBonusWords: const {},
      );

      expect(res.status, equals(WordSubmissionStatus.newBonus));
      expect(res.word, equals('PET'));
      expect(res.pointsEarned, equals(15));
      expect(res.matchedTarget, isNull);
    });

    test('Submitting already found target word is rejected with 0 points', () {
      final res = engine.submitWord(
        rawWord: 'PEN',
        level: lvl,
        foundTargetWords: {'PEN'},
        foundBonusWords: const {},
      );

      expect(res.status, equals(WordSubmissionStatus.alreadyFound));
      expect(res.pointsEarned, equals(0));
    });

    test('Submitting already found bonus word is rejected with 0 points', () {
      final res = engine.submitWord(
        rawWord: 'PET',
        level: lvl,
        foundTargetWords: const {},
        foundBonusWords: {'PET'},
      );

      expect(res.status, equals(WordSubmissionStatus.alreadyFound));
      expect(res.pointsEarned, equals(0));
    });

    test('Words shorter than 3 letters are rejected with tooShort', () {
      final res = engine.submitWord(
        rawWord: 'PE',
        level: lvl,
        foundTargetWords: const {},
        foundBonusWords: const {},
      );

      expect(res.status, equals(WordSubmissionStatus.tooShort));
      expect(res.pointsEarned, equals(0));
    });

    test('Words not in dictionary are rejected with invalidWord', () {
      final res = engine.submitWord(
        rawWord: 'NEP',
        level: lvl,
        foundTargetWords: const {},
        foundBonusWords: const {},
      );

      expect(res.status, equals(WordSubmissionStatus.invalidWord));
      expect(res.pointsEarned, equals(0));
    });

    test('Bonus words must be formable from wheel letters', () {
      // Word 'DOG' is in dictionary, but cannot be formed from 'ENPT'
      final res = engine.submitWord(
        rawWord: 'DOG',
        level: lvl,
        foundTargetWords: const {},
        foundBonusWords: const {},
      );

      expect(res.status, equals(WordSubmissionStatus.invalidWord));
    });

    test('Repeated characters multiset enforcement', () {
      // Level 18 has 2 E's: 'A', 'E', 'E', 'F', 'H', 'R', 'T'
      final lvl18 = WordCircleLevelData.getLevel(18);
      // 'TREE' has 2 E's -> valid
      expect(engine.isWordFormableFromLetters('TREE', lvl18.letters), isTrue);
      // 'THREE' has 2 E's -> valid
      expect(engine.isWordFormableFromLetters('THREE', lvl18.letters), isTrue);
      // 'TEETH' requires 3 E's -> invalid
      expect(engine.isWordFormableFromLetters('TEETH', lvl18.letters), isFalse);
    });

    test('Hint revealing finds next unrevealed, unhinted cell', () {
      final lvl1 = WordCircleLevelData.getLevel(
        1,
      ); // CAT (1,0..2), ACT (0..2,0)
      final hint1 = engine.getNextHintCell(
        level: lvl1,
        foundTargetWords: const {},
        hintedCellKeys: const {},
      );

      expect(hint1, isNotNull);

      // Hinting that cell causes getNextHintCell to pick another cell
      final hint2 = engine.getNextHintCell(
        level: lvl1,
        foundTargetWords: const {},
        hintedCellKeys: {hint1!},
      );

      expect(hint2, isNotNull);
      expect(hint2, isNot(equals(hint1)));

      // When all target words are found, no hint is returned
      final hintNone = engine.getNextHintCell(
        level: lvl1,
        foundTargetWords: {'CAT', 'ACT'},
        hintedCellKeys: const {},
      );
      expect(hintNone, isNull);
    });
  });
}
