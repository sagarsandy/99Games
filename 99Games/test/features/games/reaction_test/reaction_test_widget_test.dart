import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/reaction_test/cubit/reaction_test_cubit.dart';
import 'package:mini_games_99/features/games/reaction_test/domain/reaction_test_engine.dart';
import 'package:mini_games_99/features/games/reaction_test/domain/reaction_test_models.dart';
import 'package:mini_games_99/features/games/reaction_test/domain/reaction_test_storage.dart';
import 'package:mini_games_99/features/games/reaction_test/presentation/reaction_test_screen.dart';

class WidgetTestStopwatch implements Stopwatch {
  @override
  int elapsedMilliseconds = 245;

  @override
  int get elapsedMicroseconds => elapsedMilliseconds * 1000;

  @override
  int get elapsedTicks => elapsedMilliseconds;

  @override
  int get frequency => 1000;

  @override
  bool isRunning = false;

  @override
  Duration get elapsed => Duration(milliseconds: elapsedMilliseconds);

  @override
  void reset() => isRunning = false;

  @override
  void start() => isRunning = true;

  @override
  void stop() => isRunning = false;
}

class WidgetTestTimerService implements ReactionTimerService {
  final WidgetTestStopwatch stopwatch = WidgetTestStopwatch();
  bool autoTurnGreen = false;

  @override
  Duration getRandomDelay() => Duration.zero;

  @override
  Future<void> wait(Duration duration) {
    if (autoTurnGreen) {
      return Future.value();
    }
    return Completer<void>().future;
  }

  @override
  Stopwatch createStopwatch() => stopwatch;
}

class WidgetTestStorage implements ReactionTestStorage {
  ReactionTestStats stats = const ReactionTestStats(
    bestSingleMs: 195,
    bestSessionAverageMs: 215.4,
  );

  @override
  Future<ReactionTestStats> getStats() async => stats;

  @override
  Future<void> recordCompletedSession(List<RoundOutcome> outcomes) async {
    stats = stats.copyWith(totalGamesPlayed: stats.totalGamesPlayed + 1);
  }

  @override
  Future<void> resetStats() async {
    stats = const ReactionTestStats();
  }
}

Widget createTestApp({
  required ReactionTestCubit cubit,
  Size screenSize = const Size(400, 800),
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: screenSize),
      child: BlocProvider<ReactionTestCubit>.value(
        value: cubit,
        child: const ReactionTestScreen(),
      ),
    ),
  );
}

void main() {
  group('Reaction Test - Widget Tests', () {
    late WidgetTestStorage storage;
    late WidgetTestTimerService timerService;
    late ReactionTestCubit cubit;

    setUp(() {
      storage = WidgetTestStorage();
      timerService = WidgetTestTimerService();
      cubit = ReactionTestCubit(storage: storage, timerService: timerService);
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets(
      'renders Intro screen with title, rules icon, and Start Game button',
      (tester) async {
        await tester.pumpWidget(createTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        expect(find.text('Reaction Test'), findsWidgets);
        expect(
          find.text('Wait for green, then tap as quickly as possible.'),
          findsOneWidget,
        );
        expect(find.text('Start Game'), findsOneWidget);
        expect(find.textContaining('Personal Best: 195 ms'), findsOneWidget);

        // Tap How to Play rules icon
        await tester.tap(find.byTooltip('How to Play'));
        await tester.pumpAndSettle();

        expect(find.text('How to Play'), findsOneWidget);
        expect(find.text('Got it!'), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.text('Got it!'));
        await tester.pumpAndSettle();
        expect(find.text('How to Play'), findsNothing);
      },
    );

    testWidgets('tapping Start Game transitions to Red waiting state', (
      tester,
    ) async {
      timerService.autoTurnGreen = false;
      await tester.pumpWidget(createTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();

      expect(find.text('Wait for green...'), findsOneWidget);
      expect(find.text('Do not tap yet!'), findsOneWidget);
      expect(find.text('Round 1 of 5'), findsOneWidget);
    });

    testWidgets('tapping red area results in Too Early false start feedback', (
      tester,
    ) async {
      timerService.autoTurnGreen = false;
      await tester.pumpWidget(createTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();

      // Tap early on red play area
      await tester.tap(find.text('Wait for green...'));
      await tester.pumpAndSettle();

      expect(find.text('Too early!'), findsOneWidget);
      expect(find.text('Continue to Next Round'), findsOneWidget);
    });

    testWidgets(
      'green state appears after wait and tapping records reaction time',
      (tester) async {
        timerService.autoTurnGreen = true;
        timerService.stopwatch.elapsedMilliseconds = 245;

        await tester.pumpWidget(createTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Start Game'));
        await tester.tap(find.text('Start Game'));
        await tester.pumpAndSettle();

        expect(find.text('TAP NOW!'), findsOneWidget);

        // Tap green surface
        await tester.tap(find.text('TAP NOW!'));
        await tester.pumpAndSettle();

        expect(find.text('245 ms'), findsOneWidget);
        expect(find.text('Fast'), findsOneWidget);
        expect(find.text('Continue to Next Round'), findsOneWidget);
      },
    );

    testWidgets(
      'completing all 5 rounds displays Results screen and Play Again button',
      (tester) async {
        timerService.autoTurnGreen = true;

        await tester.pumpWidget(createTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Start Game'));
        await tester.tap(find.text('Start Game'));
        await tester.pumpAndSettle();

        // Play 5 rounds
        for (int i = 1; i <= 5; i++) {
          expect(find.text('TAP NOW!'), findsOneWidget);
          await tester.tap(find.text('TAP NOW!'));
          await tester.pumpAndSettle();

          final buttonText = i == 5 ? 'View Results' : 'Continue to Next Round';
          await tester.tap(find.text(buttonText));
          await tester.pumpAndSettle();
        }

        expect(find.text('Challenge Complete!'), findsOneWidget);
        expect(find.text('Average Reaction Time'), findsOneWidget);
        expect(find.text('Play Again'), findsOneWidget);
        expect(find.text('Back to Home'), findsOneWidget);
        expect(find.text('Round Breakdown'), findsOneWidget);

        // Tap Play Again
        await tester.ensureVisible(find.text('Play Again'));
        await tester.tap(find.text('Play Again'));
        await tester.pumpAndSettle();

        expect(find.text('TAP NOW!'), findsOneWidget);
      },
    );

    testWidgets('renders without overflow on small screens', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          cubit: cubit,
          screenSize: const Size(320, 560), // very small mobile screen
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reaction Test'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
