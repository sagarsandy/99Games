import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents a 2D coordinate on the grid.
class BlockCoordinate extends Equatable {
  final int row;
  final int col;

  const BlockCoordinate(this.row, this.col);

  @override
  List<Object?> get props => [row, col];
}

/// Definition of a block puzzle shape.
class BlockShape extends Equatable {
  final String id;
  final String name;
  final List<BlockCoordinate> cells;
  final Color color;

  const BlockShape({
    required this.id,
    required this.name,
    required this.cells,
    required this.color,
  });

  int get cellCount => cells.length;

  int get width {
    if (cells.isEmpty) return 0;
    final maxCol = cells.map((c) => c.col).reduce((a, b) => a > b ? a : b);
    return maxCol + 1;
  }

  int get height {
    if (cells.isEmpty) return 0;
    final maxRow = cells.map((c) => c.row).reduce((a, b) => a > b ? a : b);
    return maxRow + 1;
  }

  @override
  List<Object?> get props => [id, name, cells, color];
}

/// An instance of a piece presented in the player's tray.
class BlockPiece extends Equatable {
  final String instanceId;
  final BlockShape shape;
  final bool isUsed;

  const BlockPiece({
    required this.instanceId,
    required this.shape,
    this.isUsed = false,
  });

  BlockPiece copyWith({bool? isUsed}) {
    return BlockPiece(
      instanceId: instanceId,
      shape: shape,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  @override
  List<Object?> get props => [instanceId, shape, isUsed];
}

/// Summary result of placing a piece on the board.
class PlacementResult extends Equatable {
  final List<int> newBoard;
  final int placedPoints;
  final int clearedPoints;
  final int bonusPoints;
  final int totalScoreEarned;
  final int clearedRowsCount;
  final int clearedColsCount;
  final List<int> clearedCellIndices;

  const PlacementResult({
    required this.newBoard,
    required this.placedPoints,
    required this.clearedPoints,
    required this.bonusPoints,
    required this.totalScoreEarned,
    required this.clearedRowsCount,
    required this.clearedColsCount,
    required this.clearedCellIndices,
  });

  int get totalLinesCleared => clearedRowsCount + clearedColsCount;

  @override
  List<Object?> get props => [
    newBoard,
    placedPoints,
    clearedPoints,
    bonusPoints,
    totalScoreEarned,
    clearedRowsCount,
    clearedColsCount,
    clearedCellIndices,
  ];
}
