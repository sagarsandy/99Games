import 'package:flutter/foundation.dart';
import 'emoji_connect_models.dart';
import 'emoji_connect_solver.dart';

/// Immutable engine managing board state, drag interactions, path edits, undo, and win detection.
@immutable
class EmojiConnectEngine {
  final EmojiConnectLevel level;
  final Map<String, EmojiPath> paths;
  final String? activeDragPairId;
  final List<Map<String, EmojiPath>> history;
  final bool isCompleted;
  final int movesCount;

  const EmojiConnectEngine({
    required this.level,
    required this.paths,
    this.activeDragPairId,
    this.history = const [],
    this.isCompleted = false,
    this.movesCount = 0,
  });

  factory EmojiConnectEngine.initial(EmojiConnectLevel level) {
    return EmojiConnectEngine(
      level: level,
      paths: const {},
      activeDragPairId: null,
      history: const [],
      isCompleted: false,
      movesCount: 0,
    );
  }

  factory EmojiConnectEngine.fromSaved({
    required EmojiConnectLevel level,
    required Map<String, List<GridPosition>> savedPaths,
    int movesCount = 0,
  }) {
    // Validate each saved path
    final validPaths = <String, EmojiPath>{};
    final occupied = <GridPosition, String>{};

    for (final pair in level.pairs) {
      final pts = savedPaths[pair.id];
      if (pts == null || pts.isEmpty) continue;

      bool valid = true;
      for (int i = 0; i < pts.length; i++) {
        final p = pts[i];
        if (!p.isWithinBounds(level.boardSize)) {
          valid = false;
          break;
        }
        if (i > 0 && !pts[i - 1].isOrthogonalTo(p)) {
          valid = false;
          break;
        }
        final ep = level.getPairAtEndpoint(p);
        if (ep != null && ep.id != pair.id) {
          valid = false;
          break;
        }
        if (occupied.containsKey(p)) {
          valid = false;
          break;
        }
      }

      if (valid) {
        for (final p in pts) {
          occupied[p] = pair.id;
        }
        validPaths[pair.id] = EmojiPath(pairId: pair.id, points: pts);
      }
    }

    final val = EmojiConnectSolver.validate(level: level, paths: validPaths);

    return EmojiConnectEngine(
      level: level,
      paths: Map.unmodifiable(validPaths),
      activeDragPairId: null,
      history: const [],
      isCompleted: val.isCompleteWin,
      movesCount: movesCount,
    );
  }

  /// Total cells occupied by all paths.
  int get coveredCellsCount {
    final set = <GridPosition>{};
    for (final p in paths.values) {
      set.addAll(p.points);
    }
    return set.length;
  }

  /// Total number of cells on this board.
  int get totalCells => level.boardSize * level.boardSize;

  /// Number of completed pairs.
  int get completedPairsCount {
    int count = 0;
    for (final pair in level.pairs) {
      final p = paths[pair.id];
      if (p != null && p.isComplete(pair)) {
        count++;
      }
    }
    return count;
  }

  /// Whether an undo action is available.
  bool get canUndo => history.isNotEmpty && !isCompleted;

  /// Checks if a cell is occupied by any pair other than [excludePairId].
  bool isCellOccupiedByOther(GridPosition pos, String? excludePairId) {
    for (final entry in paths.entries) {
      if (entry.key == excludePairId) continue;
      if (entry.value.contains(pos)) return true;
    }
    return false;
  }

  /// Returns the pair ID occupying [pos], if any.
  String? getOccupyingPairId(GridPosition pos) {
    for (final entry in paths.entries) {
      if (entry.value.contains(pos)) return entry.key;
    }
    return null;
  }

