import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/word_circle/cubit/word_circle_cubit.dart';
import 'package:mini_games_99/features/games/word_circle/domain/word_circle_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late WordCircleStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SharedWordCircleStorage(prefs);
  });

  group('WordCircleCubit Tests', () {
    test('Initial state loads level 1 with empty progress', () async {
      final cubit = WordCircleCubit(storage: storage);
      await cubit.loadInitial();

      expect(cubit.state.levelNumber, equals(1));
      expect(cubit.state.unlockedLevel, equals(1));
      expect(cubit.state.completedLevels, isEmpty);
      expect(cubit.state.score, equals(0));
      expect(cubit.state.foundTargetWords, isEmpty);
      expect(cubit.state.foundBonusWords, isEmpty);
      expect(cubit.state.isWon, isFalse);
      expect(cubit.state.selectedLetterIds, isEmpty);
      expect(cubit.state.wheelLetters.length, equals(3));
    });

    test('Drag selection, appending letters, and retraction', () async {
      final cubit = WordCircleCubit(storage: storage);
      await cubit.loadInitial();

      // Letters on L1 wheel: 'A', 'C', 'T' (ids: 0, 1, 2)
      final letterA = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'A',
      );
      final letterC = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'C',
      );
      final letterT = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'T',
      );

      // Start drag at C
      cubit.startDrag(letterC.id);
      expect(cubit.state.selectedLetterIds, equals([letterC.id]));
      expect(cubit.state.currentWord, equals('C'));

      // Drag to A
      cubit.addLetterToDrag(letterA.id);
      expect(cubit.state.selectedLetterIds, equals([letterC.id, letterA.id]));
      expect(cubit.state.currentWord, equals('CA'));

      // Drag to T
      cubit.addLetterToDrag(letterT.id);
      expect(
        cubit.state.selectedLetterIds,
        equals([letterC.id, letterA.id, letterT.id]),
      );
      expect(cubit.state.currentWord, equals('CAT'));

      // Reversing back over A retracts T!
      cubit.addLetterToDrag(letterA.id);
      expect(cubit.state.selectedLetterIds, equals([letterC.id, letterA.id]));
      expect(cubit.state.currentWord, equals('CA'));

      // Reversing back over C retracts A!
      cubit.addLetterToDrag(letterC.id);
      expect(cubit.state.selectedLetterIds, equals([letterC.id]));
      expect(cubit.state.currentWord, equals('C'));

      // Re-add A and T
      cubit.addLetterToDrag(letterA.id);
      cubit.addLetterToDrag(letterT.id);
      expect(
        cubit.state.selectedLetterIds,
        equals([letterC.id, letterA.id, letterT.id]),
      );

      // Cannot add duplicate letter position (C is already in sequence and not previous letter)
      cubit.addLetterToDrag(letterC.id);
      expect(
        cubit.state.selectedLetterIds,
        equals([letterC.id, letterA.id, letterT.id]),
      );

      // Clear selection
      cubit.clearSelection();
      expect(cubit.state.selectedLetterIds, isEmpty);
      expect(cubit.state.currentWord, equals(''));
    });

    test('Submitting target word reveals word and adds points', () async {
      final cubit = WordCircleCubit(storage: storage);
      await cubit.loadInitial();

      final letterA = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'A',
      );
      final letterC = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'C',
      );
      final letterT = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'T',
      );

      // Form "CAT"
      cubit.startDrag(letterC.id);
      cubit.addLetterToDrag(letterA.id);
      cubit.addLetterToDrag(letterT.id);
      await cubit.endDrag();

      expect(cubit.state.foundTargetWords, contains('CAT'));
      expect(cubit.state.score, equals(30)); // 3 * 10
      expect(cubit.state.selectedLetterIds, isEmpty);
      expect(cubit.state.isWon, isFalse); // Level 1 has CAT and ACT
    });

    test('Completing all target words wins level and unlocks next', () async {
      final cubit = WordCircleCubit(storage: storage);
      await cubit.loadInitial();

      final letterA = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'A',
      );
      final letterC = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'C',
      );
      final letterT = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'T',
      );

      // Word 1: CAT
      cubit.startDrag(letterC.id);
      cubit.addLetterToDrag(letterA.id);
      cubit.addLetterToDrag(letterT.id);
      await cubit.endDrag();

      // Word 2: ACT
      cubit.startDrag(letterA.id);
      cubit.addLetterToDrag(letterC.id);
      cubit.addLetterToDrag(letterT.id);
      await cubit.endDrag();

      expect(cubit.state.isWon, isTrue);
      expect(cubit.state.score, equals(60));
      expect(await storage.getUnlockedLevel(), equals(2));
      expect((await storage.getCompletedLevels()).contains(1), isTrue);
    });

    test('Bonus words award bonus points without completing target', () async {
      // Level 3 has targets PEN, NET, TEN, and bonus word PET
      await storage.setUnlockedLevel(3);
      final cubit = WordCircleCubit(storage: storage);
      await cubit.loadInitial();
      await cubit.selectLevel(3);

      final letterP = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'P',
      );
      final letterE = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'E',
      );
      final letterT = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'T',
      );

      // Form PET (bonus)
      cubit.startDrag(letterP.id);
      cubit.addLetterToDrag(letterE.id);
      cubit.addLetterToDrag(letterT.id);
      await cubit.endDrag();

      expect(cubit.state.foundBonusWords, contains('PET'));
      expect(cubit.state.foundTargetWords, isEmpty);
      expect(cubit.state.score, equals(15)); // 3 * 5
      expect(cubit.state.isWon, isFalse);
    });

    test('Shuffle rearranges letters while preserving identities', () async {
      final cubit = WordCircleCubit(storage: storage);
      await cubit.loadInitial();

      final original = cubit.state.wheelLetters.map((l) => l.letter).toList();
      // Deterministic shuffle with seed
      cubit.shuffleWheel(random: math.Random(42));

      expect(cubit.state.wheelLetters.length, equals(original.length));
      expect(
        cubit.state.wheelLetters.map((l) => l.letter).toSet(),
        equals(original.toSet()),
      );
    });

    test('Hint reveals a crossword cell', () async {
      final cubit = WordCircleCubit(storage: storage);
      await cubit.loadInitial();

      expect(cubit.state.hintedCellKeys, isEmpty);
      cubit.useHint();
      expect(cubit.state.hintedCellKeys.length, equals(1));
      expect(cubit.state.feedbackMessage, equals('Letter revealed!'));
    });

    test('Restart level resets score and found words', () async {
      final cubit = WordCircleCubit(storage: storage);
      await cubit.loadInitial();

      final letterA = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'A',
      );
      final letterC = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'C',
      );
      final letterT = cubit.state.wheelLetters.firstWhere(
        (l) => l.letter == 'T',
      );

      cubit.startDrag(letterC.id);
      cubit.addLetterToDrag(letterA.id);
      cubit.addLetterToDrag(letterT.id);
      cubit.endDrag();
      expect(cubit.state.foundTargetWords, contains('CAT'));

      cubit.restartLevel();
      expect(cubit.state.foundTargetWords, isEmpty);
      expect(cubit.state.foundBonusWords, isEmpty);
      expect(cubit.state.score, equals(0));
      expect(cubit.state.isWon, isFalse);
    });

    test('Saved session is restored after reload', () async {
      await storage.saveSession(
        const WordCircleSavedSession(
          levelNumber: 1,
          foundTargetWords: ['CAT'],
          foundBonusWords: [],
          hintedCellKeys: ['0,0'],
          score: 30,
        ),
      );

      final cubit = WordCircleCubit(storage: storage);
      await cubit.loadInitial();

      expect(cubit.state.foundTargetWords, contains('CAT'));
      expect(cubit.state.hintedCellKeys, contains('0,0'));
      expect(cubit.state.score, equals(30));
    });
  });
}
