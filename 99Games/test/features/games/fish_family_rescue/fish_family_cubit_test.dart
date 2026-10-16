import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/cubit/fish_family_cubit.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/domain/fish_family_models.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/domain/fish_family_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late FishFamilyStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SharedFishFamilyStorage(prefs);
  });

  group('FishFamilyCubit Tests', () {
    test('Initial state loads level 1 with empty history', () async {
      final cubit = FishFamilyCubit(storage: storage);
      await cubit.loadInitial();

      expect(cubit.state.levelNumber, equals(1));
      expect(cubit.state.unlockedLevel, equals(1));
      expect(cubit.state.movesCount, equals(0));
      expect(cubit.state.canUndo, isFalse);
      expect(cubit.state.isWon, isFalse);
      expect(cubit.state.selectedTankId, isNull);
      expect(cubit.state.isAnimating, isFalse);
    });

    test(
      'Selecting a tank sets selectedTankId and highlights top fish',
      () async {
        final cubit = FishFamilyCubit(storage: storage);
        await cubit.loadInitial();

        // Tap Tank 0 (has fish)
        cubit.tapTank(0);
        expect(cubit.state.selectedTankId, equals(0));
        expect(cubit.state.selectedFish?.speciesId, equals('blue_tang'));

        // Tap Tank 0 again: deselects
        cubit.tapTank(0);
        expect(cubit.state.selectedTankId, isNull);
      },
    );

    test('Tapping empty tank does not select it as source', () async {
      final cubit = FishFamilyCubit(storage: storage);
      await cubit.loadInitial();

      // Tank 2 is empty in level 1
      cubit.tapTank(2);
      expect(cubit.state.selectedTankId, isNull);
    });

    test(
      'Valid move updates tanks, increments movesCount, and enables undo when finalized',
      () async {
        final cubit = FishFamilyCubit(storage: storage);
        await cubit.loadInitial();

        // Level 1: Tank 0 has ['clownfish', 'blue_tang'], Tank 2 is empty
        cubit.tapTank(0); // Select Tank 0
        cubit.tapTank(2, animate: false); // Move 'blue_tang' to empty Tank 2

        expect(cubit.state.movesCount, equals(1));
        expect(cubit.state.selectedTankId, isNull);
        expect(cubit.state.canUndo, isTrue);
        expect(cubit.state.tanks[0].fish.length, equals(1));
        expect(cubit.state.tanks[2].fish.length, equals(1));
        expect(cubit.state.tanks[2].topFish?.speciesId, equals('blue_tang'));

        // Undo move
        cubit.undo();
        expect(cubit.state.movesCount, equals(0));
        expect(cubit.state.tanks[0].fish.length, equals(2));
        expect(cubit.state.tanks[2].isEmpty, isTrue);
      },
    );

    test(
      'Animation lifecycle: tapTank with animate creates PendingFishMove and completePendingMove finalizes',
      () async {
        final cubit = FishFamilyCubit(storage: storage);
        await cubit.loadInitial();

        cubit.tapTank(0); // Select Tank 0
        cubit.tapTank(2, animate: true); // Start animated move to Tank 2

        // Move is pending and in flight
        expect(cubit.state.isAnimating, isTrue);
        expect(cubit.state.pendingMove, isNotNull);
        expect(cubit.state.pendingMove!.fromTankId, equals(0));
        expect(cubit.state.pendingMove!.toTankId, equals(2));
        expect(cubit.state.pendingMove!.fish.speciesId, equals('blue_tang'));
        expect(
          cubit.state.movesCount,
          equals(0),
        ); // Not incremented until completed
        expect(cubit.state.canUndo, isFalse); // Locked during animation

        // Other taps and undo are ignored while animating
        cubit.tapTank(1);
        cubit.undo();
        expect(cubit.state.movesCount, equals(0));

        // Stale sequence is rejected
        cubit.completePendingMove(9999);
        expect(cubit.state.isAnimating, isTrue);
        expect(cubit.state.movesCount, equals(0));

        // Correct sequence commits the move
        final seq = cubit.state.pendingMove!.sequence;
        cubit.completePendingMove(seq);

        expect(cubit.state.isAnimating, isFalse);
        expect(cubit.state.pendingMove, isNull);
        expect(cubit.state.movesCount, equals(1));
        expect(cubit.state.tanks[0].fish.length, equals(1));
        expect(cubit.state.tanks[2].fish.length, equals(1));
      },
    );

    test(
      'cancelPendingMove clears in-flight state without mutating tanks',
      () async {
        final cubit = FishFamilyCubit(storage: storage);
        await cubit.loadInitial();

        cubit.tapTank(0);
        cubit.tapTank(2, animate: true);
        expect(cubit.state.isAnimating, isTrue);

        cubit.cancelPendingMove();
        expect(cubit.state.isAnimating, isFalse);
        expect(cubit.state.pendingMove, isNull);
        expect(cubit.state.movesCount, equals(0));
        expect(cubit.state.tanks[0].fish.length, equals(2));
        expect(cubit.state.tanks[2].isEmpty, isTrue);
      },
    );

    test(
      'Invalid move displays feedback and triggers shaking without altering board',
      () async {
        final cubit = FishFamilyCubit(storage: storage);
        await cubit.loadInitial();

        // Tank 0 top is blue_tang, Tank 1 top is clownfish
        cubit.tapTank(0); // Select Tank 0
        cubit.tapTank(1); // Invalid: species mismatch!

        expect(cubit.state.feedbackMessage, equals('Match the fish species'));
        expect(cubit.state.shakingTankId, equals(1));
        expect(cubit.state.movesCount, equals(0));
        expect(cubit.state.tanks[0].fish.length, equals(2));
        expect(cubit.state.tanks[1].fish.length, equals(2));
      },
    );

    test('Restart resets moves and restores initial layout', () async {
      final cubit = FishFamilyCubit(storage: storage);
      await cubit.loadInitial();

      cubit.tapTank(0);
      cubit.tapTank(2, animate: false);
      expect(cubit.state.movesCount, equals(1));

      cubit.restartLevel();
      expect(cubit.state.movesCount, equals(0));
      expect(cubit.state.moveHistory, isEmpty);
      expect(cubit.state.tanks[0].fish.length, equals(2));
      expect(cubit.state.tanks[2].isEmpty, isTrue);
    });

    test(
      'Intermediate move that sorts some tanks but leaves species split does not complete level',
      () async {
        final cubit = FishFamilyCubit(storage: storage);
        await cubit.loadInitial();

        // Level 1:
        // Move 1: 0 -> 2
        cubit.tapTank(0);
        cubit.tapTank(2, animate: false);
        expect(cubit.state.isWon, isFalse);

        // Move 2: 1 -> 0 (Tank 0 is pure clownfish, Tank 1 is 1 blue tang, Tank 2 is 1 blue tang)
        // Even though each tank is individually pure, the blue tang family is split!
        cubit.tapTank(1);
        cubit.tapTank(0, animate: false);

        expect(cubit.state.isWon, isFalse);
        expect(cubit.state.movesCount, equals(2));
        expect(
          await storage.getUnlockedLevel(),
          equals(1),
        ); // Next level must NOT be unlocked!
        expect((await storage.getCompletedLevels()).contains(1), isFalse);

        // Move 3: 1 -> 2 (Combines blue tangs together!)
        cubit.tapTank(1);
        cubit.tapTank(2, animate: false);

        expect(cubit.state.isWon, isTrue);
        expect(cubit.state.movesCount, equals(3));

        // Wait for async persistence
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(await storage.getUnlockedLevel(), equals(2));
        expect((await storage.getCompletedLevels()).contains(1), isTrue);
        expect(await storage.getBestMoves(1), equals(3));
      },
    );

    test('Restarting or changing level clears completion state', () async {
      final cubit = FishFamilyCubit(storage: storage);
      await cubit.loadInitial();

      // Solve level 1
      cubit.tapTank(0);
      cubit.tapTank(2, animate: false);
      cubit.tapTank(1);
      cubit.tapTank(0, animate: false);
      cubit.tapTank(1);
      cubit.tapTank(2, animate: false);

      expect(cubit.state.isWon, isTrue);

      // Restarting clears win state
      cubit.restartLevel();
      expect(cubit.state.isWon, isFalse);
      expect(cubit.state.hasShownWinDialog, isFalse);
      expect(cubit.state.movesCount, equals(0));

      // Solve again and test level selection
      cubit.tapTank(0);
      cubit.tapTank(2, animate: false);
      cubit.tapTank(1);
      cubit.tapTank(0, animate: false);
      cubit.tapTank(1);
      cubit.tapTank(2, animate: false);
      expect(cubit.state.isWon, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.selectLevel(2);
      expect(cubit.state.levelNumber, equals(2));
      expect(cubit.state.isWon, isFalse);
      expect(cubit.state.hasShownWinDialog, isFalse);
    });

    test(
      'Undoing a move restores correct playing state and resets win if undone',
      () async {
        final cubit = FishFamilyCubit(storage: storage);
        await cubit.loadInitial();

        cubit.tapTank(0);
        cubit.tapTank(2, animate: false);
        cubit.tapTank(1);
        cubit.tapTank(0, animate: false);
        cubit.tapTank(1);
        cubit.tapTank(2, animate: false);
        expect(cubit.state.isWon, isTrue);

        cubit.undo();
        expect(cubit.state.isWon, isFalse);
        expect(cubit.state.movesCount, equals(2));
        expect(cubit.state.tanks[1].fish.length, equals(1));
      },
    );

    test('In-progress session is restored after reload', () async {
      await storage.saveSession(
        const FishFamilySavedSession(
          levelNumber: 1,
          movesCount: 4,
          tanks: [
            FishTank(
              id: 0,
              capacity: 3,
              fish: [
                Fish(id: 'c1', speciesId: 'clownfish'),
                Fish(id: 'b1', speciesId: 'blue_tang'),
              ],
            ),
            FishTank(id: 1, capacity: 3, fish: []),
            FishTank(id: 2, capacity: 3, fish: []),
          ],
        ),
      );

      final cubit = FishFamilyCubit(storage: storage);
      await cubit.loadInitial();

      expect(cubit.state.movesCount, equals(4));
      expect(cubit.state.tanks[0].fish.length, equals(2));
      expect(cubit.state.tanks[1].isEmpty, isTrue);
    });
  });
}
