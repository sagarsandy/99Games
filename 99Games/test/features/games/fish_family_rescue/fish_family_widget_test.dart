import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/cubit/fish_family_cubit.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/domain/fish_family_models.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/domain/fish_family_storage.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/presentation/fish_family_screen.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/presentation/painters/aquarium_effects_painter.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/presentation/painters/fish_painter.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/presentation/painters/fish_tank_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late FishFamilyStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SharedFishFamilyStorage(prefs);
  });

  Widget buildTestableWidget({ThemeMode themeMode = ThemeMode.light}) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: BlocProvider(
        create: (_) => FishFamilyCubit(storage: storage),
        child: const FishFamilyScreen(enableAmbientAnimation: false),
      ),
    );
  }

  group('FishFamily Widget Tests', () {
    testWidgets(
      'FishFamilyScreen renders header, aquarium tanks, and controls',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('Fish Family Rescue'), findsOneWidget);
        expect(find.textContaining('Level 1'), findsWidgets);
        expect(find.text('Baby Coral Reef'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
        expect(find.text('Restart'), findsOneWidget);
        expect(find.text('Moves: 0'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping a tank selects it, and tapping empty tank moves fish',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // Tap Tank 0 (first tank)
        final tank0 = find.bySemanticsLabel(RegExp(r'Tank 1'));
        expect(tank0, findsOneWidget);
        await tester.tap(tank0);
        await tester.pumpAndSettle();

        // Tap Tank 3 (third tank, empty)
        final tank2 = find.bySemanticsLabel(RegExp(r'Tank 3'));
        expect(tank2, findsOneWidget);
        await tester.tap(tank2);
        await tester.pumpAndSettle();

        expect(find.text('Moves: 1'), findsOneWidget);
      },
    );

    testWidgets(
      'Invalid move displays feedback banner without changing moves',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // Tank 0 top is blue_tang, Tank 1 top is clownfish
        final tank0 = find.bySemanticsLabel(RegExp(r'Tank 1'));
        final tank1 = find.bySemanticsLabel(RegExp(r'Tank 2'));

        await tester.tap(tank0);
        await tester.pumpAndSettle();

        await tester.tap(tank1);
        await tester.pumpAndSettle();

        expect(find.text('Match the fish species'), findsOneWidget);
        expect(find.text('Moves: 0'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping How to Play displays instructions and fish families dialog',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.help_outline_rounded));
        await tester.pumpAndSettle();

        expect(find.text('How to Play'), findsOneWidget);
        expect(
          find.textContaining('Objective: Sort all cartoon fish'),
          findsOneWidget,
        );
        expect(find.text('Clownfish'), findsOneWidget);
        expect(find.text('Blue Tang'), findsOneWidget);

        await tester.tap(find.text('Got it!'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Tapping Level chip opens level picker bottom sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Level 1 / 20'));
      await tester.pumpAndSettle();

      expect(find.text('Select Level (1–20)'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Solving level requires 3 full moves, displays results dialog, allows viewing completed board, and reopening results',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        final tank0 = find.bySemanticsLabel(RegExp(r'Tank 1'));
        final tank1 = find.bySemanticsLabel(RegExp(r'Tank 2'));
        final tank2 = find.bySemanticsLabel(RegExp(r'Tank 3'));

        // Move 1: Tank 0 -> Tank 2
        await tester.tap(tank0);
        await tester.pumpAndSettle();
        await tester.tap(tank2);
        await tester.pumpAndSettle();

        // Move 2: Tank 1 -> Tank 0
        await tester.tap(tank1);
        await tester.pumpAndSettle();
        await tester.tap(tank0);
        await tester.pumpAndSettle();

        // Level must NOT be completed at Move 2!
        expect(find.text('Fish Families Rescued!'), findsNothing);
        expect(find.text('Level Complete! View Results'), findsNothing);

        // Move 3: Tank 1 -> Tank 2 (Merges blue tangs together!)
        await tester.tap(tank1);
        await tester.pumpAndSettle();
        await tester.tap(tank2);
        await tester.pumpAndSettle();

        // Victory Dialog should appear
        expect(find.text('Fish Families Rescued!'), findsOneWidget);
        expect(find.text('Level 1 Completed'), findsOneWidget);
        expect(find.text('Next Level'), findsOneWidget);
        expect(find.text('Board'), findsOneWidget);

        // Dismiss dialog to view completed board
        await tester.tap(find.text('Board'));
        await tester.pumpAndSettle();

        // Bottom banner to reopen results is visible without overlapping header
        final viewResultsButton = find.text('Level Complete! View Results');
        expect(viewResultsButton, findsOneWidget);

        // Header elements must remain unobstructed and visible
        expect(find.text('Fish Family Rescue'), findsOneWidget);
        expect(find.text('Baby Coral Reef'), findsOneWidget);

        // Verify banner is located at the bottom and does not overlap title at the top
        final titleY = tester.getTopLeft(find.text('Fish Family Rescue')).dy;
        final bannerY = tester.getTopLeft(viewResultsButton).dy;
        expect(bannerY, greaterThan(titleY + 150));

        // Tap banner to reopen results dialog
        await tester.tap(viewResultsButton);
        await tester.pumpAndSettle();

        expect(find.text('Fish Families Rescued!'), findsOneWidget);
      },
    );

    testWidgets(
      'Responsive UI: No overflow occurs on narrow 320px and 360px mobile screens',
      (tester) async {
        // Test on narrow 320x640 mobile screen
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // Ensure no overflow errors occurred
        expect(tester.takeException(), isNull);

        // Controls remain visible and usable
        expect(find.text('Undo'), findsOneWidget);
        expect(find.text('Restart'), findsOneWidget);
        expect(find.text('Moves: 0'), findsOneWidget);

        // Tapping controls works without clipping
        await tester.tap(find.text('Restart'));
        await tester.pumpAndSettle();
        // Since moves == 0, restart does not open dialog
        expect(tester.takeException(), isNull);

        // Also test on 360x740 screen
        tester.view.physicalSize = const Size(360, 740);
        await tester.pumpWidget(buildTestableWidget(themeMode: ThemeMode.dark));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Undo'), findsOneWidget);
        expect(find.text('Restart'), findsOneWidget);
      },
    );

    testWidgets('CustomPainters paint without errors in light and dark modes', (
      tester,
    ) async {
      final species = FishSpecies.getById('clownfish');

      for (final isDark in [false, true]) {
        final fishPainter = FishPainter(
          species: species,
          expression: FishExpression.happy,
          isSelected: true,
          animationProgress: 0.5,
        );
        final tankPainter = FishTankPainter(
          capacity: 4,
          fishCount: 3,
          isSelected: true,
          isCompleted: false,
          isDark: isDark,
          waterAnimation: 0.5,
        );
        final effectPainter = AquariumEffectsPainter(
          progress: 0.5,
          isDark: isDark,
        );

        // Verify painters can execute paint
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        fishPainter.paint(canvas, const Size(80, 50));
        tankPainter.paint(canvas, const Size(70, 200));
        effectPainter.paint(canvas, const Size(400, 800));
        recorder.endRecording().dispose();
      }
    });
  });
}
