import 'dart:math';
import 'tic_tac_toe_models.dart';

/// Pure Dart game engine for Tic-Tac-Toe.
///
/// Contains board logic, win/draw detection, move validation,
/// and AI decision algorithms (Random, Heuristic, and Minimax).
class TicTacToeEngine {
  final Random _random;

  TicTacToeEngine({Random? random}) : _random = random ?? Random();

  /// All 8 possible winning lines on a 3x3 board.
  static const List<List<int>> winningCombinations = [
    // Rows
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    // Columns
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    // Diagonals
    [0, 4, 8],
    [2, 4, 6],
  ];

  /// Creates a fresh 9-cell empty board.
  List<PlayerSymbol> createEmptyBoard() =>
      List.filled(9, PlayerSymbol.none, growable: false);

  /// Validates if a move at [index] is permissible on [board].
  bool isValidMove(List<PlayerSymbol> board, int index) {
    if (index < 0 || index >= board.length) return false;
    return board[index].isNone;
  }

  /// Returns a new board with [symbol] placed at [index].
  ///
  /// Throws [ArgumentError] if the move is invalid.
  List<PlayerSymbol> applyMove(
    List<PlayerSymbol> board,
    int index,
    PlayerSymbol symbol,
  ) {
    if (!isValidMove(board, index)) {
      throw ArgumentError('Invalid move at index $index');
    }
    final newBoard = List<PlayerSymbol>.from(board);
    newBoard[index] = symbol;
    return List.unmodifiable(newBoard);
  }

  /// Evaluates the board and returns a [TicTacToeResult].
  TicTacToeResult evaluateBoard(List<PlayerSymbol> board) {
    for (final combo in winningCombinations) {
      final a = board[combo[0]];
      final b = board[combo[1]];
      final c = board[combo[2]];

      if (a.isOccupied && a == b && b == c) {
        return TicTacToeResult.win(a, combo);
      }
    }

    final isFull = board.every((cell) => cell.isOccupied);
    if (isFull) {
      return TicTacToeResult.draw;
    }

    return TicTacToeResult.inProgress;
  }

  /// Returns list of available (empty) indices on [board].
  List<int> getAvailableMoves(List<PlayerSymbol> board) {
    final moves = <int>[];
    for (var i = 0; i < board.length; i++) {
      if (board[i].isNone) {
        moves.add(i);
      }
    }
    return moves;
  }

  /// Selects an AI move according to [difficulty].
  ///
  /// Returns `null` if no moves are available.
  int? selectAiMove({
    required List<PlayerSymbol> board,
    required PlayerSymbol aiSymbol,
    required AiDifficulty difficulty,
  }) {
    final availableMoves = getAvailableMoves(board);
    if (availableMoves.isEmpty) return null;

    return switch (difficulty) {
      AiDifficulty.easy => _selectEasyMove(availableMoves),
      AiDifficulty.medium => _selectMediumMove(board, aiSymbol, availableMoves),
      AiDifficulty.hard => _selectHardMove(board, aiSymbol),
    };
  }

  /// Easy AI: chooses randomly from available empty cells.
  int _selectEasyMove(List<int> availableMoves) {
    return availableMoves[_random.nextInt(availableMoves.length)];
  }

  /// Medium AI:
  /// 1. Takes immediate winning move if available.
  /// 2. Blocks opponent's winning move with high probability (75%),
  ///    occasionally making an imperfect choice.
  /// 3. Prefers center cell if open.
  /// 4. Otherwise chooses randomly.
  int _selectMediumMove(
    List<PlayerSymbol> board,
    PlayerSymbol aiSymbol,
    List<int> availableMoves,
  ) {
    final opponentSymbol = aiSymbol.opposite;

    // 1. Check if AI can win immediately
    for (final move in availableMoves) {
      final testBoard = applyMove(board, move, aiSymbol);
      final result = evaluateBoard(testBoard);
      if (result.status == GameStatus.win && result.winner == aiSymbol) {
        return move;
      }
    }

    // 2. Check if opponent is about to win
    for (final move in availableMoves) {
      final testBoard = applyMove(board, move, opponentSymbol);
      final result = evaluateBoard(testBoard);
      if (result.status == GameStatus.win && result.winner == opponentSymbol) {
        // 75% chance to block, 25% chance to miss and pick another move
        final willBlock = _random.nextDouble() < 0.75;
        if (willBlock) {
          return move;
        }
      }
    }

    // 3. Take center if open (index 4)
    if (availableMoves.contains(4)) {
      return 4;
    }

    // 4. Fallback to random move
    return _selectEasyMove(availableMoves);
  }

  /// Hard AI: plays optimally using the Minimax algorithm.
  /// Never loses against any player.
  int _selectHardMove(List<PlayerSymbol> board, PlayerSymbol aiSymbol) {
    int bestScore = -10000;
    int bestMove = -1;

    final opponent = aiSymbol.opposite;
    final availableMoves = getAvailableMoves(board);

    for (final move in availableMoves) {
      final newBoard = applyMove(board, move, aiSymbol);
      final score = _minimax(
        board: newBoard,
        depth: 0,
        isMaximizing: false,
        aiSymbol: aiSymbol,
        opponentSymbol: opponent,
      );

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove != -1 ? bestMove : availableMoves.first;
  }

  int _minimax({
    required List<PlayerSymbol> board,
    required int depth,
    required bool isMaximizing,
    required PlayerSymbol aiSymbol,
    required PlayerSymbol opponentSymbol,
  }) {
    final evaluation = evaluateBoard(board);

    if (evaluation.status == GameStatus.win) {
      if (evaluation.winner == aiSymbol) {
        return 10 - depth; // Faster wins score higher
      } else {
        return depth - 10; // Slower losses score higher (delay defeat)
      }
    }

    if (evaluation.status == GameStatus.draw) {
      return 0;
    }

    final availableMoves = getAvailableMoves(board);

    if (isMaximizing) {
      int maxEval = -10000;
      for (final move in availableMoves) {
        final newBoard = applyMove(board, move, aiSymbol);
        final score = _minimax(
          board: newBoard,
          depth: depth + 1,
          isMaximizing: false,
          aiSymbol: aiSymbol,
          opponentSymbol: opponentSymbol,
        );
        maxEval = max(maxEval, score);
      }
      return maxEval;
    } else {
      int minEval = 10000;
      for (final move in availableMoves) {
        final newBoard = applyMove(board, move, opponentSymbol);
        final score = _minimax(
          board: newBoard,
          depth: depth + 1,
          isMaximizing: true,
          aiSymbol: aiSymbol,
          opponentSymbol: opponentSymbol,
        );
        minEval = min(minEval, score);
      }
      return minEval;
    }
  }
}
