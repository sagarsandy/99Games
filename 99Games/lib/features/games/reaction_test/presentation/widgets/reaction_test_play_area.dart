import 'package:flutter/material.dart';
import '../../cubit/reaction_test_cubit.dart';
import '../../cubit/reaction_test_state.dart';
import '../../domain/reaction_test_models.dart';

/// The primary touch surface measuring the player's reaction time.
class ReactionTestPlayArea extends StatelessWidget {
  final ReactionTestState state;
  final ReactionTestCubit cubit;

  const ReactionTestPlayArea({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine visual colors and content based on current phase
    final Color backgroundColor;
    final Widget content;

    switch (state.phase) {
      case ReactionPhase.waiting:
        backgroundColor = const Color(0xFFDC2626); // High contrast vibrant red
        content = _buildWaitingContent(theme);
        break;

      case ReactionPhase.green:
        backgroundColor = const Color(
          0xFF16A34A,
        ); // High contrast vibrant green
        content = _buildGreenContent(theme);
        break;

      case ReactionPhase.falseStart:
        backgroundColor = const Color(0xFF991B1B); // Deep crimson warning
        content = _buildFalseStartContent(theme);
        break;

      case ReactionPhase.roundResult:
        backgroundColor = const Color(0xFF065F46); // Deep emerald result
        content = _buildRoundResultContent(theme);
        break;

      case ReactionPhase.intro:
      case ReactionPhase.completed:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        content = const SizedBox.shrink();
        break;
    }

    final bool canTapArea =
        state.phase == ReactionPhase.waiting ||
        state.phase == ReactionPhase.green;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          // Use onTapDown for immediate touch contact timestamp registration
          behavior: HitTestBehavior.opaque,
          onTapDown: canTapArea ? (_) => cubit.handlePlayAreaTap() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            width: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.hourglass_top_rounded,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Wait for green...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Do not tap yet!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGreenContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt_rounded, size: 72, color: Colors.white),
        ),
        const SizedBox(height: 28),
        const Text(
          'TAP NOW!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap anywhere as fast as you can!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFalseStartContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Too early!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You tapped before the screen turned green.\nThis round counts as a false start.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildRoundResultContent(ThemeData theme) {
    final ms = state.latestReactionMs ?? 0;
    final category = ReactionCategory.fromMs(ms);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.timer_rounded, size: 54, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          '$ms ms',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            category.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (state.isLatestFastestInSession) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Fastest this session!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
