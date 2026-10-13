import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/game_stats_storage.dart';
import '../domain/number_slide_engine.dart';
import 'number_slide_state.dart';

/// Cubit managing board interactions, timer lifecycle, and score records.
class NumberSlideCubit extends Cubit<NumberSlideState> {
  final GameStatsStorage _statsStorage;
  final NumberSlideEngine _engine;

  Timer? _timer;
  DateTime? _segmentStartTime;
  Duration _accumulatedDuration = Duration.zero;

  NumberSlideCubit({
    required GameStatsStorage statsStorage,
    NumberSlideEngine? engine,
    List<int>? initialBoard,
  }) : _statsStorage = statsStorage,
       _engine = engine ?? NumberSlideEngine(),
       super(
         NumberSlideState.initial(
           board:
               initialBoard ??
               (engine ?? NumberSlideEngine()).generateSolvableBoard(),
         ),
       ) {
    loadBestResult();
  }

  /// Loads the persisted best result from storage.
  Future<void> loadBestResult() async {
    try {
      final best = await _statsStorage.getNumberSlideBestResult();
      if (!isClosed) {
        emit(state.copyWith(bestResult: () => best));
      }
    } catch (_) {
      // Gracefully handle storage errors without state corruption
    }
  }

  /// Slides the tile at [tileIndex] into the empty cell if adjacent.
  Future<void> makeMove(int tileIndex) async {
    if (state.isSolved) return;
    if (!_engine.canMove(state.board, tileIndex)) return;

    // Start timing upon first valid move
    if (!state.hasStarted) {
      _startTimer();
    }

    final newBoard = _engine.applyMove(state.board, tileIndex);
    final newMoves = state.moves + 1;
    final solved = _engine.isSolved(newBoard);

    if (solved) {
      await _handleVictory(newBoard, newMoves);
    } else {
      emit(
        state.copyWith(
          board: newBoard,
          emptyIndex: _engine.getEmptyIndex(newBoard),
          moves: newMoves,
          hasStarted: true,
        ),
      );
    }
  }

  Future<void> _handleVictory(List<int> finalBoard, int finalMoves) async {
    _stopTimer();

    final finalSeconds = _accumulatedDuration.inSeconds;
    final candidate = NumberSlideBestResult(
      moves: finalMoves,
      timeInSeconds: finalSeconds,
    );

    NumberSlideBestResult? updatedBest = state.bestResult;
    try {
      await _statsStorage.recordNumberSlideResult(candidate);
      updatedBest = await _statsStorage.getNumberSlideBestResult();
    } catch (_) {
      // Storage error handled gracefully
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          board: finalBoard,
          emptyIndex: _engine.getEmptyIndex(finalBoard),
          moves: finalMoves,
          elapsedSeconds: finalSeconds,
          hasStarted: true,
          isSolved: true,
          bestResult: () => updatedBest,
        ),
      );
    }
  }

  /// Generates a brand new solvable puzzle and resets gameplay stats.
  void startNewGame() {
    _stopTimer();
    _accumulatedDuration = Duration.zero;
    _segmentStartTime = null;

    final freshBoard = _engine.generateSolvableBoard();

    emit(
      state.copyWith(
        board: freshBoard,
        emptyIndex: _engine.getEmptyIndex(freshBoard),
        moves: 0,
        elapsedSeconds: 0,
        hasStarted: false,
        isSolved: false,
      ),
    );
  }

  /// Pauses the timer when the app enters the background or inactive state.
  void pauseTimer() {
    if (state.hasStarted && !state.isSolved && _segmentStartTime != null) {
      _accumulatedDuration += DateTime.now().difference(_segmentStartTime!);
      _segmentStartTime = null;
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Resumes the timer when the app returns to the foreground.
  void resumeTimer() {
    if (state.hasStarted && !state.isSolved && _segmentStartTime == null) {
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
