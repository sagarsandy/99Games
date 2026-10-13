import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/game_stats_storage.dart';
import '../domain/word_search_dictionary.dart';
import '../domain/word_search_engine.dart';
import '../domain/word_search_models.dart';
import 'word_search_state.dart';

/// Cubit orchestrating Word Search game lifecycle, selection tracking,
/// elapsed timer precision, and difficulty transitions.
class WordSearchCubit extends Cubit<WordSearchState> {
  final GameStatsStorage _statsStorage;
  final WordSearchEngine _engine;
  final Random _random;

  Timer? _timer;
  DateTime? _segmentStartTime;
  Duration _accumulatedDuration = Duration.zero;

  WordSearchCubit({
    required GameStatsStorage statsStorage,
    WordSearchEngine? engine,
    WordSearchDictionary? dictionary,
    WordSearchPuzzle? initialPuzzle,
    WordSearchDifficulty initialDifficulty = WordSearchDifficulty.easy,
    Random? random,
  }) : _statsStorage = statsStorage,
       _random = random ?? Random(),
       _engine =
           engine ?? WordSearchEngine(dictionary: dictionary, random: random),
       super(
         WordSearchState(
           difficulty: initialDifficulty,
           puzzle:
               initialPuzzle ??
               (engine ??
                       WordSearchEngine(dictionary: dictionary, random: random))
                   .generatePuzzle(
                     difficulty: initialDifficulty,
                     random: random,
                   ),
         ),
       ) {
    loadStats();
  }

  /// Loads best time and completed count for the current difficulty.
  Future<void> loadStats() async {
    try {
      final bestTime = await _statsStorage.getWordSearchBestTime(
        state.difficulty.name,
      );
      final completed = await _statsStorage.getWordSearchPuzzlesCompleted(
        state.difficulty.name,
      );
      if (!isClosed) {
        emit(
          state.copyWith(bestTime: () => bestTime, completedCount: completed),
        );
      }
    } catch (_) {
      // Storage errors handled gracefully without corrupting state
    }
  }

  /// Starts selection at [coord]. Starts timer on the player's first action.
  void startSelection(GridCoordinate coord) {
    if (state.isCompleted) return;

    if (!state.hasStarted) {
      _startTimer();
    }

    emit(
      state.copyWith(
        selectionStart: () => coord,
        selectionEnd: () => coord,
        currentSelection: [coord],
        hasStarted: true,
      ),
    );
  }

  /// Updates the straight-line selection from start to [coord].
  void updateSelection(GridCoordinate coord) {
    if (state.isCompleted || state.selectionStart == null) return;
    if (state.selectionEnd == coord) return;

    final line = _engine.getStraightLineCoordinates(
      state.selectionStart!,
      coord,
    );

    if (line != null) {
      emit(state.copyWith(selectionEnd: () => coord, currentSelection: line));
    }
  }

  /// Concludes the current selection, tests for word match, and handles completion.
  Future<void> endSelection() async {
    if (state.isCompleted || state.currentSelection.isEmpty) {
      _clearSelection();
      return;
    }

    final matchedWord = _engine.checkSelectionMatch(
      grid: state.grid,
      coordinates: state.currentSelection,
      targetWords: state.targetWords,
      alreadyFoundWords: state.foundWords.map((f) => f.word).toSet(),
    );

    if (matchedWord != null) {
      final updatedFound = List<FoundWord>.from(state.foundWords)
        ..add(
          FoundWord(
            word: matchedWord,
            coordinates: state.currentSelection,
            colorIndex: state.foundWords.length,
          ),
        );

      final isCompleted = _engine.isPuzzleCompleted(
        targetWords: state.targetWords,
        foundWords: updatedFound,
      );

      if (isCompleted) {
        await _handleVictory(updatedFound);
        return;
      } else {
        emit(
          state.copyWith(
            foundWords: updatedFound,
            currentSelection: const [],
            selectionStart: () => null,
            selectionEnd: () => null,
          ),
        );
        return;
      }
    }

    _clearSelection();
  }

