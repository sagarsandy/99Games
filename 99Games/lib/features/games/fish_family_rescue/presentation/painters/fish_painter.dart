import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/fish_family_models.dart';

/// CustomPainter that renders a cute cartoon fish with expressive eyes,
/// fins, tails, patterns, and species-specific color schemes on Canvas.
///
/// 100% Canvas drawing with ZERO external image assets or SVGs.
class FishPainter extends CustomPainter {
  final FishSpecies species;
  final FishExpression expression;
  final bool isSelected;
  final double animationProgress;
  final bool facingRight;

  const FishPainter({
    required this.species,
    this.expression = FishExpression.happy,
    this.isSelected = false,
    this.animationProgress = 0.0,
    this.facingRight = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();

    // If facing left, flip horizontally around center
    if (!facingRight) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final center = Offset(size.width * 0.45, size.height * 0.52);
    final bodyW = size.width * 0.55;
    final bodyH = size.height * 0.58;

    // Tail wag oscillation based on animationProgress
    final tailWag = math.sin(animationProgress * 2 * math.pi) * 0.12;

    // 1. Draw Tail Fin (behind body)
    _drawTail(canvas, size, center, bodyW, bodyH, tailWag);

    // 2. Draw Dorsal Fin (top)
    _drawDorsalFin(canvas, center, bodyW, bodyH);

    // 3. Draw Body
    _drawBody(canvas, center, bodyW, bodyH);

    // 4. Draw Species Pattern (stripes, spots, dual tones)
    _drawSpeciesPattern(canvas, center, bodyW, bodyH);

    // 5. Draw Belly Highlight
    _drawBellyHighlight(canvas, center, bodyW, bodyH);

    // 6. Draw Pectoral Fin (front)
    _drawPectoralFin(canvas, center, bodyW, bodyH, tailWag);

    // 7. Draw Expressive Face (Eyes, Pupil, Gloss, Mouth, Blush)
    _drawFace(canvas, center, bodyW, bodyH);

    // 8. If selected, draw glowing outline / sparkle halo
    if (isSelected) {
      _drawSelectionGlow(canvas, center, bodyW, bodyH);
    }

    canvas.restore();
  }

  void _drawTail(
    Canvas canvas,
    Size size,
    Offset center,
    double bodyW,
    double bodyH,
    double tailWag,
  ) {
    final tailPaint = Paint()
      ..color =
          species.accentColor == Colors.black ||
              species.accentColor == const Color(0xFF262626)
          ? species.primaryColor
          : species.accentColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final finLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.save();
    final tailOrigin = Offset(center.dx - bodyW * 0.45, center.dy);
    canvas.translate(tailOrigin.dx, tailOrigin.dy);
    canvas.rotate(tailWag);

    final tailPath = Path();
    final tailLen = bodyW * 0.42;

    switch (species.tailStyle) {
      case FishTailStyle.forked:
        tailPath.moveTo(0, -bodyH * 0.15);
        tailPath.lineTo(-tailLen, -bodyH * 0.42);
        tailPath.quadraticBezierTo(-tailLen * 0.6, 0, -tailLen, bodyH * 0.42);
        tailPath.lineTo(0, bodyH * 0.15);
        tailPath.close();
        break;

      case FishTailStyle.fan:
        tailPath.moveTo(0, -bodyH * 0.15);
        tailPath.quadraticBezierTo(
          -tailLen * 0.5,
          -bodyH * 0.45,
          -tailLen,
          -bodyH * 0.4,
        );
        tailPath.quadraticBezierTo(-tailLen * 1.1, 0, -tailLen, bodyH * 0.4);
        tailPath.quadraticBezierTo(
          -tailLen * 0.5,
          bodyH * 0.45,
          0,
          bodyH * 0.15,
        );
        tailPath.close();
        break;

      case FishTailStyle.heart:
        tailPath.moveTo(0, 0);
        tailPath.cubicTo(
          -tailLen * 0.3,
          -bodyH * 0.45,
          -tailLen,
          -bodyH * 0.35,
          -tailLen * 0.8,
          0,
        );
        tailPath.cubicTo(
          -tailLen,
          bodyH * 0.35,
          -tailLen * 0.3,
          bodyH * 0.45,
          0,
          0,
        );
        tailPath.close();
        break;

      case FishTailStyle.rounded:
        tailPath.moveTo(0, -bodyH * 0.18);
        tailPath.quadraticBezierTo(-tailLen, -bodyH * 0.35, -tailLen, 0);
        tailPath.quadraticBezierTo(-tailLen, bodyH * 0.35, 0, bodyH * 0.18);
        tailPath.close();
        break;
    }

    canvas.drawPath(tailPath, tailPaint);

    // Subtle fin ray detail lines
    canvas.drawLine(
      const Offset(0, 0),
      Offset(-tailLen * 0.8, 0),
      finLinePaint,
    );
    canvas.drawLine(
      Offset(0, -bodyH * 0.08),
      Offset(-tailLen * 0.75, -bodyH * 0.2),
      finLinePaint,
    );
    canvas.drawLine(
      Offset(0, bodyH * 0.08),
      Offset(-tailLen * 0.75, bodyH * 0.2),
      finLinePaint,
    );

    canvas.restore();
  }

  void _drawDorsalFin(
    Canvas canvas,
    Offset center,
    double bodyW,
    double bodyH,
  ) {
    final dorsalPaint = Paint()
      ..color = species.primaryColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(center.dx - bodyW * 0.25, center.dy - bodyH * 0.42)
      ..quadraticBezierTo(
        center.dx,
        center.dy - bodyH * 0.78,
        center.dx + bodyW * 0.15,
        center.dy - bodyH * 0.44,
      )
      ..close();

    canvas.drawPath(path, dorsalPaint);

    final rimPaint = Paint()
      ..color = species.secondaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, rimPaint);
  }

