import 'dart:convert';
import 'package:flutter/material.dart';

/// Represents a grid coordinate on the board.
@immutable
class GridPosition {
  final int row;
  final int col;

  const GridPosition(this.row, this.col);

  /// Checks if another position is orthogonally adjacent (Manhattan distance == 1).
  bool isOrthogonalTo(GridPosition other) {
    return ((row - other.row).abs() + (col - other.col).abs()) == 1;
  }

  /// Checks if this coordinate is within the board boundary [0, boardSize).
  bool isWithinBounds(int boardSize) {
    return row >= 0 && row < boardSize && col >= 0 && col < boardSize;
  }

  /// Returns orthogonal neighbors within bounds.
  List<GridPosition> orthogonalNeighbors(int boardSize) {
    final list = <GridPosition>[
      GridPosition(row - 1, col),
      GridPosition(row + 1, col),
      GridPosition(row, col - 1),
      GridPosition(row, col + 1),
    ];
    return list.where((p) => p.isWithinBounds(boardSize)).toList();
  }

  Map<String, dynamic> toMap() => {'row': row, 'col': col};

  factory GridPosition.fromMap(Map<String, dynamic> map) {
    return GridPosition(map['row'] as int? ?? 0, map['col'] as int? ?? 0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ (col.hashCode << 16);

  @override
  String toString() => 'GridPosition($row, $col)';
}

/// A matching emoji pair with two fixed endpoints.
@immutable
class EmojiPair {
  final String id;
  final String emoji;
  final int colorValue;
  final GridPosition endpointA;
  final GridPosition endpointB;

  const EmojiPair({
    required this.id,
    required this.emoji,
    required this.colorValue,
    required this.endpointA,
    required this.endpointB,
  });

  Color get color => Color(colorValue);

  bool hasEndpoint(GridPosition pos) => pos == endpointA || pos == endpointB;

  GridPosition otherEndpoint(GridPosition pos) {
    if (pos == endpointA) return endpointB;
    if (pos == endpointB) return endpointA;
    throw ArgumentError('$pos is not an endpoint of pair $id');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'emoji': emoji,
    'colorValue': colorValue,
    'endpointA': endpointA.toMap(),
    'endpointB': endpointB.toMap(),
  };

  factory EmojiPair.fromMap(Map<String, dynamic> map) {
    return EmojiPair(
      id: map['id'] as String,
      emoji: map['emoji'] as String,
      colorValue: map['colorValue'] as int,
      endpointA: GridPosition.fromMap(map['endpointA'] as Map<String, dynamic>),
      endpointB: GridPosition.fromMap(map['endpointB'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmojiPair && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EmojiPair($id, $emoji)';
}

/// A continuous path drawn on the grid for a specific emoji pair.
@immutable
class EmojiPath {
  final String pairId;
  final List<GridPosition> points;

  const EmojiPath({required this.pairId, required this.points});

  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;
  int get length => points.length;

  GridPosition? get head => points.isNotEmpty ? points.last : null;
  GridPosition? get start => points.isNotEmpty ? points.first : null;

  bool contains(GridPosition pos) => points.contains(pos);

  /// A path is complete when it starts at one endpoint and terminates at the other.
  bool isComplete(EmojiPair pair) {
    if (points.length < 2) return false;
    final first = points.first;
    final last = points.last;
    return (first == pair.endpointA && last == pair.endpointB) ||
        (first == pair.endpointB && last == pair.endpointA);
  }

  EmojiPath append(GridPosition pos) {
    return EmojiPath(pairId: pairId, points: [...points, pos]);
  }

  EmojiPath removeLast() {
    if (points.isEmpty) return this;
    return EmojiPath(
      pairId: pairId,
      points: points.sublist(0, points.length - 1),
    );
  }

  EmojiPath trimTo(GridPosition pos) {
    final idx = points.indexOf(pos);
    if (idx == -1) return this;
    return EmojiPath(pairId: pairId, points: points.sublist(0, idx + 1));
  }

  Map<String, dynamic> toMap() => {
    'pairId': pairId,
    'points': points.map((p) => p.toMap()).toList(),
  };

  factory EmojiPath.fromMap(Map<String, dynamic> map) {
    final rawPoints = map['points'] as List<dynamic>? ?? [];
    return EmojiPath(
      pairId: map['pairId'] as String,
      points: rawPoints
          .map((p) => GridPosition.fromMap(p as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmojiPath &&
          runtimeType == other.runtimeType &&
          pairId == other.pairId &&
          _listEquals(points, other.points);

  @override
  int get hashCode => pairId.hashCode ^ Object.hashAll(points);

  static bool _listEquals(List<GridPosition> a, List<GridPosition> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Difficulty settings.
enum EmojiConnectDifficulty {
  easy(5, 'Easy', '5×5 Grid', '3–4 Pairs'),
  medium(6, 'Medium', '6×6 Grid', '5–6 Pairs'),
  hard(8, 'Hard', '8×8 Grid', '7–9 Pairs');

  final int boardSize;
  final String displayName;
  final String gridSizeLabel;
  final String pairsLabel;

  const EmojiConnectDifficulty(
    this.boardSize,
    this.displayName,
    this.gridSizeLabel,
    this.pairsLabel,
  );
}

/// A level definition containing pairs and a certified reference solution.
@immutable
class EmojiConnectLevel {
  final int id;
  final EmojiConnectDifficulty difficulty;
  final int boardSize;
  final List<EmojiPair> pairs;
  final Map<String, List<GridPosition>> referenceSolution;

  const EmojiConnectLevel({
    required this.id,
    required this.difficulty,
    required this.boardSize,
    required this.pairs,
    required this.referenceSolution,
  });

  EmojiPair? getPairById(String pairId) {
    for (final p in pairs) {
      if (p.id == pairId) return p;
    }
    return null;
  }

  EmojiPair? getPairAtEndpoint(GridPosition pos) {
    for (final p in pairs) {
      if (p.hasEndpoint(pos)) return p;
    }
    return null;
  }

  bool isEndpoint(GridPosition pos) => getPairAtEndpoint(pos) != null;
}

/// Model for restoring an in-progress game.
@immutable
class EmojiConnectSavedSession {
  final EmojiConnectDifficulty difficulty;
  final int levelId;
  final Map<String, List<GridPosition>> paths;
  final int elapsedSeconds;
  final int movesCount;

  const EmojiConnectSavedSession({
    required this.difficulty,
    required this.levelId,
    required this.paths,
    required this.elapsedSeconds,
    required this.movesCount,
  });

  Map<String, dynamic> toMap() => {
    'difficulty': difficulty.name,
    'levelId': levelId,
    'paths': paths.map((k, v) => MapEntry(k, v.map((p) => p.toMap()).toList())),
    'elapsedSeconds': elapsedSeconds,
    'movesCount': movesCount,
  };

  String toJson() => jsonEncode(toMap());

  factory EmojiConnectSavedSession.fromMap(Map<String, dynamic> map) {
    final diffName = map['difficulty'] as String? ?? 'easy';
    final difficulty = EmojiConnectDifficulty.values.firstWhere(
      (d) => d.name == diffName,
      orElse: () => EmojiConnectDifficulty.easy,
    );

    final rawPaths = map['paths'] as Map<String, dynamic>? ?? {};
    final paths = <String, List<GridPosition>>{};
    rawPaths.forEach((k, v) {
      if (v is List) {
        paths[k] = v
            .map((item) => GridPosition.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    });

    return EmojiConnectSavedSession(
      difficulty: difficulty,
      levelId: map['levelId'] as int? ?? 1,
      paths: paths,
      elapsedSeconds: map['elapsedSeconds'] as int? ?? 0,
      movesCount: map['movesCount'] as int? ?? 0,
    );
  }

  factory EmojiConnectSavedSession.fromJson(String source) =>
      EmojiConnectSavedSession.fromMap(
        jsonDecode(source) as Map<String, dynamic>,
      );
}
