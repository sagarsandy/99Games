import 'package:flutter/foundation.dart';
import '../domain/number_match_models.dart';

/// Immutable state representation for the Number Match game.
@immutable
class NumberMatchState {
  final List<NumberMatchTile> tiles;
  final int? selectedIndex;
  final NumberMatchPair? hintPair;
  final int score;
  final int pairsCleared;
  final int elapsedSeconds;
  final bool isTimerRunning;
  final List<NumberMatchAction> actionHistory;
  final NumberMatchGameStatus status;
  final String? feedbackMessage;
  final NumberMatchStats stats;

  const NumberMatchState({
    required this.tiles,
    this.selectedIndex,
    this.hintPair,
    this.score = 0,
    this.pairsCleared = 0,
    this.elapsedSeconds = 0,
    this.isTimerRunning = false,
    this.actionHistory = const [],
    this.status = NumberMatchGameStatus.inProgress,
    this.feedbackMessage,
    this.stats = const NumberMatchStats(),
  });

  bool get isWon => status == NumberMatchGameStatus.won;
  bool get canUndo => actionHistory.isNotEmpty && !isWon;
  int get activeCount => tiles.where((t) => !t.isCleared).length;
  int get totalRows => tiles.isEmpty ? 0 : ((tiles.length - 1) ~/ 9) + 1;

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

  NumberMatchState copyWith({
    List<NumberMatchTile>? tiles,
    int? selectedIndex,
    bool clearSelectedIndex = false,
    NumberMatchPair? hintPair,
    bool clearHintPair = false,
    int? score,
    int? pairsCleared,
    int? elapsedSeconds,
    bool? isTimerRunning,
    List<NumberMatchAction>? actionHistory,
    NumberMatchGameStatus? status,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
    NumberMatchStats? stats,
  }) {
    return NumberMatchState(
      tiles: tiles ?? this.tiles,
      selectedIndex: clearSelectedIndex
          ? null
          : (selectedIndex ?? this.selectedIndex),
      hintPair: clearHintPair ? null : (hintPair ?? this.hintPair),
      score: score ?? this.score,
      pairsCleared: pairsCleared ?? this.pairsCleared,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      actionHistory: actionHistory ?? this.actionHistory,
      status: status ?? this.status,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      stats: stats ?? this.stats,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumberMatchState &&
          runtimeType == other.runtimeType &&
          listEquals(tiles, other.tiles) &&
          selectedIndex == other.selectedIndex &&
          hintPair == other.hintPair &&
          score == other.score &&
          pairsCleared == other.pairsCleared &&
          elapsedSeconds == other.elapsedSeconds &&
          isTimerRunning == other.isTimerRunning &&
          listEquals(actionHistory, other.actionHistory) &&
          status == other.status &&
          feedbackMessage == other.feedbackMessage &&
          stats == other.stats;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(tiles),
    selectedIndex,
    hintPair,
    score,
    pairsCleared,
    elapsedSeconds,
    isTimerRunning,
    Object.hashAll(actionHistory),
    status,
    feedbackMessage,
    stats,
  );
}
