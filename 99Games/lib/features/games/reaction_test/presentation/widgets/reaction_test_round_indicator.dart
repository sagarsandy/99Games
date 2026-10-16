import 'package:flutter/material.dart';
import '../../cubit/reaction_test_state.dart';

/// Visual header indicator showing round progression across the 5-round challenge.
class ReactionTestRoundIndicator extends StatelessWidget {
  final ReactionTestState state;

  const ReactionTestRoundIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Round ${state.currentRound} of ${state.totalRounds}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              if (state.stats.bestSingleMs != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Best: ${state.stats.bestSingleMs} ms',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(state.totalRounds, (index) {
              final roundNum = index + 1;
              final isCurrent = roundNum == state.currentRound;

              // Check if outcome exists for this round
              final outcome = state.roundOutcomes.cast<dynamic>().firstWhere(
                (o) => o.roundNumber == roundNum,
                orElse: () => null,
              );

              Color dotColor;
              IconData? icon;

              if (outcome != null) {
                if (outcome.isFalseStart) {
                  dotColor = const Color(0xFFEF4444); // Red
                  icon = Icons.close_rounded;
                } else {
                  dotColor = const Color(0xFF10B981); // Emerald
                  icon = Icons.check_rounded;
                }
              } else if (isCurrent) {
                dotColor = theme.colorScheme.primary;
              } else {
                dotColor = isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.12);
              }

              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == state.totalRounds - 1 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: icon != null
                      ? Center(child: Icon(icon, size: 8, color: Colors.white))
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
