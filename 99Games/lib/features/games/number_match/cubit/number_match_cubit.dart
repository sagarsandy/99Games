import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/number_match_engine.dart';
import '../domain/number_match_models.dart';
import '../domain/number_match_storage.dart';
import 'number_match_state.dart';

/// Cubit managing state transitions, user interactions, undo history,
/// hints, timer, and storage persistence for Number Match.
class NumberMatchCubit extends Cubit<NumberMatchState> {
  final NumberMatchStorage storage;
  final NumberMatchEngine engine;
  final bool isDeterministic;

  Timer? _timer;

  NumberMatchCubit({
    required this.storage,
    this.engine = const NumberMatchEngine(),
    this.isDeterministic = false,
  }) : super(
         NumberMatchState(
           tiles: isDeterministic
               ? engine.createClassicBoard()
               : engine.createRandomBoard(),
         ),
       ) {
    init();
  }

  /// Initializes the game session by attempting to restore saved progress,
  /// or starting a fresh game if no valid in-progress session exists.
  Future<void> init() async {
    final stats = await storage.getStats();

    if (isDeterministic) {
      emit(state.copyWith(tiles: engine.createClassicBoard(), stats: stats));
      return;
    }

    final saved = await storage.getSavedSession();
    if (saved != null &&
        saved.status == NumberMatchGameStatus.inProgress &&
        saved.tiles.isNotEmpty &&
        !engine.isGameWon(saved.tiles)) {
      emit(
        NumberMatchState(
          tiles: saved.tiles,
          score: saved.score,
          pairsCleared: saved.pairsCleared,
          elapsedSeconds: saved.elapsedSeconds,
          isTimerRunning: saved.elapsedSeconds > 0,
          actionHistory: saved.actionHistory,
          status: saved.status,
          stats: stats,
        ),
      );

      if (saved.elapsedSeconds > 0) {
        _startTimer();
      }
      return;
    }

    // Start a fresh game
    await storage.recordGameStarted();
    final freshTiles = engine.createRandomBoard();
    emit(NumberMatchState(tiles: freshTiles, stats: stats));
  }

  /// Handles player tapping a tile in the grid.
  void selectTile(int index) {
    if (state.isWon) return;
    if (index < 0 || index >= state.tiles.length) return;
    if (state.tiles[index].isCleared) return;

    if (!state.isTimerRunning && state.elapsedSeconds == 0) {
      _startTimer();
    }

    final currentSelected = state.selectedIndex;

    // First selection
    if (currentSelected == null) {
      emit(
        state.copyWith(
          selectedIndex: index,
          clearHintPair: true,
          clearFeedbackMessage: true,
        ),
      );
      return;
    }

    // Tapping the same selected tile deselects it
    if (currentSelected == index) {
      emit(
        state.copyWith(
          clearSelectedIndex: true,
          clearHintPair: true,
          clearFeedbackMessage: true,
        ),
      );
      return;
    }

    // Second selection: validate match
    final validation = engine.validateMatch(
      currentSelected,
      index,
      state.tiles,
    );

    if (validation.isValid) {
      _applyPairMatch(currentSelected, index);
    } else {
      // Invalid match: smooth continuation with the newly tapped tile
      emit(
        state.copyWith(
          selectedIndex: index,
          clearHintPair: true,
          feedbackMessage: validation.message,
        ),
      );
    }
  }

  void _applyPairMatch(int indexA, int indexB) {
    final tileA = state.tiles[indexA];
    final tileB = state.tiles[indexB];

    final updatedTiles = List<NumberMatchTile>.from(state.tiles);
    updatedTiles[indexA] = tileA.copyWith(isCleared: true);
    updatedTiles[indexB] = tileB.copyWith(isCleared: true);

    final pairPoints = NumberMatchEngine.pairScore;
    final rowBonus = engine.calculateRowClearBonus(
      indexA: indexA,
      indexB: indexB,
      beforeTiles: state.tiles,
      afterTiles: updatedTiles,
    );

    final totalPoints = pairPoints + rowBonus;
    final newScore = state.score + totalPoints;
    final newPairsCleared = state.pairsCleared + 1;

    final action = ClearPairAction(
      firstIndex: indexA,
      firstTile: tileA,
      secondIndex: indexB,
      secondTile: tileB,
      pointsAwarded: pairPoints,
      rowBonusAwarded: rowBonus,
    );

    final newHistory = List<NumberMatchAction>.from(state.actionHistory)
      ..add(action);

    final isWon = engine.isGameWon(updatedTiles);
    final finalScore = isWon ? newScore + NumberMatchEngine.winBonus : newScore;

    if (isWon) {
      _timer?.cancel();
      storage.clearSavedSession();
      storage.recordGameWon(score: finalScore, pairsCleared: newPairsCleared);

      emit(
        state.copyWith(
          tiles: updatedTiles,
          score: finalScore,
          pairsCleared: newPairsCleared,
          isTimerRunning: false,
          actionHistory: newHistory,
          status: NumberMatchGameStatus.won,
          clearSelectedIndex: true,
          clearHintPair: true,
          feedbackMessage: 'Victory! All numbers cleared!',
        ),
      );
      _refreshStats();
    } else {
      String? msg;
      if (rowBonus > 0) {
        msg = 'Row cleared! +$rowBonus bonus!';
      }

      emit(
        state.copyWith(
          tiles: updatedTiles,
          score: finalScore,
          pairsCleared: newPairsCleared,
          actionHistory: newHistory,
          clearSelectedIndex: true,
          clearHintPair: true,
          feedbackMessage: msg,
          clearFeedbackMessage: msg == null,
        ),
      );

      _saveSession();
    }
  }

