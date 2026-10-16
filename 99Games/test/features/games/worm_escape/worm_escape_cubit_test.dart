import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/worm_escape/cubit/worm_escape_cubit.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_models.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WormEscapeCubit Tests', () {
    late SharedWormEscapeStorage storage;
    late WormEscapeCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = SharedWormEscapeStorage(prefs);
      cubit = WormEscapeCubit(storage: storage);
      // Wait for async init
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });

    tearDown(() async {
      await cubit.close();
    });

    test('Initial cubit state loads level 1 Easy', () {
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.difficulty, equals(WormEscapeDifficulty.easy));
      expect(cubit.state.levelNumber, equals(1));
      expect(cubit.state.unlockedLevel, equals(1));
      expect(cubit.state.completedLevels, isEmpty);
      expect(cubit.state.engine.boardSize, equals(6));
      expect(cubit.state.engine.totalWorms, greaterThan(0));
      expect(cubit.state.isWon, isFalse);
    });

    test('Tapping empty cell does nothing and returns false', () {
      // Find a cell unoccupied by any worm
      GridPosition? emptyCell;
      for (int r = 0; r < 6; r++) {
        for (int c = 0; c < 6; c++) {
          final pos = GridPosition(r, c);
          if (cubit.state.engine.getWormAtCell(pos) == null) {
            emptyCell = pos;
            break;
          }
        }
        if (emptyCell != null) break;
      }

      expect(emptyCell, isNotNull);
      final handled = cubit.tapWormAtCell(emptyCell!);
      expect(handled, isFalse);
      expect(cubit.state.animatingWormId, isNull);
      expect(cubit.state.blockedWormId, isNull);
    });

    test('Tapping blocked worm sets blocked feedback without moving it', () {
      // Find a blocked worm
      Worm? blockedWorm;
      for (final worm in cubit.state.engine.worms.values) {
        if (!cubit.state.engine.canEscape(worm)) {
          blockedWorm = worm;
          break;
        }
      }

      if (blockedWorm != null) {
        final handled = cubit.tapWormAtCell(blockedWorm.head);
        expect(handled, isFalse);
        expect(cubit.state.blockedWormId, equals(blockedWorm.id));
        expect(cubit.state.blockingWormId, isNotNull);
        expect(cubit.state.hintMessage, equals('Path is blocked!'));
        expect(cubit.state.engine.escapedWormsCount, equals(0));

        // Clearing blocked animation
        cubit.onBlockedAnimationCompleted();
        expect(cubit.state.blockedWormId, isNull);
      }
    });

    test(
      'Tapping unblocked worm starts animation and commits escape',
      () async {
        // Find an unblocked worm (first in reference solution)
        final unblockedId = cubit.state.engine.getHintWormId()!;
        final worm = cubit.state.engine.worms[unblockedId]!;

        final handled = cubit.tapWormAtCell(worm.head);
        expect(handled, isTrue);
        expect(cubit.state.animatingWormId, equals(unblockedId));

        // Duplicate tap while animating is ignored
        final secondTap = cubit.tapWormAtCell(worm.head);
        expect(secondTap, isFalse);

        // Animation completed
        await cubit.onEscapeAnimationCompleted(unblockedId);
        expect(cubit.state.animatingWormId, isNull);
        expect(cubit.state.escapedWorms, equals(1));
        expect(cubit.state.movesCount, equals(1));
      },
    );

    test('Undo restores escaped worm', () async {
      final unblockedId = cubit.state.engine.getHintWormId()!;
      final worm = cubit.state.engine.worms[unblockedId]!;

      cubit.tapWormAtCell(worm.head);
      await cubit.onEscapeAnimationCompleted(unblockedId);
      expect(cubit.state.escapedWorms, equals(1));

      cubit.undo();
      expect(cubit.state.escapedWorms, equals(0));
      expect(cubit.state.movesCount, equals(0));
    });

    test('Reset restores initial board state', () async {
      final unblockedId = cubit.state.engine.getHintWormId()!;
      final worm = cubit.state.engine.worms[unblockedId]!;

      cubit.tapWormAtCell(worm.head);
      await cubit.onEscapeAnimationCompleted(unblockedId);
      expect(cubit.state.escapedWorms, equals(1));

      cubit.resetLevel();
      expect(cubit.state.escapedWorms, equals(0));
    });

    test('Request hint highlights an unblocked worm', () {
      expect(cubit.state.hintWormId, isNull);

      cubit.requestHint();
      expect(cubit.state.hintWormId, isNotNull);
      expect(cubit.state.hintMessage, isNotNull);
    });

    test('Solving level marks completed and unlocks level 2', () async {
      final ref = cubit.state.engine.level.referenceSolution;
      for (final id in ref) {
        final worm = cubit.state.engine.worms[id]!;
        cubit.tapWormAtCell(worm.head);
        await cubit.onEscapeAnimationCompleted(id);
      }

      expect(cubit.state.isWon, isTrue);
      expect(cubit.state.completedLevels, contains(1));
      expect(cubit.state.unlockedLevel, greaterThanOrEqualTo(2));
    });

    test('Difficulty selection switches board size and difficulty', () async {
      await cubit.selectDifficulty(WormEscapeDifficulty.medium);
      expect(cubit.state.difficulty, equals(WormEscapeDifficulty.medium));
      expect(cubit.state.engine.boardSize, equals(8));

      await cubit.selectDifficulty(WormEscapeDifficulty.hard);
      expect(cubit.state.difficulty, equals(WormEscapeDifficulty.hard));
      expect(cubit.state.engine.boardSize, equals(10));
    });

    test('Select level only navigates to unlocked levels', () async {
      // Level 2 is locked initially
      await cubit.selectLevel(2);
      expect(cubit.state.levelNumber, equals(1));

      // Unlock level 2
      await storage.setUnlockedLevel(WormEscapeDifficulty.easy, 2);
      await cubit.init();

      await cubit.selectLevel(2);
      expect(cubit.state.levelNumber, equals(2));
    });
  });
}
