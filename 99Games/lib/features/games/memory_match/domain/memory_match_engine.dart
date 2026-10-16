import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'memory_match_models.dart';

/// Result of evaluating a card tap on the board.
class CardFlipResult extends Equatable {
  final List<MemoryCard> cards;
  final int? firstSelectedId;
  final int? secondSelectedId;
  final bool isMatch;
  final bool isMismatch;
  final bool isMoveCompleted;
  final bool isLevelComplete;
  final int matchedPairsCount;

  const CardFlipResult({
    required this.cards,
    this.firstSelectedId,
    this.secondSelectedId,
    this.isMatch = false,
    this.isMismatch = false,
    this.isMoveCompleted = false,
    this.isLevelComplete = false,
    required this.matchedPairsCount,
  });

  @override
  List<Object?> get props => [
    cards,
    firstSelectedId,
    secondSelectedId,
    isMatch,
    isMismatch,
    isMoveCompleted,
    isLevelComplete,
    matchedPairsCount,
  ];
}

/// Pure domain matching and board manipulation engine for Memory Match.
class MemoryMatchEngine {
  final math.Random _random;

  MemoryMatchEngine({math.Random? random}) : _random = random ?? math.Random();

  /// Generates a complete shuffled deck of paired cards for a given level config.
  List<MemoryCard> createDeck(
    LevelConfig config, [
    math.Random? randomOverride,
  ]) {
    final rand = randomOverride ?? _random;
    final pairCount = config.pairCount;
    final tempCards = <_CardPrototype>[];

    for (int pairId = 0; pairId < pairCount; pairId++) {
      final artwork = config.artworks[pairId % config.artworks.length];
      // Exactly 2 cards per pair
      tempCards.add(_CardPrototype(pairId: pairId, artwork: artwork));
      tempCards.add(_CardPrototype(pairId: pairId, artwork: artwork));
    }

    // Shuffle prototypes
    tempCards.shuffle(rand);

    // Assign fixed sequential unique IDs based on layout positions
    return List<MemoryCard>.generate(
      tempCards.length,
      (index) => MemoryCard(
        id: index,
        pairId: tempCards[index].pairId,
        artwork: tempCards[index].artwork,
        isFaceUp: false,
        isMatched: false,
        isMismatching: false,
        isNewMatch: false,
      ),
      growable: false,
    );
  }

  /// Processes player tap on card with given [cardId].
  CardFlipResult? handleCardTap({
    required List<MemoryCard> currentCards,
    required int cardId,
    required int? firstSelectedId,
    required int? secondSelectedId,
    required int currentMatchedPairs,
  }) {
    // 1. Boundary & Selection locks
    if (cardId < 0 || cardId >= currentCards.length) {
      return null;
    }
    if (secondSelectedId != null) {
      return null; // Mismatch resolution in progress
    }

    final tappedCard = currentCards[cardId];
    if (tappedCard.isFaceUp || tappedCard.isMatched) {
      return null;
    }

    // 2. First card of the move
    if (firstSelectedId == null) {
      final updatedCards = currentCards.map((c) {
        if (c.id == cardId) {
          return c.copyWith(isFaceUp: true, isNewMatch: false);
        }
        return c.copyWith(isNewMatch: false);
      }).toList();

      return CardFlipResult(
        cards: updatedCards,
        firstSelectedId: cardId,
        secondSelectedId: null,
        isMatch: false,
        isMismatch: false,
        isMoveCompleted: false,
        isLevelComplete: false,
        matchedPairsCount: currentMatchedPairs,
      );
    }

    // 3. Second card of the move
    if (firstSelectedId == cardId) return null; // Cannot select same card twice

    final firstCard = currentCards[firstSelectedId];
    final isMatch = firstCard.pairId == tappedCard.pairId;

    if (isMatch) {
      final newMatchedCount = currentMatchedPairs + 1;
      final totalPairs = currentCards.length ~/ 2;
      final isComplete = newMatchedCount >= totalPairs;

      final updatedCards = currentCards.map((c) {
        if (c.id == firstSelectedId || c.id == cardId) {
          return c.copyWith(
            isFaceUp: true,
            isMatched: true,
            isMismatching: false,
            isNewMatch: true,
          );
        }
        return c.copyWith(isNewMatch: false);
      }).toList();

      return CardFlipResult(
        cards: updatedCards,
        firstSelectedId: null, // Ready for next pair immediately
        secondSelectedId: null,
        isMatch: true,
        isMismatch: false,
        isMoveCompleted: true,
        isLevelComplete: isComplete,
        matchedPairsCount: newMatchedCount,
      );
    } else {
      // Mismatch
      final updatedCards = currentCards.map((c) {
        if (c.id == firstSelectedId || c.id == cardId) {
          return c.copyWith(
            isFaceUp: true,
            isMismatching: true,
            isNewMatch: false,
          );
        }
        return c.copyWith(isNewMatch: false);
      }).toList();

      return CardFlipResult(
        cards: updatedCards,
        firstSelectedId: firstSelectedId,
        secondSelectedId: cardId,
        isMatch: false,
        isMismatch: true,
        isMoveCompleted: true,
        isLevelComplete: false,
        matchedPairsCount: currentMatchedPairs,
      );
    }
  }

  /// Flips mismatched cards back face down.
  List<MemoryCard> resolveMismatch({
    required List<MemoryCard> cards,
    required int firstId,
    required int secondId,
  }) {
    return cards.map((c) {
      if (c.id == firstId || c.id == secondId) {
        return c.copyWith(
          isFaceUp: false,
          isMismatching: false,
          isNewMatch: false,
        );
      }
      return c;
    }).toList();
  }

  /// Checks if all cards on the board are matched.
  bool isLevelComplete(List<MemoryCard> cards) {
    if (cards.isEmpty) return false;
    return cards.every((c) => c.isMatched);
  }
}

class _CardPrototype {
  final int pairId;
  final CardArtworkType artwork;

  _CardPrototype({required this.pairId, required this.artwork});
}
