import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/worm_escape/cubit/worm_escape_cubit.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_storage.dart';
import 'package:mini_games_99/features/games/worm_escape/presentation/widgets/worm_escape_board.dart';
import 'package:mini_games_99/features/games/worm_escape/presentation/widgets/worm_escape_controls.dart';
import 'package:mini_games_99/features/games/worm_escape/presentation/widgets/worm_escape_level_header.dart';
import 'package:mini_games_99/features/games/worm_escape/presentation/widgets/worm_escape_results_dialog.dart';
import 'package:mini_games_99/features/games/worm_escape/presentation/worm_escape_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WormEscape Widget Tests', () {
    late SharedWormEscapeStorage storage;
    late WormEscapeCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = SharedWormEscapeStorage(prefs);
      cubit = WormEscapeCubit(storage: storage);
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });

    tearDown(() async {
      await cubit.close();
    });

    Widget buildTestableWidget() {
      return MaterialApp(
        home: BlocProvider<WormEscapeCubit>.value(
          value: cubit,
          child: const WormEscapeScreen(),
        ),
      );
    }

    testWidgets('WormEscapeScreen renders header, board, and controls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.byType(WormEscapeLevelHeader), findsOneWidget);
      expect(find.text('Worm Escape'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Med'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Escaped'), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);

      // Verify Board
      expect(find.byType(WormEscapeBoard), findsOneWidget);

      // Verify Controls
      expect(find.byType(WormEscapeControls), findsOneWidget);
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
        find.textContaining('Help all worms escape the grid!'),
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

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping Hint displays hint message', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(cubit.state.hintWormId, isNull);

      await tester.tap(find.text('Hint'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(cubit.state.hintWormId, isNotNull);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
      'Completing puzzle displays results dialog, allows viewing completed board, and reopening results',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // Solve level through cubit
        final ref = cubit.state.engine.level.referenceSolution;
        for (final id in ref) {
          final worm = cubit.state.engine.worms[id]!;
          cubit.tapWormAtCell(worm.head);
          await cubit.onEscapeAnimationCompleted(id);
        }

        await tester.pumpAndSettle();

        // 1. Victory dialog appears
        expect(find.byType(WormEscapeResultsDialog), findsOneWidget);
        expect(find.text('All Worms Escaped!'), findsOneWidget);
        expect(find.text('View Board'), findsOneWidget);
        expect(find.text('Play Again'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(WormEscapeResultsDialog),
            matching: find.text('Next Level'),
          ),
          findsOneWidget,
        );

        // 2. Tap "View Board" to dismiss dialog and admire completed board
        await tester.tap(find.text('View Board'));
        await tester.pumpAndSettle();

        expect(find.byType(WormEscapeResultsDialog), findsNothing);
        expect(find.text('All Worms Escaped! 🐛'), findsOneWidget);
        expect(find.text('View Stats'), findsOneWidget);
        expect(find.text('Replay'), findsOneWidget);
        expect(find.text('Results'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(WormEscapeControls),
            matching: find.text('Next Level'),
          ),
          findsOneWidget,
        );

        // 3. Tap "Results" to reopen dialog
        await tester.tap(find.text('Results'));
        await tester.pumpAndSettle();
        expect(find.byType(WormEscapeResultsDialog), findsOneWidget);

        // 4. Tap close 'X' to close again
        await tester.tap(find.byTooltip('Close and View Board'));
        await tester.pumpAndSettle();
        expect(find.byType(WormEscapeResultsDialog), findsNothing);

        // 5. Tap "View Stats" in top banner to reopen
        await tester.tap(find.text('View Stats'));
        await tester.pumpAndSettle();
        expect(find.byType(WormEscapeResultsDialog), findsOneWidget);

        // 6. Tap "Next Level" to proceed to Level 2
        await tester.tap(
          find.descendant(
            of: find.byType(WormEscapeResultsDialog),
            matching: find.text('Next Level'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WormEscapeResultsDialog), findsNothing);
        expect(find.text('Level 2'), findsOneWidget);
        expect(cubit.state.levelNumber, equals(2));
        expect(cubit.state.isWon, isFalse);
      },
    );
  });
}
