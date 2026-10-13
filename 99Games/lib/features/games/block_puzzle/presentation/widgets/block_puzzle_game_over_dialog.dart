import 'package:flutter/material.dart';

/// Modal dialog shown when no more pieces can legally fit on the board.
class BlockPuzzleGameOverDialog extends StatelessWidget {
  final int finalScore;
  final int bestScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onReturnHome;

  const BlockPuzzleGameOverDialog({
    super.key,
    required this.finalScore,
    required this.bestScore,
    required this.onPlayAgain,
    required this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isNewRecord = finalScore >= bestScore && finalScore > 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isNewRecord
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                  : const Color(0xFFEF4444).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNewRecord
                  ? Icons.emoji_events_rounded
                  : Icons.sentiment_dissatisfied_rounded,
              color: isNewRecord
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444),
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Game Over',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isNewRecord)
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
                    'NEW BEST SCORE!',
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
            'No remaining pieces can fit on the board.',
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
                    const Text('Final Score', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '$finalScore',
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
                    const Text('Best Score', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '$bestScore',
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
          onPressed: () {
            Navigator.of(context).pop();
            onReturnHome();
          },
          child: const Text('Home'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onPlayAgain();
          },
          child: const Text('Play Again'),
        ),
      ],
    );
  }
}
