import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter that renders the circular wheel backdrop and the glowing,
/// interactive path connecting selected letter tiles.
class WordCirclePathPainter extends CustomPainter {
  final List<Offset> letterPositions;
  final List<int> selectedIndices;
  final Offset? pointerPosition;
  final Color pathColor;
  final Color wheelBorderColor;
  final bool isDark;

  const WordCirclePathPainter({
    required this.letterPositions,
    required this.selectedIndices,
    this.pointerPosition,
    this.pathColor = const Color(0xFF06B6D4),
    this.wheelBorderColor = const Color(0xFF0EA5E9),
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // 1. Draw decorative wheel backdrop ring
    _drawWheelBackdrop(canvas, center, radius);

    // 2. Draw connecting lines between selected letters
    if (selectedIndices.isNotEmpty) {
      _drawConnectingPath(canvas);
    }
  }

  void _drawWheelBackdrop(Canvas canvas, Offset center, double radius) {
    final outerRingPaint = Paint()
      ..color = wheelBorderColor.withValues(alpha: isDark ? 0.20 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius - 4, outerRingPaint);

    final innerDiscPaint = Paint()
      ..color = isDark
          ? const Color(0xFF0F172A).withValues(alpha: 0.45)
          : Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - 6, innerDiscPaint);

    // Subtle center hub
    final hubPaint = Paint()
      ..color = wheelBorderColor.withValues(alpha: isDark ? 0.15 : 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.22, hubPaint);
  }

  void _drawConnectingPath(Canvas canvas) {
    final path = Path();
    final glowPaint = Paint()
      ..color = pathColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final firstIdx = selectedIndices.first;
    if (firstIdx >= letterPositions.length) return;

    final firstPos = letterPositions[firstIdx];
    path.moveTo(firstPos.dx, firstPos.dy);

    for (int i = 1; i < selectedIndices.length; i++) {
      final idx = selectedIndices[i];
      if (idx < letterPositions.length) {
        final pos = letterPositions[idx];
        path.lineTo(pos.dx, pos.dy);
      }
    }

    // Connect to active pointer position if dragging beyond the last letter
    if (pointerPosition != null) {
      path.lineTo(pointerPosition!.dx, pointerPosition!.dy);
    }

    // Draw outer glow and crisp core stroke
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // Draw center dots on selected letters
    for (final idx in selectedIndices) {
      if (idx < letterPositions.length) {
        final pos = letterPositions[idx];
        canvas.drawCircle(pos, 4.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WordCirclePathPainter oldDelegate) {
    return oldDelegate.selectedIndices != selectedIndices ||
        oldDelegate.pointerPosition != pointerPosition ||
        oldDelegate.letterPositions != letterPositions ||
        oldDelegate.pathColor != pathColor ||
        oldDelegate.isDark != isDark;
  }
}
