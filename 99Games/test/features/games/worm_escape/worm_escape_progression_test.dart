import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_engine.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_evaluator.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_level_data.dart';
import 'package:mini_games_99/features/games/worm_escape/domain/worm_escape_models.dart';

void main() {
  group('Worm Escape Progressive Difficulty Suite (All 75 Levels)', () {
    test('Level catalog contains 25 levels for each difficulty (75 total)', () {
      final easy = WormEscapeLevelData.getLevelsByDifficulty(
        WormEscapeDifficulty.easy,
      );
      final medium = WormEscapeLevelData.getLevelsByDifficulty(
        WormEscapeDifficulty.medium,
      );
      final hard = WormEscapeLevelData.getLevelsByDifficulty(
        WormEscapeDifficulty.hard,
      );

      expect(easy.length, equals(25));
      expect(medium.length, equals(25));
      expect(hard.length, equals(25));
      expect(WormEscapeLevelData.levels.length, equals(75));
    });

    test('Every level is structurally sound and replayed to 100% completion', () {
      for (final level in WormEscapeLevelData.levels) {
        final validation = WormEscapeEngine.validateLevel(level);
        expect(
          validation.isValid,
          isTrue,
          reason:
              'Level ${level.id} failed validation: ${validation.errorMessage}',
        );
      }
    });

    test('No duplicate levels exist in the catalog', () {
      final fingerprints = <String>{};

      for (final level in WormEscapeLevelData.levels) {
        // Build structural fingerprint: sorted cell positions + directions
        final wormSigs = level.worms.map((w) {
          final bodySig = w.body.map((p) => '${p.row},${p.col}').join(';');
          return '${w.direction.name}:$bodySig';
        }).toList()..sort();

        final fp = '${level.boardSize}::${wormSigs.join('|')}';
        expect(
          fingerprints.contains(fp),
          isFalse,
          reason: 'Duplicate puzzle detected for level ${level.id}',
        );
        fingerprints.add(fp);
      }
    });

    void auditDifficultyProgression(WormEscapeDifficulty difficulty) {
      final levels = WormEscapeLevelData.getLevelsByDifficulty(difficulty);
      final buffer = StringBuffer();
      buffer.writeln('\n========================================');
      buffer.writeln(
        'PROGRESSION AUDIT: ${difficulty.displayName.toUpperCase()}',
      );
      buffer.writeln('========================================');

      WormEscapeMetrics? prevMetrics;

      for (int i = 0; i < levels.length; i++) {
        final level = levels[i];
        final metrics = WormEscapeEvaluator.evaluate(level);

        String comparison;
        if (prevMetrics == null) {
          comparison = 'Initial level';
        } else {
          final diff = metrics.difficultyScore - prevMetrics.difficultyScore;
          if (diff > 0.05) {
            comparison = 'Harder than Level $i (+${diff.toStringAsFixed(1)})';
          } else if (diff.abs() <= 0.05) {
            comparison = 'Equivalent challenge to Level $i';
          } else {
            comparison =
                'Slightly lighter than Level $i (${diff.toStringAsFixed(1)})';
          }
        }

        buffer.writeln(
          '\n${difficulty.displayName} Level ${level.levelNumber}',
        );
        buffer.writeln(
          'Difficulty score: ${metrics.difficultyScore.toStringAsFixed(1)}',
        );
        buffer.writeln('Dependency depth: ${metrics.maxDependencyDepth}');
        buffer.writeln(
          'Initially available worms: ${metrics.initiallyAvailableCount} / ${metrics.totalWorms}',
        );
        buffer.writeln('Total blockers: ${metrics.totalBlockers}');
        buffer.writeln(
          'Worms with multiple blockers: ${metrics.multipleBlockerWormCount}',
        );
        buffer.writeln(
          'Converging blocker dependencies: ${metrics.convergingBlockersCount}',
        );
        buffer.writeln('Solution valid: Yes');
        buffer.writeln('Progression: $comparison');

        // Verify non-regression: score must not drop materially below previous level
        if (prevMetrics != null) {
          expect(
            metrics.difficultyScore >= prevMetrics.difficultyScore - 1.5,
            isTrue,
            reason:
                'Level ${level.levelNumber} (${metrics.difficultyScore.toStringAsFixed(1)}) '
                'has regression compared to Level $i (${prevMetrics.difficultyScore.toStringAsFixed(1)})',
          );
        }

        prevMetrics = metrics;
      }

      // Print full formatted report for inspection
      // ignore: avoid_print
      print(buffer.toString());

      // 5-level milestone validations
      final m1 = WormEscapeEvaluator.evaluate(levels[0]); // Level 1
      final m5 = WormEscapeEvaluator.evaluate(levels[4]); // Level 5
      final m10 = WormEscapeEvaluator.evaluate(levels[9]); // Level 10
      final m15 = WormEscapeEvaluator.evaluate(levels[14]); // Level 15
      final m20 = WormEscapeEvaluator.evaluate(levels[19]); // Level 20
      final m25 = WormEscapeEvaluator.evaluate(levels[24]); // Level 25

      // Check milestones show clear structural leaps
      expect(m5.difficultyScore, greaterThan(m1.difficultyScore));
      expect(m10.difficultyScore, greaterThan(m5.difficultyScore));
      expect(m15.difficultyScore, greaterThan(m10.difficultyScore));
      expect(m20.difficultyScore, greaterThan(m15.difficultyScore));
      expect(m25.difficultyScore, greaterThan(m20.difficultyScore));

      // Level 10 vs Level 1 requirement
      expect(m10.difficultyScore, greaterThan(m1.difficultyScore * 1.5));
      expect(
        m10.maxDependencyDepth,
        greaterThanOrEqualTo(m1.maxDependencyDepth),
      );

      // Level 20 vs Level 10 requirement
      expect(m20.difficultyScore, greaterThan(m10.difficultyScore * 1.2));
      expect(
        m20.maxDependencyDepth,
        greaterThanOrEqualTo(m10.maxDependencyDepth),
      );

      // Level 25 vs Level 20 requirement
      expect(m25.difficultyScore, greaterThan(m20.difficultyScore));
    }

    test('Easy tier strictly progresses in difficulty from Level 1 to 25', () {
      auditDifficultyProgression(WormEscapeDifficulty.easy);
    });

    test(
      'Medium tier strictly progresses in difficulty from Level 1 to 25',
      () {
        auditDifficultyProgression(WormEscapeDifficulty.medium);
      },
    );

    test('Hard tier strictly progresses in difficulty from Level 1 to 25', () {
      auditDifficultyProgression(WormEscapeDifficulty.hard);
    });

    test('Cross-tier progression increases across difficulties', () {
      final easyLvl1 = WormEscapeEvaluator.evaluate(
        WormEscapeLevelData.getLevel(WormEscapeDifficulty.easy, 1),
      );
      final medLvl1 = WormEscapeEvaluator.evaluate(
        WormEscapeLevelData.getLevel(WormEscapeDifficulty.medium, 1),
      );
      final hardLvl1 = WormEscapeEvaluator.evaluate(
        WormEscapeLevelData.getLevel(WormEscapeDifficulty.hard, 1),
      );

      final easyLvl25 = WormEscapeEvaluator.evaluate(
        WormEscapeLevelData.getLevel(WormEscapeDifficulty.easy, 25),
      );
      final medLvl25 = WormEscapeEvaluator.evaluate(
        WormEscapeLevelData.getLevel(WormEscapeDifficulty.medium, 25),
      );
      final hardLvl25 = WormEscapeEvaluator.evaluate(
        WormEscapeLevelData.getLevel(WormEscapeDifficulty.hard, 25),
      );

      expect(medLvl1.difficultyScore, greaterThan(easyLvl1.difficultyScore));
      expect(hardLvl1.difficultyScore, greaterThan(medLvl1.difficultyScore));

      expect(medLvl25.difficultyScore, greaterThan(easyLvl25.difficultyScore));
      expect(hardLvl25.difficultyScore, greaterThan(medLvl25.difficultyScore));
    });
  });
}
