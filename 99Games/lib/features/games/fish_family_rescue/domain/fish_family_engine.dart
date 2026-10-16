import 'fish_family_models.dart';

/// Core domain engine for Fish Family Rescue.
///
/// Validates moves, executes state transitions, handles undo, and evaluates
/// win conditions according to the game specifications.
class FishFamilyEngine {
  const FishFamilyEngine();

  /// Validates whether a move from [fromTankId] to [toTankId] is legal.
  MoveValidationResult validateMove(
    List<FishTank> tanks,
    int fromTankId,
    int toTankId,
  ) {
    if (fromTankId == toTankId) {
      return const MoveValidationResult.invalid(
        MoveFailureReason.sameTank,
        'Cannot move into the same tank',
      );
    }

    final fromIndex = tanks.indexWhere((t) => t.id == fromTankId);
    final toIndex = tanks.indexWhere((t) => t.id == toTankId);

    if (fromIndex == -1 || toIndex == -1) {
      return const MoveValidationResult.invalid(
        MoveFailureReason.sourceEmpty,
        'Invalid tank selected',
      );
    }

    final sourceTank = tanks[fromIndex];
    final destTank = tanks[toIndex];

    if (sourceTank.isEmpty) {
      return const MoveValidationResult.invalid(
        MoveFailureReason.sourceEmpty,
        'Selected tank has no fish',
      );
    }

    if (destTank.isFull) {
      return const MoveValidationResult.invalid(
        MoveFailureReason.destinationFull,
        'Tank is full',
      );
    }

    final movingFish = sourceTank.topFish!;

    // Move is valid if destination is empty or its topmost fish is the same species.
    if (!destTank.isEmpty &&
        destTank.topFish!.speciesId != movingFish.speciesId) {
      return const MoveValidationResult.invalid(
        MoveFailureReason.speciesMismatch,
        'Match the fish species',
      );
    }

    return const MoveValidationResult.valid();
  }

  /// Executes a move, returning the new list of tanks and the recorded move.
  ///
  /// Throws an [ArgumentError] if the move is invalid.
  ({List<FishTank> tanks, FishMove move}) executeMove(
    List<FishTank> tanks,
    int fromTankId,
    int toTankId,
  ) {
    final validation = validateMove(tanks, fromTankId, toTankId);
    if (!validation.isValid) {
      throw ArgumentError(validation.errorMessage ?? 'Invalid move');
    }

    final fromIndex = tanks.indexWhere((t) => t.id == fromTankId);
    final toIndex = tanks.indexWhere((t) => t.id == toTankId);

    final source = tanks[fromIndex];
    final dest = tanks[toIndex];

    final movingFish = source.topFish!;
    final newSourceFish = List<Fish>.of(source.fish)..removeLast();
    final newDestFish = List<Fish>.of(dest.fish)..add(movingFish);

    final newTanks = List<FishTank>.of(tanks);
    newTanks[fromIndex] = source.copyWith(fish: newSourceFish);
    newTanks[toIndex] = dest.copyWith(fish: newDestFish);

    final move = FishMove(
      fromTankId: fromTankId,
      toTankId: toTankId,
      fish: movingFish,
    );

    return (tanks: List.unmodifiable(newTanks), move: move);
  }

  /// Reverses [move] and returns the previous tank state.
  List<FishTank> undoMove(List<FishTank> tanks, FishMove move) {
    final fromIndex = tanks.indexWhere((t) => t.id == move.fromTankId);
    final toIndex = tanks.indexWhere((t) => t.id == move.toTankId);

    if (fromIndex == -1 || toIndex == -1) return tanks;

    final source = tanks[fromIndex];
    final dest = tanks[toIndex];

    if (dest.isEmpty || dest.topFish!.id != move.fish.id) {
      // Inconsistent state for undo
      return tanks;
    }

    final newDestFish = List<Fish>.of(dest.fish)..removeLast();
    final newSourceFish = List<Fish>.of(source.fish)..add(move.fish);

    final newTanks = List<FishTank>.of(tanks);
    newTanks[fromIndex] = source.copyWith(fish: newSourceFish);
    newTanks[toIndex] = dest.copyWith(fish: newDestFish);

    return List.unmodifiable(newTanks);
  }

