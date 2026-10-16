import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/storage_keys.dart';
import 'home_state.dart';

/// Cubit for the Home catalog and game discovery.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState(allGames: _initialGamesCatalog));

  static const List<GameInfo> _initialGamesCatalog = [
    // 1. Playable Game: Tic-Tac-Toe
    GameInfo(
      id: StorageKeys.gameTicTacToe,
      title: 'Tic-Tac-Toe',
      description: 'Classic 3x3 strategy with smart AI & local 2P mode',
      category: GameCategory.classic,
      icon: Icons.grid_3x3_rounded,
      accentColor: Color(0xFF6366F1),
      isPlayable: true,
      playerLabel: '1-2 Players',
      route: '/games/tic-tac-toe',
    ),
    // 2. Playable Game: Number Slide (15 Puzzle)
    GameInfo(
      id: StorageKeys.gameNumberSlide,
      title: 'Number Slide',
      description: 'The classic 15 Puzzle. Slide tiles into ascending order',
      category: GameCategory.puzzle,
      icon: Icons.dialpad_rounded,
      accentColor: Color(0xFF0EA5E9),
      isPlayable: true,
      playerLabel: '1 Player',
      route: '/games/number-slide',
    ),
    // 3. Playable Game: Block Puzzle
    GameInfo(
      id: StorageKeys.gameBlockPuzzle,
      title: 'Block Puzzle',
      description: 'Fit geometric shapes into grid rows to clear lines',
      category: GameCategory.puzzle,
      icon: Icons.dashboard_customize_rounded,
      accentColor: Color(0xFF8B5CF6),
      isPlayable: true,
      playerLabel: '1 Player',
      route: '/games/block-puzzle',
    ),
    // 4. Playable Game: Word Search
    GameInfo(
      id: StorageKeys.gameWordSearch,
      title: 'Word Search',
      description: 'Find hidden words across themed puzzle boards',
      category: GameCategory.word,
      icon: Icons.spellcheck_rounded,
      accentColor: Color(0xFF10B981),
      isPlayable: true,
      playerLabel: '1 Player',
      route: '/games/word-search',
    ),
    // 5. Playable Game: Dots and Boxes
    GameInfo(
      id: StorageKeys.gameDotsAndBoxes,
      title: 'Dots and Boxes',
      description: 'Connect dots, close boxes, and outsmart your opponent',
      category: GameCategory.classic,
      icon: Icons.grid_on_rounded,
      accentColor: Color(0xFFF59E0B),
      isPlayable: true,
      playerLabel: '1-2 Players',
      route: '/games/dots-and-boxes',
    ),
    // 6. Playable Game: Sudoku
    GameInfo(
      id: StorageKeys.gameSudoku,
      title: 'Sudoku',
      description: 'Classic logic numbers puzzle with multiple grid levels',
      category: GameCategory.puzzle,
      icon: Icons.border_all_rounded,
      accentColor: Color(0xFF38BDF8),
      isPlayable: true,
      playerLabel: '1 Player',
      route: '/games/sudoku',
    ),
    // 7. Playable Game: Classic Number Match (Take Ten)
    GameInfo(
      id: StorageKeys.gameNumberMatch,
      title: 'Number Match',
      description: 'Match pairs of equal digits or pairs that sum to 10',
      category: GameCategory.puzzle,
      icon: Icons.onetwothree_rounded,
      accentColor: Color(0xFFF97316),
      isPlayable: true,
      playerLabel: '1 Player',
      route: '/games/number-match',
    ),
    // 8. Playable Game: Reaction Test
    GameInfo(
      id: StorageKeys.gameReactionTest,
      title: 'Reaction Test',
      description: 'Measure your reflex speed in milliseconds',
      category: GameCategory.brain,
      icon: Icons.speed_rounded,
      accentColor: Color(0xFF10B981),
      isPlayable: true,
      playerLabel: '1 Player',
      route: '/games/reaction-test',
    ),
    // 9. Playable Game: Emoji Connect
    GameInfo(
      id: StorageKeys.gameEmojiConnect,
      title: 'Emoji Connect',
      description:
          'Connect matching emoji pairs and cover every cell on the board',
      category: GameCategory.puzzle,
      icon: Icons.hub_rounded,
      accentColor: Color(0xFF8B5CF6),
      isPlayable: true,
      playerLabel: '1 Player',
      route: '/games/emoji-connect',
    ),
    // 10. Playable Game: Worm Escape
    GameInfo(
      id: StorageKeys.gameWormEscape,
      title: 'Worm Escape',
      description:
          'Tap colorful segmented worms in the right order to free them all',
      category: GameCategory.puzzle,
      icon: Icons.alt_route_rounded,
      accentColor: Color(0xFF10B981),
      isPlayable: true,
      playerLabel: '1 Player',
      route: '/games/worm-escape',
    ),
    // Future Games (Preview only - strictly non-playable as per specification)
    GameInfo(
      id: 'memory_match',
      title: 'Memory Match',
      description: 'Card pairing challenge to test your visual memory',
      category: GameCategory.brain,
      icon: Icons.style_rounded,
      accentColor: Color(0xFFEC4899),
      isPlayable: false,
      playerLabel: '1 Player',
    ),
    GameInfo(
      id: 'number_merge',
      title: 'Number Merge',
      description: 'Slide and combine matching numbers to reach 2048',
      category: GameCategory.puzzle,
      icon: Icons.exposure_plus_1_rounded,
      accentColor: Color(0xFFF59E0B),
      isPlayable: false,
      playerLabel: '1 Player',
    ),
    GameInfo(
      id: 'hangman',
      title: 'Hangman',
      description: 'Guess the secret word before attempts run out',
      category: GameCategory.word,
      icon: Icons.text_fields_rounded,
      accentColor: Color(0xFFF43F5E),
      isPlayable: false,
      playerLabel: '1 Player',
    ),
  ];

  void selectCategory(GameCategory category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }
}
