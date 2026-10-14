import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Exactly three difficulty levels with target prefilled clue ranges.
enum SudokuDifficulty {
  easy(
    label: 'Easy',
    minClues: 35,
    maxClues: 40,
    targetClues: 36,
    description: 'Generous clues for casual, relaxed solving.',
  ),
  medium(
    label: 'Medium',
    minClues: 28,
    maxClues: 34,
    targetClues: 30,
    description: 'Balanced challenge requiring deductive logic.',
  ),
  hard(
    label: 'Hard',
    minClues: 22,
    maxClues: 27,
    targetClues: 24,
    description: 'Minimal clues demanding advanced Sudoku techniques.',
  );

  final String label;
  final int minClues;
  final int maxClues;
  final int targetClues;
  final String description;

  const SudokuDifficulty({
    required this.label,
    required this.minClues,
    required this.maxClues,
    required this.targetClues,
    required this.description,
  });

  static SudokuDifficulty fromName(String name) {
    return SudokuDifficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => SudokuDifficulty.easy,
    );
  }
}

/// Status of the active Sudoku game.
enum SudokuGameStatus {
  inProgress,
  completed,
  gameOver;

  bool get isGameOver => this == SudokuGameStatus.gameOver;
  bool get isCompleted => this == SudokuGameStatus.completed;
  bool get isFinished => this != SudokuGameStatus.inProgress;
}

/// 2D coordinate on the 9 × 9 board.
class SudokuCellCoordinate extends Equatable {
  final int row;
  final int col;

  const SudokuCellCoordinate(this.row, this.col)
    : assert(row >= 0 && row < 9),
      assert(col >= 0 && col < 9);

  int get index => row * 9 + col;
  int get boxIndex => (row ~/ 3) * 3 + (col ~/ 3);

  factory SudokuCellCoordinate.fromIndex(int index) {
    assert(index >= 0 && index < 81);
    return SudokuCellCoordinate(index ~/ 9, index % 9);
  }

  @override
  List<Object?> get props => [row, col];

  @override
  String toString() => '($row, $col)';
}

/// Reversible player action for Undo functionality.
class SudokuAction extends Equatable {
  final int cellIndex;
  final int previousValue;
  final int newValue;
  final Set<int> previousNotes;
  final Set<int> newNotes;

  const SudokuAction({
    required this.cellIndex,
    required this.previousValue,
    required this.newValue,
    required this.previousNotes,
    required this.newNotes,
  });

  @override
  List<Object?> get props => [
    cellIndex,
    previousValue,
    newValue,
    previousNotes,
    newNotes,
  ];
}

/// Fully generated, verified Sudoku puzzle with its unique solution.
class SudokuPuzzle extends Equatable {
  /// 81 integers: 0 for empty cells, 1–9 for immutable prefilled clues.
  final List<int> clues;

  /// 81 integers: full 1–9 solution grid.
  final List<int> solution;

  final SudokuDifficulty difficulty;

  const SudokuPuzzle({
    required this.clues,
    required this.solution,
    required this.difficulty,
  }) : assert(clues.length == 81),
       assert(solution.length == 81);

  int get clueCount => clues.where((v) => v != 0).length;

  bool isClue(int index) => clues[index] != 0;

  @override
  List<Object?> get props => [clues, solution, difficulty];
}

/// Statistics for a given Sudoku difficulty.
class SudokuStats extends Equatable {
  final int gamesCompleted;
  final int gamesWon;
  final int gamesLost;
  final int? bestTimeSeconds;

  const SudokuStats({
    this.gamesCompleted = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.bestTimeSeconds,
  });

  static const empty = SudokuStats();

  double get winRate =>
      gamesCompleted == 0 ? 0.0 : (gamesWon / gamesCompleted) * 100;

  SudokuStats copyWith({
    int? gamesCompleted,
    int? gamesWon,
    int? gamesLost,
    int? bestTimeSeconds,
  }) {
    return SudokuStats(
      gamesCompleted: gamesCompleted ?? this.gamesCompleted,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesLost: gamesLost ?? this.gamesLost,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
    );
  }

  @override
  List<Object?> get props => [
    gamesCompleted,
    gamesWon,
    gamesLost,
    bestTimeSeconds,
  ];
}

/// Serialized representation of an ongoing Sudoku match for saving & resuming.
class SudokuSavedSession extends Equatable {
  static const int currentVersion = 1;

  final int version;
  final List<int> clues;
  final List<int> solution;
  final List<int> board;
  final Map<int, Set<int>> notes;
  final SudokuDifficulty difficulty;
  final int mistakes;
  final int elapsedSeconds;
  final SudokuGameStatus status;
  final int? selectedCell;

  const SudokuSavedSession({
    this.version = currentVersion,
    required this.clues,
    required this.solution,
    required this.board,
    required this.notes,
    required this.difficulty,
    required this.mistakes,
    required this.elapsedSeconds,
    required this.status,
    this.selectedCell,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'clues': clues,
      'solution': solution,
      'board': board,
      'notes': notes.map(
        (key, value) => MapEntry(key.toString(), value.toList()),
      ),
      'difficulty': difficulty.name,
      'mistakes': mistakes,
      'elapsedSeconds': elapsedSeconds,
      'status': status.name,
      'selectedCell': selectedCell,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory SudokuSavedSession.fromMap(Map<String, dynamic> map) {
    final rawNotes = map['notes'] as Map<String, dynamic>? ?? {};
    final parsedNotes = <int, Set<int>>{};
    rawNotes.forEach((k, v) {
      final key = int.tryParse(k);
      if (key != null && v is List) {
        parsedNotes[key] = v.map((e) => e as int).toSet();
      }
    });

    return SudokuSavedSession(
      version: map['version'] as int? ?? currentVersion,
      clues: (map['clues'] as List).map((e) => e as int).toList(),
      solution: (map['solution'] as List).map((e) => e as int).toList(),
      board: (map['board'] as List).map((e) => e as int).toList(),
      notes: parsedNotes,
      difficulty: SudokuDifficulty.fromName(
        map['difficulty'] as String? ?? 'easy',
      ),
      mistakes: map['mistakes'] as int? ?? 0,
      elapsedSeconds: map['elapsedSeconds'] as int? ?? 0,
      status: SudokuGameStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SudokuGameStatus.inProgress,
      ),
      selectedCell: map['selectedCell'] as int?,
    );
  }

  factory SudokuSavedSession.fromJson(String source) =>
      SudokuSavedSession.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
    version,
    clues,
    solution,
    board,
    notes,
    difficulty,
    mistakes,
    elapsedSeconds,
    status,
    selectedCell,
  ];
}
