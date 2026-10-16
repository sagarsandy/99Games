import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/fish_family_models.dart';
import '../painters/fish_painter.dart';

/// Trajectory computation and geometry for a fish swimming between two tanks.
class FishTrajectory {
  final Offset start;
  final Offset end;
  final Offset p1;
  final Offset p2;
  final bool facingRight;
  final double distance;

  const FishTrajectory({
    required this.start,
    required this.end,
    required this.p1,
    required this.p2,
    required this.facingRight,
    required this.distance,
  });

  /// Factory that constructs a smooth cubic Bézier trajectory arcing upward
  /// out of the source tank and descending into the destination slot.
  factory FishTrajectory.calculate({
    required Offset start,
    required Offset end,
    double minBoardY = 12.0,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final facingRight = dx >= 0;

    // Arc peak lifts above the higher of the two points
    final arcLift = (35.0 + (distance * 0.12)).clamp(35.0, 75.0);
    final peakY = math.max(minBoardY, math.min(start.dy, end.dy) - arcLift);

    final p1 = Offset(
      start.dx + (dx * 0.20),
      peakY + (start.dy - peakY) * 0.20,
    );
    final p2 = Offset(end.dx - (dx * 0.20), peakY + (end.dy - peakY) * 0.20);

    return FishTrajectory(
      start: start,
      end: end,
      p1: p1,
      p2: p2,
      facingRight: facingRight,
      distance: distance,
    );
  }

  /// Calculates position at normalized progress [t] in range [0.0 .. 1.0].
  Offset positionAt(double t) {
    final u = 1.0 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    final x =
        (uuu * start.dx) +
        (3 * uu * t * p1.dx) +
        (3 * u * tt * p2.dx) +
        (ttt * end.dx);

    var y =
        (uuu * start.dy) +
        (3 * uu * t * p1.dy) +
        (3 * u * tt * p2.dy) +
        (ttt * end.dy);

    // Subtle natural vertical swimming bob (2 cycles)
    final bob = math.sin(t * 4 * math.pi) * 2.0;
    y += bob;

    return Offset(x, y);
  }

  /// Calculates tangent pitch rotation angle in radians at progress [t].
  double rotationAt(double t) {
    final u = 1.0 - t;
    final tt = t * t;
    final uu = u * u;

    final vx =
        (3 * uu * (p1.dx - start.dx)) +
        (6 * u * t * (p2.dx - p1.dx)) +
        (3 * tt * (end.dx - p2.dx));

    final vy =
        (3 * uu * (p1.dy - start.dy)) +
        (6 * u * t * (p2.dy - p1.dy)) +
        (3 * tt * (end.dy - p2.dy));

    final slopeAngle = math.atan2(vy, vx.abs());
    // Restrain pitch tilt to +/- 20 degrees (0.35 rad) to avoid sudden or extreme flips
    final pitch = slopeAngle.clamp(-0.35, 0.35);
    return facingRight ? pitch : -pitch;
  }

  /// Slight scale expansion during peak jump (+8%) for depth illusion.
  double scaleAt(double t) {
    return 1.0 + (math.sin(t * math.pi) * 0.08);
  }
}

/// Overlay widget rendering the moving fish above the tank glass during flight.
class AnimatedSwimmingFishOverlay extends StatelessWidget {
  final Animation<double> animation;
  final FishTrajectory trajectory;
  final Fish fish;

  const AnimatedSwimmingFishOverlay({
    super.key,
    required this.animation,
    required this.trajectory,
    required this.fish,
  });

  @override
  Widget build(BuildContext context) {
    final t = animation.value;
    final pos = trajectory.positionAt(t);
    final rotation = trajectory.rotationAt(t);
    final scale = trajectory.scaleAt(t);
    final species = FishSpecies.getById(fish.speciesId);

    return Positioned(
      left: pos.dx - 32.0,
      top: pos.dy - 20.0,
      width: 64.0,
      height: 40.0,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(scale, scale, 1.0)
          ..rotateZ(rotation),
        child: CustomPaint(
          painter: FishPainter(
            species: species,
            expression: FishExpression.cute,
            isSelected: false,
            animationProgress: (t * 4.0) % 1.0,
            facingRight: trajectory.facingRight,
          ),
        ),
      ),
    );
  }
}
