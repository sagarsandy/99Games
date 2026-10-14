import 'package:equatable/equatable.dart';

/// Represents players in Dots and Boxes.
enum DotsPlayer {
  player1,
  player2;

  DotsPlayer get opposite => switch (this) {
    DotsPlayer.player1 => DotsPlayer.player2,
    DotsPlayer.player2 => DotsPlayer.player1,
  };

  String displayName(DotsGameMode mode) => switch (mode) {
    DotsGameMode.vsAi => switch (this) {
      DotsPlayer.player1 => 'You',
      DotsPlayer.player2 => 'Computer',
    },
    DotsGameMode.passAndPlay => switch (this) {
      DotsPlayer.player1 => 'Player 1',
      DotsPlayer.player2 => 'Player 2',
    },
  };

  String shortBadge(DotsGameMode mode) => switch (mode) {
    DotsGameMode.vsAi => switch (this) {
      DotsPlayer.player1 => 'Y',
      DotsPlayer.player2 => 'C',
    },
    DotsGameMode.passAndPlay => switch (this) {
      DotsPlayer.player1 => '1',
      DotsPlayer.player2 => '2',
    },
  };
}

/// The three required board sizes based on boxes and dots dimensions.
enum BoardSize {
  small(rows: 6, cols: 6, label: 'Small (6×6)', dimensionsText: '6 × 6'),
  medium(rows: 9, cols: 9, label: 'Medium (9×9)', dimensionsText: '9 × 9'),
  large(rows: 15, cols: 15, label: 'Large (15×15)', dimensionsText: '15 × 15');

  final int rows;
  final int cols;
  final String label;
  final String dimensionsText;

  const BoardSize({
    required this.rows,
    required this.cols,
    required this.label,
    required this.dimensionsText,
  });

  /// Dots count in vertical direction.
  int get dotRows => rows + 1;

  /// Dots count in horizontal direction.
  int get dotCols => cols + 1;

  /// Total number of claimable boxes.
  int get totalBoxes => rows * cols;

  /// Total horizontal edges on the board: (rows + 1) * cols.
  int get totalHorizontalEdges => (rows + 1) * cols;

  /// Total vertical edges on the board: rows * (cols + 1).
  int get totalVerticalEdges => rows * (cols + 1);

  /// Total edges on the board: 2 * rows * cols + rows + cols.
  int get totalEdges => totalHorizontalEdges + totalVerticalEdges;

  /// Descriptive box count label (e.g. "36 boxes").
  String get boxCountText => '$totalBoxes boxes';

  /// Descriptive dot count label (e.g. "7 × 7 dots").
  String get dotCountText => '$dotRows × $dotCols dots';
}

/// Orientation of a line segment connecting two dots.
enum EdgeOrientation { horizontal, vertical }

/// Identifies an edge by its orientation and grid indices.
///
/// For horizontal edges:
/// - [row] ranges from 0 to [BoardSize.rows] (inclusive)
/// - [col] ranges from 0 to [BoardSize.cols] - 1 (inclusive)
///
/// For vertical edges:
/// - [row] ranges from 0 to [BoardSize.rows] - 1 (inclusive)
/// - [col] ranges from 0 to [BoardSize.cols] (inclusive)
class EdgePosition extends Equatable {
  final EdgeOrientation orientation;
  final int row;
  final int col;

  const EdgePosition({
    required this.orientation,
    required this.row,
    required this.col,
  });

  const EdgePosition.horizontal(this.row, this.col)
    : orientation = EdgeOrientation.horizontal;

  const EdgePosition.vertical(this.row, this.col)
    : orientation = EdgeOrientation.vertical;

  bool get isHorizontal => orientation == EdgeOrientation.horizontal;
  bool get isVertical => orientation == EdgeOrientation.vertical;

  @override
  List<Object?> get props => [orientation, row, col];

  @override
  String toString() =>
      '${orientation == EdgeOrientation.horizontal ? 'H' : 'V'}($row, $col)';
}

/// Identifies a box by its row and column (0 <= row < rows, 0 <= col < cols).
class BoxPosition extends Equatable {
  final int row;
  final int col;

  const BoxPosition(this.row, this.col);

  @override
  List<Object?> get props => [row, col];

  @override
  String toString() => 'Box($row, $col)';
}

/// Available play modes for Dots and Boxes.
enum DotsGameMode {
  vsAi,
  passAndPlay;

  String get label => switch (this) {
    DotsGameMode.vsAi => 'vs Computer',
    DotsGameMode.passAndPlay => '2 Players',
  };
}

/// AI difficulty options.
enum DotsAiDifficulty {
  easy,
  medium,
  hard;

  String get label => switch (this) {
    DotsAiDifficulty.easy => 'Easy',
    DotsAiDifficulty.medium => 'Medium',
    DotsAiDifficulty.hard => 'Hard',
  };
}

/// Status of the game board.
enum DotsGameStatus {
  inProgress,
  completed;

  bool get isGameOver => this == DotsGameStatus.completed;
}

/// Result produced after applying a legal move to the board.
class DotsMoveResult extends Equatable {
  final EdgePosition edge;
  final DotsPlayer player;
  final List<BoxPosition> completedBoxes;
  final bool getsExtraTurn;
  final DotsPlayer nextPlayer;
  final bool isGameOver;
  final DotsPlayer? winner;
  final bool isDraw;

  const DotsMoveResult({
    required this.edge,
    required this.player,
    required this.completedBoxes,
    required this.getsExtraTurn,
    required this.nextPlayer,
    required this.isGameOver,
    this.winner,
    this.isDraw = false,
  });

  @override
  List<Object?> get props => [
    edge,
    player,
    completedBoxes,
    getsExtraTurn,
    nextPlayer,
    isGameOver,
    winner,
    isDraw,
  ];
}
