import 'package:flutter/material.dart';
import '../../cubit/fruit_catcher_state.dart';
import '../../domain/fruit_catcher_models.dart';
import '../painters/basket_painter.dart';
import '../painters/fruit_item_painter.dart';

/// Overlay presented before a round starts, showing instructions, high score, and Play button.
class FruitCatcherStartOverlay extends StatelessWidget {
  final FruitCatcherState state;
  final VoidCallback onStart;

  const FruitCatcherStartOverlay({
    super.key,
    required this.state,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                    : const Color(0xFF0284C7).withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Illustrated Preview (Basket with fruits above it)
                SizedBox(
                  width: double.infinity,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Floating fruits above basket
                      const Align(
                        alignment: Alignment(0.0, -0.75),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CustomPaint(
                                painter: FruitItemPainter(
                                  type: FruitType.apple,
                                  radius: 15,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 42,
                              height: 42,
                              child: CustomPaint(
                                painter: FruitItemPainter(
                                  type: FruitType.golden,
                                  radius: 18,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CustomPaint(
                                painter: FruitItemPainter(
                                  type: FruitType.orange,
                                  radius: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Basket at bottom
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: 130,
                          height: 48,
                          child: CustomPaint(
                            painter: BasketPainter(isDark: isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Title
                Text(
                  'Fruit Catcher',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  'Catch juicy fruits into your basket before the 60s timer expires!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Best Score Pill
                if (state.bestScore > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 18,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Best Score: ${state.bestScore}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Quick Rules Guide Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildRuleRow(
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        text: 'Normal Fruit: +10 pts',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 6),
                      _buildRuleRow(
                        icon: Icons.star_rounded,
                        color: const Color(0xFFF59E0B),
                        text: 'Golden Fruit: +50 pts',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 6),
                      _buildRuleRow(
                        icon: Icons.dangerous_rounded,
                        color: const Color(0xFFEF4444),
                        text: 'Avoid Bombs: -1 Life',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 5. Prominent Play Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    key: const Key('fruit_catcher_start_play_button'),
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded, size: 26),
                    label: const Text(
                      'Play',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
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

  Widget _buildRuleRow({
    required IconData icon,
    required Color color,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
