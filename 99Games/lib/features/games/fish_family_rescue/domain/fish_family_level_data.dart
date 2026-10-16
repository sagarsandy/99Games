import 'fish_family_models.dart';

/// Predefined collection of 20 verified, curated levels for Fish Family Rescue.
///
/// Every level has been verified by [FishFamilySolver] to guarantee 100% solvability
/// through legal moves with progressive difficulty across all 20 levels.
abstract final class FishFamilyLevelData {
  static const int totalLevels = 20;

  /// Retrieves the [FishFamilyLevel] configuration for [levelNumber] (1 to 20).
  static FishFamilyLevel getLevel(int levelNumber) {
    final clamped = levelNumber.clamp(1, totalLevels);
    return _levels[clamped - 1];
  }

  static FishTank _makeTank(int id, int capacity, List<String> speciesList) {
    int fishIndex = 0;
    final fish = speciesList
        .map((sp) => Fish(id: '${sp}_${id}_${fishIndex++}', speciesId: sp))
        .toList();
    return FishTank(id: id, capacity: capacity, fish: fish);
  }

  static final List<FishFamilyLevel> _levels = [
    // Level 1: Tutorial — 2 species, 2 fish each, cap 3, 3 tanks
    FishFamilyLevel(
      levelNumber: 1,
      title: 'Baby Coral Reef',
      description:
          'Welcome to the Aquarium! Tap a tank to select its top fish, then tap another tank to move it.',
      capacity: 3,
      targetMoves: 3,
      tanks: [
        _makeTank(0, 3, ['clownfish', 'blue_tang']),
        _makeTank(1, 3, ['blue_tang', 'clownfish']),
        _makeTank(2, 3, []),
      ],
    ),

    // Level 2: 2 species, 3 fish each, cap 4, 3 tanks
    FishFamilyLevel(
      levelNumber: 2,
      title: 'Twin Tides',
      description:
          'Sort the clownfish and blue tangs into their own family tanks.',
      capacity: 4,
      targetMoves: 6,
      tanks: [
        _makeTank(0, 4, ['clownfish', 'blue_tang', 'clownfish']),
        _makeTank(1, 4, ['blue_tang', 'clownfish', 'blue_tang']),
        _makeTank(2, 4, []),
      ],
    ),

    // Level 3: 2 species, 4 fish each, cap 4, 3 tanks
    FishFamilyLevel(
      levelNumber: 3,
      title: 'Double Trouble',
      description:
          'Use the empty tank strategically to separate alternating fish.',
      capacity: 4,
      targetMoves: 10,
      tanks: [
        _makeTank(0, 4, ['clownfish', 'blue_tang', 'clownfish', 'blue_tang']),
        _makeTank(1, 4, ['blue_tang', 'clownfish', 'blue_tang', 'clownfish']),
        _makeTank(2, 4, []),
      ],
    ),

    // Level 4: 3 species, 3 fish each, cap 4, 4 tanks (1 empty)
    FishFamilyLevel(
      levelNumber: 4,
      title: 'Sunlit Shallows',
      description:
          'Yellow tangs have joined the party! Three families to sort.',
      capacity: 4,
      targetMoves: 7,
      tanks: [
        _makeTank(0, 4, ['clownfish', 'clownfish', 'blue_tang']),
        _makeTank(1, 4, ['yellow_tang', 'blue_tang', 'yellow_tang']),
        _makeTank(2, 4, ['blue_tang', 'yellow_tang', 'clownfish']),
        _makeTank(3, 4, []),
      ],
    ),

    // Level 5: 3 species, 3 fish each, cap 4, 4 tanks (1 empty)
    FishFamilyLevel(
      levelNumber: 5,
      title: 'Swirling Currents',
      description: 'Plan two steps ahead before clearing your first tank.',
      capacity: 4,
      targetMoves: 8,
      tanks: [
        _makeTank(0, 4, ['clownfish', 'blue_tang', 'yellow_tang']),
        _makeTank(1, 4, ['yellow_tang', 'clownfish', 'blue_tang']),
        _makeTank(2, 4, ['blue_tang', 'yellow_tang', 'clownfish']),
        _makeTank(3, 4, []),
      ],
    ),

    // Level 6: 3 species, 4 fish each, cap 4, 5 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 6,
      title: 'Lagoon Haven',
      description:
          'Two empty tanks give you breathing room to organize full schools of four.',
      capacity: 4,
      targetMoves: 12,
      tanks: [
        _makeTank(0, 4, ['clownfish', 'blue_tang', 'yellow_tang', 'clownfish']),
        _makeTank(1, 4, [
          'yellow_tang',
          'clownfish',
          'blue_tang',
          'yellow_tang',
        ]),
        _makeTank(2, 4, ['blue_tang', 'yellow_tang', 'clownfish', 'blue_tang']),
        _makeTank(3, 4, []),
        _makeTank(4, 4, []),
      ],
    ),

