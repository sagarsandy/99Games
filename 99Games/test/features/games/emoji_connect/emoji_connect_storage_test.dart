import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_models.dart';
import 'package:mini_games_99/features/games/emoji_connect/domain/emoji_connect_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedEmojiConnectStorage Tests', () {
    late SharedPreferences prefs;
    late SharedEmojiConnectStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = SharedEmojiConnectStorage(prefs);
    });

    test('Selected difficulty defaults to easy and persists changes', () async {
      expect(
        await storage.getSelectedDifficulty(),
        equals(EmojiConnectDifficulty.easy),
      );

      await storage.setSelectedDifficulty(EmojiConnectDifficulty.hard);
      expect(
        await storage.getSelectedDifficulty(),
        equals(EmojiConnectDifficulty.hard),
      );
    });

    test('Current level defaults to 1 and can be updated', () async {
      expect(
        await storage.getCurrentLevel(EmojiConnectDifficulty.easy),
        equals(1),
      );

      await storage.setCurrentLevel(EmojiConnectDifficulty.easy, 4);
      expect(
        await storage.getCurrentLevel(EmojiConnectDifficulty.easy),
        equals(4),
      );
    });

    test(
      'Unlocked level defaults to 1 and does not regress to a lower value',
      () async {
        expect(
          await storage.getUnlockedLevel(EmojiConnectDifficulty.easy),
          equals(1),
        );

        await storage.setUnlockedLevel(EmojiConnectDifficulty.easy, 5);
        expect(
          await storage.getUnlockedLevel(EmojiConnectDifficulty.easy),
          equals(5),
        );

        // Attempt regression
        await storage.setUnlockedLevel(EmojiConnectDifficulty.easy, 3);
        expect(
          await storage.getUnlockedLevel(EmojiConnectDifficulty.easy),
          equals(5),
        );
      },
    );

    test('markLevelCompleted unlocks next level and saves best time', () async {
      await storage.markLevelCompleted(
        EmojiConnectDifficulty.easy,
        1,
        timeSeconds: 45,
      );

      final completed = await storage.getCompletedLevels(
        EmojiConnectDifficulty.easy,
      );
      expect(completed.contains(1), isTrue);

      final unlocked = await storage.getUnlockedLevel(
        EmojiConnectDifficulty.easy,
      );
      expect(unlocked, equals(2));

      final bestTime = await storage.getBestTime(
        EmojiConnectDifficulty.easy,
        1,
      );
      expect(bestTime, equals(45));

      // Faster completion updates best time
      await storage.markLevelCompleted(
        EmojiConnectDifficulty.easy,
        1,
        timeSeconds: 30,
      );
      expect(
        await storage.getBestTime(EmojiConnectDifficulty.easy, 1),
        equals(30),
      );

      // Slower completion does not overwrite best time
      await storage.markLevelCompleted(
        EmojiConnectDifficulty.easy,
        1,
        timeSeconds: 50,
      );
      expect(
        await storage.getBestTime(EmojiConnectDifficulty.easy, 1),
        equals(30),
      );
    });

    test('Saved session can be stored and retrieved accurately', () async {
      const session = EmojiConnectSavedSession(
        difficulty: EmojiConnectDifficulty.medium,
        levelId: 3,
        paths: {
          'pair_1': [GridPosition(0, 0), GridPosition(0, 1)],
        },
        elapsedSeconds: 25,
        movesCount: 2,
      );

      await storage.saveSession(session);
      final retrieved = await storage.getSavedSession();

      expect(retrieved, isNotNull);
      expect(retrieved!.difficulty, equals(EmojiConnectDifficulty.medium));
      expect(retrieved.levelId, equals(3));
      expect(
        retrieved.paths['pair_1'],
        equals([const GridPosition(0, 0), const GridPosition(0, 1)]),
      );
      expect(retrieved.elapsedSeconds, equals(25));
      expect(retrieved.movesCount, equals(2));

      await storage.clearSavedSession();
      expect(await storage.getSavedSession(), isNull);
    });

    test(
      'Corrupted saved session safely returns null and clears corrupted key',
      () async {
        await prefs.setString(
          'emoji_connect_v1_saved_session',
          '{invalid_json',
        );
        final result = await storage.getSavedSession();
        expect(result, isNull);
        expect(prefs.containsKey('emoji_connect_v1_saved_session'), isFalse);
      },
    );

    test('resetAll clears all stored data', () async {
      await storage.setSelectedDifficulty(EmojiConnectDifficulty.hard);
      await storage.setCurrentLevel(EmojiConnectDifficulty.hard, 5);
      await storage.markLevelCompleted(
        EmojiConnectDifficulty.hard,
        5,
        timeSeconds: 60,
      );

      await storage.resetAll();

      expect(
        await storage.getSelectedDifficulty(),
        equals(EmojiConnectDifficulty.easy),
      );
      expect(
        await storage.getCurrentLevel(EmojiConnectDifficulty.hard),
        equals(1),
      );
      expect(
        await storage.getUnlockedLevel(EmojiConnectDifficulty.hard),
        equals(1),
      );
      expect(
        await storage.getCompletedLevels(EmojiConnectDifficulty.hard),
        isEmpty,
      );
    });
  });
}
