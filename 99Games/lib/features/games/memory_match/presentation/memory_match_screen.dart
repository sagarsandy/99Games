import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/memory_match_cubit.dart';
import '../cubit/memory_match_state.dart';
import '../domain/memory_match_models.dart';
import 'widgets/memory_match_card_grid.dart';
import 'widgets/memory_match_completion_dialog.dart';
import 'widgets/memory_match_hud.dart';
import 'widgets/memory_match_start_screen.dart';

/// Main screen for Game 14: Memory Match.
class MemoryMatchScreen extends StatelessWidget {
  const MemoryMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<MemoryMatchCubit, MemoryMatchState>(
      builder: (context, state) {
        final cubit = context.read<MemoryMatchCubit>();
        final config = state.currentLevelConfig;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [
                        Color(0xFF0F172A),
                        Color(0xFF1E1B4B),
                        Color(0xFF0F172A),
                      ]
                    : const [
                        Color(0xFFEEF2FF),
                        Color(0xFFF8FAFC),
                        Color(0xFFE0E7FF),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 1. Top HUD: Back button, Title, Level Selector, Status Chips
                  MemoryMatchHud(state: state),
                  const SizedBox(height: 4),

                  // 2. Play Area with Card Grid and contextual overlays
                  Expanded(
                    child: Stack(
                      children: [
                        // Card Grid
                        Positioned.fill(
                          child: MemoryMatchCardGrid(
                            config: config,
                            cards: state.cards,
                            firstSelectedId: state.firstSelectedId,
                            secondSelectedId: state.secondSelectedId,
                            isResolvingMismatch: state.isResolvingMismatch,
                            onCardTap: (card) => cubit.onCardTapped(card.id),
                          ),
                        ),

                        // Start Game Overlay (Before round begins)
                        if (state.status == GameStatus.ready)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.45),
                              child: MemoryMatchStartScreen(
                                state: state,
                                onPlay: () => cubit.startGame(),
                              ),
                            ),
                          ),

                        // Level Complete Modal Dialog
                        if (state.status == GameStatus.completed)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.55),
                              child: MemoryMatchCompletionDialog(
                                state: state,
                                onNextLevel: () => cubit.nextLevel(),
                                onReplay: () => cubit.restartLevel(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
