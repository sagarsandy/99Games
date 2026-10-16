import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/game_stats_storage.dart';
import '../di/injection.dart';
import '../features/games/block_puzzle/cubit/block_puzzle_cubit.dart';
import '../features/games/block_puzzle/presentation/block_puzzle_screen.dart';
import '../features/games/dots_and_boxes/cubit/dots_and_boxes_cubit.dart';
import '../features/games/dots_and_boxes/presentation/dots_and_boxes_screen.dart';
import '../features/games/number_slide/cubit/number_slide_cubit.dart';
import '../features/games/number_slide/presentation/number_slide_screen.dart';
import '../features/games/sudoku/cubit/sudoku_cubit.dart';
import '../features/games/sudoku/domain/sudoku_storage.dart';
import '../features/games/sudoku/presentation/sudoku_screen.dart';
import '../features/games/tic_tac_toe/cubit/tic_tac_toe_cubit.dart';
import '../features/games/tic_tac_toe/presentation/tic_tac_toe_screen.dart';
import '../features/games/word_search/cubit/word_search_cubit.dart';
import '../features/games/word_search/presentation/word_search_screen.dart';
import '../features/games/number_match/cubit/number_match_cubit.dart';
import '../features/games/number_match/domain/number_match_storage.dart';
import '../features/games/number_match/presentation/number_match_screen.dart';
import '../features/games/reaction_test/cubit/reaction_test_cubit.dart';
import '../features/games/reaction_test/domain/reaction_test_storage.dart';
import '../features/games/reaction_test/presentation/reaction_test_screen.dart';
import '../features/games/emoji_connect/cubit/emoji_connect_cubit.dart';
import '../features/games/emoji_connect/domain/emoji_connect_storage.dart';
import '../features/games/emoji_connect/presentation/emoji_connect_screen.dart';
import '../features/games/worm_escape/cubit/worm_escape_cubit.dart';
import '../features/games/worm_escape/domain/worm_escape_storage.dart';
import '../features/games/worm_escape/presentation/worm_escape_screen.dart';
import '../features/games/fish_family_rescue/cubit/fish_family_cubit.dart';
import '../features/games/fish_family_rescue/domain/fish_family_storage.dart';
import '../features/games/fish_family_rescue/presentation/fish_family_screen.dart';
import '../features/games/word_circle/cubit/word_circle_cubit.dart';
import '../features/games/word_circle/domain/word_circle_storage.dart';
import '../features/games/word_circle/presentation/word_circle_screen.dart';
import '../features/games/fruit_catcher/cubit/fruit_catcher_cubit.dart';
import '../features/games/fruit_catcher/domain/fruit_catcher_storage.dart';
import '../features/games/fruit_catcher/presentation/fruit_catcher_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// Centralized route definitions using GoRouter.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/games/tic-tac-toe',
      builder: (context, state) => BlocProvider(
        create: (_) => TicTacToeCubit(statsStorage: getIt<GameStatsStorage>()),
        child: const TicTacToeScreen(),
      ),
    ),
    GoRoute(
      path: '/games/number-slide',
      builder: (context, state) => BlocProvider(
        create: (_) =>
            NumberSlideCubit(statsStorage: getIt<GameStatsStorage>()),
        child: const NumberSlideScreen(),
      ),
    ),
    GoRoute(
      path: '/games/block-puzzle',
      builder: (context, state) => BlocProvider(
        create: (_) =>
            BlockPuzzleCubit(statsStorage: getIt<GameStatsStorage>()),
        child: const BlockPuzzleScreen(),
      ),
    ),
    GoRoute(
      path: '/games/word-search',
      builder: (context, state) => BlocProvider(
        create: (_) => WordSearchCubit(statsStorage: getIt<GameStatsStorage>()),
        child: const WordSearchScreen(),
      ),
    ),
    GoRoute(
      path: '/games/dots-and-boxes',
      builder: (context, state) => BlocProvider(
        create: (_) =>
            DotsAndBoxesCubit(statsStorage: getIt<GameStatsStorage>()),
        child: const DotsAndBoxesScreen(),
      ),
    ),
    GoRoute(
      path: '/games/sudoku',
      builder: (context, state) => BlocProvider(
        create: (_) => SudokuCubit(storage: getIt<SudokuStorage>()),
        child: const SudokuScreen(),
      ),
    ),
    GoRoute(
      path: '/games/number-match',
      builder: (context, state) => BlocProvider(
        create: (_) => NumberMatchCubit(storage: getIt<NumberMatchStorage>()),
        child: const NumberMatchScreen(),
      ),
    ),
    GoRoute(
      path: '/games/reaction-test',
      builder: (context, state) => BlocProvider(
        create: (_) => ReactionTestCubit(storage: getIt<ReactionTestStorage>()),
        child: const ReactionTestScreen(),
      ),
    ),
    GoRoute(
      path: '/games/emoji-connect',
      builder: (context, state) => BlocProvider(
        create: (_) => EmojiConnectCubit(storage: getIt<EmojiConnectStorage>()),
        child: const EmojiConnectScreen(),
      ),
    ),
    GoRoute(
      path: '/games/worm-escape',
      builder: (context, state) => BlocProvider(
        create: (_) => WormEscapeCubit(storage: getIt<WormEscapeStorage>()),
        child: const WormEscapeScreen(),
      ),
    ),
    GoRoute(
      path: '/games/fish-family-rescue',
      builder: (context, state) => BlocProvider(
        create: (_) => FishFamilyCubit(storage: getIt<FishFamilyStorage>()),
        child: const FishFamilyScreen(),
      ),
    ),
    GoRoute(
      path: '/games/word-circle',
      builder: (context, state) => BlocProvider(
        create: (_) => WordCircleCubit(storage: getIt<WordCircleStorage>()),
        child: const WordCircleScreen(),
      ),
    ),
    GoRoute(
      path: '/games/fruit-catcher',
      builder: (context, state) => BlocProvider(
        create: (_) => FruitCatcherCubit(storage: getIt<FruitCatcherStorage>()),
        child: const FruitCatcherScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
