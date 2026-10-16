import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/memory_match/domain/memory_match_engine.dart';
import 'package:mini_games_99/features/games/memory_match/domain/memory_match_level_data.dart';
import 'package:mini_games_99/features/games/memory_match/domain/memory_match_scoring.dart';

void main() {
  group('Memory Match Scoring Tests', () {
    test('1. Base score formula gives exactly 10 points per pair', () {
      expect(MemoryMatchScoring.calculateBaseScore(1), equals(10));
      expect(MemoryMatchScoring.calculateBaseScore(2), equals(20));
      expect(MemoryMatchScoring.calculateBaseScore(8), equals(80));
      expect(MemoryMatchScoring.calculateBaseScore(15), equals(150));
      expect(MemoryMatchScoring.calculateBaseScore(0), equals(0));
      expect(MemoryMatchScoring.calculateBaseScore(-5), equals(0));
    });

    test(
      '2. Efficiency bonus gives maximum 50 points for minimum moves (M = P)',
      () {
        // P = 4, M = 4 -> (2*4 - 4)/4 = 4/4 = 1.0 -> 50 * 1 = 50
        expect(
          MemoryMatchScoring.calculateEfficiencyBonus(pairCount: 4, moves: 4),
          equals(50),
        );
        // P = 10, M = 10 -> 50
        expect(
          MemoryMatchScoring.calculateEfficiencyBonus(pairCount: 10, moves: 10),
          equals(50),
        );
      },
    );

    test(
      '3. Efficiency bonus decreases gracefully as moves increase and clamps to 0',
      () {
        // P = 4, M = 6 -> (8 - 6)/4 = 2/4 = 0.5 -> 50 * 0.5 = 25
        expect(
          MemoryMatchScoring.calculateEfficiencyBonus(pairCount: 4, moves: 6),
          equals(25),
        );
        // P = 4, M = 8 -> (8 - 8)/4 = 0 -> 0
        expect(
          MemoryMatchScoring.calculateEfficiencyBonus(pairCount: 4, moves: 8),
          equals(0),
        );
        // P = 4, M = 20 -> negative -> clamped to 0
        expect(
          MemoryMatchScoring.calculateEfficiencyBonus(pairCount: 4, moves: 20),
          equals(0),
        );
      },
    );

    test(
      '4. Time bonus gives maximum 50 points when completed instantly (T = 0)',
      () {
        // Target time = 8 * P = 32s. T = 0 -> (32 - 0)/32 = 1.0 -> 50
        expect(
          MemoryMatchScoring.calculateTimeBonus(
            pairCount: 4,
            elapsedSeconds: 0,
          ),
          equals(50),
        );
      },
    );

    test(
      '5. Time bonus decreases and clamps to 0 at or beyond target time',
      () {
        // P = 4, target = 32s. T = 16s -> (32 - 16)/32 = 0.5 -> 25
        expect(
          MemoryMatchScoring.calculateTimeBonus(
            pairCount: 4,
            elapsedSeconds: 16,
          ),
          equals(25),
        );
        // T = 32s -> 0
        expect(
          MemoryMatchScoring.calculateTimeBonus(
            pairCount: 4,
            elapsedSeconds: 32,
          ),
          equals(0),
        );
        // T = 100s -> clamped to 0
        expect(
          MemoryMatchScoring.calculateTimeBonus(
            pairCount: 4,
            elapsedSeconds: 100,
          ),
          equals(0),
        );
      },
    );

    test(
      '6. Invalid scoring inputs do not crash or produce negative bonuses',
      () {
        final breakdown = MemoryMatchScoring.calculateScore(
          pairCount: 0,
          moves: -5,
          elapsedSeconds: -10,
        );
        expect(breakdown.baseScore, equals(0));
        expect(breakdown.efficiencyBonus, equals(0));
        expect(breakdown.timeBonus, equals(0));
        expect(breakdown.totalScore, equals(0));
      },
    );

    test('7. Complete score breakdown matches specified formula example', () {
      // Completing 4 pairs in 4 moves within target time (0s)
      final breakdown = MemoryMatchScoring.calculateScore(
        pairCount: 4,
        moves: 4,
        elapsedSeconds: 0,
      );
      expect(breakdown.baseScore, equals(40));
      expect(breakdown.efficiencyBonus, equals(50));
      expect(breakdown.timeBonus, equals(50));
      expect(breakdown.totalScore, equals(140));
    });
  });

  group('Memory Match Engine & Deck Tests', () {
    final engine = MemoryMatchEngine();

    test('8. Every level starts with all cards face-down and unmatched', () {
      for (int lvl = 1; lvl <= MemoryMatchLevelData.totalLevels; lvl++) {
        final config = MemoryMatchLevelData.getLevel(lvl);
        final deck = engine.createDeck(config);

        for (final card in deck) {
          expect(card.isFaceUp, isFalse);
          expect(card.isMatched, isFalse);
          expect(card.isMismatching, isFalse);
        }
      }
    });

    test('9. Every pair ID appears exactly twice in every curated level', () {
      for (int lvl = 1; lvl <= MemoryMatchLevelData.totalLevels; lvl++) {
        final config = MemoryMatchLevelData.getLevel(lvl);
        final deck = engine.createDeck(config);

        expect(deck.length, equals(config.cardCount));
        expect(deck.length, equals(config.pairCount * 2));

        final pairCounts = <int, int>{};
        for (final card in deck) {
          pairCounts[card.pairId] = (pairCounts[card.pairId] ?? 0) + 1;
        }

        expect(pairCounts.length, equals(config.pairCount));
        for (final count in pairCounts.values) {
          expect(count, equals(2));
        }
      }
    });

    test('10. Shuffling preserves the number and identity of all cards', () {
      final config = MemoryMatchLevelData.getLevel(1);
      final random = Random(42);
      final deck1 = engine.createDeck(config, random);
      final deck2 = engine.createDeck(config, Random(99));

      expect(deck1.length, equals(deck2.length));
      final ids1 = deck1.map((c) => c.pairId).toList()..sort();
      final ids2 = deck2.map((c) => c.pairId).toList()..sort();
      expect(ids1, equals(ids2));
    });

    test('11. Matching two cards with the same pair ID succeeds', () {
      final config = MemoryMatchLevelData.getLevel(1);
      final deck = engine.createDeck(config);

      // Find two cards with the same pairId
      final card1 = deck.first;
      final card2 = deck.firstWhere(
        (c) => c.id != card1.id && c.pairId == card1.pairId,
      );

      // Tap card 1
      final tap1 = engine.handleCardTap(
        currentCards: deck,
        cardId: card1.id,
        firstSelectedId: null,
        secondSelectedId: null,
        currentMatchedPairs: 0,
      );

      expect(tap1, isNotNull);
      expect(tap1!.isMoveCompleted, isFalse);
      expect(tap1.firstSelectedId, equals(card1.id));
      expect(tap1.isMatch, isFalse);

      // Tap card 2
      final tap2 = engine.handleCardTap(
        currentCards: tap1.cards,
        cardId: card2.id,
        firstSelectedId: tap1.firstSelectedId,
        secondSelectedId: null,
        currentMatchedPairs: 0,
      );

      expect(tap2, isNotNull);
      expect(tap2!.isMoveCompleted, isTrue);
      expect(tap2.isMatch, isTrue);
      expect(tap2.matchedPairsCount, equals(1));

      final updated1 = tap2.cards.firstWhere((c) => c.id == card1.id);
      final updated2 = tap2.cards.firstWhere((c) => c.id == card2.id);
      expect(updated1.isMatched, isTrue);
      expect(updated2.isMatched, isTrue);
      expect(updated1.isFaceUp, isTrue);
      expect(updated2.isFaceUp, isTrue);
    });

    test('12. Mismatched cards mark mismatch state and flip back cleanly', () {
      final config = MemoryMatchLevelData.getLevel(1);
      final deck = engine.createDeck(config);

      // Find two cards with different pairIds
      final card1 = deck.first;
      final card2 = deck.firstWhere((c) => c.pairId != card1.pairId);

      // Tap card 1
      final tap1 = engine.handleCardTap(
        currentCards: deck,
        cardId: card1.id,
        firstSelectedId: null,
        secondSelectedId: null,
        currentMatchedPairs: 0,
      );

      // Tap card 2
      final tap2 = engine.handleCardTap(
        currentCards: tap1!.cards,
        cardId: card2.id,
        firstSelectedId: tap1.firstSelectedId,
        secondSelectedId: null,
        currentMatchedPairs: 0,
      );

      expect(tap2, isNotNull);
      expect(tap2!.isMoveCompleted, isTrue);
      expect(tap2.isMatch, isFalse);
      expect(tap2.secondSelectedId, equals(card2.id));

      final c1Mismatched = tap2.cards.firstWhere((c) => c.id == card1.id);
      final c2Mismatched = tap2.cards.firstWhere((c) => c.id == card2.id);
      expect(c1Mismatched.isMismatching, isTrue);
      expect(c2Mismatched.isMismatching, isTrue);
      expect(c1Mismatched.isFaceUp, isTrue);
      expect(c2Mismatched.isFaceUp, isTrue);

      // Resolve mismatch
      final resolved = engine.resolveMismatch(
        cards: tap2.cards,
        firstId: card1.id,
        secondId: card2.id,
      );

      final c1Resolved = resolved.firstWhere((c) => c.id == card1.id);
      final c2Resolved = resolved.firstWhere((c) => c.id == card2.id);
      expect(c1Resolved.isFaceUp, isFalse);
      expect(c2Resolved.isFaceUp, isFalse);
      expect(c1Resolved.isMismatching, isFalse);
      expect(c2Resolved.isMismatching, isFalse);
    });

    test(
      '13. Tapping the same card twice returns null and does not count as move',
      () {
        final config = MemoryMatchLevelData.getLevel(1);
        final deck = engine.createDeck(config);
        final card1 = deck.first;

        final tap1 = engine.handleCardTap(
          currentCards: deck,
          cardId: card1.id,
          firstSelectedId: null,
          secondSelectedId: null,
          currentMatchedPairs: 0,
        );

        final tap2 = engine.handleCardTap(
          currentCards: tap1!.cards,
          cardId: card1.id,
          firstSelectedId: tap1.firstSelectedId,
          secondSelectedId: null,
          currentMatchedPairs: 0,
        );

        expect(tap2, isNull);
      },
    );

    test('14. Matched cards cannot be tapped again', () {
      final config = MemoryMatchLevelData.getLevel(1);
      final deck = engine.createDeck(config);

      final card1 = deck.first;
      final card2 = deck.firstWhere(
        (c) => c.id != card1.id && c.pairId == card1.pairId,
      );

      final tap1 = engine.handleCardTap(
        currentCards: deck,
        cardId: card1.id,
        firstSelectedId: null,
        secondSelectedId: null,
        currentMatchedPairs: 0,
      );

      final tap2 = engine.handleCardTap(
        currentCards: tap1!.cards,
        cardId: card2.id,
        firstSelectedId: tap1.firstSelectedId,
        secondSelectedId: null,
        currentMatchedPairs: 0,
      );

      // Attempt to tap matched card1 again
      final tapAgain = engine.handleCardTap(
        currentCards: tap2!.cards,
        cardId: card1.id,
        firstSelectedId: null,
        secondSelectedId: null,
        currentMatchedPairs: 1,
      );

      expect(tapAgain, isNull);
    });
  });
}
