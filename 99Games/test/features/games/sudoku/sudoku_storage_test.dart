import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/sudoku/domain/sudoku_models.dart';
import 'package:mini_games_99/features/games/sudoku/domain/sudoku_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late SharedSudokuStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SharedSudokuStorage(prefs);
  });

  group('Sudoku Storage - Session Persistence', () {
    final testSession = SudokuSavedSession(
      clues: List.generate(81, (i) => i == 0 ? 5 : 0),
      solution: List.generate(81, (i) => (i % 9) + 1),
      board: List.generate(81, (i) => i == 0 ? 5 : (i == 1 ? 3 : 0)),
      notes: {
        2: {1, 4, 7},
        5: {8, 9},
      },
      difficulty: SudokuDifficulty.medium,
      mistakes: 1,
      elapsedSeconds: 145,
      status: SudokuGameStatus.inProgress,
      selectedCell: 2,
    );

    test(
      'saves and restores an unfinished puzzle session accurately',
      () async {
        await storage.saveSession(testSession);
        final restored = await storage.getSavedSession();

        expect(restored, isNotNull);
        expect(restored!.clues, equals(testSession.clues));
        expect(restored.solution, equals(testSession.solution));
        expect(restored.board, equals(testSession.board));
        expect(restored.notes[2], equals({1, 4, 7}));
        expect(restored.notes[5], equals({8, 9}));
        expect(restored.difficulty, equals(SudokuDifficulty.medium));
        expect(restored.mistakes, equals(1));
        expect(restored.elapsedSeconds, equals(145));
        expect(restored.status, equals(SudokuGameStatus.inProgress));
        expect(restored.selectedCell, equals(2));
      },
    );

    test('clearing saved session removes it from storage', () async {
      await storage.saveSession(testSession);
      await storage.clearSavedSession();

      final restored = await storage.getSavedSession();
      expect(restored, isNull);
    });

    test(
      'gracefully handles missing or corrupted saved session JSON',
      () async {
        // Empty
        expect(await storage.getSavedSession(), isNull);

        // Corrupted JSON
        await prefs.setString('sudoku_saved_session_v1', '{"invalid_json: 123');
        final corrupted = await storage.getSavedSession();
        expect(corrupted, isNull);

        // Verify corrupted key was cleaned up
        expect(prefs.containsKey('sudoku_saved_session_v1'), isFalse);
      },
    );
  });

  group('Sudoku Storage - Statistics', () {
    test('records game wins, losses, and best completion time', () async {
      // Initial stats are empty
      var stats = await storage.getStats(SudokuDifficulty.easy);
      expect(stats.gamesCompleted, equals(0));
      expect(stats.gamesWon, equals(0));
      expect(stats.gamesLost, equals(0));
      expect(stats.bestTimeSeconds, isNull);

      // 1. Record Win with time 180s
      await storage.recordGameResult(
        difficulty: SudokuDifficulty.easy,
        won: true,
        timeInSeconds: 180,
      );

      stats = await storage.getStats(SudokuDifficulty.easy);
      expect(stats.gamesCompleted, equals(1));
      expect(stats.gamesWon, equals(1));
      expect(stats.gamesLost, equals(0));
      expect(stats.bestTimeSeconds, equals(180));

      // 2. Record Loss (3 mistakes)
      await storage.recordGameResult(
        difficulty: SudokuDifficulty.easy,
        won: false,
      );

      stats = await storage.getStats(SudokuDifficulty.easy);
      expect(stats.gamesCompleted, equals(2));
      expect(stats.gamesWon, equals(1));
      expect(stats.gamesLost, equals(1));
      expect(stats.bestTimeSeconds, equals(180)); // Best time unchanged

      // 3. Record Faster Win with time 120s (new best)
      await storage.recordGameResult(
        difficulty: SudokuDifficulty.easy,
        won: true,
        timeInSeconds: 120,
      );

      stats = await storage.getStats(SudokuDifficulty.easy);
      expect(stats.gamesCompleted, equals(3));
      expect(stats.gamesWon, equals(2));
      expect(stats.bestTimeSeconds, equals(120)); // New best time!
    });

    test('resetStats clears statistics for given difficulty', () async {
      await storage.recordGameResult(
        difficulty: SudokuDifficulty.hard,
        won: true,
        timeInSeconds: 300,
      );

      await storage.resetStats(SudokuDifficulty.hard);
      final stats = await storage.getStats(SudokuDifficulty.hard);
      expect(stats.gamesCompleted, equals(0));
      expect(stats.gamesWon, equals(0));
      expect(stats.bestTimeSeconds, isNull);
    });
  });
}
