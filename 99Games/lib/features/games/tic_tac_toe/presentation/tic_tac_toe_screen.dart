import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/tic_tac_toe_cubit.dart';
import '../cubit/tic_tac_toe_state.dart';
import '../domain/tic_tac_toe_models.dart';
import 'widgets/tic_tac_toe_board.dart';
import 'widgets/tic_tac_toe_scoreboard.dart';
import 'widgets/tic_tac_toe_status_banner.dart';

/// The main Tic-Tac-Toe game screen.
class TicTacToeScreen extends StatelessWidget {
  const TicTacToeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicTacToeCubit, TicTacToeState>(
      builder: (context, state) {
        final cubit = context.read<TicTacToeCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tic-Tac-Toe'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Home',
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: 'Restart Board',
                onPressed: () => cubit.restartGame(),
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
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Section: Mode selector & difficulty
                        Column(
                          children: [
                            _buildModeSelector(context, state, cubit),
                            if (state.gameMode == GameMode.vsAi) ...[
                              const SizedBox(height: 12),
                              _buildDifficultySelector(context, state, cubit),
                            ],
                            const SizedBox(height: 14),
                            TicTacToeScoreboard(
                              gameMode: state.gameMode,
                              currentPlayer: state.currentPlayer,
                              stats: state.stats,
                              isAiThinking: state.isAiThinking,
                            ),
                            const SizedBox(height: 12),
                            TicTacToeStatusBanner(
                              status: state.status,
                              currentPlayer: state.currentPlayer,
                              winner: state.winner,
                              gameMode: state.gameMode,
                              isAiThinking: state.isAiThinking,
                            ),
                          ],
                        ),

                        // Center Section: 3x3 Game Board
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: TicTacToeBoard(
                            board: state.board,
                            winningIndices: state.winningIndices,
                            isInteractive:
                                !state.isGameOver && !state.isAiThinking,
                            onCellTapped: (index) => cubit.makeMove(index),
                          ),
                        ),

                        // Bottom Section: Actions
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildActionButtons(context, state, cubit),
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

  Widget _buildModeSelector(
    BuildContext context,
    TicTacToeState state,
    TicTacToeCubit cubit,
  ) {
    return SegmentedButton<GameMode>(
      segments: const [
        ButtonSegment<GameMode>(
          value: GameMode.vsAi,
          label: Text('vs Computer'),
          icon: Icon(Icons.smart_toy_rounded, size: 18),
        ),
        ButtonSegment<GameMode>(
          value: GameMode.passAndPlay,
          label: Text('2 Players'),
          icon: Icon(Icons.people_alt_rounded, size: 18),
        ),
      ],
      selected: {state.gameMode},
      onSelectionChanged: (newSelection) {
        cubit.setGameMode(newSelection.first);
      },
    );
  }

  Widget _buildDifficultySelector(
    BuildContext context,
    TicTacToeState state,
    TicTacToeCubit cubit,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? const Color(0xFF334155) // Slate-700
        : const Color(0xFF64748B); // Slate-500

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: AiDifficulty.values.map((difficulty) {
        final isSelected = state.aiDifficulty == difficulty;
        return ChoiceChip(
          label: Text(
            difficulty.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          selected: isSelected,
          showCheckmark: false,
          selectedColor: const Color(0xFF4F46E5),
          backgroundColor: unselectedBg,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (selected) {
            if (selected) {
              cubit.setAiDifficulty(difficulty);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    TicTacToeState state,
    TicTacToeCubit cubit,
  ) {
    final isGameOver = state.isGameOver;

    final gradient = isGameOver
        ? const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)], // Emerald victory
          )
        : const LinearGradient(
            colors: [
              Color(0xFF2563EB),
              Color(0xFF1D4ED8),
            ], // Electric royal blue
          );

    final shadowColor = isGameOver
        ? const Color(0xFF10B981).withValues(alpha: 0.35)
        : const Color(0xFF2563EB).withValues(alpha: 0.3);

    final label = isGameOver ? 'Play Again' : 'Restart Board';
    final icon = isGameOver ? Icons.replay_rounded : Icons.refresh_rounded;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => cubit.restartGame(),
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

  Future<void> _confirmResetScores(
    BuildContext context,
    TicTacToeCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Scores?'),
        content: const Text(
          'Are you sure you want to reset all tracked wins, losses, and draws for this game mode?',
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
}
