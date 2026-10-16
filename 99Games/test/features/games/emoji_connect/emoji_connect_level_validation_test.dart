import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_level_data.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_models.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_solver.dart';

void main() {
  group('Emoji Connect Curated Levels Validation', () {
    test(
      'Easy difficulty contains at least 10 levels with 5x5 board and 3-4 pairs',
      () {
        final easy = EmojiConnectLevelData.easyLevels;
        expect(easy.length, greaterThanOrEqualTo(10));

        for (final lvl in easy) {
          expect(lvl.difficulty, equals(EmojiConnectDifficulty.easy));
          expect(lvl.boardSize, equals(5));
          expect(lvl.pairs.length, inInclusiveRange(3, 4));
        }
      },
    );

    test(
      'Medium difficulty contains at least 10 levels with 6x6 board and 5-6 pairs',
      () {
        final medium = EmojiConnectLevelData.mediumLevels;
        expect(medium.length, greaterThanOrEqualTo(10));

        for (final lvl in medium) {
          expect(lvl.difficulty, equals(EmojiConnectDifficulty.medium));
          expect(lvl.boardSize, equals(6));
          expect(lvl.pairs.length, inInclusiveRange(5, 6));
        }
      },
    );

    test(
      'Hard difficulty contains at least 10 levels with 8x8 board and 7-9 pairs',
      () {
        final hard = EmojiConnectLevelData.hardLevels;
        expect(hard.length, greaterThanOrEqualTo(10));

        for (final lvl in hard) {
          expect(lvl.difficulty, equals(EmojiConnectDifficulty.hard));
          expect(lvl.boardSize, equals(8));
          expect(lvl.pairs.length, inInclusiveRange(7, 9));
        }
      },
    );

    for (final difficulty in EmojiConnectDifficulty.values) {
      group('Validation for all ${difficulty.displayName} levels', () {
        final levels = EmojiConnectLevelData.getLevelsForDifficulty(difficulty);

        for (int i = 0; i < levels.length; i++) {
          final level = levels[i];

          test(
            'Level ${level.id} (${difficulty.displayName}) is completely valid and solvable',
            () {
              final size = level.boardSize;
              final totalCells = size * size;

              // 1. Check endpoints
              final allEndpoints = <GridPosition>{};
              for (final pair in level.pairs) {
                expect(pair.endpointA.isWithinBounds(size), isTrue);
                expect(pair.endpointB.isWithinBounds(size), isTrue);
                expect(pair.endpointA, isNot(equals(pair.endpointB)));

                expect(
                  allEndpoints.add(pair.endpointA),
                  isTrue,
                  reason: 'Duplicate endpoint at ${pair.endpointA}',
                );
                expect(
                  allEndpoints.add(pair.endpointB),
                  isTrue,
                  reason: 'Duplicate endpoint at ${pair.endpointB}',
                );
              }

              // 2. Check reference solution completeness and rules
              final ref = level.referenceSolution;
              expect(ref.length, equals(level.pairs.length));

              final coveredCells = <GridPosition>{};

              for (final pair in level.pairs) {
                expect(
                  ref.containsKey(pair.id),
                  isTrue,
                  reason: 'Missing reference solution for ${pair.id}',
                );

                final path = ref[pair.id]!;
                expect(path.length, greaterThanOrEqualTo(2));

                // Endpoints match pair
                final startsAtA =
                    path.first == pair.endpointA && path.last == pair.endpointB;
                final startsAtB =
                    path.first == pair.endpointB && path.last == pair.endpointA;
                expect(
                  startsAtA || startsAtB,
                  isTrue,
                  reason: 'Path does not connect endpoints for ${pair.id}',
                );

                // Orthogonal connectivity
                for (int step = 0; step < path.length - 1; step++) {
                  final p1 = path[step];
                  final p2 = path[step + 1];
                  expect(
                    p1.isOrthogonalTo(p2),
                    isTrue,
                    reason:
                        'Diagonal or non-adjacent step between $p1 and $p2 in ${pair.id}',
                  );
                }

                // No repeated cells within path
                final selfCells = <GridPosition>{};
                for (final p in path) {
                  expect(p.isWithinBounds(size), isTrue);
                  expect(
                    selfCells.add(p),
                    isTrue,
                    reason: 'Self-intersecting cell at $p in ${pair.id}',
                  );

                  // No overlap with other paths
                  expect(
                    coveredCells.add(p),
                    isTrue,
                    reason: 'Cell overlap at $p in level ${level.id}',
                  );
                }
              }

              // 3. Complete cell coverage
              expect(
                coveredCells.length,
                equals(totalCells),
                reason:
                    'Level ${level.id} reference solution does not cover 100% of grid',
              );

              // 4. Verification with Solver
              final enginePaths = ref.map(
                (k, pts) => MapEntry(k, EmojiPath(pairId: k, points: pts)),
              );
              final val = EmojiConnectSolver.validate(
                level: level,
                paths: enginePaths,
              );
              expect(val.isValid, isTrue);
              expect(val.isCompleteWin, isTrue);
              expect(val.coveredCellsCount, equals(totalCells));
              expect(val.connectedPairsCount, equals(level.pairs.length));
            },
          );
        }
      });
    }
  });
}
