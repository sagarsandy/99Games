import 'package:equatable/equatable.dart';

/// Categories of objects depicted on the Memory Match cards.
enum ArtworkCategory {
  fruit('Fruits'),
  animal('Animals'),
  vehicle('Vehicles'),
  nature('Nature'),
  object('Objects'),
  special('Special');

  final String label;
  const ArtworkCategory(this.label);
}

/// 27 unique, recognizable cartoon object types programmatically painted on cards.
enum CardArtworkType {
  // Fruits
  apple('Apple', ArtworkCategory.fruit),
  orange('Orange', ArtworkCategory.fruit),
  banana('Banana', ArtworkCategory.fruit),
  strawberry('Strawberry', ArtworkCategory.fruit),
  grapes('Grapes', ArtworkCategory.fruit),

  // Animals
  cat('Cat', ArtworkCategory.animal),
  dog('Dog', ArtworkCategory.animal),
  rabbit('Rabbit', ArtworkCategory.animal),
  owl('Owl', ArtworkCategory.animal),
  fish('Fish', ArtworkCategory.animal),

  // Vehicles
  car('Car', ArtworkCategory.vehicle),
  bus('Bus', ArtworkCategory.vehicle),
  bicycle('Bicycle', ArtworkCategory.vehicle),
  airplane('Airplane', ArtworkCategory.vehicle),

  // Nature
  flower('Flower', ArtworkCategory.nature),
  tree('Tree', ArtworkCategory.nature),
  mushroom('Mushroom', ArtworkCategory.nature),
  sun('Sun', ArtworkCategory.nature),

  // Everyday objects
  clock('Clock', ArtworkCategory.object),
  book('Book', ArtworkCategory.object),
  umbrella('Umbrella', ArtworkCategory.object),
  cup('Cup', ArtworkCategory.object),
  key('Key', ArtworkCategory.object),

  // Special / Festive
  star('Star', ArtworkCategory.special),
  balloon('Balloon', ArtworkCategory.special),
  rocket('Rocket', ArtworkCategory.special),
  giftBox('Gift Box', ArtworkCategory.special);

  final String displayName;
  final ArtworkCategory category;

  const CardArtworkType(this.displayName, this.category);
}

/// Represents an individual card instance on the memory board.
class MemoryCard extends Equatable {
  final int id; // Unique instance ID
  final int pairId; // Matching pair ID (shared by exactly 2 cards)
  final CardArtworkType artwork;
  final bool isFaceUp;
  final bool isMatched;
  final bool isMismatching;
  final bool isNewMatch;

  const MemoryCard({
    required this.id,
    required this.pairId,
    required this.artwork,
    this.isFaceUp = false,
    this.isMatched = false,
    this.isMismatching = false,
    this.isNewMatch = false,
  });

  MemoryCard copyWith({
    int? id,
    int? pairId,
    CardArtworkType? artwork,
    bool? isFaceUp,
    bool? isMatched,
    bool? isMismatching,
    bool? isNewMatch,
  }) {
    return MemoryCard(
      id: id ?? this.id,
      pairId: pairId ?? this.pairId,
      artwork: artwork ?? this.artwork,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isMatched: isMatched ?? this.isMatched,
      isMismatching: isMismatching ?? this.isMismatching,
      isNewMatch: isNewMatch ?? this.isNewMatch,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pairId,
    artwork,
    isFaceUp,
    isMatched,
    isMismatching,
    isNewMatch,
  ];
}

/// Lifecycle status for Memory Match.
enum GameStatus { ready, playing, completed }

/// Configuration describing grid size and artwork selection for a level.
class LevelConfig extends Equatable {
  final int levelNumber;
  final int rows;
  final int cols;
  final String title;
  final List<CardArtworkType> artworks;

  const LevelConfig({
    required this.levelNumber,
    required this.rows,
    required this.cols,
    required this.title,
    required this.artworks,
  });

  int get cardCount => rows * cols;
  int get pairCount => cardCount ~/ 2;

  @override
  List<Object?> get props => [levelNumber, rows, cols, title, artworks];
}
