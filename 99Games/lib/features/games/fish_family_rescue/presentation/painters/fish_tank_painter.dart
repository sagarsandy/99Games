import 'package:flutter/material.dart';

/// CustomPainter that renders a transparent glass aquarium tank with
/// rounded base, glass gloss, water fill, capacity slot ticks, and selection aura.
///
/// 100% Canvas drawing with ZERO external assets.
class FishTankPainter extends CustomPainter {
  final int capacity;
  final int fishCount;
  final bool isSelected;
  final bool isCompleted;
  final bool isDark;
  final double waterAnimation;

  const FishTankPainter({
    required this.capacity,
    required this.fishCount,
    this.isSelected = false,
    this.isCompleted = false,
    this.isDark = true,
    this.waterAnimation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final padding = 4.0;
    final tankRect = Rect.fromLTWH(
      padding,
      padding + 8,
      size.width - padding * 2,
      size.height - padding * 2 - 8,
    );

    final cornerRadius = Radius.circular(
      (tankRect.width * 0.38).clamp(16.0, 26.0),
    );
    final tankRRect = RRect.fromRectAndCorners(
      tankRect,
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: cornerRadius,
      bottomRight: cornerRadius,
    );

    // 1. Draw Stand / Pedestal at bottom
    _drawBase(canvas, tankRect, cornerRadius);

    // 2. Draw Tank Interior Background (Subtle glass tint)
    final glassBgPaint = Paint()
      ..color = isDark
          ? const Color(0xFF0F172A).withValues(alpha: 0.5)
          : const Color(0xFFF1F5F9).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(tankRRect, glassBgPaint);

    // 3. Draw Water Fill
    _drawWaterFill(canvas, tankRect, cornerRadius);

    // 4. Draw Capacity Slot Tick Marks
    _drawSlotTicks(canvas, tankRect);

    // 5. Draw Glass Wall Reflections & Highlights
    _drawGlassReflections(canvas, tankRect, cornerRadius);

    // 6. Draw Tank Border & Selection Halo
    _drawTankBorder(canvas, tankRRect);

    // 7. Draw Glass Top Lip / Rim
    _drawTopLip(canvas, tankRect);
  }

  void _drawBase(Canvas canvas, Rect tankRect, Radius cornerRadius) {
    final baseRect = Rect.fromLTWH(
      tankRect.left - 3,
      tankRect.bottom - 4,
      tankRect.width + 6,
      10,
    );
    final basePaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;

    final baseRRect = RRect.fromRectAndRadius(
      baseRect,
      const Radius.circular(4),
    );
    canvas.drawRRect(baseRRect, basePaint);

    // Drop shadow under base
    canvas.drawShadow(
      Path()..addRRect(baseRRect),
      Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
      2.0,
      false,
    );
  }

  void _drawWaterFill(Canvas canvas, Rect tankRect, Radius cornerRadius) {
    if (fishCount == 0 && !isSelected) {
      // Empty tank has very soft ambient water tint
      final emptyWaterPaint = Paint()
        ..color = const Color(
          0xFF06B6D4,
        ).withValues(alpha: isDark ? 0.04 : 0.03)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          tankRect,
          bottomLeft: cornerRadius,
          bottomRight: cornerRadius,
        ),
        emptyWaterPaint,
      );
      return;
    }

    final waterHeightRatio = (fishCount / capacity).clamp(0.25, 1.0);
    final waterTop = tankRect.bottom - (tankRect.height * waterHeightRatio);

    final waterRect = Rect.fromLTWH(
      tankRect.left + 1.5,
      waterTop,
      tankRect.width - 3,
      tankRect.bottom - waterTop,
    );

    final waterGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        (isCompleted ? const Color(0xFF10B981) : const Color(0xFF06B6D4))
            .withValues(alpha: isDark ? 0.22 : 0.16),
        (isCompleted ? const Color(0xFF047857) : const Color(0xFF0284C7))
            .withValues(alpha: isDark ? 0.38 : 0.28),
      ],
    );

    final waterPaint = Paint()
      ..shader = waterGradient.createShader(waterRect)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndCorners(
        tankRect,
        bottomLeft: cornerRadius,
        bottomRight: cornerRadius,
      ),
    );

    // Draw water body with subtle animated surface curve
    final waterPath = Path()
      ..moveTo(waterRect.left, waterRect.top + 2)
      ..quadraticBezierTo(
        waterRect.center.dx,
        waterRect.top - 2,
        waterRect.right,
        waterRect.top + 2,
      )
      ..lineTo(waterRect.right, waterRect.bottom)
      ..lineTo(waterRect.left, waterRect.bottom)
      ..close();

    canvas.drawPath(waterPath, waterPaint);

    // Surface Meniscus Line
    final meniscusPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.45 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawLine(
      Offset(waterRect.left + 2, waterRect.top),
      Offset(waterRect.right - 2, waterRect.top),
      meniscusPaint,
    );

    canvas.restore();
  }

  void _drawSlotTicks(Canvas canvas, Rect tankRect) {
    final tickPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final slotHeight = tankRect.height / capacity;
    for (int i = 1; i < capacity; i++) {
      final y = tankRect.bottom - (slotHeight * i);
      // Small left tick
      canvas.drawLine(
        Offset(tankRect.left + 2, y),
        Offset(tankRect.left + 7, y),
        tickPaint,
      );
      // Small right tick
      canvas.drawLine(
        Offset(tankRect.right - 7, y),
        Offset(tankRect.right - 2, y),
        tickPaint,
      );
    }
  }

  void _drawGlassReflections(
    Canvas canvas,
    Rect tankRect,
    Radius cornerRadius,
  ) {
    // Sleek white vertical glass highlight streak down the left side
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.22 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(tankRect.left + 5, tankRect.top + 8),
      Offset(tankRect.left + 5, tankRect.bottom - 18),
      highlightPaint,
    );

    // Small highlight curve near bottom right
    final bottomGlint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.15 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(tankRect.right - 14, tankRect.bottom - 14),
        radius: 8,
      ),
      0,
      1.2,
      false,
      bottomGlint,
    );
  }

  void _drawTankBorder(Canvas canvas, RRect tankRRect) {
    if (isSelected) {
      // Glowing Selection Aura
      final auraPaint = Paint()
        ..color = const Color(0xFF06B6D4).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5.0);
      canvas.drawRRect(tankRRect, auraPaint);
    }

    final borderPaint = Paint()
      ..color = isSelected
          ? const Color(0xFF06B6D4)
          : (isCompleted
                ? const Color(0xFF10B981)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.18)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;

    canvas.drawRRect(tankRRect, borderPaint);
  }

  void _drawTopLip(Canvas canvas, Rect tankRect) {
    final lipRect = Rect.fromLTWH(
      tankRect.left - 2,
      tankRect.top - 2,
      tankRect.width + 4,
      5,
    );
    final lipPaint = Paint()
      ..color = isSelected
          ? const Color(0xFF06B6D4)
          : (isDark
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.25))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(lipRect, const Radius.circular(3)),
      lipPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FishTankPainter oldDelegate) {
    return oldDelegate.capacity != capacity ||
        oldDelegate.fishCount != fishCount ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isDark != isDark ||
        oldDelegate.waterAnimation != waterAnimation;
  }
}
