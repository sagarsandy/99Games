import 'package:equatable/equatable.dart';
import '../domain/block_puzzle_models.dart';

/// Immutable state for Block Puzzle.
class BlockPuzzleState extends Equatable {
  final List<int> board;
  final List<BlockPiece> availablePieces;
  final int? selectedPieceIndex;
  final BlockCoordinate? hoverAnchor;
  final int score;
  final int bestScore;
  final bool isGameOver;
  final List<int> lastClearedIndices;

  const BlockPuzzleState({
    required this.board,
    required this.availablePieces,
    this.selectedPieceIndex,
    this.hoverAnchor,
    this.score = 0,
    this.bestScore = 0,
    this.isGameOver = false,
    this.lastClearedIndices = const [],
  });

  /// Factory for initial game session.
  factory BlockPuzzleState.initial({
    required List<int> board,
    required List<BlockPiece> pieces,
    int bestScore = 0,
  }) {
    return BlockPuzzleState(
      board: List.unmodifiable(board),
      availablePieces: List.unmodifiable(pieces),
      selectedPieceIndex: null,
      hoverAnchor: null,
      score: 0,
      bestScore: bestScore,
      isGameOver: false,
      lastClearedIndices: const [],
    );
  }

  BlockPiece? get selectedPiece {
    if (selectedPieceIndex == null) return null;
    if (selectedPieceIndex! < 0 ||
        selectedPieceIndex! >= availablePieces.length) {
      return null;
    }
    final piece = availablePieces[selectedPieceIndex!];
    return piece.isUsed ? null : piece;
  }

  BlockPuzzleState copyWith({
    List<int>? board,
    List<BlockPiece>? availablePieces,
    int? Function()? selectedPieceIndex,
    BlockCoordinate? Function()? hoverAnchor,
    int? score,
    int? bestScore,
    bool? isGameOver,
    List<int>? lastClearedIndices,
  }) {
    return BlockPuzzleState(
      board: board ?? this.board,
      availablePieces: availablePieces ?? this.availablePieces,
      selectedPieceIndex: selectedPieceIndex != null
          ? selectedPieceIndex()
          : this.selectedPieceIndex,
      hoverAnchor: hoverAnchor != null ? hoverAnchor() : this.hoverAnchor,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      isGameOver: isGameOver ?? this.isGameOver,
      lastClearedIndices: lastClearedIndices ?? this.lastClearedIndices,
    );
  }

  @override
  List<Object?> get props => [
    board,
    availablePieces,
    selectedPieceIndex,
    hoverAnchor,
    score,
    bestScore,
    isGameOver,
    lastClearedIndices,
  ];
}
