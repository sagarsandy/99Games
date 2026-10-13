import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../di/injection.dart';

/// Settings screen for managing theme, sound, and app preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppPreferences _prefs;
  late ThemeMode _themeMode;
  late bool _soundEnabled;
  late bool _hapticsEnabled;

  @override
  void initState() {
    super.initState();
    _prefs = getIt<AppPreferences>();
    _themeMode = _prefs.getThemeMode();
    _soundEnabled = _prefs.isSoundEnabled();
    _hapticsEnabled = _prefs.isHapticsEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Appearance section
          Text(
            'APPEARANCE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Theme Mode',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode, size: 16),
                      ),
                    ],
                    selected: {_themeMode},
                    onSelectionChanged: (newSelection) async {
                      final selected = newSelection.first;
                      setState(() => _themeMode = selected);
                      await _prefs.setThemeMode(selected);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Audio & Feedback
          Text(
            'AUDIO & HAPTICS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined),
                  title: const Text('Sound Effects'),
                  subtitle: const Text('Play sound effects during gameplay'),
                  value: _soundEnabled,
                  onChanged: (val) async {
                    setState(() => _soundEnabled = val);
                    await _prefs.setSoundEnabled(val);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_outlined),
                  title: const Text('Haptic Feedback'),
                  subtitle: const Text('Vibrate gently on cell taps and moves'),
                  value: _hapticsEnabled,
                  onChanged: (val) async {
                    setState(() => _hapticsEnabled = val);
                    await _prefs.setHapticsEnabled(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About section
          Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('99 Mini Games'),
              subtitle: const Text('Version 1.0.0 • Pure Dart & Flutter'),
            ),
          ),
        ],
      ),
    );
  }
}
