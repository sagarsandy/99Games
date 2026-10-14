import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/dots_and_boxes_cubit.dart';
import '../cubit/dots_and_boxes_state.dart';
import '../domain/dots_and_boxes_models.dart';
import 'widgets/dots_and_boxes_board.dart';
import 'widgets/game_mode_selector.dart';
import 'widgets/game_score_panel.dart';

/// Main screen for Dots and Boxes mini game.
class DotsAndBoxesScreen extends StatelessWidget {
  const DotsAndBoxesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DotsAndBoxesCubit, DotsAndBoxesState>(
      builder: (context, state) {
        final cubit = context.read<DotsAndBoxesCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dots and Boxes'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Home',
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                tooltip: 'How to Play',
                onPressed: () => _showRulesDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Restart Board',
                onPressed: () => _confirmRestartGame(context, state, cubit),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Reset Scores',
                onPressed: () => _confirmResetScores(context, cubit),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Section: Settings & Scores
                        Column(
                          children: [
                            GameModeSelector(state: state, cubit: cubit),
                            const SizedBox(height: 12),
                            GameScorePanel(state: state),
                            if (state.isGameOver) ...[
                              const SizedBox(height: 10),
                              _buildGameOverBanner(context, state, cubit),
                            ],
                          ],
                        ),

                        // Center Section: Interactive Board
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 480,
                              maxHeight: constraints.maxHeight * 0.55,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: DotsAndBoxesBoard(
                                state: state,
                                cubit: cubit,
                              ),
                            ),
                          ),
                        ),

                        // Bottom Section: Play / Restart Action
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildActionButton(context, state, cubit),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameOverBanner(
    BuildContext context,
    DotsAndBoxesState state,
    DotsAndBoxesCubit cubit,
  ) {
    final String winnerTitle;
    final Color bannerColor;
    final IconData bannerIcon;

    if (state.isDraw) {
      winnerTitle = "It's a Draw!";
      bannerColor = const Color(0xFFD97706); // Amber
      bannerIcon = Icons.handshake_rounded;
    } else if (state.winner == DotsPlayer.player1) {
      winnerTitle = state.gameMode == DotsGameMode.vsAi
          ? 'Victory! You Won!'
          : 'Player 1 Wins!';
      bannerColor = const Color(0xFF10B981); // Emerald
      bannerIcon = Icons.emoji_events_rounded;
    } else {
      winnerTitle = state.gameMode == DotsGameMode.vsAi
          ? 'Computer Wins!'
          : 'Player 2 Wins!';
      bannerColor = const Color(0xFFEF4444); // Crimson
      bannerIcon = Icons.military_tech_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(bannerIcon, color: bannerColor, size: 24),
          const SizedBox(width: 10),
          Text(
            winnerTitle,
            style: TextStyle(
              color: bannerColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${state.player1Score} - ${state.player2Score})',
            style: TextStyle(
              color: bannerColor.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    DotsAndBoxesState state,
    DotsAndBoxesCubit cubit,
  ) {
    final isGameOver = state.isGameOver;

    final gradient = isGameOver
        ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
        : const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF4338CA)]);

    final shadowColor = isGameOver
        ? const Color(0xFF10B981).withValues(alpha: 0.35)
        : const Color(0xFF4F46E5).withValues(alpha: 0.3);

    final label = isGameOver ? 'Play Again' : 'New Game';
    final icon = isGameOver ? Icons.replay_rounded : Icons.refresh_rounded;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (isGameOver) {
                    cubit.restartGame();
                  } else {
                    _confirmRestartGame(context, state, cubit);
                  }
                },
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRestartGame(
    BuildContext context,
    DotsAndBoxesState state,
    DotsAndBoxesCubit cubit,
  ) async {
    if (!state.hasAnyMoveMade || state.isGameOver) {
      cubit.restartGame();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start New Game?'),
        content: const Text(
          'An active game is currently in progress. Discard current progress and start fresh?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('New Game'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.restartGame();
    }
  }

  Future<void> _confirmResetScores(
    BuildContext context,
    DotsAndBoxesCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Stats?'),
        content: const Text(
          'Are you sure you want to reset recorded wins, losses, and draws for this mode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.resetScores();
    }
  }

  void _showRulesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text('Dots and Boxes Rules'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. How to Play',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Players take turns drawing horizontal or vertical lines between two adjacent dots.',
              ),
              SizedBox(height: 10),
              Text(
                '2. Completing Boxes',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'When you place the 4th line closing a 1×1 box, you claim that box and earn 1 point.',
              ),
              SizedBox(height: 10),
              Text(
                '3. Extra Turns',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Whenever you close one or more boxes, you get an immediate extra turn! Keep chaining captures as long as you can.',
              ),
              SizedBox(height: 10),
              Text(
                '4. Winning the Game',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'The game ends when all boxes are claimed. The player with the most boxes wins!',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