  /// Provides accessible tap-to-select support (tap start, then tap end).
  Future<void> cellTapped(GridCoordinate coord) async {
    if (state.isCompleted) return;

    if (state.selectionStart == null) {
      startSelection(coord);
    } else if (state.selectionStart == coord) {
      _clearSelection();
    } else {
      updateSelection(coord);
      await endSelection();
    }
  }

  /// Cancels the active selection line.
  void clearSelection() {
    _clearSelection();
  }

  void _clearSelection() {
    if (!isClosed) {
      emit(
        state.copyWith(
          currentSelection: const [],
          selectionStart: () => null,
          selectionEnd: () => null,
        ),
      );
    }
  }

  Future<void> _handleVictory(List<FoundWord> finalFoundWords) async {
    _stopTimer();

    final finalSeconds = _accumulatedDuration.inSeconds;
    bool isNewBest = false;
    int? newBest = state.bestTime;
    int newCompletedCount = state.completedCount + 1;

    try {
      isNewBest = await _statsStorage.recordWordSearchCompletion(
        difficulty: state.difficulty.name,
        timeInSeconds: finalSeconds,
      );
      newBest = await _statsStorage.getWordSearchBestTime(
        state.difficulty.name,
      );
      newCompletedCount = await _statsStorage.getWordSearchPuzzlesCompleted(
        state.difficulty.name,
      );
    } catch (_) {
      // Storage errors handled gracefully
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          foundWords: finalFoundWords,
          currentSelection: const [],
          selectionStart: () => null,
          selectionEnd: () => null,
          elapsedSeconds: finalSeconds,
          isCompleted: true,
          isNewBestTime: isNewBest,
          bestTime: () => newBest,
          completedCount: newCompletedCount,
        ),
      );
    }
  }

  /// Switches difficulty, generates a corresponding fresh puzzle,
  /// and updates persisted records.
  Future<void> setDifficulty(WordSearchDifficulty difficulty) async {
    _stopTimer();
    _accumulatedDuration = Duration.zero;
    _segmentStartTime = null;

    final newPuzzle = _engine.generatePuzzle(
      difficulty: difficulty,
      random: _random,
    );

    int? bestTime;
    int completed = 0;
    try {
      bestTime = await _statsStorage.getWordSearchBestTime(difficulty.name);
      completed = await _statsStorage.getWordSearchPuzzlesCompleted(
        difficulty.name,
      );
    } catch (_) {}

    if (!isClosed) {
      emit(
        WordSearchState(
          difficulty: difficulty,
          puzzle: newPuzzle,
          bestTime: bestTime,
          completedCount: completed,
        ),
      );
    }
  }

  /// Generates a brand new puzzle for the current difficulty and resets state.
  void startNewPuzzle() {
    _stopTimer();
    _accumulatedDuration = Duration.zero;
    _segmentStartTime = null;

    final freshPuzzle = _engine.generatePuzzle(
      difficulty: state.difficulty,
      random: _random,
    );

    emit(
      WordSearchState(
        difficulty: state.difficulty,
        puzzle: freshPuzzle,
        bestTime: state.bestTime,
        completedCount: state.completedCount,
      ),
    );
  }

  /// Pauses the timer when the app enters the background or inactive state.
  void pauseTimer() {
    if (state.hasStarted && !state.isCompleted && _segmentStartTime != null) {
      _accumulatedDuration += DateTime.now().difference(_segmentStartTime!);
      _segmentStartTime = null;
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Resumes the timer when the app returns to the foreground.
  void resumeTimer() {
    if (state.hasStarted && !state.isCompleted && _segmentStartTime == null) {
      _segmentStartTime = DateTime.now();
      _runPeriodicTimer();
    }
  }

  void _startTimer() {
    _accumulatedDuration = Duration.zero;
    _segmentStartTime = DateTime.now();
    _runPeriodicTimer();
  }

  void _runPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed || _segmentStartTime == null) return;
      final currentTotal =
          _accumulatedDuration + DateTime.now().difference(_segmentStartTime!);
      emit(state.copyWith(elapsedSeconds: currentTotal.inSeconds));
    });
  }

  void _stopTimer() {
    if (_segmentStartTime != null) {
      _accumulatedDuration += DateTime.now().difference(_segmentStartTime!);
      _segmentStartTime = null;
    }
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _timer = null;
    return super.close();
  }
}
