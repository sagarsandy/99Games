import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/reaction_test/domain/reaction_test_engine.dart';
import 'package:mini_games_99/features/games/reaction_test/domain/reaction_test_models.dart';

void main() {
  group('Reaction Test - Domain Models & Logic', () {
    test(
      'ReactionCategory categorizes millisecond values according to spec',
      () {
        expect(
          ReactionCategory.fromMs(null),
          equals(ReactionCategory.falseStart),
        );
        expect(ReactionCategory.fromMs(150), equals(ReactionCategory.veryFast));
        expect(ReactionCategory.fromMs(199), equals(ReactionCategory.veryFast));
        expect(ReactionCategory.fromMs(200), equals(ReactionCategory.fast));
        expect(ReactionCategory.fromMs(245), equals(ReactionCategory.fast));
        expect(ReactionCategory.fromMs(250), equals(ReactionCategory.fast));
        expect(ReactionCategory.fromMs(251), equals(ReactionCategory.typical));
        expect(ReactionCategory.fromMs(350), equals(ReactionCategory.typical));
        expect(
          ReactionCategory.fromMs(351),
          equals(ReactionCategory.needsPractice),
        );
        expect(
          ReactionCategory.fromMs(500),
          equals(ReactionCategory.needsPractice),
        );
      },
    );

    test('RoundOutcome formats result string correctly', () {
      const valid = RoundOutcome(
        roundNumber: 1,
        isFalseStart: false,
        reactionTimeMs: 247,
      );
      expect(valid.formattedResult, equals('247 ms'));
      expect(valid.category, equals(ReactionCategory.fast));

      const falseStart = RoundOutcome(
        roundNumber: 2,
        isFalseStart: true,
        reactionTimeMs: null,
      );
      expect(falseStart.formattedResult, equals('Too early!'));
      expect(falseStart.category, equals(ReactionCategory.falseStart));
    });

    test('RoundOutcome serialization and deserialization roundtrip', () {
      const outcome = RoundOutcome(
        roundNumber: 3,
        isFalseStart: false,
        reactionTimeMs: 215,
      );
      final map = outcome.toMap();
      final restored = RoundOutcome.fromMap(map);
      expect(restored, equals(outcome));
    });

    test(
      'ReactionTestSessionSummary calculates valid average, fastest, and slowest',
      () {
        const outcomes = [
          RoundOutcome(
            roundNumber: 1,
            isFalseStart: false,
            reactionTimeMs: 200,
          ),
          RoundOutcome(
            roundNumber: 2,
            isFalseStart: false,
            reactionTimeMs: 300,
          ),
          RoundOutcome(
            roundNumber: 3,
            isFalseStart: true,
            reactionTimeMs: null,
          ),
          RoundOutcome(
            roundNumber: 4,
            isFalseStart: false,
            reactionTimeMs: 150,
          ),
          RoundOutcome(
            roundNumber: 5,
            isFalseStart: false,
            reactionTimeMs: 250,
          ),
        ];

        final summary = ReactionTestEngine.evaluateSession(outcomes);

        expect(summary.validCount, equals(4));
        expect(summary.falseStartCount, equals(1));
        expect(summary.validReactionTimes, equals([200, 300, 150, 250]));
        // (200 + 300 + 150 + 250) / 4 = 900 / 4 = 225.0
        expect(summary.averageMs, equals(225.0));
        expect(summary.fastestMs, equals(150));
        expect(summary.slowestMs, equals(300));
        expect(summary.isAllFalseStarts, isFalse);
        expect(summary.averageCategory, equals(ReactionCategory.fast));
      },
    );

    test(
      'ReactionTestSessionSummary handles all false starts safely without division by zero',
      () {
        const allFalseStarts = [
          RoundOutcome(roundNumber: 1, isFalseStart: true),
          RoundOutcome(roundNumber: 2, isFalseStart: true),
          RoundOutcome(roundNumber: 3, isFalseStart: true),
          RoundOutcome(roundNumber: 4, isFalseStart: true),
          RoundOutcome(roundNumber: 5, isFalseStart: true),
        ];

        final summary = ReactionTestEngine.evaluateSession(allFalseStarts);

        expect(summary.validCount, equals(0));
        expect(summary.falseStartCount, equals(5));
        expect(summary.validReactionTimes, isEmpty);
        expect(summary.averageMs, isNull);
        expect(summary.fastestMs, isNull);
        expect(summary.slowestMs, isNull);
        expect(summary.isAllFalseStarts, isTrue);
        expect(summary.averageCategory, isNull);
      },
    );

    test('ReactionTestSessionSummary handles empty list safely', () {
      final summary = ReactionTestEngine.evaluateSession([]);
      expect(summary.validCount, equals(0));
      expect(summary.falseStartCount, equals(0));
      expect(summary.averageMs, isNull);
      expect(summary.fastestMs, isNull);
      expect(summary.slowestMs, isNull);
      expect(summary.isAllFalseStarts, isFalse);
    });

    test('isNewPersonalBest evaluates lowest ms properly', () {
      expect(
        ReactionTestEngine.isNewPersonalBest(newMs: 250, currentBestMs: null),
        isTrue,
      );
      expect(
        ReactionTestEngine.isNewPersonalBest(newMs: 190, currentBestMs: 200),
        isTrue,
      );
      expect(
        ReactionTestEngine.isNewPersonalBest(newMs: 210, currentBestMs: 200),
        isFalse,
      );
      expect(
        ReactionTestEngine.isNewPersonalBest(newMs: 200, currentBestMs: 200),
        isFalse,
      );
    });

    test('isNewBestAverage evaluates lowest average properly', () {
      expect(
        ReactionTestEngine.isNewBestAverage(
          newAvg: null,
          currentBestAvg: 200.0,
        ),
        isFalse,
      );
      expect(
        ReactionTestEngine.isNewBestAverage(
          newAvg: 220.0,
          currentBestAvg: null,
        ),
        isTrue,
      );
      expect(
        ReactionTestEngine.isNewBestAverage(
          newAvg: 195.5,
          currentBestAvg: 200.0,
        ),
        isTrue,
      );
      expect(
        ReactionTestEngine.isNewBestAverage(
          newAvg: 205.0,
          currentBestAvg: 200.0,
        ),
        isFalse,
      );
    });

    test('formatMs and formatAverage format nicely', () {
      expect(ReactionTestEngine.formatMs(null), equals('—'));
      expect(ReactionTestEngine.formatMs(234), equals('234 ms'));

      expect(ReactionTestEngine.formatAverage(null), equals('—'));
      expect(ReactionTestEngine.formatAverage(234.567), equals('234.6 ms'));
    });

    test(
      'DefaultReactionTimerService generates delay within 2000-5000ms bounds',
      () {
        final service = DefaultReactionTimerService();
        for (int i = 0; i < 20; i++) {
          final delay = service.getRandomDelay();
          expect(delay.inMilliseconds, greaterThanOrEqualTo(2000));
          expect(delay.inMilliseconds, lessThanOrEqualTo(5000));
        }
      },
    );
  });
}
