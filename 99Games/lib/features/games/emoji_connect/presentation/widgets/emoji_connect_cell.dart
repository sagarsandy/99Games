import 'package:flutter/material.dart';
import '../../domain/emoji_connect_models.dart';

/// Renders an individual grid cell in Emoji Connect.
///
/// If the cell contains an endpoint, it renders a vibrant colored circular badge
/// with the emoji centered. Empty cells render a subtle grid anchor dot.
class EmojiConnectCell extends StatelessWidget {
  final GridPosition position;
  final EmojiPair? endpointPair;
  final bool isCompleted;
  final bool isDraggingThisPair;
  final double cellSize;

  const EmojiConnectCell({
    super.key,
    required this.position,
    this.endpointPair,
    this.isCompleted = false,
    this.isDraggingThisPair = false,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (endpointPair != null) {
      final pair = endpointPair!;
      final color = pair.color;
      final badgeSize = cellSize * 0.78;
      final fontSize = cellSize * 0.44;

      return Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isCompleted ? 0.95 : 0.85),
            border: Border.all(
              color: Colors.white,
              width: isDraggingThisPair ? 3.0 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isCompleted ? 0.45 : 0.25),
                blurRadius: isDraggingThisPair ? 10 : 6,
                spreadRadius: isDraggingThisPair ? 2 : 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              pair.emoji,
              style: TextStyle(fontSize: fontSize, height: 1.0),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Empty cell: render subtle center anchor dot
    return Center(
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.10),
        ),
      ),
    );
  }
}
