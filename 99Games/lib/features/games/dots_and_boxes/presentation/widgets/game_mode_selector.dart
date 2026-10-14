import 'package:flutter/material.dart';
import '../../cubit/dots_and_boxes_cubit.dart';
import '../../cubit/dots_and_boxes_state.dart';
import '../../domain/dots_and_boxes_models.dart';

/// Control panel containing the game mode, AI difficulty, and board size selectors.
class GameModeSelector extends StatelessWidget {
  final DotsAndBoxesState state;
  final DotsAndBoxesCubit cubit;

  const GameModeSelector({super.key, required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Play Mode Selector (vs Computer / 2 Players)
        _buildPlayModeSelector(context),
        const SizedBox(height: 10),

        // 2. AI Difficulty (only visible when in vs Computer mode)
        if (state.gameMode == DotsGameMode.vsAi) ...[
          _buildDifficultySelector(context),
          const SizedBox(height: 10),
        ],

        // 3. Board Size Selector (Small 6x6, Medium 9x9, Large 15x15)
        _buildBoardSizeSelector(context),
      ],
    );
  }

  Widget _buildPlayModeSelector(BuildContext context) {
    return SegmentedButton<DotsGameMode>(
      segments: const [
        ButtonSegment<DotsGameMode>(
          value: DotsGameMode.vsAi,
          label: Text('vs Computer'),
          icon: Icon(Icons.smart_toy_rounded, size: 18),
        ),
        ButtonSegment<DotsGameMode>(
          value: DotsGameMode.passAndPlay,
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

  Widget _buildDifficultySelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? const Color(0xFF334155) // Slate-700
        : const Color(0xFFE2E8F0); // Slate-200
    final unselectedFg = isDark ? Colors.white70 : const Color(0xFF475569);

    return Center(
      child: Wrap(
        spacing: 8,
        alignment: WrapAlignment.center,
        children: DotsAiDifficulty.values.map((difficulty) {
          final isSelected = state.aiDifficulty == difficulty;
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
              if (selected) {
                cubit.setAiDifficulty(difficulty);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoardSizeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'BOARD SIZE (BOXES)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        SegmentedButton<BoardSize>(
          segments: const [
            ButtonSegment<BoardSize>(
              value: BoardSize.small,
              label: Text('6 × 6\n(36 boxes)', textAlign: TextAlign.center),
              tooltip: 'Small: 6×6 boxes, 7×7 dots (36 boxes)',
            ),
            ButtonSegment<BoardSize>(
              value: BoardSize.medium,
              label: Text('9 × 9\n(81 boxes)', textAlign: TextAlign.center),
              tooltip: 'Medium: 9×9 boxes, 10×10 dots (81 boxes)',
            ),
            ButtonSegment<BoardSize>(
              value: BoardSize.large,
              label: Text('15 × 15\n(225 boxes)', textAlign: TextAlign.center),
              tooltip: 'Large: 15×15 boxes, 16×16 dots (225 boxes)',
            ),
          ],
          selected: {state.boardSize},
          onSelectionChanged: (newSelection) {
            cubit.setBoardSize(newSelection.first);
          },
        ),
      ],
    );
  }
}
