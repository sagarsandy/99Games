import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/core/storage/game_stats_storage.dart';
import 'package:mini_games_99/features/games/block_puzzle/cubit/block_puzzle_cubit.dart';
import 'package:mini_games_99/features/games/block_puzzle/domain/block_puzzle_engine.dart';
import 'package:mini_games_99/features/games/block_puzzle/domain/block_puzzle_models.dart';

class FakeBlockPuzzleStatsStorage implements GameStatsStorage {
  int bestScore = 0;
  bool shouldThrow = false;
  int recordCalls = 0;

  @override
  Future<int> getBlockPuzzleBestScore() async => bestScore;

  @override
  Future<bool> recordBlockPuzzleScore(int score) async {
    recordCalls++;
    if (shouldThrow) throw Exception('Disk write failed');
    if (score > bestScore) {
      bestScore = score;
      return true;
    }
    return false;
  }

  @override
  Future<void> resetBlockPuzzleBestScore() async {
    bestScore = 0;
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

  @override
  Future<NumberSlideBestResult?> getNumberSlideBestResult() async => null;

  @override
  Future<bool> recordNumberSlideResult(NumberSlideBestResult candidate) async =>
      false;

  @override
  Future<void> resetNumberSlideBestResult() async {}
}

void main() {
  late FakeBlockPuzzleStatsStorage storage;
  late BlockPuzzleEngine engine;

  const dotShape = BlockShape(
    id: 'dot',
    name: 'Dot',
    cells: [BlockCoordinate(0, 0)],
    color: Color(0xFFF59E0B),
  );

  const line2HShape = BlockShape(
    id: 'line_2h',
    name: 'Line 2H',
    cells: [BlockCoordinate(0, 0), BlockCoordinate(0, 1)],
    color: Color(0xFF3B82F6),
  );

  setUp(() {
    storage = FakeBlockPuzzleStatsStorage();
    engine = BlockPuzzleEngine(random: Random(123));
  });

  group('BlockPuzzleCubit - Initialization', () {
    test(
      'initial state has empty board, 3 pieces, 0 score, and loads best score',
      () async {
        storage.bestScore = 150;
        final cubit = BlockPuzzleCubit(statsStorage: storage, engine: engine);

        expect(cubit.state.board.length, 100);
        expect(cubit.state.board.every((c) => c == 0), isTrue);
        expect(cubit.state.availablePieces.length, 3);
        expect(cubit.state.score, 0);
        expect(cubit.state.isGameOver, isFalse);
        expect(cubit.state.selectedPieceIndex, isNull);
        expect(cubit.state.hoverAnchor, isNull);

        // Allow async loadBestScore to settle
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.bestScore, 150);

        await cubit.close();
      },
    );
  });

  group('BlockPuzzleCubit - Piece Selection & Hover', () {
    test('piece selection toggles properly and ignores used pieces', () async {
      final initialPieces = [
        const BlockPiece(instanceId: 'p0', shape: dotShape),
        const BlockPiece(instanceId: 'p1', shape: line2HShape, isUsed: true),
        const BlockPiece(instanceId: 'p2', shape: dotShape),
      ];

      final cubit = BlockPuzzleCubit(
        statsStorage: storage,
        engine: engine,
        initialPieces: initialPieces,
      );

      // Select piece 0
      cubit.selectPiece(0);
      expect(cubit.state.selectedPieceIndex, 0);
      expect(cubit.state.selectedPiece?.instanceId, 'p0');

      // Toggling same piece deselects it
      cubit.selectPiece(0);
      expect(cubit.state.selectedPieceIndex, isNull);

      // Trying to select used piece 1 does nothing
      cubit.selectPiece(1);
      expect(cubit.state.selectedPieceIndex, isNull);

      // Selecting piece 2 works
      cubit.selectPiece(2);
      expect(cubit.state.selectedPieceIndex, 2);

      // unselectPiece clears selection
      cubit.unselectPiece();
      expect(cubit.state.selectedPieceIndex, isNull);

      await cubit.close();
    });

    test(
      'hover anchor is updated when piece is selected and cleared properly',
      () async {
        final initialPieces = [
          const BlockPiece(instanceId: 'p0', shape: dotShape),
        ];

        final cubit = BlockPuzzleCubit(
          statsStorage: storage,
          engine: engine,
          initialPieces: initialPieces,
        );

        // Hover without selection does nothing
        cubit.setHoverAnchor(2, 3);
        expect(cubit.state.hoverAnchor, isNull);

        // Select piece then set hover
        cubit.selectPiece(0);
        cubit.setHoverAnchor(2, 3);
        expect(cubit.state.hoverAnchor, const BlockCoordinate(2, 3));

        // Clear hover
        cubit.clearHoverAnchor();
        expect(cubit.state.hoverAnchor, isNull);

        await cubit.close();
      },
    );
  });

