import 'package:equatable/equatable.dart';
import '../../../../core/storage/game_stats_storage.dart';
import '../domain/number_slide_engine.dart';

/// Immutable state representing the Number Slide 15-puzzle.
class NumberSlideState extends Equatable {
  final List<int> board;
  final int emptyIndex;
  final int moves;
  final int elapsedSeconds;
  final bool hasStarted;
  final bool isSolved;
  final NumberSlideBestResult? bestResult;

  const NumberSlideState({
    required this.board,
    required this.emptyIndex,
    this.moves = 0,
    this.elapsedSeconds = 0,
    this.hasStarted = false,
    this.isSolved = false,
    this.bestResult,
  });

  /// Factory for an initial state with a provided solvable board.
  factory NumberSlideState.initial({
    required List<int> board,
    NumberSlideBestResult? bestResult,
  }) {
    final emptyIdx = board.indexOf(NumberSlideEngine.emptyTileValue);
    return NumberSlideState(
      board: List.unmodifiable(board),
      emptyIndex: emptyIdx,
      moves: 0,
      elapsedSeconds: 0,
      hasStarted: false,
      isSolved: false,
      bestResult: bestResult,
    );
  }

  /// Formatted timer string in MM:SS (or HH:MM:SS if >= 1 hour).
  String get formattedTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  NumberSlideState copyWith({
    List<int>? board,
    int? emptyIndex,
    int? moves,
    int? elapsedSeconds,
    bool? hasStarted,
    bool? isSolved,
    NumberSlideBestResult? Function()? bestResult,
  }) {
    return NumberSlideState(
      board: board ?? this.board,
      emptyIndex: emptyIndex ?? this.emptyIndex,
      moves: moves ?? this.moves,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      hasStarted: hasStarted ?? this.hasStarted,
      isSolved: isSolved ?? this.isSolved,
      bestResult: bestResult != null ? bestResult() : this.bestResult,
    );
  }

  @override
  List<Object?> get props => [
    board,
    emptyIndex,
    moves,
    elapsedSeconds,
    hasStarted,
    isSolved,
    bestResult,
  ];
}
