import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/sudoku_engine.dart';
import '../domain/sudoku_generator.dart';
import '../domain/sudoku_models.dart';
import '../domain/sudoku_storage.dart';
import 'sudoku_state.dart';

/// Cubit managing Sudoku game state, selection, validation, notes,
/// three-mistake tracking, undo stack, timer, and persistent sessions.
class SudokuCubit extends Cubit<SudokuState> {
  final SudokuStorage _storage;
  final SudokuEngine _engine;
  final SudokuGenerator _generator;

  Timer? _timer;

  SudokuCubit({
    required SudokuStorage storage,
    SudokuEngine? engine,
    SudokuGenerator? generator,
    SudokuDifficulty defaultDifficulty = SudokuDifficulty.easy,
  }) : _storage = storage,
       _engine = engine ?? const SudokuEngine(),
       _generator = generator ?? SudokuGenerator(),
       super(
         SudokuState(
           clues: List.filled(81, 0),
           board: List.filled(81, 0),
           solution: List.filled(81, 0),
           notes: const {},
           difficulty: defaultDifficulty,
         ),
       ) {
    init();
  }

  /// Initializes the cubit by checking for an unfinished saved session or creating a new puzzle.
  Future<void> init() async {
    final stats = await _storage.getStats(state.difficulty);
    final saved = await _storage.getSavedSession();

    if (saved != null && saved.status == SudokuGameStatus.inProgress) {
      // Restore unfinished puzzle session
      final conflicts = _engine.getConflictingIndices(saved.board);
      final incorrect = <int>{};
      for (int i = 0; i < 81; i++) {
        if (saved.board[i] != 0 &&
            saved.clues[i] == 0 &&
            saved.board[i] != saved.solution[i]) {
          incorrect.add(i);
        }
      }

      emit(
        SudokuState(
          clues: saved.clues,
          board: saved.board,
          solution: saved.solution,
          notes: saved.notes,
          selectedCell: saved.selectedCell,
          difficulty: saved.difficulty,
          mistakes: saved.mistakes,
          elapsedSeconds: saved.elapsedSeconds,
          status: saved.status,
          conflictingIndices: conflicts,
          incorrectIndices: incorrect,
          stats: stats,
        ),
      );
      _startTimer();
    } else {
      // Start a fresh puzzle
      await startNewGame(state.difficulty);
    }
  }

  /// Starts a fresh puzzle for [difficulty], resetting all state and saving the new session.
  Future<void> startNewGame(SudokuDifficulty difficulty) async {
    _stopTimer();

    final puzzle = _generator.generatePuzzle(difficulty: difficulty);
    final stats = await _storage.getStats(difficulty);

    final initialBoard = List<int>.from(puzzle.clues);
    final emptyNotes = <int, Set<int>>{};

    emit(
      SudokuState(
        clues: puzzle.clues,
        board: initialBoard,
        solution: puzzle.solution,
        notes: emptyNotes,
        selectedCell: null,
        difficulty: difficulty,
        mistakes: 0,
        elapsedSeconds: 0,
        status: SudokuGameStatus.inProgress,
        isNotesMode: false,
        undoStack: const [],
        conflictingIndices: const {},
        incorrectIndices: const {},
        stats: stats,
      ),
    );

    await _persistSession();
    _startTimer();
  }

  /// Selects the cell at [index] (0..80).
  void selectCell(int index) {
    if (state.isFinished) return;
    if (index < 0 || index >= 81) return;
    if (state.selectedCell == index) return;

    emit(state.copyWith(selectedCell: () => index));
  }

  /// Toggles pencil notes mode on / off.
  void toggleNotesMode() {
    if (state.isFinished) return;
    emit(state.copyWith(isNotesMode: !state.isNotesMode));
  }

