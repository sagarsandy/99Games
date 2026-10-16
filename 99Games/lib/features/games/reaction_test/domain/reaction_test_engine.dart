import 'dart:async';
import 'dart:math';
import 'reaction_test_models.dart';

/// Contract for generating randomized waiting delays and monotonic stopwatches.
///
/// Injectable to allow deterministic and instant execution during unit and widget tests.
abstract interface class ReactionTimerService {
  /// Generates a random delay between min and max wait limits (2.0 to 5.0 seconds).
  Duration getRandomDelay();

  /// Waits asynchronously for the specified duration.
  Future<void> wait(Duration duration);

  /// Creates a fresh monotonic Stopwatch instance.
  Stopwatch createStopwatch();
}

/// Production implementation of [ReactionTimerService] using system monotonic clock.
class DefaultReactionTimerService implements ReactionTimerService {
  final Random _random;

  DefaultReactionTimerService({Random? random}) : _random = random ?? Random();

  @override
  Duration getRandomDelay() {
    // 2000ms to 5000ms (inclusive range)
    final ms = 2000 + _random.nextInt(3001);
    return Duration(milliseconds: ms);
  }

  @override
  Future<void> wait(Duration duration) => Future.delayed(duration);

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

/// Pure Dart domain engine for reaction time calculations and session analysis.
abstract final class ReactionTestEngine {
  static const int totalRounds = 5;
  static const int minWaitMs = 2000;
  static const int maxWaitMs = 5000;

  /// Creates a session summary from round outcomes.
  static ReactionTestSessionSummary evaluateSession(
    List<RoundOutcome> outcomes,
  ) {
    return ReactionTestSessionSummary(List.unmodifiable(outcomes));
  }

  /// Evaluates whether [newMs] is a new personal best single reaction time.
  static bool isNewPersonalBest({
    required int newMs,
    required int? currentBestMs,
  }) {
    if (currentBestMs == null) return true;
    return newMs < currentBestMs;
  }

  /// Evaluates whether [newAvg] is a new personal best session average.
  static bool isNewBestAverage({
    required double? newAvg,
    required double? currentBestAvg,
  }) {
    if (newAvg == null) return false;
    if (currentBestAvg == null) return true;
    return newAvg < currentBestAvg;
  }

  /// Formats reaction milliseconds for display.
  static String formatMs(int? ms) {
    if (ms == null) return '—';
    return '$ms ms';
  }

  /// Formats average milliseconds with 1 decimal place.
  static String formatAverage(double? avg) {
    if (avg == null) return '—';
    return '${avg.toStringAsFixed(1)} ms';
  }
}