  /// Appends the remaining active numbers to the end of the sequence.
  void addNumbers() {
    if (state.isWon) return;

    if (state.activeCount == 0) {
      // Board is already cleared: win
      _triggerVictory();
      return;
    }

    final result = engine.addRemainingNumbers(state.tiles);
    if (result.addedCount == 0) return;

    final action = AddNumbersAction(addedCount: result.addedCount);
    final newHistory = List<NumberMatchAction>.from(state.actionHistory)
      ..add(action);

    emit(
      state.copyWith(
        tiles: result.tiles,
        actionHistory: newHistory,
        clearSelectedIndex: true,
        clearHintPair: true,
        feedbackMessage: 'Added ${result.addedCount} numbers to the board.',
      ),
    );

    _saveSession();
  }

  /// Finds and highlights a valid pair on the board.
  void requestHint() {
    if (state.isWon) return;

    final pair = engine.findFirstValidPair(state.tiles);
    if (pair != null) {
      emit(
        state.copyWith(
          hintPair: pair,
          clearSelectedIndex: true,
          feedbackMessage: 'Hint: Here is a matching pair!',
        ),
      );
    } else {
      emit(
        state.copyWith(
          clearHintPair: true,
          clearSelectedIndex: true,
          feedbackMessage: 'No matching pairs left! Tap "Add Numbers".',
        ),
      );
    }
  }

  /// Reverts the most recent user action (cleared pair or added numbers).
  void undo() {
    if (!state.canUndo) return;

    final history = List<NumberMatchAction>.from(state.actionHistory);
    final lastAction = history.removeLast();

    if (lastAction is ClearPairAction) {
      final updatedTiles = List<NumberMatchTile>.from(state.tiles);
      updatedTiles[lastAction.firstIndex] = lastAction.firstTile;
      updatedTiles[lastAction.secondIndex] = lastAction.secondTile;

      final pointsToDeduct =
          lastAction.pointsAwarded + lastAction.rowBonusAwarded;
      final newScore = (state.score - pointsToDeduct).clamp(0, 999999);
      final newPairs = (state.pairsCleared - 1).clamp(0, 999999);

      emit(
        state.copyWith(
          tiles: updatedTiles,
          score: newScore,
          pairsCleared: newPairs,
          actionHistory: history,
          clearSelectedIndex: true,
          clearHintPair: true,
          feedbackMessage: 'Move undone.',
        ),
      );
    } else if (lastAction is AddNumbersAction) {
      final newLength = state.tiles.length - lastAction.addedCount;
      if (newLength >= 0) {
        final updatedTiles = state.tiles.sublist(0, newLength);
        emit(
          state.copyWith(
            tiles: updatedTiles,
            actionHistory: history,
            clearSelectedIndex: true,
            clearHintPair: true,
            feedbackMessage: 'Added numbers undone.',
          ),
        );
      }
    }

    _saveSession();
  }

  /// Restarts the game with a fresh board.
  Future<void> restartGame({bool? randomized}) async {
    _timer?.cancel();
    await storage.clearSavedSession();
    await storage.recordGameStarted();

    final isRandom = randomized ?? !isDeterministic;
    final freshTiles = isRandom
        ? engine.createRandomBoard()
        : engine.createClassicBoard();

    final stats = await storage.getStats();

    emit(
      NumberMatchState(
        tiles: freshTiles,
        score: 0,
        pairsCleared: 0,
        elapsedSeconds: 0,
        isTimerRunning: false,
        actionHistory: const [],
        status: NumberMatchGameStatus.inProgress,
        stats: stats,
      ),
    );
  }

  void _triggerVictory() {
    _timer?.cancel();
    storage.clearSavedSession();
    storage.recordGameWon(
      score: state.score + NumberMatchEngine.winBonus,
      pairsCleared: state.pairsCleared,
    );

    emit(
      state.copyWith(
        score: state.score + NumberMatchEngine.winBonus,
        status: NumberMatchGameStatus.won,
        isTimerRunning: false,
        clearSelectedIndex: true,
        clearHintPair: true,
        feedbackMessage: 'Victory! All numbers cleared!',
      ),
    );

    _refreshStats();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isWon) {
        timer.cancel();
        return;
      }
      emit(
        state.copyWith(
          elapsedSeconds: state.elapsedSeconds + 1,
          isTimerRunning: true,
        ),
      );
    });
    emit(state.copyWith(isTimerRunning: true));
  }

  void pauseTimer() {
    if (!state.isTimerRunning) return;
    _timer?.cancel();
    _timer = null;
    emit(state.copyWith(isTimerRunning: false));
  }

  void resumeTimer() {
    if (state.isWon || state.isTimerRunning) return;
    if (state.elapsedSeconds > 0) {
      _startTimer();
    }
  }

  Future<void> _refreshStats() async {
    final stats = await storage.getStats();
    emit(state.copyWith(stats: stats));
  }

  Future<void> resetStats() async {
    await storage.resetStats();
    emit(state.copyWith(stats: const NumberMatchStats()));
  }

  void _saveSession() {
    if (state.isWon) return;
    final session = NumberMatchSavedSession(
      tiles: state.tiles,
      score: state.score,
      pairsCleared: state.pairsCleared,
      elapsedSeconds: state.elapsedSeconds,
      actionHistory: state.actionHistory,
      status: state.status,
    );
    storage.saveSession(session);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