  /// Enters [number] (1–9) into the currently selected cell.
  Future<void> enterNumber(int number) async {
    if (state.isFinished) return;
    final selectedIndex = state.selectedCell;
    if (selectedIndex == null) return;
    if (number < 1 || number > 9) return;

    // Prevent modifying prefilled immutable clues
    if (_engine.isClue(state.clues, selectedIndex)) return;

    if (state.isNotesMode) {
      // In Notes mode: toggle the candidate number in the cell's notes
      final currentNotes = Map<int, Set<int>>.from(
        state.notes.map((k, v) => MapEntry(k, Set<int>.from(v))),
      );
      final cellNotes = Set<int>.from(currentNotes[selectedIndex] ?? {});

      if (cellNotes.contains(number)) {
        cellNotes.remove(number);
      } else {
        cellNotes.add(number);
      }
      currentNotes[selectedIndex] = cellNotes;

      final action = SudokuAction(
        cellIndex: selectedIndex,
        previousValue: state.board[selectedIndex],
        newValue: state.board[selectedIndex],
        previousNotes: state.notes[selectedIndex] ?? {},
        newNotes: cellNotes,
      );

      emit(
        state.copyWith(
          notes: currentNotes,
          undoStack: [...state.undoStack, action],
        ),
      );
      await _persistSession();
      return;
    }

    // Direct number entry mode
    final previousValue = state.board[selectedIndex];
    if (previousValue == number) {
      // Re-entering the exact same number does not count as a new mistake or move
      return;
    }

    final newBoard = List<int>.from(state.board);
    newBoard[selectedIndex] = number;

    // Clear notes for this cell upon placing a number
    final currentNotes = Map<int, Set<int>>.from(
      state.notes.map((k, v) => MapEntry(k, Set<int>.from(v))),
    );
    final previousCellNotes = Set<int>.from(currentNotes[selectedIndex] ?? {});
    currentNotes.remove(selectedIndex);

    final isCorrect = _engine.isCorrectEntry(
      state.solution,
      selectedIndex,
      number,
    );

    final newIncorrect = Set<int>.from(state.incorrectIndices);
    int newMistakes = state.mistakes;

    if (!isCorrect) {
      // Mistake policy: an incorrect entry increases the mistake count once
      newMistakes++;
      newIncorrect.add(selectedIndex);
    } else {
      newIncorrect.remove(selectedIndex);
    }

    final action = SudokuAction(
      cellIndex: selectedIndex,
      previousValue: previousValue,
      newValue: number,
      previousNotes: previousCellNotes,
      newNotes: const {},
    );

    final newConflicts = _engine.getConflictingIndices(newBoard);

    // Check for Game Over (3 mistakes reached)
    if (newMistakes >= 3) {
      _stopTimer();
      await _storage.recordGameResult(difficulty: state.difficulty, won: false);
      await _storage.clearSavedSession();
      final updatedStats = await _storage.getStats(state.difficulty);

      emit(
        state.copyWith(
          board: newBoard,
          notes: currentNotes,
          mistakes: newMistakes,
          status: SudokuGameStatus.gameOver,
          conflictingIndices: newConflicts,
          incorrectIndices: newIncorrect,
          undoStack: [...state.undoStack, action],
          stats: updatedStats,
        ),
      );
      return;
    }

    // Check for Puzzle Completion
    final isWon = _engine.isBoardCompleteAndValid(newBoard, state.solution);
    if (isWon) {
      _stopTimer();
      final prevBest = state.stats.bestTimeSeconds;
      await _storage.recordGameResult(
        difficulty: state.difficulty,
        won: true,
        timeInSeconds: state.elapsedSeconds,
      );
      await _storage.clearSavedSession();
      final updatedStats = await _storage.getStats(state.difficulty);
      final isNewBest = prevBest == null || state.elapsedSeconds < prevBest;

      emit(
        state.copyWith(
          board: newBoard,
          notes: currentNotes,
          mistakes: newMistakes,
          status: SudokuGameStatus.completed,
          conflictingIndices: const {},
          incorrectIndices: const {},
          undoStack: [...state.undoStack, action],
          stats: updatedStats,
          isNewBestTime: isNewBest,
        ),
      );
      return;
    }

    // Game continues in progress
    emit(
      state.copyWith(
        board: newBoard,
        notes: currentNotes,
        mistakes: newMistakes,
        conflictingIndices: newConflicts,
        incorrectIndices: newIncorrect,
        undoStack: [...state.undoStack, action],
      ),
    );

    await _persistSession();
  }

  /// Erases the value and/or notes of the selected cell.
  Future<void> erase() async {
    if (state.isFinished) return;
    final selectedIndex = state.selectedCell;
    if (selectedIndex == null) return;

    // Do not erase immutable clues
    if (_engine.isClue(state.clues, selectedIndex)) return;

    final prevValue = state.board[selectedIndex];
    final prevNotes = Set<int>.from(state.notes[selectedIndex] ?? {});

    if (prevValue == 0 && prevNotes.isEmpty) {
      // Nothing to erase
      return;
    }

    final newBoard = List<int>.from(state.board);
    newBoard[selectedIndex] = 0;

    final currentNotes = Map<int, Set<int>>.from(
      state.notes.map((k, v) => MapEntry(k, Set<int>.from(v))),
    );
    currentNotes.remove(selectedIndex);

    final newIncorrect = Set<int>.from(state.incorrectIndices)
      ..remove(selectedIndex);
    final newConflicts = _engine.getConflictingIndices(newBoard);

    final action = SudokuAction(
      cellIndex: selectedIndex,
      previousValue: prevValue,
      newValue: 0,
      previousNotes: prevNotes,
      newNotes: const {},
    );

    emit(
      state.copyWith(
        board: newBoard,
        notes: currentNotes,
        conflictingIndices: newConflicts,
        incorrectIndices: newIncorrect,
        undoStack: [...state.undoStack, action],
      ),
    );

    await _persistSession();
  }

