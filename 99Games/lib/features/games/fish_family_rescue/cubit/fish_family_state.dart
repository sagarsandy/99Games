import 'package:flutter/foundation.dart';
import '../domain/fish_family_level_data.dart';
import '../domain/fish_family_models.dart';

/// Immutable state for Fish Family Rescue game.
@immutable
class FishFamilyState {
  final int levelNumber;
  final int unlockedLevel;
  final Set<int> completedLevels;
  final List<FishTank> tanks;
  final int? selectedTankId;
  final int movesCount;
  final int? bestMoves;
  final List<FishMove> moveHistory;
  final bool isWon;
  final bool hasShownWinDialog;
  final String? feedbackMessage;
  final int? shakingTankId;
  final PendingFishMove? pendingMove;
  final bool isLoading;

  const FishFamilyState({
    required this.levelNumber,
    required this.unlockedLevel,
    required this.completedLevels,
    required this.tanks,
    this.selectedTankId,
    this.movesCount = 0,
    this.bestMoves,
    this.moveHistory = const [],
    this.isWon = false,
    this.hasShownWinDialog = false,
    this.feedbackMessage,
    this.shakingTankId,
    this.pendingMove,
    this.isLoading = false,
  });

  bool get isAnimating => pendingMove != null;
  bool get canUndo => moveHistory.isNotEmpty && !isAnimating;
  bool get hasNextLevel => levelNumber < FishFamilyLevelData.totalLevels;
  FishFamilyLevel get level => FishFamilyLevelData.getLevel(levelNumber);

  Fish? get selectedFish {
    if (selectedTankId == null) return null;
    final tank = tanks.where((t) => t.id == selectedTankId).firstOrNull;
    return tank?.topFish;
  }

  FishFamilyState copyWith({
    int? levelNumber,
    int? unlockedLevel,
    Set<int>? completedLevels,
    List<FishTank>? tanks,
    int? Function()? selectedTankId,
    int? movesCount,
    int? Function()? bestMoves,
    List<FishMove>? moveHistory,
    bool? isWon,
    bool? hasShownWinDialog,
    String? Function()? feedbackMessage,
    int? Function()? shakingTankId,
    PendingFishMove? Function()? pendingMove,
    bool? isLoading,
  }) {
    return FishFamilyState(
      levelNumber: levelNumber ?? this.levelNumber,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      completedLevels: completedLevels ?? this.completedLevels,
      tanks: tanks ?? this.tanks,
      selectedTankId: selectedTankId != null
          ? selectedTankId()
          : this.selectedTankId,
      movesCount: movesCount ?? this.movesCount,
      bestMoves: bestMoves != null ? bestMoves() : this.bestMoves,
      moveHistory: moveHistory ?? this.moveHistory,
      isWon: isWon ?? this.isWon,
      hasShownWinDialog: hasShownWinDialog ?? this.hasShownWinDialog,
      feedbackMessage: feedbackMessage != null
          ? feedbackMessage()
          : this.feedbackMessage,
      shakingTankId: shakingTankId != null
          ? shakingTankId()
          : this.shakingTankId,
      pendingMove: pendingMove != null ? pendingMove() : this.pendingMove,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FishFamilyState &&
          runtimeType == other.runtimeType &&
          levelNumber == other.levelNumber &&
          unlockedLevel == other.unlockedLevel &&
          selectedTankId == other.selectedTankId &&
          movesCount == other.movesCount &&
          bestMoves == other.bestMoves &&
          isWon == other.isWon &&
          hasShownWinDialog == other.hasShownWinDialog &&
          feedbackMessage == other.feedbackMessage &&
          shakingTankId == other.shakingTankId &&
          pendingMove == other.pendingMove &&
          isLoading == other.isLoading &&
          setEquals(completedLevels, other.completedLevels);

  @override
  int get hashCode => Object.hash(
    levelNumber,
    unlockedLevel,
    selectedTankId,
    movesCount,
    bestMoves,
    isWon,
    hasShownWinDialog,
    feedbackMessage,
    shakingTankId,
    pendingMove,
    isLoading,
  );
}
