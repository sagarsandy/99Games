import 'package:equatable/equatable.dart';
import '../domain/fruit_catcher_models.dart';

/// Immutable state for Fruit Catcher gameplay, HUD, and lifecycle.
class FruitCatcherState extends Equatable {
  final GameStatus status;
  final int score;
  final int bestScore;
  final bool isNewRecord;
  final int lives;
  final double timeRemaining;
  final BasketModel basket;
  final List<FallingItem> items;
  final List<FruitCatchParticle> particles;
  final List<FloatingIndicator> indicators;
  final bool isDamaged;
  final double timeSinceLastSpawn;
  final int nextItemId;
  final int nextIndicatorId;
  final bool isLoading;

  const FruitCatcherState({
    this.status = GameStatus.ready,
    this.score = 0,
    this.bestScore = 0,
    this.isNewRecord = false,
    this.lives = 3,
    this.timeRemaining = 60.0,
    this.basket = const BasketModel(),
    this.items = const [],
    this.particles = const [],
    this.indicators = const [],
    this.isDamaged = false,
    this.timeSinceLastSpawn = 0.0,
    this.nextItemId = 1,
    this.nextIndicatorId = 1,
    this.isLoading = false,
  });

  bool get isPlaying => status == GameStatus.playing;
  bool get isGameOver => status == GameStatus.gameOver;
  bool get isReady => status == GameStatus.ready;
  double get elapsedSeconds => (60.0 - timeRemaining).clamp(0.0, 60.0);

  FruitCatcherState copyWith({
    GameStatus? status,
    int? score,
    int? bestScore,
    bool? isNewRecord,
    int? lives,
    double? timeRemaining,
    BasketModel? basket,
    List<FallingItem>? items,
    List<FruitCatchParticle>? particles,
    List<FloatingIndicator>? indicators,
    bool? isDamaged,
    double? timeSinceLastSpawn,
    int? nextItemId,
    int? nextIndicatorId,
    bool? isLoading,
  }) {
    return FruitCatcherState(
      status: status ?? this.status,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      isNewRecord: isNewRecord ?? this.isNewRecord,
      lives: lives ?? this.lives,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      basket: basket ?? this.basket,
      items: items ?? this.items,
      particles: particles ?? this.particles,
      indicators: indicators ?? this.indicators,
      isDamaged: isDamaged ?? this.isDamaged,
      timeSinceLastSpawn: timeSinceLastSpawn ?? this.timeSinceLastSpawn,
      nextItemId: nextItemId ?? this.nextItemId,
      nextIndicatorId: nextIndicatorId ?? this.nextIndicatorId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    status,
    score,
    bestScore,
    isNewRecord,
    lives,
    timeRemaining,
    basket,
    items,
    particles,
    indicators,
    isDamaged,
    timeSinceLastSpawn,
    nextItemId,
    nextIndicatorId,
    isLoading,
  ];
}