  /// Provides a hint by revealing the correct solution digit for the selected cell.
  ///
  /// Hints never increase the mistake count and clear the cell's notes.
  Future<void> giveHint() async {
    if (state.isFinished) return;
    final selectedIndex = state.selectedCell;
    if (selectedIndex == null) return;

    // Cannot hint a clue or already correct cell
    if (_engine.isClue(state.clues, selectedIndex)) return;
    if (state.board[selectedIndex] == state.solution[selectedIndex]) return;

    final solutionValue = state.solution[selectedIndex];
    final prevValue = state.board[selectedIndex];
    final prevNotes = Set<int>.from(state.notes[selectedIndex] ?? {});

    final newBoard = List<int>.from(state.board);
    newBoard[selectedIndex] = solutionValue;

    final currentNotes = Map<int, Set<int>>.from(
      state.notes.map((k, v) => MapEntry(k, Set<int>.from(v))),
    );
    currentNotes.remove(selectedIndex);

    final newIncorrect = Set<int>.from(state.incorrectIndices)
      ..remove(selectedIndex);
    final newConflicts = _engine.getConflictingIndices(newBoard);

    final action = SudokuAction(
      cellIndex: selectedIndex,
      previousValue: prevValue,
      newValue: solutionValue,
      previousNotes: prevNotes,
      newNotes: const {},
    );

    // Check if this hint completed the puzzle
    final isWon = _engine.isBoardCompleteAndValid(newBoard, state.solution);
    if (isWon) {
      _stopTimer();
      final prevBest = state.stats.bestTimeSeconds;
      await _storage.recordGameResult(
        difficulty: state.difficulty,
        won: true,
        timeInSeconds: state.elapsedSeconds,
      );
      await _storage.clearSavedSession();
      final updatedStats = await _storage.getStats(state.difficulty);
      final isNewBest = prevBest == null || state.elapsedSeconds < prevBest;

      emit(
        state.copyWith(
          board: newBoard,
          notes: currentNotes,
          status: SudokuGameStatus.completed,
          conflictingIndices: const {},
          incorrectIndices: const {},
          undoStack: [...state.undoStack, action],
          stats: updatedStats,
          isNewBestTime: isNewBest,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        board: newBoard,
        notes: currentNotes,
        conflictingIndices: newConflicts,
        incorrectIndices: newIncorrect,
        undoStack: [...state.undoStack, action],
      ),
    );

    await _persistSession();
  }

  /// Undoes the most recent player action.
  ///
  /// Important: Undo reverts cell entries and notes, but does NOT decrement the
  /// accumulated mistake count (the three-mistake limit remains meaningful).
  Future<void> undo() async {
    if (!state.canUndo) return;

    final stack = List<SudokuAction>.from(state.undoStack);
    final lastAction = stack.removeLast();

    final newBoard = List<int>.from(state.board);
    newBoard[lastAction.cellIndex] = lastAction.previousValue;

    final currentNotes = Map<int, Set<int>>.from(
      state.notes.map((k, v) => MapEntry(k, Set<int>.from(v))),
    );
    if (lastAction.previousNotes.isNotEmpty) {
      currentNotes[lastAction.cellIndex] = lastAction.previousNotes;
    } else {
      currentNotes.remove(lastAction.cellIndex);
    }

    final newIncorrect = Set<int>.from(state.incorrectIndices);
    if (lastAction.previousValue != 0 &&
        state.clues[lastAction.cellIndex] == 0 &&
        lastAction.previousValue != state.solution[lastAction.cellIndex]) {
      newIncorrect.add(lastAction.cellIndex);
    } else {
      newIncorrect.remove(lastAction.cellIndex);
    }

    final newConflicts = _engine.getConflictingIndices(newBoard);

    emit(
      state.copyWith(
        board: newBoard,
        notes: currentNotes,
        selectedCell: () => lastAction.cellIndex,
        conflictingIndices: newConflicts,
        incorrectIndices: newIncorrect,
        undoStack: stack,
      ),
    );

    await _persistSession();
  }

  /// Resets stats for active difficulty.
  Future<void> resetStats() async {
    await _storage.resetStats(state.difficulty);
    emit(state.copyWith(stats: SudokuStats.empty));
  }

  void pauseTimer() {
    _stopTimer();
    _persistSession();
  }

  void resumeTimer() {
    if (!state.isFinished && _timer == null) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isClosed && !state.isFinished) {
        emit(state.copyWith(elapsedSeconds: state.elapsedSeconds + 1));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _persistSession() async {
    if (state.isFinished) {
      await _storage.clearSavedSession();
      return;
    }

    final session = SudokuSavedSession(
      clues: state.clues,
      solution: state.solution,
      board: state.board,
      notes: state.notes,
      difficulty: state.difficulty,
      mistakes: state.mistakes,
      elapsedSeconds: state.elapsedSeconds,
      status: state.status,
      selectedCell: state.selectedCell,
    );
    await _storage.saveSession(session);
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
