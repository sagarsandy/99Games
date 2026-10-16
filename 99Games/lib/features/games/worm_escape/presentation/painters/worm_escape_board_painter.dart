import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/worm_escape_engine.dart';
import '../../domain/worm_escape_models.dart';

/// Pure CustomPainter that renders the entire Worm Escape board, segmented worms,
/// expressive eyes, caterpillar ribs, blocked warnings, and hint pulses using Canvas.
class WormEscapeBoardPainter extends CustomPainter {
  final WormEscapeEngine engine;
  final bool isDark;
  final String? animatingWormId;
  final double escapeProgress;
  final String? blockedWormId;
  final String? blockingWormId;
  final double blockedProgress;
  final String? hintWormId;
  final double hintPulse;

  WormEscapeBoardPainter({
    required this.engine,
    required this.isDark,
    this.animatingWormId,
    this.escapeProgress = 0.0,
    this.blockedWormId,
    this.blockingWormId,
    this.blockedProgress = 0.0,
    this.hintWormId,
    this.hintPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = engine.boardSize;
    if (boardSize <= 0) return;

    final cellSize = size.width / boardSize;

    // 1. Draw subtle board grid & cell tiles
    _drawBoardGrid(canvas, size, boardSize, cellSize);

    // 2. Draw blocked trajectory & warning indicators if a worm is blocked
    if (blockedWormId != null) {
      final blockedWorm = engine.worms[blockedWormId];
      if (blockedWorm != null) {
        _drawBlockedWarning(canvas, blockedWorm, cellSize);
      }
    }

    // 3. Draw hint indicators if a worm is hinted
    if (hintWormId != null) {
      final hintWorm = engine.worms[hintWormId];
      if (hintWorm != null && hintWorm.isActive) {
        _drawHintIndicator(canvas, hintWorm, cellSize);
      }
    }

    // 4. Draw all active and animating worms
    // Draw non-animating worms first, then animating worm on top
    Worm? animatingWorm;

    for (final worm in engine.worms.values) {
      if (worm.id == animatingWormId) {
        animatingWorm = worm;
        continue;
      }
      if (worm.isActive) {
        _drawWorm(canvas, worm, cellSize);
      }
    }

    if (animatingWorm != null) {
      _drawWorm(canvas, animatingWorm, cellSize);
    }
  }

  /// Draws the background grid tiles and borders.
  void _drawBoardGrid(
    Canvas canvas,
    Size size,
    int boardSize,
    double cellSize,
  ) {
    final tilePaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.45)
          : const Color(0xFFF1F5F9).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isDark
          ? const Color(0xFF334155).withValues(alpha: 0.3)
          : const Color(0xFFCBD5E1).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final tileRadius = Radius.circular(max(4.0, cellSize * 0.16));

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final rect = Rect.fromLTWH(
          c * cellSize + 2.0,
          r * cellSize + 2.0,
          cellSize - 4.0,
          cellSize - 4.0,
        );
        final rrect = RRect.fromRectAndRadius(rect, tileRadius);
        canvas.drawRRect(rrect, tilePaint);
        canvas.drawRRect(rrect, borderPaint);
      }
    }
  }

  /// Draws a segmented worm with rounded fleshy segments, head, eyes, pupils, and blush.
  void _drawWorm(Canvas canvas, Worm worm, double cellSize) {
    Offset dynamicOffset = Offset.zero;

    // A. Escape crawl animation offset with subtle caterpillar undulation
    if (worm.id == animatingWormId) {
      final totalDist = (engine.boardSize + worm.length + 1) * cellSize;
      final fwdDist = totalDist * escapeProgress;
      final fwdOffset = Offset(
        worm.direction.dCol * fwdDist,
        worm.direction.dRow * fwdDist,
      );

      // Cute sine wave crawl undulation
      final undulation = sin(escapeProgress * 6 * pi) * (cellSize * 0.06);
      Offset lateralOffset = Offset.zero;
      if (worm.direction.isHorizontal) {
        lateralOffset = Offset(0, undulation);
      } else {
        lateralOffset = Offset(undulation, 0);
      }

      dynamicOffset = fwdOffset + lateralOffset;
    }
    // B. Blocked shake/nudge animation offset
    else if (worm.id == blockedWormId) {
      final nudge = sin(blockedProgress * 2 * pi) * (cellSize * 0.14);
      dynamicOffset = Offset(
        worm.direction.dCol * nudge,
        worm.direction.dRow * nudge,
      );
    }

    final baseColor = WormColors.getColor(worm.colorIndex);
    final highlightColor = WormColors.getHighlightColor(worm.colorIndex);
    final shadowColor = WormColors.getShadowColor(worm.colorIndex);

    final segmentRadius = cellSize * 0.38;
    final headRadius = cellSize * 0.44;

    // Compute pixel centers of all segments
    final segmentCenters = <Offset>[];
    for (final pos in worm.body) {
      final center =
          Offset((pos.col + 0.5) * cellSize, (pos.row + 0.5) * cellSize) +
          dynamicOffset;
      segmentCenters.add(center);
    }

    // 1. Connect body segments with a smooth, continuous fleshy cylinder
    final bodyConnectorPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = segmentRadius * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < segmentCenters.length - 1; i++) {
      canvas.drawLine(
        segmentCenters[i],
        segmentCenters[i + 1],
        bodyConnectorPaint,
      );
    }

    // 2. Draw individual body segments from tail to head
    for (int i = segmentCenters.length - 1; i >= 0; i--) {
      final center = segmentCenters[i];
      final isHead = (i == 0);
      final isTail = (i == segmentCenters.length - 1);
      final r = isHead
          ? headRadius
          : (isTail ? segmentRadius * 0.92 : segmentRadius);

      // Segment base fill
      final fillPaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r, fillPaint);

      // Segment shading: subtle bottom-right shadow arc
      final shadowPaint = Paint()
        ..color = shadowColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, cellSize * 0.04);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - 1.0),
        pi / 4,
        pi / 2,
        false,
        shadowPaint,
      );

      // Segment highlight: soft top-left glint
      final highlightPaint = Paint()
        ..color = highlightColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      final highlightOffset = Offset(
        center.dx - r * 0.28,
        center.dy - r * 0.28,
      );
      canvas.drawCircle(highlightOffset, r * 0.32, highlightPaint);

      // Subtle rib groove between consecutive body segments
      if (!isHead && i < segmentCenters.length - 1) {
        final ribPaint = Paint()
          ..color = shadowColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;

        final mid = (center + segmentCenters[i + 1]) / 2;
        Offset ribStart;
        Offset ribEnd;
        if (worm.direction.isHorizontal) {
          ribStart = mid + Offset(0, -segmentRadius * 0.65);
          ribEnd = mid + Offset(0, segmentRadius * 0.65);
        } else {
          ribStart = mid + Offset(-segmentRadius * 0.65, 0);
          ribEnd = mid + Offset(segmentRadius * 0.65, 0);
        }
        canvas.drawLine(ribStart, ribEnd, ribPaint);
      }
    }

    // 3. Draw head details: blushing cheeks, expressive eyes, pupils, mouth
    final headCenter = segmentCenters[0];
    _drawHeadDetails(canvas, worm, headCenter, cellSize, headRadius);
  }

  /// Draws facial features: eyes, pupils, blush, and smile on the worm's head.
  void _drawHeadDetails(
    Canvas canvas,
    Worm worm,
    Offset headCenter,
    double cellSize,
    double headRadius,
  ) {
    // Determine forward unit vector and lateral unit vector
    final fwd = Offset(
      worm.direction.dCol.toDouble(),
      worm.direction.dRow.toDouble(),
    );
    // Lateral vector perpendicular to forward (turned 90 deg clockwise)
    final lat = Offset(-fwd.dy, fwd.dx);

    // 1. Rosy blush cheeks on lateral sides
    final blushPaint = Paint()
      ..color = const Color(0xFFFF4081).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final blushDist = headRadius * 0.72;
    final blushRadius = cellSize * 0.09;
    canvas.drawCircle(headCenter + lat * blushDist, blushRadius, blushPaint);
    canvas.drawCircle(headCenter - lat * blushDist, blushRadius, blushPaint);

    // 2. Expressive Eyes
    final eyeForwardDist = headRadius * 0.36;
    final eyeLateralDist = headRadius * 0.42;
    final eyeRadius = cellSize * 0.13;

    final leftEyeCenter =
        headCenter + (fwd * eyeForwardDist) - (lat * eyeLateralDist);
    final rightEyeCenter =
        headCenter + (fwd * eyeForwardDist) + (lat * eyeLateralDist);

    final eyeWhitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final eyeBorderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw white sclera
    canvas.drawCircle(leftEyeCenter, eyeRadius, eyeWhitePaint);
    canvas.drawCircle(leftEyeCenter, eyeRadius, eyeBorderPaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius, eyeWhitePaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius, eyeBorderPaint);

    // 3. Pupils looking eagerly in movement direction
    final pupilRadius = cellSize * 0.07;
    final pupilOffset = fwd * (eyeRadius * 0.38);

    final pupilCenterLeft = leftEyeCenter + pupilOffset;
    final pupilCenterRight = rightEyeCenter + pupilOffset;

    final pupilPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pupilCenterLeft, pupilRadius, pupilPaint);
    canvas.drawCircle(pupilCenterRight, pupilRadius, pupilPaint);

    // 4. Specular glints in pupils (makes them alive!)
    final glintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final glintRadius = cellSize * 0.025;
    final glintOffset = Offset(-pupilRadius * 0.35, -pupilRadius * 0.35);

    canvas.drawCircle(pupilCenterLeft + glintOffset, glintRadius, glintPaint);
    canvas.drawCircle(pupilCenterRight + glintOffset, glintRadius, glintPaint);

    // 5. Friendly smile mouth
    final mouthCenter = headCenter + fwd * (headRadius * 0.68);
    final mouthPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, cellSize * 0.035)
      ..strokeCap = StrokeCap.round;

    final mouthHalfWidth = headRadius * 0.22;
    canvas.drawLine(
      mouthCenter - lat * mouthHalfWidth,
      mouthCenter + lat * mouthHalfWidth,
      mouthPaint,
    );
  }

  /// Draws blocked warning visuals: dotted trajectory and warning badge.
  void _drawBlockedWarning(Canvas canvas, Worm worm, double cellSize) {
    final path = engine.getEscapePath(worm);
    if (path.isEmpty) return;

    final warningPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw red warning line from worm head along escape path
    final headCenter = Offset(
      (worm.head.col + 0.5) * cellSize,
      (worm.head.row + 0.5) * cellSize,
    );

    final lastCell = path.last;
    final endCenter = Offset(
      (lastCell.col + 0.5) * cellSize,
      (lastCell.row + 0.5) * cellSize,
    );

    canvas.drawLine(headCenter, endCenter, warningPaint);

    // If a specific blocker was identified, draw warning badge at blocking intersection
    if (blockingWormId != null) {
      final blocker = engine.worms[blockingWormId];
      if (blocker != null) {
        // Find cell where blocker intersects path
        for (final pos in path) {
          if (blocker.occupies(pos)) {
            final hitCenter = Offset(
              (pos.col + 0.5) * cellSize,
              (pos.row + 0.5) * cellSize,
            );

            // Red warning circle
            final badgePaint = Paint()
              ..color = const Color(0xFFEF4444)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(hitCenter, cellSize * 0.28, badgePaint);

            // White exclamation mark
            final markPaint = Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..strokeCap = StrokeCap.round;
            canvas.drawLine(
              hitCenter + Offset(0, -cellSize * 0.12),
              hitCenter + Offset(0, cellSize * 0.04),
              markPaint,
            );
            canvas.drawCircle(
              hitCenter + Offset(0, cellSize * 0.11),
              1.2,
              Paint()..color = Colors.white,
            );
            break;
          }
        }
      }
    }
  }

  /// Draws an animated glowing pulse ring and guide arrow around the hinted worm.
  void _drawHintIndicator(Canvas canvas, Worm worm, double cellSize) {
    final glowRadius = (cellSize * 0.46) + (hintPulse * cellSize * 0.12);
    final glowAlpha = ((1.0 - hintPulse) * 0.65).clamp(0.0, 1.0);

    final glowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (final pos in worm.body) {
      final center = Offset(
        (pos.col + 0.5) * cellSize,
        (pos.row + 0.5) * cellSize,
      );
      canvas.drawCircle(center, glowRadius, glowPaint);
    }

    // Draw escape direction guide arrow ahead of head
    final headCenter = Offset(
      (worm.head.col + 0.5) * cellSize,
      (worm.head.row + 0.5) * cellSize,
    );
    final arrowOffset = Offset(
      worm.direction.dCol * (cellSize * 0.65 + hintPulse * 4.0),
      worm.direction.dRow * (cellSize * 0.65 + hintPulse * 4.0),
    );
    final arrowCenter = headCenter + arrowOffset;

    final arrowPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    final fwd = Offset(
      worm.direction.dCol.toDouble(),
      worm.direction.dRow.toDouble(),
    );
    final lat = Offset(-fwd.dy, fwd.dx);
    final arrowSize = cellSize * 0.22;

    final tip = arrowCenter + fwd * arrowSize;
    final leftCorner =
        arrowCenter - fwd * (arrowSize * 0.5) - lat * (arrowSize * 0.6);
    final rightCorner =
        arrowCenter - fwd * (arrowSize * 0.5) + lat * (arrowSize * 0.6);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(leftCorner.dx, leftCorner.dy)
      ..lineTo(rightCorner.dx, rightCorner.dy)
      ..close();

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant WormEscapeBoardPainter oldDelegate) {
    return oldDelegate.engine != engine ||
        oldDelegate.isDark != isDark ||
        oldDelegate.animatingWormId != animatingWormId ||
        oldDelegate.escapeProgress != escapeProgress ||
        oldDelegate.blockedWormId != blockedWormId ||
        oldDelegate.blockingWormId != blockingWormId ||
        oldDelegate.blockedProgress != blockedProgress ||
        oldDelegate.hintWormId != hintWormId ||
        oldDelegate.hintPulse != hintPulse;
  }
}
