import 'package:equatable/equatable.dart';
import '../domain/sudoku_models.dart';

/// Immutable state representing the entire state of a Sudoku match.
class SudokuState extends Equatable {
  final List<int> clues;
  final List<int> board;
  final List<int> solution;
  final Map<int, Set<int>> notes;
  final int? selectedCell;
  final SudokuDifficulty difficulty;
  final int mistakes;
  final int elapsedSeconds;
  final SudokuGameStatus status;
  final bool isNotesMode;
  final List<SudokuAction> undoStack;
  final Set<int> conflictingIndices;
  final Set<int> incorrectIndices;
  final SudokuStats stats;
  final bool isNewBestTime;

  const SudokuState({
    required this.clues,
    required this.board,
    required this.solution,
    required this.notes,
    this.selectedCell,
    required this.difficulty,
    this.mistakes = 0,
    this.elapsedSeconds = 0,
    this.status = SudokuGameStatus.inProgress,
    this.isNotesMode = false,
    this.undoStack = const [],
    this.conflictingIndices = const {},
    this.incorrectIndices = const {},
    this.stats = SudokuStats.empty,
    this.isNewBestTime = false,
  });

  bool get isGameOver => status.isGameOver;
  bool get isCompleted => status.isCompleted;
  bool get isFinished => status.isFinished;

  bool get canUndo => undoStack.isNotEmpty && !isFinished;

  int? get selectedCellValue =>
      selectedCell != null ? board[selectedCell!] : null;

  bool get isSelectedCellClue =>
      selectedCell != null && clues[selectedCell!] != 0;

  /// Returns time formatted as MM:SS (or HH:MM:SS if over 1 hour).
  String get formattedTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  SudokuState copyWith({
    List<int>? clues,
    List<int>? board,
    List<int>? solution,
    Map<int, Set<int>>? notes,
    int? Function()? selectedCell,
    SudokuDifficulty? difficulty,
    int? mistakes,
    int? elapsedSeconds,
    SudokuGameStatus? status,
    bool? isNotesMode,
    List<SudokuAction>? undoStack,
    Set<int>? conflictingIndices,
    Set<int>? incorrectIndices,
    SudokuStats? stats,
    bool? isNewBestTime,
  }) {
    return SudokuState(
      clues: clues ?? this.clues,
      board: board ?? this.board,
      solution: solution ?? this.solution,
      notes: notes ?? this.notes,
      selectedCell: selectedCell != null ? selectedCell() : this.selectedCell,
      difficulty: difficulty ?? this.difficulty,
      mistakes: mistakes ?? this.mistakes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      status: status ?? this.status,
      isNotesMode: isNotesMode ?? this.isNotesMode,
      undoStack: undoStack ?? this.undoStack,
      conflictingIndices: conflictingIndices ?? this.conflictingIndices,
      incorrectIndices: incorrectIndices ?? this.incorrectIndices,
      stats: stats ?? this.stats,
      isNewBestTime: isNewBestTime ?? this.isNewBestTime,
    );
  }

  @override
  List<Object?> get props => [
    clues,
    board,
    solution,
    notes,
    selectedCell,
    difficulty,
    mistakes,
    elapsedSeconds,
    status,
    isNotesMode,
    undoStack,
    conflictingIndices,
    incorrectIndices,
    stats,
    isNewBestTime,
  ];
}
