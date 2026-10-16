import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/worm_escape_engine.dart';
import '../domain/worm_escape_level_data.dart';
import '../domain/worm_escape_models.dart';
import '../domain/worm_escape_storage.dart';
import 'worm_escape_state.dart';

/// Cubit managing Worm Escape gameplay logic, animations, and progression.
class WormEscapeCubit extends Cubit<WormEscapeState> {
  final WormEscapeStorage storage;

  WormEscapeCubit({
    required this.storage,
    WormEscapeDifficulty? initialDifficulty,
    int? initialLevel,
  }) : super(WormEscapeState.initial()) {
    init(forcedDifficulty: initialDifficulty, forcedLevel: initialLevel);
  }

  /// Initializes the cubit by restoring user progress from storage.
  Future<void> init({
    WormEscapeDifficulty? forcedDifficulty,
    int? forcedLevel,
  }) async {
    final diff = forcedDifficulty ?? await storage.getSelectedDifficulty();
    final lvlNum = forcedLevel ?? await storage.getCurrentLevel(diff);
    final unlocked = await storage.getUnlockedLevel(diff);
    final completed = await storage.getCompletedLevels(diff);
    final best = await storage.getBestMoves(diff, lvlNum);

    final maxLvl = WormEscapeLevelData.getLevelCount(diff);
    final safeLvl = lvlNum.clamp(1, maxLvl);
    final level = WormEscapeLevelData.getLevel(diff, safeLvl);

    emit(
      state.copyWith(
        isLoading: false,
        engine: WormEscapeEngine.initial(level),
        difficulty: diff,
        levelNumber: safeLvl,
        unlockedLevel: unlocked,
        completedLevels: completed,
        bestMoves: best,
        clearAnimatingWormId: true,
        clearBlockedWormId: true,
        clearBlockingWormId: true,
        clearHintWormId: true,
        clearHintMessage: true,
      ),
    );
  }

  /// Selects a new difficulty and loads its current level.
  Future<void> selectDifficulty(WormEscapeDifficulty difficulty) async {
    if (state.difficulty == difficulty && !state.isLoading) return;

    await storage.setSelectedDifficulty(difficulty);
    final lvlNum = await storage.getCurrentLevel(difficulty);
    final unlocked = await storage.getUnlockedLevel(difficulty);
    final completed = await storage.getCompletedLevels(difficulty);
    final best = await storage.getBestMoves(difficulty, lvlNum);

    final level = WormEscapeLevelData.getLevel(difficulty, lvlNum);

    emit(
      state.copyWith(
        isLoading: false,
        engine: WormEscapeEngine.initial(level),
        difficulty: difficulty,
        levelNumber: lvlNum,
        unlockedLevel: unlocked,
        completedLevels: completed,
        bestMoves: best,
        clearAnimatingWormId: true,
        clearBlockedWormId: true,
        clearBlockingWormId: true,
        clearHintWormId: true,
        clearHintMessage: true,
      ),
    );
  }

  /// Selects and loads a specific level if it is unlocked.
  Future<void> selectLevel(int levelNumber) async {
    if (levelNumber > state.unlockedLevel) return;

    await storage.setCurrentLevel(state.difficulty, levelNumber);
    final best = await storage.getBestMoves(state.difficulty, levelNumber);
    final level = WormEscapeLevelData.getLevel(state.difficulty, levelNumber);

    emit(
      state.copyWith(
        isLoading: false,
        engine: WormEscapeEngine.initial(level),
        levelNumber: levelNumber,
        bestMoves: best,
        clearAnimatingWormId: true,
        clearBlockedWormId: true,
        clearBlockingWormId: true,
        clearHintWormId: true,
        clearHintMessage: true,
      ),
    );
  }

  /// Advances to the next level if available.
  Future<void> nextLevel() async {
    if (!state.hasNextLevel) return;
    await selectLevel(state.levelNumber + 1);
  }

