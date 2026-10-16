import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/emoji_connect/cubit/emoji_connect_cubit.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_models.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EmojiConnectCubit Tests', () {
    late SharedPreferences prefs;
    late SharedEmojiConnectStorage storage;
    late EmojiConnectCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = SharedEmojiConnectStorage(prefs);
      cubit = EmojiConnectCubit(storage: storage);
      // Wait for async _init
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() async {
      await cubit.close();
    });

    test('Initial cubit state loads level 1 Easy with timer ready', () {
      expect(cubit.state.difficulty, equals(EmojiConnectDifficulty.easy));
      expect(cubit.state.levelNumber, equals(1));
      expect(cubit.state.unlockedLevel, equals(1));
      expect(cubit.state.isTimerRunning, isFalse);
      expect(cubit.state.isWon, isFalse);
    });

    test(
      'Dragging creates and updates path, starts timer, then endDrag finalizes',
      () async {
        final pair = cubit.state.engine.level.pairs[0];
        final ref = cubit.state.engine.level.referenceSolution[pair.id]!;

        cubit.startDrag(ref[0]);
        expect(cubit.state.isTimerRunning, isTrue);
        expect(cubit.state.engine.activeDragPairId, equals(pair.id));

        cubit.updateDrag(ref[1]);
        expect(cubit.state.engine.paths[pair.id]?.points.length, equals(2));

        await cubit.endDrag();
        expect(cubit.state.engine.activeDragPairId, isNull);
        expect(cubit.state.engine.paths[pair.id]?.points.length, equals(2));
      },
    );

    test('Undo reverts the most recent change', () async {
      final pair = cubit.state.engine.level.pairs[0];
      final ref = cubit.state.engine.level.referenceSolution[pair.id]!;

      cubit.startDrag(ref[0]);
      cubit.updateDrag(ref[1]);
      await cubit.endDrag();

      expect(cubit.state.canUndo, isTrue);
      await cubit.undo();
      expect(cubit.state.engine.paths.isEmpty, isTrue);
    });

    test('Reset clears all paths and resets elapsed time', () async {
      final pair = cubit.state.engine.level.pairs[0];
      final ref = cubit.state.engine.level.referenceSolution[pair.id]!;

      cubit.startDrag(ref[0]);
      cubit.updateDrag(ref[1]);
      await cubit.endDrag();

      await cubit.resetLevel();
      expect(cubit.state.engine.paths.isEmpty, isTrue);
      expect(cubit.state.elapsedSeconds, equals(0));
    });

    test('requestHint applies reference route and emits message', () async {
      await cubit.requestHint();
      expect(cubit.state.hintMessage, isNotNull);
      expect(cubit.state.engine.paths.isNotEmpty, isTrue);
    });

    test(
      'Solving the entire puzzle triggers win, marks completed, and unlocks next level',
      () async {
        final level = cubit.state.engine.level;
        final ref = level.referenceSolution;

        for (final pair in level.pairs) {
          final pts = ref[pair.id]!;
          cubit.startDrag(pts[0]);
          for (int i = 1; i < pts.length; i++) {
            cubit.updateDrag(pts[i]);
          }
          await cubit.endDrag();
        }

        expect(cubit.state.isWon, isTrue);
        expect(cubit.state.isTimerRunning, isFalse);
        expect(cubit.state.unlockedLevel, greaterThanOrEqualTo(2));
        expect(cubit.state.completedLevels.contains(1), isTrue);
      },
    );

    test(
      'selectDifficulty switches board size and persists selection',
      () async {
        await cubit.selectDifficulty(EmojiConnectDifficulty.medium);

        expect(cubit.state.difficulty, equals(EmojiConnectDifficulty.medium));
        expect(cubit.state.engine.level.boardSize, equals(6));
        expect(
          await storage.getSelectedDifficulty(),
          equals(EmojiConnectDifficulty.medium),
        );
      },
    );

    test('selectLevel advances level when unlocked', () async {
      // First unlock level 2
      await storage.setUnlockedLevel(EmojiConnectDifficulty.easy, 2);
      await cubit.selectLevel(2);

      expect(cubit.state.levelNumber, equals(2));
      expect(cubit.state.engine.level.id, equals(2));
    });

    test('selectLevel ignores locked levels', () async {
      await cubit.selectLevel(5); // Level 5 is locked
      expect(cubit.state.levelNumber, equals(1));
    });

    test('nextLevel advances to next level after win', () async {
      // Unlock level 2
      await storage.setUnlockedLevel(EmojiConnectDifficulty.easy, 2);
      // Win level 1
      final level = cubit.state.engine.level;
      for (final pair in level.pairs) {
        final pts = level.referenceSolution[pair.id]!;
        cubit.startDrag(pts[0]);
        for (int i = 1; i < pts.length; i++) {
          cubit.updateDrag(pts[i]);
        }
        await cubit.endDrag();
      }

      await cubit.nextLevel();
      expect(cubit.state.levelNumber, equals(2));
    });
  });
}
