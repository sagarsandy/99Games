import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/domain/fish_family_engine.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/domain/fish_family_level_data.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/domain/fish_family_models.dart';
import 'package:mini_games_99/features/games/fish_family_rescue/domain/fish_family_solver.dart';

void main() {
  const engine = FishFamilyEngine();
  const solver = FishFamilySolver();

  group('FishFamily Models & Rules Tests', () {
    test('FishTank properties and capacity constraints', () {
      final tank = FishTank(
        id: 0,
        capacity: 4,
        fish: const [
          Fish(id: 'c1', speciesId: 'clownfish'),
          Fish(id: 'c2', speciesId: 'clownfish'),
        ],
      );

      expect(tank.isFull, isFalse);
      expect(tank.isEmpty, isFalse);
      expect(tank.freeCapacity, equals(2));
      expect(tank.topFish?.id, equals('c2'));
      expect(tank.isPure, isTrue);
      expect(tank.isComplete, isFalse);

      final fullTank = tank.copyWith(
        fish: const [
          Fish(id: 'c1', speciesId: 'clownfish'),
          Fish(id: 'c2', speciesId: 'clownfish'),
          Fish(id: 'c3', speciesId: 'clownfish'),
          Fish(id: 'c4', speciesId: 'clownfish'),
        ],
      );
      expect(fullTank.isFull, isTrue);
      expect(fullTank.isComplete, isTrue);

      final mixedTank = tank.copyWith(
        fish: const [
          Fish(id: 'c1', speciesId: 'clownfish'),
          Fish(id: 'b1', speciesId: 'blue_tang'),
        ],
      );
      expect(mixedTank.isPure, isFalse);
      expect(mixedTank.isComplete, isFalse);
    });

    test('Moving onto the same tank is rejected', () {
      final tanks = [
        const FishTank(
          id: 0,
          capacity: 4,
          fish: [Fish(id: 'c1', speciesId: 'clownfish')],
        ),
      ];

      final result = engine.validateMove(tanks, 0, 0);
      expect(result.isValid, isFalse);
      expect(result.failureReason, equals(MoveFailureReason.sameTank));
    });

    test('Moving from empty tank is rejected', () {
      final tanks = [
        const FishTank(id: 0, capacity: 4, fish: []),
        const FishTank(id: 1, capacity: 4, fish: []),
      ];

      final result = engine.validateMove(tanks, 0, 1);
      expect(result.isValid, isFalse);
      expect(result.failureReason, equals(MoveFailureReason.sourceEmpty));
    });

    test('Moving into full tank is rejected', () {
      final tanks = [
        const FishTank(
          id: 0,
          capacity: 4,
          fish: [Fish(id: 'c1', speciesId: 'clownfish')],
        ),
        const FishTank(
          id: 1,
          capacity: 2,
          fish: [
            Fish(id: 'c2', speciesId: 'clownfish'),
            Fish(id: 'c3', speciesId: 'clownfish'),
          ],
        ),
      ];

      final result = engine.validateMove(tanks, 0, 1);
      expect(result.isValid, isFalse);
      expect(result.failureReason, equals(MoveFailureReason.destinationFull));
    });

    test('Moving into tank with different top species is rejected', () {
      final tanks = [
        const FishTank(
          id: 0,
          capacity: 4,
          fish: [Fish(id: 'c1', speciesId: 'clownfish')],
        ),
        const FishTank(
          id: 1,
          capacity: 4,
          fish: [Fish(id: 'b1', speciesId: 'blue_tang')],
        ),
      ];

      final result = engine.validateMove(tanks, 0, 1);
      expect(result.isValid, isFalse);
      expect(result.failureReason, equals(MoveFailureReason.speciesMismatch));
    });

    test(
      'Moving into empty tank or matching species tank is valid and only moves top fish',
      () {
        final tanks = [
          const FishTank(
            id: 0,
            capacity: 4,
            fish: [
              Fish(id: 'b1', speciesId: 'blue_tang'),
              Fish(id: 'c1', speciesId: 'clownfish'),
            ],
          ),
          const FishTank(id: 1, capacity: 4, fish: []),
          const FishTank(
            id: 2,
            capacity: 4,
            fish: [Fish(id: 'c2', speciesId: 'clownfish')],
          ),
        ];

        // Move into empty tank
        final res1 = engine.validateMove(tanks, 0, 1);
        expect(res1.isValid, isTrue);

        // Move into matching species tank
        final res2 = engine.validateMove(tanks, 0, 2);
        expect(res2.isValid, isTrue);

        // Execute move from 0 to 2
        final executed = engine.executeMove(tanks, 0, 2);
        expect(executed.move.fish.id, equals('c1'));
        expect(executed.tanks[0].fish.length, equals(1));
        expect(executed.tanks[0].topFish?.id, equals('b1'));
        expect(executed.tanks[2].fish.length, equals(2));
        expect(executed.tanks[2].topFish?.id, equals('c1'));

        // Undo move restores exact tank state
        final undone = engine.undoMove(executed.tanks, executed.move);
        expect(undone[0].fish.length, equals(2));
        expect(undone[0].topFish?.id, equals('c1'));
        expect(undone[2].fish.length, equals(1));
        expect(undone[2].topFish?.id, equals('c2'));
      },
    );

    group('Authoritative isLevelComplete Tests', () {
      final level1 = FishFamilyLevelData.getLevel(1);

      test('Completely sorted board returns true', () {
        final sortedTanks = [
          const FishTank(
            id: 0,
            capacity: 3,
            fish: [
              Fish(id: 'clownfish_0_0', speciesId: 'clownfish'),
              Fish(id: 'clownfish_1_1', speciesId: 'clownfish'),
            ],
          ),
          const FishTank(id: 1, capacity: 3, fish: []),
          const FishTank(
            id: 2,
            capacity: 3,
            fish: [
              Fish(id: 'blue_tang_0_1', speciesId: 'blue_tang'),
              Fish(id: 'blue_tang_1_0', speciesId: 'blue_tang'),
            ],
          ),
        ];

        expect(engine.isLevelComplete(sortedTanks, level1), isTrue);
      });

      test(
        'Board with species split across multiple tanks returns false (Bug Fix)',
        () {
          // Level 1 after move 2 (Tank 1 -> Tank 0):
          // Tank 0: 2 clownfish (isPure: true)
          // Tank 1: 1 blue tang (isPure: true)
          // Tank 2: 1 blue tang (isPure: true)
          // Middle tank still has an unmerged blue tang!
          final splitTanks = [
            const FishTank(
              id: 0,
              capacity: 3,
              fish: [
                Fish(id: 'clownfish_0_0', speciesId: 'clownfish'),
                Fish(id: 'clownfish_1_1', speciesId: 'clownfish'),
              ],
            ),
            const FishTank(
              id: 1,
              capacity: 3,
              fish: [Fish(id: 'blue_tang_1_0', speciesId: 'blue_tang')],
            ),
            const FishTank(
              id: 2,
              capacity: 3,
              fish: [Fish(id: 'blue_tang_0_1', speciesId: 'blue_tang')],
            ),
          ];

          expect(engine.isLevelComplete(splitTanks, level1), isFalse);
          expect(engine.checkWin(splitTanks, expectedTotalFish: 4), isFalse);
        },
      );

      test('Board with a mixed-species tank returns false', () {
        final mixedTanks = [
          const FishTank(
            id: 0,
            capacity: 3,
            fish: [
              Fish(id: 'clownfish_0_0', speciesId: 'clownfish'),
              Fish(id: 'blue_tang_0_1', speciesId: 'blue_tang'),
            ],
          ),
          const FishTank(
            id: 1,
            capacity: 3,
            fish: [
              Fish(id: 'blue_tang_1_0', speciesId: 'blue_tang'),
              Fish(id: 'clownfish_1_1', speciesId: 'clownfish'),
            ],
          ),
          const FishTank(id: 2, capacity: 3, fish: []),
        ];

        expect(engine.isLevelComplete(mixedTanks, level1), isFalse);
      });

      test('Empty spare tanks and partially filled pure tanks are allowed', () {
        // Level 1 has capacity 3 tanks, but only 2 fish per species.
        // Tanks have 2/3 fish, which is valid and complete.
        final validTanks = [
          const FishTank(
            id: 0,
            capacity: 3,
            fish: [
              Fish(id: 'clownfish_0_0', speciesId: 'clownfish'),
              Fish(id: 'clownfish_1_1', speciesId: 'clownfish'),
            ],
          ),
          const FishTank(id: 1, capacity: 3, fish: []),
          const FishTank(
            id: 2,
            capacity: 3,
            fish: [
              Fish(id: 'blue_tang_0_1', speciesId: 'blue_tang'),
              Fish(id: 'blue_tang_1_0', speciesId: 'blue_tang'),
            ],
          ),
        ];

        expect(engine.isLevelComplete(validTanks, level1), isTrue);
      });

      test('Board missing a fish returns false', () {
        final missingFishTanks = [
          const FishTank(
            id: 0,
            capacity: 3,
            fish: [Fish(id: 'clownfish_0_0', speciesId: 'clownfish')],
          ),
          const FishTank(id: 1, capacity: 3, fish: []),
          const FishTank(
            id: 2,
            capacity: 3,
            fish: [
              Fish(id: 'blue_tang_0_1', speciesId: 'blue_tang'),
              Fish(id: 'blue_tang_1_0', speciesId: 'blue_tang'),
            ],
          ),
        ];

        expect(engine.isLevelComplete(missingFishTanks, level1), isFalse);
      });

      test('Board with duplicate fish returns false', () {
        final duplicateTanks = [
          const FishTank(
            id: 0,
            capacity: 3,
            fish: [
              Fish(id: 'clownfish_0_0', speciesId: 'clownfish'),
              Fish(id: 'clownfish_0_0', speciesId: 'clownfish'),
            ],
          ),
          const FishTank(id: 1, capacity: 3, fish: []),
          const FishTank(
            id: 2,
            capacity: 3,
            fish: [
              Fish(id: 'blue_tang_0_1', speciesId: 'blue_tang'),
              Fish(id: 'blue_tang_1_0', speciesId: 'blue_tang'),
            ],
          ),
        ];

        expect(engine.isLevelComplete(duplicateTanks, level1), isFalse);
      });

      test(
        'Board with correct total count but wrong species distribution returns false',
        () {
          final wrongDistributionTanks = [
            const FishTank(
              id: 0,
              capacity: 3,
              fish: [
                Fish(id: 'clownfish_0_0', speciesId: 'clownfish'),
                Fish(id: 'clownfish_1_1', speciesId: 'clownfish'),
                Fish(id: 'clownfish_extra', speciesId: 'clownfish'),
              ],
            ),
            const FishTank(id: 1, capacity: 3, fish: []),
            const FishTank(
              id: 2,
              capacity: 3,
              fish: [Fish(id: 'blue_tang_0_1', speciesId: 'blue_tang')],
            ),
          ];

          expect(
            engine.isLevelComplete(wrongDistributionTanks, level1),
            isFalse,
          );
        },
      );

      test('Tank exceeding capacity returns false', () {
        final overCapacityTanks = [
          const FishTank(
            id: 0,
            capacity: 2, // Capacity is 2 but 3 fish placed
            fish: [
              Fish(id: 'clownfish_0_0', speciesId: 'clownfish'),
              Fish(id: 'clownfish_1_1', speciesId: 'clownfish'),
              Fish(id: 'clownfish_extra', speciesId: 'clownfish'),
            ],
          ),
          const FishTank(id: 1, capacity: 2, fish: []),
        ];

        expect(engine.isLevelComplete(overCapacityTanks, level1), isFalse);
      });

      test(
        'A legal move alone does not trigger completion before board is solved',
        () {
          var currentTanks = level1.tanks;

          // Move 1: 0 -> 2
          final res1 = engine.executeMove(currentTanks, 0, 2);
          currentTanks = res1.tanks;
          expect(engine.isLevelComplete(currentTanks, level1), isFalse);

          // Move 2: 1 -> 0 (Leaves blue tang split!)
          final res2 = engine.executeMove(currentTanks, 1, 0);
          currentTanks = res2.tanks;
          expect(engine.isLevelComplete(currentTanks, level1), isFalse);

          // Move 3: 1 -> 2 (Combines blue tangs together)
          final res3 = engine.executeMove(currentTanks, 1, 2);
          currentTanks = res3.tanks;
          expect(engine.isLevelComplete(currentTanks, level1), isTrue);
        },
      );
    });
  });

  group('FishFamily 20 Levels Solvability Verification', () {
    test(
      'All 20 bundled levels have valid structural integrity and are 100% solvable with authoritative win condition',
      () {
        expect(FishFamilyLevelData.totalLevels, equals(20));

        for (int i = 1; i <= 20; i++) {
          final level = FishFamilyLevelData.getLevel(i);
          expect(level.levelNumber, equals(i));
          expect(engine.validateLevelIntegrity(level), isTrue);

          final solution = solver.solve(level);
          expect(
            solution,
            isNotNull,
            reason:
                'Level $i (${level.title}) must have a valid legal solution',
          );
          expect(
            solution!.length,
            equals(level.targetMoves),
            reason: 'Level $i target moves must match optimal solution length',
          );

          // Replay solution moves to verify they lead to victory and never trigger prematurely
          var currentTanks = level.tanks;
          int moveIndex = 0;
          for (final move in solution) {
            moveIndex++;
            final validation = engine.validateMove(
              currentTanks,
              move.fromTankId,
              move.toTankId,
            );
            expect(
              validation.isValid,
              isTrue,
              reason: 'Move $move in Level $i solution must be valid',
            );
            final res = engine.executeMove(
              currentTanks,
              move.fromTankId,
              move.toTankId,
            );
            currentTanks = res.tanks;

            final isIntermediateWon = engine.isLevelComplete(
              currentTanks,
              level,
            );
            if (moveIndex < solution.length) {
              expect(
                isIntermediateWon,
                isFalse,
                reason:
                    'Level $i move $moveIndex must not complete the level prematurely',
              );
            } else {
              expect(
                isIntermediateWon,
                isTrue,
                reason:
                    'Level $i final move $moveIndex must satisfy authoritative win condition',
              );
            }
          }
        }
      },
    );

    test('Progression increases from early tutorial to expert puzzles', () {
      final level1 = FishFamilyLevelData.getLevel(1);
      final level10 = FishFamilyLevelData.getLevel(10);
      final level20 = FishFamilyLevelData.getLevel(20);

      final eval1 = solver.evaluateDifficulty(level1);
      final eval10 = solver.evaluateDifficulty(level10);
      final eval20 = solver.evaluateDifficulty(level20);

      expect(eval10.difficultyScore > eval1.difficultyScore, isTrue);
      expect(eval20.speciesCount > eval10.speciesCount, isTrue);
      expect(eval20.difficultyScore > eval1.difficultyScore, isTrue);
    });
  });
}
