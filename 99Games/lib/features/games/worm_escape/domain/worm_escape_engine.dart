import 'package:flutter/foundation.dart';
import 'worm_escape_models.dart';

/// Immutable snapshot used to support multi-step undo.
@immutable
class WormEscapeSnapshot {
  final Map<String, Worm> worms;
  final List<String> escapedWormIds;
  final int movesCount;

  const WormEscapeSnapshot({
    required this.worms,
    required this.escapedWormIds,
    required this.movesCount,
  });
}

/// Pure domain engine containing game rules, collision detection, and state transitions.
@immutable
class WormEscapeEngine {
  final WormEscapeLevel level;
  final Map<String, Worm> worms;
  final List<String> escapedWormIds;
  final List<WormEscapeSnapshot> undoStack;
  final int movesCount;

  const WormEscapeEngine({
    required this.level,
    required this.worms,
    required this.escapedWormIds,
    required this.undoStack,
    required this.movesCount,
  });

  /// Initializes an engine from a [WormEscapeLevel].
  factory WormEscapeEngine.initial(WormEscapeLevel level) {
    final wormMap = <String, Worm>{};
    for (final worm in level.worms) {
      wormMap[worm.id] = worm.copyWith(status: WormStatus.active);
    }
    return WormEscapeEngine(
      level: level,
      worms: Map.unmodifiable(wormMap),
      escapedWormIds: const [],
      undoStack: const [],
      movesCount: 0,
    );
  }

  int get boardSize => level.boardSize;
  int get totalWorms => worms.length;
  int get escapedWormsCount => escapedWormIds.length;
  int get remainingWormsCount => totalWorms - escapedWormsCount;
  bool get isCompleted => totalWorms > 0 && escapedWormsCount == totalWorms;
  bool get canUndo => undoStack.isNotEmpty;

  /// Checks if a grid coordinate is within board boundaries.
  bool isInsideBoard(GridPosition pos) {
    return pos.row >= 0 &&
        pos.row < boardSize &&
        pos.col >= 0 &&
        pos.col < boardSize;
  }

  /// Finds the active worm occupying the specified grid cell, if any.
  Worm? getWormAtCell(GridPosition pos) {
    for (final worm in worms.values) {
      if (worm.isActive && worm.occupies(pos)) {
        return worm;
      }
    }
    return null;
  }

  /// Calculates the straight-line forward cells ahead of the worm's head until the board edge.
  List<GridPosition> getEscapePath(Worm worm) {
    final path = <GridPosition>[];
    var current = worm.head + worm.direction.delta;

    while (isInsideBoard(current)) {
      path.add(current);
      current = current + worm.direction.delta;
    }

    return List.unmodifiable(path);
  }

  /// Returns the first active worm blocking [worm]'s escape path, or null if clear.
  Worm? findBlockingWorm(Worm worm) {
    final path = getEscapePath(worm);
    for (final pos in path) {
      for (final other in worms.values) {
        if (other.id != worm.id && other.isActive && other.occupies(pos)) {
          return other;
        }
      }
    }
    return null;
  }

  /// Determines whether [worm] is unblocked and can immediately escape.
  bool canEscape(Worm worm) {
    if (!worm.isActive) return false;
    return findBlockingWorm(worm) == null;
  }

  /// Commits the escape of a worm.
  ///
  /// Marks the worm as escaped, adds to history, saves snapshot for undo,
  /// and increments move count.
  WormEscapeEngine escapeWorm(String wormId) {
    final targetWorm = worms[wormId];
    if (targetWorm == null || !targetWorm.isActive) {
      return this;
    }

    // Save snapshot of current state before applying escape
    final snapshot = WormEscapeSnapshot(
      worms: worms,
      escapedWormIds: escapedWormIds,
      movesCount: movesCount,
    );

    final updatedWorms = Map<String, Worm>.from(worms);
    updatedWorms[wormId] = targetWorm.copyWith(status: WormStatus.escaped);

    final updatedEscaped = List<String>.from(escapedWormIds)..add(wormId);
    final updatedUndoStack = List<WormEscapeSnapshot>.from(undoStack)
      ..add(snapshot);

    return WormEscapeEngine(
      level: level,
      worms: Map.unmodifiable(updatedWorms),
      escapedWormIds: List.unmodifiable(updatedEscaped),
      undoStack: List.unmodifiable(updatedUndoStack),
      movesCount: movesCount + 1,
    );
  }

