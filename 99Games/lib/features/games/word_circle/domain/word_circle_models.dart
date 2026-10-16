import 'package:flutter/foundation.dart';

/// Direction in which a target word is placed on the crossword grid.
enum WordDirection { horizontal, vertical }

/// Individual letter position on the circular wheel with a unique index.
@immutable
class WheelLetter {
  final int id;
  final String letter;

  const WheelLetter({required this.id, required this.letter});

  Map<String, dynamic> toJson() => {'id': id, 'letter': letter};

  factory WheelLetter.fromJson(Map<String, dynamic> json) =>
      WheelLetter(id: json['id'] as int, letter: json['letter'] as String);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WheelLetter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          letter == other.letter;

  @override
  int get hashCode => Object.hash(id, letter);

  @override
  String toString() => 'WheelLetter($id, $letter)';
}

/// A target word placed on the crossword grid at specified coordinates.
@immutable
class TargetWord {
  final String id;
  final String word;
  final int row;
  final int col;
  final WordDirection direction;

  const TargetWord({
    required this.id,
    required this.word,
    required this.row,
    required this.col,
    required this.direction,
  });

  int get length => word.length;
  bool get isHorizontal => direction == WordDirection.horizontal;

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'row': row,
    'col': col,
    'direction': direction.name,
  };

  factory TargetWord.fromJson(Map<String, dynamic> json) => TargetWord(
    id: json['id'] as String,
    word: json['word'] as String,
    row: json['row'] as int,
    col: json['col'] as int,
    direction: WordDirection.values.firstWhere(
      (d) => d.name == json['direction'],
      orElse: () => WordDirection.horizontal,
    ),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetWord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          word == other.word &&
          row == other.row &&
          col == other.col &&
          direction == other.direction;

  @override
  int get hashCode => Object.hash(id, word, row, col, direction);

  @override
  String toString() => 'TargetWord($word at ($row, $col), ${direction.name})';
}

/// A single cell on the crossword target grid.
@immutable
class CrosswordCell {
  final int row;
  final int col;
  final String letter;
  final bool isRevealed;
  final bool isHinted;
  final Set<String> targetWordIds;

  const CrosswordCell({
    required this.row,
    required this.col,
    required this.letter,
    this.isRevealed = false,
    this.isHinted = false,
    this.targetWordIds = const {},
  });

  CrosswordCell copyWith({
    bool? isRevealed,
    bool? isHinted,
    Set<String>? targetWordIds,
  }) {
    return CrosswordCell(
      row: row,
      col: col,
      letter: letter,
      isRevealed: isRevealed ?? this.isRevealed,
      isHinted: isHinted ?? this.isHinted,
      targetWordIds: targetWordIds ?? this.targetWordIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrosswordCell &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col &&
          letter == other.letter &&
          isRevealed == other.isRevealed &&
          isHinted == other.isHinted;

  @override
  int get hashCode => Object.hash(row, col, letter, isRevealed, isHinted);
}

/// Definition of a curated Word Circle puzzle level.
@immutable
class WordCircleLevel {
  final int id;
  final String theme;
  final List<String> letters;
  final List<TargetWord> targetWords;
  final List<String> bonusWords;
  final int rows;
  final int cols;

  const WordCircleLevel({
    required this.id,
    required this.theme,
    required this.letters,
    required this.targetWords,
    this.bonusWords = const [],
    required this.rows,
    required this.cols,
  });

  int get totalTargetWords => targetWords.length;

  List<WheelLetter> generateInitialWheelLetters() {
    return List.generate(
      letters.length,
      (i) => WheelLetter(id: i, letter: letters[i].toUpperCase()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordCircleLevel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WordCircleLevel($id: $theme, ${letters.join()})';
}

/// Status outcomes when a player releases a swipe sequence.
enum WordSubmissionStatus {
  newTarget,
  newBonus,
  alreadyFound,
  invalidWord,
  tooShort,
}

/// Result of evaluating a submitted word.
@immutable
class WordCircleSubmissionResult {
  final WordSubmissionStatus status;
  final String word;
  final String? message;
  final int pointsEarned;
  final TargetWord? matchedTarget;

  const WordCircleSubmissionResult({
    required this.status,
    required this.word,
    this.message,
    this.pointsEarned = 0,
    this.matchedTarget,
  });

  bool get isSuccess =>
      status == WordSubmissionStatus.newTarget ||
      status == WordSubmissionStatus.newBonus;

  @override
  String toString() =>
      'WordCircleSubmissionResult(${status.name}, "$word", +$pointsEarned pts)';
}
