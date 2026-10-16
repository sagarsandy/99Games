import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_engine.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_level_data.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_models.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_solver.dart';

void main() {
  group('EmojiConnectEngine Unit Tests', () {
    late EmojiConnectLevel level1;

    setUp(() {
      level1 = EmojiConnectLevelData.getLevel(EmojiConnectDifficulty.easy, 1);
    });

    test('Initial engine state has no paths and is not completed', () {
      final engine = EmojiConnectEngine.initial(level1);
      expect(engine.paths.isEmpty, isTrue);
      expect(engine.coveredCellsCount, equals(0));
      expect(engine.completedPairsCount, equals(0));
      expect(engine.isCompleted, isFalse);
      expect(engine.canUndo, isFalse);
      expect(engine.movesCount, equals(0));
    });

    test('Starting drag on an endpoint initiates path for that pair', () {
      final engine = EmojiConnectEngine.initial(level1);
      final pair1 = level1.pairs[0];
      final updated = engine.startPath(pair1.endpointA);

      expect(updated.activeDragPairId, equals(pair1.id));
      expect(updated.paths[pair1.id]?.points, equals([pair1.endpointA]));
      expect(updated.canUndo, isTrue);
    });

    test('Starting drag on an empty cell does nothing', () {
      final engine = EmojiConnectEngine.initial(level1);
      // Find a cell that is not an endpoint
      GridPosition? emptyCell;
      for (int r = 0; r < level1.boardSize; r++) {
        for (int c = 0; c < level1.boardSize; c++) {
          final p = GridPosition(r, c);
          if (level1.getPairAtEndpoint(p) == null) {
            emptyCell = p;
            break;
          }
        }
        if (emptyCell != null) break;
      }

      expect(emptyCell, isNotNull);
      final updated = engine.startPath(emptyCell!);
      expect(updated.activeDragPairId, isNull);
      expect(updated.paths.isEmpty, isTrue);
    });

    test('Orthogonal movement extends path successfully', () {
      final engine = EmojiConnectEngine.initial(level1);
      final pair = level1.pairs[0];
      final start = pair.endpointA;

      // Find an orthogonal neighbor that is free
      final neighbors = start.orthogonalNeighbors(level1.boardSize);
      final validNeighbor = neighbors.firstWhere(
        (n) => level1.getPairAtEndpoint(n) == null,
      );

      var state = engine.startPath(start);
      state = state.extendPath(validNeighbor);

      expect(state.paths[pair.id]?.points, equals([start, validNeighbor]));
    });

    test('Diagonal movement is strictly rejected', () {
      final engine = EmojiConnectEngine.initial(level1);
      final pair = level1.pairs[0];
      final start = pair.endpointA;

      final diag = GridPosition(start.row + 1, start.col + 1);
      var state = engine.startPath(start);
      state = state.extendPath(diag);

      expect(state.paths[pair.id]?.points, equals([start]));
    });

    test('Out-of-bounds movement is strictly rejected', () {
      // Create a level with endpoint on board boundary
      final engine = EmojiConnectEngine.initial(level1);
      final pair = level1.pairs[0];
      final start = pair.endpointA;

      final outOfBounds = GridPosition(-1, start.col);
      var state = engine.startPath(start);
      state = state.extendPath(outOfBounds);

      expect(state.paths[pair.id]?.points, equals([start]));
    });

    test('Retracting to immediately previous cell removes the last step', () {
      final engine = EmojiConnectEngine.initial(level1);
      final pair = level1.pairs[0];
      final start = pair.endpointA;
      final neighbor = start
          .orthogonalNeighbors(level1.boardSize)
          .firstWhere((n) => level1.getPairAtEndpoint(n) == null);

      var state = engine.startPath(start);
      state = state.extendPath(neighbor);
      expect(state.paths[pair.id]?.length, equals(2));

      // Drag back to start
      state = state.extendPath(start);
      expect(state.paths[pair.id]?.points, equals([start]));
    });

    test('Movement into another pair endpoint is rejected', () {
      final engine = EmojiConnectEngine.initial(level1);
      final pair1 = level1.pairs[0];
      final pair2 = level1.pairs[1];

      // If pair2 endpoint happens to be adjacent to pair1 start
      var state = engine.startPath(pair1.endpointA);
      state = state.extendPath(pair2.endpointA);

      expect(state.paths[pair1.id]?.points, equals([pair1.endpointA]));
    });

    test(
      'Movement into an occupied cell belonging to another pair is rejected',
      () {
        final engine = EmojiConnectEngine.initial(level1);
        final pair1 = level1.pairs[0];
        final pair2 = level1.pairs[1];

        // Draw path for pair1
        final ref1 = level1.referenceSolution[pair1.id]!;
        var state = engine.startPath(ref1[0]);
        for (int i = 1; i < ref1.length; i++) {
          state = state.extendPath(ref1[i]);
        }
        state = state.endPath();

        // Now start pair2 and try to step into pair1's cell
        state = state.startPath(pair2.endpointA);
        final occupiedCell = ref1[1]; // A cell occupied by pair1
        state = state.extendPath(occupiedCell);

        expect(state.paths[pair2.id]?.contains(occupiedCell), isFalse);
      },
    );

    test(
      'Redrawing an existing path clears old occupancy before replacement',
      () {
        final engine = EmojiConnectEngine.initial(level1);
        final pair1 = level1.pairs[0];
        final ref1 = level1.referenceSolution[pair1.id]!;

        // Draw full path for pair 1
        var state = engine.startPath(ref1[0]);
        for (int i = 1; i < ref1.length; i++) {
          state = state.extendPath(ref1[i]);
        }
        state = state.endPath();
        expect(state.paths[pair1.id]?.length, equals(ref1.length));

        // Start redrawing pair 1 from start
        state = state.startPath(ref1[0]);
        expect(state.paths[pair1.id]?.points, equals([ref1[0]]));
        // Old cells are freed
        expect(state.isCellOccupiedByOther(ref1[1], null), isFalse);
      },
    );

    test('Connecting to matching endpoint completes the pair', () {
      final engine = EmojiConnectEngine.initial(level1);
      final pair1 = level1.pairs[0];
      final ref1 = level1.referenceSolution[pair1.id]!;

      var state = engine.startPath(ref1[0]);
      for (int i = 1; i < ref1.length; i++) {
        state = state.extendPath(ref1[i]);
      }
      state = state.endPath();

      expect(state.paths[pair1.id]?.isComplete(pair1), isTrue);
      expect(state.completedPairsCount, equals(1));
    });

    test(
      'Incomplete board with all pairs connected but unfilled cells is NOT a win',
      () {
        // Construct a scenario where all pairs are connected directly, but empty cells remain
        final testLevel = EmojiConnectLevel(
          id: 99,
          difficulty: EmojiConnectDifficulty.easy,
          boardSize: 3,
          pairs: const [
            EmojiPair(
              id: 'p1',
              emoji: '😀',
              colorValue: 0xFFF59E0B,
              endpointA: GridPosition(0, 0),
              endpointB: GridPosition(0, 2),
            ),
            EmojiPair(
              id: 'p2',
              emoji: '⭐',
              colorValue: 0xFF6366F1,
              endpointA: GridPosition(2, 0),
              endpointB: GridPosition(2, 2),
            ),
          ],
          referenceSolution: const {
            'p1': [
              GridPosition(0, 0),
              GridPosition(0, 1),
              GridPosition(0, 2),
              GridPosition(1, 2),
              GridPosition(1, 1),
            ],
            'p2': [
              GridPosition(2, 0),
              GridPosition(2, 1),
              GridPosition(2, 2),
              GridPosition(1, 0),
            ],
          },
        );

        // Connect p1 along row 0: (0,0)->(0,1)->(0,2)
        // Connect p2 along row 2: (2,0)->(2,1)->(2,2)
        // Row 1 is completely empty (3 cells empty). Total covered = 6, board = 9.
        final paths = {
          'p1': const EmojiPath(
            pairId: 'p1',
            points: [
              GridPosition(0, 0),
              GridPosition(0, 1),
              GridPosition(0, 2),
            ],
          ),
          'p2': const EmojiPath(
            pairId: 'p2',
            points: [
              GridPosition(2, 0),
              GridPosition(2, 1),
              GridPosition(2, 2),
            ],
          ),
        };

        final val = EmojiConnectSolver.validate(level: testLevel, paths: paths);
        expect(val.connectedPairsCount, equals(2));
        expect(val.coveredCellsCount, equals(6));
        expect(
          val.isCompleteWin,
          isFalse,
          reason: 'Level must not be won if cells remain unfilled',
        );
      },
    );

    test('Complete reference solution produces a full win', () {
      final engine = EmojiConnectEngine.initial(level1);
      final ref = level1.referenceSolution;

      var state = engine;
      for (final pair in level1.pairs) {
        final pts = ref[pair.id]!;
        state = state.startPath(pts[0]);
        for (int i = 1; i < pts.length; i++) {
          state = state.extendPath(pts[i]);
        }
        state = state.endPath();
      }

      expect(state.isCompleted, isTrue);
      expect(
        state.coveredCellsCount,
        equals(level1.boardSize * level1.boardSize),
      );
      expect(state.completedPairsCount, equals(level1.pairs.length));
    });

    test('Undo restores previous board path state', () {
      final engine = EmojiConnectEngine.initial(level1);
      final pair1 = level1.pairs[0];
      final ref1 = level1.referenceSolution[pair1.id]!;

      var state = engine.startPath(ref1[0]);
      state = state.extendPath(ref1[1]);
      state = state.endPath();
      expect(state.paths[pair1.id]?.length, equals(2));

      // Undo
      state = state.undo();
      expect(state.paths.isEmpty, isTrue);
    });

    test('Reset clears all paths to initial state', () {
      final engine = EmojiConnectEngine.initial(level1);
      final pair1 = level1.pairs[0];
      final ref1 = level1.referenceSolution[pair1.id]!;

      var state = engine.startPath(ref1[0]);
      state = state.extendPath(ref1[1]);
      state = state.endPath();

      state = state.reset();
      expect(state.paths.isEmpty, isTrue);
      expect(state.coveredCellsCount, equals(0));
    });

    test(
      'applyHint connects incomplete pair according to reference solution',
      () {
        final engine = EmojiConnectEngine.initial(level1);
        final (hintedEngine, message) = engine.applyHint();

        expect(hintedEngine.paths.isNotEmpty, isTrue);
        expect(message, contains('Connected'));
        expect(hintedEngine.completedPairsCount, equals(1));
      },
    );

    test('applyHint removes conflicting paths that cross hint route', () {
      final pair1 = level1.pairs[0];
      final pair2 = level1.pairs[1];
      final ref1 = level1.referenceSolution[pair1.id]!;

      // Draw a conflicting dummy path for pair 2 crossing pair 1's reference solution
      // (as long as it starts at pair2 endpoint and reaches a cell in ref1)
      final dummyPaths = {
        pair2.id: EmojiPath(
          pairId: pair2.id,
          points: [pair2.endpointA, ref1[1]],
        ),
      };

      final conflictEngine = EmojiConnectEngine(
        level: level1,
        paths: dummyPaths,
      );

      final (hinted, msg) = conflictEngine.applyHint();
      expect(hinted.paths.containsKey(pair1.id), isTrue);
      // Conflicting pair 2 was removed
      expect(hinted.paths.containsKey(pair2.id), isFalse);
    });
  });
}
