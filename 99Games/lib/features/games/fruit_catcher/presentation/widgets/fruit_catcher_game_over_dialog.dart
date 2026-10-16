import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/fruit_catcher_cubit.dart';
import '../../cubit/fruit_catcher_state.dart';

/// Overlay presented when the round ends (time up or lives lost).
class FruitCatcherGameOverDialog extends StatelessWidget {
  final FruitCatcherState state;
  final FruitCatcherCubit cubit;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onBackToGames;

  const FruitCatcherGameOverDialog({
    super.key,
    required this.state,
    required this.cubit,
    this.onPlayAgain,
    this.onBackToGames,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTimeUp = state.timeRemaining <= 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: state.isNewRecord
                    ? const Color(0xFFF59E0B)
                    : (isDark
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                          : const Color(0xFF0284C7).withValues(alpha: 0.2)),
                width: state.isNewRecord ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: state.isNewRecord
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Icon badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: state.isNewRecord
                          ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                          : (isTimeUp
                                ? [
                                    const Color(0xFF38BDF8),
                                    const Color(0xFF0284C7),
                                  ]
                                : [
                                    const Color(0xFFF87171),
                                    const Color(0xFFDC2626),
                                  ]),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (state.isNewRecord
                                    ? const Color(0xFFF59E0B)
                                    : (isTimeUp
                                          ? const Color(0xFF0284C7)
                                          : const Color(0xFFDC2626)))
                                .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    state.isNewRecord
                        ? Icons.emoji_events_rounded
                        : (isTimeUp
                              ? Icons.timer_off_rounded
                              : Icons.heart_broken_rounded),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Title
                const Text(
                  'Game Over',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // 3. Subtitle / Reason
                Text(
                  isTimeUp
                      ? "Time's up! Great effort catching fruits!"
                      : 'You ran out of lives! Beware of bombs!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // 4. New Record banner if achieved
                if (state.isNewRecord) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.celebration_rounded,
                          color: Color(0xFFB45309),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'NEW BEST RECORD!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.celebration_rounded,
                          color: Color(0xFFB45309),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 5. Score Board
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Final Score
                      Column(
                        children: [
                          Text(
                            'FINAL SCORE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${state.score}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: state.isNewRecord
                                  ? const Color(0xFFF59E0B)
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 44,
                        width: 1,
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      // Best Score
                      Column(
                        children: [
                          Text(
                            'BEST SCORE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${state.bestScore}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0EA5E9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('fruit_catcher_play_again_button'),
                    onPressed: () {
                      if (onPlayAgain != null) {
                        onPlayAgain!();
                      } else {
                        cubit.playAgain();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(
                        0xFF10B981,
                      ).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.replay_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Play Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    key: const Key('fruit_catcher_back_to_games_button'),
                    onPressed: () {
                      if (onBackToGames != null) {
                        onBackToGames!();
                      } else {
                        context.pop();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Back to Games',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
