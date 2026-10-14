import 'dart:math';
import 'package:flutter/material.dart';
import '../../cubit/dots_and_boxes_cubit.dart';
import '../../cubit/dots_and_boxes_state.dart';
import '../../domain/dots_and_boxes_models.dart';

/// The interactive square game board for Dots and Boxes rendered via [CustomPainter].
///
/// Supports smooth pinch-to-zoom and panning via [InteractiveViewer] for Medium
/// and Large boards, with mathematical hit-testing for generous touch targets.
class DotsAndBoxesBoard extends StatefulWidget {
  final DotsAndBoxesState state;
  final DotsAndBoxesCubit cubit;

  const DotsAndBoxesBoard({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  State<DotsAndBoxesBoard> createState() => _DotsAndBoxesBoardState();
}

class _DotsAndBoxesBoardState extends State<DotsAndBoxesBoard> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final current = _transformationController.value;
    final scale = current.getMaxScaleOnAxis();
    if (scale < 3.0) {
      _transformationController.value = current.clone()
        ..scaleByDouble(1.25, 1.25, 1.0, 1.0);
    }
  }

  void _zoomOut() {
    final current = _transformationController.value;
    final scale = current.getMaxScaleOnAxis();
    if (scale > 0.8) {
      _transformationController.value = current.clone()
        ..scaleByDouble(0.8, 0.8, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boardSize = widget.state.boardSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute base board dimension based on available space and board size
        final maxAvailable = min(constraints.maxWidth, constraints.maxHeight);

        // Optimal pixel size per board tier for readability and touch targets
        final double boardPixelSize = switch (boardSize) {
          BoardSize.small => max(maxAvailable, 340.0),
          BoardSize.medium => max(maxAvailable, 390.0),
          BoardSize.large => max(maxAvailable * 1.25, 520.0),
        };

        const double padding = 24.0;
        final double gridDimension = boardPixelSize - 2 * padding;
        final double cellSize = gridDimension / boardSize.cols;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Interactive Board Container
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: maxAvailable,
                height: maxAvailable,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.35 : 0.08,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.65,
                  maxScale: 3.5,
                  boundaryMargin: const EdgeInsets.all(60),
                  child: Center(
                    child: SizedBox(
                      width: boardPixelSize,
                      height: boardPixelSize,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) => _handleTap(
                          details.localPosition,
                          padding,
                          cellSize,
                          boardSize,
                        ),
                        child: CustomPaint(
                          size: Size(boardPixelSize, boardPixelSize),
                          painter: _DotsAndBoxesPainter(
                            state: widget.state,
                            padding: padding,
                            cellSize: cellSize,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Zoom helper controls for Medium and Large boards
            if (boardSize != BoardSize.small)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.zoom_out_rounded, size: 20),
                        tooltip: 'Zoom Out',
                        onPressed: _zoomOut,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fit_screen_rounded, size: 20),
                        tooltip: 'Reset Zoom',
                        onPressed: _resetZoom,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.zoom_in_rounded, size: 20),
                        tooltip: 'Zoom In',
                        onPressed: _zoomIn,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _handleTap(
    Offset localPosition,
    double padding,
    double cellSize,
    BoardSize boardSize,
  ) {
    if (widget.state.isGameOver || widget.state.isAiThinking) return;

    final double relX = localPosition.dx - padding;
    final double relY = localPosition.dy - padding;
    final double gridWidth = boardSize.cols * cellSize;
    final double gridHeight = boardSize.rows * cellSize;

    // Check boundary tolerance
    if (relX < -cellSize * 0.4 ||
        relX > gridWidth + cellSize * 0.4 ||
        relY < -cellSize * 0.4 ||
        relY > gridHeight + cellSize * 0.4) {
      return;
    }

    // Determine nearest grid coordinates
    final int rCenter = (relY / cellSize).round();
    final int cCenter = (relX / cellSize).round();

    EdgePosition? bestEdge;
    double minDistance = double.infinity;
    final double maxHitDistance = cellSize * 0.48; // Generous hit area

    // Check candidate horizontal edges nearby
    for (
      int r = max(0, rCenter - 1);
      r <= min(boardSize.rows, rCenter + 1);
      r++
    ) {
      for (
        int c = max(0, cCenter - 1);
        c <= min(boardSize.cols - 1, cCenter + 1);
        c++
      ) {
        // Skip already claimed
        if (widget.state.horizontalEdges[r][c] != null) continue;

        final double xStart = c * cellSize;
        final double xEnd = (c + 1) * cellSize;
        final double y = r * cellSize;

        final double clampedX = relX.clamp(xStart, xEnd);
        final double dist = sqrt(pow(relX - clampedX, 2) + pow(relY - y, 2));

        if (dist < minDistance && dist <= maxHitDistance) {
          minDistance = dist;
          bestEdge = EdgePosition.horizontal(r, c);
        }
      }
    }

    // Check candidate vertical edges nearby
    for (
      int r = max(0, rCenter - 1);
      r <= min(boardSize.rows - 1, rCenter + 1);
      r++
    ) {
      for (
        int c = max(0, cCenter - 1);
        c <= min(boardSize.cols, cCenter + 1);
        c++
      ) {
        // Skip already claimed
        if (widget.state.verticalEdges[r][c] != null) continue;

        final double x = c * cellSize;
        final double yStart = r * cellSize;
        final double yEnd = (r + 1) * cellSize;

        final double clampedY = relY.clamp(yStart, yEnd);
        final double dist = sqrt(pow(relX - x, 2) + pow(relY - clampedY, 2));

        if (dist < minDistance && dist <= maxHitDistance) {
          minDistance = dist;
          bestEdge = EdgePosition.vertical(r, c);
        }
      }
    }

    if (bestEdge != null) {
      widget.cubit.claimEdge(bestEdge);
    }
  }
}

/// Custom painter that draws claimed boxes, unclaimed and claimed edges,
/// dots at vertices, and a subtle glowing highlight for the last move.
class _DotsAndBoxesPainter extends CustomPainter {
  final DotsAndBoxesState state;
  final double padding;
  final double cellSize;
  final bool isDark;

  _DotsAndBoxesPainter({
    required this.state,
    required this.padding,
    required this.cellSize,
    required this.isDark,
  });

  static const Color p1Color = Color(0xFF2563EB); // Electric Blue
  static const Color p2Color = Color(0xFFE11D48); // Radiant Rose

  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = state.boardSize;

    // 1. Draw Completed Boxes
    _paintCompletedBoxes(canvas, boardSize);

    // 2. Draw Unclaimed Edge Guidelines
    _paintUnclaimedEdges(canvas, boardSize);

    // 3. Draw Claimed Edges
    _paintClaimedEdges(canvas, boardSize);

    // 4. Draw Last Move Highlight
    _paintLastMoveHighlight(canvas);

    // 5. Draw Dots at Grid Vertices
    _paintDots(canvas, boardSize);
  }

  void _paintCompletedBoxes(Canvas canvas, BoardSize boardSize) {
    for (int r = 0; r < boardSize.rows; r++) {
      for (int c = 0; c < boardSize.cols; c++) {
        final owner = state.boxes[r][c];
        if (owner == null) continue;

        final color = owner == DotsPlayer.player1 ? p1Color : p2Color;
        final rect = Rect.fromLTWH(
          padding + c * cellSize + 2.0,
          padding + r * cellSize + 2.0,
          cellSize - 4.0,
          cellSize - 4.0,
        );

        // Fill background
        final fillPaint = Paint()
          ..color = color.withValues(alpha: isDark ? 0.26 : 0.16)
          ..style = PaintingStyle.fill;
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rrect, fillPaint);

        // Subtle inner border
        final borderPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawRRect(rrect, borderPaint);

        // Player initial / symbol badge centered
        if (cellSize >= 24) {
          final badge = owner.shortBadge(state.gameMode);
          final textPainter = TextPainter(
            text: TextSpan(
              text: badge,
              style: TextStyle(
                color: color.withValues(alpha: 0.65),
                fontSize: max(11.0, cellSize * 0.36),
                fontWeight: FontWeight.w800,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final textOffset = Offset(
            padding + c * cellSize + (cellSize - textPainter.width) / 2,
            padding + r * cellSize + (cellSize - textPainter.height) / 2,
          );
          textPainter.paint(canvas, textOffset);
        }
      }
    }
  }

  void _paintUnclaimedEdges(Canvas canvas, BoardSize boardSize) {
    final unclaimedPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Horizontal unclaimed
    for (int r = 0; r <= boardSize.rows; r++) {
      for (int c = 0; c < boardSize.cols; c++) {
        if (state.horizontalEdges[r][c] == null) {
          final p1 = Offset(padding + c * cellSize, padding + r * cellSize);
          final p2 = Offset(
            padding + (c + 1) * cellSize,
            padding + r * cellSize,
          );
          canvas.drawLine(p1, p2, unclaimedPaint);
        }
      }
    }

    // Vertical unclaimed
    for (int r = 0; r < boardSize.rows; r++) {
      for (int c = 0; c <= boardSize.cols; c++) {
        if (state.verticalEdges[r][c] == null) {
          final p1 = Offset(padding + c * cellSize, padding + r * cellSize);
          final p2 = Offset(
            padding + c * cellSize,
            padding + (r + 1) * cellSize,
          );
          canvas.drawLine(p1, p2, unclaimedPaint);
        }
      }
    }
  }

  void _paintClaimedEdges(Canvas canvas, BoardSize boardSize) {
    final double strokeWidth = max(3.5, min(5.5, cellSize * 0.12));

    final p1Paint = Paint()
      ..color = p1Color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final p2Paint = Paint()
      ..color = p2Color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Horizontal claimed
    for (int r = 0; r <= boardSize.rows; r++) {
      for (int c = 0; c < boardSize.cols; c++) {
        final owner = state.horizontalEdges[r][c];
        if (owner != null) {
          final paint = owner == DotsPlayer.player1 ? p1Paint : p2Paint;
          final p1 = Offset(padding + c * cellSize, padding + r * cellSize);
          final p2 = Offset(
            padding + (c + 1) * cellSize,
            padding + r * cellSize,
          );
          canvas.drawLine(p1, p2, paint);
        }
      }
    }

    // Vertical claimed
    for (int r = 0; r < boardSize.rows; r++) {
      for (int c = 0; c <= boardSize.cols; c++) {
        final owner = state.verticalEdges[r][c];
        if (owner != null) {
          final paint = owner == DotsPlayer.player1 ? p1Paint : p2Paint;
          final p1 = Offset(padding + c * cellSize, padding + r * cellSize);
          final p2 = Offset(
            padding + c * cellSize,
            padding + (r + 1) * cellSize,
          );
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
  }

  void _paintLastMoveHighlight(Canvas canvas) {
    final lastMove = state.lastMove;
    if (lastMove == null) return;

    final glowPaint = Paint()
      ..color = const Color(0xFFF59E0B)
          .withValues(alpha: 0.6) // Amber halo
      ..strokeWidth = max(5.0, cellSize * 0.18)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Offset p1, p2;
    if (lastMove.isHorizontal) {
      p1 = Offset(
        padding + lastMove.col * cellSize,
        padding + lastMove.row * cellSize,
      );
      p2 = Offset(
        padding + (lastMove.col + 1) * cellSize,
        padding + lastMove.row * cellSize,
      );
    } else {
      p1 = Offset(
        padding + lastMove.col * cellSize,
        padding + lastMove.row * cellSize,
      );
      p2 = Offset(
        padding + lastMove.col * cellSize,
        padding + (lastMove.row + 1) * cellSize,
      );
    }

    canvas.drawLine(p1, p2, glowPaint);
  }

  void _paintDots(Canvas canvas, BoardSize boardSize) {
    final dotRadius = max(3.0, min(5.5, cellSize * 0.11));

    final dotPaint = Paint()
      ..color = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final dotOutlinePaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int r = 0; r <= boardSize.rows; r++) {
      for (int c = 0; c <= boardSize.cols; c++) {
        final center = Offset(padding + c * cellSize, padding + r * cellSize);
        canvas.drawCircle(center, dotRadius, dotPaint);
        canvas.drawCircle(center, dotRadius, dotOutlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsAndBoxesPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.isDark != isDark;
  }
}
