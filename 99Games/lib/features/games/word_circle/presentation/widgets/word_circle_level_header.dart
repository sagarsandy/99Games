import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/word_circle_cubit.dart';
import '../../cubit/word_circle_state.dart';
import '../../domain/word_circle_level_data.dart';

/// Top header widget displaying title, back navigation, level selector, and rules dialog.
class WordCircleLevelHeader extends StatelessWidget {
  final WordCircleState state;
  final WordCircleCubit cubit;

  const WordCircleLevelHeader({
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
            Icon(Icons.help_outline_rounded, color: Color(0xFF06B6D4)),
            SizedBox(width: 10),
            Text('How to Play'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Objective: Swipe letters on the wheel to form words and fill all crossword slots!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '• Touch and drag across the circular letters to connect them.\n'
                '• Release your finger to submit the word.\n'
                '• Valid target words fill the crossword grid above.\n'
                '• Additional valid words earn bonus points.\n'
                '• Dragging back over the previous letter retracts it.\n'
                '• Use Shuffle to get a fresh perspective, or Hint to reveal a letter.',
                style: TextStyle(fontSize: 13, height: 1.45),
              ),
            ],
          ),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Level (1–20)',
                      style: TextStyle(
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
                    itemCount: WordCircleLevelData.totalLevels,
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
                                ? const Color(0xFF06B6D4)
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
                                  ? const Color(0xFF06B6D4)
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
          // Row 1: Back, Title, Help
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => context.pop(),
                tooltip: 'Back to Home',
              ),
              Expanded(
                child: Text(
                  'Word Circle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.help_outline_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => _showHelpDialog(context),
                tooltip: 'How to Play',
              ),
            ],
          ),

          // Row 2: Level chip & Words found counter
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              ActionChip(
                avatar: const Icon(
                  Icons.spellcheck_rounded,
                  size: 16,
                  color: Color(0xFF06B6D4),
                ),
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                label: Text(
                  'Level ${state.levelNumber} / ${WordCircleLevelData.totalLevels}',
                ),
                onPressed: () => _showLevelPicker(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Text(
                  'Words: ${state.targetWordsFoundCount} / ${state.targetWordsTotalCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),
          // Level theme description
          Text(
            state.level.theme,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
