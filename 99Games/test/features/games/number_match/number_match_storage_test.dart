import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_games_99/features/games/number_match/domain/number_match_models.dart';
import 'package:mini_games_99/features/games/number_match/domain/number_match_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SharedNumberMatchStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SharedNumberMatchStorage(prefs);
  });

  group('NumberMatchStorage - Session Persistence', () {
    test('getSavedSession returns null when no session is stored', () async {
      final session = await storage.getSavedSession();
      expect(session, isNull);
    });

    test(
      'saveSession persists and getSavedSession restores session accurately',
      () async {
        final sampleTiles = [
          const NumberMatchTile(id: 0, value: 5, isCleared: true),
          const NumberMatchTile(id: 1, value: 5, isCleared: true),
          const NumberMatchTile(id: 2, value: 3, isCleared: false),
        ];

        final sampleAction = ClearPairAction(
          firstIndex: 0,
          firstTile: const NumberMatchTile(id: 0, value: 5),
          secondIndex: 1,
          secondTile: const NumberMatchTile(id: 1, value: 5),
          pointsAwarded: 10,
          rowBonusAwarded: 10,
        );

        final session = NumberMatchSavedSession(
          tiles: sampleTiles,
          score: 20,
          pairsCleared: 1,
          elapsedSeconds: 45,
          actionHistory: [sampleAction],
          status: NumberMatchGameStatus.inProgress,
        );

        await storage.saveSession(session);

        final restored = await storage.getSavedSession();
        expect(restored, isNotNull);
        expect(restored!.tiles.length, equals(3));
        expect(restored.tiles[0].isCleared, isTrue);
        expect(restored.tiles[2].isCleared, isFalse);
        expect(restored.score, equals(20));
        expect(restored.pairsCleared, equals(1));
        expect(restored.elapsedSeconds, equals(45));
        expect(restored.status, equals(NumberMatchGameStatus.inProgress));
        expect(restored.actionHistory.length, equals(1));
        expect(
          (restored.actionHistory[0] as ClearPairAction).pointsAwarded,
          equals(10),
        );
      },
    );

    test('clearSavedSession removes stored session', () async {
      final session = NumberMatchSavedSession(
        tiles: [const NumberMatchTile(id: 0, value: 1)],
        score: 10,
        pairsCleared: 1,
        elapsedSeconds: 5,
        actionHistory: const [],
        status: NumberMatchGameStatus.inProgress,
      );

      await storage.saveSession(session);
      expect(await storage.getSavedSession(), isNotNull);

      await storage.clearSavedSession();
      expect(await storage.getSavedSession(), isNull);
    });

    test('gracefully recovers from corrupted session data', () async {
      await prefs.setString(
        'number_match_saved_session_v1',
        '{"invalid_json: 123',
      );
      final session = await storage.getSavedSession();
      expect(session, isNull);
      // Corrupted session should be removed to prevent recurring errors
      expect(prefs.containsKey('number_match_saved_session_v1'), isFalse);
    });
  });

  group('NumberMatchStorage - Statistics', () {
    test('tracks games started, won, best score, and total pairs', () async {
      var stats = await storage.getStats();
      expect(stats.gamesStarted, equals(0));
      expect(stats.gamesWon, equals(0));
      expect(stats.bestScore, equals(0));
      expect(stats.totalPairsCleared, equals(0));

      await storage.recordGameStarted();
      stats = await storage.getStats();
      expect(stats.gamesStarted, equals(1));

      await storage.recordGameWon(score: 150, pairsCleared: 12);
      stats = await storage.getStats();
      expect(stats.gamesWon, equals(1));
      expect(stats.bestScore, equals(150));
      expect(stats.totalPairsCleared, equals(12));

      // Second win with lower score does not reduce best score
      await storage.recordGameWon(score: 120, pairsCleared: 8);
      stats = await storage.getStats();
      expect(stats.gamesWon, equals(2));
      expect(stats.bestScore, equals(150));
      expect(stats.totalPairsCleared, equals(20));

      // Third win with higher score updates best score
      await storage.recordGameWon(score: 220, pairsCleared: 15);
      stats = await storage.getStats();
      expect(stats.bestScore, equals(220));
      expect(stats.totalPairsCleared, equals(35));
    });

    test('resetStats clears all stored statistics', () async {
      await storage.recordGameStarted();
      await storage.recordGameWon(score: 100, pairsCleared: 5);

      await storage.resetStats();
      final stats = await storage.getStats();
      expect(stats.gamesStarted, equals(0));
      expect(stats.gamesWon, equals(0));
      expect(stats.bestScore, equals(0));
      expect(stats.totalPairsCleared, equals(0));
    });
  });
}
