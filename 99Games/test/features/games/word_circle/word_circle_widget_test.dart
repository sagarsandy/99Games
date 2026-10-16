import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/word_circle/cubit/word_circle_cubit.dart';
import 'package:mini_games_99/features/games/word_circle/domain/word_circle_storage.dart';
import 'package:mini_games_99/features/games/word_circle/presentation/painters/word_circle_path_painter.dart';
import 'package:mini_games_99/features/games/word_circle/presentation/widgets/word_circle_controls.dart';
import 'package:mini_games_99/features/games/word_circle/presentation/widgets/word_circle_crossword.dart';
import 'package:mini_games_99/features/games/word_circle/presentation/widgets/word_circle_level_header.dart';
import 'package:mini_games_99/features/games/word_circle/presentation/widgets/word_circle_wheel.dart';
import 'package:mini_games_99/features/games/word_circle/presentation/word_circle_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late WordCircleStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SharedWordCircleStorage(prefs);
  });

  Widget buildTestableWidget({
    WordCircleCubit? cubit,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: BlocProvider(
        create: (_) => cubit ?? WordCircleCubit(storage: storage),
        child: const WordCircleScreen(),
      ),
    );
  }

  group('WordCircle Widget Tests', () {
    testWidgets(
      'WordCircleScreen renders header, crossword grid, letter wheel, and bottom controls',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // 1. Header elements
        expect(find.byType(WordCircleLevelHeader), findsOneWidget);
        expect(find.text('Word Circle'), findsOneWidget);
        expect(find.textContaining('Level 1'), findsOneWidget);
        expect(find.text('Words: 0 / 2'), findsOneWidget);

        // 2. Crossword target grid
        expect(find.byType(WordCircleCrossword), findsOneWidget);

        // 3. Letter wheel with CustomPainter
        expect(find.byType(WordCircleWheel), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is WordCirclePathPainter,
          ),
          findsOneWidget,
        );

        // Letters A, C, T for Level 1
        expect(find.text('A'), findsOneWidget);
        expect(find.text('C'), findsOneWidget);
        expect(find.text('T'), findsOneWidget);

        // 4. Bottom controls
        expect(find.byType(WordCircleControls), findsOneWidget);
        expect(find.text('Shuffle'), findsOneWidget);
        expect(find.text('Hint'), findsOneWidget);
        expect(find.text('Clear'), findsOneWidget);
        expect(find.text('Restart'), findsOneWidget);
      },
    );

    testWidgets(
      'Dragging across letters C-A-T submits word and reveals cells in crossword',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        final cPos = tester.getCenter(find.text('C'));
        final aPos = tester.getCenter(find.text('A'));
        final tPos = tester.getCenter(find.text('T'));

        // Start drag at C
        final gesture = await tester.startGesture(cPos);
        await tester.pump();

        // Move to A
        await gesture.moveTo(aPos);
        await tester.pump();

        // Move to T
        await gesture.moveTo(tPos);
        await tester.pump();

        // Release drag to submit CAT
        await gesture.up();
        await tester.pumpAndSettle();

        // Crossword should now have CAT revealed and Words 1/2 in header
        expect(find.text('Words: 1 / 2'), findsOneWidget);
        expect(find.text('Score: 30'), findsOneWidget);
      },
    );

    testWidgets('Dragging invalid word displays feedback message', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final tPos = tester.getCenter(find.text('T'));
      final aPos = tester.getCenter(find.text('A'));
      final cPos = tester.getCenter(find.text('C'));

      // Drag T -> A -> C -> TAC is not in dictionary
      final gesture = await tester.startGesture(tPos);
      await tester.pump();
      await gesture.moveTo(aPos);
      await tester.pump();
      await gesture.moveTo(cPos);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Check feedback message
      expect(find.text('Not in word list'), findsOneWidget);
      expect(find.text('Words: 0 / 2'), findsOneWidget);
    });

    testWidgets('Hint button reveals an undiscovered crossword cell', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hint'));
      await tester.pumpAndSettle();

      expect(find.text('Letter revealed!'), findsOneWidget);
    });

    testWidgets('Shuffle button rearranges letters on the wheel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shuffle'));
      await tester.pumpAndSettle();

      // Letters are still rendered
      expect(find.text('A'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets(
      'Restart button shows confirmation dialog and resets level on confirm',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // Form CAT first
        final cPos = tester.getCenter(find.text('C'));
        final aPos = tester.getCenter(find.text('A'));
        final tPos = tester.getCenter(find.text('T'));

        final gesture = await tester.startGesture(cPos);
        await gesture.moveTo(aPos);
        await gesture.moveTo(tPos);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('Words: 1 / 2'), findsOneWidget);

        // Tap restart
        await tester.tap(find.text('Restart'));
        await tester.pumpAndSettle();

        // Confirm dialog shows
        expect(find.text('Restart Level?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Tap Confirm Restart
        final restartButton = find.widgetWithText(FilledButton, 'Restart');
        await tester.tap(restartButton);
        await tester.pumpAndSettle();

        // Words reset to 0/2
        expect(find.text('Words: 0 / 2'), findsOneWidget);
        expect(find.text('Score: 0'), findsOneWidget);
      },
    );

    testWidgets('Completing all target words presents victory dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cubit = WordCircleCubit(storage: storage);
      await tester.pumpWidget(buildTestableWidget(cubit: cubit));
      await tester.pumpAndSettle();

      final cPos = tester.getCenter(find.text('C'));
      final aPos = tester.getCenter(find.text('A'));
      final tPos = tester.getCenter(find.text('T'));

      // 1. Submit CAT
      var gesture = await tester.startGesture(cPos);
      await gesture.moveTo(aPos);
      await gesture.moveTo(tPos);
      await gesture.up();
      await tester.pumpAndSettle();

      // 2. Submit ACT
      gesture = await tester.startGesture(aPos);
      await gesture.moveTo(cPos);
      await gesture.moveTo(tPos);
      await gesture.up();
      await tester.pumpAndSettle();

      // Check state
      expect(cubit.state.foundTargetWords, containsAll(['CAT', 'ACT']));
      expect(cubit.state.isWon, isTrue);

      // Win dialog should appear!
      expect(find.text('Level Complete!'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Replay'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets(
      'Responsive layout renders without overflow on compact screen (320x568)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // Zero overflow
        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW DETAILS:\n${err.toStringDeep()}');
        }
        expect(err, isNull);
        expect(find.text('Word Circle'), findsOneWidget);
        expect(find.byType(WordCircleCrossword), findsOneWidget);
        expect(find.byType(WordCircleWheel), findsOneWidget);
        expect(find.byType(WordCircleControls), findsOneWidget);
      },
    );

    testWidgets('Rules dialog opens when info button in header is tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('How to Play'), findsOneWidget);
      expect(find.text('Got it!'), findsOneWidget);

      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();
    });
  });
}
