import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/core/storage/game_stats_storage.dart';
import 'package:mini_games_99/features/games/tic_tac_toe/cubit/tic_tac_toe_cubit.dart';
import 'package:mini_games_99/features/games/tic_tac_toe/domain/tic_tac_toe_engine.dart';
import 'package:mini_games_99/features/games/tic_tac_toe/domain/tic_tac_toe_models.dart';

class FakeGameStatsStorage implements GameStatsStorage {
  final Map<String, GameStats> _data = {};
  int saveCount = 0;
  int resetCount = 0;

  @override
  Future<GameStats> getStats({
    required String gameId,
    required String subKey,
  }) async {
    return _data['${gameId}_$subKey'] ?? GameStats.empty;
  }

  @override
  Future<void> saveStats({
    required String gameId,
    required String subKey,
    required GameStats stats,
  }) async {
    saveCount++;
    _data['${gameId}_$subKey'] = stats;
  }

  @override
  Future<void> resetStats({
    required String gameId,
    required String subKey,
  }) async {
    resetCount++;
    _data.remove('${gameId}_$subKey');
  }

  NumberSlideBestResult? numberSlideBest;

  @override
  Future<NumberSlideBestResult?> getNumberSlideBestResult() async =>
      numberSlideBest;

  @override
  Future<bool> recordNumberSlideResult(NumberSlideBestResult candidate) async {
    if (numberSlideBest == null || numberSlideBest!.isBeatenBy(candidate)) {
      numberSlideBest = candidate;
      return true;
    }
    return false;
  }