  /// Undoes the last successful escape move, restoring the worm's position and active status.
  WormEscapeEngine undo() {
    if (!canUndo) return this;

    final snapshot = undoStack.last;
    final updatedUndoStack = List<WormEscapeSnapshot>.from(undoStack)
      ..removeLast();

    return WormEscapeEngine(
      level: level,
      worms: snapshot.worms,
      escapedWormIds: snapshot.escapedWormIds,
      undoStack: List.unmodifiable(updatedUndoStack),
      movesCount: snapshot.movesCount,
    );
  }

  /// Restores the level to its initial unsolved state.
  WormEscapeEngine reset() {
    return WormEscapeEngine.initial(level);
  }

  /// Returns the ID of an active worm that can safely escape right now.
  ///
  /// Prioritizes the level's curated reference solution sequence.
  String? getHintWormId() {
    // 1. Check reference solution in order for first unescaped, unblocked worm
    for (final id in level.referenceSolution) {
      final worm = worms[id];
      if (worm != null && worm.isActive && canEscape(worm)) {
        return id;
      }
    }

    // 2. Fallback: check all active worms if player followed alternative valid escape order
    for (final worm in worms.values) {
      if (worm.isActive && canEscape(worm)) {
        return worm.id;
      }
    }

    return null;
  }

  /// Validates the structural integrity and solvability of a [WormEscapeLevel].
  static LevelValidationResult validateLevel(WormEscapeLevel level) {
    final wormIds = <String>{};
    final occupiedCells = <GridPosition, String>{};

    for (final worm in level.worms) {
      // 1. Unique IDs
      if (!wormIds.add(worm.id)) {
        return LevelValidationResult.failure(
          'Duplicate worm ID found: ${worm.id}',
        );
      }

      // 2. Length >= 2
      if (worm.body.length < 2) {
        return LevelValidationResult.failure(
          'Worm ${worm.id} has fewer than 2 segments',
        );
      }

      // 3. In bounds
      for (final pos in worm.body) {
        if (pos.row < 0 ||
            pos.row >= level.boardSize ||
            pos.col < 0 ||
            pos.col >= level.boardSize) {
          return LevelValidationResult.failure(
            'Worm ${worm.id} segment $pos is outside board of size ${level.boardSize}',
          );
        }

        // 4. Overlap check
        if (occupiedCells.containsKey(pos)) {
          return LevelValidationResult.failure(
            'Worms ${occupiedCells[pos]} and ${worm.id} overlap at cell $pos',
          );
        }
        occupiedCells[pos] = worm.id;
      }

      // 5. Contiguous straight line in direction
      for (int i = 0; i < worm.body.length - 1; i++) {
        final current = worm.body[i];
        final next = worm.body[i + 1];

        // Body must extend backwards from head
        final expectedStep = worm.direction.opposite.delta;
        if (next != current + expectedStep) {
          return LevelValidationResult.failure(
            'Worm ${worm.id} body is not a contiguous straight line aligned with direction ${worm.direction}',
          );
        }
      }
    }

    // 6. Reference solution check: must contain all worm IDs exactly once
    if (level.referenceSolution.length != level.worms.length) {
      return LevelValidationResult.failure(
        'Reference solution length (${level.referenceSolution.length}) != worms count (${level.worms.length})',
      );
    }

    final refIds = level.referenceSolution.toSet();
    if (refIds.length != level.worms.length || !refIds.containsAll(wormIds)) {
      return LevelValidationResult.failure(
        'Reference solution does not contain all worm IDs exactly once',
      );
    }

    // 7. Replay test: execute reference solution through engine step-by-step
    var simEngine = WormEscapeEngine.initial(level);
    for (int step = 0; step < level.referenceSolution.length; step++) {
      final wormId = level.referenceSolution[step];
      final worm = simEngine.worms[wormId];
      if (worm == null) {
        return LevelValidationResult.failure(
          'Step $step: worm $wormId does not exist in level',
        );
      }

      final blocker = simEngine.findBlockingWorm(worm);
      if (blocker != null) {
        return LevelValidationResult.failure(
          'Step $step: worm $wormId is blocked by ${blocker.id} and cannot escape',
        );
      }

      simEngine = simEngine.escapeWorm(wormId);
    }

    if (!simEngine.isCompleted) {
      return LevelValidationResult.failure(
        'Replaying reference solution did not complete level',
      );
    }

    return const LevelValidationResult.success();
  }
}

/// Result returned by level validation.
class LevelValidationResult {
  final bool isValid;
  final String? errorMessage;

  const LevelValidationResult.success() : isValid = true, errorMessage = null;

  const LevelValidationResult.failure(this.errorMessage) : isValid = false;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $errorMessage';
}
