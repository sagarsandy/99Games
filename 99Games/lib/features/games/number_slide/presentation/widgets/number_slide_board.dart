import 'package:flutter/material.dart';
import '../../domain/number_slide_engine.dart';
import 'number_slide_tile.dart';

/// Renders the 4x4 Number Slide board container.
class NumberSlideBoard extends StatelessWidget {
  final List<int> board;
  final NumberSlideEngine engine;
  final bool isInteractive;
  final ValueChanged<int> onTileTapped;

  const NumberSlideBoard({
    super.key,
    required this.board,
    required this.engine,
    required this.isInteractive,
    required this.onTileTapped,
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
              itemCount: 16,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final value = board[index];
                final isMovable =
                    isInteractive && value != 0 && engine.canMove(board, index);

                return NumberSlideTile(
                  key: ValueKey('tile_$value'),
                  value: value,
                  isMovable: isMovable,
                  onTap: () => onTileTapped(index),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
