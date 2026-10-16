import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_games_99/features/games/number_match/cubit/number_match_cubit.dart';
import 'package:mini_games_99/features/games/number_match/domain/number_match_engine.dart';
import 'package:mini_games_99/features/games/number_match/domain/number_match_models.dart';
import 'package:mini_games_99/features/games/number_match/domain/number_match_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SharedNumberMatchStorage storage;
  late NumberMatchCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SharedNumberMatchStorage(prefs);
    cubit = NumberMatchCubit(storage: storage, isDeterministic: true);
    await cubit.init();
  });

  tearDown(() {
    cubit.close();
  });

  group('NumberMatchCubit - Initialization and Selection', () {
    test('initializes with deterministic classic 27-tile board', () {
      expect(cubit.state.tiles.length, equals(27));
      expect(cubit.state.score, equals(0));
      expect(cubit.state.pairsCleared, equals(0));
      expect(cubit.state.selectedIndex, isNull);
      expect(cubit.state.status, equals(NumberMatchGameStatus.inProgress));
    });

    test('selectTile selects an active tile and starts timer', () {
      cubit.selectTile(0);
      expect(cubit.state.selectedIndex, equals(0));
      expect(cubit.state.isTimerRunning, isTrue);
    });

    test('tapping the same selected tile deselects it', () {
      cubit.selectTile(0);
      expect(cubit.state.selectedIndex, equals(0));

      cubit.selectTile(0);
      expect(cubit.state.selectedIndex, isNull);
    });

    test('cannot select an already cleared tile', () {
      final customTiles = [
        const NumberMatchTile(id: 0, value: 1, isCleared: true),
        const NumberMatchTile(id: 1, value: 1, isCleared: false),
      ];
      cubit.emit(cubit.state.copyWith(tiles: customTiles));

      cubit.selectTile(0);
      expect(cubit.state.selectedIndex, isNull);
    });
  });

  group('NumberMatchCubit - Pair Matching and Scoring', () {
    test('matching a valid pair clears both tiles and awards points', () {
      // In classic board: Row 2 has 1 at idx 9 and 1 at idx 10 (consecutive 1s)
      cubit.selectTile(9);
      expect(cubit.state.selectedIndex, equals(9));

      cubit.selectTile(10);
      expect(cubit.state.selectedIndex, isNull);
      expect(cubit.state.tiles[9].isCleared, isTrue);
      expect(cubit.state.tiles[10].isCleared, isTrue);
      expect(cubit.state.pairsCleared, equals(1));
      expect(cubit.state.score, greaterThanOrEqualTo(10));
      expect(cubit.state.canUndo, isTrue);
    });

    test('invalid pair attempt keeps board unchanged and shows feedback', () {
      // Index 0 has 1, Index 1 has 2. 1 and 2 don't match.
      cubit.selectTile(0);
      cubit.selectTile(1);

      expect(cubit.state.tiles[0].isCleared, isFalse);
      expect(cubit.state.tiles[1].isCleared, isFalse);
      expect(cubit.state.pairsCleared, equals(0));
      expect(cubit.state.score, equals(0));
      expect(cubit.state.feedbackMessage, isNotNull);
      // Allows smooth continuation from the newly selected tile
      expect(cubit.state.selectedIndex, equals(1));
    });
  });

  group('NumberMatchCubit - Hints, Undo, and Add Numbers', () {
    test('requestHint discovers a valid pair and highlights it', () {
      cubit.requestHint();
      expect(cubit.state.hintPair, isNotNull);
      final pair = cubit.state.hintPair!;
      expect(
        cubit.engine.canMatch(
          pair.firstIndex,
          pair.secondIndex,
          cubit.state.tiles,
        ),
        isTrue,
      );
    });

    test('undo reverts cleared pair, score, and pairs cleared count', () {
      cubit.selectTile(9);
      cubit.selectTile(10);
      expect(cubit.state.pairsCleared, equals(1));

      cubit.undo();
      expect(cubit.state.tiles[9].isCleared, isFalse);
      expect(cubit.state.tiles[10].isCleared, isFalse);
      expect(cubit.state.pairsCleared, equals(0));
      expect(cubit.state.score, equals(0));
    });

    test('addNumbers appends active numbers to board', () {
      final initialCount = cubit.state.tiles.length;
      final activeCount = cubit.state.activeCount;

      cubit.addNumbers();
      expect(cubit.state.tiles.length, equals(initialCount + activeCount));
      expect(cubit.state.actionHistory.last, isA<AddNumbersAction>());
    });

    test('undo after addNumbers reverts appended tiles', () {
      final initialCount = cubit.state.tiles.length;
      cubit.addNumbers();
      expect(cubit.state.tiles.length, greaterThan(initialCount));

      cubit.undo();
      expect(cubit.state.tiles.length, equals(initialCount));
    });
  });

  group('NumberMatchCubit - Win Condition and Restart', () {
    test('clearing all tiles triggers victory and records win', () async {
      // Set board with only 2 matching tiles
      final twoTiles = [
        const NumberMatchTile(id: 0, value: 5),
        const NumberMatchTile(id: 1, value: 5),
      ];
      cubit.emit(
        cubit.state.copyWith(tiles: twoTiles, score: 0, pairsCleared: 0),
      );

      cubit.selectTile(0);
      cubit.selectTile(1);

      expect(cubit.state.isWon, isTrue);
      expect(
        cubit.state.score,
        equals(
          NumberMatchEngine.pairScore +
              NumberMatchEngine.rowClearBonus +
              NumberMatchEngine.winBonus,
        ),
      ); // 10 + 10 + 100 = 120

      await Future<void>.delayed(Duration.zero);
      final stats = await storage.getStats();
      expect(stats.gamesWon, equals(1));
    });

    test(
      'restartGame resets board, score, pairs, and action history',
      () async {
        cubit.selectTile(9);
        cubit.selectTile(10);
        expect(cubit.state.pairsCleared, equals(1));

        await cubit.restartGame(randomized: false);
        expect(cubit.state.pairsCleared, equals(0));
        expect(cubit.state.score, equals(0));
        expect(cubit.state.actionHistory, isEmpty);
        expect(cubit.state.tiles.every((t) => !t.isCleared), isTrue);
      },
    );
  });
}
