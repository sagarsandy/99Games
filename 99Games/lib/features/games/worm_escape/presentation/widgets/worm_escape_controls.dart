import 'package:flutter/material.dart';
import '../../cubit/worm_escape_cubit.dart';
import '../../cubit/worm_escape_state.dart';

/// Bottom action controls for Worm Escape: Hint, Undo, Reset, or Win actions.
class WormEscapeControls extends StatelessWidget {
  final WormEscapeState state;
  final WormEscapeCubit cubit;
  final VoidCallback? onViewResults;

  const WormEscapeControls({
    super.key,
    required this.state,
    required this.cubit,
    this.onViewResults,
  });

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Level?'),
        content: const Text(
          'All escaped worms will return to their starting positions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              cubit.resetLevel();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWon = state.isWon;

    if (isWon) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Replay
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => cubit.replayLevel(),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Replay'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Results Dialog
            if (onViewResults != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewResults,
                  icon: const Icon(Icons.emoji_events_rounded, size: 18),
                  label: const Text('Results'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Next Level
            if (state.hasNextLevel)
              Expanded(
                flex: onViewResults != null ? 1 : 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => cubit.nextLevel(),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text(
                    'Next Level',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Hint Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: state.animatingWormId == null
                  ? () => cubit.requestHint()
                  : null,
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
              label: const Text('Hint'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Undo Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: state.canUndo ? () => cubit.undo() : null,
              icon: const Icon(Icons.undo_rounded, size: 20),
              label: const Text('Undo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reset Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: state.escapedWorms > 0 && state.animatingWormId == null
                  ? () => _confirmReset(context)
                  : null,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
