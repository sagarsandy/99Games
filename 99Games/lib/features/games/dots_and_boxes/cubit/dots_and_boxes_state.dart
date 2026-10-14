import 'package:equatable/equatable.dart';
import '../../../../core/storage/game_stats_storage.dart';
import '../domain/dots_and_boxes_models.dart';

/// Immutable state representing the entire state of a Dots and Boxes match.
class DotsAndBoxesState extends Equatable {
  final BoardSize boardSize;
  final List<List<DotsPlayer?>> horizontalEdges;
  final List<List<DotsPlayer?>> verticalEdges;
  final List<List<DotsPlayer?>> boxes;
  final DotsPlayer currentPlayer;
  final int player1Score;
  final int player2Score;
  final DotsGameMode gameMode;
  final DotsAiDifficulty aiDifficulty;
  final DotsGameStatus status;
  final DotsPlayer? winner;
  final bool isDraw;
  final bool isAiThinking;
  final EdgePosition? lastMove;
  final GameStats stats;

  const DotsAndBoxesState({
    required this.boardSize,
    required this.horizontalEdges,
    required this.verticalEdges,
    required this.boxes,
    required this.currentPlayer,
    required this.player1Score,
    required this.player2Score,
    required this.gameMode,
    required this.aiDifficulty,
    required this.status,
    this.winner,
    this.isDraw = false,
    this.isAiThinking = false,
    this.lastMove,
    this.stats = GameStats.empty,
  });

  /// Factory constructor for a fresh, clean board state.
  factory DotsAndBoxesState.initial({
    BoardSize boardSize = BoardSize.small,
    DotsGameMode gameMode = DotsGameMode.vsAi,
    DotsAiDifficulty aiDifficulty = DotsAiDifficulty.medium,
    GameStats stats = GameStats.empty,
  }) {
    return DotsAndBoxesState(
      boardSize: boardSize,
      horizontalEdges: List.generate(
        boardSize.rows + 1,
        (_) => List<DotsPlayer?>.filled(boardSize.cols, null),
      ),
      verticalEdges: List.generate(
        boardSize.rows,
        (_) => List<DotsPlayer?>.filled(boardSize.cols + 1, null),
      ),
      boxes: List.generate(
        boardSize.rows,
        (_) => List<DotsPlayer?>.filled(boardSize.cols, null),
      ),
      currentPlayer: DotsPlayer.player1,
      player1Score: 0,
      player2Score: 0,
      gameMode: gameMode,
      aiDifficulty: aiDifficulty,
      status: DotsGameStatus.inProgress,
      winner: null,
      isDraw: false,
      isAiThinking: false,
      lastMove: null,
      stats: stats,
    );
  }

  bool get isGameOver => status.isGameOver;

  int get totalBoxes => boardSize.totalBoxes;

  int get claimedBoxesCount => player1Score + player2Score;

  int get remainingBoxes => totalBoxes - claimedBoxesCount;

  bool get hasAnyMoveMade {
    for (final row in horizontalEdges) {
      for (final cell in row) {
        if (cell != null) return true;
      }
    }
    for (final row in verticalEdges) {
      for (final cell in row) {
        if (cell != null) return true;
      }
    }
    return false;
  }

  DotsAndBoxesState copyWith({
    BoardSize? boardSize,
    List<List<DotsPlayer?>>? horizontalEdges,
    List<List<DotsPlayer?>>? verticalEdges,
    List<List<DotsPlayer?>>? boxes,
    DotsPlayer? currentPlayer,
    int? player1Score,
    int? player2Score,
    DotsGameMode? gameMode,
    DotsAiDifficulty? aiDifficulty,
    DotsGameStatus? status,
    DotsPlayer? Function()? winner,
    bool? isDraw,
    bool? isAiThinking,
    EdgePosition? Function()? lastMove,
    GameStats? stats,
  }) {
    return DotsAndBoxesState(
      boardSize: boardSize ?? this.boardSize,
      horizontalEdges: horizontalEdges ?? this.horizontalEdges,
      verticalEdges: verticalEdges ?? this.verticalEdges,
      boxes: boxes ?? this.boxes,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      gameMode: gameMode ?? this.gameMode,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      status: status ?? this.status,
      winner: winner != null ? winner() : this.winner,
      isDraw: isDraw ?? this.isDraw,
      isAiThinking: isAiThinking ?? this.isAiThinking,
      lastMove: lastMove != null ? lastMove() : this.lastMove,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
    boardSize,
    horizontalEdges,
    verticalEdges,
    boxes,
    currentPlayer,
    player1Score,
    player2Score,
    gameMode,
    aiDifficulty,
    status,
    winner,
    isDraw,
    isAiThinking,
    lastMove,
    stats,
  ];
}
