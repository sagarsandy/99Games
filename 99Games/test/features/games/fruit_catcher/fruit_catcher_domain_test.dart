import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/fruit_catcher/domain/fruit_catcher_engine.dart';
import 'package:mini_games_99/features/games/fruit_catcher/domain/fruit_catcher_models.dart';

/// A deterministic Random generator for repeatable tests.
class DeterministicRandom implements math.Random {
  final List<double> doubles;
  final List<int> ints;
  int _doubleIndex = 0;
  int _intIndex = 0;

  DeterministicRandom({this.doubles = const [], this.ints = const []});

  @override
  bool nextBool() => nextDouble() > 0.5;

  @override
  double nextDouble() {
    if (doubles.isEmpty) return 0.5;
    final val = doubles[_doubleIndex % doubles.length];
    _doubleIndex++;
    return val;
  }

  @override
  int nextInt(int max) {
    if (ints.isEmpty) return 0;
    final val = ints[_intIndex % ints.length] % max;
    _intIndex++;
    return val;
  }
}

void main() {
  group('Fruit Catcher Domain Engine Tests', () {
    test('1. A new round starts with score 0, three lives, and 60 seconds', () {
      expect(FruitCatcherEngine.roundDuration, equals(60.0));
      expect(FruitCatcherEngine.initialLives, equals(3));
      expect(FruitCatcherEngine.initialScore, equals(0));
    });

    test('2. Catching a normal fruit awards exactly 10 points', () {
      final engine = FruitCatcherEngine();
      const basket = BasketModel(x: 0.5, y: 0.86, width: 0.24, height: 0.08);

      const normalFruit = FallingItem(
        id: 1,
        type: FruitType.apple,
        x: 0.5, // Exactly aligned with basket
        y: 0.87, // Intersecting basket rim
        speed: 0.5,
        radius: 0.045,
      );

      final result = engine.updatePhysics(
        items: [normalFruit],
        basket: basket,
        dt: 0.016,
        nextIndicatorId: 1,
      );

      expect(result.pointsEarned, equals(10));
      expect(result.livesLost, equals(0));
      expect(result.hitBomb, isFalse);
      expect(result.remainingItems.isEmpty, isTrue);
      expect(result.newIndicators.length, equals(1));
      expect(result.newIndicators.first.text, equals('+10'));
    });

    test('3. Catching golden fruit awards exactly 50 points', () {
      final engine = FruitCatcherEngine();
      const basket = BasketModel(x: 0.5, y: 0.86, width: 0.24, height: 0.08);

      const goldenFruit = FallingItem(
        id: 2,
        type: FruitType.golden,
        x: 0.5,
        y: 0.87,
        speed: 0.5,
        radius: 0.045,
      );

      final result = engine.updatePhysics(
        items: [goldenFruit],
        basket: basket,
        dt: 0.016,
        nextIndicatorId: 1,
      );

      expect(result.pointsEarned, equals(50));
      expect(result.livesLost, equals(0));
      expect(result.hitBomb, isFalse);
      expect(result.remainingItems.isEmpty, isTrue);
      expect(result.newIndicators.first.text, equals('+50'));
    });

    test('4. A bomb collision deducts exactly one life', () {
      final engine = FruitCatcherEngine();
      const basket = BasketModel(x: 0.5, y: 0.86, width: 0.24, height: 0.08);

      const bomb = FallingItem(
        id: 3,
        type: FruitType.bomb,
        x: 0.5,
        y: 0.87,
        speed: 0.5,
        radius: 0.045,
      );

      final result = engine.updatePhysics(
        items: [bomb],
        basket: basket,
        dt: 0.016,
        nextIndicatorId: 1,
      );

      expect(result.livesLost, equals(1));
      expect(result.pointsEarned, equals(0));
      expect(result.hitBomb, isTrue);
      expect(result.remainingItems.isEmpty, isTrue);
      expect(result.newIndicators.first.text, equals('-1 Life'));
    });

    test('5. Reprocessing the same bomb does not deduct another life', () {
      final engine = FruitCatcherEngine();
      const basket = BasketModel(x: 0.5, y: 0.86, width: 0.24, height: 0.08);

      const alreadyCollectedBomb = FallingItem(
        id: 4,
        type: FruitType.bomb,
        x: 0.5,
        y: 0.87,
        speed: 0.5,
        radius: 0.045,
        isCollected: true, // Already collected
      );

      final result = engine.updatePhysics(
        items: [alreadyCollectedBomb],
        basket: basket,
        dt: 0.016,
        nextIndicatorId: 1,
      );

      expect(result.livesLost, equals(0));
      expect(result.pointsEarned, equals(0));
      expect(result.hitBomb, isFalse);
      expect(result.remainingItems.isEmpty, isTrue);
    });

    test('6. Missing fruit does not reduce lives or score', () {
      final engine = FruitCatcherEngine();
      const basket = BasketModel(x: 0.2, y: 0.86, width: 0.24, height: 0.08);

      // Fruit falls away on the right side and past bottom (y > 1.06)
      const missedFruit = FallingItem(
        id: 5,
        type: FruitType.strawberry,
        x: 0.85,
        y: 1.07,
        speed: 0.5,
        radius: 0.045,
      );

      final result = engine.updatePhysics(
        items: [missedFruit],
        basket: basket,
        dt: 0.016,
        nextIndicatorId: 1,
      );

      expect(result.pointsEarned, equals(0));
      expect(result.livesLost, equals(0));
      expect(result.remainingItems.isEmpty, isTrue); // Cleaned up from screen
    });

    test('7. The timer reaching zero ends the round', () {
      final engine = FruitCatcherEngine();
      expect(engine.isRoundOver(elapsedSeconds: 60.0, lives: 3), isTrue);
      expect(engine.isRoundOver(elapsedSeconds: 60.1, lives: 3), isTrue);
      expect(engine.isRoundOver(elapsedSeconds: 59.9, lives: 3), isFalse);
    });

    test('8. Losing the final life ends the round immediately', () {
      final engine = FruitCatcherEngine();
      expect(engine.isRoundOver(elapsedSeconds: 12.0, lives: 0), isTrue);
      expect(engine.isRoundOver(elapsedSeconds: 12.0, lives: -1), isTrue);
      expect(engine.isRoundOver(elapsedSeconds: 12.0, lives: 1), isFalse);
    });

    test(
      '9. Basket collision detection geometry is precise and non-penetrating',
      () {
        final engine = FruitCatcherEngine();
        const basket = BasketModel(x: 0.5, y: 0.86, width: 0.24, height: 0.08);

        // Direct hit
        expect(
          engine.checkBasketCollision(
            itemX: 0.5,
            itemY: 0.87,
            itemRadius: 0.045,
            basket: basket,
          ),
          isTrue,
        );

        // Far horizontally (outside basket left edge)
        expect(
          engine.checkBasketCollision(
            itemX: 0.1,
            itemY: 0.87,
            itemRadius: 0.045,
            basket: basket,
          ),
          isFalse,
        );

        // Far vertically (too high above basket)
        expect(
          engine.checkBasketCollision(
            itemX: 0.5,
            itemY: 0.50,
            itemRadius: 0.045,
            basket: basket,
          ),
          isFalse,
        );
      },
    );

    test('10. Basket movement is clamped to both horizontal boundaries', () {
      const basket = BasketModel(x: 0.5, y: 0.86, width: 0.24, height: 0.08);

      // Half width is 0.12, so clamping is [0.12, 0.88]
      final clampedFarLeft = basket.clampPosition(-0.5);
      expect(clampedFarLeft.x, closeTo(0.12, 0.001));

      final clampedFarRight = basket.clampPosition(1.5);
      expect(clampedFarRight.x, closeTo(0.88, 0.001));

      final validMid = basket.clampPosition(0.45);
      expect(validMid.x, closeTo(0.45, 0.001));
    });

    test(
      '13. Spawned objects are removed after processing and do not accumulate',
      () {
        final engine = FruitCatcherEngine();
        const basket = BasketModel(x: 0.5, y: 0.86, width: 0.24, height: 0.08);

        // Frame with 3 items:
        // Item 1: caught
        // Item 2: fallen past screen (y = 1.1)
        // Item 3: still falling above basket (y = 0.3)
        final items = [
          const FallingItem(
            id: 1,
            type: FruitType.orange,
            x: 0.5,
            y: 0.87,
            speed: 0.4,
          ),
          const FallingItem(
            id: 2,
            type: FruitType.apple,
            x: 0.1,
            y: 1.10,
            speed: 0.4,
          ),
          const FallingItem(
            id: 3,
            type: FruitType.grapes,
            x: 0.8,
            y: 0.30,
            speed: 0.4,
          ),
        ];

        final result = engine.updatePhysics(
          items: items,
          basket: basket,
          dt: 0.016,
          nextIndicatorId: 1,
        );

        // Item 1 was caught and removed
        // Item 2 was past bottom and removed
        // Item 3 remains active and moved downward
        expect(result.remainingItems.length, equals(1));
        expect(result.remainingItems.first.id, equals(3));
        expect(result.remainingItems.first.y, greaterThan(0.30));
      },
    );

    test(
      '14. Difficulty increases gradually and stays within configured bounds',
      () {
        final engine = FruitCatcherEngine();

        final early = engine.getDifficulty(0.0);
        final mid = engine.getDifficulty(30.0);
        final late_ = engine.getDifficulty(60.0);

        // Fall speed increases: 0.38 -> 0.72
        expect(early.fallSpeed, closeTo(0.38, 0.01));
        expect(mid.fallSpeed, greaterThan(early.fallSpeed));
        expect(late_.fallSpeed, closeTo(0.72, 0.01));
        expect(late_.fallSpeed, greaterThan(mid.fallSpeed));

        // Spawn interval decreases: 1.10s -> 0.52s
        expect(early.spawnInterval, closeTo(1.10, 0.01));
        expect(mid.spawnInterval, lessThan(early.spawnInterval));
        expect(late_.spawnInterval, closeTo(0.52, 0.01));
        expect(late_.spawnInterval, lessThan(mid.spawnInterval));

        // Bomb chance: 0.0 early -> up to 0.24 late
        expect(early.bombChance, equals(0.0));
        expect(late_.bombChance, closeTo(0.24, 0.01));

        // Golden fruit chance: 0.05 -> 0.12
        expect(early.goldenChance, closeTo(0.05, 0.01));
        expect(late_.goldenChance, closeTo(0.12, 0.01));
      },
    );

    test(
      '15. Deterministic spawning respects fairness (no bomb directly on basket)',
      () {
        // Create a deterministic engine with mock random returning bomb and basket center
        final mockRandom = DeterministicRandom(
          doubles: [0.01, 0.50], // roll < bombChance, and x = 0.5
          ints: [0],
        );

        final engine = FruitCatcherEngine(random: mockRandom);
        const basket = BasketModel(x: 0.5, y: 0.86, width: 0.24, height: 0.08);

        final spawned = engine.maybeSpawnItem(
          timeSinceLastSpawn: 2.0,
          elapsedSeconds: 40.0,
          currentItems: const [],
          basketX: basket.x,
          nextId: 1,
        );

        expect(spawned, isNotNull);
        if (spawned!.type == FruitType.bomb) {
          // Bomb must NOT be within 0.10 of basket.x (0.50)
          final distance = (spawned.x - basket.x).abs();
          expect(distance, greaterThanOrEqualTo(0.10));
        }
      },
    );
  });
}
