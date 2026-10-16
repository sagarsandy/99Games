import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/reaction_test/cubit/reaction_test_cubit.dart';
import 'package:mini_games_99/features/games/reaction_test/domain/reaction_test_engine.dart';
import 'package:mini_games_99/features/games/reaction_test/domain/reaction_test_models.dart';
import 'package:mini_games_99/features/games/reaction_test/domain/reaction_test_storage.dart';

class FakeStopwatch implements Stopwatch {
  @override
  int elapsedMilliseconds = 220;

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
  void reset() {
    isRunning = false;
  }

  @override
  void start() {
    isRunning = true;
  }

  @override
  void stop() {
    isRunning = false;
  }
}

class FakeReactionTimerService implements ReactionTimerService {
  final FakeStopwatch stopwatch = FakeStopwatch();
  Completer<void>? pendingWait;
  bool autoResolve = true;

  @override
  Duration getRandomDelay() => const Duration(milliseconds: 50);

  @override
  Future<void> wait(Duration duration) {
    if (autoResolve) {
      return Future.value();
    }
    pendingWait = Completer<void>();
    return pendingWait!.future;
  }

  void completePendingWait() {
    pendingWait?.complete();
    pendingWait = null;
  }

  @override
  Stopwatch createStopwatch() => stopwatch;
}

class InMemoryReactionTestStorage implements ReactionTestStorage {
  ReactionTestStats _stats = const ReactionTestStats();
  int recordCallCount = 0;

  @override
  Future<ReactionTestStats> getStats() async => _stats;

  @override
  Future<void> recordCompletedSession(List<RoundOutcome> outcomes) async {
    recordCallCount++;
    final summary = ReactionTestSessionSummary(outcomes);
    _stats = _stats.copyWith(
      totalGamesPlayed: _stats.totalGamesPlayed + 1,
      totalValidReactions: _stats.totalValidReactions + summary.validCount,
      totalFalseStarts: _stats.totalFalseStarts + summary.falseStartCount,
      bestSingleMs: summary.fastestMs != null
          ? (_stats.bestSingleMs == null
                ? summary.fastestMs
                : (summary.fastestMs! < _stats.bestSingleMs!
                      ? summary.fastestMs
                      : _stats.bestSingleMs))
          : _stats.bestSingleMs,
      bestSessionAverageMs: summary.averageMs != null
          ? (_stats.bestSessionAverageMs == null
                ? summary.averageMs
                : (summary.averageMs! < _stats.bestSessionAverageMs!
                      ? summary.averageMs
                      : _stats.bestSessionAverageMs))
          : _stats.bestSessionAverageMs,
      lastSessionOutcomes: outcomes,
    );
  }

  @override
  Future<void> resetStats() async {
    _stats = const ReactionTestStats();
  }
}

