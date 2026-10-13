import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/game_stats_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../domain/tic_tac_toe_engine.dart';
import '../domain/tic_tac_toe_models.dart';
import 'tic_tac_toe_state.dart';

/// Cubit managing Tic-Tac-Toe game logic, AI turns, and score persistence.
class TicTacToeCubit extends Cubit<TicTacToeState> {
  final GameStatsStorage _statsStorage;
  final TicTacToeEngine _engine;
  final Duration _aiDelay;

  TicTacToeCubit({
    required GameStatsStorage statsStorage,
    TicTacToeEngine? engine,
    Duration aiDelay = const Duration(milliseconds: 320),
  }) : _statsStorage = statsStorage,
       _engine = engine ?? TicTacToeEngine(),
       _aiDelay = aiDelay,
       super(TicTacToeState.initial()) {
    loadStats();
  }

  String get _statsSubKey => switch (state.gameMode) {
    GameMode.vsAi => 'vs_ai_${state.aiDifficulty.name}',
    GameMode.passAndPlay => 'pass_and_play',
  };

  /// Loads persisted stats for the active game mode & difficulty.
  Future<void> loadStats() async {
    final stats = await _statsStorage.getStats(
      gameId: StorageKeys.gameTicTacToe,
      subKey: _statsSubKey,
    );
    if (!isClosed) {
      emit(state.copyWith(stats: stats));
    }
  }

  /// Handles user tapping a cell at [index].
  Future<void> makeMove(int index) async {
    if (state.isGameOver || state.isAiThinking) return;

    // In AI mode, user can only move on X's turn
    if (state.gameMode == GameMode.vsAi &&
        state.currentPlayer != PlayerSymbol.x) {
      return;
    }

    if (!_engine.isValidMove(state.board, index)) return;

    final updatedBoard = _engine.applyMove(
      state.board,
      index,
      state.currentPlayer,
    );
    final result = _engine.evaluateBoard(updatedBoard);

    if (result.status.isGameOver) {
      await _handleGameOver(board: updatedBoard, result: result);
      return;
    }

    final nextPlayer = state.currentPlayer.opposite;

    if (state.gameMode == GameMode.vsAi && nextPlayer == PlayerSymbol.o) {
      // Transition to AI turn
      emit(
        state.copyWith(
          board: updatedBoard,
          currentPlayer: nextPlayer,
          isAiThinking: true,
        ),
      );

      await _executeAiMove(updatedBoard);
    } else {
      // 2 Players mode turn switch
      emit(state.copyWith(board: updatedBoard, currentPlayer: nextPlayer));
    }
  }

  Future<void> _executeAiMove(List<PlayerSymbol> currentBoard) async {
    if (_aiDelay > Duration.zero) {
      await Future<void>.delayed(_aiDelay);
    }

    if (isClosed) return;

    final aiMove = _engine.selectAiMove(
      board: currentBoard,
      aiSymbol: PlayerSymbol.o,
      difficulty: state.aiDifficulty,
    );

    if (aiMove == null) return;

    final boardAfterAi = _engine.applyMove(
      currentBoard,
      aiMove,
      PlayerSymbol.o,
    );
    final result = _engine.evaluateBoard(boardAfterAi);

    if (result.status.isGameOver) {
      await _handleGameOver(board: boardAfterAi, result: result);
    } else {
      emit(
        state.copyWith(
          board: boardAfterAi,
          currentPlayer: PlayerSymbol.x,
          isAiThinking: false,
        ),
      );
    }
  }

  Future<void> _handleGameOver({
    required List<PlayerSymbol> board,
    required TicTacToeResult result,
  }) async {
    final currentStats = state.stats;
    GameStats updatedStats;

    if (result.status == GameStatus.win) {
      if (result.winner == PlayerSymbol.x) {
        // Player X win
        updatedStats = currentStats.copyWith(wins: currentStats.wins + 1);
      } else {
        // Player O (or AI) win
        updatedStats = currentStats.copyWith(losses: currentStats.losses + 1);
      }
    } else {
      // Draw
      updatedStats = currentStats.copyWith(draws: currentStats.draws + 1);
    }

    emit(
      state.copyWith(
        board: board,
        status: result.status,
        winner: () => result.winner,
        winningIndices: () => result.winningIndices,
        isAiThinking: false,
        stats: updatedStats,
      ),
    );

    await _statsStorage.saveStats(
      gameId: StorageKeys.gameTicTacToe,
      subKey: _statsSubKey,
      stats: updatedStats,
    );
  }

  /// Restarts the board with a fresh game while preserving scores and settings.
  void restartGame() {
    emit(
      state.copyWith(
        board: _engine.createEmptyBoard(),
        currentPlayer: PlayerSymbol.x,
        status: GameStatus.inProgress,
        winner: () => null,
        winningIndices: () => null,
        isAiThinking: false,
      ),
    );
  }

  /// Changes game mode (vs AI or 2-Player Pass & Play).
  Future<void> setGameMode(GameMode mode) async {
    if (state.gameMode == mode) return;

    emit(
      state.copyWith(
        gameMode: mode,
        board: _engine.createEmptyBoard(),
        currentPlayer: PlayerSymbol.x,
        status: GameStatus.inProgress,
        winner: () => null,
        winningIndices: () => null,
        isAiThinking: false,
      ),
    );

    await loadStats();
  }

  /// Sets AI difficulty and updates statistics.
  Future<void> setAiDifficulty(AiDifficulty difficulty) async {
    if (state.aiDifficulty == difficulty) return;

    emit(
      state.copyWith(
        aiDifficulty: difficulty,
        board: _engine.createEmptyBoard(),
        currentPlayer: PlayerSymbol.x,
        status: GameStatus.inProgress,
        winner: () => null,
        winningIndices: () => null,
        isAiThinking: false,
      ),
    );

    await loadStats();
  }

  /// Resets scores for the currently active game mode and difficulty.
  Future<void> resetScores() async {
    await _statsStorage.resetStats(
      gameId: StorageKeys.gameTicTacToe,
      subKey: _statsSubKey,
    );
    emit(state.copyWith(stats: GameStats.empty));
  }
}
