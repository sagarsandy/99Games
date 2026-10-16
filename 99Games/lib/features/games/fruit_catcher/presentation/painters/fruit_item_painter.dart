import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/fruit_catcher_models.dart';

/// CustomPainter rendering recognizable cartoon fruits, golden fruit, and bombs.
///
/// 100% programmatically drawn with Canvas, Path, gradients, and shadows (zero assets).
class FruitItemPainter extends CustomPainter {
  final FruitType type;
  final double radius;
  final double rotation;

  const FruitItemPainter({
    required this.type,
    required this.radius,
    this.rotation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    if (rotation != 0.0) {
      canvas.rotate(rotation);
    }

    switch (type) {
      case FruitType.apple:
        _paintApple(canvas, radius);
        break;
      case FruitType.orange:
        _paintOrange(canvas, radius);
        break;
      case FruitType.banana:
        _paintBanana(canvas, radius);
        break;
      case FruitType.strawberry:
        _paintStrawberry(canvas, radius);
        break;
      case FruitType.grapes:
        _paintGrapes(canvas, radius);
        break;
      case FruitType.golden:
        _paintGoldenFruit(canvas, radius);
        break;
      case FruitType.bomb:
        _paintBomb(canvas, radius);
        break;
    }

    canvas.restore();
  }

  void _paintApple(Canvas canvas, double r) {
    // 1. Apple Body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: const [
          Color(0xFFF87171), // Bright red highlight
          Color(0xFFDC2626), // Classic apple red
          Color(0xFF991B1B), // Shadow crimson
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final path = Path();
    path.moveTo(0, -r * 0.7);
    // Left lobe
    path.cubicTo(-r * 0.9, -r * 1.05, -r * 1.15, r * 0.3, -r * 0.5, r * 0.95);
    // Bottom indentation
    path.cubicTo(-r * 0.2, r * 1.05, r * 0.2, r * 1.05, r * 0.5, r * 0.95);
    // Right lobe
    path.cubicTo(r * 1.15, r * 0.3, r * 0.9, -r * 1.05, 0, -r * 0.7);
    canvas.drawPath(path, bodyPaint);

    // 2. Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(0, -r * 0.65);
    stemPath.quadraticBezierTo(r * 0.15, -r * 1.05, r * 0.25, -r * 1.25);
    canvas.drawPath(stemPath, stemPaint);

    // 3. Leaf
    final leafPaint = Paint()..color = const Color(0xFF16A34A);
    final leafPath = Path();
    leafPath.moveTo(r * 0.1, -r * 0.85);
    leafPath.quadraticBezierTo(r * 0.55, -r * 1.2, r * 0.75, -r * 0.9);
    leafPath.quadraticBezierTo(r * 0.45, -r * 0.7, r * 0.1, -r * 0.85);
    canvas.drawPath(leafPath, leafPaint);

    // 4. Glossy Specular Arc
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(-r * 0.1, -r * 0.05), radius: r * 0.65),
      math.pi * 1.15,
      math.pi * 0.35,
      false,
      shinePaint,
    );
  }

  void _paintOrange(Canvas canvas, double r) {
    // 1. Orange Sphere
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 0.9,
        colors: const [
          Color(0xFFFDBA74), // Light citrus
          Color(0xFFEA580C), // Deep orange
          Color(0xFFC2410C), // Shadow
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    canvas.drawCircle(Offset.zero, r, bodyPaint);

    // 2. Subtle dimple texture
    final dimplePaint = Paint()
      ..color = const Color(0xFF9A3412).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    for (final off in [
      Offset(-r * 0.4, r * 0.2),
      Offset(-r * 0.2, r * 0.5),
      Offset(r * 0.3, r * 0.35),
      Offset(r * 0.45, -r * 0.1),
      Offset(r * 0.15, r * 0.6),
    ]) {
      canvas.drawCircle(off, r * 0.05, dimplePaint);
    }

    // 3. Top Calyx & Leaf
    final calyxPaint = Paint()..color = const Color(0xFF15803D);
    canvas.drawCircle(Offset(0, -r * 0.92), r * 0.12, calyxPaint);

    final leafPath = Path();
    leafPath.moveTo(0, -r * 0.92);
    leafPath.quadraticBezierTo(r * 0.4, -r * 1.25, r * 0.6, -r * 1.05);
    leafPath.quadraticBezierTo(r * 0.3, -r * 0.85, 0, -r * 0.92);
    canvas.drawPath(leafPath, calyxPaint);

    // 4. Glossy highlight
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.72),
      math.pi * 1.2,
      math.pi * 0.35,
      false,
      shinePaint,
    );
  }

  void _paintBanana(Canvas canvas, double r) {
    // 1. Crescent Banana Body
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFFFEF08A), // Light yellow
          Color(0xFFFACC15), // Golden banana yellow
          Color(0xFFEAB308), // Rich yellow
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final outlinePaint = Paint()
      ..color = const Color(0xFFCA8A04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(-r * 0.8, -r * 0.5);
    // Outer curve
    path.cubicTo(-r * 0.5, -r * 0.9, r * 0.5, -r * 0.8, r * 0.9, r * 0.5);
    // Bottom tip
    path.lineTo(r * 0.75, r * 0.65);
    // Inner curve
    path.cubicTo(r * 0.3, -r * 0.35, -r * 0.3, -r * 0.45, -r * 0.8, -r * 0.5);
    path.close();

    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, outlinePaint);

    // 2. Brown Stem & Bottom Tip
    final tipPaint = Paint()..color = const Color(0xFF713F12);
    canvas.drawCircle(Offset(-r * 0.8, -r * 0.5), r * 0.12, tipPaint);
    canvas.drawCircle(Offset(r * 0.85, r * 0.55), r * 0.10, tipPaint);

    // 3. Highlight stripe along curve
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.10
      ..strokeCap = StrokeCap.round;

    final shinePath = Path();
    shinePath.moveTo(-r * 0.45, -r * 0.65);
    shinePath.quadraticBezierTo(r * 0.15, -r * 0.65, r * 0.55, r * 0.1);
    canvas.drawPath(shinePath, shinePaint);
  }

  void _paintStrawberry(Canvas canvas, double r) {
    // 1. Tapered Heart Body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 0.85,
        colors: const [
          Color(0xFFFB7185), // Pinkish red highlight
          Color(0xFFE11D48), // Crimson strawberry
          Color(0xFF9F1239), // Dark ruby shadow
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final path = Path();
    path.moveTo(0, -r * 0.7);
    path.cubicTo(-r * 0.85, -r * 0.8, -r * 0.95, r * 0.1, 0, r * 1.05);
    path.cubicTo(r * 0.95, r * 0.1, r * 0.85, -r * 0.8, 0, -r * 0.7);
    canvas.drawPath(path, bodyPaint);

    // 2. Yellow Seed Specks
    final seedPaint = Paint()..color = const Color(0xFFFEF08A);
    for (final seed in [
      Offset(-r * 0.35, -r * 0.3),
      Offset(0, -r * 0.35),
      Offset(r * 0.35, -r * 0.3),
      Offset(-r * 0.45, 0.0),
      Offset(-r * 0.15, -0.05),
      Offset(r * 0.2, 0.0),
      Offset(r * 0.5, -0.02),
      Offset(-r * 0.25, r * 0.3),
      Offset(r * 0.08, r * 0.32),
      Offset(r * 0.35, r * 0.25),
      Offset(-r * 0.1, r * 0.6),
      Offset(r * 0.15, r * 0.58),
      Offset(0, r * 0.82),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: seed, width: r * 0.07, height: r * 0.12),
        seedPaint,
      );
    }

    // 3. Green Calyx Leaves at Top
    final calyxPaint = Paint()..color = const Color(0xFF16A34A);
    final crownPath = Path();
    crownPath.moveTo(0, -r * 0.65);
    crownPath.lineTo(-r * 0.4, -r * 0.5);
    crownPath.lineTo(-r * 0.7, -r * 0.85);
    crownPath.lineTo(-r * 0.25, -r * 0.75);
    crownPath.lineTo(0, -r * 1.05);
    crownPath.lineTo(r * 0.25, -r * 0.75);
    crownPath.lineTo(r * 0.7, -r * 0.85);
    crownPath.lineTo(r * 0.4, -r * 0.5);
    crownPath.close();
    canvas.drawPath(crownPath, calyxPaint);

    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF15803D)
      ..strokeWidth = r * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, -r * 0.8), Offset(0, -r * 1.15), stemPaint);
  }

  void _paintGrapes(Canvas canvas, double r) {
    final grapePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.8,
        colors: const [
          Color(0xFFC084FC), // Lavender glow
          Color(0xFF9333EA), // Royal purple
          Color(0xFF581C87), // Deep grape shadow
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final gr = r * 0.38; // Radius of each individual grape orb

    // Cluster positions (drawn back-to-front)
    final positions = [
      Offset(-r * 0.4, -r * 0.3),
      Offset(r * 0.4, -r * 0.3),
      Offset(0, -r * 0.35),
      Offset(-r * 0.45, r * 0.1),
      Offset(0, 0.0),
      Offset(r * 0.45, r * 0.1),
      Offset(-r * 0.22, r * 0.45),
      Offset(r * 0.22, r * 0.45),
      Offset(0, r * 0.75),
    ];

    for (final pos in positions) {
      canvas.drawCircle(pos, gr, grapePaint);
      // Small highlight on each grape
      final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.45);
      canvas.drawCircle(
        pos + Offset(-gr * 0.3, -gr * 0.3),
        gr * 0.22,
        shinePaint,
      );
    }

    // Stem & Leaf
    final stemPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = r * 0.14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, -r * 0.4), Offset(0, -r * 0.95), stemPaint);

    final leafPaint = Paint()..color = const Color(0xFF16A34A);
    final leaf = Path();
    leaf.moveTo(0, -r * 0.8);
    leaf.quadraticBezierTo(r * 0.4, -r * 1.15, r * 0.65, -r * 0.9);
    leaf.quadraticBezierTo(r * 0.3, -r * 0.7, 0, -r * 0.8);
    canvas.drawPath(leaf, leafPaint);
  }

  void _paintGoldenFruit(Canvas canvas, double r) {
    // 1. Radiant Outer Halo Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, r * 1.15, glowPaint);

    // 2. Shimmering Golden Body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.35),
        radius: 0.9,
        colors: const [
          Color(0xFFFEF9C3), // Sparkle ivory
          Color(0xFFFDE047), // Brilliant gold
          Color(0xFFF59E0B), // Warm amber
          Color(0xFFB45309), // Bronze depth
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    canvas.drawCircle(Offset.zero, r, bodyPaint);

    // 3. Golden Crown Leaf
    final leafPaint = Paint()..color = const Color(0xFFFACC15);
    final leaf = Path();
    leaf.moveTo(0, -r * 0.9);
    leaf.quadraticBezierTo(r * 0.4, -r * 1.25, r * 0.6, -r * 1.05);
    leaf.quadraticBezierTo(r * 0.3, -r * 0.8, 0, -r * 0.9);
    canvas.drawPath(leaf, leafPaint);

    // 4. Diamond Sparkle Stars painted around it
    _paintSparkleStar(canvas, Offset(r * 0.65, -r * 0.6), r * 0.28);
    _paintSparkleStar(canvas, Offset(-r * 0.7, r * 0.45), r * 0.22);
    _paintSparkleStar(canvas, Offset(r * 0.55, r * 0.65), r * 0.18);

    // 5. Bright Curving Specular
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.15
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.7),
      math.pi * 1.15,
      math.pi * 0.4,
      false,
      shinePaint,
    );
  }

  void _paintSparkleStar(Canvas canvas, Offset center, double size) {
    final p = Paint()..color = const Color(0xFFFEF08A);
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    canvas.drawPath(path, p);
  }

  void _paintBomb(Canvas canvas, double r) {
    // 1. Dark Metallic Bomb Sphere
    final bombPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: const [
          Color(0xFF475569), // Metallic sheen
          Color(0xFF1E293B), // Slate black
          Color(0xFF0F172A), // Deep obsidian
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    canvas.drawCircle(Offset.zero, r, bombPaint);

    // 2. Metallic Specular Arc
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.72),
      math.pi * 1.15,
      math.pi * 0.35,
      false,
      shinePaint,
    );

    // 3. Neck Collar
    final collarPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -r * 0.95),
          width: r * 0.5,
          height: r * 0.22,
        ),
        Radius.circular(r * 0.08),
      ),
      collarPaint,
    );

    // 4. Curved Rope Fuse
    final fusePaint = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;

    final fusePath = Path();
    fusePath.moveTo(0, -r * 1.05);
    fusePath.cubicTo(
      r * 0.2,
      -r * 1.25,
      r * 0.45,
      -r * 1.15,
      r * 0.35,
      -r * 1.45,
    );
    canvas.drawPath(fusePath, fusePaint);

    // 5. Burning Fuse Tip Spark / Flame
    final flameCenter = Offset(r * 0.35, -r * 1.45);

    // Outer glow
    final sparkGlow = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(flameCenter, r * 0.25, sparkGlow);

    // Fiery orange/yellow starburst
    _paintSparkleStar(canvas, flameCenter, r * 0.22);

    final corePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(flameCenter, r * 0.08, corePaint);
  }

  @override
  bool shouldRepaint(FruitItemPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.radius != radius ||
        oldDelegate.rotation != rotation;
  }
}
