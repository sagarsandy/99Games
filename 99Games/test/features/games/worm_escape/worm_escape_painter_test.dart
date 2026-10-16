import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_engine.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_models.dart';
import 'package:mini_games_99/features/games/worm_escape/presentation/painters/worm_escape_board_painter.dart';

void main() {
  group('WormEscapeBoardPainter Tests', () {
    late WormEscapeLevel multiDirectionLevel;

    setUp(() {
      // Create a level with worms facing all 4 directions: UP, DOWN, LEFT, RIGHT
      multiDirectionLevel = const WormEscapeLevel(
        id: 'test_painter',
        difficulty: WormEscapeDifficulty.easy,
        levelNumber: 1,
        boardSize: 6,
        worms: [
          // 1. Vertical Up worm
          Worm(
            id: 'w_up',
            body: [GridPosition(0, 1), GridPosition(1, 1), GridPosition(2, 1)],
            direction: WormDirection.up,
            colorIndex: 0,
          ),
          // 2. Vertical Down worm
          Worm(
            id: 'w_down',
            body: [GridPosition(5, 4), GridPosition(4, 4), GridPosition(3, 4)],
            direction: WormDirection.down,
            colorIndex: 1,
          ),
          // 3. Horizontal Left worm
          Worm(
            id: 'w_left',
            body: [GridPosition(4, 0), GridPosition(4, 1), GridPosition(4, 2)],
            direction: WormDirection.left,
            colorIndex: 2,
          ),
          // 4. Horizontal Right worm
          Worm(
            id: 'w_right',
            body: [GridPosition(1, 5), GridPosition(1, 4), GridPosition(1, 3)],
            direction: WormDirection.right,
            colorIndex: 3,
          ),
        ],
        referenceSolution: ['w_up', 'w_down', 'w_left', 'w_right'],
      );
    });

    testWidgets('Painter paints without errors for light and dark modes', (
      tester,
    ) async {
      final engine = WormEscapeEngine.initial(multiDirectionLevel);

      // Light mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(300, 300),
              painter: WormEscapeBoardPainter(engine: engine, isDark: false),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);

      // Dark mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(300, 300),
              painter: WormEscapeBoardPainter(engine: engine, isDark: true),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Painter paints escape animation frames and blocked feedback', (
      tester,
    ) async {
      final engine = WormEscapeEngine.initial(multiDirectionLevel);

      // Frame during escape animation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(300, 300),
              painter: WormEscapeBoardPainter(
                engine: engine,
                isDark: false,
                animatingWormId: 'w_up',
                escapeProgress: 0.5,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);

      // Frame during blocked warning & shake
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(300, 300),
              painter: WormEscapeBoardPainter(
                engine: engine,
                isDark: false,
                blockedWormId: 'w_left',
                blockingWormId: 'w_up',
                blockedProgress: 0.7,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);

      // Frame during hint pulsating
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(300, 300),
              painter: WormEscapeBoardPainter(
                engine: engine,
                isDark: true,
                hintWormId: 'w_down',
                hintPulse: 0.8,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('shouldRepaint returns true when animation progresses', () {
      final engine = WormEscapeEngine.initial(multiDirectionLevel);

      final p1 = WormEscapeBoardPainter(
        engine: engine,
        isDark: false,
        escapeProgress: 0.2,
      );

      final p2 = WormEscapeBoardPainter(
        engine: engine,
        isDark: false,
        escapeProgress: 0.4,
      );

      expect(p1.shouldRepaint(p2), isTrue);
    });
  });
}