  /// Begins dragging a path for a pair.
  EmojiConnectEngine startPath(GridPosition pos) {
    if (isCompleted) return this;
    if (!pos.isWithinBounds(level.boardSize)) return this;

    // Check if pos is an endpoint
    final endpointPair = level.getPairAtEndpoint(pos);
    if (endpointPair != null) {
      // Record history before altering paths
      final newHistory = [...history, Map<String, EmojiPath>.from(paths)];

      // Remove existing path for this pair so old occupancy is cleared
      final newPaths = Map<String, EmojiPath>.from(paths);
      newPaths[endpointPair.id] = EmojiPath(
        pairId: endpointPair.id,
        points: [pos],
      );

      return EmojiConnectEngine(
        level: level,
        paths: Map.unmodifiable(newPaths),
        activeDragPairId: endpointPair.id,
        history: newHistory,
        isCompleted: false,
        movesCount: movesCount,
      );
    }

    // Check if pos is in an existing path
    final occupyingPairId = getOccupyingPairId(pos);
    if (occupyingPairId != null) {
      final existingPath = paths[occupyingPairId]!;
      final newHistory = [...history, Map<String, EmojiPath>.from(paths)];

      final trimmed = existingPath.trimTo(pos);
      final newPaths = Map<String, EmojiPath>.from(paths);
      newPaths[occupyingPairId] = trimmed;

      return EmojiConnectEngine(
        level: level,
        paths: Map.unmodifiable(newPaths),
        activeDragPairId: occupyingPairId,
        history: newHistory,
        isCompleted: false,
        movesCount: movesCount,
      );
    }

    return this;
  }

  /// Extends the active drag path to [pos].
  EmojiConnectEngine extendPath(GridPosition pos) {
    if (isCompleted || activeDragPairId == null) return this;
    if (!pos.isWithinBounds(level.boardSize)) return this;

    final pair = level.getPairById(activeDragPairId!)!;
    final currentPath =
        paths[pair.id] ?? EmojiPath(pairId: pair.id, points: []);
    if (currentPath.isEmpty) return this;

    final head = currentPath.head!;
    if (pos == head) return this;

    // Must be orthogonally adjacent to the head of the path
    if (!pos.isOrthogonalTo(head)) return this;

    // Retraction check: dragging back to the immediately previous cell
    if (currentPath.length >= 2 &&
        pos == currentPath.points[currentPath.length - 2]) {
      final retracted = currentPath.removeLast();
      final newPaths = Map<String, EmojiPath>.from(paths);
      newPaths[pair.id] = retracted;
      return EmojiConnectEngine(
        level: level,
        paths: Map.unmodifiable(newPaths),
        activeDragPairId: activeDragPairId,
        history: history,
        isCompleted: false,
        movesCount: movesCount,
      );
    }

    // If path is already complete, do not extend further past endpoint
    if (currentPath.isComplete(pair)) return this;

    // Self-intersection check: if dragging to earlier cell in same path, trim to it
    if (currentPath.contains(pos)) {
      final trimmed = currentPath.trimTo(pos);
      final newPaths = Map<String, EmojiPath>.from(paths);
      newPaths[pair.id] = trimmed;
      return EmojiConnectEngine(
        level: level,
        paths: Map.unmodifiable(newPaths),
        activeDragPairId: activeDragPairId,
        history: history,
        isCompleted: false,
        movesCount: movesCount,
      );
    }

    // Endpoint obstacle check: cannot pass through an unrelated pair's endpoint
    final ep = level.getPairAtEndpoint(pos);
    if (ep != null && ep.id != pair.id) {
      return this; // Move rejected
    }

    // Path overlap check: cannot cross or overlap another pair's path
    if (isCellOccupiedByOther(pos, pair.id)) {
      return this; // Move rejected
    }

    // Valid extension!
    final extended = currentPath.append(pos);
    final newPaths = Map<String, EmojiPath>.from(paths);
    newPaths[pair.id] = extended;

    return EmojiConnectEngine(
      level: level,
      paths: Map.unmodifiable(newPaths),
      activeDragPairId: activeDragPairId,
      history: history,
      isCompleted: false,
      movesCount: movesCount,
    );
  }

