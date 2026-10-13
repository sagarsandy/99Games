import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/core/storage/game_stats_storage.dart';
import 'package:mini_games_99/features/games/number_slide/cubit/number_slide_cubit.dart';
import 'package:mini_games_99/features/games/number_slide/domain/number_slide_engine.dart';

class FakeNumberSlideStorage implements GameStatsStorage {
  NumberSlideBestResult? bestResult;
  bool shouldThrowOnSave = false;
  int recordCalls = 0;

  @override
  Future<NumberSlideBestResult?> getNumberSlideBestResult() async => bestResult;

  @override
  Future<bool> recordNumberSlideResult(NumberSlideBestResult candidate) async {
    recordCalls++;
    if (shouldThrowOnSave) {
      throw Exception('Disk failure');
    }
    if (bestResult == null || bestResult!.isBeatenBy(candidate)) {
      bestResult = candidate;
      return true;
    }
    return false;
  }

  @override
  Future<void> resetNumberSlideBestResult() async {
    bestResult = null;
  }

  int blockPuzzleBest = 0;

  @override
  Future<int> getBlockPuzzleBestScore() async => blockPuzzleBest;

  @override
  Future<bool> recordBlockPuzzleScore(int score) async {
    if (score > blockPuzzleBest) {
      blockPuzzleBest = score;
      return true;
    }
    return false;
  }

  @override
  Future<void> resetBlockPuzzleBestScore() async {
    blockPuzzleBest = 0;
  }

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
  late FakeNumberSlideStorage fakeStorage;
  late NumberSlideEngine engine;

  // Board 1 move away from solved:
  // Tile 15 at index 15, empty 0 at index 14
  // Solved by sliding tile 15 (index 15) into index 14
  final oneMoveAwayBoard = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    0,
    15,
  ];

  setUp(() {
    fakeStorage = FakeNumberSlideStorage();
    engine = NumberSlideEngine();
  });

  NumberSlideCubit createCubit({List<int>? board}) {
    return NumberSlideCubit(
      statsStorage: fakeStorage,
      engine: engine,
      initialBoard: board ?? oneMoveAwayBoard,
    );
  }

  group('NumberSlideCubit - Initial State', () {
    test('initial state has 16 tiles, 0 moves, and timer stopped', () {
      final cubit = createCubit();

      expect(cubit.state.board.length, 16);
      expect(cubit.state.emptyIndex, 14);
      expect(cubit.state.moves, 0);
      expect(cubit.state.elapsedSeconds, 0);
      expect(cubit.state.hasStarted, isFalse);
      expect(cubit.state.isSolved, isFalse);

      cubit.close();
    });

    test('loads persisted best result on initialization', () async {
      fakeStorage.bestResult = const NumberSlideBestResult(
        moves: 45,
        timeInSeconds: 30,
      );
      final cubit = createCubit();

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.bestResult, equals(fakeStorage.bestResult));
      cubit.close();
    });
  });

  group('NumberSlideCubit - Moves and State Updates', () {
    test(
      'valid move updates board, increments moves, and starts timer',
      () async {
        final cubit = createCubit();

        // Index 10 is directly above empty index 14 (row 2 col 2 vs row 3 col 2)
        expect(cubit.state.hasStarted, isFalse);
        await cubit.makeMove(10);

        expect(cubit.state.hasStarted, isTrue);
        expect(cubit.state.moves, 1);
        expect(cubit.state.board[14], 11); // Tile 11 moved down to 14
        expect(cubit.state.board[10], 0); // Empty slot now at 10
        expect(cubit.state.emptyIndex, 10);

        cubit.close();
      },
    );

    test(
      'invalid move does not modify board, move count, or start status',
      () async {
        final cubit = createCubit();
        final boardBefore = List<int>.from(cubit.state.board);

        // Tile at index 0 is not adjacent to index 14
        await cubit.makeMove(0);

        expect(cubit.state.board, equals(boardBefore));
        expect(cubit.state.moves, 0);
        expect(cubit.state.hasStarted, isFalse);

        cubit.close();
      },
    );
  });

  group('NumberSlideCubit - Victory Detection and Score Persistence', () {
    test(
      'solving the puzzle stops timer, emits isSolved, and records best result',
      () async {
        final cubit = createCubit(board: oneMoveAwayBoard);

        // Move tile 15 from index 15 to index 14 -> Solved!
        await cubit.makeMove(15);

        expect(cubit.state.isSolved, isTrue);
        expect(cubit.state.moves, 1);
        expect(fakeStorage.recordCalls, 1);
        expect(fakeStorage.bestResult, isNotNull);
        expect(fakeStorage.bestResult!.moves, 1);

        // Subsequent moves are rejected
        await cubit.makeMove(14);
        expect(cubit.state.moves, 1);

        cubit.close();
      },
    );

    test(
      'storage failure is handled gracefully without corrupting game state',
      () async {
        fakeStorage.shouldThrowOnSave = true;
        final cubit = createCubit(board: oneMoveAwayBoard);

        await cubit.makeMove(15);

        expect(cubit.state.isSolved, isTrue);
        expect(cubit.state.moves, 1);

        cubit.close();
      },
    );
  });

  group('NumberSlideCubit - New Game', () {
    test(
      'startNewGame resets move count, elapsed time, and starts fresh solvable board',
      () async {
        final cubit = createCubit(board: oneMoveAwayBoard);

        await cubit.makeMove(10);
        expect(cubit.state.moves, 1);
        expect(cubit.state.hasStarted, isTrue);

        cubit.startNewGame();

        expect(cubit.state.moves, 0);
        expect(cubit.state.elapsedSeconds, 0);
        expect(cubit.state.hasStarted, isFalse);
        expect(cubit.state.isSolved, isFalse);
        expect(engine.isSolvable(cubit.state.board), isTrue);

        cubit.close();
      },
    );
  });

  group('NumberSlideCubit - Timer Lifecycle', () {
    test(
      'pauseTimer and resumeTimer pause and restart periodic timer',
      () async {
        final cubit = createCubit();

        await cubit.makeMove(10);
        expect(cubit.state.hasStarted, isTrue);

        cubit.pauseTimer();
        // Emulating paused state
        cubit.resumeTimer();

        cubit.close();
      },
    );
  });
}
