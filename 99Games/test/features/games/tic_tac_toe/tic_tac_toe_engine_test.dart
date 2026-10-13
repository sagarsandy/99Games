import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/tic_tac_toe/domain/tic_tac_toe_engine.dart';
import 'package:mini_games_99/features/games/tic_tac_toe/domain/tic_tac_toe_models.dart';

void main() {
  late TicTacToeEngine engine;

  setUp(() {
    engine = TicTacToeEngine();
  });

  group('TicTacToeEngine - Board and Moves', () {
    test('initial board has 9 empty cells', () {
      final board = engine.createEmptyBoard();
      expect(board.length, 9);
      expect(board.every((cell) => cell.isNone), isTrue);
    });

    test('valid and invalid moves are detected correctly', () {
      final board = engine.createEmptyBoard();

      // Inside bounds empty cell
      expect(engine.isValidMove(board, 0), isTrue);
      expect(engine.isValidMove(board, 4), isTrue);
      expect(engine.isValidMove(board, 8), isTrue);

      // Out of bounds
      expect(engine.isValidMove(board, -1), isFalse);
      expect(engine.isValidMove(board, 9), isFalse);

      // Occupied cell
      final boardWithMove = engine.applyMove(board, 4, PlayerSymbol.x);
      expect(engine.isValidMove(boardWithMove, 4), isFalse);
    });

    test(
      'applyMove returns a new immutable board without mutating original',
      () {
        final originalBoard = engine.createEmptyBoard();
        final updatedBoard = engine.applyMove(originalBoard, 2, PlayerSymbol.x);

        expect(originalBoard[2], PlayerSymbol.none);
        expect(updatedBoard[2], PlayerSymbol.x);
        expect(() => updatedBoard[2] = PlayerSymbol.o, throwsUnsupportedError);
      },
    );

    test('applyMove throws ArgumentError when move is invalid', () {
      final board = engine.createEmptyBoard();
      final moved = engine.applyMove(board, 0, PlayerSymbol.x);

      expect(
        () => engine.applyMove(moved, 0, PlayerSymbol.o),
        throwsArgumentError,
      );
    });

    test('turn switching via PlayerSymbol.opposite', () {
      expect(PlayerSymbol.x.opposite, PlayerSymbol.o);
      expect(PlayerSymbol.o.opposite, PlayerSymbol.x);
      expect(PlayerSymbol.none.opposite, PlayerSymbol.none);
    });
  });

  group('TicTacToeEngine - Win Detection', () {
    test('detects all 8 possible winning combinations for player X', () {
      for (final combo in TicTacToeEngine.winningCombinations) {
        final board = List.filled(9, PlayerSymbol.none);
        board[combo[0]] = PlayerSymbol.x;
        board[combo[1]] = PlayerSymbol.x;
        board[combo[2]] = PlayerSymbol.x;

        final result = engine.evaluateBoard(board);
        expect(
          result.status,
          GameStatus.win,
          reason: 'Failed for combo $combo',
        );
        expect(result.winner, PlayerSymbol.x);
        expect(result.winningIndices, combo);
      }
    });

    test('detects all 8 possible winning combinations for player O', () {
      for (final combo in TicTacToeEngine.winningCombinations) {
        final board = List.filled(9, PlayerSymbol.none);
        board[combo[0]] = PlayerSymbol.o;
        board[combo[1]] = PlayerSymbol.o;
        board[combo[2]] = PlayerSymbol.o;

        final result = engine.evaluateBoard(board);
        expect(
          result.status,
          GameStatus.win,
          reason: 'Failed for combo $combo',
        );
        expect(result.winner, PlayerSymbol.o);
        expect(result.winningIndices, combo);
      }
    });

    test('detects draw when board is full with no winner', () {
      // Board layout:
      // X O X
      // X X O
      // O X O
      final board = [
        PlayerSymbol.x,
        PlayerSymbol.o,
        PlayerSymbol.x,
        PlayerSymbol.x,
        PlayerSymbol.x,
        PlayerSymbol.o,
        PlayerSymbol.o,
        PlayerSymbol.x,
        PlayerSymbol.o,
      ];

      final result = engine.evaluateBoard(board);
      expect(result.status, GameStatus.draw);
      expect(result.winner, isNull);
      expect(result.winningIndices, isNull);
    });

    test('returns inProgress for unfinished board without winner', () {
      final board = [
        PlayerSymbol.x,
        PlayerSymbol.o,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.x,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.none,
      ];

      final result = engine.evaluateBoard(board);
      expect(result.status, GameStatus.inProgress);
    });
  });

  group('TicTacToeEngine - AI Difficulty Modes', () {
    test('easy AI returns a valid empty cell', () {
      final board = [
        PlayerSymbol.x,
        PlayerSymbol.o,
        PlayerSymbol.x,
        PlayerSymbol.o,
        PlayerSymbol.x,
        PlayerSymbol.none,
        PlayerSymbol.o,
        PlayerSymbol.none,
        PlayerSymbol.none,
      ];

      final move = engine.selectAiMove(
        board: board,
        aiSymbol: PlayerSymbol.o,
        difficulty: AiDifficulty.easy,
      );

      expect(move, isNotNull);
      expect([5, 7, 8].contains(move), isTrue);
      expect(engine.isValidMove(board, move!), isTrue);
    });

    test('medium AI returns a valid empty cell', () {
      final board = [
        PlayerSymbol.x,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.o,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.none,
      ];

      final move = engine.selectAiMove(
        board: board,
        aiSymbol: PlayerSymbol.o,
        difficulty: AiDifficulty.medium,
      );

      expect(move, isNotNull);
      expect(engine.isValidMove(board, move!), isTrue);
    });

    test('hard AI takes an immediate winning move', () {
      // O can win at index 2 (row 0: O, O, empty)
      final board = [
        PlayerSymbol.o,
        PlayerSymbol.o,
        PlayerSymbol.none,
        PlayerSymbol.x,
        PlayerSymbol.x,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.none,
      ];

      final move = engine.selectAiMove(
        board: board,
        aiSymbol: PlayerSymbol.o,
        difficulty: AiDifficulty.hard,
      );

      expect(move, equals(2));
    });

    test('hard AI blocks an opponent immediate winning move', () {
      // X threatens to win at index 2 (row 0: X, X, empty)
      // O must block at 2
      final board = [
        PlayerSymbol.x,
        PlayerSymbol.x,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.o,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.none,
        PlayerSymbol.none,
      ];

      final move = engine.selectAiMove(
        board: board,
        aiSymbol: PlayerSymbol.o,
        difficulty: AiDifficulty.hard,
      );

      expect(move, equals(2));
    });

    test('hard AI never loses against any sequence of moves', () {
      // Exhaustively test hard AI (playing as O) against multiple opening moves by X
      // For any opening move by X, playing against hard AI should result in either AI win or Draw, NEVER an AI loss.
      for (int xOpening = 0; xOpening < 9; xOpening++) {
        var currentBoard = engine.createEmptyBoard();
        currentBoard = engine.applyMove(currentBoard, xOpening, PlayerSymbol.x);

        // Simulate game to end with greedy/random X moves against optimal hard AI
        final pseudoRandom = Random(42 + xOpening);
        while (true) {
          final eval1 = engine.evaluateBoard(currentBoard);
          if (eval1.status.isGameOver) break;

          // AI (O) move
          final aiMove = engine.selectAiMove(
            board: currentBoard,
            aiSymbol: PlayerSymbol.o,
            difficulty: AiDifficulty.hard,
          );
          expect(aiMove, isNotNull);
          currentBoard = engine.applyMove(
            currentBoard,
            aiMove!,
            PlayerSymbol.o,
          );

          final eval2 = engine.evaluateBoard(currentBoard);
          if (eval2.status.isGameOver) {
            expect(
              eval2.winner,
              isNot(PlayerSymbol.x),
              reason: 'Hard AI should never lose!',
            );
            break;
          }

          // X move (picks an available move, prioritizing wins/blocks if possible)
          final availableForX = engine.getAvailableMoves(currentBoard);
          if (availableForX.isEmpty) break;
          final xMove =
              availableForX[pseudoRandom.nextInt(availableForX.length)];
          currentBoard = engine.applyMove(currentBoard, xMove, PlayerSymbol.x);

          final eval3 = engine.evaluateBoard(currentBoard);
          if (eval3.status.isGameOver) {
            expect(
              eval3.winner,
              isNot(PlayerSymbol.x),
              reason: 'Hard AI should never lose against any sequence!',
            );
            break;
          }
        }
      }
    });
  });
}
