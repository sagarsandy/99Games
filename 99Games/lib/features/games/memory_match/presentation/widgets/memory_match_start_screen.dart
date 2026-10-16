import 'package:flutter/material.dart';
import '../../cubit/memory_match_state.dart';
import '../../domain/memory_match_models.dart';
import '../painters/memory_match_artwork_painter.dart';

/// Start overlay displayed when the player enters Memory Match,
/// showcasing sample cartoon cards, game rules, high score, and a Play button.
class MemoryMatchStartScreen extends StatelessWidget {
  final MemoryMatchState state;
  final VoidCallback onPlay;

  const MemoryMatchStartScreen({
    super.key,
    required this.state,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1B4B).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Sample Illustrated Cards Showcase
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSampleCard(CardArtworkType.apple, -0.08),
                    const SizedBox(width: 10),
                    _buildSampleCard(CardArtworkType.cat, 0.0),
                    const SizedBox(width: 10),
                    _buildSampleCard(CardArtworkType.rocket, 0.08),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. Title & Subtitle
                const Text(
                  'Memory Match',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Flip, remember, and match pairs of cartoon cards!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 18),

                // 3. Stats Badges (Current Level, Highest Unlocked, Best Score)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildStatPill(
                      icon: Icons.layers_rounded,
                      iconColor: const Color(0xFF6366F1),
                      label: 'Level ${state.currentLevel} / 20',
                      isDark: isDark,
                    ),
                    _buildStatPill(
                      icon: Icons.lock_open_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'Unlocked: ${state.highestUnlockedLevel}',
                      isDark: isDark,
                    ),
                    if (state.bestScoreForLevel > 0)
                      _buildStatPill(
                        icon: Icons.emoji_events_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Best: ${state.bestScoreForLevel} pts',
                        isDark: isDark,
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. Quick Rules summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildRuleRow(
                        Icons.touch_app_rounded,
                        'Tap cards to reveal cute cartoon illustrations.',
                        isDark,
                      ),
                      const SizedBox(height: 6),
                      _buildRuleRow(
                        Icons.check_circle_rounded,
                        'Match identical pairs to earn 10 base points each.',
                        isDark,
                      ),
                      const SizedBox(height: 6),
                      _buildRuleRow(
                        Icons.bolt_rounded,
                        'Finish fast and in fewer moves for maximum bonus!',
                        isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. Vibrant Play Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('memory_match_start_play_button'),
                    onPressed: onPlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(
                        0xFF6366F1,
                      ).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          'Play Level ${state.currentLevel}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
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

  Widget _buildSampleCard(CardArtworkType artwork, double rotation) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 62,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Center(
          child: CustomPaint(
            size: const Size(44, 44),
            painter: MemoryMatchArtworkPainter(artwork: artwork),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
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
              color: isDark ? const Color(0xFFE0E7FF) : const Color(0xFF312E81),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(IconData icon, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
