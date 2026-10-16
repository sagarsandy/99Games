import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/fish_family_engine.dart';
import '../domain/fish_family_level_data.dart';
import '../domain/fish_family_models.dart';
import '../domain/fish_family_storage.dart';
import 'fish_family_state.dart';

/// Cubit managing state transitions, moves, undo, and persistence for Fish Family Rescue.
class FishFamilyCubit extends Cubit<FishFamilyState> {
  final FishFamilyStorage storage;
  final FishFamilyEngine engine;

  FishFamilyCubit({
    required this.storage,
    this.engine = const FishFamilyEngine(),
  }) : super(
         FishFamilyState(
           levelNumber: 1,
           unlockedLevel: 1,
           completedLevels: const {},
           tanks: FishFamilyLevelData.getLevel(1).tanks,
           isLoading: true,
         ),
       ) {
    loadInitial();
  }

  /// Initializes the cubit by reading saved progress and active sessions.
  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true));

    final unlocked = await storage.getUnlockedLevel();
    final completed = await storage.getCompletedLevels();
    final savedCurrent = await storage.getCurrentLevel();
    final currentLevel = savedCurrent.clamp(1, unlocked);

    final best = await storage.getBestMoves(currentLevel);
    final savedSession = await storage.getSavedSession();
    final currentLevelDef = FishFamilyLevelData.getLevel(currentLevel);

    if (savedSession != null &&
        savedSession.levelNumber == currentLevel &&
        !engine.isLevelComplete(savedSession.tanks, currentLevelDef)) {
      // Restore in-progress session
      emit(
        FishFamilyState(
          levelNumber: currentLevel,
          unlockedLevel: unlocked,
          completedLevels: completed,
          tanks: savedSession.tanks,
          movesCount: savedSession.movesCount,
          bestMoves: best,
          isLoading: false,
        ),
      );
    } else {
      // Fresh level load
      final level = FishFamilyLevelData.getLevel(currentLevel);
      emit(
        FishFamilyState(
          levelNumber: currentLevel,
          unlockedLevel: unlocked,
          completedLevels: completed,
          tanks: level.tanks,
          movesCount: 0,
          bestMoves: best,
          isLoading: false,
        ),
      );
    }
  }

  int _moveSequence = 0;

  /// Selects a tank or starts an in-flight move if a source tank is selected.
  void tapTank(int tankId, {bool animate = true}) {
    if (state.isWon || state.isAnimating) return;

    final selectedId = state.selectedTankId;

    // No tank currently selected: select source
    if (selectedId == null) {
      final tank = state.tanks.firstWhere((t) => t.id == tankId);
      if (tank.isEmpty) return; // Cannot select an empty tank

      emit(
        state.copyWith(
          selectedTankId: () => tankId,
          feedbackMessage: () => null,
          shakingTankId: () => null,
        ),
      );
      return;
    }

    // Tapping the currently selected source tank: deselect
    if (selectedId == tankId) {
      emit(
        state.copyWith(
          selectedTankId: () => null,
          feedbackMessage: () => null,
          shakingTankId: () => null,
        ),
      );
      return;
    }

    // A source tank is selected and a different tank was tapped: validate move
    final validation = engine.validateMove(state.tanks, selectedId, tankId);

    if (!validation.isValid) {
      // If user tapped a different tank that also has fish, allow switching selection
      if (state.shakingTankId == tankId) {
        final newSource = state.tanks.firstWhere((t) => t.id == tankId);
        if (!newSource.isEmpty) {
          emit(
            state.copyWith(
              selectedTankId: () => tankId,
              feedbackMessage: () => null,
              shakingTankId: () => null,
            ),
          );
          return;
        }
      }

      // Show invalid move feedback and shake the destination tank
      emit(
        state.copyWith(
          feedbackMessage: () => validation.errorMessage ?? 'Invalid move',
          shakingTankId: () => tankId,
        ),
      );
      return;
    }

    // Move is valid:
    final sourceTank = state.tanks.firstWhere((t) => t.id == selectedId);
    final movingFish = sourceTank.topFish!;

    if (!animate) {
      _finalizeMove(selectedId, tankId);
      return;
    }

    _moveSequence++;
    emit(
      state.copyWith(
        selectedTankId: () => null,
        feedbackMessage: () => null,
        shakingTankId: () => null,
        pendingMove: () => PendingFishMove(
          fromTankId: selectedId,
          toTankId: tankId,
          fish: movingFish,
          sequence: _moveSequence,
        ),
      ),
    );
  }

  /// Finalizes the in-flight move animation when [sequence] matches active move.
  void completePendingMove(int sequence) {
    if (state.pendingMove == null || state.pendingMove!.sequence != sequence) {
      return; // Reject stale or cancelled animation callback
    }
    final move = state.pendingMove!;
    _finalizeMove(move.fromTankId, move.toTankId);
  }

  /// Cancels an in-flight move animation without committing board changes.
  void cancelPendingMove() {
    if (state.pendingMove == null) return;
    _moveSequence++;
    emit(
      state.copyWith(
        pendingMove: () => null,
        selectedTankId: () => null,
        feedbackMessage: () => null,
        shakingTankId: () => null,
      ),
    );
  }

  void _finalizeMove(int fromTankId, int toTankId) {
    final result = engine.executeMove(state.tanks, fromTankId, toTankId);
    final newMovesCount = state.movesCount + 1;
    final newHistory = [...state.moveHistory, result.move];

    // Check win condition using single authoritative method
    final level = state.level;
    final isWon = engine.isLevelComplete(result.tanks, level);

    emit(
      state.copyWith(
        tanks: result.tanks,
        movesCount: newMovesCount,
        moveHistory: newHistory,
        selectedTankId: () => null,
        feedbackMessage: () => null,
        shakingTankId: () => null,
        pendingMove: () => null,
        isWon: isWon,
        hasShownWinDialog: false,
      ),
    );

    if (isWon) {
      _handleWin(newMovesCount);
    } else {
      // Save current in-progress state
      storage.saveSession(
        FishFamilySavedSession(
          levelNumber: state.levelNumber,
          movesCount: newMovesCount,
          tanks: result.tanks,
        ),
      );
    }
  }

  /// Explicitly changes the source selection to [tankId].
  void selectSource(int tankId) {
    if (state.isWon || state.isAnimating) return;
    final tank = state.tanks.firstWhere((t) => t.id == tankId);
    if (tank.isEmpty) return;

    emit(
      state.copyWith(
        selectedTankId: () => tankId,
        feedbackMessage: () => null,
        shakingTankId: () => null,
      ),
    );
  }

  /// Deselects any currently selected source tank.
  void deselectSource() {
    if (state.isAnimating) return;
    emit(
      state.copyWith(
        selectedTankId: () => null,
        feedbackMessage: () => null,
        shakingTankId: () => null,
      ),
    );
  }

  /// Reverses the most recent fish move.
  void undo() {
    if (!state.canUndo || state.isAnimating) return;

    final lastMove = state.moveHistory.last;
    final restoredTanks = engine.undoMove(state.tanks, lastMove);
    final newHistory = List<FishMove>.of(state.moveHistory)..removeLast();
    final newMovesCount = (state.movesCount - 1).clamp(0, 9999);

    final isStillWon = engine.isLevelComplete(restoredTanks, state.level);

    emit(
      state.copyWith(
        tanks: restoredTanks,
        movesCount: newMovesCount,
        moveHistory: newHistory,
        selectedTankId: () => null,
        feedbackMessage: () => null,
        shakingTankId: () => null,
        pendingMove: () => null,
        isWon: isStillWon,
        hasShownWinDialog: isStillWon ? state.hasShownWinDialog : false,
      ),
    );

    storage.saveSession(
      FishFamilySavedSession(
        levelNumber: state.levelNumber,
        movesCount: newMovesCount,
        tanks: restoredTanks,
      ),
    );
  }

  /// Restores the initial layout of the current level.
  void restartLevel() {
    _moveSequence++;
    final level = FishFamilyLevelData.getLevel(state.levelNumber);

    emit(
      state.copyWith(
        tanks: level.tanks,
        movesCount: 0,
        moveHistory: const [],
        selectedTankId: () => null,
        feedbackMessage: () => null,
        shakingTankId: () => null,
        pendingMove: () => null,
        isWon: false,
        hasShownWinDialog: false,
      ),
    );

    storage.clearSavedSession();
  }

  /// Switches to a specific unlocked [levelNumber].
  Future<void> selectLevel(int levelNumber) async {
    if (levelNumber > state.unlockedLevel ||
        levelNumber < 1 ||
        levelNumber > FishFamilyLevelData.totalLevels) {
      return;
    }

    _moveSequence++;
    final level = FishFamilyLevelData.getLevel(levelNumber);
    final best = await storage.getBestMoves(levelNumber);
    await storage.setCurrentLevel(levelNumber);

    emit(
      state.copyWith(
        levelNumber: levelNumber,
        tanks: level.tanks,
        movesCount: 0,
        bestMoves: () => best,
        moveHistory: const [],
        selectedTankId: () => null,
        feedbackMessage: () => null,
        shakingTankId: () => null,
        pendingMove: () => null,
        isWon: false,
        hasShownWinDialog: false,
      ),
    );

    await storage.clearSavedSession();
  }

  /// Advances to the next level if unlocked.
  Future<void> nextLevel() async {
    if (!state.hasNextLevel) return;
    await selectLevel(state.levelNumber + 1);
  }

  /// Marks that the completion dialog has been presented.
  void markWinDialogShown() {
    emit(state.copyWith(hasShownWinDialog: true));
  }

  /// Clears active feedback message and shaking effect.
  void clearFeedback() {
    emit(
      state.copyWith(feedbackMessage: () => null, shakingTankId: () => null),
    );
  }

  Future<void> _handleWin(int finalMoves) async {
    final levelNum = state.levelNumber;
    await storage.markLevelCompleted(levelNum, movesCount: finalMoves);

    final unlocked = await storage.getUnlockedLevel();
    final completed = await storage.getCompletedLevels();
    final best = await storage.getBestMoves(levelNum);

    emit(
      state.copyWith(
        unlockedLevel: unlocked,
        completedLevels: completed,
        bestMoves: () => best,
      ),
    );
  }
}
