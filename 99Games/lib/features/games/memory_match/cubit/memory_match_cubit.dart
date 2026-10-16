import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/memory_match_engine.dart';
import '../domain/memory_match_level_data.dart';
import '../domain/memory_match_models.dart';
import '../domain/memory_match_scoring.dart';
import '../domain/memory_match_storage.dart';
import 'memory_match_state.dart';

/// Cubit managing state and interactions for Game 14: Memory Match.
class MemoryMatchCubit extends Cubit<MemoryMatchState> {
  final MemoryMatchStorage storage;
  final MemoryMatchEngine engine;

  Timer? _timer;

  MemoryMatchCubit({required this.storage, MemoryMatchEngine? engine})
    : engine = engine ?? MemoryMatchEngine(),
      super(const MemoryMatchState());

  /// Convenience alias for initializing.
  Future<void> init() => loadInitial();

  /// Loads saved progress and initializes the board in ready state.
  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true));
    final highestUnlocked = await storage.getHighestUnlockedLevel();
    final bestScore = await storage.getBestScore(1);

    final config = MemoryMatchLevelData.getLevel(1);
    final initialCards = engine.createDeck(config);

    emit(
      state.copyWith(
        status: GameStatus.ready,
        currentLevel: 1,
        highestUnlockedLevel: highestUnlocked,
        cards: initialCards,
        totalPairs: config.pairCount,
        matchedPairs: 0,
        moves: 0,
        elapsedSeconds: 0,
        bestScoreForLevel: bestScore,
        isLoading: false,
        clearFirstSelected: true,
        clearSecondSelected: true,
        isResolvingMismatch: false,
      ),
    );
  }

  /// Starts playing the current level from the start screen.
  Future<void> startGame() => startLevel(state.currentLevel);

  /// Starts or restarts a specific level.
  Future<void> startLevel(int level) async {
    _stopTimer();

    final safeLevel = level.clamp(1, MemoryMatchLevelData.totalLevels);
    final config = MemoryMatchLevelData.getLevel(safeLevel);
    final newCards = engine.createDeck(config);
    final bestScore = await storage.getBestScore(safeLevel);

    emit(
      state.copyWith(
        status: GameStatus.playing,
        currentLevel: safeLevel,
        cards: newCards,
        totalPairs: config.pairCount,
        matchedPairs: 0,
        moves: 0,
        elapsedSeconds: 0,
        currentScore: 0,
        bestScoreForLevel: bestScore,
        isNewBest: false,
        clearScoreBreakdown: true,
        clearFirstSelected: true,
        clearSecondSelected: true,
        isResolvingMismatch: false,
        roundToken: state.roundToken + 1,
      ),
    );
  }

  /// Handles player tapping a card on the grid.
  Future<void> onCardTapped(int cardId) async {
    if (!state.isPlaying || state.isResolvingMismatch) return;

    // Start timer on first card tap
    if (_timer == null) {
      _startTimer();
    }

    final result = engine.handleCardTap(
      currentCards: state.cards,
      cardId: cardId,
      firstSelectedId: state.firstSelectedId,
      secondSelectedId: state.secondSelectedId,
      currentMatchedPairs: state.matchedPairs,
    );

    if (result == null) return;

    final newMoves = result.isMoveCompleted ? state.moves + 1 : state.moves;

    if (result.isMatch) {
      final newScore = state.currentScore + 10;

      if (result.isLevelComplete) {
        _stopTimer();

        final breakdown = MemoryMatchScoring.calculateScore(
          pairCount: state.totalPairs,
          moves: newMoves,
          elapsedSeconds: state.elapsedSeconds,
        );

        final isNewRecord = breakdown.totalScore > state.bestScoreForLevel;
        final newBest = isNewRecord
            ? breakdown.totalScore
            : state.bestScoreForLevel;

        await storage.setBestScore(state.currentLevel, breakdown.totalScore);
        await storage.setBestMoves(state.currentLevel, newMoves);
        await storage.setBestTime(state.currentLevel, state.elapsedSeconds);

        var newHighest = state.highestUnlockedLevel;
        if (state.currentLevel >= state.highestUnlockedLevel &&
            state.currentLevel < MemoryMatchLevelData.totalLevels) {
          newHighest = state.currentLevel + 1;
          await storage.setHighestUnlockedLevel(newHighest);
        }

        emit(
          state.copyWith(
            status: GameStatus.completed,
            cards: result.cards,
            moves: newMoves,
            matchedPairs: result.matchedPairsCount,
            currentScore: breakdown.totalScore,
            bestScoreForLevel: newBest,
            isNewBest: isNewRecord,
            highestUnlockedLevel: newHighest,
            scoreBreakdown: breakdown,
            clearFirstSelected: true,
            clearSecondSelected: true,
            isResolvingMismatch: false,
          ),
        );
      } else {
        // Matched a pair, but level continues
        emit(
          state.copyWith(
            cards: result.cards,
            moves: newMoves,
            matchedPairs: result.matchedPairsCount,
            currentScore: newScore,
            clearFirstSelected: true,
            clearSecondSelected: true,
            isResolvingMismatch: false,
          ),
        );
      }
    } else if (result.isMismatch) {
      // Two mismatched cards displayed
      final token = state.roundToken;
      final firstId = result.firstSelectedId!;
      final secondId = result.secondSelectedId!;

      emit(
        state.copyWith(
          cards: result.cards,
          firstSelectedId: firstId,
          secondSelectedId: secondId,
          moves: newMoves,
          isResolvingMismatch: true,
        ),
      );

      // Brief pause to view both mismatched cards (~800ms)
      await Future.delayed(const Duration(milliseconds: 800));

      // Guard against disposal, restart, or level change
      if (isClosed || state.roundToken != token) return;

      final restoredCards = engine.resolveMismatch(
        cards: state.cards,
        firstId: firstId,
        secondId: secondId,
      );

      emit(
        state.copyWith(
          cards: restoredCards,
          clearFirstSelected: true,
          clearSecondSelected: true,
          isResolvingMismatch: false,
        ),
      );
    } else {
      // First card flipped face-up
      emit(
        state.copyWith(
          cards: result.cards,
          firstSelectedId: result.firstSelectedId,
          clearSecondSelected: true,
          moves: newMoves,
          isResolvingMismatch: false,
        ),
      );
    }
  }

  /// Restarts the active level with fresh shuffle.
  Future<void> restartLevel() => startLevel(state.currentLevel);

  /// Advances to the next level if unlocked.
  Future<void> nextLevel() async {
    if (state.currentLevel < MemoryMatchLevelData.totalLevels) {
      await startLevel(state.currentLevel + 1);
    }
  }

  /// Selects a level directly from level picker.
  Future<void> selectLevel(int level) async {
    if (level <= state.highestUnlockedLevel) {
      await startLevel(level);
    }
  }

  /// Increments game timer every second.
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isClosed && state.isPlaying) {
        emit(state.copyWith(elapsedSeconds: state.elapsedSeconds + 1));
      } else {
        timer.cancel();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
