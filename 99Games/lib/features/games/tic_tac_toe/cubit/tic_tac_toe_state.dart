import 'package:equatable/equatable.dart';
import '../../../../core/storage/game_stats_storage.dart';
import '../domain/tic_tac_toe_models.dart';

/// Immutable state for the Tic-Tac-Toe game screen.
class TicTacToeState extends Equatable {
  final List<PlayerSymbol> board;
  final PlayerSymbol currentPlayer;
  final GameStatus status;
  final GameMode gameMode;
  final AiDifficulty aiDifficulty;
  final PlayerSymbol? winner;
  final List<int>? winningIndices;
  final bool isAiThinking;
  final GameStats stats;

  const TicTacToeState({
    required this.board,
    required this.currentPlayer,
    required this.status,
    required this.gameMode,
    required this.aiDifficulty,
    this.winner,
    this.winningIndices,
    this.isAiThinking = false,
    this.stats = GameStats.empty,
  });

  /// Factory for the initial state of a new session.
  factory TicTacToeState.initial({
    GameMode gameMode = GameMode.vsAi,
    AiDifficulty aiDifficulty = AiDifficulty.medium,
  }) {
    return TicTacToeState(
      board: List.filled(9, PlayerSymbol.none, growable: false),
      currentPlayer: PlayerSymbol.x,
      status: GameStatus.inProgress,
      gameMode: gameMode,
      aiDifficulty: aiDifficulty,
      winner: null,
      winningIndices: null,
      isAiThinking: false,
      stats: GameStats.empty,
    );
  }

  bool get isGameOver => status.isGameOver;

  TicTacToeState copyWith({
    List<PlayerSymbol>? board,
    PlayerSymbol? currentPlayer,
    GameStatus? status,
    GameMode? gameMode,
    AiDifficulty? aiDifficulty,
    PlayerSymbol? Function()? winner,
    List<int>? Function()? winningIndices,
    bool? isAiThinking,
    GameStats? stats,
  }) {
    return TicTacToeState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      status: status ?? this.status,
      gameMode: gameMode ?? this.gameMode,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      winner: winner != null ? winner() : this.winner,
      winningIndices: winningIndices != null
          ? winningIndices()
          : this.winningIndices,
      isAiThinking: isAiThinking ?? this.isAiThinking,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
    board,
    currentPlayer,
    status,
    gameMode,
    aiDifficulty,
    winner,
    winningIndices,
    isAiThinking,
    stats,
  ];
}
