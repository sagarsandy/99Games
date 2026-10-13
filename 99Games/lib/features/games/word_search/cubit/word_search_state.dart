import 'package:equatable/equatable.dart';
import '../domain/word_search_models.dart';

/// Immutable state for the Word Search puzzle game.
class WordSearchState extends Equatable {
  final WordSearchPuzzle puzzle;
  final WordSearchDifficulty difficulty;
  final List<FoundWord> foundWords;
  final List<GridCoordinate> currentSelection;
  final GridCoordinate? selectionStart;
  final GridCoordinate? selectionEnd;
  final int elapsedSeconds;
  final bool hasStarted;
  final bool isCompleted;
  final int? bestTime;
  final int completedCount;
  final bool isNewBestTime;

  const WordSearchState({
    required this.puzzle,
    required this.difficulty,
    this.foundWords = const [],
    this.currentSelection = const [],
    this.selectionStart,
    this.selectionEnd,
    this.elapsedSeconds = 0,
    this.hasStarted = false,
    this.isCompleted = false,
    this.bestTime,
    this.completedCount = 0,
    this.isNewBestTime = false,
  });

  List<List<String>> get grid => puzzle.grid;

  List<String> get targetWords => puzzle.targetWords;

  int get foundCount => foundWords.length;

  int get totalWords => targetWords.length;

  double get progress => totalWords == 0 ? 0.0 : foundCount / totalWords;

  bool isWordFound(String word) =>
      foundWords.any((f) => f.word.toUpperCase() == word.toUpperCase());

  /// Formatted elapsed time in MM:SS (or HH:MM:SS if >= 1 hour).
  String get formattedTime => formatDuration(elapsedSeconds);

  /// Formatted best time in MM:SS (or '--:--' if unrecorded).
  String get formattedBestTime =>
      bestTime != null ? formatDuration(bestTime!) : '--:--';

  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  WordSearchState copyWith({
    WordSearchPuzzle? puzzle,
    WordSearchDifficulty? difficulty,
    List<FoundWord>? foundWords,
    List<GridCoordinate>? currentSelection,
    GridCoordinate? Function()? selectionStart,
    GridCoordinate? Function()? selectionEnd,
    int? elapsedSeconds,
    bool? hasStarted,
    bool? isCompleted,
    int? Function()? bestTime,
    int? completedCount,
    bool? isNewBestTime,
  }) {
    return WordSearchState(
      puzzle: puzzle ?? this.puzzle,
      difficulty: difficulty ?? this.difficulty,
      foundWords: foundWords ?? this.foundWords,
      currentSelection: currentSelection ?? this.currentSelection,
      selectionStart: selectionStart != null
          ? selectionStart()
          : this.selectionStart,
      selectionEnd: selectionEnd != null ? selectionEnd() : this.selectionEnd,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      hasStarted: hasStarted ?? this.hasStarted,
      isCompleted: isCompleted ?? this.isCompleted,
      bestTime: bestTime != null ? bestTime() : this.bestTime,
      completedCount: completedCount ?? this.completedCount,
      isNewBestTime: isNewBestTime ?? this.isNewBestTime,
    );
  }

  @override
  List<Object?> get props => [
    puzzle,
    difficulty,
    foundWords,
    currentSelection,
    selectionStart,
    selectionEnd,
    elapsedSeconds,
    hasStarted,
    isCompleted,
    bestTime,
    completedCount,
    isNewBestTime,
  ];
}
