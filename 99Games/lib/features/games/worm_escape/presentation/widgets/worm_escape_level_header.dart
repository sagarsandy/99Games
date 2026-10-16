import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/worm_escape_cubit.dart';
import '../../cubit/worm_escape_state.dart';
import '../../domain/worm_escape_level_data.dart';
import '../../domain/worm_escape_models.dart';

/// Header widget displaying back navigation, difficulty selector, level picker, and escape progress.
class WormEscapeLevelHeader extends StatelessWidget {
  final WormEscapeState state;
  final WormEscapeCubit cubit;

  const WormEscapeLevelHeader({
    super.key,
    required this.state,
    required this.cubit,
  });

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('How to Play'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Goal:\nHelp all worms escape the grid!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '🐛 Worm Directions:\nEach colorful worm has an expressive head with eyes looking in its fixed escape direction.',
            ),
            SizedBox(height: 10),
            Text(
              '👆 Tap to Crawl:\nTap any segment of a worm to send it crawling straight forward off the board.',
            ),
            SizedBox(height: 10),
            Text(
              '🛑 Clear the Blockers:\nIf another active worm is in the way, it cannot escape! Free up the blocking worms in the correct order.',
            ),
            SizedBox(height: 10),
            Text(
              '💡 Hints & Undo:\nUse Hint when stuck to highlight a worm with a clear path, or Undo to backtrack a move.',
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showLevelPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final totalCount = WormEscapeLevelData.getLevelCount(state.difficulty);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      final lvl = index + 1;
                      final isUnlocked = lvl <= state.unlockedLevel;
                      final isCompleted = state.completedLevels.contains(lvl);
                      final isCurrent = lvl == state.levelNumber;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isUnlocked
                            ? () {
                                Navigator.of(ctx).pop();
                                cubit.selectLevel(lvl);
                              }
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF10B981)
                                : (isCompleted
                                      ? const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.15)
                                      : (isUnlocked
                                            ? Theme.of(context).cardColor
                                            : Colors.grey.withValues(
                                                alpha: 0.1,
                                              ))),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF10B981)
                                  : (isCompleted
                                        ? const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.4)
                                        : Colors.grey.withValues(alpha: 0.2)),
                              width: isCurrent ? 2 : 1,
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
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent
                                              ? Colors.white
                                              : (isCompleted
                                                    ? const Color(0xFF10B981)
                                                    : null),
                                        ),
                                      ),
                                      if (isCompleted && !isCurrent) ...[
                                        const SizedBox(height: 2),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 11,
                                          color: Color(0xFF10B981),
                                        ),
                                      ],
                                    ],
                                  )
                                : const Icon(
                                    Icons.lock_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // Row 1: Back, Title, How to Play
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
              const Expanded(
                child: Text(
                  'Worm Escape',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                tooltip: 'How to Play',
                onPressed: () => _showHelpDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Row 2: Difficulty selector & Level picker
          Row(
            children: [
              // Segmented Difficulty Selector
              Expanded(
                flex: 3,
                child: SegmentedButton<WormEscapeDifficulty>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: WormEscapeDifficulty.easy,
                      label: Text('Easy', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: WormEscapeDifficulty.medium,
                      label: Text('Med', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: WormEscapeDifficulty.hard,
                      label: Text('Hard', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {state.difficulty},
                  onSelectionChanged: (set) {
                    cubit.selectDifficulty(set.first);
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Level Picker Chip
              ActionChip(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                avatar: const Icon(
                  Icons.format_list_numbered_rounded,
                  size: 16,
                ),
                label: Text(
                  'Level ${state.levelNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () => _showLevelPicker(context),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 3: Escaped Counter, Moves, Best
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Worms Escaped
                Column(
                  children: [
                    const Text(
                      'Escaped',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.escapedWorms} / ${state.totalWorms}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
                // Moves
                Column(
                  children: [
                    const Text(
                      'Moves',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.movesCount}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (state.bestMoves != null) ...[
                  Container(
                    height: 24,
                    width: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                  // Best Moves
                  Column(
                    children: [
                      const Text(
                        'Best',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.bestMoves}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
