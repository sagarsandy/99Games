import 'package:flutter/material.dart';
import '../core/storage/app_preferences.dart';
import '../di/injection.dart';
import 'app_router.dart';
import 'app_theme.dart';

/// Root application widget for 99 Mini Games.
class NinetyNineGamesApp extends StatelessWidget {
  const NinetyNineGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = getIt<AppPreferences>();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: prefs.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: '99 Mini Games',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
