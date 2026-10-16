import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/memory_match_cubit.dart';
import '../../cubit/memory_match_state.dart';
import '../../domain/memory_match_level_data.dart';

/// Top HUD for Memory Match displaying level info, pairs matched,
/// moves count, timer, current score, rules modal, and restart button.
class MemoryMatchHud extends StatelessWidget {
  final MemoryMatchState state;

  const MemoryMatchHud({super.key, required this.state});

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.psychology_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('How to Play'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Objective: Find all matching pairs of cartoon cards in the fewest moves and fastest time!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '• Tap a face-down card to reveal its cartoon illustration.\n'
                '• Tap a second face-down card to check for a match.\n'
                '• If both cards match, they stay face-up and you score base points!\n'
                '• If they mismatch, they flip back face-down after a brief glance.\n'
                '• Scoring Formula:\n'
                '   - Base Points: +10 pts per matched pair.\n'
                '   - Efficiency Bonus: Up to +50 pts for completing in fewer moves.\n'
                '   - Time Bonus: Up to +50 pts for fast matching (target 8s per pair).\n'
                '• Beat all 20 curated levels from 2×2 up to 5×6 grids!',
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

  void _showLevelSelector(BuildContext context) {
    final cubit = context.read<MemoryMatchCubit>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Select Level',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: MemoryMatchLevelData.totalLevels,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                    itemBuilder: (context, index) {
                      final lvl = index + 1;
                      final isUnlocked = lvl <= state.highestUnlockedLevel;
                      final isCurrent = lvl == state.currentLevel;

                      return InkWell(
                        onTap: isUnlocked
                            ? () {
                                Navigator.of(ctx).pop();
                                cubit.startLevel(lvl);
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF6366F1)
                                : isUnlocked
                                ? const Color(0xFFEEF2FF)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF4338CA)
                                  : isUnlocked
                                  ? const Color(0xFFC7D2FE)
                                  : Colors.grey.withValues(alpha: 0.3),
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isUnlocked
                              ? Text(
                                  '$lvl',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent
                                        ? Colors.white
                                        : const Color(0xFF312E81),
                                  ),
                                )
                              : const Icon(
                                  Icons.lock_rounded,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Back, Title, Level Selector chip, Rules & Restart
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => context.pop(),
                tooltip: 'Back to Home',
              ),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Memory Match',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showLevelSelector(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lvl ${state.currentLevel}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 16,
                              color: Color(0xFF6366F1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () =>
                    context.read<MemoryMatchCubit>().restartLevel(),
                tooltip: 'Restart Level',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.help_outline_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => _showRulesDialog(context),
                tooltip: 'How to Play',
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Row 2: Status Chips (Pairs progress, Moves, Time, Current Score)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              // 1. Matched Pairs Badge
              _buildPill(
                isDark: isDark,
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF10B981),
                label: '${state.matchedPairs}/${state.totalPairs} Pairs',
              ),

              // 2. Moves Badge
              _buildPill(
                isDark: isDark,
                icon: Icons.touch_app_rounded,
                iconColor: const Color(0xFF3B82F6),
                label: '${state.moves} Moves',
              ),

              // 3. Timer Badge
              _buildPill(
                isDark: isDark,
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFFF59E0B),
                label: _formatTime(state.elapsedSeconds),
              ),

              // 4. Current Score Badge
              _buildPill(
                isDark: isDark,
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFEAB308),
                label: '${state.currentScore} pts',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
