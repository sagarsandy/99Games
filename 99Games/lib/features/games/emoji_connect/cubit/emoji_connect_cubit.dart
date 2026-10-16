import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/emoji_connect_engine.dart';
import '../domain/emoji_connect_level_data.dart';
import '../domain/emoji_connect_models.dart';
import '../domain/emoji_connect_storage.dart';
import 'emoji_connect_state.dart';

/// Cubit managing Emoji Connect gameplay, levels, timer, and persistence.
class EmojiConnectCubit extends Cubit<EmojiConnectState> {
  final EmojiConnectStorage _storage;
  final bool _enableTimer;
  Timer? _timer;

  EmojiConnectCubit({
    required EmojiConnectStorage storage,
    bool enableTimer = true,
  }) : _storage = storage,
       _enableTimer = enableTimer,
       super(
         EmojiConnectState(
           difficulty: EmojiConnectDifficulty.easy,
           levelNumber: 1,
           engine: EmojiConnectEngine.initial(
             EmojiConnectLevelData.getLevel(EmojiConnectDifficulty.easy, 1),
           ),
           unlockedLevel: 1,
           completedLevels: const {},
           isLoading: true,
         ),
       ) {
    _init();
  }

  Future<void> _init() async {
    final diff = await _storage.getSelectedDifficulty();
    final lvlNum = await _storage.getCurrentLevel(diff);
    final unlocked = await _storage.getUnlockedLevel(diff);
    final completed = await _storage.getCompletedLevels(diff);
    final bestTime = await _storage.getBestTime(diff, lvlNum);

    final level = EmojiConnectLevelData.getLevel(diff, lvlNum);
    final saved = await _storage.getSavedSession();

    EmojiConnectEngine initialEngine;
    int elapsed = 0;

    if (saved != null && saved.difficulty == diff && saved.levelId == lvlNum) {
      initialEngine = EmojiConnectEngine.fromSaved(
        level: level,
        savedPaths: saved.paths,
        movesCount: saved.movesCount,
      );
      elapsed = saved.elapsedSeconds;
    } else {
      initialEngine = EmojiConnectEngine.initial(level);
    }

    emit(
      state.copyWith(
        difficulty: diff,
        levelNumber: lvlNum,
        engine: initialEngine,
        unlockedLevel: unlocked,
        completedLevels: completed,
        bestTimeSeconds: bestTime,
        elapsedSeconds: elapsed,
        isLoading: false,
      ),
    );
  }

  void _startTimer() {
    if (!_enableTimer) return;
    _timer?.cancel();
    emit(state.copyWith(isTimerRunning: true));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed && !state.isWon) {
        emit(state.copyWith(elapsedSeconds: state.elapsedSeconds + 1));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    emit(state.copyWith(isTimerRunning: false));
  }

  /// Starts dragging a path from [pos].
  void startDrag(GridPosition pos) {
    if (state.isWon) return;
    if (!state.isTimerRunning) {
      _startTimer();
    }
    final updated = state.engine.startPath(pos);
    if (updated != state.engine) {
      emit(state.copyWith(engine: updated, clearHintMessage: true));
    }
  }

  /// Extends active drag path to [pos].
  void updateDrag(GridPosition pos) {
    if (state.isWon) return;
    final updated = state.engine.extendPath(pos);
    if (updated != state.engine) {
      emit(state.copyWith(engine: updated));
    }
  }

  /// Finalizes the drag interaction upon touch release.
  Future<void> endDrag() async {
    if (state.isWon) return;
    final updated = state.engine.endPath();
    emit(state.copyWith(engine: updated));

    if (updated.isCompleted) {
      await _onWin();
    } else {
      await _saveSession();
    }
  }

  /// Handles winning the level.
  Future<void> _onWin() async {
    _stopTimer();

    // Persist completion and unlock next level
    await _storage.markLevelCompleted(
      state.difficulty,
      state.levelNumber,
      timeSeconds: state.elapsedSeconds,
    );
    await _storage.clearSavedSession();

    final unlocked = await _storage.getUnlockedLevel(state.difficulty);
    final completed = await _storage.getCompletedLevels(state.difficulty);
    final bestTime = await _storage.getBestTime(
      state.difficulty,
      state.levelNumber,
    );

    emit(
      state.copyWith(
        unlockedLevel: unlocked,
        completedLevels: completed,
        bestTimeSeconds: bestTime,
      ),
    );
  }

