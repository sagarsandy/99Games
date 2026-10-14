import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents a single tile in the Number Match grid with a stable identity.
@immutable
class NumberMatchTile {
  final int id;
  final int value;
  final bool isCleared;

  const NumberMatchTile({
    required this.id,
    required this.value,
    this.isCleared = false,
  });

  NumberMatchTile copyWith({int? id, int? value, bool? isCleared}) {
    return NumberMatchTile(
      id: id ?? this.id,
      value: value ?? this.value,
      isCleared: isCleared ?? this.isCleared,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'value': value, 'isCleared': isCleared};
  }

  factory NumberMatchTile.fromMap(Map<String, dynamic> map) {
    return NumberMatchTile(
      id: map['id'] as int,
      value: map['value'] as int,
      isCleared: map['isCleared'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumberMatchTile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          isCleared == other.isCleared;

  @override
  int get hashCode => Object.hash(id, value, isCleared);

  @override
  String toString() =>
      'NumberMatchTile(id: $id, value: $value, isCleared: $isCleared)';
}

/// Pair coordinates represented by their indices in the ordered sequence.
@immutable
class NumberMatchPair {
  final int firstIndex;
  final int secondIndex;

  const NumberMatchPair(this.firstIndex, this.secondIndex);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumberMatchPair &&
          runtimeType == other.runtimeType &&
          ((firstIndex == other.firstIndex &&
                  secondIndex == other.secondIndex) ||
              (firstIndex == other.secondIndex &&
                  secondIndex == other.firstIndex));

  @override
  int get hashCode => Object.hash(
    firstIndex < secondIndex ? firstIndex : secondIndex,
    firstIndex < secondIndex ? secondIndex : firstIndex,
  );

  @override
  String toString() => 'NumberMatchPair($firstIndex, $secondIndex)';
}

/// Result of evaluating whether two tiles can be matched.
enum MatchValidationStatus {
  valid,
  sameTile,
  alreadyCleared,
  valuesDoNotMatch,
  blockedPath,
  notConnected,
}

/// Validation details for player feedback.
@immutable
class MatchValidationResult {
  final MatchValidationStatus status;
  final String message;

  const MatchValidationResult({required this.status, required this.message});

  bool get isValid => status == MatchValidationStatus.valid;

  static const MatchValidationResult valid = MatchValidationResult(
    status: MatchValidationStatus.valid,
    message: 'Valid pair matched!',
  );

  static const MatchValidationResult sameTile = MatchValidationResult(
    status: MatchValidationStatus.sameTile,
    message: 'Cannot match a number with itself.',
  );

  static const MatchValidationResult alreadyCleared = MatchValidationResult(
    status: MatchValidationStatus.alreadyCleared,
    message: 'One or both numbers are already cleared.',
  );

  static const MatchValidationResult valuesDoNotMatch = MatchValidationResult(
    status: MatchValidationStatus.valuesDoNotMatch,
    message: 'Numbers must be identical or add up to 10.',
  );

  static const MatchValidationResult blockedPath = MatchValidationResult(
    status: MatchValidationStatus.blockedPath,
    message: 'Path is blocked by another number.',
  );

  static const MatchValidationResult notConnected = MatchValidationResult(
    status: MatchValidationStatus.notConnected,
    message:
        'Numbers are not connected horizontally, vertically, or sequentially.',
  );
}

/// Sealed representation of undoable actions in Number Match.
sealed class NumberMatchAction {
  const NumberMatchAction();

  Map<String, dynamic> toMap();

  factory NumberMatchAction.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    if (type == 'clearPair') {
      return ClearPairAction.fromMap(map);
    } else if (type == 'addNumbers') {
      return AddNumbersAction.fromMap(map);
    }
    throw FormatException('Unknown action type: $type');
  }
}

/// Reversible action representing clearing a pair of tiles.
final class ClearPairAction extends NumberMatchAction {
  final int firstIndex;
  final NumberMatchTile firstTile;
  final int secondIndex;
  final NumberMatchTile secondTile;
  final int pointsAwarded;
  final int rowBonusAwarded;

  const ClearPairAction({
    required this.firstIndex,
    required this.firstTile,
    required this.secondIndex,
    required this.secondTile,
    required this.pointsAwarded,
    this.rowBonusAwarded = 0,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'clearPair',
      'firstIndex': firstIndex,
      'firstTile': firstTile.toMap(),
      'secondIndex': secondIndex,
      'secondTile': secondTile.toMap(),
      'pointsAwarded': pointsAwarded,
      'rowBonusAwarded': rowBonusAwarded,
    };
  }

  factory ClearPairAction.fromMap(Map<String, dynamic> map) {
    return ClearPairAction(
      firstIndex: map['firstIndex'] as int,
      firstTile: NumberMatchTile.fromMap(
        map['firstTile'] as Map<String, dynamic>,
      ),
      secondIndex: map['secondIndex'] as int,
      secondTile: NumberMatchTile.fromMap(
        map['secondTile'] as Map<String, dynamic>,
      ),
      pointsAwarded: map['pointsAwarded'] as int? ?? 10,
      rowBonusAwarded: map['rowBonusAwarded'] as int? ?? 0,
    );
  }
}

/// Reversible action representing the Add Numbers action.
final class AddNumbersAction extends NumberMatchAction {
  final int addedCount;

  const AddNumbersAction({required this.addedCount});

  @override
  Map<String, dynamic> toMap() {
    return {'type': 'addNumbers', 'addedCount': addedCount};
  }

  factory AddNumbersAction.fromMap(Map<String, dynamic> map) {
    return AddNumbersAction(addedCount: map['addedCount'] as int);
  }
}

/// Game state lifecycle status.
enum NumberMatchGameStatus {
  inProgress,
  won;

  bool get isWon => this == NumberMatchGameStatus.won;
}

/// Persistent statistics for Number Match.
@immutable
class NumberMatchStats {
  final int gamesStarted;
  final int gamesWon;
  final int bestScore;
  final int totalPairsCleared;

  const NumberMatchStats({
    this.gamesStarted = 0,
    this.gamesWon = 0,
    this.bestScore = 0,
    this.totalPairsCleared = 0,
  });

  NumberMatchStats copyWith({
    int? gamesStarted,
    int? gamesWon,
    int? bestScore,
    int? totalPairsCleared,
  }) {
    return NumberMatchStats(
      gamesStarted: gamesStarted ?? this.gamesStarted,
      gamesWon: gamesWon ?? this.gamesWon,
      bestScore: bestScore ?? this.bestScore,
      totalPairsCleared: totalPairsCleared ?? this.totalPairsCleared,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gamesStarted': gamesStarted,
      'gamesWon': gamesWon,
      'bestScore': bestScore,
      'totalPairsCleared': totalPairsCleared,
    };
  }

  factory NumberMatchStats.fromMap(Map<String, dynamic> map) {
    return NumberMatchStats(
      gamesStarted: map['gamesStarted'] as int? ?? 0,
      gamesWon: map['gamesWon'] as int? ?? 0,
      bestScore: map['bestScore'] as int? ?? 0,
      totalPairsCleared: map['totalPairsCleared'] as int? ?? 0,
    );
  }
}

/// Serialized model for in-progress session persistence.
@immutable
class NumberMatchSavedSession {
  final List<NumberMatchTile> tiles;
  final int score;
  final int pairsCleared;
  final int elapsedSeconds;
  final List<NumberMatchAction> actionHistory;
  final NumberMatchGameStatus status;

  const NumberMatchSavedSession({
    required this.tiles,
    required this.score,
    required this.pairsCleared,
    required this.elapsedSeconds,
    required this.actionHistory,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': 1,
      'tiles': tiles.map((t) => t.toMap()).toList(),
      'score': score,
      'pairsCleared': pairsCleared,
      'elapsedSeconds': elapsedSeconds,
      'actionHistory': actionHistory.map((a) => a.toMap()).toList(),
      'status': status.name,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory NumberMatchSavedSession.fromMap(Map<String, dynamic> map) {
    final rawTiles = (map['tiles'] as List<dynamic>)
        .map((item) => NumberMatchTile.fromMap(item as Map<String, dynamic>))
        .toList();

    final rawHistory = (map['actionHistory'] as List<dynamic>? ?? const [])
        .map((item) => NumberMatchAction.fromMap(item as Map<String, dynamic>))
        .toList();

    final statusStr = map['status'] as String? ?? 'inProgress';
    final status = NumberMatchGameStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => NumberMatchGameStatus.inProgress,
    );

    return NumberMatchSavedSession(
      tiles: rawTiles,
      score: map['score'] as int? ?? 0,
      pairsCleared: map['pairsCleared'] as int? ?? 0,
      elapsedSeconds: map['elapsedSeconds'] as int? ?? 0,
      actionHistory: rawHistory,
      status: status,
    );
  }

  factory NumberMatchSavedSession.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return NumberMatchSavedSession.fromMap(map);
  }
}
