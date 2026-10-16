import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/fruit_catcher_models.dart';

/// CustomPainter rendering catch particle bursts and floating score indicators (+10, +50, -1 Life).
class CatchEffectsPainter extends CustomPainter {
  final List<FruitCatchParticle> particles;
  final List<FloatingIndicator> indicators;
  final bool isDamaged;

  const CatchEffectsPainter({
    required this.particles,
    required this.indicators,
    this.isDamaged = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Red flash overlay if damaged by bomb
    if (isDamaged) {
      final flashPaint = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.28);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), flashPaint);
    }

    // 2. Render Particles
    for (final p in particles) {
      final px = p.x * w;
      final py = p.y * h;
      final opacity = p.opacity;
      if (opacity <= 0.0) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      if (p.isStar) {
        _drawStar(canvas, Offset(px, py), p.size, paint);
      } else {
        canvas.drawCircle(Offset(px, py), p.size, paint);
      }
    }

    // 3. Render Floating Indicators (+10, +50, -1 Life)
    for (final ind in indicators) {
      final ix = ind.x * w;
      final iy = (ind.y + ind.offsetY) * h;
      final opacity = ind.opacity;
      if (opacity <= 0.0) continue;

      final isBombDamage = ind.text.contains('Life');

      final textSpan = TextSpan(
        text: ind.text,
        style: TextStyle(
          color: ind.color.withValues(alpha: opacity),
          fontSize: isBombDamage ? 20 : 18,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.65 * opacity),
              blurRadius: 4,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(ix - (textPainter.width / 2), iy - (textPainter.height / 2)),
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final x1 = center.dx + math.cos(angle) * size;
      final y1 = center.dy + math.sin(angle) * size;
      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      final midAngle = angle + math.pi / 4;
      final x2 = center.dx + math.cos(midAngle) * (size * 0.35);
      final y2 = center.dy + math.sin(midAngle) * (size * 0.35);
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CatchEffectsPainter oldDelegate) => true;
}
