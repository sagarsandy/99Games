import 'package:flutter/material.dart';
import '../../cubit/sudoku_cubit.dart';
import '../../cubit/sudoku_state.dart';
import '../../domain/sudoku_engine.dart';
import 'sudoku_cell.dart';

/// The interactive 9 × 9 Sudoku board widget.
class SudokuBoard extends StatelessWidget {
  final SudokuState state;
  final SudokuCubit cubit;
  final SudokuEngine engine;

  const SudokuBoard({
    super.key,
    required this.state,
    required this.cubit,
    this.engine = const SudokuEngine(),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedIndex = state.selectedCell;
    final selectedVal = state.selectedCellValue;
    final relatedIndices = selectedIndex != null
        ? engine.getRelatedIndices(selectedIndex)
        : const <int>{};

    return AspectRatio(
      aspectRatio: 1.0,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white70 : const Color(0xFF0F172A),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13.5),
            child: Column(
              children: [
                for (int r = 0; r < 9; r++)
                  Expanded(
                    child: Row(
                      children: [
                        for (int c = 0; c < 9; c++)
                          Expanded(
                            child: _buildCell(
                              r * 9 + c,
                              selectedIndex,
                              selectedVal,
                              relatedIndices,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(
    int index,
    int? selectedIndex,
    int? selectedVal,
    Set<int> relatedIndices,
  ) {
    final val = state.board[index];
    final isClue = state.clues[index] != 0;
    final isSelected = selectedIndex == index;
    final isRelated = relatedIndices.contains(index);
    final isSameNumber =
        selectedVal != null && selectedVal != 0 && val == selectedVal;
    final isIncorrect = state.incorrectIndices.contains(index);
    final isConflicting = state.conflictingIndices.contains(index);
    final notes = state.notes[index] ?? const <int>{};

    return SudokuCell(
      index: index,
      value: val,
      isClue: isClue,
      notes: notes,
      isSelected: isSelected,
      isRelated: isRelated,
      isSameNumber: isSameNumber,
      isIncorrect: isIncorrect,
      isConflicting: isConflicting,
      onTap: () => cubit.selectCell(index),
    );
  }
}
