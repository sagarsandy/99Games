import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/core/storage/game_stats_storage.dart';
import 'package:mini_games_99/features/games/word_search/cubit/word_search_cubit.dart';
import 'package:mini_games_99/features/games/word_search/domain/word_search_dictionary.dart';
import 'package:mini_games_99/features/games/word_search/domain/word_search_engine.dart';
import 'package:mini_games_99/features/games/word_search/domain/word_search_models.dart';

class FakeWordSearchStatsStorage implements GameStatsStorage {
  final Map<String, int> _bestTimes = {};
  final Map<String, int> _completed = {};
  bool shouldThrow = false;
  int recordCalls = 0;

  @override
  Future<int?> getWordSearchBestTime(String difficulty) async {
    return _bestTimes[difficulty];
  }

  @override
  Future<bool> recordWordSearchCompletion({
    required String difficulty,
    required int timeInSeconds,
  }) async {
    recordCalls++;
    if (shouldThrow) throw Exception('Disk failure');

    _completed[difficulty] = (_completed[difficulty] ?? 0) + 1;

    final currentBest = _bestTimes[difficulty];
    if (currentBest == null || timeInSeconds < currentBest) {
      _bestTimes[difficulty] = timeInSeconds;
      return true;
    }
    return false;
  }

  @override
  Future<int> getWordSearchPuzzlesCompleted(String difficulty) async {
    return _completed[difficulty] ?? 0;
  }

  @override
  Future<void> resetWordSearchStats(String difficulty) async {
    _bestTimes.remove(difficulty);
    _completed.remove(difficulty);
  }

  @override
  Future<int> getBlockPuzzleBestScore() async => 0;

  @override
  Future<bool> recordBlockPuzzleScore(int score) async => false;

  @override
  Future<void> resetBlockPuzzleBestScore() async {}

  @override
  Future<NumberSlideBestResult?> getNumberSlideBestResult() async => null;

  @override
  Future<bool> recordNumberSlideResult(NumberSlideBestResult candidate) async =>
      false;

  @override
  Future<void> resetNumberSlideBestResult() async {}

  @override
  Future<GameStats> getStats({
    required String gameId,
    required String subKey,
  }) async => GameStats.empty;

  @override
  Future<void> saveStats({
    required String gameId,
    required String subKey,
    required GameStats stats,
  }) async {}

  @override
  Future<void> resetStats({
    required String gameId,
    required String subKey,
  }) async {}
}

