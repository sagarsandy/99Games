import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/sudoku/cubit/sudoku_cubit.dart';
import 'package:mini_games_99/features/games/sudoku/domain/sudoku_engine.dart';
import 'package:mini_games_99/features/games/sudoku/domain/sudoku_generator.dart';
import 'package:mini_games_99/features/games/sudoku/domain/sudoku_models.dart';
import 'package:mini_games_99/features/games/sudoku/domain/sudoku_storage.dart';

class FakeSudokuStorage implements SudokuStorage {
  SudokuSavedSession? session;
  final Map<SudokuDifficulty, SudokuStats> stats = {};
  int recordResultCount = 0;
  int clearSessionCount = 0;

  @override
  Future<SudokuSavedSession?> getSavedSession() async => session;

  @override
  Future<void> saveSession(SudokuSavedSession s) async {
    session = s;
  }

  @override
  Future<void> clearSavedSession() async {
    clearSessionCount++;
    session = null;
  }

  @override
  Future<SudokuStats> getStats(SudokuDifficulty difficulty) async {
    return stats[difficulty] ?? SudokuStats.empty;
  }

  @override
  Future<void> recordGameResult({
    required SudokuDifficulty difficulty,
    required bool won,
    int? timeInSeconds,
  }) async {
    recordResultCount++;
    final current = stats[difficulty] ?? SudokuStats.empty;
    stats[difficulty] = SudokuStats(
      gamesCompleted: current.gamesCompleted + 1,
      gamesWon: won ? current.gamesWon + 1 : current.gamesWon,
      gamesLost: won ? current.gamesLost : current.gamesLost + 1,
      bestTimeSeconds: won && timeInSeconds != null
          ? (current.bestTimeSeconds == null ||
                    timeInSeconds < current.bestTimeSeconds!
                ? timeInSeconds
                : current.bestTimeSeconds)
          : current.bestTimeSeconds,
    );
  }

  @override
  Future<void> resetStats(SudokuDifficulty difficulty) async {
    stats.remove(difficulty);
  }
}

class DeterministicSudokuGenerator extends SudokuGenerator {
  final SudokuPuzzle deterministicPuzzle;

  DeterministicSudokuGenerator(this.deterministicPuzzle);

  @override
  SudokuPuzzle generatePuzzle({
    required SudokuDifficulty difficulty,
    int maxAttempts = 8,
  }) {
    return deterministicPuzzle;
  }
}

