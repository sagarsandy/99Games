import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/fruit_catcher_engine.dart';
import '../domain/fruit_catcher_models.dart';
import '../domain/fruit_catcher_storage.dart';
import 'fruit_catcher_state.dart';

/// Cubit managing Fruit Catcher state, physics updates, input, and score persistence.
class FruitCatcherCubit extends Cubit<FruitCatcherState> {
  final FruitCatcherStorage storage;
  final FruitCatcherEngine engine;

  FruitCatcherCubit({required this.storage, FruitCatcherEngine? engine})
    : engine = engine ?? FruitCatcherEngine(),
      super(const FruitCatcherState());

  /// Initializes the cubit and loads saved best score.
  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true));
    final bestScore = await storage.getBestScore();
    emit(
      state.copyWith(
        bestScore: bestScore,
        status: GameStatus.ready,
        isLoading: false,
      ),
    );
  }

  /// Begins a new game round from the start screen or replay button.
  void startGame() {
    if (state.isPlaying) return; // Prevent duplicate game loop triggers

    emit(
      state.copyWith(
        status: GameStatus.playing,
        score: 0,
        lives: FruitCatcherEngine.initialLives,
        timeRemaining: FruitCatcherEngine.roundDuration,
        isNewRecord: false,
        items: const [],
        particles: const [],
        indicators: const [],
        isDamaged: false,
        timeSinceLastSpawn: 0.0,
        nextItemId: 1,
        nextIndicatorId: 1,
        basket: const BasketModel(),
      ),
    );
  }

  /// Moves the basket to a normalized horizontal position (0.0 to 1.0).
  void moveBasket(double normalizedX) {
    if (!state.isPlaying) return;
    emit(state.copyWith(basket: state.basket.moveTo(normalizedX)));
  }

  /// Nudges the basket left or right by [delta].
  void nudgeBasket(double delta) {
    if (!state.isPlaying) return;
    emit(state.copyWith(basket: state.basket.nudge(delta)));
  }

  /// Advances the simulation by [dt] seconds.
  ///
  /// Can be driven by a frame Ticker or called deterministically in tests.
  void updateGame(double dt) {
    if (!state.isPlaying) return;

    final newTimeRemaining = math.max(0.0, state.timeRemaining - dt);
    final elapsed = (FruitCatcherEngine.roundDuration - newTimeRemaining).clamp(
      0.0,
      FruitCatcherEngine.roundDuration,
    );

    // 1. Spawning
    final newTimeSinceSpawn = state.timeSinceLastSpawn + dt;
    final currentItems = List<FallingItem>.from(state.items);
    var nextItemId = state.nextItemId;
    double updatedTimeSinceSpawn = newTimeSinceSpawn;

    final spawnedItem = engine.maybeSpawnItem(
      timeSinceLastSpawn: newTimeSinceSpawn,
      elapsedSeconds: elapsed,
      currentItems: currentItems,
      basketX: state.basket.x,
      nextId: nextItemId,
    );

    if (spawnedItem != null) {
      currentItems.add(spawnedItem);
      nextItemId++;
      updatedTimeSinceSpawn = 0.0;
    }

    // 2. Physics & Collisions
    final physicsResult = engine.updatePhysics(
      items: currentItems,
      basket: state.basket,
      dt: dt,
      nextIndicatorId: state.nextIndicatorId,
    );

    final newScore = state.score + physicsResult.pointsEarned;
    final newLives = math.max(0, state.lives - physicsResult.livesLost);

    // 3. Particles & Floating Indicators update
    final allParticles = [
      ...state.particles.map((p) => p.update(dt)).where((p) => !p.isExpired),
      ...physicsResult.newParticles,
    ];

    final allIndicators = [
      ...state.indicators.map((i) => i.update(dt)).where((i) => !i.isExpired),
      ...physicsResult.newIndicators,
    ];

    // Check round over condition (time out OR 0 lives)
    final isRoundOver = newTimeRemaining <= 0.0 || newLives <= 0;

    if (isRoundOver) {
      final isNewRecord = newScore > state.bestScore;
      final finalBest = math.max(state.bestScore, newScore);

      if (isNewRecord) {
        storage.setBestScore(finalBest);
      }

      emit(
        state.copyWith(
          status: GameStatus.gameOver,
          score: newScore,
          bestScore: finalBest,
          isNewRecord: isNewRecord,
          lives: newLives,
          timeRemaining: newTimeRemaining,
          items: const [], // Clear items on game over to freeze scene cleanly
          particles: allParticles,
          indicators: allIndicators,
          isDamaged: physicsResult.hitBomb,
          timeSinceLastSpawn: updatedTimeSinceSpawn,
          nextItemId: nextItemId,
          nextIndicatorId:
              state.nextIndicatorId + physicsResult.newIndicators.length,
        ),
      );
      return;
    }

    // Regular active frame update
    emit(
      state.copyWith(
        score: newScore,
        lives: newLives,
        timeRemaining: newTimeRemaining,
        items: physicsResult.activeItems,
        particles: allParticles,
        indicators: allIndicators,
        isDamaged: physicsResult.hitBomb,
        timeSinceLastSpawn: updatedTimeSinceSpawn,
        nextItemId: nextItemId,
        nextIndicatorId:
            state.nextIndicatorId + physicsResult.newIndicators.length,
      ),
    );
  }

  /// Restarts a fresh 60-second round while retaining best score.
  void playAgain() {
    startGame();
  }

  /// Resets back to start screen while retaining best score.
  void resetToReady() {
    emit(
      state.copyWith(
        status: GameStatus.ready,
        score: 0,
        lives: FruitCatcherEngine.initialLives,
        timeRemaining: FruitCatcherEngine.roundDuration,
        items: const [],
        particles: const [],
        indicators: const [],
        isDamaged: false,
      ),
    );
  }
}
