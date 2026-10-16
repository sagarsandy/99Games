import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/emoji_connect_cubit.dart';
import '../cubit/emoji_connect_state.dart';
import 'widgets/emoji_connect_board.dart';
import 'widgets/emoji_connect_controls.dart';
import 'widgets/emoji_connect_level_header.dart';
import 'widgets/emoji_connect_results_dialog.dart';

/// The primary game screen for Emoji Connect (Game 9).
class EmojiConnectScreen extends StatefulWidget {
  const EmojiConnectScreen({super.key});

  @override
  State<EmojiConnectScreen> createState() => _EmojiConnectScreenState();
}

class _EmojiConnectScreenState extends State<EmojiConnectScreen> {
  int? _winDialogShownForLevel;
  bool _isResultsDialogOpen = false;

  void _showResultsDialog(
    BuildContext context,
    EmojiConnectState state,
    EmojiConnectCubit cubit,
  ) {
    if (_isResultsDialogOpen) return;
    _isResultsDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => EmojiConnectResultsDialog(
        state: state,
        cubit: cubit,
        onViewBoard: () {
          // Dialog dismissed; player can inspect completed board
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isResultsDialogOpen = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmojiConnectCubit, EmojiConnectState>(
      listenWhen: (prev, curr) =>
          prev.isWon != curr.isWon ||
          prev.hintMessage != curr.hintMessage ||
          prev.levelNumber != curr.levelNumber ||
          prev.difficulty != curr.difficulty,
      listener: (context, state) {
        final cubit = context.read<EmojiConnectCubit>();

        // Reset dialog tracking if level changed or game is no longer won
        if (!state.isWon) {
          _winDialogShownForLevel = null;
        }

        // 1. Show hint notification if triggered
        if (state.hintMessage != null && state.hintMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.hintMessage!)),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        // 2. Automatically show victory dialog upon win (once per level)
        if (state.isWon && _winDialogShownForLevel != state.levelNumber) {
          _winDialogShownForLevel = state.levelNumber;
          _showResultsDialog(context, state, cubit);
        }
      },
      builder: (context, state) {
        final cubit = context.read<EmojiConnectCubit>();

        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                EmojiConnectLevelHeader(state: state, cubit: cubit),
                if (state.isWon) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Level Completed! (100% Flow)',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: () =>
                                _showResultsDialog(context, state, cubit),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Stats',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EmojiConnectBoard(state: state, cubit: cubit),
                  ),
                ),
                EmojiConnectControls(
                  state: state,
                  cubit: cubit,
                  onViewResults: () =>
                      _showResultsDialog(context, state, cubit),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
