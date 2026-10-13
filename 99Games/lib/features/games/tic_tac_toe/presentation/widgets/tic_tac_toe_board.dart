import 'package:flutter/material.dart';
import '../../domain/tic_tac_toe_models.dart';
import 'tic_tac_toe_cell.dart';

/// Renders the 3x3 Tic-Tac-Toe game board.
class TicTacToeBoard extends StatelessWidget {
  final List<PlayerSymbol> board;
  final List<int>? winningIndices;
  final bool isInteractive;
  final ValueChanged<int> onCellTapped;

  const TicTacToeBoard({
    super.key,
    required this.board,
    required this.winningIndices,
    required this.isInteractive,
    required this.onCellTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 380),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141E33) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final symbol = board[index];
                final isWinningCell = winningIndices?.contains(index) ?? false;

                return TicTacToeCell(
                  index: index,
                  symbol: symbol,
                  isWinningCell: isWinningCell,
                  isEnabled: isInteractive,
                  onTap: () => onCellTapped(index),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
