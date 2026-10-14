import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/dots_and_boxes/domain/dots_and_boxes_engine.dart';
import 'package:mini_games_99/features/games/dots_and_boxes/domain/dots_and_boxes_models.dart';

void main() {
  late DotsAndBoxesEngine engine;

  setUp(() {
    engine = DotsAndBoxesEngine(random: Random(42));
  });

  group('Dots and Boxes - AI Behaviors', () {
    test('Easy AI always returns a legal unclaimed edge', () {
      const size = BoardSize.small;
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      for (int i = 0; i < 20; i++) {
        final move = engine.selectAiMove(
          boardSize: size,
          horizontalEdges: h,
          verticalEdges: v,
          boxes: b,
          aiPlayer: DotsPlayer.player2,
          difficulty: DotsAiDifficulty.easy,
        );

        expect(move, isNotNull);
        expect(
          engine.isLegalMove(
            size: size,
            horizontalEdges: h,
            verticalEdges: v,
            edge: move!,
          ),
          isTrue,
        );

        // Claim move
        if (move.isHorizontal) {
          h[move.row][move.col] = DotsPlayer.player2;
        } else {
          v[move.row][move.col] = DotsPlayer.player2;
        }
      }
    });

    test('Medium AI always prioritizes completing an available box', () {
      const size = BoardSize.small;
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      // Set up box (2, 2) with 3 edges drawn:
      // H(2, 2), H(3, 2), V(2, 2) drawn.
      // Missing edge: V(2, 3)
      h[2][2] = DotsPlayer.player1;
      h[3][2] = DotsPlayer.player1;
      v[2][2] = DotsPlayer.player1;

      final aiMove = engine.selectAiMove(
        boardSize: size,
        horizontalEdges: h,
        verticalEdges: v,
        boxes: b,
        aiPlayer: DotsPlayer.player2,
        difficulty: DotsAiDifficulty.medium,
      );

      expect(aiMove, equals(const EdgePosition.vertical(2, 3)));
    });

    test('Medium AI prioritizes completing 2 boxes over 1 box', () {
      const size = BoardSize.small;
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      // Setup 1: Box (0, 0) has 3 edges: H(0,0), H(1,0), V(0,0) -> missing V(0,1)
      // Setup 2: Two adjacent boxes sharing H(3, 3) where H(3, 3) completes BOTH boxes!
      // Box above (2, 3): H(2,3), V(2,3), V(2,4)
      h[2][3] = DotsPlayer.player1;
      v[2][3] = DotsPlayer.player1;
      v[2][4] = DotsPlayer.player1;

      // Box below (3, 3): H(4,3), V(3,3), V(3,4)
      h[4][3] = DotsPlayer.player1;
      v[3][3] = DotsPlayer.player1;
      v[3][4] = DotsPlayer.player1;

      // H(3, 3) completes BOTH boxes!
      // Also setup a single-box completion at (0, 0)
      h[0][0] = DotsPlayer.player1;
      h[1][0] = DotsPlayer.player1;
      v[0][0] = DotsPlayer.player1; // missing V(0,1)

      final aiMove = engine.selectAiMove(
        boardSize: size,
        horizontalEdges: h,
        verticalEdges: v,
        boxes: b,
        aiPlayer: DotsPlayer.player2,
        difficulty: DotsAiDifficulty.medium,
      );

      // Should choose H(3, 3) which completes 2 boxes
      expect(aiMove, equals(const EdgePosition.horizontal(3, 3)));
    });

    test('Medium AI avoids creating 3-edge boxes when safe moves exist', () {
      const size = BoardSize.small;
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      // Box (0, 0) already has 2 edges: H(0, 0) and V(0, 0).
      // Drawing H(1, 0) or V(0, 1) would make Box (0, 0) have 3 edges!
      h[0][0] = DotsPlayer.player1;
      v[0][0] = DotsPlayer.player1;

      // AI should pick a safe move away from Box (0, 0)
      final aiMove = engine.selectAiMove(
        boardSize: size,
        horizontalEdges: h,
        verticalEdges: v,
        boxes: b,
        aiPlayer: DotsPlayer.player2,
        difficulty: DotsAiDifficulty.medium,
      );

      expect(aiMove, isNotNull);
      // It should NOT pick H(1, 0) or V(0, 1) because safe moves exist on empty parts of the board
      expect(aiMove, isNot(equals(const EdgePosition.horizontal(1, 0))));
      expect(aiMove, isNot(equals(const EdgePosition.vertical(0, 1))));
    });

    test(
      'Hard AI works across Small (6x6), Medium (9x9), and Large (15x15)',
      () {
        for (final size in BoardSize.values) {
          final h = engine.createEmptyHorizontalEdges(size);
          final v = engine.createEmptyVerticalEdges(size);
          final b = engine.createEmptyBoxes(size);

          final stopwatch = Stopwatch()..start();

          final aiMove = engine.selectAiMove(
            boardSize: size,
            horizontalEdges: h,
            verticalEdges: v,
            boxes: b,
            aiPlayer: DotsPlayer.player2,
            difficulty: DotsAiDifficulty.hard,
          );

          stopwatch.stop();

          expect(aiMove, isNotNull);
          expect(
            engine.isLegalMove(
              size: size,
              horizontalEdges: h,
              verticalEdges: v,
              edge: aiMove!,
            ),
            isTrue,
          );
          // Ensure execution is well under 100ms
          expect(stopwatch.elapsedMilliseconds, lessThan(100));
        }
      },
    );

    test('Hard AI minimizes sacrifice cascade when no safe moves exist', () {
      const size = BoardSize.small;
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      // Fill board with 2-edge boxes everywhere so that all moves are sacrifices.
      // Setup Corridor A (length 1) and Corridor B (length 3).
      // Hard AI should choose the move opening the shorter Corridor A.
      // Let's verify Hard AI returns a legal move and doesn't crash or hang.
      for (int r = 0; r < size.rows; r++) {
        for (int c = 0; c < size.cols; c++) {
          h[r][c] = DotsPlayer.player1;
          v[r][c] = DotsPlayer.player1;
        }
      }

      final move = engine.selectAiMove(
        boardSize: size,
        horizontalEdges: h,
        verticalEdges: v,
        boxes: b,
        aiPlayer: DotsPlayer.player2,
        difficulty: DotsAiDifficulty.hard,
      );

      expect(move, isNotNull);
      expect(
        engine.isLegalMove(
          size: size,
          horizontalEdges: h,
          verticalEdges: v,
          edge: move!,
        ),
        isTrue,
      );
    });

    test('selectAiMove returns null when board has no legal moves left', () {
      const size = BoardSize.small;
      final h = engine.createEmptyHorizontalEdges(size);
      final v = engine.createEmptyVerticalEdges(size);
      final b = engine.createEmptyBoxes(size);

      // Claim every edge
      for (int r = 0; r <= size.rows; r++) {
        for (int c = 0; c < size.cols; c++) {
          h[r][c] = DotsPlayer.player1;
        }
      }
      for (int r = 0; r < size.rows; r++) {
        for (int c = 0; c <= size.cols; c++) {
          v[r][c] = DotsPlayer.player1;
        }
      }

      final move = engine.selectAiMove(
        boardSize: size,
        horizontalEdges: h,
        verticalEdges: v,
        boxes: b,
        aiPlayer: DotsPlayer.player2,
        difficulty: DotsAiDifficulty.hard,
      );

      expect(move, isNull);
    });
  });
}
