import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/worm_escape_cubit.dart';
import '../cubit/worm_escape_state.dart';
import 'widgets/worm_escape_board.dart';
import 'widgets/worm_escape_controls.dart';
import 'widgets/worm_escape_level_header.dart';
import 'widgets/worm_escape_results_dialog.dart';

/// Primary game screen for Worm Escape (Game 10).
class WormEscapeScreen extends StatefulWidget {
  const WormEscapeScreen({super.key});

  @override
  State<WormEscapeScreen> createState() => _WormEscapeScreenState();
}

class _WormEscapeScreenState extends State<WormEscapeScreen> {
  int? _winDialogShownForLevel;
  bool _isResultsDialogOpen = false;

  void _showResultsDialog(
    BuildContext context,
    WormEscapeState state,
    WormEscapeCubit cubit,
  ) {
    if (_isResultsDialogOpen) return;
    _isResultsDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WormEscapeResultsDialog(
        state: state,
        cubit: cubit,
        onViewBoard: () {
          // Dialog dismissed to view completed board
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
    return BlocConsumer<WormEscapeCubit, WormEscapeState>(
      listenWhen: (prev, curr) =>
          prev.isWon != curr.isWon ||
          prev.hintMessage != curr.hintMessage ||
          prev.levelNumber != curr.levelNumber ||
          prev.difficulty != curr.difficulty,
      listener: (context, state) {
        final cubit = context.read<WormEscapeCubit>();

        // Reset dialog tracking if level changed or game is no longer won
        if (!state.isWon) {
          _winDialogShownForLevel = null;
        }

        // 1. Show message notification if triggered
        if (state.hintMessage != null && state.hintMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    state.blockedWormId != null
                        ? Icons.block_rounded
                        : Icons.tips_and_updates_rounded,
                    color: state.blockedWormId != null
                        ? Colors.redAccent
                        : Colors.amber,
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
        final cubit = context.read<WormEscapeCubit>();

        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                WormEscapeLevelHeader(state: state, cubit: cubit),
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
                            'All Worms Escaped! 🐛',
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
                    child: WormEscapeBoard(state: state, cubit: cubit),
                  ),
                ),
                WormEscapeControls(
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
