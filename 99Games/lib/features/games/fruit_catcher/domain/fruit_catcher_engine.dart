import 'dart:math' as math;
import 'dart:ui';
import 'fruit_catcher_models.dart';

/// Difficulty parameters evaluated dynamically based on round elapsed time.
class DifficultySettings {
  final double fallSpeed;
  final double spawnInterval;
  final double bombChance;
  final double goldenChance;
  final int maxActiveObjects;

  const DifficultySettings({
    required this.fallSpeed,
    required this.spawnInterval,
    required this.bombChance,
    required this.goldenChance,
    required this.maxActiveObjects,
  });
}

/// Result of an engine update step for collisions, scoring, and lifecycle events.
class EngineUpdateResult {
  final List<FallingItem> activeItems;
  final int pointsEarned;
  final int livesLost;
  final List<FruitCatchParticle> newParticles;
  final List<FloatingIndicator> newIndicators;
  final bool hitBomb;

  const EngineUpdateResult({
    required this.activeItems,
    this.pointsEarned = 0,
    this.livesLost = 0,
    this.newParticles = const [],
    this.newIndicators = const [],
    this.hitBomb = false,
  });

  /// Alias for activeItems
  List<FallingItem> get remainingItems => activeItems;
}

/// Pure domain gameplay engine for Fruit Catcher.
class FruitCatcherEngine {
  final math.Random _random;

  FruitCatcherEngine({math.Random? random}) : _random = random ?? math.Random();

  static const double roundDuration = 60.0;
  static const int initialLives = 3;
  static const int initialScore = 0;

  /// Returns true if the round is finished (timer expired or no lives left).
  bool isRoundOver({required double elapsedSeconds, required int lives}) {
    return elapsedSeconds >= roundDuration || lives <= 0;
  }

  /// Evaluates difficulty curve across the 60-second round.
  DifficultySettings getDifficulty(double elapsedSeconds) {
    final progress = (elapsedSeconds / roundDuration).clamp(0.0, 1.0);

    // Fall speed: 0.38 (early) -> 0.72 (late)
    final fallSpeed = 0.38 + (0.34 * progress);

    // Spawn interval: 1.10s (early) -> 0.52s (late)
    final spawnInterval = 1.10 - (0.58 * progress);

    // Bomb chance: 0% in early game -> up to 24% in late game
    final bombChance = progress < 0.20
        ? 0.0
        : (0.24 * ((progress - 0.20) / 0.80));

    // Golden fruit chance: ~5% early -> ~12% late
    final goldenChance = 0.05 + (0.07 * progress);

    // Maximum simultaneous objects on screen
    final maxActiveObjects = progress < 0.40 ? 5 : (progress < 0.75 ? 7 : 8);

    return DifficultySettings(
      fallSpeed: fallSpeed,
      spawnInterval: spawnInterval,
      bombChance: bombChance,
      goldenChance: goldenChance,
      maxActiveObjects: maxActiveObjects,
    );
  }

  /// Attempts to spawn a new item if interval and object count permit.
  FallingItem? maybeSpawnItem({
    required double timeSinceLastSpawn,
    required double elapsedSeconds,
    required List<FallingItem> currentItems,
    required double basketX,
    required int nextId,
    math.Random? randomOverride,
  }) {
    final rand = randomOverride ?? _random;
    final difficulty = getDifficulty(elapsedSeconds);

    if (timeSinceLastSpawn < difficulty.spawnInterval) {
      return null;
    }

    if (currentItems.length >= difficulty.maxActiveObjects) {
      return null;
    }

    // Determine type: bomb, golden fruit, or normal fruit
    final roll = rand.nextDouble();
    FruitType type;

    if (roll < difficulty.bombChance) {
      type = FruitType.bomb;
    } else if (roll < (difficulty.bombChance + difficulty.goldenChance)) {
      type = FruitType.golden;
    } else {
      const normalFruits = [
        FruitType.apple,
        FruitType.orange,
        FruitType.banana,
        FruitType.strawberry,
        FruitType.grapes,
      ];
      type = normalFruits[rand.nextInt(normalFruits.length)];
    }

    // Determine horizontal spawn position (between 0.08 and 0.92)
    // Fairness rule: prevent spawning bomb directly on basket without reaction margin
    double spawnX = 0.08 + rand.nextDouble() * 0.84;
    if (type == FruitType.bomb && (spawnX - basketX).abs() < 0.10) {
      // Shift away from basket center
      spawnX = spawnX < 0.5 ? spawnX + 0.25 : spawnX - 0.25;
      spawnX = spawnX.clamp(0.08, 0.92);
    }

    // Slight variance in fall speed (±10%)
    final speedVariance = 0.90 + (rand.nextDouble() * 0.20);
    final speed = difficulty.fallSpeed * speedVariance;

    // Slight rotation tumble (-1.5 to +1.5 rad/sec)
    final rotSpeed = (rand.nextDouble() - 0.5) * 3.0;

    return FallingItem(
      id: nextId,
      type: type,
      x: spawnX,
      y: -0.05,
      speed: speed,
      radius: type == FruitType.bomb ? 0.048 : 0.045,
      rotation: rand.nextDouble() * math.pi * 2,
      rotationSpeed: rotSpeed,
      isCollected: false,
    );
  }

