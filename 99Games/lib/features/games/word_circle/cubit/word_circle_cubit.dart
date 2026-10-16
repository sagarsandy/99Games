import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/word_circle_engine.dart';
import '../domain/word_circle_level_data.dart';
import '../domain/word_circle_models.dart';
import '../domain/word_circle_storage.dart';
import 'word_circle_state.dart';

/// Cubit managing game state, word dragging, puzzle completion, and storage for Word Circle.
class WordCircleCubit extends Cubit<WordCircleState> {
  final WordCircleStorage storage;
  final WordCircleEngine engine;

  WordCircleCubit({
    required this.storage,
    this.engine = const WordCircleEngine(),
  }) : super(WordCircleState.initial()) {
    loadInitial();
  }

  /// Loads stored level progress, unlocked status, and saved in-progress session.
  Future<void> loadInitial() async {
    final currentLevel = await storage.getCurrentLevel();
    final unlocked = await storage.getUnlockedLevel();
    final completed = await storage.getCompletedLevels();
    final best = await storage.getBestScore(currentLevel);

    final level = WordCircleLevelData.getLevel(currentLevel);
    final session = await storage.getSavedSession();

    if (session != null && session.levelNumber == currentLevel) {
      final isWon = engine.isLevelComplete(
        level,
        session.foundTargetWords.toSet(),
      );

      emit(
        WordCircleState(
          levelNumber: currentLevel,
          unlockedLevel: unlocked,
          completedLevels: completed,
          level: level,
          wheelLetters: level.generateInitialWheelLetters(),
          foundTargetWords: session.foundTargetWords.toSet(),
          foundBonusWords: session.foundBonusWords.toSet(),
          hintedCellKeys: session.hintedCellKeys.toSet(),
          score: session.score,
          bestScore: best,
          isWon: isWon,
          hasShownWinDialog: false,
          isLoading: false,
        ),
      );
    } else {
      emit(
        WordCircleState(
          levelNumber: currentLevel,
          unlockedLevel: unlocked,
          completedLevels: completed,
          level: level,
          wheelLetters: level.generateInitialWheelLetters(),
          score: 0,
          bestScore: best,
          isLoading: false,
        ),
      );
    }
  }

  /// Begins a new drag starting from the tile with [letterId].
  void startDrag(int letterId, {Offset? pointerPos}) {
    if (state.isWon) return;
    if (!state.wheelLetters.any((wl) => wl.id == letterId)) return;

    emit(
      state.copyWith(
        selectedLetterIds: [letterId],
        pointerPosition: () => pointerPos,
        feedbackMessage: () => null,
      ),
    );
  }

  /// Updates pointer coordinates for dynamic connecting line while dragging.
  void updatePointer(Offset pointerPos) {
    if (state.selectedLetterIds.isEmpty) return;
    emit(state.copyWith(pointerPosition: () => pointerPos));
  }

  /// Handles entering another letter tile during a continuous swipe.
  void addLetterToDrag(int letterId, {Offset? pointerPos}) {
    if (state.isWon) return;

    if (state.selectedLetterIds.isEmpty) {
      startDrag(letterId, pointerPos: pointerPos);
      return;
    }

    // Already the top letter: update pointer position
    if (state.selectedLetterIds.last == letterId) {
      if (pointerPos != null) updatePointer(pointerPos);
      return;
    }

    // Backtracking / reversing over previous letter: retract last selection
    if (state.selectedLetterIds.length >= 2 &&
        state.selectedLetterIds[state.selectedLetterIds.length - 2] ==
            letterId) {
      final retracted = List<int>.from(state.selectedLetterIds)..removeLast();
      emit(
        state.copyWith(
          selectedLetterIds: retracted,
          pointerPosition: () => pointerPos,
          feedbackMessage: () => null,
        ),
      );
      return;
    }

    // Avoid reusing an already-selected wheel letter position
    if (state.selectedLetterIds.contains(letterId)) {
      if (pointerPos != null) updatePointer(pointerPos);
      return;
    }

    // Append newly entered letter to the active selection
    emit(
      state.copyWith(
        selectedLetterIds: [...state.selectedLetterIds, letterId],
        pointerPosition: () => pointerPos,
        feedbackMessage: () => null,
      ),
    );
  }

