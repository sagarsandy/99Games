import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/game_stats_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../domain/dots_and_boxes_engine.dart';
import '../domain/dots_and_boxes_models.dart';
import 'dots_and_boxes_state.dart';

/// Cubit managing Dots and Boxes game state, player turns, AI scheduling,
/// and game statistics persistence.
class DotsAndBoxesCubit extends Cubit<DotsAndBoxesState> {
  final GameStatsStorage _statsStorage;
  final DotsAndBoxesEngine _engine;
  final Duration _aiDelay;

  /// Monotonically increasing session ID to invalidate pending AI tasks
  /// whenever the game is restarted, resized, or settings change.
  int _turnSessionId = 0;

  DotsAndBoxesCubit({
    required GameStatsStorage statsStorage,
    DotsAndBoxesEngine? engine,
    Duration aiDelay = const Duration(milliseconds: 320),
    BoardSize initialBoardSize = BoardSize.small,
    DotsGameMode initialGameMode = DotsGameMode.vsAi,
    DotsAiDifficulty initialDifficulty = DotsAiDifficulty.medium,
  }) : _statsStorage = statsStorage,
       _engine = engine ?? DotsAndBoxesEngine(),
       _aiDelay = aiDelay,
       super(
         DotsAndBoxesState.initial(
           boardSize: initialBoardSize,
           gameMode: initialGameMode,
           aiDifficulty: initialDifficulty,
         ),
       ) {
    loadStats();
  }

  String get _statsSubKey => switch (state.gameMode) {
    DotsGameMode.vsAi => 'vs_ai_${state.aiDifficulty.name}',
    DotsGameMode.passAndPlay => 'pass_and_play',
  };

  /// Loads persisted match statistics for the active game mode.
  Future<void> loadStats() async {
    final stats = await _statsStorage.getStats(
      gameId: StorageKeys.gameDotsAndBoxes,
      subKey: _statsSubKey,
    );
    if (!isClosed) {
      emit(state.copyWith(stats: stats));
    }
  }

  /// Processes a player claiming [edge].
  Future<void> claimEdge(EdgePosition edge) async {
    if (state.isGameOver || state.isAiThinking) return;

    // In vs AI mode, user can only play on Player 1's turn
    if (state.gameMode == DotsGameMode.vsAi &&
        state.currentPlayer != DotsPlayer.player1) {
      return;
    }

    if (!_engine.isLegalMove(
      size: state.boardSize,
      horizontalEdges: state.horizontalEdges,
      verticalEdges: state.verticalEdges,
      edge: edge,
    )) {
      return;
    }

    final result = _engine.applyMove(
      size: state.boardSize,
      horizontalEdges: state.horizontalEdges,
      verticalEdges: state.verticalEdges,
      boxes: state.boxes,
      edge: edge,
      player: state.currentPlayer,
    );

    // Update board matrices
    final newH = _engine.cloneGrid(state.horizontalEdges);
    final newV = _engine.cloneGrid(state.verticalEdges);
    final newBoxes = _engine.cloneGrid(state.boxes);

    if (edge.isHorizontal) {
      newH[edge.row][edge.col] = state.currentPlayer;
    } else {
      newV[edge.row][edge.col] = state.currentPlayer;
    }

    for (final box in result.completedBoxes) {
      newBoxes[box.row][box.col] = state.currentPlayer;
    }

    final newP1Score =
        state.player1Score +
        (state.currentPlayer == DotsPlayer.player1
            ? result.completedBoxes.length
            : 0);
    final newP2Score =
        state.player2Score +
        (state.currentPlayer == DotsPlayer.player2
            ? result.completedBoxes.length
            : 0);

    if (result.isGameOver) {
      await _handleGameOver(
        horizontalEdges: newH,
        verticalEdges: newV,
        boxes: newBoxes,
        p1Score: newP1Score,
        p2Score: newP2Score,
        lastMove: edge,
        winner: result.winner,
        isDraw: result.isDraw,
      );
      return;
    }

    // Turn resolution:
    // If extra turn awarded, current player continues.
    if (result.getsExtraTurn) {
      emit(
        state.copyWith(
          horizontalEdges: newH,
          verticalEdges: newV,
          boxes: newBoxes,
          player1Score: newP1Score,
          player2Score: newP2Score,
          lastMove: () => edge,
        ),
      );
      return;
    }

    // Turn switches
    final nextPlayer = result.nextPlayer;
    if (state.gameMode == DotsGameMode.vsAi &&
        nextPlayer == DotsPlayer.player2) {
      emit(
        state.copyWith(
          horizontalEdges: newH,
          verticalEdges: newV,
          boxes: newBoxes,
          player1Score: newP1Score,
          player2Score: newP2Score,
          currentPlayer: nextPlayer,
          isAiThinking: true,
          lastMove: () => edge,
        ),
      );
      await _executeAiTurn();
    } else {
      emit(
        state.copyWith(
          horizontalEdges: newH,
          verticalEdges: newV,
          boxes: newBoxes,
          player1Score: newP1Score,
          player2Score: newP2Score,
          currentPlayer: nextPlayer,
          lastMove: () => edge,
        ),
      );
    }
  }

