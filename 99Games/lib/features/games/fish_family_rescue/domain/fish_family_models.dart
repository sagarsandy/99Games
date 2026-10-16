import 'package:flutter/material.dart';

/// Decorative pattern variations for cartoon fish.
enum FishPatternType { stripes, spots, bellyGrad, dualTone, scales, finsGlow }

/// Tail fin silhouette shapes.
enum FishTailStyle { rounded, forked, fan, heart }

/// Facial expression variations for cute cartoon fish.
enum FishExpression { happy, cute, curious, wink }

/// Definition of a fish species with distinctive colors, pattern, and tail shape.
class FishSpecies {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final FishPatternType patternType;
  final FishTailStyle tailStyle;

  const FishSpecies({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.patternType,
    required this.tailStyle,
  });

  /// Palette of 6 distinct, vibrant species with cute cartoon color schemes.
  static const List<FishSpecies> allSpecies = [
    FishSpecies(
      id: 'clownfish',
      name: 'Clownfish',
      primaryColor: Color(0xFFFF7A00),
      secondaryColor: Color(0xFFFFFFFF),
      accentColor: Color(0xFF262626),
      patternType: FishPatternType.stripes,
      tailStyle: FishTailStyle.rounded,
    ),
    FishSpecies(
      id: 'blue_tang',
      name: 'Blue Tang',
      primaryColor: Color(0xFF2563EB),
      secondaryColor: Color(0xFF1E293B),
      accentColor: Color(0xFFFBBF24),
      patternType: FishPatternType.dualTone,
      tailStyle: FishTailStyle.fan,
    ),
    FishSpecies(
      id: 'yellow_tang',
      name: 'Yellow Tang',
      primaryColor: Color(0xFFFACC15),
      secondaryColor: Color(0xFFFEF08A),
      accentColor: Color(0xFFD97706),
      patternType: FishPatternType.bellyGrad,
      tailStyle: FishTailStyle.heart,
    ),
    FishSpecies(
      id: 'royal_gramma',
      name: 'Royal Gramma',
      primaryColor: Color(0xFF9333EA),
      secondaryColor: Color(0xFFF59E0B),
      accentColor: Color(0xFFC084FC),
      patternType: FishPatternType.dualTone,
      tailStyle: FishTailStyle.forked,
    ),
    FishSpecies(
      id: 'green_chromis',
      name: 'Green Chromis',
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFFA7F3D0),
      accentColor: Color(0xFF047857),
      patternType: FishPatternType.spots,
      tailStyle: FishTailStyle.fan,
    ),
    FishSpecies(
      id: 'pink_anthias',
      name: 'Pink Anthias',
      primaryColor: Color(0xFFEC4899),
      secondaryColor: Color(0xFFFCE7F3),
      accentColor: Color(0xFFF59E0B),
      patternType: FishPatternType.stripes,
      tailStyle: FishTailStyle.rounded,
    ),
  ];

  static FishSpecies getById(String id) {
    return allSpecies.firstWhere(
      (s) => s.id == id,
      orElse: () => allSpecies.first,
    );
  }
}

/// Representation of an individual fish in a tank.
@immutable
class Fish {
  final String id;
  final String speciesId;
  final FishExpression expression;