  /// Releases pointer and evaluates the formed word.
  Future<void> endDrag() async {
    if (state.selectedLetterIds.isEmpty) return;

    final word = state.currentWord;

    // Clear active selection immediately
    emit(
      state.copyWith(selectedLetterIds: const [], pointerPosition: () => null),
    );

    if (word.isEmpty) return;

    final result = engine.submitWord(
      rawWord: word,
      level: state.level,
      foundTargetWords: state.foundTargetWords,
      foundBonusWords: state.foundBonusWords,
    );

    switch (result.status) {
      case WordSubmissionStatus.newTarget:
        final newTargets = {...state.foundTargetWords, result.word};
        final newScore = state.score + result.pointsEarned;
        final isWon = engine.isLevelComplete(state.level, newTargets);

        emit(
          state.copyWith(
            foundTargetWords: newTargets,
            score: newScore,
            feedbackMessage: () => result.message,
            isWon: isWon,
            hasShownWinDialog: false,
          ),
        );

        if (isWon) {
          await _handleWin(newScore);
        } else {
          _persistSession();
        }
        break;

      case WordSubmissionStatus.newBonus:
        final newBonus = {...state.foundBonusWords, result.word};
        final newScore = state.score + result.pointsEarned;

        emit(
          state.copyWith(
            foundBonusWords: newBonus,
            score: newScore,
            feedbackMessage: () => result.message,
          ),
        );
        _persistSession();
        break;

      case WordSubmissionStatus.alreadyFound:
      case WordSubmissionStatus.invalidWord:
      case WordSubmissionStatus.tooShort:
        emit(state.copyWith(feedbackMessage: () => result.message));
        break;
    }
  }

  /// Clears active selection and transient drag pointer.
  void clearSelection() {
    emit(
      state.copyWith(selectedLetterIds: const [], pointerPosition: () => null),
    );
  }

  /// Shuffles the order of letters around the wheel.
  void shuffleWheel({math.Random? random}) {
    if (state.isWon) return;
    final shuffled = List<WheelLetter>.from(state.wheelLetters);
    shuffled.shuffle(random);
    emit(state.copyWith(wheelLetters: shuffled));
  }

  /// Consumes a hint to reveal the next unrevealed letter in an unsolved target word.
  void useHint() {
    if (state.isWon) return;

    final nextKey = engine.getNextHintCell(
      level: state.level,
      foundTargetWords: state.foundTargetWords,
      hintedCellKeys: state.hintedCellKeys,
    );

    if (nextKey == null) {
      emit(state.copyWith(feedbackMessage: () => 'All words revealed!'));
      return;
    }

    final newHinted = {...state.hintedCellKeys, nextKey};
    emit(
      state.copyWith(
        hintedCellKeys: newHinted,
        feedbackMessage: () => 'Letter revealed!',
      ),
    );
    _persistSession();
  }

  /// Resets progress on the current level back to initial state.
  void restartLevel() {
    emit(
      state.copyWith(
        foundTargetWords: const {},
        foundBonusWords: const {},
        hintedCellKeys: const {},
        score: 0,
        selectedLetterIds: const [],
        pointerPosition: () => null,
        feedbackMessage: () => null,
        isWon: false,
        hasShownWinDialog: false,
        wheelLetters: state.level.generateInitialWheelLetters(),
      ),
    );
    storage.clearSavedSession();
  }

  /// Changes to a specific unlocked level.
  Future<void> selectLevel(int levelNumber) async {
    if (levelNumber < 1 ||
        levelNumber > WordCircleLevelData.totalLevels ||
        levelNumber > state.unlockedLevel) {
      return;
    }

    final level = WordCircleLevelData.getLevel(levelNumber);
    final best = await storage.getBestScore(levelNumber);
    await storage.setCurrentLevel(levelNumber);

    emit(
      state.copyWith(
        levelNumber: levelNumber,
        level: level,
        wheelLetters: level.generateInitialWheelLetters(),
        foundTargetWords: const {},
        foundBonusWords: const {},
        hintedCellKeys: const {},
        score: 0,
        bestScore: () => best,
        selectedLetterIds: const [],
        pointerPosition: () => null,
        feedbackMessage: () => null,
        isWon: false,
        hasShownWinDialog: false,
      ),
    );

    await storage.clearSavedSession();
  }

  /// Advances to the next unlocked level if available.
  Future<void> nextLevel() async {
    if (!state.hasNextLevel) return;
    await selectLevel(state.levelNumber + 1);
  }

  /// Marks that the completion dialog has been presented.
  void markWinDialogShown() {
    emit(state.copyWith(hasShownWinDialog: true));
  }

  /// Clears active feedback message.
  void clearFeedback() {
    emit(state.copyWith(feedbackMessage: () => null));
  }

  void _persistSession() {
    storage.saveSession(
      WordCircleSavedSession(
        levelNumber: state.levelNumber,
        foundTargetWords: state.foundTargetWords.toList(),
        foundBonusWords: state.foundBonusWords.toList(),
        hintedCellKeys: state.hintedCellKeys.toList(),
        score: state.score,
      ),
    );
  }

  Future<void> _handleWin(int finalScore) async {
    final lvl = state.levelNumber;
    await storage.markLevelCompleted(lvl, score: finalScore);

    final unlocked = await storage.getUnlockedLevel();
    final completed = await storage.getCompletedLevels();
    final best = await storage.getBestScore(lvl);

    emit(
      state.copyWith(
        unlockedLevel: unlocked,
        completedLevels: completed,
        bestScore: () => best,
      ),
    );
  }
}
