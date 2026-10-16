import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../cubit/word_circle_state.dart';
import '../../domain/word_circle_engine.dart';

/// Responsive crossword-style target grid displaying unrevealed empty tiles,
/// revealed letters for solved target words, and hinted cells.
class WordCircleCrossword extends StatelessWidget {
  final WordCircleState state;
  final WordCircleEngine engine;

  const WordCircleCrossword({
    super.key,
    required this.state,
    this.engine = const WordCircleEngine(),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final level = state.level;
    final cellMap = engine.generateCrosswordGrid(
      level: level,
      foundTargetWords: state.foundTargetWords,
      hintedCellKeys: state.hintedCellKeys,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cell size that fits both horizontally and vertically
        final cellSpacing = 4.0;
        final totalVerticalMargins = (level.rows * cellSpacing) + 12.0;
        final totalHorizontalMargins = (level.cols * cellSpacing) + 16.0;

        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - totalHorizontalMargins,
        );
        final availableHeight = constraints.maxHeight > 0
            ? math.max(0.0, constraints.maxHeight - totalVerticalMargins)
            : 220.0;

        final rawCellW = availableWidth / level.cols;
        final rawCellH = availableHeight / level.rows;
        final cellSize = math.min(rawCellW, rawCellH).clamp(18.0, 42.0);
        final borderRadius = BorderRadius.circular(cellSize < 30 ? 6 : 8);

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(level.rows, (r) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: cellSpacing / 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(level.cols, (c) {
                        final key = '$r,$c';
                        final cell = cellMap[key];

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: cellSpacing / 2,
                          ),
                          child: SizedBox(
                            width: cellSize,
                            height: cellSize,
                            child: cell == null
                                ? const SizedBox.shrink()
                                : AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      borderRadius: borderRadius,
                                      color: cell.isRevealed
                                          ? (isDark
                                                ? const Color(0xFF1E293B)
                                                : Colors.white)
                                          : (cell.isHinted
                                                ? const Color(
                                                    0xFFF59E0B,
                                                  ).withValues(alpha: 0.15)
                                                : (isDark
                                                      ? const Color(
                                                          0xFF0F172A,
                                                        ).withValues(alpha: 0.5)
                                                      : Colors.white.withValues(
                                                          alpha: 0.6,
                                                        ))),
                                      border: Border.all(
                                        color: cell.isRevealed
                                            ? const Color(0xFF06B6D4)
                                            : (cell.isHinted
                                                  ? const Color(0xFFF59E0B)
                                                  : (isDark
                                                        ? Colors.white24
                                                        : Colors.black12)),
                                        width:
                                            (cell.isRevealed || cell.isHinted)
                                            ? 2.0
                                            : 1.0,
                                      ),
                                      boxShadow: [
                                        if (cell.isRevealed)
                                          BoxShadow(
                                            color: const Color(
                                              0xFF06B6D4,
                                            ).withValues(alpha: 0.25),
                                            blurRadius: 6.0,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: Center(
                                      child: (cell.isRevealed || cell.isHinted)
                                          ? Text(
                                              cell.letter,
                                              style: TextStyle(
                                                fontSize: cellSize * 0.52,
                                                fontWeight: FontWeight.bold,
                                                color: cell.isRevealed
                                                    ? (isDark
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF0F172A,
                                                            ))
                                                    : const Color(0xFFD97706),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
