import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/sudoku_cubit.dart';
import '../cubit/sudoku_state.dart';
import '../domain/sudoku_models.dart';
import 'widgets/sudoku_board.dart';
import 'widgets/sudoku_game_controls.dart';
import 'widgets/sudoku_notes_panel.dart';
import 'widgets/sudoku_number_pad.dart';

/// The main Sudoku game screen.
class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen>
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
    final cubit = context.read<SudokuCubit>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      cubit.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      cubit.resumeTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SudokuCubit, SudokuState>(
      listenWhen: (prev, current) =>
          prev.status != current.status && current.isFinished,
      listener: (context, state) {
        if (state.isCompleted) {
          _showWinDialog(context, state);
        } else if (state.isGameOver) {
          _showGameOverDialog(context, state);
        }
      },
      buildWhen: (prev, current) =>
          prev.board != current.board ||
          prev.clues != current.clues ||
          prev.selectedCell != current.selectedCell ||
          prev.isNotesMode != current.isNotesMode ||
          prev.status != current.status ||
          prev.difficulty != current.difficulty ||
          prev.mistakes != current.mistakes ||
          prev.canUndo != current.canUndo ||
          prev.stats != current.stats ||
          prev.notes != current.notes ||
          prev.conflictingIndices != current.conflictingIndices ||
          prev.incorrectIndices != current.incorrectIndices,
      builder: (context, state) {
        final cubit = context.read<SudokuCubit>();

        return SelectionContainer.disabled(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Sudoku'),
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
                  tooltip: 'New Game',
                  onPressed: () => _confirmNewGame(context, state, cubit),
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
                      vertical: 8,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Top Section: Difficulty & Status
                          Column(
                            children: [
                              _buildDifficultySelector(context, state, cubit),
                              const SizedBox(height: 10),
                              _buildStatusBar(context, state),
                              const SizedBox(height: 6),
                              SudokuNotesPanel(state: state),
                            ],
                          ),

                          // Center Section: Board
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 440,
                                maxHeight: constraints.maxHeight * 0.54,
                              ),
                              child: SudokuBoard(state: state, cubit: cubit),
                            ),
                          ),

                          // Bottom Section: Controls & Number Pad
                          Column(
                            children: [
                              SudokuGameControls(state: state, cubit: cubit),
                              const SizedBox(height: 12),
                              SudokuNumberPad(state: state, cubit: cubit),
                              const SizedBox(height: 8),
                            ],
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

  Widget _buildDifficultySelector(
    BuildContext context,
    SudokuState state,
    SudokuCubit cubit,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final unselectedFg = isDark ? Colors.white70 : const Color(0xFF475569);

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: SudokuDifficulty.values.map((difficulty) {
        final isSelected = state.difficulty == difficulty;
        return ChoiceChip(
          label: Text(
            difficulty.label,
            style: TextStyle(
              color: isSelected ? Colors.white : unselectedFg,
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
            if (selected && state.difficulty != difficulty) {
              _confirmDifficultyChange(context, state, cubit, difficulty);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildStatusBar(BuildContext context, SudokuState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mistakeColor = switch (state.mistakes) {
      0 => const Color(0xFF10B981), // Emerald
      1 => const Color(0xFFF59E0B), // Amber
      2 => const Color(0xFFEA580C), // Orange
      _ => const Color(0xFFEF4444), // Red
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Mistakes Counter Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: mistakeColor.withValues(alpha: isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: mistakeColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: mistakeColor),
              const SizedBox(width: 5),
              Text(
                'Mistakes: ${state.mistakes} / 3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: mistakeColor,
                ),
              ),
            ],
          ),
        ),

        // Best Time Pill (if available)
        if (state.stats.bestTimeSeconds != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 15,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  'Best: ${_formatSeconds(state.stats.bestTimeSeconds!)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

        // Timer Pill (isolated to prevent full-screen rebuilds on each second tick)
        const _SudokuTimerPill(),
      ],
    );
  }

  String _formatSeconds(int seconds) {
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmNewGame(
    BuildContext context,
    SudokuState state,
    SudokuCubit cubit,
  ) async {
    if (state.isFinished || state.elapsedSeconds == 0) {
      cubit.startNewGame(state.difficulty);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('New Puzzle?'),
        content: const Text(
          'An active game is in progress. Discard your current puzzle and start a new one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dContext).pop(true),
            child: const Text('New Puzzle'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.startNewGame(state.difficulty);
    }
  }

  Future<void> _confirmDifficultyChange(
    BuildContext context,
    SudokuState state,
    SudokuCubit cubit,
    SudokuDifficulty nextDifficulty,
  ) async {
    if (state.isFinished || state.elapsedSeconds == 0) {
      cubit.startNewGame(nextDifficulty);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: Text('Switch to ${nextDifficulty.label}?'),
        content: const Text(
          'Switching difficulty will discard your current progress and generate a new puzzle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dContext).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.startNewGame(nextDifficulty);
    }
  }

  Future<void> _confirmResetStats(
    BuildContext context,
    SudokuCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('Reset Stats?'),
        content: const Text(
          'Are you sure you want to reset all tracked stats and best completion time for this difficulty?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.resetStats();
    }
  }

  void _showWinDialog(BuildContext context, SudokuState state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dContext) => AlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFF59E0B),
              size: 28,
            ),
            SizedBox(width: 10),
            Text('Puzzle Solved!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! You successfully completed the ${state.difficulty.label} Sudoku puzzle.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Time: ${state.formattedTime}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (state.isNewBestTime) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW BEST!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Mistakes: ${state.mistakes} / 3',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dContext).pop();
              context.read<SudokuCubit>().startNewGame(state.difficulty);
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, SudokuState state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dContext) => AlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.heart_broken_rounded,
              color: Color(0xFFEF4444),
              size: 28,
            ),
            SizedBox(width: 10),
            Text('Game Over'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You made 3 mistakes! The round has ended.'),
            const SizedBox(height: 10),
            Text(
              'Difficulty: ${state.difficulty.label}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Time Elapsed: ${state.formattedTime}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
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
              context.read<SudokuCubit>().startNewGame(state.difficulty);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text('Sudoku Rules'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Goal', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text(
                'Fill every empty cell with a digit from 1 to 9 so that each row, column, and 3×3 subgrid contains every number exactly once.',
              ),
              SizedBox(height: 10),
              Text(
                '2. Three Mistakes Rule',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Placing an incorrect number counts as a mistake. Reaching 3 mistakes ends the round.',
              ),
              SizedBox(height: 10),
              Text(
                '3. Pencil Notes',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Toggle Notes mode ON to jot down candidate possibilities in any cell without committing a final move.',
              ),
              SizedBox(height: 10),
              Text(
                '4. Hints & Undo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Tap Hint to reveal the correct digit for the selected cell. Use Undo to revert previous entries or note toggles.',
              ),
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

/// An isolated timer pill that only rebuilds when elapsedSeconds changes,
/// preventing expensive whole-screen rebuilds on each second tick.
class _SudokuTimerPill extends StatelessWidget {
  const _SudokuTimerPill();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocSelector<SudokuCubit, SudokuState, int>(
      selector: (state) => state.elapsedSeconds,
      builder: (context, elapsedSeconds) {
        final hours = elapsedSeconds ~/ 3600;
        final minutes = (elapsedSeconds % 3600) ~/ 60;
        final seconds = elapsedSeconds % 60;

        final mStr = minutes.toString().padLeft(2, '0');
        final sStr = seconds.toString().padLeft(2, '0');
        final formattedTime = hours > 0
            ? '${hours.toString().padLeft(2, '0')}:$mStr:$sStr'
            : '$mStr:$sStr';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              const SizedBox(width: 5),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
