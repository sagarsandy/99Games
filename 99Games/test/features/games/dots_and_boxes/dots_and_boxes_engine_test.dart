import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/dots_and_boxes/domain/dots_and_boxes_engine.dart';
import 'package:mini_games_99/features/games/dots_and_boxes/domain/dots_and_boxes_models.dart';

void main() {
  late DotsAndBoxesEngine engine;

  setUp(() {
    engine = DotsAndBoxesEngine();
  });

  group('DotsAndBoxesEngine - Board Initialization', () {
    test(
      'createEmptyHorizontalEdges creates correct dimensions for all sizes',
      () {
        for (final size in BoardSize.values) {
          final h = engine.createEmptyHorizontalEdges(size);
          expect(h.length, equals(size.rows + 1));
          for (final row in h) {
            expect(row.length, equals(size.cols));
            expect(row.every((cell) => cell == null), isTrue);
          }
        }
      },
    );

    test(
      'createEmptyVerticalEdges creates correct dimensions for all sizes',
      () {
        for (final size in BoardSize.values) {
          final v = engine.createEmptyVerticalEdges(size);
          expect(v.length, equals(size.rows));
          for (final row in v) {
            expect(row.length, equals(size.cols + 1));
            expect(row.every((cell) => cell == null), isTrue);
          }
        }
      },
    );

    test('createEmptyBoxes creates correct dimensions for all sizes', () {
      for (final size in BoardSize.values) {
        final b = engine.createEmptyBoxes(size);
        expect(b.length, equals(size.rows));
        for (final row in b) {
          expect(row.length, equals(size.cols));
          expect(row.every((cell) => cell == null), isTrue);
        }
      }
    });

    test('getAllUnclaimedEdges returns exact total edge counts initially', () {
      expect(
        engine
            .getAllUnclaimedEdges(
              size: BoardSize.small,
              horizontalEdges: engine.createEmptyHorizontalEdges(
                BoardSize.small,
              ),
              verticalEdges: engine.createEmptyVerticalEdges(BoardSize.small),
            )
            .length,
        equals(84),
      );

      expect(
        engine
            .getAllUnclaimedEdges(
              size: BoardSize.medium,
              horizontalEdges: engine.createEmptyHorizontalEdges(
                BoardSize.medium,
              ),
              verticalEdges: engine.createEmptyVerticalEdges(BoardSize.medium),
            )
            .length,
        equals(180),
      );

      expect(
        engine
            .getAllUnclaimedEdges(
              size: BoardSize.large,
              horizontalEdges: engine.createEmptyHorizontalEdges(
                BoardSize.large,
              ),
              verticalEdges: engine.createEmptyVerticalEdges(BoardSize.large),
            )
            .length,
        equals(480),
      );
    });
  });

  group('DotsAndBoxesEngine - Move Validation', () {
    const size = BoardSize.small;

    test('validates legal horizontal and vertical edges', () {
      expect(
        engine.isValidEdge(size, const EdgePosition.horizontal(0, 0)),
        isTrue,
      );
      expect(
        engine.isValidEdge(size, const EdgePosition.horizontal(6, 5)),
        isTrue,
      );
      expect(
        engine.isValidEdge(size, const EdgePosition.vertical(0, 0)),
        isTrue,
      );
      expect(
        engine.isValidEdge(size, const EdgePosition.vertical(5, 6)),
        isTrue,
      );
    });

    test('rejects out of bounds horizontal and vertical edges', () {
      expect(
        engine.isValidEdge(size, const EdgePosition.horizontal(-1, 0)),
        isFalse,
      );
      expect(
        engine.isValidEdge(size, const EdgePosition.horizontal(7, 0)),
        isFalse,
      );
      expect(
        engine.isValidEdge(size, const EdgePosition.horizontal(0, 6)),
        isFalse,
      );
      expect(
        engine.isValidEdge(size, const EdgePosition.vertical(0, -1)),
        isFalse,
      );
      expect(
        engine.isValidEdge(size, const EdgePosition.vertical(6, 0)),
        isFalse,
      );
      expect(
        engine.isValidEdge(size, const EdgePosition.vertical(0, 7)),
        isFalse,
      );
    });

    test('rejects already claimed edge', () {
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      const edge = EdgePosition.horizontal(0, 0);
      expect(
        engine.isLegalMove(
          size: size,
          horizontalEdges: h,
          verticalEdges: v,
          edge: edge,
        ),
        isTrue,
      );

      // Claim edge
      h[0][0] = DotsPlayer.player1;

      expect(
        engine.isLegalMove(
          size: size,
          horizontalEdges: h,
          verticalEdges: v,
          edge: edge,
        ),
        isFalse,
      );

      expect(
        () => engine.applyMove(
          size: size,
          horizontalEdges: h,
          verticalEdges: v,
          boxes: b,
          edge: edge,
          player: DotsPlayer.player2,
        ),
        throwsArgumentError,
      );
    });
  });

  group('DotsAndBoxesEngine - Box Completion & Extra Turns', () {
    const size = BoardSize.small;

    test('non-scoring move switches turn and awards no boxes', () {
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      const edge = EdgePosition.horizontal(0, 0);
      final result = engine.applyMove(
        size: size,
        horizontalEdges: h,
        verticalEdges: v,
        boxes: b,
        edge: edge,
        player: DotsPlayer.player1,
      );

      expect(result.edge, equals(edge));
      expect(result.player, equals(DotsPlayer.player1));
      expect(result.completedBoxes, isEmpty);
      expect(result.getsExtraTurn, isFalse);
      expect(result.nextPlayer, equals(DotsPlayer.player2));
      expect(result.isGameOver, isFalse);
    });

    test('completing a single box awards box and retains turn for player', () {
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      // Box (0, 0) boundaries:
      // Top: H(0, 0)
      // Bottom: H(1, 0)
      // Left: V(0, 0)
      // Right: V(0, 1)

      h[0][0] = DotsPlayer.player1;
      h[1][0] = DotsPlayer.player2;
      v[0][0] = DotsPlayer.player1;

      // Player 2 completes box with V(0, 1)
      const finishingEdge = EdgePosition.vertical(0, 1);
      final result = engine.applyMove(
        size: size,
        horizontalEdges: h,
        verticalEdges: v,
        boxes: b,
        edge: finishingEdge,
        player: DotsPlayer.player2,
      );

      expect(result.completedBoxes, equals([const BoxPosition(0, 0)]));
      expect(result.getsExtraTurn, isTrue);
      expect(result.nextPlayer, equals(DotsPlayer.player2)); // Retains turn
      expect(result.isGameOver, isFalse);
    });

    test(
      'completing two boxes with one interior edge awards both and retains turn',
      () {
        final h = engine.createEmptyHorizontalEdges(size);
        final v = engine.createEmptyVerticalEdges(size);
        final b = engine.createEmptyBoxes(size);

        // We set up two adjacent boxes sharing H(1, 0):
        // Box above (0, 0) has edges: H(0,0), H(1,0), V(0,0), V(0,1)
        // Box below (1, 0) has edges: H(1,0), H(2,0), V(1,0), V(1,1)

        // Draw all edges except the shared H(1, 0)
        h[0][0] = DotsPlayer.player1;
        v[0][0] = DotsPlayer.player2;
        v[0][1] = DotsPlayer.player1;

        h[2][0] = DotsPlayer.player2;
        v[1][0] = DotsPlayer.player1;
        v[1][1] = DotsPlayer.player2;

        // Player 1 plays shared H(1, 0)
        const sharedEdge = EdgePosition.horizontal(1, 0);
        final result = engine.applyMove(
          size: size,
          horizontalEdges: h,
          verticalEdges: v,
          boxes: b,
          edge: sharedEdge,
          player: DotsPlayer.player1,
        );

        expect(result.completedBoxes.length, equals(2));
        expect(
          result.completedBoxes,
          containsAll([const BoxPosition(0, 0), const BoxPosition(1, 0)]),
        );
        expect(result.getsExtraTurn, isTrue);
        expect(result.nextPlayer, equals(DotsPlayer.player1)); // Retains turn
      },
    );

    test(
      'completing two vertical adjacent boxes with one interior vertical edge',
      () {
        final h = engine.createEmptyHorizontalEdges(size);
        final v = engine.createEmptyVerticalEdges(size);
        final b = engine.createEmptyBoxes(size);

        // Shared edge: V(0, 1) between Box (0, 0) and Box (0, 1)
        // Box (0, 0): H(0,0), H(1,0), V(0,0)
        h[0][0] = DotsPlayer.player1;
        h[1][0] = DotsPlayer.player1;
        v[0][0] = DotsPlayer.player1;

        // Box (0, 1): H(0,1), H(1,1), V(0,2)
        h[0][1] = DotsPlayer.player2;
        h[1][1] = DotsPlayer.player2;
        v[0][2] = DotsPlayer.player2;

        // Player 2 plays shared V(0, 1)
        const sharedV = EdgePosition.vertical(0, 1);
        final result = engine.applyMove(
          size: size,
          horizontalEdges: h,
          verticalEdges: v,
          boxes: b,
          edge: sharedV,
          player: DotsPlayer.player2,
        );

        expect(result.completedBoxes.length, equals(2));
        expect(
          result.completedBoxes,
          containsAll([const BoxPosition(0, 0), const BoxPosition(0, 1)]),
        );
        expect(result.getsExtraTurn, isTrue);
        expect(result.nextPlayer, equals(DotsPlayer.player2));
      },
    );
  });

  group('DotsAndBoxesEngine - Game Over & Winner / Draw Determination', () {
    const size = BoardSize.small; // 36 boxes

    test('detects game over, winner, and draw accurately', () {
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      // Fill 35 boxes with player1 and player2
      for (int r = 0; r < size.rows; r++) {
        for (int c = 0; c < size.cols; c++) {
          if (r == 5 && c == 5) continue; // leave last box (5,5)

          // Assign player1 to first 24 boxes, player2 to remainder
          final p = r < 4 ? DotsPlayer.player1 : DotsPlayer.player2;
          b[r][c] = p;

          // Draw surrounding edges
          h[r][c] = p;
          h[r + 1][c] = p;
          v[r][c] = p;
          v[r][c + 1] = p;
        }
      }

      // Box (5,5) needs 1 more edge to complete
      h[5][5] = DotsPlayer.player1;
      v[5][5] = DotsPlayer.player1;
      v[5][6] = DotsPlayer.player1;
      // Missing: H(6, 5)
      const finalEdge = EdgePosition.horizontal(6, 5);

      final result = engine.applyMove(
        size: size,
        horizontalEdges: h,
        verticalEdges: v,
        boxes: b,
        edge: finalEdge,
        player: DotsPlayer.player1,
      );

      expect(result.isGameOver, isTrue);
      expect(result.completedBoxes, equals([const BoxPosition(5, 5)]));
      expect(result.winner, isNotNull);
    });

    test('draw result when scores are equal at game over', () {
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      // Fill 18 boxes for player1, 17 boxes for player2, and 1 left for player2
      int countP1 = 0;

      for (int r = 0; r < size.rows; r++) {
        for (int c = 0; c < size.cols; c++) {
          if (r == 5 && c == 5) continue; // last box

          if (countP1 < 18) {
            b[r][c] = DotsPlayer.player1;
            h[r][c] = DotsPlayer.player1;
            h[r + 1][c] = DotsPlayer.player1;
            v[r][c] = DotsPlayer.player1;
            v[r][c + 1] = DotsPlayer.player1;
            countP1++;
          } else {
            b[r][c] = DotsPlayer.player2;
            h[r][c] = DotsPlayer.player2;
            h[r + 1][c] = DotsPlayer.player2;
            v[r][c] = DotsPlayer.player2;
            v[r][c + 1] = DotsPlayer.player2;
          }
        }
      }

      // Now P1 has 18, P2 has 17. Box (5,5) claimed by P2 will make it 18-18 (Draw).
      h[5][5] = DotsPlayer.player2;
      v[5][5] = DotsPlayer.player2;
      v[5][6] = DotsPlayer.player2;
      const finalEdge = EdgePosition.horizontal(6, 5);

      final result = engine.applyMove(
        size: size,
        horizontalEdges: h,
        verticalEdges: v,
        boxes: b,
        edge: finalEdge,
        player: DotsPlayer.player2,
      );

      expect(result.isGameOver, isTrue);
      expect(result.isDraw, isTrue);
      expect(result.winner, isNull);
    });
  });
}
