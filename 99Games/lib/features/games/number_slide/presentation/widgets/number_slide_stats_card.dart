import 'package:flutter/material.dart';
import 'package:mini_games_99/core/storage/game_stats_storage.dart';

/// Scoreboard displaying current moves, elapsed time, and best result.
class NumberSlideStatsCard extends StatelessWidget {
  final int moves;
  final String formattedTime;
  final NumberSlideBestResult? bestResult;

  const NumberSlideStatsCard({
    super.key,
    required this.moves,
    required this.formattedTime,
    this.bestResult,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Moves Counter
          _buildMetric(
            context: context,
            label: 'Moves',
            value: '$moves',
            icon: Icons.touch_app_rounded,
            color: const Color(0xFF3B82F6), // Blue
          ),
          Container(
            height: 38,
            width: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          // Time Counter
          _buildMetric(
            context: context,
            label: 'Time',
            value: formattedTime,
            icon: Icons.timer_outlined,
            color: const Color(0xFF10B981), // Emerald
          ),
          Container(
            height: 38,
            width: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          // Best Result
          _buildMetric(
            context: context,
            label: 'Best',
            value: bestResult != null ? '${bestResult!.moves} m' : '—',
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFFF59E0B), // Amber
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