  @override
  Future<void> resetNumberSlideBestResult() async {
    numberSlideBest = null;
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
  Future<int?> getWordSearchBestTime(String difficulty) async => null;

  @override
  Future<bool> recordWordSearchCompletion({
    required String difficulty,
    required int timeInSeconds,
  }) async => false;

  @override
  Future<int> getWordSearchPuzzlesCompleted(String difficulty) async => 0;

  @override
  Future<void> resetWordSearchStats(String difficulty) async {}
}

void main() {
  late FakeGameStatsStorage fakeStatsStorage;
  late TicTacToeEngine engine;

  setUp(() {
    fakeStatsStorage = FakeGameStatsStorage();
    engine = TicTacToeEngine();
  });

  TicTacToeCubit createCubit({Duration aiDelay = Duration.zero}) {
    return TicTacToeCubit(
      statsStorage: fakeStatsStorage,
      engine: engine,
      aiDelay: aiDelay,
    );
  }

  group('TicTacToeCubit - Initialization', () {
    test('initial state is clean and configured for vs AI', () {
      final cubit = createCubit();

      expect(cubit.state.board.length, 9);
      expect(cubit.state.board.every((cell) => cell.isNone), isTrue);
      expect(cubit.state.currentPlayer, PlayerSymbol.x);
      expect(cubit.state.status, GameStatus.inProgress);
      expect(cubit.state.gameMode, GameMode.vsAi);
      expect(cubit.state.aiDifficulty, AiDifficulty.medium);
      expect(cubit.state.winner, isNull);
      expect(cubit.state.winningIndices, isNull);
      expect(cubit.state.isAiThinking, isFalse);
      expect(cubit.state.stats, GameStats.empty);

      cubit.close();
    });
  });

  group('TicTacToeCubit - Pass and Play (2 Players)', () {
    test('alternates turns between Player X and Player O', () async {
      final cubit = createCubit();
      await cubit.setGameMode(GameMode.passAndPlay);

      // Move 1: X moves at index 0
      await cubit.makeMove(0);
      expect(cubit.state.board[0], PlayerSymbol.x);
      expect(cubit.state.currentPlayer, PlayerSymbol.o);

      // Move 2: O moves at index 1
      await cubit.makeMove(1);
      expect(cubit.state.board[1], PlayerSymbol.o);
      expect(cubit.state.currentPlayer, PlayerSymbol.x);

      cubit.close();
    });

    test(
      'invalid moves on occupied cells do not corrupt board or advance turn',
      () async {
        final cubit = createCubit();
        await cubit.setGameMode(GameMode.passAndPlay);

        await cubit.makeMove(0); // X plays at 0
        final boardAfterFirstMove = List<PlayerSymbol>.from(cubit.state.board);

        // Player O tries to play at occupied index 0
        await cubit.makeMove(0);

        expect(cubit.state.board, equals(boardAfterFirstMove));
        expect(
          cubit.state.currentPlayer,
          PlayerSymbol.o,
        ); // Turn did not switch

        cubit.close();
      },
    );

    test('win condition updates scores and persists to storage', () async {
      final cubit = createCubit();
      await cubit.setGameMode(GameMode.passAndPlay);

      // X: 0, O: 3
      // X: 1, O: 4
      // X: 2 -> X wins row 0!
      await cubit.makeMove(0); // X
      await cubit.makeMove(3); // O
      await cubit.makeMove(1); // X
      await cubit.makeMove(4); // O
      await cubit.makeMove(2); // X

      expect(cubit.state.status, GameStatus.win);
      expect(cubit.state.winner, PlayerSymbol.x);
      expect(cubit.state.winningIndices, equals([0, 1, 2]));
      expect(cubit.state.stats.wins, 1);
      expect(cubit.state.stats.losses, 0);
      expect(fakeStatsStorage.saveCount, 1);

      // Tapping after win does nothing
      await cubit.makeMove(5);
      expect(cubit.state.board[5], PlayerSymbol.none);

      cubit.close();
    });

    test(
      'draw condition updates draws score and persists to storage',
      () async {
        final cubit = createCubit();
        await cubit.setGameMode(GameMode.passAndPlay);

        // Verified sequence leading to draw:
        // X:0, O:4, X:8, O:1, X:7, O:6, X:2, O:5, X:3
        final moves = [0, 4, 8, 1, 7, 6, 2, 5, 3];
        for (final move in moves) {
          await cubit.makeMove(move);
        }

        expect(cubit.state.status, GameStatus.draw);
        expect(cubit.state.winner, isNull);
        expect(cubit.state.stats.draws, 1);
        expect(fakeStatsStorage.saveCount, 1);

        cubit.close();
      },
    );
  });

  group('TicTacToeCubit - vs AI Mode', () {
    test('AI plays automatically following human move with 0 delay', () async {
      final cubit = createCubit(aiDelay: Duration.zero);

      // Player X moves at cell 0
      await cubit.makeMove(0);

      // Since aiDelay is zero, AI move executes and state completes
      expect(cubit.state.board[0], PlayerSymbol.x);
      final aiMovesCount = cubit.state.board
          .where((cell) => cell == PlayerSymbol.o)
          .length;
      expect(aiMovesCount, 1);
      expect(cubit.state.currentPlayer, PlayerSymbol.x);
      expect(cubit.state.isAiThinking, isFalse);

      cubit.close();
    });

    test('changing AI difficulty resets board and reloads stats', () async {
      final cubit = createCubit();
      await cubit.makeMove(0);

      await cubit.setAiDifficulty(AiDifficulty.hard);

      expect(cubit.state.aiDifficulty, AiDifficulty.hard);
      expect(cubit.state.board.every((cell) => cell.isNone), isTrue);
      expect(cubit.state.currentPlayer, PlayerSymbol.x);
      expect(cubit.state.status, GameStatus.inProgress);

      cubit.close();
    });
  });

  group('TicTacToeCubit - Restart and Reset Scores', () {
    test('restartGame clears board and keeps scores', () async {
      final cubit = createCubit();
      await cubit.setGameMode(GameMode.passAndPlay);

      // Win game
      await cubit.makeMove(0); // X
      await cubit.makeMove(3); // O
      await cubit.makeMove(1); // X
      await cubit.makeMove(4); // O
      await cubit.makeMove(2); // X

      expect(cubit.state.stats.wins, 1);

      cubit.restartGame();

      expect(cubit.state.board.every((cell) => cell.isNone), isTrue);
      expect(cubit.state.status, GameStatus.inProgress);
      expect(cubit.state.winner, isNull);
      expect(cubit.state.winningIndices, isNull);
      expect(cubit.state.stats.wins, 1); // Preserves score

      cubit.close();
    });

    test('resetScores resets storage and emits zero scores', () async {
      final cubit = createCubit();
      await cubit.setGameMode(GameMode.passAndPlay);

      // Complete a match
      await cubit.makeMove(0); // X
      await cubit.makeMove(3); // O
      await cubit.makeMove(1); // X
      await cubit.makeMove(4); // O
      await cubit.makeMove(2); // X

      expect(cubit.state.stats.wins, 1);

      await cubit.resetScores();

      expect(cubit.state.stats, equals(GameStats.empty));
      expect(fakeStatsStorage.resetCount, 1);

      cubit.close();
    });
  });
}