void main() {
  group('Reaction Test - Cubit Tests', () {
    late InMemoryReactionTestStorage storage;
    late FakeReactionTimerService timerService;
    late ReactionTestCubit cubit;

    setUp(() {
      storage = InMemoryReactionTestStorage();
      timerService = FakeReactionTimerService();
      cubit = ReactionTestCubit(storage: storage, timerService: timerService);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state defaults to intro phase with loaded stats', () async {
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.phase, equals(ReactionPhase.intro));
      expect(cubit.state.currentRound, equals(1));
      expect(cubit.state.totalRounds, equals(5));
      expect(cubit.state.roundOutcomes, isEmpty);
    });

    test('startGame enters waiting phase and transitions to green', () async {
      timerService.autoResolve = false;

      cubit.startGame();
      expect(cubit.state.phase, equals(ReactionPhase.waiting));
      expect(cubit.state.currentRound, equals(1));

      // Resolve delay
      timerService.completePendingWait();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.phase, equals(ReactionPhase.green));
      expect(timerService.stopwatch.isRunning, isTrue);
    });

    test(
      'tapping before green records a false start and consumes the round',
      () async {
        timerService.autoResolve = false;

        cubit.startGame();
        expect(cubit.state.phase, equals(ReactionPhase.waiting));

        // Tap early
        cubit.handlePlayAreaTap();

        expect(cubit.state.phase, equals(ReactionPhase.falseStart));
        expect(cubit.state.roundOutcomes.length, equals(1));
        expect(cubit.state.roundOutcomes.first.isFalseStart, isTrue);
        expect(cubit.state.roundOutcomes.first.reactionTimeMs, isNull);

        // Now complete the pending wait - screen must NOT turn green!
        timerService.completePendingWait();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.phase, equals(ReactionPhase.falseStart));
      },
    );

    test('tapping after green records valid reaction time', () async {
      timerService.autoResolve = true;
      timerService.stopwatch.elapsedMilliseconds = 215;

      cubit.startGame();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.phase, equals(ReactionPhase.green));

      cubit.handlePlayAreaTap();

      expect(cubit.state.phase, equals(ReactionPhase.roundResult));
      expect(cubit.state.roundOutcomes.length, equals(1));
      expect(cubit.state.roundOutcomes.first.isFalseStart, isFalse);
      expect(cubit.state.roundOutcomes.first.reactionTimeMs, equals(215));
      expect(cubit.state.latestReactionMs, equals(215));
      expect(cubit.state.isLatestFastestInSession, isTrue);
    });

    test(
      'repeated taps in roundResult or falseStart cannot record duplicate outcomes',
      () async {
        timerService.autoResolve = true;
        cubit.startGame();
        await Future<void>.delayed(Duration.zero);

        cubit.handlePlayAreaTap();
        expect(cubit.state.roundOutcomes.length, equals(1));

        // Repeated taps
        cubit.handlePlayAreaTap();
        cubit.handlePlayAreaTap();
        expect(cubit.state.roundOutcomes.length, equals(1));
      },
    );

    test(
      'continueToNextRound advances round exactly once and starts next wait',
      () async {
        timerService.autoResolve = false;
        cubit.startGame();
        timerService.completePendingWait();
        await Future<void>.delayed(Duration.zero);

        cubit.handlePlayAreaTap();
        expect(cubit.state.phase, equals(ReactionPhase.roundResult));
        expect(cubit.state.currentRound, equals(1));

        // Continue
        cubit.continueToNextRound();
        expect(cubit.state.phase, equals(ReactionPhase.waiting));
        expect(cubit.state.currentRound, equals(2));

        // Green turns on
        timerService.completePendingWait();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.phase, equals(ReactionPhase.green));
      },
    );

    test(
      'completing 5 rounds transitions to completed state and updates stats once',
      () async {
        timerService.autoResolve = true;
        cubit.startGame();
        await Future<void>.delayed(Duration.zero);

        // Complete 5 rounds (3 valid, 2 false starts)
        for (int i = 1; i <= 5; i++) {
          if (i % 2 == 1) {
            // Valid round: turns green, then tap
            timerService.stopwatch.elapsedMilliseconds = 190 + (i * 10);
            cubit.handlePlayAreaTap();
          } else {
            // False start: tapped while waiting
            cubit.handlePlayAreaTap();
          }

          if (i < 5) {
            // Configure whether next round auto turns green or stays waiting for tap
            final nextIsFalseStart = (i + 1) % 2 == 0;
            timerService.autoResolve = !nextIsFalseStart;
            cubit.continueToNextRound();
            if (!nextIsFalseStart) {
              await Future<void>.delayed(Duration.zero);
            }
          }
        }

        // Finish 5th round
        cubit.continueToNextRound();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.phase, equals(ReactionPhase.completed));
        expect(cubit.state.roundOutcomes.length, equals(5));
        expect(storage.recordCallCount, equals(1));
        expect(cubit.state.stats.totalGamesPlayed, equals(1));
        expect(cubit.state.stats.totalValidReactions, equals(3));
        expect(cubit.state.stats.totalFalseStarts, equals(2));

        // Calling continue again does nothing
        cubit.continueToNextRound();
        expect(storage.recordCallCount, equals(1));
      },
    );

    test(
      'playAgain restarts fresh session directly from completed screen',
      () async {
        timerService.autoResolve = true;
        cubit.startGame();
        await Future<void>.delayed(Duration.zero);

        // Play 5 rounds
        for (int i = 1; i <= 5; i++) {
          cubit.handlePlayAreaTap();
          cubit.continueToNextRound();
          await Future<void>.delayed(Duration.zero);
        }
        expect(cubit.state.phase, equals(ReactionPhase.completed));

        cubit.playAgain();
        expect(cubit.state.currentRound, equals(1));
        expect(cubit.state.roundOutcomes, isEmpty);
      },
    );

    test('resetToIntro resets state to intro', () {
      cubit.startGame();
      expect(cubit.state.phase, isNot(equals(ReactionPhase.intro)));

      cubit.resetToIntro();
      expect(cubit.state.phase, equals(ReactionPhase.intro));
      expect(cubit.state.roundOutcomes, isEmpty);
      expect(cubit.state.currentRound, equals(1));
    });

    test('handleAppPaused invalidates pending round cleanly', () async {
      timerService.autoResolve = false;
      cubit.startGame();
      expect(cubit.state.phase, equals(ReactionPhase.waiting));

      cubit.handleAppPaused();
      expect(cubit.state.phase, equals(ReactionPhase.waiting));

      // Resolve old delay - should not corrupt round count or turn green
      timerService.completePendingWait();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.currentRound, equals(1));
      expect(cubit.state.roundOutcomes, isEmpty);
    });
  });
}
