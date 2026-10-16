import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/memory_match/cubit/memory_match_cubit.dart';
import 'package:mini_games_99/features/games/memory_match/domain/memory_match_storage.dart';
import 'package:mini_games_99/features/games/memory_match/presentation/memory_match_screen.dart';
import 'package:mini_games_99/features/games/memory_match/presentation/widgets/memory_match_card.dart';
import 'package:mini_games_99/features/games/memory_match/presentation/widgets/memory_match_completion_dialog.dart';
import 'package:mini_games_99/features/games/memory_match/presentation/widgets/memory_match_hud.dart';
import 'package:mini_games_99/features/games/memory_match/presentation/widgets/memory_match_start_screen.dart';

class MockMemoryMatchStorage implements MemoryMatchStorage {
  int _highestUnlocked = 1;
  final Map<int, int> _bestScores = {};

  MockMemoryMatchStorage({int initialUnlocked = 1})
    : _highestUnlocked = initialUnlocked;

  @override
  Future<int> getHighestUnlockedLevel() async => _highestUnlocked;

  @override
  Future<void> setHighestUnlockedLevel(int level) async {
    _highestUnlocked = level;
  }

  @override
  Future<int> getBestScore(int level) async => _bestScores[level] ?? 0;

  @override
  Future<void> setBestScore(int level, int score) async {
    _bestScores[level] = score;
  }

  @override
  Future<int> getBestMoves(int level) async => 0;

  @override
  Future<void> setBestMoves(int level, int moves) async {}

  @override
  Future<int> getBestTime(int level) async => 0;

  @override
  Future<void> setBestTime(int level, int seconds) async {}

  @override
  Future<int> getTotalBestScore() async => 0;

  @override
  Future<void> resetAll() async {}
}

Widget createTestApp(MemoryMatchCubit cubit) {
  return MaterialApp(
    home: BlocProvider<MemoryMatchCubit>.value(
      value: cubit,
      child: const MemoryMatchScreen(),
    ),
  );
}

void main() {
  group('Memory Match Widget Tests', () {
    testWidgets(
      '1. Displays start screen overlay initially with Play button and rules',
      (tester) async {
        final storage = MockMemoryMatchStorage();
        final cubit = MemoryMatchCubit(storage: storage);
        await cubit.loadInitial();

        await tester.pumpWidget(createTestApp(cubit));
        await tester.pumpAndSettle();

        expect(find.byType(MemoryMatchStartScreen), findsOneWidget);
        expect(find.text('Memory Match'), findsWidgets);
        expect(
          find.byKey(const Key('memory_match_start_play_button')),
          findsOneWidget,
        );
        expect(find.text('Play Level 1'), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets('2. Tapping Play button reveals grid and HUD stats', (
      tester,
    ) async {
      final storage = MockMemoryMatchStorage();
      final cubit = MemoryMatchCubit(storage: storage);
      await cubit.loadInitial();

      await tester.pumpWidget(createTestApp(cubit));
      await tester.pumpAndSettle();

      // Tap Play
      await tester.tap(find.byKey(const Key('memory_match_start_play_button')));
      await tester.pumpAndSettle();

      // Start overlay gone
      expect(find.byType(MemoryMatchStartScreen), findsNothing);

      // HUD and Grid visible
      expect(find.byType(MemoryMatchHud), findsOneWidget);
      expect(find.text('0 Moves'), findsOneWidget);
      expect(find.text('0/2 Pairs'), findsOneWidget);
      expect(find.text('0 pts'), findsOneWidget);

      // Level 1 has 4 cards
      expect(find.byType(MemoryMatchCard), findsNWidgets(4));

      await cubit.close();
    });

    testWidgets('3. Tapping a card triggers flip animation', (tester) async {
      final storage = MockMemoryMatchStorage();
      final cubit = MemoryMatchCubit(storage: storage);
      await cubit.loadInitial();

      await tester.pumpWidget(createTestApp(cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('memory_match_start_play_button')));
      await tester.pumpAndSettle();

      // Tap the first card
      await tester.tap(find.byType(MemoryMatchCard).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(cubit.state.cards.any((c) => c.isFaceUp), isTrue);

      await cubit.close();
    });

    testWidgets(
      '4. Solved level displays completion dialog with score breakdown',
      (tester) async {
        final storage = MockMemoryMatchStorage();
        final cubit = MemoryMatchCubit(storage: storage);
        await cubit.loadInitial();

        await tester.pumpWidget(createTestApp(cubit));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('memory_match_start_play_button')),
        );
        await tester.pumpAndSettle();

        // Match all pairs programmatically
        final deck = cubit.state.cards;
        final pair0 = deck.where((c) => c.pairId == 0).toList();
        final pair1 = deck.where((c) => c.pairId == 1).toList();

        await cubit.onCardTapped(pair0[0].id);
        await cubit.onCardTapped(pair0[1].id);
        await cubit.onCardTapped(pair1[0].id);
        await cubit.onCardTapped(pair1[1].id);

        await tester.pumpAndSettle();

        // Completion dialog appears
        expect(find.byType(MemoryMatchCompletionDialog), findsOneWidget);
        expect(find.text('Level Complete!'), findsOneWidget);
        expect(find.text('TOTAL LEVEL SCORE'), findsOneWidget);
        expect(find.text('Next Level'), findsOneWidget);
        expect(find.text('Replay'), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets(
      '5. Narrow mobile screen (320x568) renders 30-card level without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final storage = MockMemoryMatchStorage(initialUnlocked: 20);
        final cubit = MemoryMatchCubit(storage: storage);
        await cubit.startLevel(20); // 30 cards

        await tester.pumpWidget(createTestApp(cubit));
        await tester.pumpAndSettle();

        // Verify all 30 cards rendered
        expect(find.byType(MemoryMatchCard), findsNWidgets(30));

        // No RenderFlex overflow
        expect(tester.takeException(), isNull);

        await cubit.close();
      },
    );
  });
}