void main() {
  late FakeWordSearchStatsStorage fakeStorage;
  late WordSearchEngine engine;
  late WordSearchDictionary dictionary;

  // A controlled deterministic 4x4 test puzzle with target words: ['CAT', 'DOG']
  final testPuzzle = WordSearchPuzzle(
    grid: [
      ['C', 'A', 'T', 'X'],
      ['D', 'O', 'G', 'Y'],
      ['A', 'B', 'C', 'D'],
      ['E', 'F', 'G', 'H'],
    ],
    targetWords: ['CAT', 'DOG'],
    placedWords: [
      const PlacedWord(
        word: 'CAT',
        start: GridCoordinate(0, 0),
        end: GridCoordinate(0, 2),
        direction: WordDirection.horizontalRight,
        coordinates: [
          GridCoordinate(0, 0),
          GridCoordinate(0, 1),
          GridCoordinate(0, 2),
        ],
      ),
      const PlacedWord(
        word: 'DOG',
        start: GridCoordinate(1, 0),
        end: GridCoordinate(1, 2),
        direction: WordDirection.horizontalRight,
        coordinates: [
          GridCoordinate(1, 0),
          GridCoordinate(1, 1),
          GridCoordinate(1, 2),
        ],
      ),
    ],
    difficulty: WordSearchDifficulty.easy,
  );

  setUp(() {
    fakeStorage = FakeWordSearchStatsStorage();
    dictionary = WordSearchDictionary();
    engine = WordSearchEngine(dictionary: dictionary);
  });

  WordSearchCubit createCubit({
    WordSearchPuzzle? initialPuzzle,
    WordSearchDifficulty initialDifficulty = WordSearchDifficulty.easy,
  }) {
    return WordSearchCubit(
      statsStorage: fakeStorage,
      engine: engine,
      dictionary: dictionary,
      initialPuzzle: initialPuzzle ?? testPuzzle,
      initialDifficulty: initialDifficulty,
      random: Random(42),
    );
  }

  group('WordSearchCubit - Initialization', () {
    test(
      'initial state has valid puzzle, 0 elapsed seconds, and timer stopped',
      () {
        final cubit = createCubit();

        expect(cubit.state.difficulty, WordSearchDifficulty.easy);
        expect(cubit.state.puzzle, equals(testPuzzle));
        expect(cubit.state.foundCount, 0);
        expect(cubit.state.totalWords, 2);
        expect(cubit.state.progress, 0.0);
        expect(cubit.state.elapsedSeconds, 0);
        expect(cubit.state.hasStarted, isFalse);
        expect(cubit.state.isCompleted, isFalse);

        cubit.close();
      },
    );

    test('loads persisted records on initialization', () async {
      await fakeStorage.recordWordSearchCompletion(
        difficulty: WordSearchDifficulty.easy.name,
        timeInSeconds: 45,
      );

      final cubit = createCubit();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.bestTime, 45);
      expect(cubit.state.completedCount, 1);

      cubit.close();
    });
  });

  group('WordSearchCubit - Selection and Matching', () {
    test('startSelection starts timer and tracks initial coordinate', () {
      final cubit = createCubit();

      expect(cubit.state.hasStarted, isFalse);
      cubit.startSelection(const GridCoordinate(0, 0));

      expect(cubit.state.hasStarted, isTrue);
      expect(cubit.state.selectionStart, equals(const GridCoordinate(0, 0)));
      expect(cubit.state.selectionEnd, equals(const GridCoordinate(0, 0)));
      expect(
        cubit.state.currentSelection,
        equals([const GridCoordinate(0, 0)]),
      );

      cubit.close();
    });

    test('updateSelection updates end coordinate and line path', () {
      final cubit = createCubit();
      cubit.startSelection(const GridCoordinate(0, 0));
      cubit.updateSelection(const GridCoordinate(0, 2));

      expect(cubit.state.selectionEnd, equals(const GridCoordinate(0, 2)));
      expect(cubit.state.currentSelection.length, 3);
      expect(
        cubit.state.currentSelection,
        equals([
          const GridCoordinate(0, 0),
          const GridCoordinate(0, 1),
          const GridCoordinate(0, 2),
        ]),
      );

      cubit.close();
    });

    test(
      'endSelection on valid target word adds to foundWords and updates progress',
      () async {
        final cubit = createCubit();
        cubit.startSelection(const GridCoordinate(0, 0));
        cubit.updateSelection(const GridCoordinate(0, 2));
        await cubit.endSelection();

        expect(cubit.state.foundCount, 1);
        expect(cubit.state.isWordFound('CAT'), isTrue);
        expect(cubit.state.progress, 0.5);
        expect(cubit.state.currentSelection, isEmpty);
        expect(cubit.state.isCompleted, isFalse);

        cubit.close();
      },
    );

    test('reverse selection (right-to-left) matches target word', () async {
      final cubit = createCubit();
      // Select T (0, 2) -> C (0, 0)
      cubit.startSelection(const GridCoordinate(0, 2));
      cubit.updateSelection(const GridCoordinate(0, 0));
      await cubit.endSelection();

      expect(cubit.state.foundCount, 1);
      expect(cubit.state.isWordFound('CAT'), isTrue);

      cubit.close();
    });

    test(
      'invalid word selection clears selection without increasing progress',
      () async {
        final cubit = createCubit();
        // Select random letters X(0, 3) -> Y(1, 3)
        cubit.startSelection(const GridCoordinate(0, 3));
        cubit.updateSelection(const GridCoordinate(1, 3));
        await cubit.endSelection();

        expect(cubit.state.foundCount, 0);
        expect(cubit.state.currentSelection, isEmpty);

        cubit.close();
      },
    );

    test(
      'selecting already found word does not increment progress or duplicate',
      () async {
        final cubit = createCubit();

        // Find CAT
        cubit.startSelection(const GridCoordinate(0, 0));
        cubit.updateSelection(const GridCoordinate(0, 2));
        await cubit.endSelection();
        expect(cubit.state.foundCount, 1);

        // Select CAT again
        cubit.startSelection(const GridCoordinate(0, 0));
        cubit.updateSelection(const GridCoordinate(0, 2));
        await cubit.endSelection();
        expect(cubit.state.foundCount, 1);

        cubit.close();
      },
    );

    test('accessible tap-to-select cellTapped works correctly', () async {
      final cubit = createCubit();

      // Tap start cell (0, 0)
      await cubit.cellTapped(const GridCoordinate(0, 0));
      expect(cubit.state.selectionStart, equals(const GridCoordinate(0, 0)));

      // Tap end cell (0, 2)
      await cubit.cellTapped(const GridCoordinate(0, 2));
      expect(cubit.state.foundCount, 1);
      expect(cubit.state.isWordFound('CAT'), isTrue);

      cubit.close();
    });
  });

  group('WordSearchCubit - Completion and Persistence', () {
    test(
      'finding all words triggers completion and persists best result',
      () async {
        final cubit = createCubit();

        // 1. Find CAT
        cubit.startSelection(const GridCoordinate(0, 0));
        cubit.updateSelection(const GridCoordinate(0, 2));
        await cubit.endSelection();
        expect(cubit.state.isCompleted, isFalse);

        // 2. Find DOG
        cubit.startSelection(const GridCoordinate(1, 0));
        cubit.updateSelection(const GridCoordinate(1, 2));
        await cubit.endSelection();

        expect(cubit.state.isCompleted, isTrue);
        expect(cubit.state.foundCount, 2);
        expect(cubit.state.progress, 1.0);
        expect(fakeStorage.recordCalls, 1);
        expect(cubit.state.completedCount, 1);

        cubit.close();
      },
    );

    test(
      'storage failure is handled gracefully without crashing state',
      () async {
        fakeStorage.shouldThrow = true;
        final cubit = createCubit();

        // Find CAT
        cubit.startSelection(const GridCoordinate(0, 0));
        cubit.updateSelection(const GridCoordinate(0, 2));
        await cubit.endSelection();

        // Find DOG
        cubit.startSelection(const GridCoordinate(1, 0));
        cubit.updateSelection(const GridCoordinate(1, 2));
        await cubit.endSelection();

        expect(cubit.state.isCompleted, isTrue);
        cubit.close();
      },
    );
  });

  group('WordSearchCubit - New Puzzle and Difficulty Change', () {
    test('startNewPuzzle resets selections, found words, and timer', () async {
      final cubit = createCubit();

      cubit.startSelection(const GridCoordinate(0, 0));
      cubit.updateSelection(const GridCoordinate(0, 2));
      await cubit.endSelection();
      expect(cubit.state.foundCount, 1);

      cubit.startNewPuzzle();

      expect(cubit.state.foundCount, 0);
      expect(cubit.state.hasStarted, isFalse);
      expect(cubit.state.elapsedSeconds, 0);
      expect(cubit.state.isCompleted, isFalse);

      cubit.close();
    });

    test(
      'setDifficulty regenerates puzzle with matching grid dimensions',
      () async {
        final cubit = createCubit();

        await cubit.setDifficulty(WordSearchDifficulty.medium);

        expect(cubit.state.difficulty, WordSearchDifficulty.medium);
        expect(cubit.state.puzzle.size, 10);
        expect(cubit.state.foundCount, 0);
        expect(cubit.state.hasStarted, isFalse);

        await cubit.setDifficulty(WordSearchDifficulty.hard);
        expect(cubit.state.difficulty, WordSearchDifficulty.hard);
        expect(cubit.state.puzzle.size, 12);

        cubit.close();
      },
    );
  });

  group('WordSearchCubit - Lifecycle Pausing and Resuming', () {
    test('pauseTimer and resumeTimer execute cleanly', () {
      final cubit = createCubit();

      cubit.startSelection(const GridCoordinate(0, 0));
      expect(cubit.state.hasStarted, isTrue);

      cubit.pauseTimer();
      cubit.resumeTimer();

      cubit.close();
    });
  });
}
