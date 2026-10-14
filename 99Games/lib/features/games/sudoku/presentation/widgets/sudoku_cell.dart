import 'package:flutter/material.dart';

/// Single cell on the 9 × 9 Sudoku board.
///
/// Distinctly renders original clues, player entries, pencil notes,
/// selection highlights, row/col/box related tints, matching number glows,
/// and mistake/conflict indicators.
class SudokuCell extends StatelessWidget {
  final int index;
  final int value;
  final bool isClue;
  final Set<int> notes;
  final bool isSelected;
  final bool isRelated;
  final bool isSameNumber;
  final bool isIncorrect;
  final bool isConflicting;
  final VoidCallback onTap;

  const SudokuCell({
    super.key,
    required this.index,
    required this.value,
    required this.isClue,
    required this.notes,
    required this.isSelected,
    required this.isRelated,
    required this.isSameNumber,
    required this.isIncorrect,
    required this.isConflicting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final row = index ~/ 9;
    final col = index % 9;

    // Outer and 3x3 block border styling
    final borderTop = BorderSide(
      color: row % 3 == 0
          ? (isDark ? Colors.white70 : const Color(0xFF1E293B))
          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      width: row % 3 == 0 ? 2.0 : 0.75,
    );
    final borderLeft = BorderSide(
      color: col % 3 == 0
          ? (isDark ? Colors.white70 : const Color(0xFF1E293B))
          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      width: col % 3 == 0 ? 2.0 : 0.75,
    );
    final borderBottom = BorderSide(
      color: row == 8
          ? (isDark ? Colors.white70 : const Color(0xFF1E293B))
          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      width: row == 8 ? 2.0 : 0.75,
    );
    final borderRight = BorderSide(
      color: col == 8
          ? (isDark ? Colors.white70 : const Color(0xFF1E293B))
          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      width: col == 8 ? 2.0 : 0.75,
    );

    // Background color resolution based on state priorities
    Color backgroundColor;
    if (isSelected) {
      backgroundColor = const Color(
        0xFF6366F1,
      ).withValues(alpha: isDark ? 0.35 : 0.25);
    } else if (isIncorrect || isConflicting) {
      backgroundColor = const Color(
        0xFFEF4444,
      ).withValues(alpha: isDark ? 0.25 : 0.15);
    } else if (isSameNumber && value != 0) {
      backgroundColor = const Color(
        0xFF4F46E5,
      ).withValues(alpha: isDark ? 0.22 : 0.14);
    } else if (isRelated) {
      backgroundColor = isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.7)
          : const Color(0xFFF1F5F9);
    } else {
      backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    }

    // Text color resolution
    final Color textColor;
    if (isIncorrect) {
      textColor = const Color(0xFFEF4444); // Red error
    } else if (isClue) {
      textColor = isDark
          ? Colors.white
          : const Color(0xFF0F172A); // Bold dark/white clue
    } else {
      textColor = const Color(0xFF2563EB); // Player blue entry
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: borderTop,
              left: borderLeft,
              bottom: borderBottom,
              right: borderRight,
            ),
          ),
          child: Center(
            child: value != 0
                ? Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: isClue ? FontWeight.w800 : FontWeight.w700,
                      color: textColor,
                    ),
                  )
                : (notes.isNotEmpty
                    ? _buildNotesGrid(isDark)
                    : const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesGrid(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int r = 0; r < 3; r++)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int c = 0; c < 3; c++)
                  _buildNoteDigit(r * 3 + c + 1, isDark),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNoteDigit(int digit, bool isDark) {
    final hasNote = notes.contains(digit);
    return SizedBox(
      width: 9,
      height: 9,
      child: Center(
        child: hasNote
            ? Text(
                '$digit',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  height: 1.0,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
