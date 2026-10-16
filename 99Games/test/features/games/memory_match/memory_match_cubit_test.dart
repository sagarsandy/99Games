import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/memory_match/cubit/memory_match_cubit.dart';
import 'package:mini_games_99/features/games/memory_match/domain/memory_match_models.dart';
import 'package:mini_games_99/features/games/memory_match/domain/memory_match_storage.dart';

class MockMemoryMatchStorage implements MemoryMatchStorage {
  int _highestUnlocked = 1;
  final Map<int, int> _bestScores = {};
  final Map<int, int> _bestMoves = {};
  final Map<int, int> _bestTimes = {};

  MockMemoryMatchStorage({
    int initialUnlocked = 1,
    Map<int, int>? initialScores,
  }) : _highestUnlocked = initialUnlocked {
    if (initialScores != null) {
      _bestScores.addAll(initialScores);
    }
  }

  @override
  Future<int> getHighestUnlockedLevel() async => _highestUnlocked;

  @override
  Future<void> setHighestUnlockedLevel(int level) async {
    if (level > _highestUnlocked) {
      _highestUnlocked = level;
    }
  }

  @override
  Future<int> getBestScore(int level) async => _bestScores[level] ?? 0;

  @override
  Future<void> setBestScore(int level, int score) async {
    final current = _bestScores[level] ?? 0;
    if (score > current) {
      _bestScores[level] = score;
    }
  }

  @override
  Future<int> getTotalBestScore() async =>
      _bestScores.values.fold<int>(0, (sum, s) => sum + s);

  @override
  Future<int> getBestMoves(int level) async => _bestMoves[level] ?? 0;

  @override
  Future<void> setBestMoves(int level, int moves) async {
    _bestMoves[level] = moves;
  }

  @override
  Future<int> getBestTime(int level) async => _bestTimes[level] ?? 0;

  @override
  Future<void> setBestTime(int level, int seconds) async {
    _bestTimes[level] = seconds;
  }