  group('BlockPuzzleCubit - Placement and Score Progression', () {
    test(
      'valid placement places piece, updates score and marks piece as used',
      () async {
        final initialPieces = [
          const BlockPiece(instanceId: 'p0', shape: dotShape),
          const BlockPiece(instanceId: 'p1', shape: line2HShape),
          const BlockPiece(instanceId: 'p2', shape: dotShape),
        ];

        final cubit = BlockPuzzleCubit(
          statsStorage: storage,
          engine: engine,
          initialPieces: initialPieces,
        );

        cubit.selectPiece(0);
        final success = await cubit.placePieceAt(1, 1);
        expect(success, isTrue);

        expect(cubit.state.board[1 * 10 + 1], dotShape.color.toARGB32());
        expect(cubit.state.score, 1);
        expect(cubit.state.bestScore, 1);
        expect(cubit.state.availablePieces[0].isUsed, isTrue);
        expect(cubit.state.selectedPieceIndex, isNull);

        await cubit.close();
      },
    );

    test(
      'invalid placement returns false and does not corrupt state',
      () async {
        final initialPieces = [
          const BlockPiece(instanceId: 'p0', shape: line2HShape),
        ];

        final cubit = BlockPuzzleCubit(
          statsStorage: storage,
          engine: engine,
          initialPieces: initialPieces,
        );

        cubit.selectPiece(0);
        // Col 9 with width 2 goes off board (cols 9 and 10)
        final success = await cubit.placePieceAt(0, 9);
        expect(success, isFalse);

        // Board remains empty
        expect(cubit.state.board.every((c) => c == 0), isTrue);
        expect(cubit.state.score, 0);
        expect(cubit.state.availablePieces[0].isUsed, isFalse);
        expect(cubit.state.selectedPieceIndex, 0); // selection preserved

        await cubit.close();
      },
    );

    test('all 3 pieces used triggers generation of fresh new pieces', () async {
      final initialPieces = [
        const BlockPiece(instanceId: 'p0', shape: dotShape),
        const BlockPiece(instanceId: 'p1', shape: dotShape),
        const BlockPiece(instanceId: 'p2', shape: dotShape),
      ];

      final cubit = BlockPuzzleCubit(
        statsStorage: storage,
        engine: engine,
        initialPieces: initialPieces,
      );

      // Place 1st piece
      cubit.selectPiece(0);
      await cubit.placePieceAt(0, 0);
      expect(cubit.state.availablePieces[0].isUsed, isTrue);
      expect(cubit.state.availablePieces[1].isUsed, isFalse);

      // Place 2nd piece
      cubit.selectPiece(1);
      await cubit.placePieceAt(0, 1);
      expect(cubit.state.availablePieces[1].isUsed, isTrue);

      // Place 3rd piece
      cubit.selectPiece(2);
      await cubit.placePieceAt(0, 2);

      // All 3 used -> New pieces generated!
      expect(cubit.state.availablePieces.length, 3);
      expect(cubit.state.availablePieces.every((p) => !p.isUsed), isTrue);
      expect(cubit.state.score, 3);

      await cubit.close();
    });

    test(
      'best score is persisted when beaten and survives storage failure gracefully',
      () async {
        storage.bestScore = 5;
        storage.shouldThrow = true; // Simulating disk failure

        final initialPieces = [
          const BlockPiece(instanceId: 'p0', shape: dotShape),
        ];

        final cubit = BlockPuzzleCubit(
          statsStorage: storage,
          engine: engine,
          initialPieces: initialPieces,
        );

        // Even if storage throws, placing piece succeeds and cubit survives
        cubit.selectPiece(0);
        final success = await cubit.placePieceAt(0, 0);
        expect(success, isTrue);
        expect(cubit.state.score, 1);

        await cubit.close();
      },
    );
  });

