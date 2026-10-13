import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/block_puzzle_cubit.dart';
import '../cubit/block_puzzle_state.dart';
import '../domain/block_puzzle_engine.dart';
import 'widgets/block_puzzle_board.dart';
import 'widgets/block_puzzle_game_over_dialog.dart';
import 'widgets/block_puzzle_stats_card.dart';
import 'widgets/piece_tray.dart';

/// The main Block Puzzle game screen.
class BlockPuzzleScreen extends StatelessWidget {
  const BlockPuzzleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = BlockPuzzleEngine();

    return BlocConsumer<BlockPuzzleCubit, BlockPuzzleState>(
      listenWhen: (prev, current) => !prev.isGameOver && current.isGameOver,
      listener: (context, state) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => BlockPuzzleGameOverDialog(
            finalScore: state.score,
            bestScore: state.bestScore,
            onPlayAgain: () => context.read<BlockPuzzleCubit>().startNewGame(),
            onReturnHome: () => context.pop(),
          ),
        );
      },
      builder: (context, state) {
        final cubit = context.read<BlockPuzzleCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Block Puzzle'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Home',
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'New Game',
                onPressed: () => _handleNewGame(context, state, cubit),
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
                        // Top Section: Scoreboard & Hint banner
                        Column(
                          children: [
                            BlockPuzzleStatsCard(
                              score: state.score,
                              bestScore: state.bestScore,
                            ),
                            const SizedBox(height: 10),
                            _buildInstructionBanner(context, state),
                          ],
                        ),

                        // Center Section: 10x10 Board
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: BlockPuzzleBoard(
                            board: state.board,
                            selectedPiece: state.selectedPiece,
                            hoverAnchor: state.hoverAnchor,
                            engine: engine,
                            onCellTapped: (row, col) {
                              if (state.selectedPiece != null) {
                                cubit.placePieceAt(row, col);
                              }
                            },
                            onPieceDropped: (row, col, piece) {
                              cubit.placePieceAt(
                                row,
                                col,
                                explicitPiece: piece,
                              );
                            },
                            onCellHovered: (row, col) {
                              cubit.setHoverAnchor(row, col);
                            },
                            onHoverLeave: () {
                              cubit.clearHoverAnchor();
                            },
                          ),
                        ),

                        // Bottom Section: Piece Tray & New Game
                        Column(
                          children: [
                            PieceTray(
                              pieces: state.availablePieces,
                              selectedPieceIndex: state.selectedPieceIndex,
                              onSelectPiece: (index) =>
                                  cubit.selectPiece(index),
                            ),
                            const SizedBox(height: 14),
                            _buildActionButton(context, state, cubit),
                          ],
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

  Widget _buildInstructionBanner(BuildContext context, BlockPuzzleState state) {
    final (text, color, icon) = state.isGameOver
        ? (
            'Game Over! No available pieces fit.',
            const Color(0xFFEF4444),
            Icons.warning_amber_rounded,
          )
        : state.selectedPiece != null
        ? (
            'Tap a position on the board to place ${state.selectedPiece!.shape.name}',
            const Color(0xFF10B981),
            Icons.touch_app_rounded,
          )
        : (
            'Select a piece below or drag it onto the board',
            const Color(0xFF3B82F6),
            Icons.pan_tool_alt_rounded,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    BlockPuzzleState state,
    BlockPuzzleCubit cubit,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _handleNewGame(context, state, cubit),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'New Game',
                        style: TextStyle(
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

  Future<void> _handleNewGame(
    BuildContext context,
    BlockPuzzleState state,
    BlockPuzzleCubit cubit,
  ) async {
    if (state.score > 0 && !state.isGameOver) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Start New Game?'),
          content: const Text(
            'Your current score and board progress will be discarded. Are you sure you want to start a new game?',
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
              child: const Text('Restart'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    cubit.startNewGame();
  }
}
