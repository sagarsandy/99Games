import 'package:flutter/material.dart';

/// CustomPainter rendering a cheerful arcade orchard backdrop with clouds and hills.
///
/// 100% programmatically drawn with Canvas and Path (zero external assets).
class CatcherBackgroundPainter extends CustomPainter {
  final bool isDark;

  const CatcherBackgroundPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [
                Color(0xFF0F172A), // Midnight slate
                Color(0xFF1E293B),
                Color(0xFF0F766E), // Deep forest horizon
              ]
            : const [
                Color(0xFFBAE6FD), // Sky blue
                Color(0xFFE0F2FE), // Soft bright horizon
                Color(0xFFDCFCE7), // Pale pasture warmth
              ],
      ).createShader(skyRect);

    canvas.drawRect(skyRect, skyPaint);

    // 2. Distant Sun / Moon
    final sunCenter = Offset(w * 0.85, h * 0.12);
    final sunRadius = w * 0.12;

    final sunGlow = Paint()
      ..color = (isDark ? const Color(0xFF67E8F9) : const Color(0xFFFDE047))
          .withValues(alpha: isDark ? 0.20 : 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(sunCenter, sunRadius * 1.3, sunGlow);

    final sunPaint = Paint()
      ..color = (isDark ? const Color(0xFFE0F2FE) : const Color(0xFFFEF08A))
          .withValues(alpha: 0.85);
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    // 3. Gentle Cartoon Clouds
    _drawCloud(canvas, Offset(w * 0.18, h * 0.18), w * 0.16, isDark);
    _drawCloud(canvas, Offset(w * 0.65, h * 0.24), w * 0.14, isDark);
    _drawCloud(canvas, Offset(w * 0.92, h * 0.32), w * 0.12, isDark);

    // 4. Rolling Green Hills at Horizon
    final hillPaint1 = Paint()
      ..color = (isDark ? const Color(0xFF064E3B) : const Color(0xFF86EFAC))
          .withValues(alpha: isDark ? 0.40 : 0.50);

    final hill1 = Path();
    hill1.moveTo(0, h * 0.92);
    hill1.quadraticBezierTo(w * 0.35, h * 0.86, w * 0.70, h * 0.93);
    hill1.quadraticBezierTo(w * 0.88, h * 0.95, w, h * 0.91);
    hill1.lineTo(w, h);
    hill1.lineTo(0, h);
    hill1.close();
    canvas.drawPath(hill1, hillPaint1);

    final hillPaint2 = Paint()
      ..color = (isDark ? const Color(0xFF022C22) : const Color(0xFF4ADE80))
          .withValues(alpha: isDark ? 0.60 : 0.65);

    final hill2 = Path();
    hill2.moveTo(0, h * 0.96);
    hill2.quadraticBezierTo(w * 0.25, h * 0.92, w * 0.55, h * 0.97);
    hill2.quadraticBezierTo(w * 0.80, h * 1.01, w, h * 0.95);
    hill2.lineTo(w, h);
    hill2.lineTo(0, h);
    hill2.close();
    canvas.drawPath(hill2, hillPaint2);
  }

  void _drawCloud(Canvas canvas, Offset center, double size, bool dark) {
    final cloudPaint = Paint()
      ..color = (dark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.75));

    final r = size * 0.45;
    canvas.drawCircle(center, r, cloudPaint);
    canvas.drawCircle(
      center + Offset(-r * 0.75, r * 0.2),
      r * 0.70,
      cloudPaint,
    );
    canvas.drawCircle(center + Offset(r * 0.75, r * 0.2), r * 0.65, cloudPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, r * 0.4),
        width: size * 1.8,
        height: r * 0.9,
      ),
      cloudPaint,
    );
  }

  @override
  bool shouldRepaint(CatcherBackgroundPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
