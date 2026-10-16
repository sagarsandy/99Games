import 'package:flutter/material.dart';
import '../../cubit/emoji_connect_cubit.dart';
import '../../cubit/emoji_connect_state.dart';

/// Victory dialog shown upon completing an Emoji Connect level with 100% flow.
class EmojiConnectResultsDialog extends StatelessWidget {
  final EmojiConnectState state;
  final EmojiConnectCubit cubit;
  final VoidCallback? onViewBoard;

  const EmojiConnectResultsDialog({
    super.key,
    required this.state,
    required this.cubit,
    this.onViewBoard,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasNext = state.hasNextLevel;

    final isNewRecord =
        state.bestTimeSeconds != null &&
        state.elapsedSeconds <= state.bestTimeSeconds!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top close icon to dismiss and view board
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Close and View Board',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.of(context).pop();
                onViewBoard?.call();
              },
            ),
          ),

          // Celebration Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
            ),
            child: const Center(
              child: Text('🎉', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Puzzle Solved!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            '${state.difficulty.displayName} • Level ${state.levelNumber}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Time',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(state.elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 28,
                  width: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
                Column(
                  children: [
                    const Text(
                      'Flow',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '100%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 28,
                  width: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
                Column(
                  children: [
                    const Text(
                      'Moves',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.engine.movesCount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isNewRecord) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                const Text(
                  'New Best Time!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Actions
          if (hasNext) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  cubit.nextLevel();
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Next Level',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // View Board Button (allows inspecting completed grid)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onViewBoard?.call();
              },
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('View Board'),
            ),
          ),
          const SizedBox(height: 8),

          // Play Again Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                cubit.replayLevel();
              },
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Play Again'),
            ),
          ),
        ],
      ),
    );
  }
}
