import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/emoji_connect_cubit.dart';
import '../../cubit/emoji_connect_state.dart';
import '../../domain/emoji_connect_level_data.dart';
import '../../domain/emoji_connect_models.dart';

/// Header widget displaying app bar, difficulty selector, level selector, and live progress indicators.
class EmojiConnectLevelHeader extends StatelessWidget {
  final EmojiConnectState state;
  final EmojiConnectCubit cubit;

  const EmojiConnectLevelHeader({
    super.key,
    required this.state,
    required this.cubit,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('How to Play'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Drag between matching emojis to connect each pair.\n'
              '• Paths move only horizontally or vertically (no diagonals).\n'
              '• Paths cannot overlap each other or pass through other emojis.\n'
              '• Every cell on the board must be covered by a completed path to win!',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showLevelPicker(BuildContext context) {
    final levels = EmojiConnectLevelData.getLevelsForDifficulty(
      state.difficulty,
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${state.difficulty.displayName} Levels',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(levels.length, (index) {
                    final lvl = index + 1;
                    final isUnlocked = lvl <= state.unlockedLevel;
                    final isCurrent = lvl == state.levelNumber;
                    final isDone = state.completedLevels.contains(lvl);

                    return InkWell(
                      onTap: isUnlocked
                          ? () {
                              cubit.selectLevel(lvl);
                              Navigator.of(ctx).pop();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF6366F1)
                              : (isDone
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.15)
                                    : (isUnlocked
                                          ? Colors.grey.withValues(alpha: 0.15)
                                          : Colors.grey.withValues(
                                              alpha: 0.08,
                                            ))),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF4F46E5)
                                : (isDone
                                      ? const Color(0xFF10B981)
                                      : Colors.transparent),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isUnlocked
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$lvl',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent
                                            ? Colors.white
                                            : (isDone
                                                  ? const Color(0xFF10B981)
                                                  : null),
                                      ),
                                    ),
                                    if (isDone)
                                      Icon(
                                        Icons.check_rounded,
                                        size: 12,
                                        color: isCurrent
                                            ? Colors.white
                                            : const Color(0xFF10B981),
                                      ),
                                  ],
                                )
                              : const Icon(
                                  Icons.lock_rounded,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final covered = state.coveredCells;
    final totalCells = state.totalCells;
    final coveragePercent = totalCells > 0 ? (covered * 100 ~/ totalCells) : 0;
    final connected = state.connectedPairs;
    final totalPairs = state.totalPairs;

    return Column(
      children: [
        // Top Bar
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Home',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            const SizedBox(width: 4),
            const Text(
              'Emoji Connect',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'How to Play',
              onPressed: () => _showHelpDialog(context),
            ),
          ],
        ),

        // Difficulty & Level Selector Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Segmented Difficulty Selector
              Expanded(
                child: SegmentedButton<EmojiConnectDifficulty>(
                  segments: const [
                    ButtonSegment(
                      value: EmojiConnectDifficulty.easy,
                      label: Text('Easy', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: EmojiConnectDifficulty.medium,
                      label: Text('Med', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: EmojiConnectDifficulty.hard,
                      label: Text('Hard', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {state.difficulty},
                  onSelectionChanged: (selected) {
                    cubit.selectDifficulty(selected.first);
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Level button
              InkWell(
                onTap: () => _showLevelPicker(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Level ${state.levelNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress indicators card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Pairs Connected
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$connected / $totalPairs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: connected == totalPairs
                            ? const Color(0xFF10B981)
                            : null,
                      ),
                    ),
                    Text(
                      'Pairs Connected',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                Container(
                  height: 24,
                  width: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),

                // Flow / Cell Coverage
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$coveragePercent%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: coveragePercent == 100
                            ? const Color(0xFF10B981)
                            : null,
                      ),
                    ),
                    Text(
                      'Board Flow',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                Container(
                  height: 24,
                  width: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),

                // Timer
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(state.elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      state.bestTimeSeconds != null
                          ? 'Best: ${_formatTime(state.bestTimeSeconds!)}'
                          : 'Time',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
