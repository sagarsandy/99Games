import 'package:flutter/material.dart';
import '../../cubit/sudoku_cubit.dart';
import '../../cubit/sudoku_state.dart';
import '../../domain/sudoku_engine.dart';

/// On-screen number pad for entering digits 1 through 9.
///
/// Displays remaining digit counts and dims completed numbers (all 9 placed).
class SudokuNumberPad extends StatelessWidget {
  final SudokuState state;
  final SudokuCubit cubit;
  final SudokuEngine engine;

  const SudokuNumberPad({
    super.key,
    required this.state,
    required this.cubit,
    this.engine = const SudokuEngine(),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingMap = engine.countRemainingNumbers(state.board);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (8 * 6)) / 9;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int digit = 1; digit <= 9; digit++)
              _buildDigitButton(
                digit: digit,
                remaining: remainingMap[digit] ?? 0,
                width: itemWidth,
                isDark: isDark,
              ),
          ],
        );
      },
    );
  }

  Widget _buildDigitButton({
    required int digit,
    required int remaining,
    required double width,
    required bool isDark,
  }) {
    final isCompleted = remaining <= 0;
    final isEnabled = !state.isFinished && !isCompleted;

    final bgColor = isCompleted
        ? (isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.3)
              : const Color(0xFFF1F5F9))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    final fgColor = isCompleted
        ? (isDark ? Colors.white24 : const Color(0xFFCBD5E1))
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    return SizedBox(
      width: width,
      height: 58,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        elevation: isCompleted ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isEnabled ? () => cubit.enterNumber(digit) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$digit',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isCompleted ? '✓' : '$remaining',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? const Color(0xFF10B981) // Emerald check
                      : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
