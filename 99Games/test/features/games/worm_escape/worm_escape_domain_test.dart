import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_engine.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_level_data.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_models.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_solver.dart';

void main() {
  group('Worm Escape Domain Models', () {
    test('GridPosition arithmetic and equality', () {
      const p1 = GridPosition(2, 3);
      const p2 = GridPosition(1, -1);

      expect(p1 + p2, equals(const GridPosition(3, 2)));
      expect(p1 - p2, equals(const GridPosition(1, 4)));
      expect(p1.isOrthogonalTo(const GridPosition(2, 4)), isTrue);
      expect(p1.isOrthogonalTo(const GridPosition(3, 3)), isTrue);
      expect(p1.isOrthogonalTo(const GridPosition(3, 4)), isFalse);
    });

    test('WormDirection vectors and opposites', () {
      expect(WormDirection.up.delta, equals(const GridPosition(-1, 0)));
      expect(WormDirection.down.delta, equals(const GridPosition(1, 0)));
      expect(WormDirection.left.delta, equals(const GridPosition(0, -1)));
      expect(WormDirection.right.delta, equals(const GridPosition(0, 1)));

      expect(WormDirection.up.opposite, equals(WormDirection.down));
      expect(WormDirection.down.opposite, equals(WormDirection.up));
      expect(WormDirection.left.opposite, equals(WormDirection.right));
      expect(WormDirection.right.opposite, equals(WormDirection.left));
    });

    test('Worm head, tail, and body convention', () {
      const worm = Worm(
        id: 'w1',
        body: [GridPosition(2, 2), GridPosition(3, 2), GridPosition(4, 2)],
        direction: WormDirection.up,
        colorIndex: 0,
      );

      expect(worm.head, equals(const GridPosition(2, 2)));
      expect(worm.tail, equals(const GridPosition(4, 2)));
      expect(worm.length, equals(3));
      expect(worm.occupies(const GridPosition(3, 2)), isTrue);
      expect(worm.occupies(const GridPosition(1, 2)), isFalse);
    });
  });

  group('Worm Escape Collision & Rules Engine', () {
    late WormEscapeLevel sampleLevel;

    setUp(() {
      // 5x5 board with 2 worms: w1 moving right, blocked by w2 moving down
      sampleLevel = const WormEscapeLevel(
        id: 'test_1',
        difficulty: WormEscapeDifficulty.easy,
        levelNumber: 1,
        boardSize: 5,
        worms: [
          Worm(
            id: 'w1',
            body: [GridPosition(2, 1), GridPosition(2, 0)],
            direction: WormDirection.right,
            colorIndex: 0,
          ),
          Worm(
            id: 'w2',
            body: [GridPosition(2, 3), GridPosition(1, 3)],
            direction: WormDirection.down,
            colorIndex: 1,
          ),
        ],
        referenceSolution: ['w2', 'w1'],
      );
    });

    test('Identifies blocking worms correctly along escape path', () {
      final engine = WormEscapeEngine.initial(sampleLevel);
      final w1 = engine.worms['w1']!;
      final w2 = engine.worms['w2']!;

      // w1's forward path to the right contains (2, 2), (2, 3), (2, 4)
      // Cell (2, 3) is occupied by w2!
      expect(engine.findBlockingWorm(w1), equals(w2));
      expect(engine.canEscape(w1), isFalse);

      // w2's forward path down contains (3, 3), (4, 3)
      // Both cells are clear!
      expect(engine.findBlockingWorm(w2), isNull);
      expect(engine.canEscape(w2), isTrue);
    });

    test('Escaping worm unblocks other worms and updates state', () {
      var engine = WormEscapeEngine.initial(sampleLevel);
      expect(engine.remainingWormsCount, equals(2));
      expect(engine.isCompleted, isFalse);

      // Escape w2
      engine = engine.escapeWorm('w2');
      expect(engine.escapedWormIds, contains('w2'));
      expect(engine.remainingWormsCount, equals(1));
      expect(engine.movesCount, equals(1));

      // w1 is now unblocked!
      final w1 = engine.worms['w1']!;
      expect(engine.findBlockingWorm(w1), isNull);
      expect(engine.canEscape(w1), isTrue);

      // Escape w1
      engine = engine.escapeWorm('w1');
      expect(engine.remainingWormsCount, equals(0));
      expect(engine.isCompleted, isTrue);
      expect(engine.movesCount, equals(2));
    });

    test('Undo restores previous game state exactly', () {
      var engine = WormEscapeEngine.initial(sampleLevel);
      engine = engine.escapeWorm('w2');
      expect(engine.escapedWormsCount, equals(1));
      expect(engine.canUndo, isTrue);

      engine = engine.undo();
      expect(engine.escapedWormsCount, equals(0));
      expect(engine.worms['w2']!.isActive, isTrue);
      expect(engine.canEscape(engine.worms['w1']!), isFalse);
      expect(engine.movesCount, equals(0));
    });

    test('Reset restores initial state of level', () {
      var engine = WormEscapeEngine.initial(sampleLevel);
      engine = engine.escapeWorm('w2');
      engine = engine.escapeWorm('w1');
      expect(engine.isCompleted, isTrue);

      engine = engine.reset();
      expect(engine.isCompleted, isFalse);
      expect(engine.escapedWormsCount, equals(0));
      expect(engine.movesCount, equals(0));
    });

    test('Hint identifies the next unblocked worm in reference sequence', () {
      final engine = WormEscapeEngine.initial(sampleLevel);
      // Reference solution is ['w2', 'w1']
      // w2 is unblocked, so hint must return 'w2'
      expect(engine.getHintWormId(), equals('w2'));
    });

    test('Solver finds solution sequence for solvable level', () {
      final solution = WormEscapeSolver.solve(sampleLevel);
      expect(solution, isNotNull);
      expect(solution, equals(['w2', 'w1']));
    });
  });

  group('Curated Level Validation (All 75 Levels)', () {
    test('75 bundled levels exist (25 Easy, 25 Medium, 25 Hard)', () {
      expect(WormEscapeLevelData.levels.length, equals(75));

      final easy = WormEscapeLevelData.getLevelsByDifficulty(
        WormEscapeDifficulty.easy,
      );
      final medium = WormEscapeLevelData.getLevelsByDifficulty(
        WormEscapeDifficulty.medium,
      );
      final hard = WormEscapeLevelData.getLevelsByDifficulty(
        WormEscapeDifficulty.hard,
      );

      expect(easy.length, equals(25));
      expect(medium.length, equals(25));
      expect(hard.length, equals(25));
    });

    test('Every level passes strict engine validation and replays cleanly', () {
      for (final level in WormEscapeLevelData.levels) {
        final result = WormEscapeEngine.validateLevel(level);
        expect(
          result.isValid,
          isTrue,
          reason: 'Level ${level.id} failed: ${result.errorMessage}',
        );
      }
    });
  });
}
