import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/word_search_cubit.dart';
import '../cubit/word_search_state.dart';
import '../domain/word_search_models.dart';
import 'widgets/word_list_panel.dart';
import 'widgets/word_search_completion_dialog.dart';
import 'widgets/word_search_grid.dart';
import 'widgets/word_search_stats_bar.dart';

/// The main Word Search puzzle screen.
class WordSearchScreen extends StatefulWidget {
  const WordSearchScreen({super.key});

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen>
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
    final cubit = context.read<WordSearchCubit>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      cubit.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      cubit.resumeTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WordSearchCubit, WordSearchState>(
      listenWhen: (previous, current) =>
          !previous.isCompleted && current.isCompleted,
      listener: (context, state) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => WordSearchCompletionDialog(
            wordsCount: state.totalWords,
            formattedTime: state.formattedTime,
            isNewBestTime: state.isNewBestTime,
            bestTimeSeconds: state.bestTime,
            onNewPuzzle: () => context.read<WordSearchCubit>().startNewPuzzle(),
          ),
        );
      },
      builder: (context, state) {
        final cubit = context.read<WordSearchCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Word Search'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Home',
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'New Puzzle',
                onPressed: () => _handleNewPuzzle(context, state, cubit),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Difficulty selector
                        _buildDifficultySelector(context, state, cubit),
                        const SizedBox(height: 12),

                        // Stats bar (Words found, timer, progress)
                        const WordSearchStatsBar(),
                        const SizedBox(height: 12),

                        // Interactive Letter Grid
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: WordSearchGrid(state: state, cubit: cubit),
                        ),
                        const SizedBox(height: 14),

                        // Target Words List Panel
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: WordListPanel(
                            targetWords: state.targetWords,
                            foundWords: state.foundWords,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action Button (New Puzzle)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: _buildActionButton(context, state, cubit),
                        ),
                        const SizedBox(height: 12),
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

  Widget _buildDifficultySelector(
    BuildContext context,
    WordSearchState state,
    WordSearchCubit cubit,
  ) {
    return SegmentedButton<WordSearchDifficulty>(
      segments: const [
        ButtonSegment(
          value: WordSearchDifficulty.easy,
          label: Text('Easy'),
          icon: Icon(Icons.sentiment_satisfied_rounded, size: 16),
        ),
        ButtonSegment(
          value: WordSearchDifficulty.medium,
          label: Text('Medium'),
          icon: Icon(Icons.sentiment_neutral_rounded, size: 16),
        ),
        ButtonSegment(
          value: WordSearchDifficulty.hard,
          label: Text('Hard'),
          icon: Icon(Icons.sentiment_very_dissatisfied_rounded, size: 16),
        ),
      ],
      selected: {state.difficulty},
      onSelectionChanged: (selection) async {
        final chosen = selection.first;
        if (chosen == state.difficulty) return;

        if (state.foundCount > 0 && !state.isCompleted) {
          final confirmed = await _showDiscardConfirmation(context);
          if (!confirmed) return;
        }

        cubit.setDifficulty(chosen);
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WordSearchState state,
    WordSearchCubit cubit,
  ) {
    final isCompleted = state.isCompleted;
    final gradient = isCompleted
        ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
        : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0D9488)]);

    final shadowColor = const Color(0xFF10B981).withValues(alpha: 0.3);
    final label = isCompleted ? 'Play Again' : 'New Puzzle';
    final icon = isCompleted ? Icons.replay_rounded : Icons.shuffle_rounded;

    return SizedBox(
      width: double.infinity,
      height: 52,
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
            onTap: () => _handleNewPuzzle(context, state, cubit),
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
    );
  }

  Future<void> _handleNewPuzzle(
    BuildContext context,
    WordSearchState state,
    WordSearchCubit cubit,
  ) async {
    if (state.foundCount > 0 && !state.isCompleted) {
      final confirmed = await _showDiscardConfirmation(context);
      if (!confirmed) return;
    }

    cubit.startNewPuzzle();
  }

  Future<bool> _showDiscardConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start New Puzzle?'),
        content: const Text(
          'Your current puzzle progress will be discarded. Are you sure you want to start a new puzzle?',
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

    return result ?? false;
  }
}
