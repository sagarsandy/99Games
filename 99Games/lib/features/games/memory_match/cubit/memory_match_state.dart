import 'package:equatable/equatable.dart';
import '../domain/memory_match_level_data.dart';
import '../domain/memory_match_models.dart';
import '../domain/memory_match_scoring.dart';

/// Immutable state for Game 14: Memory Match.
class MemoryMatchState extends Equatable {
  final GameStatus status;
  final int currentLevel;
  final int highestUnlockedLevel;
  final List<MemoryCard> cards;
  final int? firstSelectedId;
  final int? secondSelectedId;
  final bool isResolvingMismatch;
  final int moves;
  final int matchedPairs;
  final int totalPairs;
  final int elapsedSeconds;
  final int currentScore;
  final int bestScoreForLevel;
  final bool isNewBest;
  final MemoryMatchScoreBreakdown? scoreBreakdown;
  final bool isLoading;
  final int roundToken;

  const MemoryMatchState({
    this.status = GameStatus.ready,
    this.currentLevel = 1,
    this.highestUnlockedLevel = 1,
    this.cards = const [],
    this.firstSelectedId,
    this.secondSelectedId,
    this.isResolvingMismatch = false,
    this.moves = 0,
    this.matchedPairs = 0,
    this.totalPairs = 2,
    this.elapsedSeconds = 0,
    this.currentScore = 0,
    this.bestScoreForLevel = 0,
    this.isNewBest = false,
    this.scoreBreakdown,
    this.isLoading = false,
    this.roundToken = 0,
  });

  bool get isReady => status == GameStatus.ready;
  bool get isPlaying => status == GameStatus.playing;
  bool get isCompleted => status == GameStatus.completed;
  bool get hasActiveSelection =>
      firstSelectedId != null || secondSelectedId != null;
  bool get canAdvanceLevel =>
      currentLevel < MemoryMatchLevelData.totalLevels &&
      currentLevel < highestUnlockedLevel;

  LevelConfig get currentLevelConfig =>
      MemoryMatchLevelData.getLevel(currentLevel);

  MemoryMatchState copyWith({
    GameStatus? status,
    int? currentLevel,
    int? highestUnlockedLevel,
    List<MemoryCard>? cards,
    int? firstSelectedId,
    bool clearFirstSelected = false,
    int? secondSelectedId,
    bool clearSecondSelected = false,
    bool? isResolvingMismatch,
    int? moves,
    int? matchedPairs,
    int? totalPairs,
    int? elapsedSeconds,
    int? currentScore,
    int? bestScoreForLevel,
    bool? isNewBest,
    MemoryMatchScoreBreakdown? scoreBreakdown,
    bool clearScoreBreakdown = false,
    bool? isLoading,
    int? roundToken,
  }) {
    return MemoryMatchState(
      status: status ?? this.status,
      currentLevel: currentLevel ?? this.currentLevel,
      highestUnlockedLevel: highestUnlockedLevel ?? this.highestUnlockedLevel,
      cards: cards ?? this.cards,
      firstSelectedId: clearFirstSelected
          ? null
          : (firstSelectedId ?? this.firstSelectedId),
      secondSelectedId: clearSecondSelected
          ? null
          : (secondSelectedId ?? this.secondSelectedId),
      isResolvingMismatch: isResolvingMismatch ?? this.isResolvingMismatch,
      moves: moves ?? this.moves,
      matchedPairs: matchedPairs ?? this.matchedPairs,
      totalPairs: totalPairs ?? this.totalPairs,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      currentScore: currentScore ?? this.currentScore,
      bestScoreForLevel: bestScoreForLevel ?? this.bestScoreForLevel,
      isNewBest: isNewBest ?? this.isNewBest,
      scoreBreakdown: clearScoreBreakdown
          ? null
          : (scoreBreakdown ?? this.scoreBreakdown),
      isLoading: isLoading ?? this.isLoading,
      roundToken: roundToken ?? this.roundToken,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentLevel,
    highestUnlockedLevel,
    cards,
    firstSelectedId,
    secondSelectedId,
    isResolvingMismatch,
    moves,
    matchedPairs,
    totalPairs,
    elapsedSeconds,
    currentScore,
    bestScoreForLevel,
    isNewBest,
    scoreBreakdown,
    isLoading,
    roundToken,
  ];
}