  void _drawBody(Canvas canvas, Offset center, double bodyW, double bodyH) {
    final bodyRect = Rect.fromCenter(
      center: center,
      width: bodyW,
      height: bodyH,
    );

    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        species.primaryColor,
        Color.lerp(species.primaryColor, species.secondaryColor, 0.45)!,
      ],
    );

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(bodyRect)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Smooth rounded fish body path (slightly tapered at tail, rounded at head)
    final bodyPath = Path()
      ..moveTo(center.dx - bodyW * 0.46, center.dy)
      ..cubicTo(
        center.dx - bodyW * 0.35,
        center.dy - bodyH * 0.52,
        center.dx + bodyW * 0.2,
        center.dy - bodyH * 0.52,
        center.dx + bodyW * 0.48,
        center.dy,
      )
      ..cubicTo(
        center.dx + bodyW * 0.2,
        center.dy + bodyH * 0.52,
        center.dx - bodyW * 0.35,
        center.dy + bodyH * 0.52,
        center.dx - bodyW * 0.46,
        center.dy,
      )
      ..close();

    // Soft drop shadow beneath fish
    canvas.drawShadow(
      bodyPath,
      Colors.black.withValues(alpha: 0.25),
      3.0,
      false,
    );

    canvas.drawPath(bodyPath, bodyPaint);
  }

  void _drawSpeciesPattern(
    Canvas canvas,
    Offset center,
    double bodyW,
    double bodyH,
  ) {
    switch (species.patternType) {
      case FishPatternType.stripes:
        // Clownfish / Anthias style: 2 curved vertical white stripes with dark trim
        final stripePaint = Paint()
          ..color = species.secondaryColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        final stripeBorder = Paint()
          ..color = species.accentColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        for (final offsetFactor in [-0.15, 0.12]) {
          final stripePath = Path()
            ..moveTo(
              center.dx + bodyW * offsetFactor - 4,
              center.dy - bodyH * 0.4,
            )
            ..quadraticBezierTo(
              center.dx + bodyW * (offsetFactor - 0.05),
              center.dy,
              center.dx + bodyW * offsetFactor - 4,
              center.dy + bodyH * 0.4,
            )
            ..lineTo(
              center.dx + bodyW * offsetFactor + 5,
              center.dy + bodyH * 0.4,
            )
            ..quadraticBezierTo(
              center.dx + bodyW * (offsetFactor + 0.04),
              center.dy,
              center.dx + bodyW * offsetFactor + 5,
              center.dy - bodyH * 0.4,
            )
            ..close();

          canvas.drawPath(stripePath, stripePaint);
          canvas.drawPath(stripePath, stripeBorder);
        }
        break;

      case FishPatternType.spots:
        // Chromis style: cute round pastel polka dots
        final spotPaint = Paint()
          ..color = species.secondaryColor.withValues(alpha: 0.75)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        final spots = [
          Offset(center.dx - bodyW * 0.18, center.dy - bodyH * 0.12),
          Offset(center.dx - bodyW * 0.05, center.dy - bodyH * 0.18),
          Offset(center.dx - bodyW * 0.12, center.dy + bodyH * 0.1),
          Offset(center.dx + bodyW * 0.05, center.dy - bodyH * 0.05),
        ];

        for (final sp in spots) {
          canvas.drawCircle(sp, 3.5, spotPaint);
        }
        break;

      case FishPatternType.dualTone:
        // Royal Gramma / Blue Tang: stylish back-half or swirl overlay
        final dualPaint = Paint()
          ..color = species.secondaryColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        final swirlPath = Path()
          ..moveTo(center.dx - bodyW * 0.44, center.dy)
          ..quadraticBezierTo(
            center.dx - bodyW * 0.1,
            center.dy - bodyH * 0.35,
            center.dx - bodyW * 0.05,
            center.dy,
          )
          ..quadraticBezierTo(
            center.dx - bodyW * 0.1,
            center.dy + bodyH * 0.35,
            center.dx - bodyW * 0.44,
            center.dy,
          )
          ..close();

        canvas.drawPath(swirlPath, dualPaint);
        break;

      case FishPatternType.bellyGrad:
      case FishPatternType.scales:
      case FishPatternType.finsGlow:
        // Soft lateral accent line
        final linePaint = Paint()
          ..color = species.secondaryColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(center.dx - bodyW * 0.35, center.dy + bodyH * 0.05),
          Offset(center.dx + bodyW * 0.15, center.dy + bodyH * 0.05),
          linePaint,
        );
        break;
    }
  }

  void _drawBellyHighlight(
    Canvas canvas,
    Offset center,
    double bodyW,
    double bodyH,
  ) {
    final bellyPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final bellyPath = Path()
      ..moveTo(center.dx - bodyW * 0.25, center.dy + bodyH * 0.36)
      ..quadraticBezierTo(
        center.dx + bodyW * 0.1,
        center.dy + bodyH * 0.42,
        center.dx + bodyW * 0.35,
        center.dy + bodyH * 0.2,
      );

    canvas.drawPath(bellyPath, bellyPaint);
  }

  void _drawPectoralFin(
    Canvas canvas,
    Offset center,
    double bodyW,
    double bodyH,
    double tailWag,
  ) {
    final finPaint = Paint()
      ..color = species.primaryColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final finBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();
    final finOrigin = Offset(
      center.dx + bodyW * 0.05,
      center.dy + bodyH * 0.08,
    );
    canvas.translate(finOrigin.dx, finOrigin.dy);
    canvas.rotate(-0.15 + tailWag * 0.4);

    final finPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        -bodyW * 0.22,
        bodyH * 0.12,
        -bodyW * 0.18,
        bodyH * 0.28,
      )
      ..quadraticBezierTo(-bodyW * 0.05, bodyH * 0.22, 0, 0)
      ..close();

    canvas.drawPath(finPath, finPaint);
    canvas.drawPath(finPath, finBorder);
    canvas.restore();
  }

  void _drawFace(Canvas canvas, Offset center, double bodyW, double bodyH) {
    final eyeCenter = Offset(center.dx + bodyW * 0.3, center.dy - bodyH * 0.12);
    final eyeR = bodyH * 0.24;

    // 1. Eye Sclera (White)
    final scleraPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(eyeCenter, eyeR, scleraPaint);

    final eyeBorder = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(eyeCenter, eyeR, eyeBorder);

    // 2. Pupil
    final pupilR = eyeR * 0.62;
    final pupilOffset = Offset(eyeCenter.dx + eyeR * 0.18, eyeCenter.dy);
    final pupilPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (expression == FishExpression.wink) {
      // Winking arc
      final winkPaint = Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final winkPath = Path()
        ..moveTo(eyeCenter.dx - eyeR * 0.6, eyeCenter.dy)
        ..quadraticBezierTo(
          eyeCenter.dx,
          eyeCenter.dy - eyeR * 0.5,
          eyeCenter.dx + eyeR * 0.6,
          eyeCenter.dy,
        );
      canvas.drawPath(winkPath, winkPaint);
    } else {
      canvas.drawCircle(pupilOffset, pupilR, pupilPaint);

      // Cute Shiny Specular Highlights (Double Glint)
      final glintBig = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(pupilOffset.dx - pupilR * 0.35, pupilOffset.dy - pupilR * 0.35),
        pupilR * 0.42,
        glintBig,
      );

      final glintSmall = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(pupilOffset.dx + pupilR * 0.35, pupilOffset.dy + pupilR * 0.35),
        pupilR * 0.22,
        glintSmall,
      );
    }

    // 3. Cute Pink Blush Cheek
    final blushPaint = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          eyeCenter.dx - bodyW * 0.04,
          eyeCenter.dy + bodyH * 0.24,
        ),
        width: eyeR * 0.9,
        height: eyeR * 0.55,
      ),
      blushPaint,
    );

    // 4. Cute Cartoon Smiling Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(center.dx + bodyW * 0.44, center.dy + bodyH * 0.12)
      ..quadraticBezierTo(
        center.dx + bodyW * 0.48,
        center.dy + bodyH * 0.22,
        center.dx + bodyW * 0.4,
        center.dy + bodyH * 0.26,
      );
    canvas.drawPath(mouthPath, mouthPaint);
  }

  void _drawSelectionGlow(
    Canvas canvas,
    Offset center,
    double bodyW,
    double bodyH,
  ) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6.0);

    final glowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: bodyW * 1.25,
            height: bodyH * 1.35,
          ),
          Radius.circular(bodyH * 0.6),
        ),
      );

    canvas.drawPath(glowPath, glowPaint);
  }

  @override
  bool shouldRepaint(covariant FishPainter oldDelegate) {
    return oldDelegate.species != species ||
        oldDelegate.expression != expression ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.facingRight != facingRight;
  }
}
