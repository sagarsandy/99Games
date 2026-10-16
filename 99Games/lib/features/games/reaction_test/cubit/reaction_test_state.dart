import 'package:flutter/foundation.dart';
import '../domain/reaction_test_models.dart';

/// Immutable state representing the Reaction Test game.
@immutable
class ReactionTestState {
  final ReactionPhase phase;
  final int currentRound;
  final int totalRounds;
  final List<RoundOutcome> roundOutcomes;
  final int? latestReactionMs;
  final bool isLatestFastestInSession;
  final ReactionTestStats stats;
  final bool isNewBestSingle;
  final bool isNewBestAverage;

  const ReactionTestState({
    this.phase = ReactionPhase.intro,
    this.currentRound = 1,
    this.totalRounds = 5,
    this.roundOutcomes = const [],
    this.latestReactionMs,
    this.isLatestFastestInSession = false,
    this.stats = const ReactionTestStats(),
    this.isNewBestSingle = false,
    this.isNewBestAverage = false,
  });

  ReactionTestSessionSummary get sessionSummary =>
      ReactionTestSessionSummary(roundOutcomes);

  bool get isGameOver => phase == ReactionPhase.completed;

  ReactionTestState copyWith({
    ReactionPhase? phase,
    int? currentRound,
    int? totalRounds,
    List<RoundOutcome>? roundOutcomes,
    int? latestReactionMs,
    bool? isLatestFastestInSession,
    ReactionTestStats? stats,
    bool? isNewBestSingle,
    bool? isNewBestAverage,
  }) {
    return ReactionTestState(
      phase: phase ?? this.phase,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      roundOutcomes: roundOutcomes ?? this.roundOutcomes,
      latestReactionMs: latestReactionMs ?? this.latestReactionMs,
      isLatestFastestInSession:
          isLatestFastestInSession ?? this.isLatestFastestInSession,
      stats: stats ?? this.stats,
      isNewBestSingle: isNewBestSingle ?? this.isNewBestSingle,
      isNewBestAverage: isNewBestAverage ?? this.isNewBestAverage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionTestState &&
          runtimeType == other.runtimeType &&
          phase == other.phase &&
          currentRound == other.currentRound &&
          totalRounds == other.totalRounds &&
          listEquals(roundOutcomes, other.roundOutcomes) &&
          latestReactionMs == other.latestReactionMs &&
          isLatestFastestInSession == other.isLatestFastestInSession &&
          stats == other.stats &&
          isNewBestSingle == other.isNewBestSingle &&
          isNewBestAverage == other.isNewBestAverage;

  @override
  int get hashCode => Object.hash(
    phase,
    currentRound,
    totalRounds,
    Object.hashAll(roundOutcomes),
    latestReactionMs,
    isLatestFastestInSession,
    stats,
    isNewBestSingle,
    isNewBestAverage,
  );
}
