import 'package:flutter/material.dart';

/// CustomPainter rendering a woven wicker basket with depth, rim, and texture.
///
/// 100% programmatically drawn with Canvas and Path (zero external assets).
class BasketPainter extends CustomPainter {
  final bool isDark;

  const BasketPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final rimH = h * 0.25;
    final bodyH = h - rimH;

    // 1. Soft Drop Shadow below basket
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.45 : 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h + 2),
        width: w * 0.85,
        height: 12,
      ),
      shadowPaint,
    );

    // 2. Basket Body Path (tapered trapezoid with curved bottom)
    final bodyPath = Path();
    const marginX = 8.0;
    bodyPath.moveTo(marginX, rimH);
    bodyPath.lineTo(w - marginX, rimH);
    // Right curved side
    bodyPath.quadraticBezierTo(w * 0.95, h * 0.65, w * 0.82, h);
    // Curved bottom
    bodyPath.quadraticBezierTo(w * 0.5, h + 3, w * 0.18, h);
    // Left curved side
    bodyPath.quadraticBezierTo(w * 0.05, h * 0.65, marginX, rimH);
    bodyPath.close();

    // Body Gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFD97706), // Warm amber wicker
          Color(0xFFB45309), // Golden brown
          Color(0xFF78350F), // Deep rich shadow
        ],
      ).createShader(Rect.fromLTWH(0, rimH, w, bodyH));

    canvas.drawPath(bodyPath, bodyPaint);

    // 3. Woven Wicker Cross-Hatch Lattice Pattern
    canvas.save();
    canvas.clipPath(bodyPath);

    final latticePaint = Paint()
      ..color = const Color(0xFF451A03).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final step = w * 0.12;
    for (double x = -w; x < w * 2; x += step) {
      canvas.drawLine(Offset(x, rimH), Offset(x + h, h), latticePaint);
      canvas.drawLine(Offset(x, h), Offset(x + h, rimH), latticePaint);
    }

    // Horizontal weave bands
    final bandPaint = Paint()
      ..color = const Color(0xFFFEF3C7).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(0, rimH + bodyH * 0.35),
      Offset(w, rimH + bodyH * 0.35),
      bandPaint,
    );
    canvas.drawLine(
      Offset(0, rimH + bodyH * 0.70),
      Offset(w, rimH + bodyH * 0.70),
      bandPaint,
    );

    canvas.restore();

    // 4. Inner Dark Depth Shadow at the Top Rim Opening
    final innerOpeningPath = Path();
    innerOpeningPath.addOval(
      Rect.fromCenter(
        center: Offset(w / 2, rimH * 0.75),
        width: w * 0.90,
        height: rimH * 0.85,
      ),
    );

    final innerShadowPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF291505), Color(0xFF78350F)],
      ).createShader(Rect.fromLTWH(0, 0, w, rimH * 1.5));

    canvas.drawPath(innerOpeningPath, innerShadowPaint);

    // 5. Braided Wicker Rim
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, rimH * 0.65),
        width: w,
        height: rimH,
      ),
      Radius.circular(rimH * 0.45),
    );

    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFFDE68A), // Light bamboo/wicker highlight
          Color(0xFFD97706), // Rich amber
          Color(0xFF92400E), // Rim underside shadow
        ],
      ).createShader(rimRect.outerRect);

    canvas.drawRRect(rimRect, rimPaint);

    // Rim braid segment marks
    final braidPaint = Paint()
      ..color = const Color(0xFF78350F).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final braidStep = w * 0.08;
    for (double x = marginX + 6; x < w - marginX - 6; x += braidStep) {
      canvas.drawLine(
        Offset(x, rimH * 0.2),
        Offset(x + (braidStep * 0.4), rimH * 1.1),
        braidPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BasketPainter oldDelegate) => oldDelegate.isDark != isDark;
}
