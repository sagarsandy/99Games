import 'package:flutter/material.dart';
import '../../domain/block_puzzle_models.dart';
import 'block_piece_widget.dart';

/// The piece tray widget displaying the 3 available block pieces.
class PieceTray extends StatelessWidget {
  final List<BlockPiece> pieces;
  final int? selectedPieceIndex;
  final ValueChanged<int> onSelectPiece;

  const PieceTray({
    super.key,
    required this.pieces,
    required this.selectedPieceIndex,
    required this.onSelectPiece,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(pieces.length, (index) {
          final piece = pieces[index];
          final isSelected = selectedPieceIndex == index;

          if (piece.isUsed) {
            // Empty placeholder for consumed piece
            return Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: Colors.white24,
                ),
              ),
            );
          }

          return Draggable<BlockPiece>(
            data: piece,
            feedback: Material(
              color: Colors.transparent,
              child: BlockPieceWidget(
                shape: piece.shape,
                cellSize: 28.0,
                isSelected: true,
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: _buildPieceCard(context, piece, isSelected: false),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelectPiece(index),
              child: _buildPieceCard(context, piece, isSelected: isSelected),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPieceCard(
    BuildContext context,
    BlockPiece piece, {
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isSelected
        ? theme.colorScheme.primary
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06));

    final bgColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1)
        : (isDark ? const Color(0xFF141E33) : const Color(0xFFF8FAFC));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: BlockPieceWidget(
          shape: piece.shape,
          cellSize: 16.0,
          isSelected: isSelected,
        ),
      ),
    );
  }
}
