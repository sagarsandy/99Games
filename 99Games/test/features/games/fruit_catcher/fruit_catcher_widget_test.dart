import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/fruit_catcher/cubit/fruit_catcher_cubit.dart';
import 'package:mini_games_99/features/games/fruit_catcher/domain/fruit_catcher_models.dart';
import 'package:mini_games_99/features/games/fruit_catcher/domain/fruit_catcher_storage.dart';
import 'package:mini_games_99/features/games/fruit_catcher/presentation/fruit_catcher_screen.dart';
import 'package:mini_games_99/features/games/fruit_catcher/presentation/widgets/fruit_catcher_game_over_dialog.dart';
import 'package:mini_games_99/features/games/fruit_catcher/presentation/widgets/fruit_catcher_hud.dart';
import 'package:mini_games_99/features/games/fruit_catcher/presentation/widgets/fruit_catcher_start_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late FruitCatcherStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'fruit_catcher_v1_best_score': 100,
    });
    prefs = await SharedPreferences.getInstance();
    storage = SharedFruitCatcherStorage(prefs);
  });

  Widget buildTestableWidget({
    FruitCatcherCubit? cubit,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: cubit != null
          ? BlocProvider.value(value: cubit, child: const FruitCatcherScreen())
          : BlocProvider(
              create: (_) => FruitCatcherCubit(storage: storage)..loadInitial(),
              child: const FruitCatcherScreen(),
            ),
    );
  }

  group('Fruit Catcher Widget & UI Tests', () {
    testWidgets(
      '1. Start overlay renders title, best score, preview and Play button',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.byType(FruitCatcherStartOverlay), findsOneWidget);
        expect(find.text('Fruit Catcher'), findsWidgets);
        expect(
          find.text(
            'Catch juicy fruits into your basket before the 60s timer expires!',
          ),
          findsOneWidget,
        );
        expect(find.text('Best Score: 100'), findsOneWidget); // Best score
        expect(
          find.byKey(const Key('fruit_catcher_start_play_button')),
          findsOneWidget,
        );
        expect(find.byType(CustomPaint), findsWidgets);
      },
    );

    testWidgets('2. Tapping Play button starts game, displays HUD and basket', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final playBtn = find.byKey(const Key('fruit_catcher_start_play_button'));
      expect(playBtn, findsOneWidget);
      await tester.tap(playBtn);
      await tester.pump();

      // Start overlay is now gone
      expect(find.byType(FruitCatcherStartOverlay), findsNothing);

      // HUD and basket are visible
      expect(find.byType(FruitCatcherHud), findsOneWidget);
      expect(find.byKey(const Key('fruit_catcher_basket')), findsOneWidget);
      expect(find.text('Score: 0'), findsOneWidget);
      expect(find.text('Time: 60s'), findsOneWidget);
    });

    testWidgets('3. Dragging horizontally moves the basket', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cubit = FruitCatcherCubit(storage: storage);
      await tester.pumpWidget(buildTestableWidget(cubit: cubit));
      await tester.pumpAndSettle();

      // Tap Play button
      await tester.tap(
        find.byKey(const Key('fruit_catcher_start_play_button')),
      );
      await tester.pump();

      final initialBasketX = cubit.state.basket.x;

      // Drag play area gesture horizontally
      final playAreaFinder = find.byKey(
        const Key('fruit_catcher_play_area_gesture'),
      );
      expect(playAreaFinder, findsOneWidget);
      await tester.drag(playAreaFinder, const Offset(200, 0));
      await tester.pump();

      expect(cubit.state.basket.x, greaterThan(initialBasketX));
    });

    testWidgets('4. Tapping left / right area nudges the basket', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cubit = FruitCatcherCubit(storage: storage);
      await tester.pumpWidget(buildTestableWidget(cubit: cubit));
      await tester.pumpAndSettle();

      // Tap Play button
      await tester.tap(
        find.byKey(const Key('fruit_catcher_start_play_button')),
      );
      await tester.pump();

      final startX = cubit.state.basket.x;

      // Tap on left region (< 40% of 800 is < 320)
      await tester.tapAt(const Offset(100, 600));
      await tester.pump();
      expect(cubit.state.basket.x, lessThan(startX));

      // Tap on right region (> 60% of 800 is > 480)
      await tester.tapAt(const Offset(700, 600));
      await tester.pump();
      expect(cubit.state.basket.x, greaterThan(startX - 0.08));
    });

    testWidgets(
      '5. Game Over overlay renders final score, record indicator, and Play Again button',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final cubit = FruitCatcherCubit(storage: storage);
        await tester.pumpWidget(buildTestableWidget(cubit: cubit));
        await tester.pumpAndSettle();

        // Trigger game over with new high score
        cubit.emit(
          cubit.state.copyWith(
            status: GameStatus.gameOver,
            score: 180,
            bestScore: 180,
            isNewRecord: true,
            timeRemaining: 0.0,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FruitCatcherGameOverDialog), findsOneWidget);
        expect(find.text('Game Over'), findsOneWidget);
        expect(
          find.text("Time's up! Great effort catching fruits!"),
          findsOneWidget,
        );
        expect(find.text('NEW BEST RECORD!'), findsOneWidget);
        expect(find.text('180'), findsWidgets);
        expect(
          find.byKey(const Key('fruit_catcher_play_again_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('fruit_catcher_back_to_games_button')),
          findsOneWidget,
        );

        // Tap Play Again
        await tester.tap(
          find.byKey(const Key('fruit_catcher_play_again_button')),
        );
        await tester.pump();

        expect(cubit.state.status, equals(GameStatus.playing));
        expect(cubit.state.score, equals(0));
        expect(cubit.state.bestScore, equals(180));
      },
    );

    testWidgets(
      '6. Screen fits ultra-narrow compact display (320x568) without overflow',
      (tester) async {
        // iPhone SE (1st gen) compact dimensions
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // Ensure no overflow on start screen
        expect(tester.takeException(), isNull);
        expect(find.byType(FruitCatcherStartOverlay), findsOneWidget);

        // Start game
        await tester.tap(
          find.byKey(const Key('fruit_catcher_start_play_button')),
        );
        await tester.pump();

        // Ensure no overflow on gameplay screen
        expect(tester.takeException(), isNull);
        expect(find.byType(FruitCatcherHud), findsOneWidget);
      },
    );

    testWidgets('7. Disposing screen cleans up resources safely', (
      tester,
    ) async {
      final cubit = FruitCatcherCubit(storage: storage);

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));
      await tester.pumpAndSettle();

      cubit.startGame();
      await tester.pump();

      // Replace widget to trigger dispose()
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Disposed'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Disposed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