  /// Restarts the current level from scratch.
  void replayLevel() {
    emit(
      state.copyWith(
        engine: state.engine.reset(),
        clearAnimatingWormId: true,
        clearBlockedWormId: true,
        clearBlockingWormId: true,
        clearHintWormId: true,
        clearHintMessage: true,
      ),
    );
  }

  /// Handles player tapping a grid cell.
  ///
  /// - If unblocked, starts escape animation.
  /// - If blocked, triggers shake feedback and highlights blocking worm.
  /// - If empty or already escaping, does nothing.
  bool tapWormAtCell(GridPosition pos) {
    if (state.isWon || state.animatingWormId != null) return false;

    final worm = state.engine.getWormAtCell(pos);
    if (worm == null || !worm.isActive) return false;

    // Check collision along escape path
    final blocker = state.engine.findBlockingWorm(worm);

    if (blocker != null) {
      // Worm is blocked! Show feedback without changing engine state
      emit(
        state.copyWith(
          blockedWormId: worm.id,
          blockingWormId: blocker.id,
          clearHintWormId: true,
          hintMessage: 'Path is blocked!',
        ),
      );
      return false;
    }

    // Path is clear! Trigger escape animation
    emit(
      state.copyWith(
        animatingWormId: worm.id,
        clearBlockedWormId: true,
        clearBlockingWormId: true,
        clearHintWormId: true,
        clearHintMessage: true,
      ),
    );
    return true;
  }

  /// Called when the escape animation finishes to commit the worm's escape to the engine.
  Future<void> onEscapeAnimationCompleted(String wormId) async {
    final updatedEngine = state.engine.escapeWorm(wormId);
    final isNowWon = updatedEngine.isCompleted;

    Set<int> updatedCompleted = state.completedLevels;
    int updatedUnlocked = state.unlockedLevel;
    int? updatedBest = state.bestMoves;

    if (isNowWon) {
      await storage.markLevelCompleted(
        state.difficulty,
        state.levelNumber,
        movesCount: updatedEngine.movesCount,
      );
      updatedCompleted = await storage.getCompletedLevels(state.difficulty);
      updatedUnlocked = await storage.getUnlockedLevel(state.difficulty);
      updatedBest = await storage.getBestMoves(
        state.difficulty,
        state.levelNumber,
      );
    }

    emit(
      state.copyWith(
        engine: updatedEngine,
        completedLevels: updatedCompleted,
        unlockedLevel: updatedUnlocked,
        bestMoves: updatedBest,
        clearAnimatingWormId: true,
        clearBlockedWormId: true,
        clearBlockingWormId: true,
        clearHintWormId: true,
      ),
    );
  }

  /// Clears blocked/shake feedback after its brief animation completes.
  void onBlockedAnimationCompleted() {
    if (state.blockedWormId != null || state.blockingWormId != null) {
      emit(
        state.copyWith(
          clearBlockedWormId: true,
          clearBlockingWormId: true,
          clearHintMessage: true,
        ),
      );
    }
  }

  /// Finds and highlights a worm that is guaranteed safe to escape.
  void requestHint() {
    if (state.isWon || state.animatingWormId != null) return;

    final hintId = state.engine.getHintWormId();
    if (hintId != null) {
      emit(
        state.copyWith(
          hintWormId: hintId,
          hintMessage: 'This worm has a clear path to escape!',
          clearBlockedWormId: true,
          clearBlockingWormId: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          hintMessage: 'No unblocked worm available. Try undo or reset.',
        ),
      );
    }
  }

  /// Undoes the last escape move.
  void undo() {
    if (!state.canUndo) return;

    emit(
      state.copyWith(
        engine: state.engine.undo(),
        clearAnimatingWormId: true,
        clearBlockedWormId: true,
        clearBlockingWormId: true,
        clearHintWormId: true,
        clearHintMessage: true,
      ),
    );
  }

  /// Resets the current level after confirmation.
  void resetLevel() {
    replayLevel();
  }
}
