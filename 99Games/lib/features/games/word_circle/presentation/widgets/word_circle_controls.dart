import 'package:flutter/material.dart';
import '../../cubit/word_circle_cubit.dart';
import '../../cubit/word_circle_state.dart';

/// Control bar with Shuffle, Hint, Clear, Restart, and current score for Word Circle.
class WordCircleControls extends StatelessWidget {
  final WordCircleState state;
  final WordCircleCubit cubit;
  final VoidCallback? onViewResults;

  const WordCircleControls({
    super.key,
    required this.state,
    required this.cubit,
    this.onViewResults,
  });

  void _confirmRestart(BuildContext context) {
    if (state.score == 0 && state.foundTargetWords.isEmpty) {
      cubit.restartLevel();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restart Level?'),
        content: const Text(
          'Your progress and found words on this level will be reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(ctx).pop();
              cubit.restartLevel();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View results banner if puzzle is solved
                if (state.isWon && onViewResults != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onViewResults,
                      icon: const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFBBF24),
                        size: 20,
                      ),
                      label: const Text(
                        'Level Complete! View Results',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Row 1: Score & Bonus words badge
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Score: ${state.score}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (state.bestScore != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(Best: ${state.bestScore})',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (state.bonusWordsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.card_giftcard_rounded,
                              size: 15,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Bonus: ${state.bonusWordsCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Action buttons (Shuffle, Hint, Clear, Restart)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.shuffle_rounded,
                        label: 'Shuffle',
                        onPressed: () => cubit.shuffleWheel(),
                        isDark: isDark,
                      ),
                      _buildControlButton(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Hint',
                        onPressed: () => cubit.useHint(),
                        isDark: isDark,
                        iconColor: const Color(0xFFF59E0B),
                      ),
                      _buildControlButton(
                        icon: Icons.backspace_outlined,
                        label: 'Clear',
                        onPressed: state.selectedLetterIds.isNotEmpty
                            ? () => cubit.clearSelection()
                            : null,
                        isDark: isDark,
                      ),
                      _buildControlButton(
                        icon: Icons.refresh_rounded,
                        label: 'Restart',
                        onPressed: () => _confirmRestart(context),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isDark,
    Color? iconColor,
  }) {
    final disabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: disabled
                    ? (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05))
                    : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0)),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: disabled
                    ? (isDark ? Colors.white30 : Colors.black26)
                    : (iconColor ??
                          (isDark ? Colors.white : const Color(0xFF0F172A))),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: disabled
                    ? (isDark ? Colors.white30 : Colors.black26)
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
