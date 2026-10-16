import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../domain/word_circle_level_data.dart';
import '../domain/word_circle_models.dart';

/// Immutable UI state for the Word Circle puzzle game.
@immutable
class WordCircleState {
  final int levelNumber;
  final int unlockedLevel;
  final Set<int> completedLevels;
  final WordCircleLevel level;
  final List<WheelLetter> wheelLetters;
  final List<int> selectedLetterIds;
  final Offset? pointerPosition;
  final Set<String> foundTargetWords;
  final Set<String> foundBonusWords;
  final Set<String> hintedCellKeys;
  final int score;
  final int? bestScore;
  final String? feedbackMessage;
  final bool isWon;
  final bool hasShownWinDialog;
  final bool isLoading;

  const WordCircleState({
    required this.levelNumber,
    this.unlockedLevel = 1,
    this.completedLevels = const {},
    required this.level,
    required this.wheelLetters,
    this.selectedLetterIds = const [],
    this.pointerPosition,
    this.foundTargetWords = const {},
    this.foundBonusWords = const {},
    this.hintedCellKeys = const {},
    this.score = 0,
    this.bestScore,
    this.feedbackMessage,
    this.isWon = false,
    this.hasShownWinDialog = false,
    this.isLoading = false,
  });

  factory WordCircleState.initial() {
    final lvl = WordCircleLevelData.getLevel(1);
    return WordCircleState(
      levelNumber: 1,
      level: lvl,
      wheelLetters: lvl.generateInitialWheelLetters(),
      isLoading: true,
    );
  }

  /// Word currently being formed by dragging letters on the wheel.
  String get currentWord {
    if (selectedLetterIds.isEmpty) return '';
    final letterMap = {for (final wl in wheelLetters) wl.id: wl.letter};
    return selectedLetterIds.map((id) => letterMap[id] ?? '').join();
  }

  int get targetWordsFoundCount => foundTargetWords.length;
  int get targetWordsTotalCount => level.totalTargetWords;
  int get targetWordsRemaining =>
      (level.totalTargetWords - foundTargetWords.length).clamp(0, 999);
  int get bonusWordsCount => foundBonusWords.length;

  bool get hasNextLevel => levelNumber < WordCircleLevelData.totalLevels;
  bool get hasPrevLevel => levelNumber > 1;

  WordCircleState copyWith({
    int? levelNumber,
    int? unlockedLevel,
    Set<int>? completedLevels,
    WordCircleLevel? level,
    List<WheelLetter>? wheelLetters,
    List<int>? selectedLetterIds,
    ValueGetter<Offset?>? pointerPosition,
    Set<String>? foundTargetWords,
    Set<String>? foundBonusWords,
    Set<String>? hintedCellKeys,
    int? score,
    ValueGetter<int?>? bestScore,
    ValueGetter<String?>? feedbackMessage,
    bool? isWon,
    bool? hasShownWinDialog,
    bool? isLoading,
  }) {
    return WordCircleState(
      levelNumber: levelNumber ?? this.levelNumber,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      completedLevels: completedLevels ?? this.completedLevels,
      level: level ?? this.level,
      wheelLetters: wheelLetters ?? this.wheelLetters,
      selectedLetterIds: selectedLetterIds ?? this.selectedLetterIds,
      pointerPosition: pointerPosition != null
          ? pointerPosition()
          : this.pointerPosition,
      foundTargetWords: foundTargetWords ?? this.foundTargetWords,
      foundBonusWords: foundBonusWords ?? this.foundBonusWords,
      hintedCellKeys: hintedCellKeys ?? this.hintedCellKeys,
      score: score ?? this.score,
      bestScore: bestScore != null ? bestScore() : this.bestScore,
      feedbackMessage: feedbackMessage != null
          ? feedbackMessage()
          : this.feedbackMessage,
      isWon: isWon ?? this.isWon,
      hasShownWinDialog: hasShownWinDialog ?? this.hasShownWinDialog,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordCircleState &&
          runtimeType == other.runtimeType &&
          levelNumber == other.levelNumber &&
          unlockedLevel == other.unlockedLevel &&
          setEquals(completedLevels, other.completedLevels) &&
          level == other.level &&
          listEquals(wheelLetters, other.wheelLetters) &&
          listEquals(selectedLetterIds, other.selectedLetterIds) &&
          pointerPosition == other.pointerPosition &&
          setEquals(foundTargetWords, other.foundTargetWords) &&
          setEquals(foundBonusWords, other.foundBonusWords) &&
          setEquals(hintedCellKeys, other.hintedCellKeys) &&
          score == other.score &&
          bestScore == other.bestScore &&
          feedbackMessage == other.feedbackMessage &&
          isWon == other.isWon &&
          hasShownWinDialog == other.hasShownWinDialog &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(
    levelNumber,
    unlockedLevel,
    Object.hashAll(completedLevels),
    level,
    Object.hashAll(wheelLetters),
    Object.hashAll(selectedLetterIds),
    pointerPosition,
    Object.hashAll(foundTargetWords),
    Object.hashAll(foundBonusWords),
    Object.hashAll(hintedCellKeys),
    score,
    bestScore,
    feedbackMessage,
    isWon,
    hasShownWinDialog,
    isLoading,
  );
}
