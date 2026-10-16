import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/reaction_test_cubit.dart';
import '../../cubit/reaction_test_state.dart';
import '../../domain/reaction_test_engine.dart';

/// Full results screen presented upon finishing all 5 rounds of Reaction Test.
class ReactionTestResults extends StatelessWidget {
  final ReactionTestState state;
  final ReactionTestCubit cubit;

  const ReactionTestResults({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = state.sessionSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Trophy Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.7,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                summary.isAllFalseStarts
                    ? Icons.sentiment_dissatisfied_rounded
                    : Icons.emoji_events_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            summary.isAllFalseStarts
                ? 'Challenge Incomplete'
                : 'Challenge Complete!',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle / Average
          if (summary.isAllFalseStarts)
            Text(
              'No valid reaction times recorded',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            Text(
              'Average Reaction Time',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ReactionTestEngine.formatAverage(summary.averageMs),
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (summary.averageCategory != null) ...[
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    summary.averageCategory!.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],

          // New Record Banner
          if (state.isNewBestSingle || state.isNewBestAverage) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '🎉 New Personal Best Achieved!',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Overview Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme,
                  isDark,
                  title: 'Fastest',
                  value: ReactionTestEngine.formatMs(summary.fastestMs),
                  icon: Icons.flash_on_rounded,
                  iconColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  isDark,
                  title: 'Slowest',
                  value: ReactionTestEngine.formatMs(summary.slowestMs),
                  icon: Icons.timelapse_rounded,
                  iconColor: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme,
                  isDark,
                  title: 'Valid Taps',
                  value: '${summary.validCount} / ${state.totalRounds}',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  isDark,
                  title: 'False Starts',
                  value: '${summary.falseStartCount}',
                  icon: Icons.error_outline_rounded,
                  iconColor: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Round Breakdown Header
          Text(
            'Round Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // All 5 Rounds in Chronological Order
          ...state.roundOutcomes.map((outcome) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: outcome.isFalseStart
                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                          : const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${outcome.roundNumber}',
                        style: TextStyle(
                          color: outcome.isFalseStart
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      outcome.isFalseStart
                          ? 'False Start'
                          : '${outcome.reactionTimeMs} ms',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: outcome.isFalseStart
                            ? const Color(0xFFEF4444)
                            : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: outcome.isFalseStart
                          ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      outcome.category.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: outcome.isFalseStart
                            ? const Color(0xFFEF4444)
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Personal Best Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Best Records',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fastest: ${ReactionTestEngine.formatMs(state.stats.bestSingleMs)}  •  Best Avg: ${ReactionTestEngine.formatAverage(state.stats.bestSessionAverageMs)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons: Play Again & Back to Home
          FilledButton.icon(
            onPressed: cubit.playAgain,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.replay_rounded),
            label: const Text(
              'Play Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.home_rounded),
            label: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    bool isDark, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
