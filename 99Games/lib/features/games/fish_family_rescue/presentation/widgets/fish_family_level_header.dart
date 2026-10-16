import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/fish_family_cubit.dart';
import '../../cubit/fish_family_state.dart';
import '../../domain/fish_family_level_data.dart';
import '../../domain/fish_family_models.dart';
import '../painters/fish_painter.dart';

/// Top header widget displaying title, back navigation, level selector, and rules.
class FishFamilyLevelHeader extends StatelessWidget {
  final FishFamilyState state;
  final FishFamilyCubit cubit;

  const FishFamilyLevelHeader({
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Objective: Sort all cartoon fish into tanks until every occupied tank contains only one species!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                '• Tap a tank to select its topmost fish.\n'
                '• Tap another tank to move the fish there.\n'
                '• A move is valid if the destination tank has free space and is either EMPTY or has the SAME fish species on top.\n'
                '• Only one fish moves per turn.\n'
                '• Tap the selected tank again to deselect.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'Fish Families:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: FishSpecies.allSpecies.map((sp) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 22,
                        child: CustomPaint(
                          painter: FishPainter(
                            species: sp,
                            animationProgress: 0.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sp.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }).toList(),
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
                    itemCount: FishFamilyLevelData.totalLevels,
                    itemBuilder: (context, index) {
                      final lvl = index + 1;
                      final isUnlocked = lvl <= state.unlockedLevel;
                      final isCompleted = state.completedLevels.contains(lvl);
                      final isCurrent = lvl == state.levelNumber;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isUnlocked && !state.isAnimating
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
          // Row 1: Back, Title, How to Play
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
                  'Fish Family Rescue',
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

          // Row 2: Level chip & level title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(
                  Icons.water_drop_rounded,
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
                  'Level ${state.levelNumber} / ${FishFamilyLevelData.totalLevels}',
                ),
                onPressed: !state.isAnimating
                    ? () => _showLevelPicker(context)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          // Short description / level subtitle
          Text(
            state.level.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            state.level.description,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
