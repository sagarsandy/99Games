/// Centralized storage keys for SharedPreferences.
abstract final class StorageKeys {
  // App preferences
  static const String themeMode = 'app_theme_mode';
  static const String soundEnabled = 'app_sound_enabled';
  static const String hapticsEnabled = 'app_haptics_enabled';

  // Game IDs
  static const String gameTicTacToe = 'tic_tac_toe';
  static const String gameNumberSlide = 'number_slide';
  static const String gameBlockPuzzle = 'block_puzzle';
  static const String gameWordSearch = 'word_search';

  // Key generator helper for game statistics
  static String gameStatsKey(String gameId, String subKey) =>
      'game_stats_${gameId}_$subKey';
}
