import 'dart:ui';
import 'package:equatable/equatable.dart';

/// Types of objects that fall from the top of the playfield.
enum FruitType {
  apple(points: 10, displayName: 'Apple', isHazard: false, isGolden: false),
  orange(points: 10, displayName: 'Orange', isHazard: false, isGolden: false),
  banana(points: 10, displayName: 'Banana', isHazard: false, isGolden: false),
  strawberry(
    points: 10,
    displayName: 'Strawberry',
    isHazard: false,
    isGolden: false,
  ),
  grapes(points: 10, displayName: 'Grapes', isHazard: false, isGolden: false),
  golden(
    points: 50,
    displayName: 'Golden Fruit',
    isHazard: false,
    isGolden: true,
  ),
  bomb(points: 0, displayName: 'Bomb', isHazard: true, isGolden: false);

  final int points;
  final String displayName;
  final bool isHazard;
  final bool isGolden;

  const FruitType({
    required this.points,
    required this.displayName,
    required this.isHazard,
    required this.isGolden,
  });
}

/// Represents an active falling fruit or bomb in normalized coordinates (0.0 to 1.0).
class FallingItem extends Equatable {
  final int id;
  final FruitType type;
  final double x; // Horizontal center (0.0 to 1.0)
  final double y; // Vertical center (0.0 = top, 1.0 = bottom)
  final double speed; // Normalized distance traveled per second
  final double radius; // Normalized collision radius
  final double rotation; // Radians
  final double rotationSpeed; // Radians per second
  final bool isCollected;

  const FallingItem({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.speed,
    this.radius = 0.045,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
    this.isCollected = false,
  });

  /// Diameter of the falling object in normalized coordinates.
  double get size => radius * 2;

  FallingItem copyWith({
    int? id,
    FruitType? type,
    double? x,
    double? y,
    double? speed,
    double? radius,
    double? rotation,
    double? rotationSpeed,
    bool? isCollected,
  }) {
    return FallingItem(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      speed: speed ?? this.speed,
      radius: radius ?? this.radius,
      rotation: rotation ?? this.rotation,
      rotationSpeed: rotationSpeed ?? this.rotationSpeed,
      isCollected: isCollected ?? this.isCollected,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    x,
    y,
    speed,
    radius,
    rotation,
    rotationSpeed,
    isCollected,
  ];
}

/// Basket controlled by the player at the bottom of the play area.
class BasketModel extends Equatable {
  final double x; // Normalized horizontal center (0.0 to 1.0)
  final double width; // Normalized width (e.g. 0.24)
  final double height; // Normalized height (e.g. 0.08)
  final double y; // Normalized top edge of basket

  const BasketModel({
    this.x = 0.5,
    this.width = 0.24,
    this.height = 0.08,
    this.y = 0.86,
  });

  double get halfWidth => width / 2;
  double get minX => halfWidth;
  double get maxX => 1.0 - halfWidth;
  double get left => (x - halfWidth).clamp(0.0, 1.0);
  double get right => (x + halfWidth).clamp(0.0, 1.0);

  BasketModel moveTo(double newX) {
    return BasketModel(
      x: newX.clamp(minX, maxX),
      width: width,
      height: height,
      y: y,
    );
  }

  /// Clamps position within horizontal bounds [minX, maxX].
  BasketModel clampPosition(double newX) => moveTo(newX);

  BasketModel nudge(double delta) {
    return moveTo(x + delta);
  }

  @override
  List<Object?> get props => [x, width, height, y];
}

/// Lightweight visual burst particle created when catching fruit or hitting a bomb.
class FruitCatchParticle extends Equatable {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;
  final double age; // In seconds
  final double maxLife; // In seconds
  final bool isStar;

  const FruitCatchParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    this.age = 0.0,
    this.maxLife = 0.5,
    this.isStar = false,
  });

  double get progress => (age / maxLife).clamp(0.0, 1.0);
  double get opacity => (1.0 - progress).clamp(0.0, 1.0);
  bool get isExpired => age >= maxLife;

  FruitCatchParticle update(double dt) {
    return FruitCatchParticle(
      x: x + vx * dt,
      y: y + vy * dt,
      vx: vx * 0.96, // Slight friction
      vy: vy + 0.35 * dt, // Mild gravity
      color: color,
      size: size * (1.0 - 0.25 * progress),
      age: age + dt,
      maxLife: maxLife,
      isStar: isStar,
    );
  }

  @override
  List<Object?> get props => [x, y, vx, vy, color, size, age, maxLife, isStar];
}

/// Floating indicator (e.g. +10, +50, -1 Life) displaying brief catch feedback.
class FloatingIndicator extends Equatable {
  final int id;
  final String text;
  final double x;
  final double y;
  final Color color;
  final double age;
  final double maxLife;

  const FloatingIndicator({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    this.age = 0.0,
    this.maxLife = 0.75,
  });

  double get progress => (age / maxLife).clamp(0.0, 1.0);
  double get opacity => (1.0 - (progress * progress)).clamp(0.0, 1.0);
  double get offsetY => -progress * 0.06; // Floats upward
  bool get isExpired => age >= maxLife;

  FloatingIndicator update(double dt) {
    return FloatingIndicator(
      id: id,
      text: text,
      x: x,
      y: y,
      color: color,
      age: age + dt,
      maxLife: maxLife,
    );
  }

  @override
  List<Object?> get props => [id, text, x, y, color, age, maxLife];
}

/// Overall lifecycle status of a Fruit Catcher round.
enum GameStatus { ready, playing, gameOver }
