import 'package:flutter/foundation.dart';
import '../domain/worm_escape_engine.dart';
import '../domain/worm_escape_level_data.dart';
import '../domain/worm_escape_models.dart';

/// State of the Worm Escape game.
@immutable
class WormEscapeState {
  final bool isLoading;
  final WormEscapeEngine engine;
  final WormEscapeDifficulty difficulty;
  final int levelNumber;
  final int unlockedLevel;
  final Set<int> completedLevels;
  final int? bestMoves;

  /// Currently escaping worm (undergoing escape crawl animation).
  final String? animatingWormId;

  /// Currently blocked worm (undergoing shake/bounce animation).
  final String? blockedWormId;

  /// The worm directly blocking the [blockedWormId] (highlighted during blocked feedback).
  final String? blockingWormId;

  /// Worm highlighted by the hint feature.
  final String? hintWormId;

  /// Transient hint or feedback message displayed to user.
  final String? hintMessage;

  const WormEscapeState({
    required this.isLoading,
    required this.engine,
    required this.difficulty,
    required this.levelNumber,
    required this.unlockedLevel,
    required this.completedLevels,
    this.bestMoves,
    this.animatingWormId,
    this.blockedWormId,
    this.blockingWormId,
    this.hintWormId,
    this.hintMessage,
  });

  /// Initial loading state before saved preferences are retrieved.
  factory WormEscapeState.initial() {
    final firstLevel = WormEscapeLevelData.levels.first;
    return WormEscapeState(
      isLoading: true,
      engine: WormEscapeEngine.initial(firstLevel),
      difficulty: WormEscapeDifficulty.easy,
      levelNumber: 1,
      unlockedLevel: 1,
      completedLevels: const {},
    );
  }

  bool get isWon => engine.isCompleted;
  bool get hasNextLevel =>
      levelNumber < WormEscapeLevelData.getLevelCount(difficulty);
  bool get canUndo => engine.canUndo && animatingWormId == null;
  int get remainingWorms => engine.remainingWormsCount;
  int get escapedWorms => engine.escapedWormsCount;
  int get totalWorms => engine.totalWorms;
  int get movesCount => engine.movesCount;

  WormEscapeState copyWith({
    bool? isLoading,
    WormEscapeEngine? engine,
    WormEscapeDifficulty? difficulty,
    int? levelNumber,
    int? unlockedLevel,
    Set<int>? completedLevels,
    int? bestMoves,
    bool clearBestMoves = false,
    String? animatingWormId,
    bool clearAnimatingWormId = false,
    String? blockedWormId,
    bool clearBlockedWormId = false,
    String? blockingWormId,
    bool clearBlockingWormId = false,
    String? hintWormId,
    bool clearHintWormId = false,
    String? hintMessage,
    bool clearHintMessage = false,
  }) {
    return WormEscapeState(
      isLoading: isLoading ?? this.isLoading,
      engine: engine ?? this.engine,
      difficulty: difficulty ?? this.difficulty,
      levelNumber: levelNumber ?? this.levelNumber,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      completedLevels: completedLevels ?? this.completedLevels,
      bestMoves: clearBestMoves ? null : (bestMoves ?? this.bestMoves),
      animatingWormId: clearAnimatingWormId
          ? null
          : (animatingWormId ?? this.animatingWormId),
      blockedWormId: clearBlockedWormId
          ? null
          : (blockedWormId ?? this.blockedWormId),
      blockingWormId: clearBlockingWormId
          ? null
          : (blockingWormId ?? this.blockingWormId),
      hintWormId: clearHintWormId ? null : (hintWormId ?? this.hintWormId),
      hintMessage: clearHintMessage ? null : (hintMessage ?? this.hintMessage),
    );
  }
}
