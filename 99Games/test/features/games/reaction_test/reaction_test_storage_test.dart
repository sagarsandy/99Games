import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/reaction_test/domain/reaction_test_models.dart';
import 'package:mini_games_99/features/games/reaction_test/domain/reaction_test_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Reaction Test - Storage Tests', () {
    late SharedPreferences prefs;
    late SharedReactionTestStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = SharedReactionTestStorage(prefs);
    });

    test('initial stats are zero or null', () async {
      final stats = await storage.getStats();
      expect(stats.totalGamesPlayed, equals(0));
      expect(stats.totalValidReactions, equals(0));
      expect(stats.totalFalseStarts, equals(0));
      expect(stats.bestSingleMs, isNull);
      expect(stats.bestSessionAverageMs, isNull);
      expect(stats.lastSessionOutcomes, isNull);
    });

    test('recordCompletedSession updates stats correctly', () async {
      const outcomes = [
        RoundOutcome(roundNumber: 1, isFalseStart: false, reactionTimeMs: 220),
        RoundOutcome(roundNumber: 2, isFalseStart: false, reactionTimeMs: 250),
        RoundOutcome(roundNumber: 3, isFalseStart: true, reactionTimeMs: null),
        RoundOutcome(roundNumber: 4, isFalseStart: false, reactionTimeMs: 180),
        RoundOutcome(roundNumber: 5, isFalseStart: false, reactionTimeMs: 230),
      ];

      await storage.recordCompletedSession(outcomes);

      final stats = await storage.getStats();
      expect(stats.totalGamesPlayed, equals(1));
      expect(stats.totalValidReactions, equals(4));
      expect(stats.totalFalseStarts, equals(1));
      expect(stats.bestSingleMs, equals(180));
      // Average of [220, 250, 180, 230] = 880 / 4 = 220.0
      expect(stats.bestSessionAverageMs, equals(220.0));
      expect(stats.lastSessionOutcomes?.length, equals(5));
      expect(stats.lastSessionOutcomes?[3].reactionTimeMs, equals(180));
    });

    test('multiple sessions update personal best only when improved', () async {
      // Session 1: Best single 200, avg 210
      await storage.recordCompletedSession(const [
        RoundOutcome(roundNumber: 1, isFalseStart: false, reactionTimeMs: 200),
        RoundOutcome(roundNumber: 2, isFalseStart: false, reactionTimeMs: 220),
      ]);

      var stats = await storage.getStats();
      expect(stats.totalGamesPlayed, equals(1));
      expect(stats.bestSingleMs, equals(200));
      expect(stats.bestSessionAverageMs, equals(210.0));

      // Session 2: Slower times: 250, 260
      await storage.recordCompletedSession(const [
        RoundOutcome(roundNumber: 1, isFalseStart: false, reactionTimeMs: 250),
        RoundOutcome(roundNumber: 2, isFalseStart: false, reactionTimeMs: 260),
      ]);

      stats = await storage.getStats();
      expect(stats.totalGamesPlayed, equals(2));
      expect(stats.bestSingleMs, equals(200)); // still 200
      expect(stats.bestSessionAverageMs, equals(210.0)); // still 210

      // Session 3: Faster times: 170, 190 (avg 180)
      await storage.recordCompletedSession(const [
        RoundOutcome(roundNumber: 1, isFalseStart: false, reactionTimeMs: 170),
        RoundOutcome(roundNumber: 2, isFalseStart: false, reactionTimeMs: 190),
      ]);

      stats = await storage.getStats();
      expect(stats.totalGamesPlayed, equals(3));
      expect(stats.bestSingleMs, equals(170)); // improved!
      expect(stats.bestSessionAverageMs, equals(180.0)); // improved!
    });

    test('resetStats cleans all stored keys', () async {
      await storage.recordCompletedSession(const [
        RoundOutcome(roundNumber: 1, isFalseStart: false, reactionTimeMs: 200),
      ]);
      expect((await storage.getStats()).totalGamesPlayed, equals(1));

      await storage.resetStats();
      final stats = await storage.getStats();
      expect(stats.totalGamesPlayed, equals(0));
      expect(stats.bestSingleMs, isNull);
      expect(stats.lastSessionOutcomes, isNull);
    });

    test('corrupted stored session JSON is handled safely', () async {
      await prefs.setString('reaction_test_v1_last_session', '{"corrupt');
      final stats = await storage.getStats();
      expect(stats.lastSessionOutcomes, isNull);
    });
  });
}
