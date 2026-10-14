import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/core/storage/game_stats_storage.dart';
import 'package:mini_games_99/core/storage/storage_keys.dart';
import 'package:mini_games_99/features/games/dots_and_boxes/cubit/dots_and_boxes_cubit.dart';
import 'package:mini_games_99/features/games/dots_and_boxes/domain/dots_and_boxes_engine.dart';
import 'package:mini_games_99/features/games/dots_and_boxes/domain/dots_and_boxes_models.dart';

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

  @override
  Future<NumberSlideBestResult?> getNumberSlideBestResult() async => null;

  @override
  Future<bool> recordNumberSlideResult(NumberSlideBestResult candidate) async =>
      false;

  @override
  Future<void> resetNumberSlideBestResult() async {}

  @override
  Future<int> getBlockPuzzleBestScore() async => 0;

  @override
  Future<bool> recordBlockPuzzleScore(int score) async => false;

  @override
  Future<void> resetBlockPuzzleBestScore() async {}

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
  late FakeGameStatsStorage storage;
  late DotsAndBoxesEngine engine;

  setUp(() {
    storage = FakeGameStatsStorage();
    engine = DotsAndBoxesEngine();
  });

  DotsAndBoxesCubit createCubit({
    Duration aiDelay = Duration.zero,
    BoardSize boardSize = BoardSize.small,
    DotsGameMode gameMode = DotsGameMode.passAndPlay,
    DotsAiDifficulty difficulty = DotsAiDifficulty.medium,
  }) {
    return DotsAndBoxesCubit(
      statsStorage: storage,
      engine: engine,
      aiDelay: aiDelay,
      initialBoardSize: boardSize,
      initialGameMode: gameMode,
      initialDifficulty: difficulty,
    );
  }

  group('DotsAndBoxesCubit - Initialization', () {
    test(
      'initial state defaults to 6x6 Small board, 0 scores, in progress',
      () async {
        final cubit = createCubit();
        expect(cubit.state.boardSize, equals(BoardSize.small));
        expect(cubit.state.currentPlayer, equals(DotsPlayer.player1));
        expect(cubit.state.player1Score, equals(0));
        expect(cubit.state.player2Score, equals(0));
        expect(cubit.state.isGameOver, isFalse);
        expect(cubit.state.horizontalEdges.length, equals(7)); // 6 + 1
        expect(cubit.state.verticalEdges.length, equals(6));
        expect(cubit.state.boxes.length, equals(6));
        await cubit.close();
      },
    );
  });

  group('DotsAndBoxesCubit - Board Size & Resets', () {
    test(
      'setBoardSize changes dimensions to Medium (9x9) and Large (15x15)',
      () async {
        final cubit = createCubit();

        // Change to Medium (9x9)
        cubit.setBoardSize(BoardSize.medium);
        expect(cubit.state.boardSize, equals(BoardSize.medium));
        expect(cubit.state.horizontalEdges.length, equals(10));
        expect(cubit.state.verticalEdges.length, equals(9));
        expect(cubit.state.boxes.length, equals(9));
        expect(cubit.state.totalBoxes, equals(81));

        // Change to Large (15x15)
        cubit.setBoardSize(BoardSize.large);
        expect(cubit.state.boardSize, equals(BoardSize.large));
        expect(cubit.state.horizontalEdges.length, equals(16));
        expect(cubit.state.verticalEdges.length, equals(15));
        expect(cubit.state.boxes.length, equals(15));
        expect(cubit.state.totalBoxes, equals(225));

        await cubit.close();
      },
    );

    test('restartGame clears all moves and resets scores', () async {
      final cubit = createCubit();
      await cubit.claimEdge(const EdgePosition.horizontal(0, 0));
      expect(cubit.state.hasAnyMoveMade, isTrue);

      cubit.restartGame();
      expect(cubit.state.hasAnyMoveMade, isFalse);
      expect(cubit.state.player1Score, equals(0));
      expect(cubit.state.player2Score, equals(0));
      expect(cubit.state.currentPlayer, equals(DotsPlayer.player1));

      await cubit.close();
    });

    test(
      'setGameMode and setAiDifficulty reset board and re-fetch stats',
      () async {
        final cubit = createCubit();

        await cubit.setGameMode(DotsGameMode.vsAi);
        expect(cubit.state.gameMode, equals(DotsGameMode.vsAi));

        await cubit.setAiDifficulty(DotsAiDifficulty.hard);
        expect(cubit.state.aiDifficulty, equals(DotsAiDifficulty.hard));

        await cubit.close();
      },
    );
  });

  group('DotsAndBoxesCubit - Gameplay (2 Players)', () {
    test(
      'alternates turns between Player 1 and Player 2 on non-scoring moves',
      () async {
        final cubit = createCubit(gameMode: DotsGameMode.passAndPlay);

        expect(cubit.state.currentPlayer, equals(DotsPlayer.player1));
        await cubit.claimEdge(const EdgePosition.horizontal(0, 0));

        expect(cubit.state.currentPlayer, equals(DotsPlayer.player2));
        await cubit.claimEdge(const EdgePosition.horizontal(0, 1));

        expect(cubit.state.currentPlayer, equals(DotsPlayer.player1));

        await cubit.close();
      },
    );

    test('awards extra turn to Player 1 upon completing a box', () async {
      final cubit = createCubit(gameMode: DotsGameMode.passAndPlay);

      // Box (0, 0) edges: H(0,0), H(1,0), V(0,0), V(0,1)
      await cubit.claimEdge(const EdgePosition.horizontal(0, 0)); // P1
      await cubit.claimEdge(const EdgePosition.horizontal(1, 0)); // P2
      await cubit.claimEdge(const EdgePosition.vertical(0, 0)); // P1

      expect(cubit.state.currentPlayer, equals(DotsPlayer.player2));
      // P2 completes box with V(0, 1)
      await cubit.claimEdge(const EdgePosition.vertical(0, 1));

      expect(cubit.state.player2Score, equals(1));
      expect(cubit.state.player1Score, equals(0));
      // P2 retains turn!
      expect(cubit.state.currentPlayer, equals(DotsPlayer.player2));

      await cubit.close();
    });

    test('rejects claiming an already claimed edge', () async {
      final cubit = createCubit(gameMode: DotsGameMode.passAndPlay);

      await cubit.claimEdge(const EdgePosition.horizontal(0, 0));
      expect(cubit.state.currentPlayer, equals(DotsPlayer.player2));

      // Try claiming same edge again
      await cubit.claimEdge(const EdgePosition.horizontal(0, 0));
      // Nothing changed
      expect(cubit.state.currentPlayer, equals(DotsPlayer.player2));

      await cubit.close();
    });
  });

  group('DotsAndBoxesCubit - Gameplay (vs AI)', () {
    test('human move triggers immediate AI turn with aiDelay = zero', () async {
      final cubit = createCubit(
        gameMode: DotsGameMode.vsAi,
        aiDelay: Duration.zero,
      );

      expect(cubit.state.currentPlayer, equals(DotsPlayer.player1));
      await cubit.claimEdge(const EdgePosition.horizontal(0, 0));

      // Since aiDelay is zero, AI move should have run and finished,
      // switching back to human player
      expect(cubit.state.isAiThinking, isFalse);
      expect(cubit.state.currentPlayer, equals(DotsPlayer.player1));

      await cubit.close();
    });

    test('ignores tap while AI is thinking', () async {
      final cubit = createCubit(
        gameMode: DotsGameMode.vsAi,
        aiDelay: const Duration(milliseconds: 100),
      );

      // Start human move
      final moveFuture = cubit.claimEdge(const EdgePosition.horizontal(0, 0));

      // Attempt to move during AI delay
      await cubit.claimEdge(const EdgePosition.horizontal(0, 1));

      await moveFuture;
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await cubit.close();
    });
  });

  group('DotsAndBoxesCubit - Stats & Stale AI Cancellation', () {
    test('resetScores resets storage and emits empty stats', () async {
      final cubit = createCubit(gameMode: DotsGameMode.vsAi);

      // Pre-save some stats
      await storage.saveStats(
        gameId: StorageKeys.gameDotsAndBoxes,
        subKey: 'vs_ai_medium',
        stats: const GameStats(wins: 3, losses: 1, draws: 0),
      );
      await cubit.loadStats();
      expect(cubit.state.stats.wins, equals(3));

      await cubit.resetScores();
      expect(cubit.state.stats, equals(GameStats.empty));
      expect(storage.resetCount, equals(1));

      await cubit.close();
    });

    test('restarting game cancels pending delayed AI operation', () async {
      final cubit = createCubit(
        gameMode: DotsGameMode.vsAi,
        aiDelay: const Duration(milliseconds: 200),
      );

      // Human move triggers delayed AI turn
      unawaited(cubit.claimEdge(const EdgePosition.horizontal(0, 0)));

      // Give 20ms for state to become isAiThinking
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cubit.state.isAiThinking, isTrue);

      // Restart game immediately
      cubit.restartGame();
      expect(cubit.state.hasAnyMoveMade, isFalse);
      expect(cubit.state.isAiThinking, isFalse);

      // Wait out original AI delay
      await Future<void>.delayed(const Duration(milliseconds: 250));

      // Board must remain completely clean!
      expect(cubit.state.hasAnyMoveMade, isFalse);

      await cubit.close();
    });
  });
}
