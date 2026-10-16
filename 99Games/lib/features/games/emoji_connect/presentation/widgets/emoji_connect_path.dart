import 'package:flutter/material.dart';
import '../../domain/emoji_connect_models.dart';

/// CustomPainter rendering grid lines, cell backgrounds, and flowing connection paths.
class EmojiConnectPathPainter extends CustomPainter {
  final EmojiConnectLevel level;
  final Map<String, EmojiPath> paths;
  final String? activeDragPairId;
  final bool isDark;

  const EmojiConnectPathPainter({
    required this.level,
    required this.paths,
    this.activeDragPairId,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = level.boardSize;
    final cellSize = size.width / boardSize;

    // 1. Draw subtle grid cell background squares with rounded corners
    final cellBgPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.5)
          : const Color(0xFFF1F5F9).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final cellBorderPaint = Paint()
      ..color = isDark
          ? const Color(0xFF334155).withValues(alpha: 0.4)
          : const Color(0xFFCBD5E1).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            c * cellSize + 2,
            r * cellSize + 2,
            cellSize - 4,
            cellSize - 4,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, cellBgPaint);
        canvas.drawRRect(rect, cellBorderPaint);
      }
    }

    // 2. Draw paths
    final strokeWidth = cellSize * 0.36;

    for (final pair in level.pairs) {
      final path = paths[pair.id];
      if (path == null || path.points.isEmpty) continue;

      final pts = path.points;
      final isComplete = path.isComplete(pair);
      final isActive = pair.id == activeDragPairId;

      final pathPaint = Paint()
        ..color = pair.color.withValues(
          alpha: isComplete ? 0.92 : (isActive ? 0.85 : 0.70),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (isActive) {
        // Subtle outer glow for active path
        final glowPaint = Paint()
          ..color = pair.color.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        final glowPath = Path();
        final startOffset = Offset(
          (pts[0].col + 0.5) * cellSize,
          (pts[0].row + 0.5) * cellSize,
        );
        glowPath.moveTo(startOffset.dx, startOffset.dy);
        for (int i = 1; i < pts.length; i++) {
          glowPath.lineTo(
            (pts[i].col + 0.5) * cellSize,
            (pts[i].row + 0.5) * cellSize,
          );
        }
        canvas.drawPath(glowPath, glowPaint);
      }

      if (pts.length >= 2) {
        final linePath = Path();
        final startOffset = Offset(
          (pts[0].col + 0.5) * cellSize,
          (pts[0].row + 0.5) * cellSize,
        );
        linePath.moveTo(startOffset.dx, startOffset.dy);

        for (int i = 1; i < pts.length; i++) {
          linePath.lineTo(
            (pts[i].col + 0.5) * cellSize,
            (pts[i].row + 0.5) * cellSize,
          );
        }
        canvas.drawPath(linePath, pathPaint);
      } else {
        // Single point path: draw a dot
        final center = Offset(
          (pts[0].col + 0.5) * cellSize,
          (pts[0].row + 0.5) * cellSize,
        );
        canvas.drawCircle(
          center,
          strokeWidth / 2,
          Paint()..color = pair.color.withValues(alpha: 0.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant EmojiConnectPathPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.paths != paths ||
        oldDelegate.activeDragPairId != activeDragPairId ||
        oldDelegate.isDark != isDark;
  }
}
