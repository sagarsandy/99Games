import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/number_match_cubit.dart';
import '../cubit/number_match_state.dart';
import 'widgets/number_match_board.dart';
import 'widgets/number_match_controls.dart';
import 'widgets/number_match_status.dart';

/// The main Classic Number Match game screen.
class NumberMatchScreen extends StatefulWidget {
  const NumberMatchScreen({super.key});

  @override
  State<NumberMatchScreen> createState() => _NumberMatchScreenState();
}

class _NumberMatchScreenState extends State<NumberMatchScreen>
    with WidgetsBindingObserver {
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
    final cubit = context.read<NumberMatchCubit>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      cubit.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      cubit.resumeTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NumberMatchCubit, NumberMatchState>(
      listenWhen: (prev, current) =>
          prev.status != current.status && current.isWon,
      listener: (context, state) {
        if (state.isWon) {
          _showWinDialog(context, state);
        }
      },
      buildWhen: (prev, current) =>
          prev.tiles != current.tiles ||
          prev.selectedIndex != current.selectedIndex ||
          prev.hintPair != current.hintPair ||
          prev.score != current.score ||
          prev.pairsCleared != current.pairsCleared ||
          prev.status != current.status ||
          prev.feedbackMessage != current.feedbackMessage ||
          prev.stats != current.stats ||
          prev.actionHistory.length != current.actionHistory.length,
      builder: (context, state) {
        final cubit = context.read<NumberMatchCubit>();

        return SelectionContainer.disabled(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Number Match'),
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
                  tooltip: 'Restart Game',
                  onPressed: () => _confirmRestartGame(context, state, cubit),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Reset Stats',
                  onPressed: () => _confirmResetStats(context, cubit),
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
                          // 1. Top Section: Status Header
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: NumberMatchStatus(state: state),
                          ),
                          const SizedBox(height: 12),

                          // 2. Center Section: 9-Column Board
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: NumberMatchBoard(state: state, cubit: cubit),
                          ),
                          const SizedBox(height: 12),

                          // 3. Bottom Section: Controls
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: NumberMatchControls(
                              state: state,
                              cubit: cubit,
                              onRestart: () =>
                                  _confirmRestartGame(context, state, cubit),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmRestartGame(
    BuildContext context,
    NumberMatchState state,
    NumberMatchCubit cubit,
  ) async {
    if (state.isWon || state.pairsCleared == 0) {
      cubit.restartGame();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('Restart Board?'),
        content: const Text(
          'A game is currently in progress. Discard current progress and start a fresh board?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dContext).pop(true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.restartGame();
    }
  }

  Future<void> _confirmResetStats(
    BuildContext context,
    NumberMatchCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('Reset Statistics?'),
        content: const Text(
          'This will clear your best score, games won, and total pairs cleared. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.of(dContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.resetStats();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Statistics reset.')));
      }
    }
  }

  void _showWinDialog(BuildContext context, NumberMatchState state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dContext) => AlertDialog(
        icon: const Icon(
          Icons.emoji_events_rounded,
          color: Color(0xFFF59E0B),
          size: 48,
        ),
        title: const Text(
          'Victory!',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'All numbers cleared! Incredible job!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _dialogStatRow('Final Score', '${state.score}'),
                  const Divider(height: 12),
                  _dialogStatRow('Pairs Cleared', '${state.pairsCleared}'),
                  const Divider(height: 12),
                  _dialogStatRow('Time Elapsed', state.formattedTime),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dContext).pop();
              context.pop();
            },
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dContext).pop();
              context.read<NumberMatchCubit>().restartGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _dialogStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('How to Play: Number Match'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Valid Pairs',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Match pairs of numbers that are IDENTICAL (1-1, 2-2, etc.) or ADD UP TO 10 (1-9, 2-8, 3-7, 4-6, 5-5).',
              ),
              SizedBox(height: 12),
              Text(
                '2. Connection Rules',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Numbers can be matched if they are connected with NO active numbers blocking them:\n'
                '• Horizontally adjacent or across cleared cells in the same row.\n'
                '• Vertically adjacent or across cleared cells in the same column.\n'
                '• Diagonally adjacent or across cleared cells on a diagonal line.\n'
                '• Sequentially in reading order (including wrapping from the end of one row to the start of the next).',
              ),
              SizedBox(height: 12),
              Text(
                '3. Add Numbers',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'When no more pairs can be found, tap "Add Numbers" to duplicate all remaining active numbers to the end of the board.',
              ),
              SizedBox(height: 12),
              Text(
                '4. Objective',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text('Clear all numbers from the board to win the game!'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
