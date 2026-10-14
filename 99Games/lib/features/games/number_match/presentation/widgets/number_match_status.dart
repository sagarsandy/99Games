import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/number_match_cubit.dart';
import '../../cubit/number_match_state.dart';

/// Status header for Number Match displaying Score, Pairs Cleared, Timer, and Best Score.
class NumberMatchStatus extends StatelessWidget {
  final NumberMatchState state;

  const NumberMatchStatus({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Top status pills row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Score Pill
            _buildPill(
              context: context,
              icon: Icons.stars_rounded,
              iconColor: const Color(0xFF6366F1),
              label: 'Score',
              value: '${state.score}',
            ),

            // Pairs Cleared Pill
            _buildPill(
              context: context,
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF10B981),
              label: 'Pairs',
              value: '${state.pairsCleared}',
            ),

            // Best Score Pill (if available)
            if (state.stats.bestScore > 0)
              _buildPill(
                context: context,
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFF59E0B),
                label: 'Best',
                value: '${state.stats.bestScore}',
              ),

            // Timer Pill (isolated)
            const NumberMatchTimerPill(),
          ],
        ),

        // Feedback / hint / warning message banner
        if (state.feedbackMessage != null &&
            state.feedbackMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.6)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.feedbackMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPill({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

/// An isolated timer pill that only rebuilds when elapsedSeconds changes.
class NumberMatchTimerPill extends StatelessWidget {
  const NumberMatchTimerPill({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocSelector<NumberMatchCubit, NumberMatchState, int>(
      selector: (state) => state.elapsedSeconds,
      builder: (context, elapsedSeconds) {
        final hours = elapsedSeconds ~/ 3600;
        final minutes = (elapsedSeconds % 3600) ~/ 60;
        final seconds = elapsedSeconds % 60;

        final mStr = minutes.toString().padLeft(2, '0');
        final sStr = seconds.toString().padLeft(2, '0');
        final formattedTime = hours > 0
            ? '${hours.toString().padLeft(2, '0')}:$mStr:$sStr'
            : '$mStr:$sStr';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 15,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              const SizedBox(width: 4),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
