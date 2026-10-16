import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/fruit_catcher/cubit/fruit_catcher_cubit.dart';
import 'package:mini_games_99/features/games/fruit_catcher/domain/fruit_catcher_models.dart';
import 'package:mini_games_99/features/games/fruit_catcher/domain/fruit_catcher_storage.dart';

class MockFruitCatcherStorage implements FruitCatcherStorage {
  int _storedBest = 0;
  int saveCount = 0;

  MockFruitCatcherStorage({int initialBest = 0}) : _storedBest = initialBest;

  @override
  Future<int> getBestScore() async => _storedBest;

  @override
  Future<void> setBestScore(int score) async {
    saveCount++;
    _storedBest = score;
  }

  @override
  Future<void> resetAll() async {
    _storedBest = 0;
  }
}

void main() {
  group('FruitCatcherCubit Tests', () {
    test(
      '1. Cubit initializes with default state and loads saved best score',
      () async {
        final storage = MockFruitCatcherStorage(initialBest: 150);
        final cubit = FruitCatcherCubit(storage: storage);

        expect(cubit.state.status, equals(GameStatus.ready));
        expect(cubit.state.score, equals(0));
        expect(cubit.state.lives, equals(3));
        expect(cubit.state.timeRemaining, equals(60.0));

        await cubit.loadInitial();

        expect(cubit.state.bestScore, equals(150));
        expect(cubit.state.isLoading, isFalse);
      },
    );

    test('2. startGame transitions state to playing with 60s and 3 lives', () {
      final storage = MockFruitCatcherStorage();
      final cubit = FruitCatcherCubit(storage: storage);

      cubit.startGame();

      expect(cubit.state.status, equals(GameStatus.playing));
      expect(cubit.state.score, equals(0));
      expect(cubit.state.lives, equals(3));
      expect(cubit.state.timeRemaining, equals(60.0));
    });

    test(
      '3. Repeated startGame taps cannot create multiple game loops or restart unexpectedly',
      () {
        final storage = MockFruitCatcherStorage();
        final cubit = FruitCatcherCubit(storage: storage);

        cubit.startGame();
        // Simulate score progress
        cubit.updateGame(0.1);
        final scoreBefore = cubit.state.score;
        final timeBefore = cubit.state.timeRemaining;

        // Second start call while already playing should be ignored
        cubit.startGame();

        expect(cubit.state.status, equals(GameStatus.playing));
        expect(cubit.state.timeRemaining, equals(timeBefore));
        expect(cubit.state.score, equals(scoreBefore));
      },
    );

    test('4. Basket movement is responsive and clamped within boundaries', () {
      final storage = MockFruitCatcherStorage();
      final cubit = FruitCatcherCubit(storage: storage);

      cubit.startGame();

      // Basket half-width is 0.12, so clamped range is [0.12, 0.88]
      cubit.moveBasket(0.5);
      expect(cubit.state.basket.x, closeTo(0.5, 0.001));

      cubit.moveBasket(-0.8);
      expect(cubit.state.basket.x, closeTo(0.12, 0.001));

      cubit.moveBasket(1.5);
      expect(cubit.state.basket.x, closeTo(0.88, 0.001));

      // Nudge basket
      cubit.moveBasket(0.5);
      cubit.nudgeBasket(0.1);
      expect(cubit.state.basket.x, closeTo(0.6, 0.001));

      cubit.nudgeBasket(-0.2);
      expect(cubit.state.basket.x, closeTo(0.4, 0.001));
    });

    test(
      '5. Game over triggers when time reaches 0, persists new high score',
      () async {
        final storage = MockFruitCatcherStorage(initialBest: 50);
        final cubit = FruitCatcherCubit(storage: storage);
        await cubit.loadInitial();

        cubit.startGame();

        // Artificially award 80 score by adding a normal fruit collision
        final basket = cubit.state.basket;
        final fruit = FallingItem(
          id: 99,
          type: FruitType.golden,
          x: basket.x,
          y: basket.y,
          speed: 0.1,
        );

        // Force-inject items and simulate time expiration
        cubit.emit(
          cubit.state.copyWith(items: [fruit], score: 40, timeRemaining: 0.02),
        );

        // Frame tick pushes time to 0
        cubit.updateGame(0.03);

        expect(cubit.state.status, equals(GameStatus.gameOver));
        expect(cubit.state.timeRemaining, equals(0.0));
        expect(cubit.state.score, greaterThan(50));
        expect(cubit.state.isNewRecord, isTrue);
        expect(cubit.state.bestScore, equals(cubit.state.score));

        // Check persistence
        await pumpEventQueue();
        expect(storage.saveCount, equals(1));
        expect(await storage.getBestScore(), equals(cubit.state.score));
      },
    );

    test('6. Losing final life ends the round immediately', () async {
      final storage = MockFruitCatcherStorage();
      final cubit = FruitCatcherCubit(storage: storage);

      cubit.startGame();
      cubit.emit(cubit.state.copyWith(lives: 1));

      // Bomb hits basket
      final bomb = FallingItem(
        id: 101,
        type: FruitType.bomb,
        x: cubit.state.basket.x,
        y: cubit.state.basket.y,
        speed: 0.1,
      );

      cubit.emit(cubit.state.copyWith(items: [bomb]));
      cubit.updateGame(0.016);

      expect(cubit.state.lives, equals(0));
      expect(cubit.state.status, equals(GameStatus.gameOver));
    });

    test(
      '7. Play Again resets round values but preserves saved best score',
      () async {
        final storage = MockFruitCatcherStorage(initialBest: 100);
        final cubit = FruitCatcherCubit(storage: storage);
        await cubit.loadInitial();

        cubit.startGame();
        // Simulate game over with 120 points
        cubit.emit(
          cubit.state.copyWith(
            status: GameStatus.gameOver,
            score: 120,
            bestScore: 120,
            lives: 0,
            timeRemaining: 0.0,
            isNewRecord: true,
          ),
        );

        // Tap Play Again
        cubit.playAgain();

        expect(cubit.state.status, equals(GameStatus.playing));
        expect(cubit.state.score, equals(0));
        expect(cubit.state.lives, equals(3));
        expect(cubit.state.timeRemaining, equals(60.0));
        expect(cubit.state.bestScore, equals(120)); // Retained!
        expect(cubit.state.isNewRecord, isFalse);
      },
    );

    test('8. resetToReady returns state to ready and cleans play objects', () {
      final storage = MockFruitCatcherStorage();
      final cubit = FruitCatcherCubit(storage: storage);

      cubit.startGame();
      cubit.resetToReady();

      expect(cubit.state.status, equals(GameStatus.ready));
      expect(cubit.state.items.isEmpty, isTrue);
      expect(cubit.state.particles.isEmpty, isTrue);
      expect(cubit.state.indicators.isEmpty, isTrue);
    });
  });
}
