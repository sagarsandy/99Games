import 'dart:math';
import 'word_search_models.dart';

/// A curated, age-appropriate English dictionary for Word Search.
///
/// Designed with extensible categories to facilitate adding new themes
/// or languages in the future without modifying puzzle logic.
class WordSearchDictionary {
  final Map<String, List<String>> _categories;

  WordSearchDictionary({Map<String, List<String>>? categories})
    : _categories = categories ?? _defaultCategories;

  /// Default categories of family-friendly English words.
  static const Map<String, List<String>> _defaultCategories = {
    'Animals': [
      'CAT',
      'DOG',
      'FOX',
      'OWL',
      'LION',
      'BEAR',
      'WOLF',
      'DEER',
      'DUCK',
      'FROG',
      'TIGER',
      'ZEBRA',
      'EAGLE',
      'HORSE',
      'PANDA',
      'SHARK',
      'WHALE',
      'MONKEY',
      'DOLPHIN',
      'GIRAFFE',
      'CHEETAH',
      'PENGUIN',
      'LEOPARD',
      'KANGAROO',
      'ELEPHANT',
      'FLAMINGO',
    ],
    'Nature': [
      'SUN',
      'SKY',
      'SEA',
      'AIR',
      'TREE',
      'ROSE',
      'LILY',
      'FERN',
      'LEAF',
      'RIVER',
      'OCEAN',
      'FOREST',
      'FLOWER',
      'GARDEN',
      'VALLEY',
      'DESERT',
      'STREAM',
      'MEADOW',
      'RAINBOW',
      'SUNSHINE',
      'MOUNTAIN',
      'BLOSSOM',
      'WATERFALL',
    ],
    'Space': [
      'MOON',
      'STAR',
      'MARS',
      'NOVA',
      'VENUS',
      'COMET',
      'ORBIT',
      'SOLAR',
      'PLUTO',
      'SATURN',
      'PLANET',
      'METEOR',
      'GALAXY',
      'NEBULA',
      'ROCKET',
      'JUPITER',
      'ECLIPSE',
      'COSMOS',
      'ASTEROID',
      'ASTRONAUT',
      'SATELLITE',
    ],
    'Food': [
      'PIE',
      'TEA',
      'JAM',
      'NUT',
      'CAKE',
      'BREAD',
      'APPLE',
      'PEACH',
      'BERRY',
      'MANGO',
      'LEMON',
      'CHEESE',
      'PIZZA',
      'BANANA',
      'COOKIE',
      'ORANGE',
      'WAFFLE',
      'CHERRY',
      'PANCAKE',
      'AVOCADO',
      'SANDWICH',
    ],
    'Science': [
      'ATOM',
      'CODE',
      'DATA',
      'WAVE',
      'LASER',
      'LIGHT',
      'RADAR',
      'PIXEL',
      'ROBOT',
      'LOGIC',
      'CIRCUIT',
      'ENERGY',
      'FUSION',
      'GRAVITY',
      'QUANTUM',
      'SILICON',
      'MAGNET',
      'ELEMENT',
      'ELECTRON',
    ],
    'Sports': [
      'RUN',
      'BALL',
      'SWIM',
      'GOAL',
      'SURF',
      'SKATE',
      'CLIMB',
      'TRACK',
      'TENNIS',
      'SOCCER',
      'HOCKEY',
      'SPRINT',
      'CYCLING',
      'SAILING',
      'ARCHERY',
      'CRICKET',
      'BASEBALL',
      'VOLLEY',
    ],
    'Colors': [
      'RED',
      'BLUE',
      'PINK',
      'GOLD',
      'TEAL',
      'GREEN',
      'WHITE',
      'BLACK',
      'CORAL',
      'PURPLE',
      'YELLOW',
      'SILVER',
      'INDIGO',
      'ORANGE',
      'VIOLET',
      'CRIMSON',
      'EMERALD',
    ],
  };

  /// Returns all available category names.
  List<String> get categoryNames => _categories.keys.toList();

  /// Retrieves all words meeting the length criteria for [difficulty].
  List<String> getCandidatesForDifficulty(
    WordSearchDifficulty difficulty, {
    String? category,
  }) {
    final pool = <String>{};

    if (category != null && _categories.containsKey(category)) {
      pool.addAll(_categories[category]!);
    } else {
      for (final words in _categories.values) {
        pool.addAll(words);
      }
    }

    return pool
        .map((w) => w.trim().toUpperCase())
        .where(
          (w) =>
              w.length >= difficulty.minWordLength &&
              w.length <= difficulty.maxWordLength &&
              w.length <= difficulty.gridSize &&
              RegExp(r'^[A-Z]+$').hasMatch(w),
        )
        .toList();
  }

  /// Selects a prioritized list of words suitable for generating a puzzle
  /// at the given [difficulty].
  List<String> getWordsForDifficulty(
    WordSearchDifficulty difficulty, {
    Random? random,
    int? count,
    String? category,
  }) {
    final rng = random ?? Random();
    final candidates = getCandidatesForDifficulty(
      difficulty,
      category: category,
    );

    candidates.shuffle(rng);

    final targetCount = count ?? difficulty.targetWordCount;
    if (candidates.length <= targetCount) {
      return candidates;
    }

    return candidates.sublist(0, targetCount);
  }
}
