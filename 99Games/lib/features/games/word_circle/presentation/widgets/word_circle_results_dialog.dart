import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/word_circle_cubit.dart';
import '../../cubit/word_circle_state.dart';

/// Modal dialog shown when a Word Circle level is successfully solved.
class WordCircleResultsDialog extends StatelessWidget {
  final WordCircleState state;
  final WordCircleCubit cubit;
  final VoidCallback onViewBoard;

  const WordCircleResultsDialog({
    super.key,
    required this.state,
    required this.cubit,
    required this.onViewBoard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFF59E0B),
              size: 48,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Level Complete!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Level ${state.levelNumber}: ${state.level.theme}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildStatRow(
                  label: 'Target Words Solved',
                  value:
                      '${state.targetWordsFoundCount} / ${state.targetWordsTotalCount}',
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF10B981),
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _buildStatRow(
                  label: 'Bonus Words Found',
                  value: '${state.bonusWordsCount}',
                  icon: Icons.card_giftcard_rounded,
                  iconColor: const Color(0xFF06B6D4),
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _buildStatRow(
                  label: 'Final Score',
                  value: '${state.score} pts',
                  icon: Icons.stars_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  isDark: isDark,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onViewBoard();
            },
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('View Solved Crossword'),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop(); // Back to Home
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Home'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  cubit.restartLevel();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Replay'),
              ),
            ),
            if (state.hasNextLevel) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    cubit.nextLevel();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
