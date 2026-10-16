import 'dart:math';
import 'package:flutter/material.dart';
import '../../cubit/emoji_connect_cubit.dart';
import '../../cubit/emoji_connect_state.dart';
import '../../domain/emoji_connect_models.dart';
import 'emoji_connect_cell.dart';
import 'emoji_connect_path.dart';

/// The interactive, touch/mouse-driven square board for Emoji Connect.
class EmojiConnectBoard extends StatefulWidget {
  final EmojiConnectState state;
  final EmojiConnectCubit cubit;

  const EmojiConnectBoard({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  State<EmojiConnectBoard> createState() => _EmojiConnectBoardState();
}

class _EmojiConnectBoardState extends State<EmojiConnectBoard> {
  GridPosition? _lastDragCoord;

  GridPosition? _offsetToCoord(
    Offset localPosition,
    double cellSize,
    int boardSize,
  ) {
    final col = (localPosition.dx / cellSize).floor();
    final row = (localPosition.dy / cellSize).floor();

    if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
      return GridPosition(row, col);
    }
    return null;
  }

  /// Interpolates missing intermediate orthogonal steps if pointer moved fast.
  void _handleDragMove(GridPosition target) {
    if (_lastDragCoord == null) {
      _lastDragCoord = target;
      widget.cubit.updateDrag(target);
      return;
    }

    final prev = _lastDragCoord!;
    if (prev == target) return;

    // If already orthogonal, process directly
    if (prev.isOrthogonalTo(target)) {
      _lastDragCoord = target;
      widget.cubit.updateDrag(target);
      return;
    }

    // Fast pointer movement: step row-wise then col-wise (or vice-versa)
    int currR = prev.row;
    int currC = prev.col;

    while (currR != target.row || currC != target.col) {
      if (currR != target.row) {
        currR += (target.row > currR) ? 1 : -1;
      } else if (currC != target.col) {
        currC += (target.col > currC) ? 1 : -1;
      }
      final step = GridPosition(currR, currC);
      widget.cubit.updateDrag(step);
    }

    _lastDragCoord = target;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boardSize = widget.state.engine.level.boardSize;
    final level = widget.state.engine.level;
    final paths = widget.state.engine.paths;
    final activeDragPairId = widget.state.engine.activeDragPairId;

    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardPixelSize = min(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final cellSize = boardPixelSize / boardSize;

            return IgnorePointer(
              ignoring: widget.state.isWon,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  final coord = _offsetToCoord(
                    details.localPosition,
                    cellSize,
                    boardSize,
                  );
                  if (coord != null) {
                    _lastDragCoord = coord;
                    widget.cubit.startDrag(coord);
                  }
                },
                onPanUpdate: (details) {
                  final coord = _offsetToCoord(
                    details.localPosition,
                    cellSize,
                    boardSize,
                  );
                  if (coord != null) {
                    _handleDragMove(coord);
                  }
                },
                onPanEnd: (_) {
                  _lastDragCoord = null;
                  widget.cubit.endDrag();
                },
                onPanCancel: () {
                  _lastDragCoord = null;
                  widget.cubit.endDrag();
                },
                onTapDown: (details) {
                  final coord = _offsetToCoord(
                    details.localPosition,
                    cellSize,
                    boardSize,
                  );
                  if (coord != null) {
                    _lastDragCoord = coord;
                    widget.cubit.startDrag(coord);
                  }
                },
                onTapUp: (_) {
                  _lastDragCoord = null;
                  widget.cubit.endDrag();
                },
                child: Container(
                  width: boardPixelSize,
                  height: boardPixelSize,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.state.isWon
                          ? const Color(0xFF10B981)
                          : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                      width: widget.state.isWon ? 2.5 : 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.state.isWon
                            ? const Color(0xFF10B981).withValues(alpha: 0.25)
                            : Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.08,
                              ),
                        blurRadius: widget.state.isWon ? 20 : 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Custom painter for grid and drawn paths
                        CustomPaint(
                          painter: EmojiConnectPathPainter(
                            level: level,
                            paths: paths,
                            activeDragPairId: activeDragPairId,
                            isDark: isDark,
                          ),
                        ),

                        // 2. Cell grid overlay rendering emoji endpoints and center anchor dots
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: boardSize * boardSize,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: boardSize,
                              ),
                          itemBuilder: (context, index) {
                            final r = index ~/ boardSize;
                            final c = index % boardSize;
                            final pos = GridPosition(r, c);
                            final endpointPair = level.getPairAtEndpoint(pos);
                            final isPairCompleted =
                                endpointPair != null &&
                                paths[endpointPair.id]?.isComplete(
                                      endpointPair,
                                    ) ==
                                    true;
                            final isDraggingPair =
                                endpointPair != null &&
                                endpointPair.id == activeDragPairId;

                            return EmojiConnectCell(
                              key: ValueKey('emoji_cell_${r}_$c'),
                              position: pos,
                              endpointPair: endpointPair,
                              isCompleted: isPairCompleted,
                              isDraggingThisPair: isDraggingPair,
                              cellSize: cellSize,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
