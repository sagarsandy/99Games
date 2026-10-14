import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_games_99/features/games/number_match/cubit/number_match_cubit.dart';
import 'package:mini_games_99/features/games/number_match/domain/number_match_storage.dart';
import 'package:mini_games_99/features/games/number_match/presentation/number_match_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SharedNumberMatchStorage storage;
  late NumberMatchCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SharedNumberMatchStorage(prefs);
    cubit = NumberMatchCubit(storage: storage, isDeterministic: true);
    await cubit.init();
  });

  tearDown(() {
    cubit.pauseTimer();
    cubit.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider.value(value: cubit, child: const NumberMatchScreen()),
    );
  }

  group('NumberMatchScreen - Widget Rendering and Interaction', () {
    testWidgets('renders title, status bar, 9-column board, and controls', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Number Match'), findsOneWidget);
      expect(find.textContaining('Score: 0'), findsOneWidget);
      expect(find.textContaining('Pairs: 0'), findsOneWidget);
      expect(find.text('Hint'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.textContaining('Add (+27)'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
    });

    testWidgets('tapping a tile selects it and updates visual styling', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find first tile (digit '1')
      final firstTileFinder = find.text('1').first;
      await tester.tap(firstTileFinder);
      await tester.pumpAndSettle();

      expect(cubit.state.selectedIndex, equals(0));
      cubit.pauseTimer();
    });

    testWidgets('tapping Hint highlights a matching pair', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hint'));
      await tester.pumpAndSettle();

      expect(cubit.state.hintPair, isNotNull);
      expect(
        find.textContaining('Hint: Here is a matching pair!'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Add Numbers appends remaining numbers', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Add (+27)'));
      await tester.pumpAndSettle();

      expect(cubit.state.tiles.length, equals(54));
      expect(
        find.textContaining('Added 27 numbers to the board.'),
        findsOneWidget,
      );
    });

    testWidgets('rules dialog opens when tapping How to Play icon', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('How to Play: Number Match'), findsOneWidget);
      expect(find.text('Got it!'), findsOneWidget);

      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();
      expect(find.text('How to Play: Number Match'), findsNothing);
    });
  });
}
