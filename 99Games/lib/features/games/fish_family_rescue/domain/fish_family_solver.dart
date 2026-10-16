import 'dart:collection';
import 'fish_family_engine.dart';
import 'fish_family_models.dart';

/// Search-based solver and solvability verifier for Fish Family Rescue.
///
/// Uses breadth-first search (BFS) with canonical state hashing and heuristic
/// symmetry pruning to find optimal solutions and verify puzzle solvability.
class FishFamilySolver {
  final FishFamilyEngine engine;
  final int maxStates;

  const FishFamilySolver({
    this.engine = const FishFamilyEngine(),
    this.maxStates = 25000,
  });

  /// Canonical state key for pruning symmetric and duplicate states.
  ///
  /// Serializes each tank's fish species from bottom to top, then sorts the tank
  /// signatures so permutations of empty or identical tanks map to the same key.
  String _canonicalKey(List<FishTank> tanks) {
    final tankSignatures = tanks.map((t) {
      if (t.isEmpty) return '';
      return t.fish.map((f) => f.speciesId).join(',');
    }).toList()..sort();

    return tankSignatures.join('|');
  }

  /// Attempts to solve the given [level] within [maxStates].
  ///
  /// Returns the shortest list of [FishMove]s leading to victory, or `null` if unsolvable.
  List<FishMove>? solve(FishFamilyLevel level) {
    return solveTanks(
      level.tanks,
      level: level,
      expectedTotalFish: level.totalFish,
      expectedSpecies: level.speciesInLevel,
    );
  }

  /// Solves an arbitrary list of [tanks].
  List<FishMove>? solveTanks(
    List<FishTank> initialTanks, {
    FishFamilyLevel? level,
    int? expectedTotalFish,
    Set<String>? expectedSpecies,
  }) {
    final isInitialWon = level != null
        ? engine.isLevelComplete(initialTanks, level)
        : engine.checkWin(
            initialTanks,
            expectedTotalFish: expectedTotalFish,
            expectedSpecies: expectedSpecies,
          );
    if (isInitialWon) {
      return const [];
    }

    final visited = <String>{};
    final queue = Queue<_SolverNode>();

    queue.add(_SolverNode(tanks: initialTanks, moves: const []));
    visited.add(_canonicalKey(initialTanks));

    int exploredStates = 0;

    while (queue.isNotEmpty) {
      if (exploredStates++ >= maxStates) {
        return null; // Search budget exceeded
      }

      final current = queue.removeFirst();
      final currentTanks = current.tanks;

      // Track if we already moved to an empty tank in this step (all empty tanks are symmetric)
      bool movedToEmptyTank = false;

      for (int i = 0; i < currentTanks.length; i++) {
        final fromTank = currentTanks[i];
        if (fromTank.isEmpty) continue;

        // Heuristic: Do not move a fish out of an already completed pure tank
        if (fromTank.isComplete) continue;

        // Heuristic: If tank has only one fish, moving it to an empty tank achieves nothing
        final isSingleFish = fromTank.fish.length == 1;

        for (int j = 0; j < currentTanks.length; j++) {
          if (i == j) continue;
          final toTank = currentTanks[j];

          // Symmetric empty tank pruning: only try moving to the first available empty tank
          if (toTank.isEmpty) {
            if (isSingleFish) {
              continue; // Moving single fish to empty tank is useless loop
            }
            if (fromTank.isPure) {
              continue; // Moving pure stack into empty tank is useless
            }
            if (movedToEmptyTank) {
              continue; // Already branched to an empty tank for this fromTank
            }
          }

          final validation = engine.validateMove(
            currentTanks,
            fromTank.id,
            toTank.id,
          );
          if (!validation.isValid) continue;

          // Execute move
          final result = engine.executeMove(
            currentTanks,
            fromTank.id,
            toTank.id,
          );

          if (toTank.isEmpty) {
            movedToEmptyTank = true;
          }

          // Check win using authoritative condition
          final isWon = level != null
              ? engine.isLevelComplete(result.tanks, level)
              : engine.checkWin(
                  result.tanks,
                  expectedTotalFish: expectedTotalFish,
                  expectedSpecies: expectedSpecies,
                );
          if (isWon) {
            return [...current.moves, result.move];
          }

          // Check visited
          final key = _canonicalKey(result.tanks);
          if (visited.add(key)) {
            queue.add(
              _SolverNode(
                tanks: result.tanks,
                moves: [...current.moves, result.move],
              ),
            );
          }
        }
      }
    }

    return null; // Unsolvable
  }

  /// Calculates objective puzzle complexity metrics for difficulty progression.
  ({
    int minMoves,
    int speciesCount,
    int mixedTanksCount,
    double difficultyScore,
  })
  evaluateDifficulty(FishFamilyLevel level) {
    final solution = solve(level);
    final minMoves = solution?.length ?? 999;
    final speciesCount = level.speciesInLevel.length;
    final mixedTanksCount = level.tanks
        .where((t) => !t.isEmpty && !t.isPure)
        .length;

    // Difficulty score composite:
    // - minMoves * 5.0
    // - speciesCount * 8.0
    // - mixedTanksCount * 6.0
    final score =
        (minMoves * 5.0) + (speciesCount * 8.0) + (mixedTanksCount * 6.0);

    return (
      minMoves: minMoves,
      speciesCount: speciesCount,
      mixedTanksCount: mixedTanksCount,
      difficultyScore: score,
    );
  }
}

class _SolverNode {
  final List<FishTank> tanks;
  final List<FishMove> moves;

  const _SolverNode({required this.tanks, required this.moves});
}
