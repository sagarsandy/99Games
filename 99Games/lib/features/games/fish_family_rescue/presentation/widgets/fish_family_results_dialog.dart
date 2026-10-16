import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/fish_family_cubit.dart';
import '../../cubit/fish_family_state.dart';
import '../../domain/fish_family_models.dart';
import '../painters/fish_painter.dart';

/// Victory dialog presented when all fish species have been sorted into their family tanks.
class FishFamilyResultsDialog extends StatelessWidget {
  final FishFamilyState state;
  final FishFamilyCubit cubit;
  final VoidCallback? onViewBoard;

  const FishFamilyResultsDialog({
    super.key,
    required this.state,
    required this.cubit,
    this.onViewBoard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasNext = state.hasNextLevel;

    final target = state.level.targetMoves;
    final moves = state.movesCount;

    // Stars calculation: 3 stars if within target, 2 stars if target + 3, 1 star otherwise
    final stars = moves <= target ? 3 : (moves <= target + 3 ? 2 : 1);

    final isNewBest = state.bestMoves == null || moves <= state.bestMoves!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button to dismiss and view completed board
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

          // Custom-Painted Cute Cartoon Happy Fish Artwork
          Container(
            width: 88,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
            ),
            child: Center(
              child: SizedBox(
                width: 68,
                height: 44,
                child: CustomPaint(
                  painter: FishPainter(
                    species: FishSpecies.getById('clownfish'),
                    expression: FishExpression.happy,
                    isSelected: false,
                    animationProgress: 0.25,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Fish Families Rescued!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            'Level ${state.levelNumber} Completed',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),

          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isFilled = index < stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 32,
                  color: isFilled
                      ? const Color(0xFFF59E0B)
                      : (isDark ? Colors.grey[700] : Colors.grey[400]),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

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
                      'Moves',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$moves',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF06B6D4),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                Column(
                  children: [
                    const Text(
                      'Target',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$target',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (state.bestMoves != null) ...[
                  Container(
                    width: 1,
                    height: 32,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Best',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.bestMoves}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (isNewBest && state.bestMoves != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '★ New Best Record! ★',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Actions
          if (hasNext)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  cubit.nextLevel();
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Next Level',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '🏆 You have mastered all 20 Fish Family Rescue levels!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    cubit.restartLevel();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Replay'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onViewBoard?.call();
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Board'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
