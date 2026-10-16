import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/app/app.dart';
import 'package:mini_games_99/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  testWidgets(
    'App launches to Home screen, navigates to Block Puzzle, Number Slide, Tic-Tac-Toe and back',
    (tester) async {
      await tester.pumpWidget(const NinetyNineGamesApp());
      await tester.pumpAndSettle();

      // Verify Home Screen elements
      expect(find.text('99 Mini Games'), findsOneWidget);
      expect(find.text('Tic-Tac-Toe'), findsOneWidget);
      expect(find.text('Number Slide'), findsOneWidget);
      expect(find.text('Block Puzzle'), findsOneWidget);

      // 1. Navigate to Block Puzzle
      await tester.tap(find.text('Block Puzzle'));
      await tester.pumpAndSettle();

      // Verify Block Puzzle screen elements
      expect(find.text('Block Puzzle'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
      expect(find.text('Best'), findsOneWidget);
      expect(find.text('New Game'), findsWidgets);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // 2. Navigate to Number Slide
      await tester.tap(find.text('Number Slide'));
      await tester.pumpAndSettle();

      // Verify Number Slide screen opened
      expect(find.text('Moves'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('New Game'), findsWidgets);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);
      expect(find.text('Number Slide'), findsOneWidget);

      // 3. Navigate to Tic-Tac-Toe
      await tester.tap(find.text('Tic-Tac-Toe'));
      await tester.pumpAndSettle();

      // Verify Tic-Tac-Toe screen opened
      expect(find.text('vs Computer'), findsOneWidget);
      expect(find.text('2 Players'), findsOneWidget);
      expect(find.text('Restart Board'), findsOneWidget);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // 4. Navigate to Word Search
      await tester.tap(find.text('Word Search'));
      await tester.pumpAndSettle();

      // Verify Word Search screen opened
      expect(find.text('Word Search'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Words to Find'), findsOneWidget);
      expect(find.text('New Puzzle'), findsWidgets);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);
      expect(find.text('Word Search'), findsOneWidget);
      expect(find.text('Dots and Boxes'), findsOneWidget);

      // 5. Navigate to Dots and Boxes
      await tester.tap(find.text('Dots and Boxes'));
      await tester.pumpAndSettle();

      // Verify Dots and Boxes screen opened
      expect(find.text('Dots and Boxes'), findsWidgets);
      expect(find.text('BOARD SIZE (BOXES)'), findsOneWidget);
      expect(find.text('New Game'), findsWidgets);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);
      expect(find.text('Dots and Boxes'), findsOneWidget);
      expect(find.text('Sudoku'), findsOneWidget);

      // 6. Navigate to Sudoku
      await tester.tap(find.text('Sudoku'));
      await tester.pumpAndSettle();

      // Verify Sudoku screen opened
      expect(find.text('Sudoku'), findsWidgets);
      expect(find.text('Mistakes: 0 / 3'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Hint'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Erase'), findsOneWidget);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);
      expect(find.text('Sudoku'), findsOneWidget);

      // 7. Scroll and Navigate to Number Match
      await tester.scrollUntilVisible(
        find.text('Number Match'),
        200,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Number Match'), findsOneWidget);

      await tester.tap(find.text('Number Match'));
      await tester.pumpAndSettle();

      // Verify Number Match screen opened
      expect(find.text('Number Match'), findsWidgets);
      expect(find.textContaining('Score: 0'), findsOneWidget);
      expect(find.textContaining('Pairs: 0'), findsOneWidget);
      expect(find.text('Hint'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.textContaining('Add (+'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);

      // 8. Scroll and Navigate to Reaction Test
      await tester.scrollUntilVisible(
        find.text('Reaction Test'),
        200,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reaction Test'), findsOneWidget);

      await tester.tap(find.text('Reaction Test'));
      await tester.pumpAndSettle();

      // Verify Reaction Test screen opened
      expect(find.text('Reaction Test'), findsWidgets);
      expect(
        find.text('Wait for green, then tap as quickly as possible.'),
        findsOneWidget,
      );
      expect(find.text('Start Game'), findsOneWidget);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);

      // 9. Scroll and Navigate to Emoji Connect
      await tester.scrollUntilVisible(
        find.text('Emoji Connect'),
        200,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Emoji Connect'), findsOneWidget);

      await tester.tap(find.text('Emoji Connect'));
      await tester.pumpAndSettle();

      // Verify Emoji Connect screen opened
      expect(find.text('Emoji Connect'), findsWidgets);
      expect(find.text('Pairs Connected'), findsOneWidget);
      expect(find.text('Board Flow'), findsOneWidget);
      expect(find.text('Hint'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);

      // 10. Scroll and Navigate to Worm Escape
      await tester.scrollUntilVisible(
        find.text('Worm Escape'),
        200,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Worm Escape'), findsOneWidget);

      await tester.tap(find.text('Worm Escape'));
      await tester.pumpAndSettle();

      // Verify Worm Escape screen opened
      expect(find.text('Worm Escape'), findsWidgets);
      expect(find.text('Escaped'), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);
      expect(find.text('Hint'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);

      // 11. Scroll and Navigate to Fish Family Rescue
      await tester.scrollUntilVisible(
        find.text('Fish Family Rescue'),
        200,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fish Family Rescue'), findsOneWidget);

      await tester.tap(find.text('Fish Family Rescue'));
      await tester.pumpAndSettle();

      // Verify Fish Family Rescue screen opened
      expect(find.text('Fish Family Rescue'), findsWidgets);
      expect(find.text('Baby Coral Reef'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
      expect(find.text('Moves: 0'), findsOneWidget);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);

      // 12. Scroll and Navigate to Word Circle
      await tester.scrollUntilVisible(
        find.text('Word Circle'),
        200,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Word Circle'), findsOneWidget);

      await tester.tap(find.text('Word Circle'));
      await tester.pumpAndSettle();

      // Verify Word Circle screen opened
      expect(find.text('Word Circle'), findsWidgets);
      expect(find.textContaining('Level 1'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Hint'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);

      // 13. Scroll and Navigate to Fruit Catcher
      await tester.scrollUntilVisible(
        find.text('Fruit Catcher'),
        200,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fruit Catcher'), findsOneWidget);

      await tester.tap(find.text('Fruit Catcher'));
      await tester.pumpAndSettle();

      // Verify Fruit Catcher screen opened
      expect(find.text('Fruit Catcher'), findsWidgets);
      expect(
        find.byKey(const Key('fruit_catcher_start_play_button')),
        findsOneWidget,
      );

      // Return to Home
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();

      // Verify back on Home
      expect(find.text('99 Mini Games'), findsOneWidget);
    },
  );
}
