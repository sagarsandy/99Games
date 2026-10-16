import 'package:flutter/material.dart';

/// Represents a 0-indexed cell coordinate on the board.
@immutable
class GridPosition {
  final int row;
  final int col;

  const GridPosition(this.row, this.col);

  GridPosition operator +(GridPosition other) =>
      GridPosition(row + other.row, col + other.col);

  GridPosition operator -(GridPosition other) =>
      GridPosition(row - other.row, col - other.col);

  bool isOrthogonalTo(GridPosition other) {
    final dr = (row - other.row).abs();
    final dc = (col - other.col).abs();
    return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row, $col)';

  Map<String, dynamic> toJson() => {'row': row, 'col': col};

  factory GridPosition.fromJson(Map<String, dynamic> json) =>
      GridPosition(json['row'] as int, json['col'] as int);
}

/// Movement direction for a worm.
enum WormDirection {
  up(-1, 0, '↑'),
  down(1, 0, '↓'),
  left(0, -1, '←'),
  right(0, 1, '→');

  final int dRow;
  final int dCol;
  final String arrow;

  const WormDirection(this.dRow, this.dCol, this.arrow);

  GridPosition get delta => GridPosition(dRow, dCol);

  WormDirection get opposite {
    switch (this) {
      case WormDirection.up:
        return WormDirection.down;
      case WormDirection.down:
        return WormDirection.up;
      case WormDirection.left:
        return WormDirection.right;
      case WormDirection.right:
        return WormDirection.left;
    }
  }

  bool get isVertical => this == WormDirection.up || this == WormDirection.down;
  bool get isHorizontal =>
      this == WormDirection.left || this == WormDirection.right;
}

/// Lifecycle status of a worm.
enum WormStatus { active, escaping, escaped }

/// Model for a segmented worm.
///
/// **Head and Body Convention**:
/// - `body[0]` is always the **HEAD** of the worm.
/// - `body.last` is always the **TAIL** of the worm.
/// - `direction` specifies the forward movement vector pointing directly out from the head.
/// - Worm body cells form a contiguous straight line along the grid.
/// - In the forward escape path, the worm advances cell by cell in `direction.delta` from `body[0]`.
@immutable
class Worm {
  final String id;
  final List<GridPosition> body;
  final WormDirection direction;
  final int colorIndex;
  final WormStatus status;

  const Worm({
    required this.id,
    required this.body,
    required this.direction,
    required this.colorIndex,
    this.status = WormStatus.active,
  });

  GridPosition get head => body.first;
  GridPosition get tail => body.last;
  int get length => body.length;

  bool get isActive => status == WormStatus.active;
  bool get isEscaping => status == WormStatus.escaping;
  bool get isEscaped => status == WormStatus.escaped;

  bool occupies(GridPosition pos) => body.contains(pos);

  Worm copyWith({
    String? id,
    List<GridPosition>? body,
    WormDirection? direction,
    int? colorIndex,
    WormStatus? status,
  }) {
    return Worm(
      id: id ?? this.id,
      body: body ?? this.body,
      direction: direction ?? this.direction,
      colorIndex: colorIndex ?? this.colorIndex,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'body': body.map((p) => p.toJson()).toList(),
    'direction': direction.name,
    'colorIndex': colorIndex,
    'status': status.name,
  };

  factory Worm.fromJson(Map<String, dynamic> json) => Worm(
    id: json['id'] as String,
    body: (json['body'] as List<dynamic>)
        .map((p) => GridPosition.fromJson(p as Map<String, dynamic>))
        .toList(),
    direction: WormDirection.values.byName(json['direction'] as String),
    colorIndex: json['colorIndex'] as int,
    status: WormStatus.values.byName(json['status'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Worm &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          direction == other.direction &&
          colorIndex == other.colorIndex &&
          status == other.status &&
          _listEquals(body, other.body);

  static bool _listEquals(List<GridPosition> a, List<GridPosition> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(id, direction, colorIndex, status, Object.hashAll(body));
}

/// Difficulty tiers for Worm Escape.
enum WormEscapeDifficulty {
  easy('Easy', 6),
  medium('Medium', 8),
  hard('Hard', 10);

  final String displayName;
  final int boardSize;

  const WormEscapeDifficulty(this.displayName, this.boardSize);
}

/// Curated palette of worm colors.
class WormColors {
  WormColors._();

  static const List<Color> palette = [
    Color(0xFF10B981), // 0: Emerald Green
    Color(0xFF0EA5E9), // 1: Ocean Blue
    Color(0xFFF43F5E), // 2: Coral Rose
    Color(0xFFF59E0B), // 3: Amber Orange
    Color(0xFF8B5CF6), // 4: Violet Purple
    Color(0xFFEC4899), // 5: Bubblegum Pink
    Color(0xFF14B8A6), // 6: Teal Mint
    Color(0xFF6366F1), // 7: Indigo Blue
    Color(0xFF84CC16), // 8: Lime Green
    Color(0xFFFF6B4A), // 9: Warm Tangerine
  ];

  static Color getColor(int index) => palette[index % palette.length];

  static Color getHighlightColor(int index) {
    final c = getColor(index);
    return HSLColor.fromColor(c)
        .withLightness((HSLColor.fromColor(c).lightness + 0.18).clamp(0.0, 1.0))
        .toColor();
  }

  static Color getShadowColor(int index) {
    final c = getColor(index);
    return HSLColor.fromColor(c)
        .withLightness((HSLColor.fromColor(c).lightness - 0.22).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Definition of a curated Worm Escape level.
@immutable
class WormEscapeLevel {
  final String id;
  final WormEscapeDifficulty difficulty;
  final int levelNumber;
  final int boardSize;
  final List<Worm> worms;
  final List<String> referenceSolution;

  const WormEscapeLevel({
    required this.id,
    required this.difficulty,
    required this.levelNumber,
    required this.boardSize,
    required this.worms,
    required this.referenceSolution,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'difficulty': difficulty.name,
    'levelNumber': levelNumber,
    'boardSize': boardSize,
    'worms': worms.map((w) => w.toJson()).toList(),
    'referenceSolution': referenceSolution,
  };

  factory WormEscapeLevel.fromJson(Map<String, dynamic> json) =>
      WormEscapeLevel(
        id: json['id'] as String,
        difficulty: WormEscapeDifficulty.values.byName(
          json['difficulty'] as String,
        ),
        levelNumber: json['levelNumber'] as int,
        boardSize: json['boardSize'] as int,
        worms: (json['worms'] as List<dynamic>)
            .map((w) => Worm.fromJson(w as Map<String, dynamic>))
            .toList(),
        referenceSolution: (json['referenceSolution'] as List<dynamic>)
            .cast<String>(),
      );
}
