import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for the card back with a geometric diamond lattice pattern,
/// gradient background, inner border, and a central decorative star badge.
class MemoryMatchCardBackPainter extends CustomPainter {
  const MemoryMatchCardBackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Clip to rounded card shape
    canvas.save();
    canvas.clipRRect(rrect);

    // 1. Rich gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF1E1B4B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Decorative diamond lattice pattern
    final patternPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const step = 14.0;
    for (double d = -size.height; d < size.width + size.height; d += step) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        patternPaint,
      );
      canvas.drawLine(
        Offset(d, size.height),
        Offset(d + size.height, 0),
        patternPaint,
      );
    }

    // 3. Inner border inset
    final innerRect = rect.deflate(5.0);
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      const Radius.circular(8),
    );
    final innerBorderPaint = Paint()
      ..color = const Color(0xFF818CF8).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(innerRRect, innerBorderPaint);

    // 4. Center decorative motif: Celestial 8-point compass star with rings
    final center = Offset(size.width / 2, size.height / 2);
    final badgeRadius = math.min(size.width, size.height) * 0.22;

    // Glowing outer circle
    final glowPaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, badgeRadius * 1.25, glowPaint);

    // Center disc
    final discPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
      ).createShader(Rect.fromCircle(center: center, radius: badgeRadius));
    canvas.drawCircle(center, badgeRadius, discPaint);

    final discBorderPaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, badgeRadius, discBorderPaint);

    // 8-point gold star
    final starPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.fill;

    final starPath = Path();
    const points = 8;
    final rOuter = badgeRadius * 0.72;
    final rInner = badgeRadius * 0.32;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? rOuter : rInner;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);

    // Tiny center pearl
    final pearlPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(center, badgeRadius * 0.14, pearlPaint);

    canvas.restore();

    // Subtle card border
    final cardBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, cardBorderPaint);
  }

  @override
  bool shouldRepaint(covariant MemoryMatchCardBackPainter oldDelegate) => false;
}