  /// Finalizes the active drag path upon pointer release.
  EmojiConnectEngine endPath() {
    if (activeDragPairId == null) return this;

    final newPaths = Map<String, EmojiPath>.from(paths);
    final currentPath = newPaths[activeDragPairId];

    // Remove single-point paths (tapping an endpoint without dragging)
    if (currentPath != null && currentPath.length <= 1) {
      newPaths.remove(activeDragPairId);
    }

    // Check if the board is now completely solved
    final val = EmojiConnectSolver.validate(level: level, paths: newPaths);

    return EmojiConnectEngine(
      level: level,
      paths: Map.unmodifiable(newPaths),
      activeDragPairId: null,
      history: history,
      isCompleted: val.isCompleteWin,
      movesCount: movesCount + 1,
    );
  }

  /// Undoes the last path change.
  EmojiConnectEngine undo() {
    if (!canUndo) return this;

    final previousPaths = history.last;
    final newHistory = history.sublist(0, history.length - 1);
    final val = EmojiConnectSolver.validate(level: level, paths: previousPaths);

    return EmojiConnectEngine(
      level: level,
      paths: Map.unmodifiable(previousPaths),
      activeDragPairId: null,
      history: newHistory,
      isCompleted: val.isCompleteWin,
      movesCount: movesCount,
    );
  }

  /// Resets all drawn paths to initial empty state.
  EmojiConnectEngine reset() {
    return EmojiConnectEngine(
      level: level,
      paths: const {},
      activeDragPairId: null,
      history: const [],
      isCompleted: false,
      movesCount: 0,
    );
  }

  /// Applies a hint from the verified reference solution.
  ///
  /// Returns a tuple of (updatedEngine, hintDescription).
  (EmojiConnectEngine, String) applyHint() {
    if (isCompleted) {
      return (this, 'Level is already completed!');
    }

    // Find the first pair that is incomplete or deviates from the reference solution
    EmojiPair? targetPair;
    for (final pair in level.pairs) {
      final current = paths[pair.id];
      final ref = level.referenceSolution[pair.id];
      if (ref == null) continue;

      if (current == null || !current.isComplete(pair)) {
        targetPair = pair;
        break;
      }

      // Check if current matches ref
      final currentPts = current.points;
      final refForward = ref;
      final refBackward = ref.reversed.toList();
      final matchesForward = _listEquals(currentPts, refForward);
      final matchesBackward = _listEquals(currentPts, refBackward);

      if (!matchesForward && !matchesBackward) {
        targetPair = pair;
        break;
      }
    }

    if (targetPair == null) {
      return (this, 'All current paths match the reference solution!');
    }

    final refPoints = level.referenceSolution[targetPair.id]!;
    final newHistory = [...history, Map<String, EmojiPath>.from(paths)];

    // Remove any conflicting paths that intersect with the hint route
    final newPaths = Map<String, EmojiPath>.from(paths);
    final refSet = refPoints.toSet();

    for (final pair in level.pairs) {
      if (pair.id == targetPair.id) continue;
      final p = newPaths[pair.id];
      if (p != null && p.points.any(refSet.contains)) {
        newPaths.remove(pair.id);
      }
    }

    newPaths[targetPair.id] = EmojiPath(
      pairId: targetPair.id,
      points: refPoints,
    );

    final val = EmojiConnectSolver.validate(level: level, paths: newPaths);

    final updated = EmojiConnectEngine(
      level: level,
      paths: Map.unmodifiable(newPaths),
      activeDragPairId: null,
      history: newHistory,
      isCompleted: val.isCompleteWin,
      movesCount: movesCount + 1,
    );

    return (updated, 'Connected ${targetPair.emoji} along its solution path!');
  }

  static bool _listEquals(List<GridPosition> a, List<GridPosition> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