  /// Undoes the last move.
  Future<void> undo() async {
    if (!state.canUndo) return;
    final updated = state.engine.undo();
    emit(state.copyWith(engine: updated, clearHintMessage: true));
    await _saveSession();
  }

  /// Resets the current level.
  Future<void> resetLevel() async {
    _stopTimer();
    final updated = state.engine.reset();
    emit(
      state.copyWith(
        engine: updated,
        elapsedSeconds: 0,
        clearHintMessage: true,
      ),
    );
    await _storage.clearSavedSession();
  }

  /// Requests a hint from the reference solution.
  Future<void> requestHint() async {
    if (state.isWon) return;
    if (!state.isTimerRunning) {
      _startTimer();
    }
    final (updated, message) = state.engine.applyHint();
    emit(state.copyWith(engine: updated, hintMessage: message));

    if (updated.isCompleted) {
      await _onWin();
    } else {
      await _saveSession();
    }
  }

  /// Switches to another difficulty.
  Future<void> selectDifficulty(EmojiConnectDifficulty difficulty) async {
    if (difficulty == state.difficulty) return;
    _stopTimer();

    await _storage.setSelectedDifficulty(difficulty);
    final lvlNum = await _storage.getCurrentLevel(difficulty);
    final unlocked = await _storage.getUnlockedLevel(difficulty);
    final completed = await _storage.getCompletedLevels(difficulty);
    final bestTime = await _storage.getBestTime(difficulty, lvlNum);

    final level = EmojiConnectLevelData.getLevel(difficulty, lvlNum);
    final engine = EmojiConnectEngine.initial(level);

    emit(
      state.copyWith(
        difficulty: difficulty,
        levelNumber: lvlNum,
        engine: engine,
        unlockedLevel: unlocked,
        completedLevels: completed,
        bestTimeSeconds: bestTime,
        clearBestTime: bestTime == null,
        elapsedSeconds: 0,
        clearHintMessage: true,
      ),
    );

    _startTimer();
  }

  /// Selects a specific level (must be unlocked or already completed).
  Future<void> selectLevel(int levelNumber) async {
    if (levelNumber == state.levelNumber) return;
    final maxLvl = EmojiConnectLevelData.getLevelsForDifficulty(
      state.difficulty,
    ).length;
    if (levelNumber < 1 || levelNumber > maxLvl) return;

    final unlocked = await _storage.getUnlockedLevel(state.difficulty);
    if (levelNumber > unlocked) return;

    _stopTimer();
    await _storage.setCurrentLevel(state.difficulty, levelNumber);
    final bestTime = await _storage.getBestTime(state.difficulty, levelNumber);

    final level = EmojiConnectLevelData.getLevel(state.difficulty, levelNumber);
    final engine = EmojiConnectEngine.initial(level);

    emit(
      state.copyWith(
        levelNumber: levelNumber,
        unlockedLevel: unlocked,
        engine: engine,
        bestTimeSeconds: bestTime,
        clearBestTime: bestTime == null,
        elapsedSeconds: 0,
        clearHintMessage: true,
      ),
    );

    _startTimer();
  }

  /// Advances to the next level.
  Future<void> nextLevel() async {
    if (!state.hasNextLevel) return;
    await selectLevel(state.levelNumber + 1);
  }

  /// Replays the current level from scratch.
  Future<void> replayLevel() async {
    await resetLevel();
  }

  void clearHintMessage() {
    emit(state.copyWith(clearHintMessage: true));
  }

  Future<void> _saveSession() async {
    if (state.isWon) return;

    final session = EmojiConnectSavedSession(
      difficulty: state.difficulty,
      levelId: state.levelNumber,
      paths: state.engine.paths.map((k, v) => MapEntry(k, v.points)),
      elapsedSeconds: state.elapsedSeconds,
      movesCount: state.engine.movesCount,
    );

    await _storage.saveSession(session);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
