import 'package:equatable/equatable.dart';

/// Represents cell marks or active players in Tic-Tac-Toe.
enum PlayerSymbol {
  none,
  x,
  o;

  bool get isNone => this == PlayerSymbol.none;
  bool get isOccupied => this != PlayerSymbol.none;

  PlayerSymbol get opposite => switch (this) {
    PlayerSymbol.x => PlayerSymbol.o,
    PlayerSymbol.o => PlayerSymbol.x,
    PlayerSymbol.none => PlayerSymbol.none,
  };

  String get displayName => switch (this) {
    PlayerSymbol.x => 'X',
    PlayerSymbol.o => 'O',
    PlayerSymbol.none => '',
  };
}

/// Available game modes for Tic-Tac-Toe.
enum GameMode {
  vsAi,
  passAndPlay;

  String get label => switch (this) {
    GameMode.vsAi => 'vs AI',
    GameMode.passAndPlay => '2 Players',
  };
}

/// AI difficulty settings.
enum AiDifficulty {
  easy,
  medium,
  hard;

  String get label => switch (this) {
    AiDifficulty.easy => 'Easy',
    AiDifficulty.medium => 'Medium',
    AiDifficulty.hard => 'Hard',
  };
}

/// Status of the game board.
enum GameStatus {
  inProgress,
  win,
  draw;

  bool get isGameOver => this != GameStatus.inProgress;
}

/// The outcome and winning sequence of a Tic-Tac-Toe board check.
class TicTacToeResult extends Equatable {
  final GameStatus status;
  final PlayerSymbol? winner;
  final List<int>? winningIndices;

  const TicTacToeResult({
    required this.status,
    this.winner,
    this.winningIndices,
  });

  static const inProgress = TicTacToeResult(status: GameStatus.inProgress);
  static const draw = TicTacToeResult(status: GameStatus.draw);

  factory TicTacToeResult.win(PlayerSymbol winner, List<int> indices) {
    return TicTacToeResult(
      status: GameStatus.win,
      winner: winner,
      winningIndices: List.unmodifiable(indices),
    );
  }

  @override
  List<Object?> get props => [status, winner, winningIndices];
}
