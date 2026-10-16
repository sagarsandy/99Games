import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/emoji_connect/cubit/emoji_connect_cubit.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_storage.dart';
import 'package:mini_games_99/features/games/emoji_connect/presentation/emoji_connect_screen.dart';
import 'package:mini_games_99/features/games/emoji_connect/presentation/widgets/emoji_connect_board.dart';
import 'package:mini_games_99/features/games/emoji_connect/presentation/widgets/emoji_connect_cell.dart';
import 'package:mini_games_99/features/games/emoji_connect/presentation/widgets/emoji_connect_controls.dart';
import 'package:mini_games_99/features/games/emoji_connect/presentation/widgets/emoji_connect_level_header.dart';
import 'package:mini_games_99/features/games/emoji_connect/presentation/widgets/emoji_connect_results_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EmojiConnect Widget Tests', () {
    late SharedEmojiConnectStorage storage;
    late EmojiConnectCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = SharedEmojiConnectStorage(prefs);
      cubit = EmojiConnectCubit(storage: storage, enableTimer: false);
      // Wait for async init
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() async {
      await cubit.close();
    });

    Widget buildTestableWidget() {
      return MaterialApp(
        home: BlocProvider<EmojiConnectCubit>.value(
          value: cubit,
          child: const EmojiConnectScreen(),
        ),
      );
    }

    testWidgets('EmojiConnectScreen renders header, board, and controls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.byType(EmojiConnectLevelHeader), findsOneWidget);
      expect(find.text('Emoji Connect'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Med'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Pairs Connected'), findsOneWidget);
      expect(find.text('Board Flow'), findsOneWidget);

      // Verify Board
      expect(find.byType(EmojiConnectBoard), findsOneWidget);
      expect(
        find.byType(EmojiConnectCell),
        findsNWidgets(25),
      ); // 5x5 = 25 cells

      // Check emojis for endpoints
      for (final pair in cubit.state.engine.level.pairs) {
        expect(find.text(pair.emoji), findsAtLeastNWidgets(2));
      }

      // Verify Controls
      expect(find.byType(EmojiConnectControls), findsOneWidget);
      expect(find.text('Hint'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('Tapping How to Play displays instructions dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('How to Play'));
      await tester.pumpAndSettle();

      expect(find.text('How to Play'), findsOneWidget);
      expect(
        find.textContaining('Drag between matching emojis'),
        findsOneWidget,
      );

      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();
      expect(find.text('How to Play'), findsNothing);
    });

    testWidgets('Tapping Level chip opens level picker bottom sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Level 1'));
      await tester.pumpAndSettle();

      expect(find.text('Easy Levels'), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      // Close bottom sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping Hint requests and applies a hint', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(cubit.state.coveredCells, equals(0));

      await tester.tap(find.text('Hint'));
      await tester.pumpAndSettle();

      expect(cubit.state.coveredCells, greaterThan(0));
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Tapping Reset shows confirmation dialog and clears board', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Add a path directly via cubit so no SnackBar is shown
      final pair = cubit.state.engine.level.pairs[0];
      final ref = cubit.state.engine.level.referenceSolution[pair.id]!;
      cubit.startDrag(ref[0]);
      cubit.updateDrag(ref[1]);
      await cubit.endDrag();
      await tester.pumpAndSettle();

      expect(cubit.state.coveredCells, greaterThan(0));

      // Tap Reset button
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Level?'), findsOneWidget);
      expect(
        find.text('All your drawn paths for this level will be cleared.'),
        findsOneWidget,
      );

      // Confirm Reset
      await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      await tester.pumpAndSettle();

      expect(cubit.state.coveredCells, equals(0));
    });

    testWidgets(
      'Completing puzzle allows viewing completed board and reopening results dialog',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // Solve the board using reference solution
        final ref = cubit.state.engine.level.referenceSolution;
        for (final pair in cubit.state.engine.level.pairs) {
          final pts = ref[pair.id]!;
          cubit.startDrag(pts[0]);
          for (int i = 1; i < pts.length; i++) {
            cubit.updateDrag(pts[i]);
          }
          await cubit.endDrag();
        }

        await tester.pumpAndSettle();

        // 1. Verify victory dialog is automatically presented
        expect(find.byType(EmojiConnectResultsDialog), findsOneWidget);
        expect(find.text('Puzzle Solved!'), findsOneWidget);
        expect(find.text('100%'), findsWidgets);
        expect(
          find.descendant(
            of: find.byType(EmojiConnectResultsDialog),
            matching: find.text('Next Level'),
          ),
          findsOneWidget,
        );
        expect(find.text('View Board'), findsOneWidget);
        expect(find.text('Play Again'), findsOneWidget);

        // 2. Tap "View Board" to dismiss the dialog and view completed board
        await tester.tap(find.text('View Board'));
        await tester.pumpAndSettle();

        // Results dialog should be gone, but completed board visible
        expect(find.byType(EmojiConnectResultsDialog), findsNothing);
        expect(find.text('Level Completed! (100% Flow)'), findsOneWidget);
        expect(find.text('View Stats'), findsOneWidget);
        expect(cubit.state.coveredCells, equals(25));
        expect(cubit.state.isWon, isTrue);

        // Controls bar displays Replay, Results, and Next Level
        expect(find.text('Replay'), findsOneWidget);
        expect(find.text('Results'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(EmojiConnectControls),
            matching: find.text('Next Level'),
          ),
          findsOneWidget,
        );

        // 3. Tap "Results" button to reopen the dialog
        await tester.tap(find.text('Results'));
        await tester.pumpAndSettle();
        expect(find.byType(EmojiConnectResultsDialog), findsOneWidget);

        // 4. Tap the close 'X' button to dismiss dialog back to completed board
        await tester.tap(find.byTooltip('Close and View Board'));
        await tester.pumpAndSettle();
        expect(find.byType(EmojiConnectResultsDialog), findsNothing);
        expect(find.text('Level Completed! (100% Flow)'), findsOneWidget);

        // 5. Tap "View Stats" chip to reopen the dialog again
        await tester.tap(find.text('View Stats'));
        await tester.pumpAndSettle();
        expect(find.byType(EmojiConnectResultsDialog), findsOneWidget);

        // 6. Advance to Next Level from dialog
        await tester.tap(
          find.descendant(
            of: find.byType(EmojiConnectResultsDialog),
            matching: find.text('Next Level'),
          ),
        );
        await tester.pumpAndSettle();

        // Now on Level 2 with cleared board
        expect(find.byType(EmojiConnectResultsDialog), findsNothing);
        expect(find.text('Level 2'), findsOneWidget);
        expect(cubit.state.coveredCells, equals(0));
        expect(cubit.state.isWon, isFalse);
      },
    );
  });
}
