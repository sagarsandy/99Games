import 'package:flutter/material.dart';
import '../../domain/block_puzzle_engine.dart';
import '../../domain/block_puzzle_models.dart';

/// Renders the 10x10 Block Puzzle grid with DragTarget and tap-to-place support.
class BlockPuzzleBoard extends StatelessWidget {
  final List<int> board;
  final BlockPiece? selectedPiece;
  final BlockCoordinate? hoverAnchor;
  final BlockPuzzleEngine engine;
  final void Function(int row, int col) onCellTapped;
  final void Function(int row, int col, BlockPiece piece) onPieceDropped;
  final void Function(int row, int col) onCellHovered;
  final VoidCallback onHoverLeave;

  const BlockPuzzleBoard({
    super.key,
    required this.board,
    required this.selectedPiece,
    required this.hoverAnchor,
    required this.engine,
    required this.onCellTapped,
    required this.onPieceDropped,
    required this.onCellHovered,
    required this.onHoverLeave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Precalculate preview cells
    final previewIndices = <int>{};
    bool isPreviewValid = false;

    if (selectedPiece != null && hoverAnchor != null) {
      isPreviewValid = engine.canPlacePiece(
        board,
        selectedPiece!.shape,
        hoverAnchor!.row,
        hoverAnchor!.col,
      );

      for (final cell in selectedPiece!.shape.cells) {
        final r = hoverAnchor!.row + cell.row;
        final c = hoverAnchor!.col + cell.col;
        if (r >= 0 && r < 10 && c >= 0 && c < 10) {
          previewIndices.add(r * 10 + c);
        }
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 380),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141E33) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: 100,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final row = index ~/ 10;
                final col = index % 10;
                final colorValue = board[index];
                final isOccupied = colorValue != 0;

                final isPreview = previewIndices.contains(index);

                return DragTarget<BlockPiece>(
                  onWillAcceptWithDetails: (details) {
                    onCellHovered(row, col);
                    return true;
                  },
                  onLeave: (_) => onHoverLeave(),
                  onAcceptWithDetails: (details) {
                    onPieceDropped(row, col, details.data);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => onCellTapped(row, col),
                      onHover: (hovering) {
                        if (hovering) {
                          onCellHovered(row, col);
                        } else {
                          onHoverLeave();
                        }
                      },
                      child: _buildCell(
                        context: context,
                        isOccupied: isOccupied,
                        colorValue: colorValue,
                        isPreview: isPreview,
                        isPreviewValid: isPreviewValid,
                        previewColor: selectedPiece?.shape.color,
                        isDark: isDark,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell({
    required BuildContext context,
    required bool isOccupied,
    required int colorValue,
    required bool isPreview,
    required bool isPreviewValid,
    required Color? previewColor,
    required bool isDark,
  }) {
    if (isOccupied) {
      final cellColor = Color(colorValue);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: cellColor.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
    }

    if (isPreview) {
      final color = isPreviewValid
          ? (previewColor ?? const Color(0xFF10B981))
          : Colors.redAccent;

      return Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: isPreviewValid ? 0.65 : 0.45),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 1.5),
        ),
      );
    }

    // Default empty cell
    final emptyColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFCBD5E1);

    return Container(
      decoration: BoxDecoration(
        color: emptyColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
