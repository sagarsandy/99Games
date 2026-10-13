import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/number_slide_cubit.dart';
import '../cubit/number_slide_state.dart';
import '../domain/number_slide_engine.dart';
import 'widgets/number_slide_board.dart';
import 'widgets/number_slide_stats_card.dart';
import 'widgets/number_slide_victory_dialog.dart';

/// The main Number Slide 15-puzzle screen.
class NumberSlideScreen extends StatefulWidget {
  const NumberSlideScreen({super.key});

  @override
  State<NumberSlideScreen> createState() => _NumberSlideScreenState();
}

class _NumberSlideScreenState extends State<NumberSlideScreen>
    with WidgetsBindingObserver {
  final NumberSlideEngine _engine = NumberSlideEngine();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<NumberSlideCubit>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      cubit.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      cubit.resumeTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NumberSlideCubit, NumberSlideState>(
      listenWhen: (previous, current) => !previous.isSolved && current.isSolved,
      listener: (context, state) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => NumberSlideVictoryDialog(
            moves: state.moves,
            formattedTime: state.formattedTime,
            bestResult: state.bestResult,
            onNewGame: () => context.read<NumberSlideCubit>().startNewGame(),
          ),
        );
      },
      builder: (context, state) {
        final cubit = context.read<NumberSlideCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Number Slide'),
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
                        // Top Section: Stats Card
                        Column(
                          children: [
                            NumberSlideStatsCard(
                              moves: state.moves,
                              formattedTime: state.formattedTime,
                              bestResult: state.bestResult,
                            ),
                            const SizedBox(height: 12),
                            _buildInstructionBanner(context, state),
                          ],
                        ),

                        // Center Section: 4x4 Grid Board
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: NumberSlideBoard(
                            board: state.board,
                            engine: _engine,
                            isInteractive: !state.isSolved,
                            onTileTapped: (index) => cubit.makeMove(index),
                          ),
                        ),

                        // Bottom Section: Action Button
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

  Widget _buildInstructionBanner(BuildContext context, NumberSlideState state) {
    final (text, color, icon) = state.isSolved
        ? (
            '🎉 Puzzle Solved! Outstanding work!',
            const Color(0xFF10B981),
            Icons.check_circle_outline_rounded,
          )
        : state.hasStarted
        ? (
            'Slide adjacent tiles to sort numbers 1 to 15',
            const Color(0xFF3B82F6),
            Icons.touch_app_rounded,
          )
        : (
            'Tap any tile adjacent to the empty slot to begin',
            const Color(0xFF6366F1),
            Icons.play_circle_outline_rounded,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                fontSize: 13,
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
    NumberSlideState state,
    NumberSlideCubit cubit,
  ) {
    final isSolved = state.isSolved;

    final gradient = isSolved
        ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
        : const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]);

    final shadowColor = isSolved
        ? const Color(0xFF10B981).withValues(alpha: 0.35)
        : const Color(0xFF2563EB).withValues(alpha: 0.3);

    final label = isSolved ? 'Play Again' : 'New Game';
    final icon = isSolved ? Icons.replay_rounded : Icons.shuffle_rounded;

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
                onTap: () => _handleNewGame(context, state, cubit),
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

  Future<void> _handleNewGame(
    BuildContext context,
    NumberSlideState state,
    NumberSlideCubit cubit,
  ) async {
    // If game in progress (moves > 0 and not solved), ask confirmation
    if (state.hasStarted && !state.isSolved) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Start New Game?'),
          content: const Text(
            'Your current puzzle progress will be discarded. Are you sure you want to start a new game?',
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
