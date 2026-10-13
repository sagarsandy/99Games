import 'package:flutter/material.dart';

/// Scoreboard displaying current score and best score for Block Puzzle.
class BlockPuzzleStatsCard extends StatelessWidget {
  final int score;
  final int bestScore;

  const BlockPuzzleStatsCard({
    super.key,
    required this.score,
    required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
          // Current Score
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, size: 16, color: Color(0xFF3B82F6)),
                  SizedBox(width: 4),
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            height: 36,
            width: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          // Best Score
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Best',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '$bestScore',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
