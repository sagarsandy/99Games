import 'package:flutter/material.dart';
import 'package:mini_games_99/core/storage/game_stats_storage.dart';

/// Modal dialog shown upon puzzle completion.
class NumberSlideVictoryDialog extends StatelessWidget {
  final int moves;
  final String formattedTime;
  final NumberSlideBestResult? bestResult;
  final VoidCallback onNewGame;

  const NumberSlideVictoryDialog({
    super.key,
    required this.moves,
    required this.formattedTime,
    required this.bestResult,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isNewBest = bestResult != null && bestResult!.moves == moves;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFF10B981),
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Puzzle Solved!',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isNewBest)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'NEW BEST RECORD!',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'Magnificent! You arranged all 15 tiles into numerical order.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Moves', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '$moves',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                Column(
                  children: [
                    const Text('Time', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Review Board'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onNewGame();
          },
          child: const Text('New Game'),
        ),
      ],
    );
  }
}