  @override
  Future<void> resetAll() async {
    _highestUnlocked = 1;
    _bestScores.clear();
    _bestMoves.clear();
    _bestTimes.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MemoryMatchCubit Lifecycle & Gameplay Tests', () {
    test(
      '1. Initial state is ready, loads saved highest unlocked level and best score',
      () async {
        final storage = MockMemoryMatchStorage(
          initialUnlocked: 3,
          initialScores: {1: 120, 2: 130},
        );
        final cubit = MemoryMatchCubit(storage: storage);

        expect(cubit.state.status, equals(GameStatus.ready));
        expect(cubit.state.currentLevel, equals(1));
        expect(cubit.state.highestUnlockedLevel, equals(1));

        await cubit.loadInitial();

        expect(cubit.state.highestUnlockedLevel, equals(3));
        expect(cubit.state.bestScoreForLevel, equals(120));
        expect(cubit.state.cards.isNotEmpty, isTrue);
        expect(cubit.state.cards.every((c) => !c.isFaceUp), isTrue);

        await cubit.close();
      },
    );

    test(
      '2. startGame transitions status to playing with zero moves and score',
      () async {
        final storage = MockMemoryMatchStorage();
        final cubit = MemoryMatchCubit(storage: storage);
        await cubit.loadInitial();

        await cubit.startGame();

        expect(cubit.state.status, equals(GameStatus.playing));
        expect(cubit.state.moves, equals(0));
        expect(cubit.state.currentScore, equals(0));
        expect(cubit.state.elapsedSeconds, equals(0));
        expect(cubit.state.matchedPairs, equals(0));
        expect(cubit.state.firstSelectedId, isNull);

        await cubit.close();
      },
    );

    test(
      '3. Tapping two matching cards updates matchedPairs and adds 10 base points',
      () async {
        final storage = MockMemoryMatchStorage();
        final cubit = MemoryMatchCubit(storage: storage);
        await cubit.startGame();

        final deck = cubit.state.cards;
        final card1 = deck.first;
        final card2 = deck.firstWhere(
          (c) => c.id != card1.id && c.pairId == card1.pairId,
        );

        // Tap card 1
        await cubit.onCardTapped(card1.id);
        expect(cubit.state.firstSelectedId, equals(card1.id));
        expect(cubit.state.moves, equals(0));

        // Tap card 2
        await cubit.onCardTapped(card2.id);
        expect(cubit.state.moves, equals(1));
        expect(cubit.state.matchedPairs, equals(1));
        expect(cubit.state.currentScore, equals(10));
        expect(cubit.state.firstSelectedId, isNull);

        final c1 = cubit.state.cards.firstWhere((c) => c.id == card1.id);
        final c2 = cubit.state.cards.firstWhere((c) => c.id == card2.id);
        expect(c1.isMatched, isTrue);
        expect(c2.isMatched, isTrue);

        await cubit.close();
      },
    );

    test(
      '4. Tapping two mismatched cards sets isResolvingMismatch and flips them back',
      () async {
        final storage = MockMemoryMatchStorage();
        final cubit = MemoryMatchCubit(storage: storage);
        await cubit.startGame();

        final deck = cubit.state.cards;
        final card1 = deck.first;
        final card2 = deck.firstWhere((c) => c.pairId != card1.pairId);

        // Tap card 1
        await cubit.onCardTapped(card1.id);
        // Tap card 2
        final futureTap = cubit.onCardTapped(card2.id);

        // Immediately after second tap, mismatch state is resolving
        expect(cubit.state.isResolvingMismatch, isTrue);
        expect(cubit.state.moves, equals(1));

        // Wait for delay to complete
        await futureTap;

        // After mismatch resolves, cards are face down and mismatch cleared
        expect(cubit.state.isResolvingMismatch, isFalse);
        expect(cubit.state.firstSelectedId, isNull);
        expect(cubit.state.secondSelectedId, isNull);

        final c1 = cubit.state.cards.firstWhere((c) => c.id == card1.id);
        final c2 = cubit.state.cards.firstWhere((c) => c.id == card2.id);
        expect(c1.isFaceUp, isFalse);
        expect(c2.isFaceUp, isFalse);

        await cubit.close();
      },
    );

    test('5. Rapid taps during mismatch resolution are blocked', () async {
      final storage = MockMemoryMatchStorage();
      final cubit = MemoryMatchCubit(storage: storage);
      await cubit.startGame();

      final deck = cubit.state.cards;
      final card1 = deck.first;
      final card2 = deck.firstWhere((c) => c.pairId != card1.pairId);
      final card3 = deck.lastWhere((c) => c.id != card1.id && c.id != card2.id);

      await cubit.onCardTapped(card1.id);
      final futureMismatch = cubit.onCardTapped(card2.id);

      // Attempt to tap third card while mismatch is resolving
      await cubit.onCardTapped(card3.id);
      // Card 3 should remain face down
      final c3 = cubit.state.cards.firstWhere((c) => c.id == card3.id);
      expect(c3.isFaceUp, isFalse);

      await futureMismatch;
      await cubit.close();
    });

    test(
      '6. Completing level triggers completed status, unlocks next level, and computes final score',
      () async {
        final storage = MockMemoryMatchStorage();
        final cubit = MemoryMatchCubit(storage: storage);
        // Level 1 has 2 pairs
        await cubit.startGame();

        final deck = cubit.state.cards;
        final pair0Cards = deck.where((c) => c.pairId == 0).toList();
        final pair1Cards = deck.where((c) => c.pairId == 1).toList();

        // Match pair 0
        await cubit.onCardTapped(pair0Cards[0].id);
        await cubit.onCardTapped(pair0Cards[1].id);

        expect(cubit.state.status, equals(GameStatus.playing));
        expect(cubit.state.matchedPairs, equals(1));

        // Match pair 1 (completes level)
        await cubit.onCardTapped(pair1Cards[0].id);
        await cubit.onCardTapped(pair1Cards[1].id);

        expect(cubit.state.status, equals(GameStatus.completed));
        expect(cubit.state.matchedPairs, equals(2));
        expect(cubit.state.scoreBreakdown, isNotNull);
        expect(cubit.state.highestUnlockedLevel, equals(2));
        expect(await storage.getHighestUnlockedLevel(), equals(2));

        await cubit.close();
      },
    );

    test('7. Restart resets board state and shuffles cards fresh', () async {
      final storage = MockMemoryMatchStorage();
      final cubit = MemoryMatchCubit(storage: storage);
      await cubit.startGame();

      final deck = cubit.state.cards;
      final card1 = deck.first;
      final card2 = deck.firstWhere(
        (c) => c.id != card1.id && c.pairId == card1.pairId,
      );

      await cubit.onCardTapped(card1.id);
      await cubit.onCardTapped(card2.id);

      expect(cubit.state.moves, equals(1));
      expect(cubit.state.currentScore, equals(10));

      await cubit.restartLevel();

      expect(cubit.state.moves, equals(0));
      expect(cubit.state.currentScore, equals(0));
      expect(cubit.state.matchedPairs, equals(0));
      expect(cubit.state.cards.every((c) => !c.isFaceUp), isTrue);

      await cubit.close();
    });

    test(
      '8. Stale mismatch callbacks cannot mutate state after restart',
      () async {
        final storage = MockMemoryMatchStorage();
        final cubit = MemoryMatchCubit(storage: storage);
        await cubit.startGame();

        final deck = cubit.state.cards;
        final card1 = deck.first;
        final card2 = deck.firstWhere((c) => c.pairId != card1.pairId);

        await cubit.onCardTapped(card1.id);
        // Initiate mismatch
        final mismatchFuture = cubit.onCardTapped(card2.id);

        // Player immediately restarts while mismatch is pending
        await cubit.restartLevel();
        final newRoundToken = cubit.state.roundToken;

        // Let old mismatch timer finish
        await mismatchFuture;

        // Round token and state must not be corrupted
        expect(cubit.state.roundToken, equals(newRoundToken));
        expect(cubit.state.moves, equals(0));
        expect(cubit.state.cards.every((c) => !c.isFaceUp), isTrue);

        await cubit.close();
      },
    );
  });
}
