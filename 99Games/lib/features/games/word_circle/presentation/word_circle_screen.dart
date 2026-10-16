import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/word_circle_cubit.dart';
import '../cubit/word_circle_state.dart';
import 'widgets/word_circle_controls.dart';
import 'widgets/word_circle_crossword.dart';
import 'widgets/word_circle_level_header.dart';
import 'widgets/word_circle_results_dialog.dart';
import 'widgets/word_circle_wheel.dart';

/// Main gameplay screen for Game 12: Word Circle.
class WordCircleScreen extends StatefulWidget {
  const WordCircleScreen({super.key});

  @override
  State<WordCircleScreen> createState() => _WordCircleScreenState();
}

class _WordCircleScreenState extends State<WordCircleScreen> {
  bool _isViewingBoard = false;

  void _showResults(BuildContext context, WordCircleState state) {
    final cubit = context.read<WordCircleCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => WordCircleResultsDialog(
        state: state,
        cubit: cubit,
        onViewBoard: () {
          setState(() {
            _isViewingBoard = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColors = isDark
        ? [const Color(0xFF0F172A), const Color(0xFF0C4A6E)]
        : [const Color(0xFFF0FDF4), const Color(0xFFE0F2FE)];

    return BlocConsumer<WordCircleCubit, WordCircleState>(
      listener: (context, state) {
        if (!state.isWon && _isViewingBoard) {
          setState(() {
            _isViewingBoard = false;
          });
        }

        if (state.isWon && !state.hasShownWinDialog && !_isViewingBoard) {
          context.read<WordCircleCubit>().markWinDialogShown();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showResults(context, state);
            }
          });
        }
      },
      builder: (context, state) {
        final cubit = context.read<WordCircleCubit>();

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 1. Level Header
                  WordCircleLevelHeader(state: state, cubit: cubit),

                  // 2. Main Play Area: Crossword Target Grid & Letter Wheel
                  Expanded(
                    child: state.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF06B6D4),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                children: [
                                  // Top: Crossword Target Grid
                                  Expanded(
                                    flex: 5,
                                    child: WordCircleCrossword(state: state),
                                  ),

                                  // Middle: Word Preview / Feedback Bubble
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: SizedBox(
                                      height: 38,
                                      child: Center(
                                        child: _buildWordPreviewBubble(
                                          state,
                                          isDark,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Bottom: Circular Letter Wheel
                                  Expanded(
                                    flex: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: WordCircleWheel(
                                        state: state,
                                        cubit: cubit,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),

                  // 3. Controls Bar
                  WordCircleControls(
                    state: state,
                    cubit: cubit,
                    onViewResults: (_isViewingBoard && state.isWon)
                        ? () {
                            setState(() {
                              _isViewingBoard = false;
                            });
                            _showResults(context, state);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWordPreviewBubble(WordCircleState state, bool isDark) {
    if (state.currentWord.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF06B6D4),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          state.currentWord,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
      );
    }

    if (state.feedbackMessage != null) {
      final isSuccess =
          state.feedbackMessage!.contains('Target') ||
          state.feedbackMessage!.contains('Bonus') ||
          state.feedbackMessage!.contains('revealed');

      final color = isSuccess
          ? const Color(0xFF10B981)
          : const Color(0xFFEF4444);

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: ValueKey(state.feedbackMessage),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            state.feedbackMessage!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