void main() {
  late FakeSudokuStorage storage;
  late SudokuEngine engine;
  late SudokuPuzzle testPuzzle;
  late DeterministicSudokuGenerator generator;

  // Known solution
  final testSolution = [
    5,
    3,
    4,
    6,
    7,
    8,
    9,
    1,
    2,
    6,
    7,
    2,
    1,
    9,
    5,
    3,
    4,
    8,
    1,
    9,
    8,
    3,
    4,
    2,
    5,
    6,
    7,
    8,
    5,
    9,
    7,
    6,
    1,
    4,
    2,
    3,
    4,
    2,
    6,
    8,
    5,
    3,
    7,
    9,
    1,
    7,
    1,
    3,
    9,
    2,
    4,
    8,
    5,
    6,
    9,
    6,
    1,
    5,
    3,
    7,
    2,
    8,
    4,
    2,
    8,
    7,
    4,
    1,
    9,
    6,
    3,
    5,
    3,
    4,
    5,
    2,
    8,
    6,
    1,
    7,
    9,
  ];

  // Clues with empty spots at (0, 0) and (0, 1)
  final testClues = List<int>.from(testSolution);
  testClues[0] = 0; // Solution is 5
  testClues[1] = 0; // Solution is 3

  setUp(() {
    storage = FakeSudokuStorage();
    engine = const SudokuEngine();
    testPuzzle = SudokuPuzzle(
      clues: List.unmodifiable(testClues),
      solution: List.unmodifiable(testSolution),
      difficulty: SudokuDifficulty.easy,
    );
    generator = DeterministicSudokuGenerator(testPuzzle);
  });

  SudokuCubit createCubit() {
    return SudokuCubit(
      storage: storage,
      engine: engine,
      generator: generator,
      defaultDifficulty: SudokuDifficulty.easy,
    );
  }

  group('SudokuCubit - Initialization & Selection', () {
    test(
      'initializes with fresh puzzle when no saved session exists',
      () async {
        final cubit = createCubit();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.clues, equals(testPuzzle.clues));
        expect(cubit.state.solution, equals(testPuzzle.solution));
        expect(cubit.state.difficulty, equals(SudokuDifficulty.easy));
        expect(cubit.state.mistakes, equals(0));
        expect(cubit.state.status, equals(SudokuGameStatus.inProgress));
        expect(cubit.state.selectedCell, isNull);

        await cubit.close();
      },
    );

    test('selectCell updates selected index', () async {
      final cubit = createCubit();
      await Future<void>.delayed(Duration.zero);

      cubit.selectCell(10);
      expect(cubit.state.selectedCell, equals(10));

      // Re-selecting same cell does nothing
      cubit.selectCell(10);
      expect(cubit.state.selectedCell, equals(10));

      await cubit.close();
    });
  });

  group('SudokuCubit - Number Entry & Mistakes', () {
    test('disallows editing prefilled clues', () async {
      final cubit = createCubit();
      await Future<void>.delayed(Duration.zero);

      // Cell 2 is a clue (value 4)
      cubit.selectCell(2);
      expect(cubit.state.isSelectedCellClue, isTrue);

      await cubit.enterNumber(9);
      // Board remains 4
      expect(cubit.state.board[2], equals(4));
      expect(cubit.state.mistakes, equals(0));

      await cubit.close();
    });

    test('correct number entry does not increment mistake count', () async {
      final cubit = createCubit();
      await Future<void>.delayed(Duration.zero);

      // Cell 0 is empty, correct value is 5
      cubit.selectCell(0);
      await cubit.enterNumber(5);

      expect(cubit.state.board[0], equals(5));
      expect(cubit.state.mistakes, equals(0));
      expect(cubit.state.incorrectIndices.contains(0), isFalse);

      await cubit.close();
    });

    test(
      'incorrect number entry increments mistake count and marks cell',
      () async {
        final cubit = createCubit();
        await Future<void>.delayed(Duration.zero);

        // Cell 0 is empty, correct value is 5. Enter 9 (wrong)!
        cubit.selectCell(0);
        await cubit.enterNumber(9);

        expect(cubit.state.board[0], equals(9));
        expect(cubit.state.mistakes, equals(1));
        expect(cubit.state.incorrectIndices.contains(0), isTrue);

        // Re-entering same number does not increment mistake count again
        await cubit.enterNumber(9);
        expect(cubit.state.mistakes, equals(1));

        await cubit.close();
      },
    );

    test('three mistakes triggers Game Over and stops the game', () async {
      final cubit = createCubit();
      await Future<void>.delayed(Duration.zero);

      cubit.selectCell(0);
      await cubit.enterNumber(1); // Mistake 1
      expect(cubit.state.mistakes, equals(1));

      await cubit.enterNumber(2); // Mistake 2
      expect(cubit.state.mistakes, equals(2));

      await cubit.enterNumber(3); // Mistake 3 -> Game Over!
      expect(cubit.state.mistakes, equals(3));
      expect(cubit.state.status, equals(SudokuGameStatus.gameOver));
      expect(cubit.state.isGameOver, isTrue);

      // Cannot make further moves after Game Over
      await cubit.enterNumber(5);
      expect(cubit.state.board[0], equals(3));

      // Saved session cleared on Game Over
      expect(storage.clearSessionCount, greaterThanOrEqualTo(1));

      await cubit.close();
    });
  });

  group('SudokuCubit - Notes Mode', () {
    test(
      'toggling notes adds and removes candidates without counting mistakes',
      () async {
        final cubit = createCubit();
        await Future<void>.delayed(Duration.zero);

        cubit.selectCell(0);
        cubit.toggleNotesMode();
        expect(cubit.state.isNotesMode, isTrue);

        // Add note 2 and 4
        await cubit.enterNumber(2);
        await cubit.enterNumber(4);
        expect(cubit.state.notes[0], equals({2, 4}));
        expect(cubit.state.mistakes, equals(0));
        expect(cubit.state.board[0], equals(0)); // Cell remains unfilled

        // Toggle off note 2
        await cubit.enterNumber(2);
        expect(cubit.state.notes[0], equals({4}));

        // Entering a real number in normal mode clears cell notes
        cubit.toggleNotesMode();
        await cubit.enterNumber(5);
        expect(cubit.state.board[0], equals(5));
        expect(cubit.state.notes[0], isNull);

        await cubit.close();
      },
    );
  });

  group('SudokuCubit - Erase, Hint, Undo & Win', () {
    test(
      'erase clears player value and notes without incrementing mistakes',
      () async {
        final cubit = createCubit();
        await Future<void>.delayed(Duration.zero);

        cubit.selectCell(0);
        await cubit.enterNumber(9); // wrong entry
        expect(cubit.state.board[0], equals(9));
        expect(cubit.state.mistakes, equals(1));

        await cubit.erase();
        expect(cubit.state.board[0], equals(0));
        expect(cubit.state.mistakes, equals(1)); // mistakes not reset

        await cubit.close();
      },
    );

    test('hint reveals solution without counting as mistake', () async {
      final cubit = createCubit();
      await Future<void>.delayed(Duration.zero);

      cubit.selectCell(0);
      await cubit.giveHint();

      expect(cubit.state.board[0], equals(5)); // correct solution
      expect(cubit.state.mistakes, equals(0));

      await cubit.close();
    });

    test(
      'undo reverts previous entry and notes without resetting mistakes',
      () async {
        final cubit = createCubit();
        await Future<void>.delayed(Duration.zero);

        cubit.selectCell(0);
        await cubit.enterNumber(9); // wrong
        expect(cubit.state.board[0], equals(9));
        expect(cubit.state.mistakes, equals(1));

        await cubit.undo();
        expect(cubit.state.board[0], equals(0));
        // Crucial: Undo does not erase accumulated mistakes!
        expect(cubit.state.mistakes, equals(1));

        await cubit.close();
      },
    );

    test('filling all cells correctly triggers completed win status', () async {
      final cubit = createCubit();
      await Future<void>.delayed(Duration.zero);

      // Only cell 0 and cell 1 are empty
      cubit.selectCell(0);
      await cubit.enterNumber(5);

      cubit.selectCell(1);
      await cubit.enterNumber(3); // Fills last cell with correct digit!

      expect(cubit.state.status, equals(SudokuGameStatus.completed));
      expect(cubit.state.isCompleted, isTrue);
      expect(storage.recordResultCount, equals(1));

      await cubit.close();
    });
  });

  group('SudokuCubit - Save and Resume', () {
    test('restores an existing in-progress session upon init', () async {
      storage.session = SudokuSavedSession(
        clues: testPuzzle.clues,
        solution: testPuzzle.solution,
        board: [
          ...testPuzzle.clues.sublist(0, 1),
          3, // cell 1 filled
          ...testPuzzle.clues.sublist(2),
        ],
        notes: {
          0: {5},
        },
        difficulty: SudokuDifficulty.medium,
        mistakes: 1,
        elapsedSeconds: 210,
        status: SudokuGameStatus.inProgress,
        selectedCell: 0,
      );

      final cubit = createCubit();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.difficulty, equals(SudokuDifficulty.medium));
      expect(cubit.state.board[1], equals(3));
      expect(cubit.state.notes[0], equals({5}));
      expect(cubit.state.mistakes, equals(1));
      expect(cubit.state.elapsedSeconds, equals(210));
      expect(cubit.state.selectedCell, equals(0));

      await cubit.close();
    });
  });
}
