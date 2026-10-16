import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/app_preferences.dart';
import '../core/storage/game_stats_storage.dart';
import '../features/games/sudoku/domain/sudoku_storage.dart';
import '../features/games/number_match/domain/number_match_storage.dart';
import '../features/games/reaction_test/domain/reaction_test_storage.dart';
import '../features/games/emoji_connect/domain/emoji_connect_storage.dart';
import '../features/games/worm_escape/domain/worm_escape_storage.dart';

final GetIt getIt = GetIt.instance;

/// Configures shared singleton services in GetIt.
///
/// Should be called after `WidgetsFlutterBinding.ensureInitialized()`
/// and before `runApp()`.
Future<void> configureDependencies({SharedPreferences? customPrefs}) async {
  // If customPrefs is passed (e.g. for testing), use that; otherwise get default.
  final prefs = customPrefs ?? await SharedPreferences.getInstance();

  if (getIt.isRegistered<SharedPreferences>()) {
    await getIt.reset();
  }

  getIt.registerSingleton<SharedPreferences>(prefs);

  // Storage abstractions
  getIt.registerLazySingleton<AppPreferences>(
    () => SharedAppPreferences(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<GameStatsStorage>(
    () => SharedGameStatsStorage(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<SudokuStorage>(
    () => SharedSudokuStorage(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<NumberMatchStorage>(
    () => SharedNumberMatchStorage(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<ReactionTestStorage>(
    () => SharedReactionTestStorage(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<EmojiConnectStorage>(
    () => SharedEmojiConnectStorage(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<WormEscapeStorage>(
    () => SharedWormEscapeStorage(getIt<SharedPreferences>()),
  );
}
