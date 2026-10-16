import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/fruit_catcher_state.dart';

/// Top HUD displaying Title, Back, Rules, Score, Timer, and Lives.
class FruitCatcherHud extends StatelessWidget {
  final FruitCatcherState state;

  const FruitCatcherHud({super.key, required this.state});

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sports_esports_rounded, color: Color(0xFFF59E0B)),
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
                'Objective: Catch falling fruits into your basket to score points before time runs out!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '• Drag the basket horizontally or tap left/right to move.\n'
                '• 🍎 Normal Fruits: +10 points each (Apple, Orange, Banana, Strawberry, Grapes).\n'
                '• ⭐ Golden Fruits: +50 points each.\n'
                '• 💣 Bombs: Avoid them! Each bomb costs exactly 1 life.\n'
                '• Missed fruits have no penalty.\n'
                '• You start with 3 lives and 60 seconds. Survive and achieve the highest score!',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final secondsLeft = state.timeRemaining.ceil();
    final isTimeLow = secondsLeft <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  'Fruit Catcher',
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
                onPressed: () => _showRulesDialog(context),
                tooltip: 'How to Play',
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Row 2: Status Badges (Score, Timer, Lives)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              // 1. Score Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Score: ${state.score}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (state.bestScore > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(Best: ${state.bestScore})',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 2. Timer Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isTimeLow
                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTimeLow
                        ? const Color(0xFFEF4444)
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: isTimeLow ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: isTimeLow
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Time: ${secondsLeft}s',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isTimeLow
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Lives Indicator (Hearts)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final isHeartFilled = index < state.lives;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Icon(
                        isHeartFilled
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: isHeartFilled
                            ? const Color(0xFFEF4444)
                            : (isDark
                                  ? Colors.white24
                                  : Colors.black.withValues(alpha: 0.2)),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
