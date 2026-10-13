import 'package:flutter/material.dart';
import '../../cubit/word_search_cubit.dart';
import '../../cubit/word_search_state.dart';
import '../../domain/word_search_models.dart';
import 'word_search_cell.dart';
import 'word_search_palette.dart';

/// The interactive square letter grid for Word Search.
///
/// Supports smooth touch-drag selection as well as accessible tap-to-select.
class WordSearchGrid extends StatelessWidget {
  final WordSearchState state;
  final WordSearchCubit cubit;

  const WordSearchGrid({super.key, required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final size = state.puzzle.size;
    final grid = state.grid;
    final isInteractive = !state.isCompleted;

    // Precompute found colors lookup for all coordinates
    final Map<GridCoordinate, List<Color>> coordinateFoundColors = {};
    for (final found in state.foundWords) {
      final color = WordSearchPalette.getColor(found.colorIndex);
      for (final coord in found.coordinates) {
        coordinateFoundColors.putIfAbsent(coord, () => []).add(color);
      }
    }

    final selectedCoordsSet = state.currentSelection.toSet();

    return AspectRatio(
      aspectRatio: 1.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridPixelSize = constraints.maxWidth;
          final cellSize = gridPixelSize / size;

          GridCoordinate? offsetToCoord(Offset localPosition) {
            final col = (localPosition.dx / cellSize).floor();
            final row = (localPosition.dy / cellSize).floor();

            if (row >= 0 && row < size && col >= 0 && col < size) {
              return GridCoordinate(row, col);
            }
            return null;
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: !isInteractive
                ? null
                : (details) {
                    final coord = offsetToCoord(details.localPosition);
                    if (coord != null) {
                      cubit.startSelection(coord);
                    }
                  },
            onPanUpdate: !isInteractive
                ? null
                : (details) {
                    final coord = offsetToCoord(details.localPosition);
                    if (coord != null) {
                      cubit.updateSelection(coord);
                    }
                  },
            onPanEnd: !isInteractive
                ? null
                : (_) {
                    cubit.endSelection();
                  },
            onPanCancel: !isInteractive
                ? null
                : () {
                    cubit.clearSelection();
                  },
            onTapUp: !isInteractive
                ? null
                : (details) {
                    final coord = offsetToCoord(details.localPosition);
                    if (coord != null) {
                      cubit.cellTapped(coord);
                    }
                  },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: size * size,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size,
                  crossAxisSpacing: size > 10 ? 3 : 4,
                  mainAxisSpacing: size > 10 ? 3 : 4,
                ),
                itemBuilder: (context, index) {
                  final row = index ~/ size;
                  final col = index % size;
                  final coord = GridCoordinate(row, col);
                  final isSelected = selectedCoordsSet.contains(coord);
                  final isStart = state.selectionStart == coord;
                  final isEnd = state.selectionEnd == coord;
                  final foundColors = coordinateFoundColors[coord] ?? const [];

                  return WordSearchCell(
                    key: ValueKey('cell_${row}_$col'),
                    letter: grid[row][col],
                    isSelected: isSelected,
                    isSelectionStart: isStart,
                    isSelectionEnd: isEnd,
                    foundColors: foundColors,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