  group('BlockPuzzleCubit - Game Over and Reset', () {
    test('game over triggers when no remaining pieces can fit anywhere', () async {
      // Board has nearly all cells filled, but each row and column has an empty cell
      // so placing a dot will not complete any row or column.
      final board = List.filled(100, 0xFFFFFFFF);
      for (int r = 0; r < 10; r++) {
        board[r * 10 + (9 - r)] = 0; // Anti-diagonal is empty
      }
      board[0 * 10 + 0] = 0; // anchor to place dot
      board[9 * 10 + 0] = 0; // keeps col 0 from completing
      board[0 * 10 + 5] = 0; // keeps row 0 from completing

      const square3x3Shape = BlockShape(
        id: 'square_3x3',
        name: 'Square 3x3',
        cells: [
          BlockCoordinate(0, 0),
          BlockCoordinate(0, 1),
          BlockCoordinate(0, 2),
          BlockCoordinate(1, 0),
          BlockCoordinate(1, 1),
          BlockCoordinate(1, 2),
          BlockCoordinate(2, 0),
          BlockCoordinate(2, 1),
          BlockCoordinate(2, 2),
        ],
        color: Color(0xFFF43F5E),
      );

      final initialPieces = [
        const BlockPiece(instanceId: 'p0', shape: dotShape), // fits at (0, 0)
        const BlockPiece(
          instanceId: 'p1',
          shape: square3x3Shape,
        ), // cannot fit anywhere
      ];

      final cubit = BlockPuzzleCubit(
        statsStorage: storage,
        engine: engine,
        initialBoard: board,
        initialPieces: initialPieces,
      );

      // Place dot at (0, 0)
      cubit.selectPiece(0);
      await cubit.placePieceAt(0, 0);

      // Neither row 0 nor col 0 cleared because (0, 5), (0, 9), (9, 0) remain empty.
      // The only remaining piece is square_3x3 which cannot fit anywhere on the board.
      expect(cubit.state.isGameOver, isTrue);

      // Cannot place anything after game over
      final afterGameOver = await cubit.placePieceAt(
        0,
        0,
        explicitPiece: initialPieces[1],
      );
      expect(afterGameOver, isFalse);

      await cubit.close();
    });

    test(
      'startNewGame resets board and score while preserving best score',
      () async {
        storage.bestScore = 200;
        final cubit = BlockPuzzleCubit(statsStorage: storage, engine: engine);
        await Future<void>.delayed(Duration.zero);

        // Play a move
        cubit.selectPiece(0);
        await cubit.placePieceAt(0, 0);
        expect(cubit.state.score, greaterThan(0));

        // Reset
        cubit.startNewGame();
        expect(cubit.state.score, 0);
        expect(cubit.state.bestScore, 200);
        expect(cubit.state.isGameOver, isFalse);
        expect(cubit.state.board.every((c) => c == 0), isTrue);
        expect(cubit.state.availablePieces.length, 3);
        expect(cubit.state.availablePieces.every((p) => !p.isUsed), isTrue);

        await cubit.close();
      },
    );
  });
}
