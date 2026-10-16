import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/reaction_test_engine.dart';
import '../domain/reaction_test_models.dart';
import '../domain/reaction_test_storage.dart';
import 'reaction_test_state.dart';

/// Cubit managing Reaction Test lifecycle, precision timing, and state transitions.
class ReactionTestCubit extends Cubit<ReactionTestState> {
  final ReactionTestStorage _storage;
  final ReactionTimerService _timerService;

  late final Stopwatch _stopwatch;
  int _roundToken = 0;
  bool _hasSavedCompletedSession = false;

  ReactionTestCubit({
    required ReactionTestStorage storage,
    ReactionTimerService? timerService,
  }) : _storage = storage,
       _timerService = timerService ?? DefaultReactionTimerService(),
       super(const ReactionTestState()) {
    _stopwatch = _timerService.createStopwatch();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _storage.getStats();
    if (!isClosed) {
      emit(state.copyWith(stats: stats));
    }
  }

  /// Starts a new 5-round challenge from the intro screen.
  void startGame() {
    _roundToken++;
    _hasSavedCompletedSession = false;
    _stopwatch.reset();

    emit(
      state.copyWith(
        phase: ReactionPhase.waiting,
        currentRound: 1,
        totalRounds: ReactionTestEngine.totalRounds,
        roundOutcomes: const [],
        latestReactionMs: null,
        isLatestFastestInSession: false,
        isNewBestSingle: false,
        isNewBestAverage: false,
      ),
    );

    _scheduleGreenSignal(_roundToken);
  }

  /// Schedules the transition to green after a randomized delay (2.0 to 5.0 seconds).
  Future<void> _scheduleGreenSignal(int token) async {
    final delay = _timerService.getRandomDelay();
    await _timerService.wait(delay);

    if (isClosed ||
        token != _roundToken ||
        state.phase != ReactionPhase.waiting) {
      return;
    }

    // Monotonic clock is started immediately before publishing the Green state.
    // Note: Rendering introduces minimal device-dependent latency; timing starts on the signal.
    _stopwatch.reset();
    _stopwatch.start();

    emit(state.copyWith(phase: ReactionPhase.green));
  }

  /// Handles player tap on the primary play area.
  ///
  /// The monotonic timestamp is captured at the very first line of execution.
  void handlePlayAreaTap() {
    // CAPTURE TIMESTAMP FIRST
    final int elapsedMs = _stopwatch.elapsedMilliseconds;

    if (state.phase == ReactionPhase.waiting) {
      // False start: player tapped while area is still red
      _roundToken++; // Cancel pending green signal
      _stopwatch.stop();
      _stopwatch.reset();

      final outcome = RoundOutcome(
        roundNumber: state.currentRound,
        isFalseStart: true,
        reactionTimeMs: null,
      );

      final updatedOutcomes = [...state.roundOutcomes, outcome];

      emit(
        state.copyWith(
          phase: ReactionPhase.falseStart,
          roundOutcomes: updatedOutcomes,
          latestReactionMs: null,
          isLatestFastestInSession: false,
        ),
      );
    } else if (state.phase == ReactionPhase.green) {
      // Valid reaction: stop stopwatch immediately
      _stopwatch.stop();

      // Check if this was the fastest valid round in this session so far
      final priorValidTimes = state.roundOutcomes
          .where((o) => !o.isFalseStart && o.reactionTimeMs != null)
          .map((o) => o.reactionTimeMs!);

      final bool isFastestInSession =
          priorValidTimes.isEmpty ||
          elapsedMs < priorValidTimes.reduce((a, b) => a < b ? a : b);

      final outcome = RoundOutcome(
        roundNumber: state.currentRound,
        isFalseStart: false,
        reactionTimeMs: elapsedMs,
      );

      final updatedOutcomes = [...state.roundOutcomes, outcome];

      emit(
        state.copyWith(
          phase: ReactionPhase.roundResult,
          roundOutcomes: updatedOutcomes,
          latestReactionMs: elapsedMs,
          isLatestFastestInSession: isFastestInSession,
        ),
      );
    }
  }

  /// Continues to the next round or finishes the 5-round challenge.
  void continueToNextRound() {
    if (state.phase != ReactionPhase.roundResult &&
        state.phase != ReactionPhase.falseStart) {
      return;
    }

    if (state.currentRound < state.totalRounds) {
      final nextRound = state.currentRound + 1;
      _roundToken++;
      _stopwatch.reset();

      emit(
        state.copyWith(
          phase: ReactionPhase.waiting,
          currentRound: nextRound,
          latestReactionMs: null,
          isLatestFastestInSession: false,
        ),
      );

      _scheduleGreenSignal(_roundToken);
    } else {
      _finishGame();
    }
  }

  /// Concludes the session, calculates stats, and persists results idempotently.
  Future<void> _finishGame() async {
    if (_hasSavedCompletedSession) return;
    _hasSavedCompletedSession = true;

    final summary = ReactionTestEngine.evaluateSession(state.roundOutcomes);

    final bool isNewBestSingle =
        summary.fastestMs != null &&
        ReactionTestEngine.isNewPersonalBest(
          newMs: summary.fastestMs!,
          currentBestMs: state.stats.bestSingleMs,
        );

    final bool isNewBestAvg =
        summary.averageMs != null &&
        ReactionTestEngine.isNewBestAverage(
          newAvg: summary.averageMs,
          currentBestAvg: state.stats.bestSessionAverageMs,
        );

    await _storage.recordCompletedSession(state.roundOutcomes);
    final updatedStats = await _storage.getStats();

    if (!isClosed) {
      emit(
        state.copyWith(
          phase: ReactionPhase.completed,
          stats: updatedStats,
          isNewBestSingle: isNewBestSingle,
          isNewBestAverage: isNewBestAvg,
        ),
      );
    }
  }

  /// Starts a fresh session directly from the completed results screen.
  void playAgain() {
    startGame();
  }

  /// Returns to the intro screen.
  void resetToIntro() {
    _roundToken++;
    _stopwatch.reset();
    _stopwatch.stop();

    emit(
      state.copyWith(
        phase: ReactionPhase.intro,
        currentRound: 1,
        roundOutcomes: const [],
        latestReactionMs: null,
        isLatestFastestInSession: false,
        isNewBestSingle: false,
        isNewBestAverage: false,
      ),
    );
  }

  /// Cancels any pending round delay when the app is paused or navigated away.
  void handleAppPaused() {
    if (state.phase == ReactionPhase.waiting ||
        state.phase == ReactionPhase.green) {
      _roundToken++;
      _stopwatch.stop();
      _stopwatch.reset();

      // Invalidate current interrupted round so player restarts it cleanly
      emit(state.copyWith(phase: ReactionPhase.waiting));
      _scheduleGreenSignal(_roundToken);
    }
  }

  @override
  Future<void> close() {
    _roundToken++;
    _stopwatch.stop();
    return super.close();
  }
}
