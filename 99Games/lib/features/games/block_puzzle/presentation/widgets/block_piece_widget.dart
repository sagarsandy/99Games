import 'package:flutter/material.dart';
import '../../domain/block_puzzle_models.dart';

/// Renders a preview representation of a block puzzle shape.
class BlockPieceWidget extends StatelessWidget {
  final BlockShape shape;
  final double cellSize;
  final bool isSelected;

  const BlockPieceWidget({
    super.key,
    required this.shape,
    this.cellSize = 20.0,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = shape.width * cellSize;
    final height = shape.height * cellSize;

    return AnimatedScale(
      scale: isSelected ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: shape.cells.map((cell) {
            return Positioned(
              left: cell.col * cellSize,
              top: cell.row * cellSize,
              width: cellSize - 2,
              height: cellSize - 2,
              child: Container(
                decoration: BoxDecoration(
                  color: shape.color,
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 1.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: shape.color.withValues(
                        alpha: isSelected ? 0.6 : 0.3,
                      ),
                      blurRadius: isSelected ? 6 : 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