  /// Authoritative single source of truth method to determine whether [tanks]
  /// satisfies the puzzle completion objective for [level].
  ///
  /// A valid completed board must satisfy:
  /// 1. Every fish originally belonging to the level is accounted for (stable fish IDs).
  /// 2. No fish has been duplicated or lost.
  /// 3. Every non-empty tank contains fish of exactly one species (`isPure`).
  /// 4. All required species are fully sorted and grouped into family tanks without
  ///    being split across multiple tanks.
  /// 5. Species counts on board match the original level definition.
  /// 6. Every tank remains within its capacity.
  /// 7. Empty spare tanks are allowed; tanks do not need to be full.
  bool isLevelComplete(List<FishTank> tanks, FishFamilyLevel level) {
    int totalCount = 0;
    final seenFishIds = <String>{};
    final speciesToTankIds = <String, Set<int>>{};
    final speciesCounts = <String, int>{};

    for (final tank in tanks) {
      if (tank.isEmpty) continue;

      // 6. Tank capacity constraint
      if (tank.fish.length > tank.capacity) {
        return false;
      }

      // 3. Every non-empty tank must contain exactly one species
      if (!tank.isPure) {
        return false;
      }

      final speciesId = tank.topFish!.speciesId;
      speciesToTankIds.putIfAbsent(speciesId, () => <int>{}).add(tank.id);

      for (final fish in tank.fish) {
        // 2. No fish duplicated
        if (!seenFishIds.add(fish.id)) {
          return false;
        }
        speciesCounts[fish.speciesId] =
            (speciesCounts[fish.speciesId] ?? 0) + 1;
        totalCount++;
      }
    }

    // 1 & 2. Total count must match level definition
    if (totalCount != level.totalFish) {
      return false;
    }

    // 1. All original fish accounted for
    final originalFishIds = level.tanks
        .expand((t) => t.fish)
        .map((f) => f.id)
        .toSet();
    if (seenFishIds.length != originalFishIds.length ||
        !seenFishIds.containsAll(originalFishIds)) {
      return false;
    }

    // 5. Expected species counts match original level definition
    final expectedCounts = <String, int>{};
    for (final t in level.tanks) {
      for (final f in t.fish) {
        expectedCounts[f.speciesId] = (expectedCounts[f.speciesId] ?? 0) + 1;
      }
    }
    for (final entry in expectedCounts.entries) {
      if (speciesCounts[entry.key] != entry.value) {
        return false;
      }
    }

    // 4. All required species are fully sorted and grouped together.
    for (final sp in level.speciesInLevel) {
      final tankIds = speciesToTankIds[sp];
      if (tankIds == null || tankIds.isEmpty) {
        return false; // Missing required species
      }
      final count = expectedCounts[sp] ?? 0;
      final maxAllowedTanks = (count / level.capacity).ceil();
      if (tankIds.length > maxAllowedTanks) {
        return false; // Species split across multiple tanks!
      }
    }

    return true;
  }

  /// Evaluates whether the current board state satisfies the win condition.
  ///
  /// If [level] is provided, delegates to [isLevelComplete].
  /// Otherwise, validates that:
  /// 1. Every non-empty tank is pure (`tank.isPure`).
  /// 2. Tanks respect their capacity.
  /// 3. No duplicate fish IDs.
  /// 4. No species family is split across multiple tanks.
  /// 5. Counts match optional [expectedTotalFish] and [expectedSpecies].
  bool checkWin(
    List<FishTank> tanks, {
    FishFamilyLevel? level,
    int? expectedTotalFish,
    Set<String>? expectedSpecies,
  }) {
    if (level != null) {
      return isLevelComplete(tanks, level);
    }

    int totalCount = 0;
    final seenFishIds = <String>{};
    final seenSpecies = <String>{};
    final speciesToTankIds = <String, Set<int>>{};
    final speciesCounts = <String, int>{};

    for (final tank in tanks) {
      if (tank.isEmpty) continue;

      if (tank.fish.length > tank.capacity) {
        return false;
      }

      if (!tank.isPure) {
        return false;
      }

      final speciesId = tank.topFish!.speciesId;
      speciesToTankIds.putIfAbsent(speciesId, () => <int>{}).add(tank.id);

      for (final fish in tank.fish) {
        if (!seenFishIds.add(fish.id)) {
          return false;
        }
        seenSpecies.add(fish.speciesId);
        speciesCounts[fish.speciesId] =
            (speciesCounts[fish.speciesId] ?? 0) + 1;
        totalCount++;
      }
    }

    // Must have at least one fish
    if (totalCount == 0) return false;

    // Enforce that each species is grouped together
    for (final entry in speciesToTankIds.entries) {
      final count = speciesCounts[entry.key] ?? 0;
      // Default standard capacity fallback is 4 if tanks vary
      final firstTankWithSpecies = tanks.firstWhere(
        (t) => entry.value.contains(t.id),
      );
      final cap = firstTankWithSpecies.capacity;
      final maxAllowed = (count / cap).ceil();
      if (entry.value.length > maxAllowed) {
        return false; // Family split across multiple tanks
      }
    }

    if (expectedTotalFish != null && totalCount != expectedTotalFish) {
      return false;
    }

    if (expectedSpecies != null && !seenSpecies.containsAll(expectedSpecies)) {
      return false;
    }

    return true;
  }

  /// Verifies structural level integrity before play or solving.
  bool validateLevelIntegrity(FishFamilyLevel level) {
    final seenFishIds = <String>{};

    for (final tank in level.tanks) {
      if (tank.fish.length > tank.capacity) {
        return false;
      }
      for (final fish in tank.fish) {
        if (!seenFishIds.add(fish.id)) {
          return false;
        }
      }
    }

    return seenFishIds.isNotEmpty;
  }
}