    // Level 7: 3 species, 4 fish each, cap 4, 5 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 7,
      title: 'Coral Garden',
      description:
          'Stack matching fish together whenever possible to free up slots.',
      capacity: 4,
      targetMoves: 12,
      tanks: [
        _makeTank(0, 4, ['blue_tang', 'clownfish', 'yellow_tang', 'blue_tang']),
        _makeTank(1, 4, ['clownfish', 'yellow_tang', 'clownfish', 'blue_tang']),
        _makeTank(2, 4, [
          'yellow_tang',
          'blue_tang',
          'yellow_tang',
          'clownfish',
        ]),
        _makeTank(3, 4, []),
        _makeTank(4, 4, []),
      ],
    ),

    // Level 8: 3 species, 4 fish each, cap 4, 5 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 8,
      title: 'Anemone Cove',
      description:
          'Dig out the bottom fish by temporarily parking top fish in the buffer.',
      capacity: 4,
      targetMoves: 12,
      tanks: [
        _makeTank(0, 4, ['clownfish', 'yellow_tang', 'blue_tang', 'clownfish']),
        _makeTank(1, 4, ['blue_tang', 'clownfish', 'yellow_tang', 'blue_tang']),
        _makeTank(2, 4, [
          'yellow_tang',
          'blue_tang',
          'clownfish',
          'yellow_tang',
        ]),
        _makeTank(3, 4, []),
        _makeTank(4, 4, []),
      ],
    ),

    // Level 9: 4 species, 3 fish each, cap 4, 5 tanks (1 empty)
    FishFamilyLevel(
      levelNumber: 9,
      title: 'Royal Arrival',
      description:
          'The majestic Royal Gramma arrives with royal purple colors!',
      capacity: 4,
      targetMoves: 11,
      tanks: [
        _makeTank(0, 4, ['royal_gramma', 'clownfish', 'blue_tang']),
        _makeTank(1, 4, ['yellow_tang', 'royal_gramma', 'clownfish']),
        _makeTank(2, 4, ['blue_tang', 'yellow_tang', 'royal_gramma']),
        _makeTank(3, 4, ['clownfish', 'blue_tang', 'yellow_tang']),
        _makeTank(4, 4, []),
      ],
    ),

    // Level 10: 4 species, 4 fish each, cap 4, 6 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 10,
      title: 'Reef Crossroad',
      description:
          'Milestone Level 10! Four colorful species navigating between two buffer tanks.',
      capacity: 4,
      targetMoves: 16,
      tanks: [
        _makeTank(0, 4, [
          'royal_gramma',
          'blue_tang',
          'clownfish',
          'yellow_tang',
        ]),
        _makeTank(1, 4, [
          'clownfish',
          'yellow_tang',
          'blue_tang',
          'royal_gramma',
        ]),
        _makeTank(2, 4, [
          'blue_tang',
          'royal_gramma',
          'yellow_tang',
          'clownfish',
        ]),
        _makeTank(3, 4, [
          'yellow_tang',
          'clownfish',
          'royal_gramma',
          'blue_tang',
        ]),
        _makeTank(4, 4, []),
        _makeTank(5, 4, []),
      ],
    ),

    // Level 11: 4 species, 4 fish each, cap 4, 6 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 11,
      title: 'Deep Blue Mystery',
      description:
          'Sixteen fish across four families. Watch your buffer space carefully!',
      capacity: 4,
      targetMoves: 15,
      tanks: [
        _makeTank(0, 4, [
          'clownfish',
          'blue_tang',
          'yellow_tang',
          'royal_gramma',
        ]),
        _makeTank(1, 4, [
          'royal_gramma',
          'clownfish',
          'blue_tang',
          'yellow_tang',
        ]),
        _makeTank(2, 4, [
          'yellow_tang',
          'royal_gramma',
          'clownfish',
          'blue_tang',
        ]),
        _makeTank(3, 4, [
          'blue_tang',
          'yellow_tang',
          'royal_gramma',
          'clownfish',
        ]),
        _makeTank(4, 4, []),
        _makeTank(5, 4, []),
      ],
    ),

    // Level 12: 4 species, 4 fish each, cap 4, 6 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 12,
      title: 'Aquamarine Maze',
      description:
          'Unraveling this grid requires matching pairs before tackling singletons.',
      capacity: 4,
      targetMoves: 15,
      tanks: [
        _makeTank(0, 4, [
          'blue_tang',
          'royal_gramma',
          'clownfish',
          'yellow_tang',
        ]),
        _makeTank(1, 4, [
          'yellow_tang',
          'blue_tang',
          'royal_gramma',
          'clownfish',
        ]),
        _makeTank(2, 4, [
          'clownfish',
          'yellow_tang',
          'blue_tang',
          'royal_gramma',
        ]),
        _makeTank(3, 4, [
          'royal_gramma',
          'clownfish',
          'yellow_tang',
          'blue_tang',
        ]),
        _makeTank(4, 4, []),
        _makeTank(5, 4, []),
      ],
    ),

    // Level 13: 4 species, 4 fish each, cap 4, 6 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 13,
      title: 'Bioluminescent Bay',
      description:
          'A tightly packed arrangement where one wrong move blocks the buffer.',
      capacity: 4,
      targetMoves: 13,
      tanks: [
        _makeTank(0, 4, [
          'clownfish',
          'clownfish',
          'royal_gramma',
          'blue_tang',
        ]),
        _makeTank(1, 4, [
          'yellow_tang',
          'blue_tang',
          'clownfish',
          'royal_gramma',
        ]),
        _makeTank(2, 4, [
          'royal_gramma',
          'yellow_tang',
          'blue_tang',
          'yellow_tang',
        ]),
        _makeTank(3, 4, [
          'blue_tang',
          'royal_gramma',
          'yellow_tang',
          'clownfish',
        ]),
        _makeTank(4, 4, []),
        _makeTank(5, 4, []),
      ],
    ),

    // Level 14: 4 species, 4 fish each, cap 4, 6 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 14,
      title: 'Tidal Cascade',
      description:
          'Cascade matching fish in succession to reveal buried species.',
      capacity: 4,
      targetMoves: 16,
      tanks: [
        _makeTank(0, 4, [
          'royal_gramma',
          'yellow_tang',
          'clownfish',
          'blue_tang',
        ]),
        _makeTank(1, 4, [
          'blue_tang',
          'clownfish',
          'royal_gramma',
          'yellow_tang',
        ]),
        _makeTank(2, 4, [
          'yellow_tang',
          'royal_gramma',
          'blue_tang',
          'clownfish',
        ]),
        _makeTank(3, 4, [
          'clownfish',
          'blue_tang',
          'yellow_tang',
          'royal_gramma',
        ]),
        _makeTank(4, 4, []),
        _makeTank(5, 4, []),
      ],
    ),

    // Level 15: 4 species, 4 fish each, cap 4, 6 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 15,
      title: 'Coral Labyrinth',
      description:
          'Complex interweaving demands complete preservation of your spare tank.',
      capacity: 4,
      targetMoves: 15,
      tanks: [
        _makeTank(0, 4, [
          'yellow_tang',
          'clownfish',
          'royal_gramma',
          'blue_tang',
        ]),
        _makeTank(1, 4, [
          'blue_tang',
          'yellow_tang',
          'clownfish',
          'royal_gramma',
        ]),
        _makeTank(2, 4, [
          'royal_gramma',
          'blue_tang',
          'yellow_tang',
          'clownfish',
        ]),
        _makeTank(3, 4, [
          'clownfish',
          'royal_gramma',
          'blue_tang',
          'yellow_tang',
        ]),
        _makeTank(4, 4, []),
        _makeTank(5, 4, []),
      ],
    ),

    // Level 16: 5 species, 3 fish each, cap 4, 7 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 16,
      title: 'Emerald Waters',
      description:
          'Green Chromis joins the family! Five species across seven tanks.',
      capacity: 4,
      targetMoves: 13,
      tanks: [
        _makeTank(0, 4, ['green_chromis', 'clownfish', 'blue_tang']),
        _makeTank(1, 4, ['yellow_tang', 'green_chromis', 'royal_gramma']),
        _makeTank(2, 4, ['clownfish', 'blue_tang', 'green_chromis']),
        _makeTank(3, 4, ['royal_gramma', 'yellow_tang', 'clownfish']),
        _makeTank(4, 4, ['blue_tang', 'royal_gramma', 'yellow_tang']),
        _makeTank(5, 4, []),
        _makeTank(6, 4, []),
      ],
    ),

    // Level 17: 5 species, 4 fish each, cap 4, 7 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 17,
      title: 'Abyssal Symphony',
      description:
          'Twenty vibrant fish needing rescue. Precision and foresight are essential.',
      capacity: 4,
      targetMoves: 20,
      tanks: [
        _makeTank(0, 4, [
          'green_chromis',
          'blue_tang',
          'yellow_tang',
          'clownfish',
        ]),
        _makeTank(1, 4, [
          'clownfish',
          'royal_gramma',
          'green_chromis',
          'blue_tang',
        ]),
        _makeTank(2, 4, [
          'blue_tang',
          'yellow_tang',
          'royal_gramma',
          'green_chromis',
        ]),
        _makeTank(3, 4, [
          'royal_gramma',
          'green_chromis',
          'clownfish',
          'yellow_tang',
        ]),
        _makeTank(4, 4, [
          'yellow_tang',
          'clownfish',
          'blue_tang',
          'royal_gramma',
        ]),
        _makeTank(5, 4, []),
        _makeTank(6, 4, []),
      ],
    ),

    // Level 18: 5 species, 4 fish each, cap 4, 7 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 18,
      title: 'Sunken Kingdom',
      description:
          'Deep dependencies require sorting outer families before unlocking the core.',
      capacity: 4,
      targetMoves: 19,
      tanks: [
        _makeTank(0, 4, [
          'yellow_tang',
          'green_chromis',
          'blue_tang',
          'royal_gramma',
        ]),
        _makeTank(1, 4, [
          'green_chromis',
          'clownfish',
          'yellow_tang',
          'royal_gramma',
        ]),
        _makeTank(2, 4, [
          'royal_gramma',
          'blue_tang',
          'green_chromis',
          'clownfish',
        ]),
        _makeTank(3, 4, [
          'clownfish',
          'royal_gramma',
          'blue_tang',
          'yellow_tang',
        ]),
        _makeTank(4, 4, [
          'blue_tang',
          'yellow_tang',
          'clownfish',
          'green_chromis',
        ]),
        _makeTank(5, 4, []),
        _makeTank(6, 4, []),
      ],
    ),

    // Level 19: 5 species, 4 fish each, cap 4, 7 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 19,
      title: 'Pelagic Trench',
      description:
          'Extreme multi-stage sorting where every buffer move must be planned in advance.',
      capacity: 4,
      targetMoves: 21,
      tanks: [
        _makeTank(0, 4, [
          'clownfish',
          'royal_gramma',
          'yellow_tang',
          'green_chromis',
        ]),
        _makeTank(1, 4, [
          'green_chromis',
          'blue_tang',
          'clownfish',
          'yellow_tang',
        ]),
        _makeTank(2, 4, [
          'yellow_tang',
          'green_chromis',
          'royal_gramma',
          'blue_tang',
        ]),
        _makeTank(3, 4, [
          'blue_tang',
          'clownfish',
          'green_chromis',
          'royal_gramma',
        ]),
        _makeTank(4, 4, [
          'royal_gramma',
          'yellow_tang',
          'blue_tang',
          'clownfish',
        ]),
        _makeTank(5, 4, []),
        _makeTank(6, 4, []),
      ],
    ),

    // Level 20: 6 species, 3 fish each, cap 4, 8 tanks (2 empty)
    FishFamilyLevel(
      levelNumber: 20,
      title: 'Grand Aquarium Finale',
      description:
          'The ultimate challenge! All six species assembled for the grand rescue celebration.',
      capacity: 4,
      targetMoves: 15,
      tanks: [
        _makeTank(0, 4, ['pink_anthias', 'clownfish', 'blue_tang']),
        _makeTank(1, 4, ['green_chromis', 'pink_anthias', 'yellow_tang']),
        _makeTank(2, 4, ['royal_gramma', 'green_chromis', 'pink_anthias']),
        _makeTank(3, 4, ['blue_tang', 'royal_gramma', 'clownfish']),
        _makeTank(4, 4, ['yellow_tang', 'blue_tang', 'green_chromis']),
        _makeTank(5, 4, ['clownfish', 'yellow_tang', 'royal_gramma']),
        _makeTank(6, 4, []),
        _makeTank(7, 4, []),
      ],
    ),
  ];
}
