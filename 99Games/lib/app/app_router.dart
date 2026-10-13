import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/game_stats_storage.dart';
import '../di/injection.dart';
import '../features/games/block_puzzle/cubit/block_puzzle_cubit.dart';
import '../features/games/block_puzzle/presentation/block_puzzle_screen.dart';
import '../features/games/number_slide/cubit/number_slide_cubit.dart';
import '../features/games/number_slide/presentation/number_slide_screen.dart';
import '../features/games/tic_tac_toe/cubit/tic_tac_toe_cubit.dart';
import '../features/games/tic_tac_toe/presentation/tic_tac_toe_screen.dart';
import '../features/games/word_search/cubit/word_search_cubit.dart';
import '../features/games/word_search/presentation/word_search_screen.dart';
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
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
