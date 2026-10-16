import 'worm_escape_engine.dart';
import 'worm_escape_models.dart';

/// Solver and level generator algorithms for Worm Escape puzzles.
class WormEscapeSolver {
  WormEscapeSolver._();

  /// Finds a valid escape sequence for the given [level] using DFS with pruning.
  ///
  /// Returns ordered list of worm IDs that solves the puzzle, or null if unsolvable.
  static List<String>? solve(WormEscapeLevel level) {
    final engine = WormEscapeEngine.initial(level);
    return _dfs(engine, []);
  }

  static List<String>? _dfs(
    WormEscapeEngine currentEngine,
    List<String> currentPath,
  ) {
    if (currentEngine.isCompleted) {
      return currentPath;
    }

    // Find all active worms that can escape right now
    final canEscapeWorms = <Worm>[];
    for (final worm in currentEngine.worms.values) {
      if (worm.isActive && currentEngine.canEscape(worm)) {
        canEscapeWorms.add(worm);
      }
    }

    if (canEscapeWorms.isEmpty) {
      // Deadlock reached
      return null;
    }

    for (final worm in canEscapeWorms) {
      final nextEngine = currentEngine.escapeWorm(worm.id);
      final solution = _dfs(nextEngine, [...currentPath, worm.id]);
      if (solution != null) {
        return solution;
      }
    }

    return null;
  }
}