  const Fish({
    required this.id,
    required this.speciesId,
    this.expression = FishExpression.happy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'speciesId': speciesId,
    'expression': expression.name,
  };

  factory Fish.fromJson(Map<String, dynamic> json) {
    return Fish(
      id: json['id'] as String,
      speciesId: json['speciesId'] as String,
      expression: FishExpression.values.firstWhere(
        (e) => e.name == json['expression'],
        orElse: () => FishExpression.happy,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fish && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Fish($id, $speciesId)';
}

/// Reason for a move validation failure.
enum MoveFailureReason {
  sameTank,
  sourceEmpty,
  destinationFull,
  speciesMismatch,
}

/// Result of validating a proposed move between tanks.
class MoveValidationResult {
  final bool isValid;
  final MoveFailureReason? failureReason;
  final String? errorMessage;

  const MoveValidationResult.valid()
    : isValid = true,
      failureReason = null,
      errorMessage = null;

  const MoveValidationResult.invalid(this.failureReason, this.errorMessage)
    : isValid = false;
}

/// Representation of a single fish tank.
///
/// Fish inside are ordered from bottom to top: `fish.first` is at the bottom,
/// and `fish.last` is the topmost fish (the only one that can be moved).
@immutable
class FishTank {
  final int id;
  final int capacity;
  final List<Fish> fish;

  const FishTank({
    required this.id,
    required this.capacity,
    required this.fish,
  });

  bool get isFull => fish.length >= capacity;
  bool get isEmpty => fish.isEmpty;
  Fish? get topFish => fish.isNotEmpty ? fish.last : null;
  int get freeCapacity => capacity - fish.length;

  /// Whether all fish in this tank belong to the same species (or tank is empty).
  bool get isPure =>
      fish.isEmpty || fish.every((f) => f.speciesId == fish.first.speciesId);

  /// Whether the tank is filled to capacity with a single species.
  bool get isComplete => fish.length == capacity && isPure;

  /// Validates whether [movingFish] can be placed into this tank.
  bool canAdd(Fish movingFish) {
    if (isFull) return false;
    if (isEmpty) return true;
    return topFish!.speciesId == movingFish.speciesId;
  }

  FishTank copyWith({int? id, int? capacity, List<Fish>? fish}) {
    return FishTank(
      id: id ?? this.id,
      capacity: capacity ?? this.capacity,
      fish: fish ?? List<Fish>.unmodifiable(this.fish),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'capacity': capacity,
    'fish': fish.map((f) => f.toJson()).toList(),
  };

  factory FishTank.fromJson(Map<String, dynamic> json) {
    return FishTank(
      id: json['id'] as int,
      capacity: json['capacity'] as int,
      fish: (json['fish'] as List<dynamic>)
          .map((f) => Fish.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FishTank &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          capacity == other.capacity &&
          _listEquals(fish, other.fish);

  static bool _listEquals(List<Fish> a, List<Fish> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, capacity, Object.hashAll(fish));

  @override
  String toString() => 'FishTank($id, cap: $capacity, fish: ${fish.length})';
}

/// Record of a completed fish move for history, undo, and replaying.
@immutable
class FishMove {
  final int fromTankId;
  final int toTankId;
  final Fish fish;

  const FishMove({
    required this.fromTankId,
    required this.toTankId,
    required this.fish,
  });

  Map<String, dynamic> toJson() => {
    'fromTankId': fromTankId,
    'toTankId': toTankId,
    'fish': fish.toJson(),
  };

  factory FishMove.fromJson(Map<String, dynamic> json) {
    return FishMove(
      fromTankId: json['fromTankId'] as int,
      toTankId: json['toTankId'] as int,
      fish: Fish.fromJson(json['fish'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() => 'Move(${fish.speciesId} from $fromTankId to $toTankId)';
}

/// Level specification with initial layout and difficulty targets.
@immutable
class FishFamilyLevel {
  final int levelNumber;
  final String title;
  final String description;
  final int capacity;
  final List<FishTank> tanks;
  final int targetMoves;

  const FishFamilyLevel({
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.capacity,
    required this.tanks,
    required this.targetMoves,
  });

  int get totalTanks => tanks.length;
  int get totalFish => tanks.fold(0, (sum, t) => sum + t.fish.length);

  Set<String> get speciesInLevel {
    final species = <String>{};
    for (final t in tanks) {
      for (final f in t.fish) {
        species.add(f.speciesId);
      }
    }
    return species;
  }
}

/// Representation of an active in-flight move animation between two tanks.
@immutable
class PendingFishMove {
  final int fromTankId;
  final int toTankId;
  final Fish fish;
  final int sequence;

  const PendingFishMove({
    required this.fromTankId,
    required this.toTankId,
    required this.fish,
    required this.sequence,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingFishMove &&
          runtimeType == other.runtimeType &&
          fromTankId == other.fromTankId &&
          toTankId == other.toTankId &&
          fish == other.fish &&
          sequence == other.sequence;

  @override
  int get hashCode => Object.hash(fromTankId, toTankId, fish, sequence);

  @override
  String toString() =>
      'PendingMove(${fish.speciesId} from $fromTankId to $toTankId, seq: $sequence)';
}