  /// Executes an AI turn (or chain of AI turns if extra turns are earned).
  Future<void> _executeAiTurn() async {
    final session = ++_turnSessionId;

    if (_aiDelay > Duration.zero) {
      await Future<void>.delayed(_aiDelay);
    }

    // Check if game or session changed while waiting
    if (isClosed || _turnSessionId != session || state.isGameOver) {
      return;
    }

    final aiMove = _engine.selectAiMove(
      boardSize: state.boardSize,
      horizontalEdges: state.horizontalEdges,
      verticalEdges: state.verticalEdges,
      boxes: state.boxes,
      aiPlayer: DotsPlayer.player2,
      difficulty: state.aiDifficulty,
    );

    if (aiMove == null) {
      emit(state.copyWith(isAiThinking: false));
      return;
    }

    final result = _engine.applyMove(
      size: state.boardSize,
      horizontalEdges: state.horizontalEdges,
      verticalEdges: state.verticalEdges,
      boxes: state.boxes,
      edge: aiMove,
      player: DotsPlayer.player2,
    );

    final newH = _engine.cloneGrid(state.horizontalEdges);
    final newV = _engine.cloneGrid(state.verticalEdges);
    final newBoxes = _engine.cloneGrid(state.boxes);

    if (aiMove.isHorizontal) {
      newH[aiMove.row][aiMove.col] = DotsPlayer.player2;
    } else {
      newV[aiMove.row][aiMove.col] = DotsPlayer.player2;
    }

    for (final box in result.completedBoxes) {
      newBoxes[box.row][box.col] = DotsPlayer.player2;
    }

    final newP2Score = state.player2Score + result.completedBoxes.length;

    if (result.isGameOver) {
      await _handleGameOver(
        horizontalEdges: newH,
        verticalEdges: newV,
        boxes: newBoxes,
        p1Score: state.player1Score,
        p2Score: newP2Score,
        lastMove: aiMove,
        winner: result.winner,
        isDraw: result.isDraw,
      );
      return;
    }

    if (result.getsExtraTurn) {
      // AI gets another turn; update board and schedule next AI move
      emit(
        state.copyWith(
          horizontalEdges: newH,
          verticalEdges: newV,
          boxes: newBoxes,
          player2Score: newP2Score,
          isAiThinking: true,
          lastMove: () => aiMove,
        ),
      );
      await _executeAiTurn();
    } else {
      // AI turn finished, back to human
      emit(
        state.copyWith(
          horizontalEdges: newH,
          verticalEdges: newV,
          boxes: newBoxes,
          player2Score: newP2Score,
          currentPlayer: DotsPlayer.player1,
          isAiThinking: false,
          lastMove: () => aiMove,
        ),
      );
    }
  }

  /// Finalizes the game, computes updated stats, and persists them.
  Future<void> _handleGameOver({
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required List<List<DotsPlayer?>> boxes,
    required int p1Score,
    required int p2Score,
    required EdgePosition lastMove,
    required DotsPlayer? winner,
    required bool isDraw,
  }) async {
    GameStats updatedStats = state.stats;

    if (state.gameMode == DotsGameMode.vsAi) {
      if (winner == DotsPlayer.player1) {
        updatedStats = updatedStats.copyWith(wins: updatedStats.wins + 1);
      } else if (winner == DotsPlayer.player2) {
        updatedStats = updatedStats.copyWith(losses: updatedStats.losses + 1);
      } else {
        updatedStats = updatedStats.copyWith(draws: updatedStats.draws + 1);
      }
    } else {
      if (winner == DotsPlayer.player1) {
        updatedStats = updatedStats.copyWith(wins: updatedStats.wins + 1);
      } else if (winner == DotsPlayer.player2) {
        updatedStats = updatedStats.copyWith(losses: updatedStats.losses + 1);
      } else {
        updatedStats = updatedStats.copyWith(draws: updatedStats.draws + 1);
      }
    }

    await _statsStorage.saveStats(
      gameId: StorageKeys.gameDotsAndBoxes,
      subKey: _statsSubKey,
      stats: updatedStats,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          boxes: boxes,
          player1Score: p1Score,
          player2Score: p2Score,
          status: DotsGameStatus.completed,
          winner: () => winner,
          isDraw: isDraw,
          isAiThinking: false,
          lastMove: () => lastMove,
          stats: updatedStats,
        ),
      );
    }
  }

  /// Switches board size, resetting the board to empty and resizing all edge matrices.
  void setBoardSize(BoardSize size) {
    if (state.boardSize == size) return;
    _turnSessionId++;

    emit(
      DotsAndBoxesState.initial(
        boardSize: size,
        gameMode: state.gameMode,
        aiDifficulty: state.aiDifficulty,
        stats: state.stats,
      ),
    );
  }

  /// Sets the play mode (vs Computer or 2 Players) and reloads mode-specific stats.
  Future<void> setGameMode(DotsGameMode mode) async {
    if (state.gameMode == mode) return;
    _turnSessionId++;

    final nextState = DotsAndBoxesState.initial(
      boardSize: state.boardSize,
      gameMode: mode,
      aiDifficulty: state.aiDifficulty,
      stats: state.stats,
    );
    emit(nextState);

    await loadStats();
  }

  /// Sets the AI difficulty level.
  Future<void> setAiDifficulty(DotsAiDifficulty difficulty) async {
    if (state.aiDifficulty == difficulty) return;
    _turnSessionId++;

    final nextState = DotsAndBoxesState.initial(
      boardSize: state.boardSize,
      gameMode: state.gameMode,
      aiDifficulty: difficulty,
      stats: state.stats,
    );
    emit(nextState);

    await loadStats();
  }

  /// Clears the board for a new game on the current size and mode.
  void restartGame() {
    _turnSessionId++;

    emit(
      DotsAndBoxesState.initial(
        boardSize: state.boardSize,
        gameMode: state.gameMode,
        aiDifficulty: state.aiDifficulty,
        stats: state.stats,
      ),
    );
  }

  /// Clears tracked statistics in storage and memory for active configuration.
  Future<void> resetScores() async {
    await _statsStorage.resetStats(
      gameId: StorageKeys.gameDotsAndBoxes,
      subKey: _statsSubKey,
    );
    if (!isClosed) {
      emit(state.copyWith(stats: GameStats.empty));
    }
  }
}
