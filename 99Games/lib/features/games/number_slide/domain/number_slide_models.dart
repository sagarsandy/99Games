import 'package:equatable/equatable.dart';

/// Represents a 2D coordinate on the 4x4 board.
class TileCoordinate extends Equatable {
  final int row;
  final int col;

  const TileCoordinate(this.row, this.col);

  int get index => row * 4 + col;

  factory TileCoordinate.fromIndex(int index) {
    return TileCoordinate(index ~/ 4, index % 4);
  }

  bool isAdjacentTo(TileCoordinate other) {
    final rowDiff = (row - other.row).abs();
    final colDiff = (col - other.col).abs();
    return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
  }

  @override
  List<Object?> get props => [row, col];
}
