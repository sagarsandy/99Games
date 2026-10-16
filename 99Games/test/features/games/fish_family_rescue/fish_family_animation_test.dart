import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/cubit/fish_family_cubit.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/domain/fish_family_storage.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/presentation/fish_family_screen.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/presentation/widgets/animated_swimming_fish.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late FishFamilyStorage storage;
  late FishFamilyCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SharedFishFamilyStorage(prefs);
    cubit = FishFamilyCubit(storage: storage);
    await cubit.loadInitial();
  });

  tearDown(() {
    cubit.close();
  });

  Widget buildTestableScreen() {
    return MaterialApp(
      home: BlocProvider<FishFamilyCubit>.value(
        value: cubit,
        child: const FishFamilyScreen(enableAmbientAnimation: false),
      ),
    );
  }

  group('FishTrajectory Geometry & Physics Tests', () {
    test(
      'Trajectory correctly determines direction, arc peak, and endpoints',
      () {
        const start = Offset(100, 300);
        const end = Offset(300, 300);

        final traj = FishTrajectory.calculate(
          start: start,
          end: end,
          minBoardY: 10.0,
        );

        expect(traj.facingRight, isTrue);
        expect(traj.distance, equals(200.0));

        // Control points must be significantly higher (lower y) than start and end
        expect(traj.p1.dy, lessThan(start.dy));
        expect(traj.p2.dy, lessThan(end.dy));

        // At t = 0.0, position matches start (before bobbing)
        final pos0 = traj.positionAt(0.0);
        expect((pos0.dx - start.dx).abs(), lessThan(0.01));
        expect((pos0.dy - start.dy).abs(), lessThan(0.01));

        // At t = 1.0, position matches end (before bobbing)
        final pos1 = traj.positionAt(1.0);
        expect((pos1.dx - end.dx).abs(), lessThan(0.01));
        expect((pos1.dy - end.dy).abs(), lessThan(0.01));

        // Mid-flight scale expands
        expect(traj.scaleAt(0.5), greaterThan(traj.scaleAt(0.0)));

        // Pitch rotates upward initially and downward upon entry
        final rotStart = traj.rotationAt(0.1);
        final rotEnd = traj.rotationAt(0.9);
        expect(rotStart, lessThan(0.0)); // pitching up towards apex
        expect(rotEnd, greaterThan(0.0)); // pitching down into destination
      },
    );

    test('Moving right-to-left sets facingRight to false', () {
      const start = Offset(400, 250);
      const end = Offset(150, 250);

      final traj = FishTrajectory.calculate(start: start, end: end);
      expect(traj.facingRight, isFalse);
    });
  });

  group('Fish Swimming Animation In-Flight & State Consistency Tests', () {
    testWidgets(
      'Valid move renders animated fish in-flight, hides it from source, and finalizes cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableScreen());
        await tester.pumpAndSettle();

        // Level 1: Tank 1 has clownfish & blue_tang; Tank 3 is empty
        final tank0 = find.bySemanticsLabel(RegExp(r'Tank 1'));
        final tank2 = find.bySemanticsLabel(RegExp(r'Tank 3'));

        // Step 1: Tap Tank 1 to select source
        await tester.tap(tank0);
        await tester.pump();

        // Step 2: Tap Tank 3 to start swimming move
        await tester.tap(tank2);
        // Pump 50ms into animation: fish has taken flight
        await tester.pump(const Duration(milliseconds: 50));

        // Animated swimming overlay is now active
        expect(find.byType(AnimatedSwimmingFishOverlay), findsOneWidget);

        // While in-flight:
        // 1. Move count is still 0 (not finalized early)
        expect(find.text('Moves: 0'), findsOneWidget);
        // 2. Undo is disabled while animating
        final undoButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Undo'),
        );
        expect(undoButton.onPressed, isNull);
        // 3. Restart is disabled while animating
        final restartButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Restart'),
        );
        expect(restartButton.onPressed, isNull);

        // Advance animation to halfway (200ms)
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byType(AnimatedSwimmingFishOverlay), findsOneWidget);

        // Advance to full completion
        await tester.pumpAndSettle();

        // After completion:
        // 1. Overlay is removed
        expect(find.byType(AnimatedSwimmingFishOverlay), findsNothing);
        // 2. Move count increments to 1
        expect(find.text('Moves: 1'), findsOneWidget);
        // 3. Undo is now enabled
        final undoAfter = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Undo'),
        );
        expect(undoAfter.onPressed, isNotNull);
        // 4. Destination tank contains the fish
        expect(cubit.state.tanks[2].fish.length, equals(1));
        expect(cubit.state.tanks[2].topFish?.speciesId, equals('blue_tang'));
        // 5. Source tank has 1 fish remaining
        expect(cubit.state.tanks[0].fish.length, equals(1));
      },
    );

    testWidgets('Invalid move does NOT trigger swimming animation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final tank0 = find.bySemanticsLabel(RegExp(r'Tank 1'));
      final tank1 = find.bySemanticsLabel(RegExp(r'Tank 2'));

      // Select Tank 1 (blue_tang), try to move to Tank 2 (clownfish)
      await tester.tap(tank0);
      await tester.pump();
      await tester.tap(tank1);
      await tester.pump(const Duration(milliseconds: 50));

      // No swimming overlay is created
      expect(find.byType(AnimatedSwimmingFishOverlay), findsNothing);
      expect(find.text('Match the fish species'), findsOneWidget);
      expect(find.text('Moves: 0'), findsOneWidget);
    });

    testWidgets(
      'Swimming animation runs flawlessly on narrow mobile screen (320x600)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableScreen());
        await tester.pumpAndSettle();

        final tank0 = find.bySemanticsLabel(RegExp(r'Tank 1'));
        final tank2 = find.bySemanticsLabel(RegExp(r'Tank 3'));

        await tester.tap(tank0);
        await tester.pump();
        await tester.tap(tank2);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(AnimatedSwimmingFishOverlay), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
        ); // Zero overflow or render errors

        await tester.pumpAndSettle();
        expect(find.text('Moves: 1'), findsOneWidget);
      },
    );
  });
}
