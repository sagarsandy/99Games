import 'package:flutter/material.dart';
import '../../cubit/reaction_test_cubit.dart';
import '../../cubit/reaction_test_state.dart';
import '../../domain/reaction_test_models.dart';

/// Control buttons and bottom action bar for the Reaction Test game.
class ReactionTestControls extends StatelessWidget {
  final ReactionTestState state;
  final ReactionTestCubit cubit;

  const ReactionTestControls({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showContinue =
        state.phase == ReactionPhase.roundResult ||
        state.phase == ReactionPhase.falseStart;

    if (!showContinue) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Text(
          state.phase == ReactionPhase.waiting
              ? 'Prepare to tap as soon as the screen flashes green!'
              : 'Tap anywhere inside the green box!',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final isLastRound = state.currentRound >= state.totalRounds;
    final buttonLabel = isLastRound ? 'View Results' : 'Continue to Next Round';
    final buttonIcon = isLastRound
        ? Icons.assessment_rounded
        : Icons.arrow_forward_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: cubit.continueToNextRound,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(buttonIcon),
          label: Text(
            buttonLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
