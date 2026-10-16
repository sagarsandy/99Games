import 'package:equatable/equatable.dart';
import '../domain/emoji_connect_engine.dart';
import '../domain/emoji_connect_level_data.dart';
import '../domain/emoji_connect_models.dart';

/// Immutable state for Emoji Connect.
class EmojiConnectState extends Equatable {
  final EmojiConnectDifficulty difficulty;
  final int levelNumber;
  final EmojiConnectEngine engine;
  final int unlockedLevel;
  final Set<int> completedLevels;
  final int? bestTimeSeconds;
  final int elapsedSeconds;
  final bool isTimerRunning;
  final String? hintMessage;
  final bool isLoading;

  const EmojiConnectState({
    required this.difficulty,
    required this.levelNumber,
    required this.engine,
    required this.unlockedLevel,
    required this.completedLevels,
    this.bestTimeSeconds,
    this.elapsedSeconds = 0,
    this.isTimerRunning = false,
    this.hintMessage,
    this.isLoading = false,
  });

  bool get isWon => engine.isCompleted;
  int get coveredCells => engine.coveredCellsCount;
  int get totalCells => engine.totalCells;
  int get connectedPairs => engine.completedPairsCount;
  int get totalPairs => engine.level.pairs.length;
  bool get canUndo => engine.canUndo;
  bool get hasNextLevel =>
      levelNumber <
      EmojiConnectLevelData.getLevelsForDifficulty(difficulty).length;

  EmojiConnectState copyWith({
    EmojiConnectDifficulty? difficulty,
    int? levelNumber,
    EmojiConnectEngine? engine,
    int? unlockedLevel,
    Set<int>? completedLevels,
    int? bestTimeSeconds,
    bool clearBestTime = false,
    int? elapsedSeconds,
    bool? isTimerRunning,
    String? hintMessage,
    bool clearHintMessage = false,
    bool? isLoading,
  }) {
    return EmojiConnectState(
      difficulty: difficulty ?? this.difficulty,
      levelNumber: levelNumber ?? this.levelNumber,
      engine: engine ?? this.engine,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      completedLevels: completedLevels ?? this.completedLevels,
      bestTimeSeconds: clearBestTime
          ? null
          : (bestTimeSeconds ?? this.bestTimeSeconds),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      hintMessage: clearHintMessage ? null : (hintMessage ?? this.hintMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    difficulty,
    levelNumber,
    engine,
    unlockedLevel,
    completedLevels,
    bestTimeSeconds,
    elapsedSeconds,
    isTimerRunning,
    hintMessage,
    isLoading,
  ];
}
