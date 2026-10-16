import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter rendering ambient aquatic background effects:
/// rising bubbles and soft shimmering caustic light rays.
///
/// 100% Canvas drawing with zero external assets.
class AquariumEffectsPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const AquariumEffectsPainter({required this.progress, this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Soft Caustic Light Rays from top water surface
    _drawCausticRays(canvas, size);

    // 2. Rising Translucent Bubbles
    _drawBubbles(canvas, size);
  }

  void _drawCausticRays(Canvas canvas, Size size) {
    final rayPaint = Paint()
      ..color = (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
          .withValues(alpha: isDark ? 0.05 : 0.04)
      ..style = PaintingStyle.fill;

    final rayCount = 5;
    for (int i = 0; i < rayCount; i++) {
      final t = (progress + (i / rayCount)) % 1.0;
      final sway = math.sin(t * 2 * math.pi) * 20;

      final startX = (size.width / (rayCount + 1)) * (i + 1) + sway;
      final topWidth = 24.0;
      final bottomWidth = 60.0;

      final path = Path()
        ..moveTo(startX - topWidth / 2, 0)
        ..lineTo(startX + topWidth / 2, 0)
        ..lineTo(startX + bottomWidth / 2 + sway * 1.5, size.height * 0.75)
        ..lineTo(startX - bottomWidth / 2 + sway * 1.5, size.height * 0.75)
        ..close();

      canvas.drawPath(path, rayPaint);
    }
  }

  void _drawBubbles(Canvas canvas, Size size) {
    // 8 deterministic ambient bubbles floating upward
    final bubbleData = [
      (0.12, 0.25, 4.0),
      (0.28, 0.65, 5.5),
      (0.45, 0.15, 3.5),
      (0.62, 0.85, 6.0),
      (0.78, 0.40, 4.5),
      (0.88, 0.75, 3.0),
      (0.35, 0.90, 5.0),
      (0.70, 0.10, 4.0),
    ];

    final bubbleStroke = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.25 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final bubbleFill = Paint()
      ..color = (isDark ? const Color(0xFF38BDF8) : const Color(0xFFBAE6FD))
          .withValues(alpha: isDark ? 0.08 : 0.12)
      ..style = PaintingStyle.fill;

    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.4 : 0.6)
      ..style = PaintingStyle.fill;

    for (final (xRel, yBase, radius) in bubbleData) {
      // Y position moves up with progress
      final yNorm = (yBase - progress) % 1.0;
      final y = yNorm * size.height;

      // Small horizontal wobble
      final wobble = math.sin((progress * 2 * math.pi) + (xRel * 10)) * 6.0;
      final x = (xRel * size.width) + wobble;

      final center = Offset(x, y);

      // Bubble circle
      canvas.drawCircle(center, radius, bubbleFill);
      canvas.drawCircle(center, radius, bubbleStroke);

      // Tiny white shine reflection glint inside bubble
      canvas.drawCircle(
        Offset(center.dx - radius * 0.35, center.dy - radius * 0.35),
        radius * 0.28,
        glintPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AquariumEffectsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
