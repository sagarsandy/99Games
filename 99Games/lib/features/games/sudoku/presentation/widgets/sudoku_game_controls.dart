import 'package:flutter/material.dart';
import '../../cubit/sudoku_cubit.dart';
import '../../cubit/sudoku_state.dart';

/// Control buttons bar for Undo, Erase, Notes mode toggle, and Hint.
class SudokuGameControls extends StatelessWidget {
  final SudokuState state;
  final SudokuCubit cubit;

  const SudokuGameControls({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 1. Undo Button
        _buildActionButton(
          icon: Icons.undo_rounded,
          label: 'Undo',
          isEnabled: state.canUndo,
          onTap: () => cubit.undo(),
          isDark: isDark,
        ),

        // 2. Erase Button
        _buildActionButton(
          icon: Icons.backspace_outlined,
          label: 'Erase',
          isEnabled:
              !state.isFinished &&
              state.selectedCell != null &&
              !state.isSelectedCellClue,
          onTap: () => cubit.erase(),
          isDark: isDark,
        ),

        // 3. Notes Mode Toggle Button
        _buildNotesToggleButton(isDark),

        // 4. Hint Button
        _buildActionButton(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Hint',
          isEnabled:
              !state.isFinished &&
              state.selectedCell != null &&
              !state.isSelectedCellClue &&
              state.selectedCellValue != state.solution[state.selectedCell!],
          onTap: () => cubit.giveHint(),
          isDark: isDark,
          accentColor: const Color(0xFFF59E0B), // Amber bulb
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
    required bool isDark,
    Color? accentColor,
  }) {
    final effectiveColor = isEnabled
        ? (accentColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)))
        : (isDark ? Colors.white24 : const Color(0xFFCBD5E1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: isEnabled ? onTap : null,
          icon: Icon(icon, size: 24),
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
            foregroundColor: effectiveColor,
            disabledBackgroundColor: isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isEnabled
                ? (isDark ? Colors.white70 : const Color(0xFF475569))
                : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesToggleButton(bool isDark) {
    final isNotesOn = state.isNotesMode;
    final primaryColor = const Color(0xFF4F46E5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filled(
              onPressed: !state.isFinished
                  ? () => cubit.toggleNotesMode()
                  : null,
              icon: Icon(
                Icons.edit_note_rounded,
                size: 26,
                color: isNotesOn
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
              style: IconButton.styleFrom(
                backgroundColor: isNotesOn
                    ? primaryColor
                    : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9)),
                padding: const EdgeInsets.all(12),
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isNotesOn
                      ? const Color(0xFF10B981) // Green ON
                      : const Color(0xFF94A3B8), // Grey OFF
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isNotesOn ? 'ON' : 'OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Notes',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isNotesOn
                ? primaryColor
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ],
    );
  }
}
