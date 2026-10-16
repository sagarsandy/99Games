import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/memory_match_models.dart';

/// CustomPainter rendering 27 distinct cartoon illustrations programmatically.
///
/// 100% Canvas, Path, and gradient drawings without external assets.
class MemoryMatchArtworkPainter extends CustomPainter {
  final CardArtworkType artwork;

  const MemoryMatchArtworkPainter({required this.artwork});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Center coordinate space and scale to card dimensions
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) * 0.40;

    canvas.translate(cx, cy);

    switch (artwork) {
      // Fruits
      case CardArtworkType.apple:
        _drawApple(canvas, r);
        break;
      case CardArtworkType.orange:
        _drawOrange(canvas, r);
        break;
      case CardArtworkType.banana:
        _drawBanana(canvas, r);
        break;
      case CardArtworkType.strawberry:
        _drawStrawberry(canvas, r);
        break;
      case CardArtworkType.grapes:
        _drawGrapes(canvas, r);
        break;

      // Animals
      case CardArtworkType.cat:
        _drawCat(canvas, r);
        break;
      case CardArtworkType.dog:
        _drawDog(canvas, r);
        break;
      case CardArtworkType.rabbit:
        _drawRabbit(canvas, r);
        break;
      case CardArtworkType.owl:
        _drawOwl(canvas, r);
        break;
      case CardArtworkType.fish:
        _drawFish(canvas, r);
        break;

      // Vehicles
      case CardArtworkType.car:
        _drawCar(canvas, r);
        break;
      case CardArtworkType.bus:
        _drawBus(canvas, r);
        break;
      case CardArtworkType.bicycle:
        _drawBicycle(canvas, r);
        break;
      case CardArtworkType.airplane:
        _drawAirplane(canvas, r);
        break;

      // Nature
      case CardArtworkType.flower:
        _drawFlower(canvas, r);
        break;
      case CardArtworkType.tree:
        _drawTree(canvas, r);
        break;
      case CardArtworkType.mushroom:
        _drawMushroom(canvas, r);
        break;
      case CardArtworkType.sun:
        _drawSun(canvas, r);
        break;

      // Everyday objects
      case CardArtworkType.clock:
        _drawClock(canvas, r);
        break;
      case CardArtworkType.book:
        _drawBook(canvas, r);
        break;
      case CardArtworkType.umbrella:
        _drawUmbrella(canvas, r);
        break;
      case CardArtworkType.cup:
        _drawCup(canvas, r);
        break;
      case CardArtworkType.key:
        _drawKey(canvas, r);
        break;

      // Special
      case CardArtworkType.star:
        _drawStar(canvas, r);
        break;
      case CardArtworkType.balloon:
        _drawBalloon(canvas, r);
        break;
      case CardArtworkType.rocket:
        _drawRocket(canvas, r);
        break;
      case CardArtworkType.giftBox:
        _drawGiftBox(canvas, r);
        break;
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // FRUITS
  // ---------------------------------------------------------------------------
  void _drawApple(Canvas canvas, double r) {
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFFF87171), Color(0xFFDC2626), Color(0xFF991B1B)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final path = Path();
    path.moveTo(0, -r * 0.7);
    path.cubicTo(-r * 0.6, -r * 1.1, -r * 1.1, -r * 0.3, -r * 0.95, r * 0.4);
    path.cubicTo(-r * 0.8, r * 1.0, -r * 0.2, r * 1.05, 0, r * 0.85);
    path.cubicTo(r * 0.2, r * 1.05, r * 0.8, r * 1.0, r * 0.95, r * 0.4);
    path.cubicTo(r * 1.1, -r * 0.3, r * 0.6, -r * 1.1, 0, -r * 0.7);
    canvas.drawPath(path, bodyPaint);

    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round;
    final stem = Path()
      ..moveTo(0, -r * 0.65)
      ..quadraticBezierTo(r * 0.15, -r * 1.05, r * 0.25, -r * 1.25);
    canvas.drawPath(stem, stemPaint);

    // Leaf
    final leafPaint = Paint()..color = const Color(0xFF22C55E);
    final leaf = Path()
      ..moveTo(r * 0.1, -r * 0.9)
      ..quadraticBezierTo(r * 0.6, -r * 1.15, r * 0.7, -r * 0.8)
      ..quadraticBezierTo(r * 0.4, -r * 0.65, r * 0.1, -r * 0.9);
    canvas.drawPath(leaf, leafPaint);

    // Highlight
    final hlPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(-r * 0.4, -r * 0.3), r * 0.16, hlPaint);
  }

  void _drawOrange(Canvas canvas, double r) {
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFFFDBA74), Color(0xFFF97316), Color(0xFFC2410C)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r * 0.95, bodyPaint);

    // Dimples texture
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(-r * 0.4, -r * 0.4), r * 0.08, dotPaint);
    canvas.drawCircle(Offset(r * 0.3, -r * 0.2), r * 0.06, dotPaint);
    canvas.drawCircle(Offset(-r * 0.2, r * 0.4), r * 0.07, dotPaint);

    // Leaf
    final leafPaint = Paint()..color = const Color(0xFF16A34A);
    final leaf = Path()
      ..moveTo(0, -r * 0.9)
      ..quadraticBezierTo(r * 0.45, -r * 1.25, r * 0.55, -r * 0.8)
      ..quadraticBezierTo(r * 0.25, -r * 0.7, 0, -r * 0.9);
    canvas.drawPath(leaf, leafPaint);
  }

  void _drawBanana(Canvas canvas, double r) {
    final bananaPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFFFEF08A), Color(0xFFFACC15), Color(0xFFCA8A04)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final path = Path()
      ..moveTo(-r * 0.85, -r * 0.6)
      ..quadraticBezierTo(0, -r * 1.1, r * 0.85, r * 0.4)
      ..quadraticBezierTo(0, r * 0.3, -r * 0.85, -r * 0.6);
    canvas.drawPath(path, bananaPaint);

    // Tips
    final tipPaint = Paint()..color = const Color(0xFF713F12);
    canvas.drawCircle(Offset(-r * 0.85, -r * 0.6), r * 0.12, tipPaint);
    canvas.drawCircle(Offset(r * 0.85, r * 0.4), r * 0.10, tipPaint);
  }

  void _drawStrawberry(Canvas canvas, double r) {
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        colors: const [Color(0xFFF87171), Color(0xFFEF4444), Color(0xFFB91C1C)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final path = Path()
      ..moveTo(0, -r * 0.7)
      ..cubicTo(-r * 0.9, -r * 0.7, -r * 0.9, r * 0.2, 0, r * 1.0)
      ..cubicTo(r * 0.9, r * 0.2, r * 0.9, -r * 0.7, 0, -r * 0.7);
    canvas.drawPath(path, bodyPaint);

    // Green crown
    final crownPaint = Paint()..color = const Color(0xFF22C55E);
    for (int i = -2; i <= 2; i++) {
      final crown = Path()
        ..moveTo(0, -r * 0.65)
        ..quadraticBezierTo(i * r * 0.35, -r * 1.05, i * r * 0.4, -r * 0.65);
      canvas.drawPath(crown, crownPaint);
    }

    // Yellow seeds
    final seedPaint = Paint()..color = const Color(0xFFFEF08A);
    const seeds = [
      Offset(-0.35, -0.2),
      Offset(0.0, -0.3),
      Offset(0.35, -0.2),
      Offset(-0.2, 0.15),
      Offset(0.2, 0.15),
      Offset(0.0, 0.5),
    ];
    for (final s in seeds) {
      canvas.drawCircle(Offset(s.dx * r, s.dy * r), r * 0.05, seedPaint);
    }
  }

  void _drawGrapes(Canvas canvas, double r) {
    final grapePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFFC084FC), Color(0xFF9333EA), Color(0xFF581C87)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final circles = [
      Offset(-r * 0.4, -r * 0.3),
      Offset(0, -r * 0.35),
      Offset(r * 0.4, -r * 0.3),
      Offset(-r * 0.25, 0.05),
      Offset(r * 0.25, 0.05),
      Offset(0, r * 0.45),
    ];

    for (final c in circles) {
      canvas.drawCircle(c, r * 0.32, grapePaint);
      final hl = Paint()..color = Colors.white.withValues(alpha: 0.45);
      canvas.drawCircle(c + Offset(-r * 0.08, -r * 0.08), r * 0.08, hl);
    }

    // Leaf
    final leafPaint = Paint()..color = const Color(0xFF16A34A);
    final leaf = Path()
      ..moveTo(0, -r * 0.4)
      ..quadraticBezierTo(r * 0.4, -r * 0.9, r * 0.5, -r * 0.5)
      ..quadraticBezierTo(r * 0.2, -r * 0.3, 0, -r * 0.4);
    canvas.drawPath(leaf, leafPaint);
  }

  // ---------------------------------------------------------------------------
  // ANIMALS
  // ---------------------------------------------------------------------------
  void _drawCat(Canvas canvas, double r) {
    final headPaint = Paint()..color = const Color(0xFFFBBF24); // Warm ginger
    canvas.drawCircle(Offset(0, r * 0.1), r * 0.75, headPaint);

    // Ears
    final earPaint = Paint()..color = const Color(0xFFF59E0B);
    final innerEar = Paint()..color = const Color(0xFFFDA4AF);
    final leftEar = Path()
      ..moveTo(-r * 0.65, -r * 0.2)
      ..lineTo(-r * 0.65, -r * 0.9)
      ..lineTo(-r * 0.15, -r * 0.55)
      ..close();
    canvas.drawPath(leftEar, earPaint);

    final leftInner = Path()
      ..moveTo(-r * 0.58, -r * 0.25)
      ..lineTo(-r * 0.58, -r * 0.75)
      ..lineTo(-r * 0.22, -r * 0.5)
      ..close();
    canvas.drawPath(leftInner, innerEar);

    final rightEar = Path()
      ..moveTo(r * 0.65, -r * 0.2)
      ..lineTo(r * 0.65, -r * 0.9)
      ..lineTo(r * 0.15, -r * 0.55)
      ..close();
    canvas.drawPath(rightEar, earPaint);

    final rightInner = Path()
      ..moveTo(r * 0.58, -r * 0.25)
      ..lineTo(r * 0.58, -r * 0.75)
      ..lineTo(r * 0.22, -r * 0.5)
      ..close();
    canvas.drawPath(rightInner, innerEar);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(-r * 0.3, 0), r * 0.10, eyePaint);
    canvas.drawCircle(Offset(r * 0.3, 0), r * 0.10, eyePaint);

    // Nose & Whiskers
    final nosePaint = Paint()..color = const Color(0xFFE11D48);
    final nose = Path()
      ..moveTo(0, r * 0.18)
      ..lineTo(-r * 0.1, r * 0.10)
      ..lineTo(r * 0.1, r * 0.10)
      ..close();
    canvas.drawPath(nose, nosePaint);

    final whiskerPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = r * 0.05
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(-r * 0.3, r * 0.2),
      Offset(-r * 0.8, r * 0.15),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(-r * 0.3, r * 0.3),
      Offset(-r * 0.75, r * 0.35),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(r * 0.3, r * 0.2),
      Offset(r * 0.8, r * 0.15),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(r * 0.3, r * 0.3),
      Offset(r * 0.75, r * 0.35),
      whiskerPaint,
    );
  }

  void _drawDog(Canvas canvas, double r) {
    final headPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawCircle(Offset(0, 0), r * 0.75, headPaint);

    // Floppy ears
    final earPaint = Paint()..color = const Color(0xFF92400E);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.75, 0),
        width: r * 0.45,
        height: r * 0.85,
      ),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r * 0.75, 0),
        width: r * 0.45,
        height: r * 0.85,
      ),
      earPaint,
    );

    // Snout
    final snoutPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, r * 0.25),
        width: r * 0.75,
        height: r * 0.55,
      ),
      snoutPaint,
    );

    // Nose
    final nosePaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(0, r * 0.15), r * 0.12, nosePaint);

    // Eyes
    canvas.drawCircle(Offset(-r * 0.28, -r * 0.15), r * 0.09, nosePaint);
    canvas.drawCircle(Offset(r * 0.28, -r * 0.15), r * 0.09, nosePaint);

    // Tongue
    final tonguePaint = Paint()..color = const Color(0xFFF43F5E);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, r * 0.48),
        width: r * 0.25,
        height: r * 0.22,
      ),
      tonguePaint,
    );
  }

  void _drawRabbit(Canvas canvas, double r) {
    // Tall ears
    final earPaint = Paint()..color = const Color(0xFFF1F5F9);
    final innerEar = Paint()..color = const Color(0xFFFDA4AF);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.35, -r * 0.55),
        width: r * 0.30,
        height: r * 0.85,
      ),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.35, -r * 0.55),
        width: r * 0.16,
        height: r * 0.65,
      ),
      innerEar,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r * 0.35, -r * 0.55),
        width: r * 0.30,
        height: r * 0.85,
      ),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r * 0.35, -r * 0.55),
        width: r * 0.16,
        height: r * 0.65,
      ),
      innerEar,
    );

    // Head
    canvas.drawCircle(Offset(0, r * 0.2), r * 0.65, earPaint);

    // Eyes & Nose
    final eyePaint = Paint()..color = const Color(0xFFE11D48);
    canvas.drawCircle(Offset(-r * 0.25, r * 0.15), r * 0.08, eyePaint);
    canvas.drawCircle(Offset(r * 0.25, r * 0.15), r * 0.08, eyePaint);

    final nosePaint = Paint()..color = const Color(0xFFFB7185);
    canvas.drawCircle(Offset(0, r * 0.32), r * 0.07, nosePaint);
  }

  void _drawOwl(Canvas canvas, double r) {
    final bodyPaint = Paint()..color = const Color(0xFF854D0E);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, r * 0.1),
        width: r * 1.3,
        height: r * 1.5,
      ),
      bodyPaint,
    );

    // Big eye discs
    final discPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(-r * 0.32, -r * 0.15), r * 0.32, discPaint);
    canvas.drawCircle(Offset(r * 0.32, -r * 0.15), r * 0.32, discPaint);

    final eyePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(-r * 0.32, -r * 0.15), r * 0.16, eyePaint);
    canvas.drawCircle(Offset(r * 0.32, -r * 0.15), r * 0.16, eyePaint);

    // Beak
    final beakPaint = Paint()..color = const Color(0xFFF59E0B);
    final beak = Path()
      ..moveTo(0, r * 0.15)
      ..lineTo(-r * 0.15, -r * 0.05)
      ..lineTo(r * 0.15, -r * 0.05)
      ..close();
    canvas.drawPath(beak, beakPaint);
  }

  void _drawFish(Canvas canvas, double r) {
    final fishPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final body = Path()
      ..moveTo(-r * 0.6, 0)
      ..quadraticBezierTo(0, -r * 0.65, r * 0.5, 0)
      ..lineTo(r * 0.9, -r * 0.45)
      ..lineTo(r * 0.75, 0)
      ..lineTo(r * 0.9, r * 0.45)
      ..lineTo(r * 0.5, 0)
      ..quadraticBezierTo(0, r * 0.65, -r * 0.6, 0);
    canvas.drawPath(body, fishPaint);

    // Eye
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(-r * 0.35, -r * 0.1), r * 0.12, eyePaint);
    final pupilPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(-r * 0.38, -r * 0.1), r * 0.06, pupilPaint);

    // Fin
    final finPaint = Paint()..color = const Color(0xFFF59E0B);
    final fin = Path()
      ..moveTo(0, 0)
      ..lineTo(-r * 0.1, r * 0.35)
      ..lineTo(r * 0.2, r * 0.2)
      ..close();
    canvas.drawPath(fin, finPaint);
  }

  // ---------------------------------------------------------------------------
  // VEHICLES
  // ---------------------------------------------------------------------------
  void _drawCar(Canvas canvas, double r) {
    final bodyPaint = Paint()..color = const Color(0xFFEF4444);
    final carBody = Path()
      ..moveTo(-r * 0.85, r * 0.2)
      ..lineTo(-r * 0.85, 0)
      ..lineTo(-r * 0.5, 0)
      ..cubicTo(-r * 0.4, -r * 0.6, r * 0.2, -r * 0.6, r * 0.45, 0)
      ..lineTo(r * 0.85, 0)
      ..lineTo(r * 0.85, r * 0.2)
      ..close();
    canvas.drawPath(carBody, bodyPaint);

    // Windows
    final winPaint = Paint()..color = const Color(0xFF93C5FD);
    final win = Path()
      ..moveTo(-r * 0.4, -r * 0.05)
      ..lineTo(-r * 0.3, -r * 0.45)
      ..lineTo(r * 0.3, -r * 0.45)
      ..lineTo(r * 0.4, -r * 0.05)
      ..close();
    canvas.drawPath(win, winPaint);

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF1E293B);
    final rimPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawCircle(Offset(-r * 0.5, r * 0.25), r * 0.22, wheelPaint);
    canvas.drawCircle(Offset(-r * 0.5, r * 0.25), r * 0.10, rimPaint);
    canvas.drawCircle(Offset(r * 0.5, r * 0.25), r * 0.22, wheelPaint);
    canvas.drawCircle(Offset(r * 0.5, r * 0.25), r * 0.10, rimPaint);
  }

  void _drawBus(Canvas canvas, double r) {
    final busPaint = Paint()..color = const Color(0xFFFBBF24); // Yellow bus
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -r * 0.05),
          width: r * 1.6,
          height: r * 0.9,
        ),
        Radius.circular(r * 0.15),
      ),
      busPaint,
    );

    // Windows
    final winPaint = Paint()..color = const Color(0xFF38BDF8);
    for (int i = -2; i <= 2; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(i * r * 0.3, -r * 0.18),
            width: r * 0.22,
            height: r * 0.25,
          ),
          Radius.circular(r * 0.04),
        ),
        winPaint,
      );
    }

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(-r * 0.5, r * 0.4), r * 0.18, wheelPaint);
    canvas.drawCircle(Offset(r * 0.5, r * 0.4), r * 0.18, wheelPaint);
  }

  void _drawBicycle(Canvas canvas, double r) {
    final wheelPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.10;
    canvas.drawCircle(Offset(-r * 0.55, r * 0.25), r * 0.28, wheelPaint);
    canvas.drawCircle(Offset(r * 0.55, r * 0.25), r * 0.28, wheelPaint);

    final framePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;
    final frame = Path()
      ..moveTo(-r * 0.55, r * 0.25)
      ..lineTo(0, r * 0.25)
      ..lineTo(-r * 0.2, -r * 0.25)
      ..lineTo(-r * 0.55, r * 0.25)
      ..moveTo(0, r * 0.25)
      ..lineTo(r * 0.35, -r * 0.25)
      ..lineTo(r * 0.55, r * 0.25);
    canvas.drawPath(frame, framePaint);

    // Handlebar & Seat
    final partPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.10;
    canvas.drawLine(
      Offset(-r * 0.3, -r * 0.25),
      Offset(-r * 0.1, -r * 0.25),
      partPaint,
    );
    canvas.drawLine(
      Offset(r * 0.25, -r * 0.35),
      Offset(r * 0.45, -r * 0.35),
      partPaint,
    );
  }

  void _drawAirplane(Canvas canvas, double r) {
    final planePaint = Paint()..color = const Color(0xFF38BDF8);

    // Fuselage
    final body = Path()
      ..moveTo(-r * 0.9, 0)
      ..cubicTo(-r * 0.5, -r * 0.25, r * 0.5, -r * 0.25, r * 0.8, 0)
      ..cubicTo(r * 0.5, r * 0.25, -r * 0.5, r * 0.25, -r * 0.9, 0);
    canvas.drawPath(body, planePaint);

    // Wings
    final wingPaint = Paint()..color = const Color(0xFF0284C7);
    final wings = Path()
      ..moveTo(0, -r * 0.75)
      ..lineTo(r * 0.25, -r * 0.15)
      ..lineTo(-r * 0.2, -r * 0.15)
      ..close()
      ..moveTo(0, r * 0.75)
      ..lineTo(r * 0.25, r * 0.15)
      ..lineTo(-r * 0.2, r * 0.15)
      ..close();
    canvas.drawPath(wings, wingPaint);

    // Cockpit
    final glassPaint = Paint()..color = const Color(0xFFFEF08A);
    canvas.drawCircle(Offset(r * 0.55, -r * 0.05), r * 0.08, glassPaint);
  }

  // ---------------------------------------------------------------------------
  // NATURE
  // ---------------------------------------------------------------------------
  void _drawFlower(Canvas canvas, double r) {
    final petalPaint = Paint()..color = const Color(0xFFEC4899);
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final px = math.cos(angle) * r * 0.5;
      final py = math.sin(angle) * r * 0.5;
      canvas.drawCircle(Offset(px, py), r * 0.35, petalPaint);
    }
    // Center
    final centerPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(Offset.zero, r * 0.35, centerPaint);
  }

  void _drawTree(Canvas canvas, double r) {
    // Trunk
    final trunkPaint = Paint()..color = const Color(0xFF78350F);
    canvas.drawRect(Rect.fromLTWH(-r * 0.18, 0, r * 0.36, r * 0.8), trunkPaint);

    // Foliage
    final foliagePaint = Paint()
      ..shader =
          RadialGradient(
            colors: const [Color(0xFF4ADE80), Color(0xFF16A34A)],
          ).createShader(
            Rect.fromCircle(center: Offset(0, -r * 0.25), radius: r * 0.65),
          );
    canvas.drawCircle(Offset(0, -r * 0.25), r * 0.65, foliagePaint);
  }

  void _drawMushroom(Canvas canvas, double r) {
    // Stem
    final stemPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, r * 0.3),
          width: r * 0.6,
          height: r * 0.7,
        ),
        Radius.circular(r * 0.2),
      ),
      stemPaint,
    );

    // Cap
    final capPaint = Paint()..color = const Color(0xFFEF4444);
    final cap = Path()
      ..moveTo(-r * 0.85, r * 0.1)
      ..quadraticBezierTo(0, -r * 1.0, r * 0.85, r * 0.1)
      ..close();
    canvas.drawPath(cap, capPaint);

    // Polka dots
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(-r * 0.4, -r * 0.2), r * 0.12, dotPaint);
    canvas.drawCircle(Offset(0, -r * 0.45), r * 0.14, dotPaint);
    canvas.drawCircle(Offset(r * 0.4, -r * 0.2), r * 0.12, dotPaint);
  }

  void _drawSun(Canvas canvas, double r) {
    final rayPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x1 = math.cos(angle) * r * 0.65;
      final y1 = math.sin(angle) * r * 0.65;
      final x2 = math.cos(angle) * r * 0.95;
      final y2 = math.sin(angle) * r * 0.95;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), rayPaint);
    }

    final sunPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(Offset.zero, r * 0.55, sunPaint);

    // Smiling eyes
    final eyePaint = Paint()..color = const Color(0xFF92400E);
    canvas.drawCircle(Offset(-r * 0.18, -r * 0.08), r * 0.06, eyePaint);
    canvas.drawCircle(Offset(r * 0.18, -r * 0.08), r * 0.06, eyePaint);
  }

  // ---------------------------------------------------------------------------
  // EVERYDAY OBJECTS
  // ---------------------------------------------------------------------------
  void _drawClock(Canvas canvas, double r) {
    // Top bells
    final bellPaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawCircle(Offset(-r * 0.5, -r * 0.55), r * 0.22, bellPaint);
    canvas.drawCircle(Offset(r * 0.5, -r * 0.55), r * 0.22, bellPaint);

    // Body
    final dialPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawCircle(Offset.zero, r * 0.75, dialPaint);

    final facePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, r * 0.60, facePaint);

    // Hands
    final handPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(0, -r * 0.38), handPaint);
    canvas.drawLine(Offset.zero, Offset(r * 0.25, 0), handPaint);
  }

  void _drawBook(Canvas canvas, double r) {
    final coverPaint = Paint()..color = const Color(0xFF6366F1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * 1.5, height: r * 1.2),
        Radius.circular(r * 0.12),
      ),
      coverPaint,
    );

    final pagesPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(r * 0.05, 0),
          width: r * 1.3,
          height: r * 1.05,
        ),
        Radius.circular(r * 0.08),
      ),
      pagesPaint,
    );

    // Bookmark ribbon
    final ribbonPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRect(
      Rect.fromLTWH(0, -r * 0.55, r * 0.14, r * 0.8),
      ribbonPaint,
    );
  }

  void _drawUmbrella(Canvas canvas, double r) {
    final canopyPaint = Paint()..color = const Color(0xFFF43F5E);
    final canopy = Path()
      ..moveTo(-r * 0.85, 0)
      ..quadraticBezierTo(0, -r * 1.05, r * 0.85, 0)
      ..close();
    canvas.drawPath(canopy, canopyPaint);

    // Shaft & hook handle
    final handlePaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;
    final handle = Path()
      ..moveTo(0, 0)
      ..lineTo(0, r * 0.65)
      ..quadraticBezierTo(0, r * 0.9, -r * 0.2, r * 0.85);
    canvas.drawPath(handle, handlePaint);
  }

  void _drawCup(Canvas canvas, double r) {
    final cupPaint = Paint()..color = const Color(0xFF14B8A6);
    final cup = Path()
      ..moveTo(-r * 0.55, -r * 0.4)
      ..lineTo(r * 0.55, -r * 0.4)
      ..quadraticBezierTo(r * 0.5, r * 0.6, 0, r * 0.65)
      ..quadraticBezierTo(-r * 0.5, r * 0.6, -r * 0.55, -r * 0.4);
    canvas.drawPath(cup, cupPaint);

    // Handle
    final handlePaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(r * 0.55, 0),
        width: r * 0.45,
        height: r * 0.45,
      ),
      -math.pi / 2,
      math.pi,
      false,
      handlePaint,
    );

    // Steam swirl
    final steamPaint = Paint()
      ..color = const Color(0xFF99F6E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;
    final steam = Path()
      ..moveTo(-r * 0.15, -r * 0.55)
      ..quadraticBezierTo(0, -r * 0.75, -r * 0.1, -r * 0.95);
    canvas.drawPath(steam, steamPaint);
  }

  void _drawKey(Canvas canvas, double r) {
    final keyPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round;

    // Bow (circle head)
    canvas.drawCircle(Offset(-r * 0.4, 0), r * 0.32, keyPaint);

    // Shaft
    canvas.drawLine(Offset(-r * 0.1, 0), Offset(r * 0.7, 0), keyPaint);

    // Wards
    canvas.drawLine(Offset(r * 0.45, 0), Offset(r * 0.45, r * 0.3), keyPaint);
    canvas.drawLine(Offset(r * 0.65, 0), Offset(r * 0.65, r * 0.22), keyPaint);
  }

  // ---------------------------------------------------------------------------
  // SPECIAL
  // ---------------------------------------------------------------------------
  void _drawStar(Canvas canvas, double r) {
    final starPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFEF08A), Color(0xFFFBBF24), Color(0xFFD97706)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final rad = i.isEven ? r * 0.9 : r * 0.42;
      final angle = (i * math.pi / 5) - (math.pi / 2);
      final x = math.cos(angle) * rad;
      final y = math.sin(angle) * rad;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, starPaint);

    // Cute smiling eyes
    final facePaint = Paint()..color = const Color(0xFF78350F);
    canvas.drawCircle(Offset(-r * 0.15, -r * 0.05), r * 0.06, facePaint);
    canvas.drawCircle(Offset(r * 0.15, -r * 0.05), r * 0.06, facePaint);
  }

  void _drawBalloon(Canvas canvas, double r) {
    final balloonPaint = Paint()
      ..shader =
          RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: const [
              Color(0xFFF472B6),
              Color(0xFFDB2777),
              Color(0xFF9D174D),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(0, -r * 0.1), radius: r * 0.7),
          );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -r * 0.15),
        width: r * 1.15,
        height: r * 1.35,
      ),
      balloonPaint,
    );

    // Knot
    final knotPaint = Paint()..color = const Color(0xFF9D174D);
    final knot = Path()
      ..moveTo(-r * 0.12, r * 0.52)
      ..lineTo(r * 0.12, r * 0.52)
      ..lineTo(0, r * 0.62)
      ..close();
    canvas.drawPath(knot, knotPaint);

    // String
    final stringPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.06;
    final stringPath = Path()
      ..moveTo(0, r * 0.62)
      ..quadraticBezierTo(-r * 0.15, r * 0.8, r * 0.05, r * 1.05);
    canvas.drawPath(stringPath, stringPaint);
  }

  void _drawRocket(Canvas canvas, double r) {
    // Body
    final bodyPaint = Paint()..color = const Color(0xFFF1F5F9);
    final body = Path()
      ..moveTo(0, -r * 0.95)
      ..quadraticBezierTo(r * 0.45, -r * 0.3, r * 0.35, r * 0.4)
      ..lineTo(-r * 0.35, r * 0.4)
      ..quadraticBezierTo(-r * 0.45, -r * 0.3, 0, -r * 0.95);
    canvas.drawPath(body, bodyPaint);

    // Fins
    final finPaint = Paint()..color = const Color(0xFFEF4444);
    final leftFin = Path()
      ..moveTo(-r * 0.35, r * 0.1)
      ..lineTo(-r * 0.7, r * 0.5)
      ..lineTo(-r * 0.35, r * 0.4)
      ..close();
    canvas.drawPath(leftFin, finPaint);

    final rightFin = Path()
      ..moveTo(r * 0.35, r * 0.1)
      ..lineTo(r * 0.7, r * 0.5)
      ..lineTo(r * 0.35, r * 0.4)
      ..close();
    canvas.drawPath(rightFin, finPaint);

    // Porthole
    final portPaint = Paint()..color = const Color(0xFF0EA5E9);
    canvas.drawCircle(Offset(0, -r * 0.2), r * 0.16, portPaint);

    // Flame
    final flamePaint = Paint()..color = const Color(0xFFF59E0B);
    final flame = Path()
      ..moveTo(-r * 0.2, r * 0.4)
      ..lineTo(0, r * 0.85)
      ..lineTo(r * 0.2, r * 0.4)
      ..close();
    canvas.drawPath(flame, flamePaint);
  }

  void _drawGiftBox(Canvas canvas, double r) {
    // Box body
    final boxPaint = Paint()..color = const Color(0xFF8B5CF6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, r * 0.15),
          width: r * 1.3,
          height: r * 1.1,
        ),
        Radius.circular(r * 0.12),
      ),
      boxPaint,
    );

    // Lid
    final lidPaint = Paint()..color = const Color(0xFF7C3AED);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -r * 0.4),
          width: r * 1.45,
          height: r * 0.32,
        ),
        Radius.circular(r * 0.08),
      ),
      lidPaint,
    );

    // Golden ribbons
    final ribbonPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawRect(
      Rect.fromLTWH(-r * 0.14, -r * 0.55, r * 0.28, r * 1.25),
      ribbonPaint,
    );

    // Bow loops
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.2, -r * 0.65),
        width: r * 0.35,
        height: r * 0.22,
      ),
      ribbonPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r * 0.2, -r * 0.65),
        width: r * 0.35,
        height: r * 0.22,
      ),
      ribbonPaint,
    );
  }

  @override
  bool shouldRepaint(MemoryMatchArtworkPainter oldDelegate) {
    return oldDelegate.artwork != artwork;
  }
}