  /// Advances physics, checks collisions, updates particles, and handles score/lives.
  EngineUpdateResult updatePhysics({
    required List<FallingItem> items,
    required BasketModel basket,
    required double dt,
    required int nextIndicatorId,
  }) {
    final remainingItems = <FallingItem>[];
    int pointsEarned = 0;
    int livesLost = 0;
    bool hitBomb = false;
    final newParticles = <FruitCatchParticle>[];
    final newIndicators = <FloatingIndicator>[];

    var indicatorIdCounter = nextIndicatorId;

    for (final item in items) {
      if (item.isCollected) continue;

      // Update position
      final newY = item.y + (item.speed * dt);
      final newRot = item.rotation + (item.rotationSpeed * dt);

      // Check collision with basket
      final collided = checkBasketCollision(
        itemX: item.x,
        itemY: newY,
        itemRadius: item.radius,
        basket: basket,
      );

      if (collided) {
        // Collect object exactly once
        if (item.type == FruitType.bomb) {
          livesLost += 1;
          hitBomb = true;

          // Red/dark smoke explosion particles
          newParticles.addAll(_createBombExplosionParticles(item.x, basket.y));

          // Floating damage indicator
          newIndicators.add(
            FloatingIndicator(
              id: indicatorIdCounter++,
              text: '-1 Life',
              x: item.x,
              y: basket.y,
              color: const Color(0xFFEF4444),
            ),
          );
        } else {
          pointsEarned += item.type.points;

          // Fruit catch particle burst
          newParticles.addAll(_createFruitCatchParticles(item));

          // Floating score indicator
          newIndicators.add(
            FloatingIndicator(
              id: indicatorIdCounter++,
              text: '+${item.type.points}',
              x: item.x,
              y: basket.y,
              color: item.type.isGolden
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
            ),
          );
        }
        // Do not add collected items back to active list
      } else if (newY <= 1.06) {
        // Still within playfield
        remainingItems.add(item.copyWith(y: newY, rotation: newRot));
      } else {
        // Missed fruit: falls off screen cleanly with 0 penalty
      }
    }

    return EngineUpdateResult(
      activeItems: remainingItems,
      pointsEarned: pointsEarned,
      livesLost: livesLost,
      newParticles: newParticles,
      newIndicators: newIndicators,
      hitBomb: hitBomb,
    );
  }

  /// Determines if an item touches the basket's catch zone.
  bool checkBasketCollision({
    required double itemX,
    required double itemY,
    required double itemRadius,
    required BasketModel basket,
  }) {
    // Basket rim area: from top of basket down to upper third
    final catchTop = basket.y - (itemRadius * 0.7);
    final catchBottom = basket.y + (basket.height * 0.65);

    // Horizontal bounds: within basket width + catch margin
    final catchLeft = basket.left - (itemRadius * 0.4);
    final catchRight = basket.right + (itemRadius * 0.4);

    return itemY >= catchTop &&
        itemY <= catchBottom &&
        itemX >= catchLeft &&
        itemX <= catchRight;
  }

  List<FruitCatchParticle> _createFruitCatchParticles(FallingItem item) {
    final particles = <FruitCatchParticle>[];
    final color = _getFruitParticleColor(item.type);
    final count = item.type.isGolden ? 16 : 10;

    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 0.15 + (_random.nextDouble() * 0.35);

      particles.add(
        FruitCatchParticle(
          x: item.x,
          y: item.y,
          vx: math.cos(angle) * speed,
          vy: (math.sin(angle) * speed) - 0.12, // Slight upward pop
          color: item.type.isGolden && i.isEven
              ? const Color(0xFFFEF08A)
              : color,
          size: item.type.isGolden ? 6.0 : 4.5,
          maxLife: 0.45 + (_random.nextDouble() * 0.20),
          isStar: item.type.isGolden,
        ),
      );
    }
    return particles;
  }

  List<FruitCatchParticle> _createBombExplosionParticles(double x, double y) {
    final particles = <FruitCatchParticle>[];
    const colors = [
      Color(0xFFEF4444), // Red
      Color(0xFFF97316), // Orange
      Color(0xFF1E293B), // Dark slate smoke
      Color(0xFFF59E0B), // Ember yellow
    ];

    for (int i = 0; i < 20; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 0.20 + (_random.nextDouble() * 0.45);
      final c = colors[i % colors.length];

      particles.add(
        FruitCatchParticle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: (math.sin(angle) * speed) - 0.15,
          color: c,
          size: 5.5 + (_random.nextDouble() * 3.5),
          maxLife: 0.55 + (_random.nextDouble() * 0.25),
          isStar: false,
        ),
      );
    }
    return particles;
  }

  Color _getFruitParticleColor(FruitType type) {
    switch (type) {
      case FruitType.apple:
        return const Color(0xFFEF4444);
      case FruitType.orange:
        return const Color(0xFFF97316);
      case FruitType.banana:
        return const Color(0xFFFBBF24);
      case FruitType.strawberry:
        return const Color(0xFFE11D48);
      case FruitType.grapes:
        return const Color(0xFF9333EA);
      case FruitType.golden:
        return const Color(0xFFF59E0B);
      case FruitType.bomb:
        return const Color(0xFF1E293B);
    }
  }
}
